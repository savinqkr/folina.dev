import XCTest

final class BookshelfUITests: XCTestCase {
    @MainActor
    func testCreationOptionsPreviewAndReturnWithoutSaving() throws {
        let app = XCUIApplication()
        XCUIDevice.shared.orientation = .landscapeLeft
        defer { XCUIDevice.shared.orientation = .portrait }
        app.launch()
        let create = app.buttons["create-diary"]
        XCTAssertTrue(create.waitForExistence(timeout: 5))
        XCTAssertTrue(app.descendants(matching: .any)["sample-seasons"].firstMatch.exists)
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
        tap("creation-submit", in: app)
        let notice = app.alerts["저장 기능 준비 중"]
        XCTAssertTrue(notice.waitForExistence(timeout: 3))
        XCTAssertTrue(notice.staticTexts["현재는 미리보기만 제공해요. 다이어리는 생성되거나 저장되지 않으며 책장에 추가되지 않아요."].exists)
        notice.buttons["계속 꾸미기"].tap()
        tap("creation-back", in: app)
        XCTAssertTrue(create.waitForExistence(timeout: 3))
        XCTAssertFalse(app.staticTexts["여행 일기"].exists)
        create.tap()
        XCTAssertEqual(app.textFields["diary-name"].value as? String, "나의 다이어리")
    }

    @MainActor
    func testPortraitAndLandscapeNavigation() {
        let app = XCUIApplication()
        XCUIDevice.shared.orientation = .portrait
        app.launch()
        app.buttons["create-diary"].tap()
        XCTAssertTrue(app.buttons["creation-back"].waitForExistence(timeout: 3))
        XCUIDevice.shared.orientation = .landscapeLeft
        tap("paper-grid", in: app)
        XCUIDevice.shared.orientation = .portrait
        tap("creation-back", in: app)
        XCTAssertTrue(app.buttons["create-diary"].exists)
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
