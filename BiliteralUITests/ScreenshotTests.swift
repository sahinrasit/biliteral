import XCTest

/// Captures the App Store screenshots listed in the launch plan (§12). Run with `fastlane screenshots`.
@MainActor
final class ScreenshotTests: XCTestCase {
    override func setUp() {
        continueAfterFailure = false
    }

    private func launch(_ arguments: [String]) -> XCUIApplication {
        let app = XCUIApplication()
        setupSnapshot(app)
        app.launchArguments += ["-UITest", "-SeedDemo"] + arguments
        app.launch()
        return app
    }

    private func waitForReader(_ app: XCUIApplication) {
        XCTAssertTrue(app.buttons["chaptersButton"].waitForExistence(timeout: 60))
        sleep(2)
    }

    func test01TwoLanguages() {
        let app = launch(["-SkipOnboarding", "-Pro", "YES", "-Theme", "paper", "-Screen", "reader"])
        waitForReader(app)
        snapshot("01-two-languages")
    }

    func test02Alignment() {
        let app = launch(["-SkipOnboarding", "-Pro", "YES", "-Screen", "select"])
        waitForReader(app)
        XCTAssertTrue(app.otherElements["sentenceBar"].waitForExistence(timeout: 60) || app.staticTexts["selectedTranslation"].exists)
        snapshot("02-alignment")
    }

    func test03Import() {
        let app = launch(["-SkipOnboarding", "-Pro", "NO"])
        XCTAssertTrue(app.buttons["importPaste"].waitForExistence(timeout: 60))
        sleep(1)
        snapshot("03-import")
    }

    func test04Word() {
        let app = launch(["-SkipOnboarding", "-Pro", "YES", "-Screen", "word"])
        XCTAssertTrue(app.staticTexts["lookupMeaning"].waitForExistence(timeout: 60))
        sleep(1)
        snapshot("04-word")
    }

    func test05Flashcards() {
        let app = launch(["-SkipOnboarding", "-Pro", "YES", "-Screen", "review"])
        let start = app.buttons["startReview"]
        XCTAssertTrue(start.waitForExistence(timeout: 60))
        start.tap()
        let show = app.buttons["showAnswer"]
        XCTAssertTrue(show.waitForExistence(timeout: 60))
        show.tap()
        XCTAssertTrue(app.staticTexts["cardMeaning"].waitForExistence(timeout: 60))
        sleep(1)
        snapshot("05-flashcards")
    }

    func test06Offline() {
        let app = launch(["-Pro", "YES"])
        let next = app.buttons["onboardingContinue"]
        XCTAssertTrue(next.waitForExistence(timeout: 60))
        next.tap()
        next.tap()
        sleep(1)
        snapshot("06-offline")
    }

    func test07EveryScreen() {
        let app = launch(["-SkipOnboarding", "-Pro", "YES", "-Theme", "night", "-Layout", "single", "-Screen", "reader"])
        waitForReader(app)
        snapshot("07-every-screen")
    }

    func test08Paywall() {
        let app = launch(["-SkipOnboarding", "-Pro", "NO", "-Screen", "paywall"])
        XCTAssertTrue(app.buttons["paywallClose"].waitForExistence(timeout: 60))
        sleep(2)
        snapshot("08-paywall")
    }
}
