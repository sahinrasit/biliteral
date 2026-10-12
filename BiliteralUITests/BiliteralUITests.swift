import XCTest

final class BiliteralUITests: XCTestCase {
    override func setUp() {
        continueAfterFailure = false
    }

    private func launch(_ arguments: [String]) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-UITest"] + arguments
        app.launch()
        return app
    }

    func testOnboardingOpensTheSampleBook() {
        let app = launch(["-Pro", "NO"])
        let next = app.buttons["onboardingContinue"]
        XCTAssertTrue(next.waitForExistence(timeout: 60))
        next.tap()
        next.tap()
        next.tap()
        XCTAssertTrue(app.buttons["chaptersButton"].waitForExistence(timeout: 60), "Reader with the sample book")
    }

    func testTappingASentenceShowsItsTranslation() {
        let app = launch(["-SkipOnboarding", "-Pro", "YES", "-SeedDemo", "-Screen", "reader"])
        let firstRow = app.descendants(matching: .any)["source-0"]
        XCTAssertTrue(firstRow.waitForExistence(timeout: 60))
        let link = app.links.firstMatch
        XCTAssertTrue(link.waitForExistence(timeout: 60))
        link.tap()
        XCTAssertTrue(app.descendants(matching: .any)["selectedTranslation"].waitForExistence(timeout: 60))
    }

    func testWordLookupCreatesAFlashcard() {
        let app = launch(["-SkipOnboarding", "-Pro", "YES", "-SeedDemo", "-Screen", "word"])
        XCTAssertTrue(app.staticTexts["lookupMeaning"].waitForExistence(timeout: 30))
        app.buttons["addCardButton"].tap()
        XCTAssertTrue(app.buttons["addCardButton"].waitForExistence(timeout: 60))
        XCTAssertFalse(app.buttons["addCardButton"].isEnabled, "Button turns into “Added to flashcards”")
    }

    /// Free tier: one imported book. Pasting a text works, the second import shows the paywall.
    func testSecondImportShowsPaywallForFreeUsers() {
        let app = launch(["-SkipOnboarding", "-Pro", "NO"])
        let paste = app.buttons["importPaste"]
        XCTAssertTrue(paste.waitForExistence(timeout: 60))
        paste.tap()
        let editor = app.textViews["pasteText"]
        XCTAssertTrue(editor.waitForExistence(timeout: 60))
        editor.tap()
        editor.typeText("The quick brown fox jumps over the lazy dog. It was a sunny day in the park.")
        app.navigationBars.buttons.element(boundBy: 1).tap()
        let start = app.buttons["startReading"]
        XCTAssertTrue(start.waitForExistence(timeout: 60))
        start.tap()
        XCTAssertTrue(app.buttons["chaptersButton"].waitForExistence(timeout: 60))
        app.navigationBars.buttons.element(boundBy: 0).tap()

        let add = app.buttons["addBookButton"]
        XCTAssertTrue(add.waitForExistence(timeout: 60))
        add.tap()
        app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'Paste'")).firstMatch.tap()
        XCTAssertTrue(app.buttons["paywallClose"].waitForExistence(timeout: 60))
    }

    func testFlashcardReview() {
        let app = launch(["-SkipOnboarding", "-Pro", "YES", "-SeedDemo", "-Screen", "review"])
        let start = app.buttons["startReview"]
        XCTAssertTrue(start.waitForExistence(timeout: 60))
        start.tap()
        app.buttons["showAnswer"].tap()
        XCTAssertTrue(app.staticTexts["cardMeaning"].waitForExistence(timeout: 60))
        app.buttons["grade-2"].tap()
    }
}
