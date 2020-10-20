//
//  DetailDataManager.swift
//  Bookshelf
//
//  Created by Den Jo on 2020/10/20.
//

import Foundation

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
    func requestDetail() -> Bool {
        guard let isbn = isbn else { return false }
        
        var request = URLRequest(httpMethod: .get, url: .detail(isbn: isbn))
        request.add(value: .applicationJSON,     field: .contentType)
        request.add(value: .applicationJsonUTF8, field: .accept)
        
        return NetworkManager.shared.request(urlRequest: request) { response in
            var detail: DetailResponse? = nil
            var errorMessage: String? = nil
            
            defer {
                DispatchQueue.main.async {
                    self.detail = detail
                    NotificationCenter.default.post(name: DetailNotificationName.detail, object: errorMessage)
                }
            }
            
            guard let decodableData = response?.data else {
                errorMessage = response?.detail?.message ?? NSLocalizedString("Please check your network connection or try again.", comment: "")
                return
            }
            
            do {
                detail = try JSONDecoder().decode(DetailResponse.self, from: decodableData)
                
            } catch {
                log(.error, error.localizedDescription)
                errorMessage = error.localizedDescription
                return
            }
        }
    }
}
