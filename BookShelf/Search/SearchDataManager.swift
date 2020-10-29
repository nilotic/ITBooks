//
//  SearchDataManager.swift
//  Bookshelf
//
//  Created by Den Jo on 2020/10/19.
//

import UIKit
import CoreData

// MARK: - Define
struct SearchNotificationName {
    static let autocompletes = Notification.Name("AutocompletesNotification")
    static let update        = Notification.Name("AutocompleteUpdateNotification")
}

final class SearchDataManager: NSObject {
    
    // MARK: - Value
    // MARK: Public
    var dataSource: Any? = nil
    
    private(set) var autocompletes = [HashableAutocomplete]()
    private(set) var totalCount: UInt = 0
    private(set) var sectionIdenfication = 0
    
    var keyword: String? = nil {
        didSet {
            guard let keyword = keyword, oldValue != keyword else { return }
            request()
        }
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
    private let queue = DispatchQueue(label: "accessQueue")
    
    
    
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
            self.keywordCache = nil // Lock before requesting the next page
        }
        
        self.paginationWorkItem = workItem
        DispatchQueue.main.async(execute: workItem)
    }
    
    /// Delete a keyword
    func delete(indexPath: IndexPath) -> Bool {
        guard indexPath.row < autocompletes.count, let autocomplete = autocompletes[indexPath.row].data as? KeywordAutocomplete else { return false }
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
        guard let keyword = keyword, let encodedKeyword = keyword.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed), keyword != "" else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                self.autocompletes = []
                self.sectionIdenfication = Int.random(in: 0...100)
                
                NotificationCenter.default.post(name: SearchNotificationName.autocompletes, object: nil)
            }
            return false
        }
        
        let request = URLRequest(httpMethod: .get, url: .autocomplete(keyword: encodedKeyword))
        
        return NetworkManager.shared.request(urlRequest: request) { response in
            var autocompletes      = [HashableAutocomplete]()
            var booksAutocompletes = [BookAutocomplete]()
            
            var currentPage: UInt = 0
            var count: UInt       = 0
            var totalCount: UInt  = 0
            var errorDetail: ResponseDetail? = nil
            
            defer {
                DispatchQueue.main.async {
                    self.autocompletes       = autocompletes
                    self.currentPage         = currentPage
                    self.totalCount          = totalCount
                    self.keywordCache        = keyword
                    self.sectionIdenfication = Int.random(in: 0...100)
                    
                    NotificationCenter.default.post(name: SearchNotificationName.autocompletes, object: errorDetail)
                    
                    guard booksAutocompletes.isEmpty == false else { return }
                    self.updateKeywords(keyword: keyword, currentPage: currentPage, count: count, totalCount: totalCount)
                    self.cache(autocompletes: booksAutocompletes, keyword: keyword)
                }
            }
            
            guard let decodableData = response?.data else {
                errorDetail = response?.detail ?? ResponseDetail(message: NSLocalizedString("Please check your network connection or try again.", comment: ""))
                return
            }
            
            do {
                let data = try JSONDecoder().decode(BooksResponse.self, from: decodableData)
                
                for book in data.books {
                    let autocomplete = BookAutocomplete(data: book)
                    booksAutocompletes.append(autocomplete)
                    autocompletes.append(HashableAutocomplete(data: autocomplete))
                }
                
                currentPage = data.page
                totalCount  = data.total
                count       = UInt(booksAutocompletes.count)
                
                guard autocompletes.count < data.total else { return }
                autocompletes.append(HashableAutocomplete(data: LoadingAutocomplete()))
                
            } catch {
                log(.error, error.localizedDescription)
                errorDetail = ResponseDetail(message: error.localizedDescription)
                return
            }
        }
    }
    
    @discardableResult
    private func requesNextPage(keyword: String) -> Bool {
        guard let encodedKeyword = keyword.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed), keyword != "" else { return false }
        var autocompletes = self.autocompletes
        let request = URLRequest(httpMethod: .get, url: .autocomplete(keyword: encodedKeyword, page: currentPage + 1))
       
        return NetworkManager.shared.request(urlRequest: request) { response in
            var animations         = [UITableViewAnimationSet]()
            var booksAutocompletes = [BookAutocomplete]()
            
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
                    self.cache(autocompletes: booksAutocompletes, keyword: keyword)
                }
            }
            
            guard let decodableData = response?.data else {
                errorDetail = response?.detail ?? ResponseDetail(message: NSLocalizedString("Please check your network connection or try again.", comment: ""))
                return
            }
            
            do {
                let data = try JSONDecoder().decode(BooksResponse.self, from: decodableData)
                currentPage = data.page
                totalCount  = data.total
                
                if autocompletes.last?.data is LoadingAutocomplete {
                    autocompletes.removeLast()
                    count = UInt(autocompletes.count)
                }
                
                guard data.books.isEmpty == false else {
                    animations.append(UITableViewAnimationSet(animation: .deleteRows, rows: [IndexPath(row: autocompletes.count, section: 0)])) // Remove Indicator animation
                    return
                }
                
                animations.append(UITableViewAnimationSet(animation: .reloadRows, rows: [IndexPath(row: autocompletes.count, section: 0)])) // Reload the last cell (indicator -> item)
                
                var rows = [IndexPath]()
                let lastItemCount = autocompletes.count
                
                for (i, book) in data.books.enumerated() {
                    let autocomplete = BookAutocomplete(data: book)
                    booksAutocompletes.append(autocomplete)
                    autocompletes.append(HashableAutocomplete(data: autocomplete))
                    
                    guard 0 < i else { continue }
                    rows.append(IndexPath(row: lastItemCount + i, section: 0))
                }
                
                animations.append(UITableViewAnimationSet(animation: .insertRows, rows: rows))
                count = UInt(autocompletes.count)
                 
                guard autocompletes.count < data.total else { return }
                animations.append(UITableViewAnimationSet(animation: .insertRows, rows: [IndexPath(row: autocompletes.count, section: 0)]))
                autocompletes.append(HashableAutocomplete(data: LoadingAutocomplete()))
                
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
            let autocompletes = keywords.map { HashableAutocomplete(data: KeywordAutocomplete(keyword: $0.keyword)) }
                
            DispatchQueue.main.async {
                self.autocompletes = autocompletes
                self.sectionIdenfication = Int.random(in: 0...100)
                NotificationCenter.default.post(name: SearchNotificationName.autocompletes, object: nil)
            }
        }
    }
    
    /// Load the cache in CoreData
    private func loadResult() -> Bool {
        #if UNITTEST
        return true
        
        #elseif UITEST
        return true
        
        #else
        guard let keyword = keyword, keyword != "", let searchedKeyword = searchedKeywords.first(where: { $0.keyword == keyword }) else { return false }
        
        let request: NSFetchRequest<BookEntity> = BookEntity.fetchRequest()
        request.predicate = NSPredicate(format: "%K BEGINSWITH %@", #keyPath(BookEntity.keyword), keyword)

        queue.async {
            do {
                let result = try self.coreDataStack.managedContext.fetch(request)
                var autocompletes: [HashableAutocomplete] = result.map { HashableAutocomplete(data: BookAutocomplete(data: $0)) }
                
                if searchedKeyword.count < searchedKeyword.totalCount {
                    autocompletes.append(HashableAutocomplete(data: LoadingAutocomplete()))
                }
                
                DispatchQueue.main.async {
                    self.autocompletes       = autocompletes
                    self.currentPage         = searchedKeyword.currentPage
                    self.totalCount          = searchedKeyword.totalCount
                    self.keywordCache        = keyword
                    self.sectionIdenfication = Int.random(in: 0...100)
                    
                    NotificationCenter.default.post(name: SearchNotificationName.autocompletes, object: nil)
                }
                
            } catch {
                log(.error, error.localizedDescription)
            }
        }
        #endif
        
        return true
    }
    
    /// Save searched keywords
    private func updateKeywords(keyword: String, currentPage: UInt, count: UInt, totalCount: UInt) {
        var keywords = searchedKeywords
        if let index = keywords.firstIndex(where: { $0.keyword == keyword }) {
            keywords.remove(at: index)
        }
            
        keywords.insert(SearchedKeyword(keyword: keyword, currentPage: currentPage, count: count, totalCount: totalCount), at: 0)
        searchedKeywords = keywords
    }
    
    /// Save data in CoreData
    private func cache(autocompletes: [BookAutocomplete], keyword: String) {
        #if UNITTEST
        #elseif UITEST
        #else
        guard autocompletes.isEmpty == false else { return }
        
        queue.async {
            for autocomplete in autocompletes {
                let entity = BookEntity(context: self.coreDataStack.managedContext)
                entity.keyword  = keyword
                entity.title    = autocomplete.title
                entity.subtitle = autocomplete.subtitle
                entity.price    = autocomplete.price
                entity.isbn     = autocomplete.isbn
                entity.imageURL = autocomplete.imageURL
                entity.url      = autocomplete.url
            }
            
            self.coreDataStack.saveContext()
        }
        #endif
    }
}
