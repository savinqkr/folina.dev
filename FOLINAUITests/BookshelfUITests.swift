import XCTest

final class BookshelfUITests: XCTestCase {
    @MainActor
    func testBookshelfAndCreationNoticeDoNotCreateDiary() throws {
        let app = XCUIApplication()
        app.launch()

        for id in ["sample-seasons", "sample-daily", "sample-bullet"] {
            let card = app.descendants(matching: .any)[id].firstMatch
            for _ in 0..<6 {
                if card.exists { break }
                app.swipeUp()
            }
            XCTAssertTrue(card.waitForExistence(timeout: 5), "샘플 누락: \(id)")
        }
        for _ in 0..<6 {
            if app.buttons["create-diary"].isHittable { break }
            app.swipeDown()
        }
        let create = app.buttons["create-diary"]
        XCTAssertTrue(create.waitForExistence(timeout: 5))
        create.tap()
        let alert = app.alerts["새 다이어리 만들기"]
        XCTAssertTrue(alert.waitForExistence(timeout: 3))
        XCTAssertTrue(alert.staticTexts["다이어리 생성 기능은 준비 중이에요."].exists)
        alert.buttons["확인"].tap()
        XCTAssertFalse(alert.exists)
        XCTAssertTrue(create.exists)
    }
}
