import XCTest

final class VisualSmokeTests: XCTestCase {
    func testFurnitureCategoryTabsCanBeRepeated() {
        let app = launch("decorate")
        XCTAssertTrue(app.buttons["침대 추가"].waitForExistence(timeout: 40))
        for _ in 0..<3 {
            for title in ["벽지", "바닥재", "소품", "가구"] {
                let tab = app.buttons[title]
                XCTAssertTrue(tab.waitForExistence(timeout: 10))
                tab.tap()
                XCTAssertEqual(app.state, .runningForeground)
            }
            XCTAssertTrue(app.buttons["의자 추가"].waitForExistence(timeout: 10))
        }
        app.buttons["의자 추가"].tap()
        let list = app.buttons["가구 목록"]
        XCTAssertTrue(list.waitForExistence(timeout: 10))
        app.buttons["좌우반전"].tap()
        list.tap()
        XCTAssertTrue(app.buttons["가구"].waitForExistence(timeout: 10))
    }

    func testRoomDecoratingCanBeRepeated() {
        let app = launch("tabs-ui")
        for _ in 0..<3 {
            let tools = app.buttons["방 도구"]
            XCTAssertTrue(tools.waitForExistence(timeout: 40))
            let loading = app.staticTexts["포근한 방을 준비하고 있어요"]
            XCTAssertTrue(loading.waitForNonExistence(timeout: 40))
            tools.tap()
            app.buttons["방 꾸미기"].tap()
            let done = app.buttons["꾸미기 완료"]
            XCTAssertTrue(done.waitForExistence(timeout: 40))
            XCTAssertTrue(app.buttons["침대 추가"].waitForExistence(timeout: 20))
            XCTAssertEqual(app.state, .runningForeground)
            done.tap()
        }
        XCTAssertTrue(app.buttons["방 도구"].waitForExistence(timeout: 40))
    }

