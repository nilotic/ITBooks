//
//  BookShelfTests.swift
//  BookShelfTests
//
//  Created by Den Jo on 2020/10/20.
//

import XCTest
@testable import BookShelf

final class BookShelfTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
    
    
    // MARK: - API
    // MARK: Autocomplete
    func testRequestAutocomplete() {
        let expectation = XCTestExpectation(description: "testRequestAutocomplete")
        
        NotificationCenter.default.addObserver(forName: SearchNotificationName.autocompletes, object: nil, queue: nil) { notification in
            XCTAssertNil(notification.object)
            expectation.fulfill()
        }
        
        let dataManager = SearchDataManager()
        dataManager.keyword = "Hosts"
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    // MARK: Detail
    func testRequestDetail() {
        let expectation = XCTestExpectation(description: "testRequestDetail")
                
        NotificationCenter.default.addObserver(forName: DetailNotificationName.detail, object: nil, queue: nil) { notification in
            XCTAssertNil(notification.object)
            expectation.fulfill()
        }
        
        let dataManager = DetailDataManager()
        dataManager.isbn = "9780321856715"
        XCTAssert(dataManager.requestDetail())
        wait(for: [expectation], timeout: 5.0)
    }
}
