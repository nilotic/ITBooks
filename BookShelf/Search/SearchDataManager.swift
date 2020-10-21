//
//  SearchDataManager.swift
//  Bookshelf
//
//  Created by Den Jo on 2020/10/19.
//

import Foundation
import CoreData

// MARK: - Define
struct SearchNotificationName {
    static let autocompletes = Notification.Name("AutocompletesNotification")
    static let update        = Notification.Name("AutocompleteUpdateNotification")
}

final class SearchDataManager: NSObject {
    
    // MARK: - Value
    // MARK: Public
    private(set) var autocompletes = [Autocomplete]()
    private(set) var totalCount: UInt = 0
    
    var keyword: String? = nil {
        didSet { request()  }
    }
    
    
    // MARK: Private
    private lazy var coreDataStack: BookCoreDataStack = {
        let coreDataStack = BookCoreDataStack()
        return coreDataStack
    }()

    
    private var keywordWorkItem: DispatchWorkItem?    = nil
    private var paginationWorkItem: DispatchWorkItem? = nil
    
    private var keywordCache: String? = nil
    private var currentPage: UInt     = 0
    
    private var searchedKeywords: [SearchedKeyword] {
        set {
            guard newValue.isEmpty == false else { return }
            do { UserDefaults.standard.set(try JSONEncoder().encode(newValue), forKey: UserDefaultsKey.searchedKeywords) } catch { log(.error, error.localizedDescription) }
        }
        
        get {
            guard let data = UserDefaults.standard.value(forKey: UserDefaultsKey.searchedKeywords) as? Data else { return [] }
            return (try? JSONDecoder().decode([SearchedKeyword].self, from: data)) ?? []
        }
    }
    
    
    
    // MARK: - Initializer
    override init() {
        super.init()
       
        coreDataStack.loadPersistentStores { error in
            guard let error = error else { return }
            log(.error, error.localizedDescription)
        }
    }
    
    
    
