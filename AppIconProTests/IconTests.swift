//
//  IconTests.swift
//  AppIconBoxTests
//
//  Created by 孙翔宇 on 05/07/2019.
//  Copyright © 2019 孙翔宇. All rights reserved.
//

import XCTest
@testable import AppIconPro

class IconTests: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func test1xIcon() {
        let icon = Icon(size: "20x21", idiom: "iphone", scale: "1x", role: nil, subtype: nil)
        
        XCTAssertEqual(icon.pixelSize.width, 20)
        XCTAssertEqual(icon.pixelSize.height, 20)
        
        XCTAssertEqual(icon.debugDescription, "20x21")
    }

    func test2xIcon() {
        let icon = Icon(size: "20x21", idiom: "iphone", scale: "2x", role: nil, subtype: nil)
        XCTAssertEqual(icon.pixelSize.width, 40)
        XCTAssertEqual(icon.pixelSize.height, 40)
        XCTAssertEqual(icon.debugDescription, "20x21@2x")
    }

}