    private func launch(_ route: String) -> XCUIApplication {
        continueAfterFailure = false
        let app = XCUIApplication(bundleIdentifier: "com.nayeon.Malrang")
        app.launchArguments = ["--design-preview=" + route, "--room-hour=13", "--focus-doll=bear"]
        app.launch()
        return app
    }
    private func launch(_ route: String) -> XCUIApplication {
        continueAfterFailure = false
        let app = XCUIApplication(bundleIdentifier: "com.nayeon.Malrang")
        app.launchArguments = ["--design-preview=" + route, "--room-hour=13", "--focus-doll=bear"]
        app.launch()
        return app
    }
    func testBlockedPlacementCannotComplete() {
        let app = XCUIApplication(bundleIdentifier: "com.nayeon.Malrang")
        app.launchArguments = ["--design-preview=tabs-ui", "--furniture-preview=placement", "--blocked-preview", "--room-hour=13"]
        app.launch()
        let done = app.buttons["완료"]
        XCTAssertTrue(done.waitForExistence(timeout: 40))
        XCTAssertTrue(app.staticTexts["책상에는 이동시킬 수 없어요"].waitForExistence(timeout: 10))
        XCTAssertFalse(done.isEnabled)
        XCTAssertTrue(app.buttons["취소"].isEnabled)
    }
    func testRadioActionsStayInsideScreen() {
        let app = launch("radio-playing")
        let timer = app.buttons["타이머 변경"]
        XCTAssertTrue(timer.waitForExistence(timeout: 20))
        XCTAssertTrue(timer.isHittable)
        XCTAssertLessThan(timer.frame.maxY, app.frame.maxY - 34)
        XCTAssertTrue(app.buttons["다른 소리"].isHittable)
    }
    func testCouchMiniOpensFullPlayer() {
        let app = XCUIApplication(bundleIdentifier: "com.nayeon.Malrang")
        app.launchArguments = ["--design-preview=tabs-ui", "--furniture-preview=couch-mini", "--room-hour=13"]
        app.launch()
        let open = app.buttons["소파에서 크게 보기"]
        XCTAssertTrue(open.waitForExistence(timeout: 40))
        XCTAssertTrue(open.isHittable)
        open.tap()
        XCTAssertTrue(app.staticTexts["couch time"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.buttons["홈에서 계속 보기"].isHittable)
    }
    func testActualCreationExitCanStay() {
        let app = launch("photo-flow")
        let back = app.buttons["인형 만들기 나가기"]
        XCTAssertTrue(back.waitForExistence(timeout: 30))
        XCTAssertTrue(back.isHittable)
        back.tap()
        let title = app.staticTexts["인형 만들기를 그만할까요?"]
        XCTAssertTrue(title.waitForExistence(timeout: 5))
        app.buttons["머무르기"].tap()
        XCTAssertFalse(title.exists)
        XCTAssertTrue(back.isHittable)
    }
    func testPhotoPickerNotice() {
        let app = launch("photo-pick")
        let notice = app.buttons["확인"]
        if notice.waitForExistence(timeout: 12) { notice.tap() }
        XCTAssertTrue(app.buttons["이 사진으로 만들기"].waitForExistence(timeout: 10))
        let shot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        shot.lifetime = .keepAlways
        add(shot)
    }
    func testPlacementExitCanStay() {
        let app = XCUIApplication(bundleIdentifier: "com.nayeon.Malrang")
        app.launchArguments = ["--design-preview=tabs-ui", "--room-hour=13", "--furniture-preview=placement", "--placement-exit-preview"]
        app.launch()
        let title = app.staticTexts["인형 만들기를 그만할까요?"]
        XCTAssertTrue(title.waitForExistence(timeout: 40))
        if app.buttons["배치 취소"].exists { XCTAssertFalse(app.buttons["배치 취소"].isEnabled) }
        app.buttons["머무르기"].tap()
        XCTAssertTrue(app.buttons["배치 취소"].waitForExistence(timeout: 5))
        XCTAssertFalse(title.exists)
    }
    func testWallPhotoActionsAreVisible() {
        let app = launch("wall-photo")
        let remove = app.buttons["사진 빼기"]
        XCTAssertTrue(remove.waitForExistence(timeout: 30))
        XCTAssertTrue(remove.isHittable)
        XCTAssertLessThan(remove.frame.maxY, app.frame.maxY - 34)
        XCTAssertTrue(app.buttons["사진 바꾸기"].isHittable)
        remove.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.85)).tap()
        XCTAssertTrue(app.staticTexts["사진 추가하기"].waitForExistence(timeout: 5))
    }
    func testDeskPhotoActionsAfterLayoutCorrection() {
        let app = launch("desk-photo")
        let remove = app.buttons["사진 빼기"]
        XCTAssertTrue(remove.waitForExistence(timeout: 30))
        XCTAssertTrue(remove.isHittable)
        XCTAssertTrue(app.buttons["사진 바꾸기"].isHittable)
        XCTAssertGreaterThanOrEqual(remove.frame.height, 59)
        XCTAssertLessThan(remove.frame.maxY, app.frame.maxY - 34)
        remove.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.85)).tap()
        XCTAssertTrue(app.staticTexts["사진 추가하기"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.staticTexts["적용된 사진"].exists)
    }
    func testDollPartSlider() {
        let app = launch("create-parts")
        let slider = app.sliders["머리 높이"]
        XCTAssertTrue(slider.waitForExistence(timeout: 30))
        let before = slider.value as? String
        slider.adjust(toNormalizedSliderPosition: 0.85)
        XCTAssertNotEqual(slider.value as? String, before)
        XCTAssertTrue(app.buttons["완성하기"].isHittable)
    }
    func testNameEntryStaysClearOfKeyboardAndFooter() {
        let app = launch("create-name-empty")
        let field = app.textFields.firstMatch
        let finish = app.buttons["완성하기"]
        XCTAssertTrue(field.waitForExistence(timeout: 30))
        XCTAssertTrue(app.keyboards.firstMatch.waitForExistence(timeout: 10))
        XCTAssertFalse(finish.isEnabled)
        field.tap()
        field.typeText("Mimi")
        XCTAssertTrue(finish.isEnabled)
        XCTAssertTrue(finish.isHittable)
        XCTAssertLessThan(field.frame.maxY, finish.frame.minY)
        XCTAssertLessThan(finish.frame.maxY, app.keyboards.firstMatch.frame.minY)
        app.buttons["이전 단계"].tap()
        XCTAssertTrue(app.sliders["머리 높이"].waitForExistence(timeout: 10))
    }
    func testFocusExitCanStay() {
        let app = launch("exit")
        let title = app.staticTexts["집중 화면에서 나갈까요?"]
        XCTAssertTrue(title.waitForExistence(timeout: 30))
        app.buttons["머무르기"].tap()
        XCTAssertFalse(title.exists)
        XCTAssertTrue(app.buttons["일시정지"].waitForExistence(timeout: 5))
    }
    func testFocusPauseResume() {
        let app = launch("running")
        let pause = app.buttons["일시정지"]
        XCTAssertTrue(pause.waitForExistence(timeout: 30))
        pause.tap()
        let resume = app.buttons["집중 이어하기"]
        XCTAssertTrue(resume.waitForExistence(timeout: 5))
        resume.tap()
        XCTAssertTrue(pause.waitForExistence(timeout: 5))
    }
    func testOneCouchCompanion() {
        let app = launch("couch-choice")
        let bear = app.buttons.containing(.staticText, identifier: "몽글이").firstMatch
        let cat = app.buttons.containing(.staticText, identifier: "귀염둥이").firstMatch
        XCTAssertTrue(bear.waitForExistence(timeout: 15))
        bear.tap()
        XCTAssertTrue(bear.isSelected)
        cat.tap()
        XCTAssertTrue(cat.isSelected)
        XCTAssertFalse(bear.isSelected)
        XCTAssertTrue(app.buttons["다음"].isEnabled)
    }
    func testDollDetailHidesTabBar() {
        let app = launch("tabs-profile")
        XCTAssertTrue(app.staticTexts["처음 만난 날"].waitForExistence(timeout: 20))
        XCTAssertFalse(app.buttons["솜뭉치들"].exists)
        XCTAssertFalse(app.buttons["마이"].exists)
        let back = app.buttons["뒤로"]
        XCTAssertTrue(back.isHittable)
        back.tap()
        XCTAssertTrue(app.buttons["인형 만들기"].waitForExistence(timeout: 5))
    }
    func testCouchChoiceFromRoom() {
        continueAfterFailure = false
        let app = XCUIApplication(bundleIdentifier: "com.nayeon.Malrang")
        app.launchArguments = ["--design-preview=tabs-ui", "--furniture-preview=couch-choice", "--room-hour=13"]
        app.launch()
        XCTAssertTrue(app.staticTexts["같이 볼 인형"].waitForExistence(timeout: 30))
        let bear = app.buttons.containing(.staticText, identifier: "몽글이").firstMatch
        XCTAssertTrue(bear.waitForExistence(timeout: 5))
        bear.tap()
        XCTAssertTrue(bear.isSelected)
        app.buttons["다음"].tap()
        XCTAssertTrue(app.staticTexts["couch time"].waitForExistence(timeout: 10))
        XCTAssertFalse(app.staticTexts["같이 볼 인형"].exists)
    }
    func testRadioTimerApply() {
        let app = launch("radio-timer")
        let apply = app.buttons["타이머 적용하기"]
        XCTAssertTrue(apply.waitForExistence(timeout: 20))
        app.buttons["재생 시간 5분 늘리기"].tap()
        XCTAssertTrue(app.staticTexts["35"].exists)
        apply.tap()
        XCTAssertTrue(app.buttons["타이머 변경"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.staticTexts["지금부터 남은 시간"].exists)
    }
    func testRadioSoundSheetDismissAndReopen() {
        let app = launch("radio-sound")
        let title = app.staticTexts["듣고 싶은 소리를 골라주세요"]
        XCTAssertTrue(title.waitForExistence(timeout: 20))
        title.swipeDown()
        XCTAssertTrue(app.buttons["다른 소리"].waitForExistence(timeout: 5))
        app.buttons["다른 소리"].tap()
        XCTAssertTrue(title.waitForExistence(timeout: 5))
        let fire = app.buttons.containing(.staticText, identifier: "모닥불").firstMatch
        fire.tap()
        app.buttons["타이머 적용하기"].tap()
        XCTAssertTrue(app.staticTexts["모닥불"].waitForExistence(timeout: 5))
        XCTAssertFalse(title.exists)
    }
}