    // MARK: - Function
    // MARK: Public
    func request() {
        // Cancel workItems brefore requesting autocompletes
        keywordWorkItem?.cancel()
        paginationWorkItem?.cancel()
        keywordCache = nil

        
        guard let keyword = keyword, keyword != "" else {
            requestSearchedKeywords()
            return
        }
        
        // Set workItem
        let workItem = DispatchWorkItem {
            guard self.loadResult() == false else { return }
            self.requestAutocompletes()
        }
        
        keywordWorkItem = workItem
        
        
        // Lazy request
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: workItem)
    }
    
    func requestNextPage() {
        guard let keywordCache = keywordCache else { return }
        
        let workItem = DispatchWorkItem {
            guard self.requesNextPage(keyword: keywordCache) == true else { return }
            self.keywordCache = nil // Lock
        }
        
        self.paginationWorkItem = workItem
        DispatchQueue.main.async(execute: workItem)
    }
    
    func delete(indexPath: IndexPath) -> Bool {
        guard indexPath.row < autocompletes.count, let autocomplete = autocompletes[indexPath.row] as? KeywordAutocomplete else { return false }
        var keywords = searchedKeywords
        
        guard let index = keywords.firstIndex(where: { $0.keyword == autocomplete.keyword }) else { return false }
        keywords.remove(at: index)
        searchedKeywords = keywords
        
        autocompletes.remove(at: indexPath.row)
        
        NotificationCenter.default.post(name: SearchNotificationName.update, object: [UITableViewAnimationSet(animation: .deleteRows, rows: [indexPath])])
        return true
    }
    
    
    // MARK: Private
    @discardableResult
    private func requestAutocompletes() -> Bool {
        guard let keyword = keyword?.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed), keyword != "" else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                self.autocompletes = []
                NotificationCenter.default.post(name: SearchNotificationName.autocompletes, object: nil)
            }
            return false
        }
        
        let request = URLRequest(httpMethod: .get, url: .autocomplete(keyword: keyword))
        
        return NetworkManager.shared.request(urlRequest: request) { response in
            var autocompletes = [Autocomplete]()
            var currentPage: UInt = 0
            var count: UInt       = 0
            var totalCount: UInt  = 0
            var errorDetail: ResponseDetail? = nil
            
            defer {
                DispatchQueue.main.async {
                    self.autocompletes = autocompletes
                    self.currentPage   = currentPage
                    self.totalCount    = totalCount
                    self.keywordCache  = keyword
                    
                
                    NotificationCenter.default.post(name: SearchNotificationName.autocompletes, object: errorDetail)
                    
                    guard autocompletes.isEmpty == false else { return }
                    self.updateKeywords(keyword: keyword, currentPage: currentPage, count: count, totalCount: totalCount)
                    self.cache()
                }
            }
            
            guard let decodableData = response?.data else {
                errorDetail = response?.detail ?? ResponseDetail(message: NSLocalizedString("Please check your network connection or try again.", comment: ""))
                return
            }
            
            do {
                let data = try JSONDecoder().decode(BooksResponse.self, from: decodableData)
                autocompletes = data.books.map { BookAutocomplete(data: $0) }
                currentPage   = data.page
                totalCount    = data.total
                count         = UInt(autocompletes.count)
                
                guard autocompletes.count < data.total else { return }
                autocompletes.append(LoadingAutocomplete())
                
            } catch {
                log(.error, error.localizedDescription)
                errorDetail = ResponseDetail(message: error.localizedDescription)
                return
            }
        }
    }
    
    @discardableResult
    private func requesNextPage(keyword: String) -> Bool {
        guard let keyword = keyword.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed), keyword != "" else { return false }
        var autocompletes = self.autocompletes
        let request = URLRequest(httpMethod: .get, url: .autocomplete(keyword: keyword, page: currentPage + 1))
       
        return NetworkManager.shared.request(urlRequest: request) { response in
            var animations = [UITableViewAnimationSet]()
            var currentPage: UInt = 0
            var totalCount: UInt  = 0
            var count: UInt       = 0
            var errorDetail: ResponseDetail? = nil
            
            defer {
                DispatchQueue.main.async {
                    guard currentPage == self.currentPage + 1, self.keyword == keyword else { return }
                    self.autocompletes = autocompletes
                    self.totalCount    = totalCount
                    self.currentPage   = currentPage
                    self.keywordCache  = keyword
                    
                    NotificationCenter.default.post(name: SearchNotificationName.update, object: errorDetail == nil ? animations : errorDetail)
                    
                    guard autocompletes.isEmpty == false else { return }
                    self.updateKeywords(keyword: keyword, currentPage: currentPage, count: count, totalCount: totalCount)
                    self.cache()
                }
            }
            
            guard let decodableData = response?.data else {
                errorDetail = response?.detail ?? ResponseDetail(message: NSLocalizedString("Please check your network connection or try again.", comment: ""))
                return
            }
            
            do {
                let data = try JSONDecoder().decode(BooksResponse.self, from: decodableData)
                
                if autocompletes.last is LoadingAutocomplete {
                    autocompletes.removeLast()
                }
                
                guard data.books.isEmpty == false else {
                    animations.append(UITableViewAnimationSet(animation: .deleteRows, rows: [IndexPath(row: autocompletes.count, section: 0)])) // Remove Indicator animation
                    return
                }
                
                animations.append(UITableViewAnimationSet(animation: .reloadRows, rows: [IndexPath(row: autocompletes.count, section: 0)])) // Reload the last cell (indicator -> item)
                
                var rows = [IndexPath]()
                let lastItemCount = autocompletes.count
                
                for (i, book) in data.books.enumerated() {
                    autocompletes.append(BookAutocomplete(data: book))
                    
                    guard 0 < i else { continue }
                    rows.append(IndexPath(row: lastItemCount + i, section: 0))
                }
                
                animations.append(UITableViewAnimationSet(animation: .insertRows, rows: rows))
                currentPage = data.page
                totalCount  = data.total
                count       = UInt(autocompletes.count)
                 
                guard autocompletes.count < data.total else { return }
                animations.append(UITableViewAnimationSet(animation: .insertRows, rows: [IndexPath(row: autocompletes.count, section: 0)]))
                autocompletes.append(LoadingAutocomplete())
                
            } catch {
                log(.error, error.localizedDescription)
                errorDetail = ResponseDetail(message: error.localizedDescription)
                return
            }
        }
    }
    
    private func requestSearchedKeywords() {
        guard (keyword == nil || keyword == "") else { return }
        
        let keywords = searchedKeywords
        guard keywords.isEmpty == false else { return }
        
        DispatchQueue.global().async {
            let autocompletes = keywords.map { KeywordAutocomplete(keyword: $0.keyword) }
                
            DispatchQueue.main.async {
                self.autocompletes = autocompletes
                NotificationCenter.default.post(name: SearchNotificationName.autocompletes, object: nil)
            }
        }
    }
    
    private func loadResult() -> Bool {
        #if UNITTEST
        return true
        
        #elseif UITEST
        return true
        
        #else
        guard let keyword = keyword?.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed), keyword != "", let searchedKeyword = searchedKeywords.first(where: { $0.keyword == keyword }) else { return false }
        
        let request: NSFetchRequest<BookEntity> = BookEntity.fetchRequest()
        request.predicate = NSPredicate(format: "%K BEGINSWITH %@", #keyPath(BookEntity.keyword), keyword)

        do {
            let result = try self.coreDataStack.managedContext.fetch(request)
            
            DispatchQueue.global().async {
                var autocompletes: [Autocomplete] = result.map { BookAutocomplete(data: $0) }
                
                if searchedKeyword.count < searchedKeyword.totalCount {
                    autocompletes.append(LoadingAutocomplete())
                }
                
                DispatchQueue.main.async {
                    self.autocompletes = autocompletes
                    self.currentPage   = searchedKeyword.currentPage
                    self.totalCount    = searchedKeyword.totalCount
                    self.keywordCache  = keyword
                    
                    NotificationCenter.default.post(name: SearchNotificationName.autocompletes, object: nil)
                }
            }

            return true
            
        } catch {
            log(.error, error.localizedDescription)
            return false
        }
        #endif
       
    }
    
    private func updateKeywords(keyword: String, currentPage: UInt, count: UInt, totalCount: UInt) {
        var keywords = searchedKeywords
        if let index = keywords.firstIndex(where: { $0.keyword == keyword }) {
            keywords.remove(at: index)
        }
            
        keywords.insert(SearchedKeyword(keyword: keyword, currentPage: currentPage, count: count, totalCount: totalCount), at: 0)
        searchedKeywords = keywords
    }
    
    private func cache() {
        #if UNITTEST
        #elseif UITEST
        #else
        guard let keyword = keyword else {
            log(.error, "Failed to cache the result.")
            return
        }
        
        // Remove the loading data
        var autocompletes = self.autocompletes
        guard autocompletes.isEmpty == false else { return }
        
        if autocompletes.last is LoadingAutocomplete {
            autocompletes.removeLast()
        }
        
        
        // Save
        guard let bookAutocompletes = autocompletes as? [BookAutocomplete] else {
            log(.error, "Failed to cache the result. keyword: \(keyword)")
            return
        }
        
        for autocomplete in bookAutocompletes {
            let entity = BookEntity(context: coreDataStack.managedContext)
            entity.keyword  = keyword
            entity.title    = autocomplete.title
            entity.subtitle = autocomplete.subtitle
            entity.price    = autocomplete.price
            entity.isbn     = autocomplete.isbn
            entity.imageURL = autocomplete.imageURL
            entity.url      = autocomplete.url
        }
        
        coreDataStack.saveContext()
        #endif
    }
}
