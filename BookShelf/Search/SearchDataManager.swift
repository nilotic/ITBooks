//
//  SearchDataManager.swift
//  Bookshelf
//
//  Created by Den Jo on 2020/10/19.
//

import Foundation

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
    private var keywordWorkItem: DispatchWorkItem?    = nil
    private var paginationWorkItem: DispatchWorkItem? = nil
    
    private var keywordCache: String? = nil
    private var currentPage: UInt     = 0
    
    
    
    // MARK: - Function
    // MARK: Public
    func request() {
        // Cancel workItems brefore requesting autocompletes
        keywordWorkItem?.cancel()
        paginationWorkItem?.cancel()
        keywordCache = nil

        // Set workItem
        let workItem = DispatchWorkItem { self.requestAutocompletes() }
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
            var totalCount: UInt  = 0
            var errorDetail: ResponseDetail? = nil
            
            defer {
                DispatchQueue.main.async {
                    self.autocompletes = autocompletes
                    self.currentPage   = currentPage
                    self.totalCount    = totalCount
                    self.keywordCache  = keyword
                    
                    NotificationCenter.default.post(name: SearchNotificationName.autocompletes, object: errorDetail)
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
            var errorDetail: ResponseDetail? = nil
            
            defer {
                DispatchQueue.main.async {
                    guard currentPage == self.currentPage + 1, self.keyword == keyword else { return }
                    self.autocompletes = autocompletes
                    self.currentPage   = currentPage
                    self.keywordCache  = keyword
                    
                    NotificationCenter.default.post(name: SearchNotificationName.update, object: errorDetail == nil ? animations : errorDetail)
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
}
