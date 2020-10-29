//
//  DetailDataManager.swift
//  Bookshelf
//
//  Created by Den Jo on 2020/10/20.
//

import Foundation
import CoreData

// MARK: - Define
struct DetailNotificationName {
    static let detail = Notification.Name("DetailNotification")
}

@objc final class DetailDataManager: NSObject {
    
    // MARK: - Value
    // MARK: Public
    private(set) var detail: DetailResponse? = nil
    var isbn: String? = nil
    var note: String? = nil
    
    
    
    // MARK: - Function
    // MARK: Public
    func request() -> Bool {
        var detail: DetailResponse?      = nil
        var note: String?                = nil
        var errorDetail: ResponseDetail? = nil
        
        let group = DispatchGroup()
        
        // Detail
        group.enter()
        guard requestDetail(completion: { (data, error) in
            detail      = data
            errorDetail = error
            
            group.leave()
            
        }) == true else {
            group.leave()
            return false
        }
        
        
        // Detail
        group.enter()
        guard loadNote(completion: { data in
            note = data
            group.leave()
            
        }) == true else {
            group.leave()
            return false
        }
        
        
        group.notify(queue: .main) {
            self.detail = detail
            self.note   = note
            
            NotificationCenter.default.post(name: DetailNotificationName.detail, object: errorDetail)
        }
        return true
    }
    
    func saveNote() {
        guard let isbn = isbn, let note = note, note != "" else { return }
        
        DispatchQueue.global().async {
            let entity = NoteEntity(context: BookCoreDataStack.shared.managedContext)
            entity.isbn = isbn
            entity.note = note
        
            BookCoreDataStack.shared.saveContext()
        }
    }
    
    
    // MARK: Private
    private func requestDetail(completion: @escaping (_ detail: DetailResponse?, _ error: ResponseDetail?) -> Void) -> Bool {
        guard let isbn = isbn else { return false }
        let request = URLRequest(httpMethod: .get, url: .detail(isbn: isbn))
        
        return NetworkManager.shared.request(urlRequest: request) { response in
            var detail: DetailResponse? = nil
            var errorDetail: ResponseDetail? = nil
            
            defer { completion(detail, errorDetail) }
            
            guard let decodableData = response?.data else {
                errorDetail = ResponseDetail(message: response?.detail?.message ?? NSLocalizedString("Please check your network connection or try again.", comment: ""))
                return
            }
            
            do {
                detail = try JSONDecoder().decode(DetailResponse.self, from: decodableData)
                
            } catch {
                log(.error, error.localizedDescription)
                errorDetail = ResponseDetail(message: error.localizedDescription)
                return
            }
        }
    }
    
    private func loadNote(completion: @escaping (_ note: String?) -> Void) -> Bool {
        guard let isbn = isbn else { return false }
        
        let request: NSFetchRequest<NoteEntity> = NoteEntity.fetchRequest()
        request.predicate  = NSPredicate(format: "%K == %@", #keyPath(NoteEntity.isbn), isbn)
        request.fetchLimit = 1
        
        var note: String? = nil
        
        DispatchQueue.global().async {
            defer { completion(note) }
            
            do {
                let result = try BookCoreDataStack.shared.managedContext.fetch(request)
                note = result.first?.note
                
            } catch {
                log(.error, error.localizedDescription)
            }
        }
        
        return true
    }
}
