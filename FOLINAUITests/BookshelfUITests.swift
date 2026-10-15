import XCTest

final class BookshelfUITests: XCTestCase {
    @MainActor
    func testCreationOptionsPreviewAndReturnWithoutSaving() throws {
        let app = XCUIApplication()
        XCUIDevice.shared.orientation = .landscapeLeft
        defer { XCUIDevice.shared.orientation = .portrait }
        app.launch()
        waitForLibrary(in: app)
        let create = app.buttons["create-diary"]
        XCTAssertTrue(create.waitForExistence(timeout: 5))
        create.tap()
        XCTAssertTrue(app.buttons["creation-back"].waitForExistence(timeout: 3))

        let name = app.textFields["diary-name"]
        name.tap()
        name.typeText("여행 일기\n")
        tap("kind-scrapbook", in: app)
        tap("binding-hardcover", in: app)
        tap("tone-lavender", in: app)
        tap("cover-botanicalWindow", in: app)
        tap("paper-dotted", in: app)
        tap("orientation-landscape", in: app)

        // 한 옵션을 바꿔도 다른 선택이 유지되고 실제 미리보기의 접근성 값에 반영됩니다.
        let preview = app.descendants(matching: .any)["creation-preview"].firstMatch
        let value = try XCTUnwrap(preview.value as? String)
        for text in ["여행 일기", "자유 스크랩북", "하드커버 노트", "라벤더", "식물 창 장식", "도트", "가로"] {
            XCTAssertTrue(value.contains(text), "미리보기 선택 누락: \(text)")
        }
        tap("creation-back", in: app)
        XCTAssertTrue(create.waitForExistence(timeout: 3))
        XCTAssertFalse(app.descendants(matching: .any)["diary-creation"].firstMatch.exists)
        create.tap()
        XCTAssertEqual(app.textFields["diary-name"].value as? String, "나의 다이어리")
    }

    @MainActor
    func testCreationPersistsAfterRelaunchAndOpensDetails() {
        let app = XCUIApplication()
        let title = "저장 검증 " + UUID().uuidString
        app.launch()
        waitForLibrary(in: app)
        let create = app.buttons["create-diary"]
        XCTAssertTrue(create.waitForExistence(timeout: 10))
        create.tap()
        let name = app.textFields["diary-name"]
        XCTAssertTrue(name.waitForExistence(timeout: 3))
        name.tap()
        name.typeText(title + "\n")
        tap("creation-submit", in: app)
        XCTAssertTrue(create.waitForExistence(timeout: 10))
        app.terminate()
        app.launch()
        waitForLibrary(in: app)
        let card = app.buttons.matching(NSPredicate(format: "label CONTAINS %@", title)).firstMatch
        XCTAssertTrue(card.waitForExistence(timeout: 10))
        card.tap()
        XCTAssertTrue(app.descendants(matching: .any)["diary-detail"].firstMatch.waitForExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts[title].exists)
    }

