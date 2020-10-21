//
//  BookShelfUITests.swift
//  BookShelfUITests
//
//  Created by Den Jo on 2020/10/20.
//

import XCTest

final class BookShelfUITests: XCTestCase {
    
    // MARK: - Value
    // MARK: Prvate
    private var application: XCUIApplication!
    
    
    /*
       Put setup code here. This method is called before the invocation of each test method in the class.
       In UI tests it is usually best to stop immediately when a failure occurs.
       In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
     */
    override func setUpWithError() throws {
        continueAfterFailure = false
        
        application = XCUIApplication()
        application.launch()
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testLaunchPerformance() throws {
        if #available(macOS 10.15, iOS 13.0, tvOS 13.0, *) {
            // This measures how long it takes to launch your application.
            measure(metrics: [XCTApplicationLaunchMetric()]) {
                XCUIApplication().launch()
            }
        }
    }
    
    
    // MARK: - UI
    // MARK: Search
    func testSearch() {
        let searchfield = application.searchFields.firstMatch
        searchfield.typeText("Hosts")
        
        self.application.tables.element(boundBy: 0).cells.element(boundBy: 0).tap()
    }
}
