//
//  AppIconBoxTests.swift
//  AppIconBoxTests
//
//  Created by 孙翔宇 on 05/07/2019.
//  Copyright © 2019 孙翔宇. All rights reserved.
//

import XCTest
@testable import AppIconPro

class AppIconBoxTests: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testIconCount() {
        XCTAssertEqual(try! MacIconGenerator(marktingImage: NSImage()).icons.count, 39)
    }

    
    func testOutputStructure() {
        XCTAssertEqual(try! MacIconGenerator(marktingImage: NSImage()).populateIconStructure().count, 6)
    }
}