    @MainActor
    func testReaderBookmarkContentsRotationAndRelaunch() {
        let app = XCUIApplication()
        let title = "읽기 검증 " + UUID().uuidString
        XCUIDevice.shared.orientation = .portrait
        defer { XCUIDevice.shared.orientation = .portrait }
        app.launch()
        waitForLibrary(in: app)
        app.buttons["create-diary"].tap()
        let name = app.textFields["diary-name"]
        XCTAssertTrue(name.waitForExistence(timeout: 3))
        name.tap()
        name.typeText(title + "\n")
        tap("creation-submit", in: app)
        waitForLibrary(in: app)
        let card = app.buttons.matching(NSPredicate(format: "label CONTAINS %@", title)).firstMatch
        XCTAssertTrue(card.waitForExistence(timeout: 5))
        card.tap()
        let page = app.buttons["reading-page-1"]
        XCTAssertTrue(page.waitForExistence(timeout: 3))
        XCTAssertFalse(app.buttons["reading-previous"].isEnabled)
        XCTAssertFalse(app.buttons["reading-next"].isEnabled)
        app.buttons["reading-toggle-bookmark"].tap()
        let bookmarked = NSPredicate(format: "label CONTAINS %@", "해제")
        expectation(for: bookmarked, evaluatedWith: app.buttons["reading-toggle-bookmark"])
        waitForExpectations(timeout: 5)
        app.buttons["reading-contents"].tap()
        XCTAssertTrue(app.buttons["reading-jump-1"].waitForExistence(timeout: 3))
        app.buttons["reading-jump-1"].tap()
        XCUIDevice.shared.orientation = .landscapeLeft
        XCTAssertTrue(page.waitForExistence(timeout: 3))
        XCTAssertEqual(app.staticTexts["reading-position"].label, "1 / 1페이지")
        app.buttons["close-reader"].tap()
        app.terminate()
        app.launch()
        waitForLibrary(in: app)
        XCTAssertTrue(card.waitForExistence(timeout: 5))
        card.tap()
        XCTAssertTrue(app.buttons["reading-bookmarks"].waitForExistence(timeout: 3))
        app.buttons["reading-bookmarks"].tap()
        XCTAssertTrue(app.buttons["reading-jump-1"].waitForExistence(timeout: 3))
        app.buttons["reading-jump-1"].tap()
        app.buttons["reading-toggle-bookmark"].tap()
        let removed = NSPredicate(format: "label CONTAINS %@", "추가")
        expectation(for: removed, evaluatedWith: app.buttons["reading-toggle-bookmark"])
        waitForExpectations(timeout: 5)
    }

    @MainActor
    func testPortraitAndLandscapeNavigation() {
        let app = XCUIApplication()
        XCUIDevice.shared.orientation = .portrait
        app.launch()
        waitForLibrary(in: app)
        app.buttons["create-diary"].tap()
        XCTAssertTrue(app.buttons["creation-back"].waitForExistence(timeout: 3))
        XCUIDevice.shared.orientation = .landscapeLeft
        tap("paper-grid", in: app)
        XCUIDevice.shared.orientation = .portrait
        tap("creation-back", in: app)
        XCTAssertTrue(app.buttons["create-diary"].exists)
    }

    @MainActor
    func testSidebarCanCollapseExpandAndShowMarketNotice() {
        let app = XCUIApplication()
        XCUIDevice.shared.orientation = .landscapeLeft
        defer { XCUIDevice.shared.orientation = .portrait }
        app.launch()
        waitForLibrary(in: app)
        let toggle = app.buttons["sidebar-toggle"]
        XCTAssertTrue(toggle.waitForExistence(timeout: 5))
        let diaries = app.buttons["sidebar-diaries"]
        let expandedWidth = diaries.frame.width
        toggle.tap()
        XCTAssertEqual(toggle.value as? String, "접힘")
        XCTAssertLessThan(diaries.frame.width, expandedWidth)
        for id in ["diaries", "freeGoods", "myGoods", "market", "settings"] {
            XCTAssertTrue(app.buttons["sidebar-\(id)"].isHittable)
        }
        app.buttons["sidebar-market"].tap()
        XCTAssertTrue(app.alerts["마켓"].waitForExistence(timeout: 3))
        app.alerts["마켓"].buttons["확인"].tap()
        toggle.tap()
        XCTAssertEqual(toggle.value as? String, "펼쳐짐")
        XCTAssertEqual(diaries.frame.width, expandedWidth, accuracy: 1)
        XCTAssertTrue(app.buttons["create-diary"].exists)
    }

    @MainActor
    private func waitForLibrary(in app: XCUIApplication) {
        let create = app.buttons["create-diary"]
        XCTAssertTrue(create.waitForExistence(timeout: 10))
        let ready = NSPredicate(format: "enabled == true")
        expectation(for: ready, evaluatedWith: create)
        waitForExpectations(timeout: 10)
    }

    @MainActor
    private func tap(_ identifier: String, in app: XCUIApplication) {
        let button = app.buttons[identifier]
        for _ in 0..<12 {
            if button.isHittable { break }
            app.swipeUp()
        }
        if !button.isHittable {
            for _ in 0..<12 {
                if button.isHittable { break }
                app.swipeDown()
            }
        }
        XCTAssertTrue(button.isHittable, "옵션에 접근할 수 없음: \(identifier)")
        if button.isHittable { button.tap() }
    }
}
