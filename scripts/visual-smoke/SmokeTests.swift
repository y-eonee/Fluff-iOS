import XCTest

final class VisualSmokeTests: XCTestCase {
    override func setUp() {
        super.setUp()
        XCUIDevice.shared.orientation = .portrait
    }

    func testPreloginSplashHandsOffToAppleSignIn() {
        continueAfterFailure = false
        let app = XCUIApplication(bundleIdentifier: "com.nayeon.Malrang")
        app.launchArguments = ["--onboarding-preview", "--reset-onboarding-preview", "--show-startup-splash", "-isSignedIn", "NO"]
        app.launch()
        let splash = app.otherElements["prelogin-splash"]
        XCTAssertTrue(splash.waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["apple-sign-in"].exists, "Sign-in must stay hidden during startup")
        let first = XCTAttachment(screenshot: app.screenshot())
        first.name = "prelogin-five-icons-live"
        first.lifetime = .keepAlways
        add(first)
        XCUIDevice.shared.press(.home)
        app.activate()
        XCTAssertTrue(splash.exists, "Foregrounding must resume the splash")
        XCTAssertTrue(splash.waitForNonExistence(timeout: 15))
        XCTAssertTrue(app.buttons["apple-sign-in"].waitForExistence(timeout: 3))
        XCTAssertFalse(app.otherElements["room-loading"].exists)
        let login = XCTAttachment(screenshot: app.screenshot())
        login.name = "prelogin-apple-sign-in"
        login.lifetime = .keepAlways
        add(login)
    }

    func testPreloginSplashDesignPhases() {
        let app = XCUIApplication(bundleIdentifier: "com.nayeon.Malrang")
        for (index, time) in [0.35, 0.81, 1.27, 1.73, 2.19].enumerated() {
            app.launchArguments = ["--design-preview=prelogin-splash", "--splash-time=\(time)"]
            app.launch()
            XCTAssertTrue(app.otherElements["prelogin-splash"].waitForExistence(timeout: 5))
            let frame = XCTAttachment(screenshot: app.screenshot())
            frame.name = "prelogin-jump-\(index + 1)"
            frame.lifetime = .keepAlways
            add(frame)
            app.terminate()
        }
    }
    func testProductionHomeStartupAndTabReturns() {
        continueAfterFailure = false
        let app = XCUIApplication(bundleIdentifier: "com.nayeon.Malrang")
        // Exercise RootView and the real startup gate, without a design-preview route.
        app.launchArguments = ["-isSignedIn", "YES", "-didSeeFurnitureGuideV2", "YES", "--ui-testing"]
        app.launch()
        waitForHomeControls(app)
        XCTAssertTrue(app.otherElements["room-loading"].waitForNonExistence(timeout: 20))
        for title in ["내 인형", "마이", "내 인형", "마이"] {
            app.buttons[title].tap()
            app.buttons["내 방"].tap()
            waitForHomeControls(app)
            XCTAssertTrue(app.otherElements["room-loading"].waitForNonExistence(timeout: 20))
            app.buttons["방 도구"].tap()
            XCTAssertTrue(app.buttons["방 꾸미기"].waitForExistence(timeout: 5))
            app.buttons["방 도구 닫기"].tap()
        }
        XCUIDevice.shared.press(.home)
        app.activate()
        waitForHomeControls(app)
        XCTAssertTrue(app.otherElements["room-loading"].waitForNonExistence(timeout: 20))
        captureUpdatedLoading(app, "production-home-after-tab-returns")
    }

    func testRoomLoadingPreviewAndLiveHandoff() {
        continueAfterFailure = false
        let app = XCUIApplication(bundleIdentifier: "com.nayeon.Malrang")
        app.launchArguments = ["--design-preview=room-loading", "--room-loading-time=0.45"]
        app.launch()
        XCTAssertTrue(app.otherElements["room-loading"].waitForExistence(timeout: 20))
        let loading = XCTAttachment(screenshot: app.screenshot())
        loading.name = "room-loading-breathing"
        loading.lifetime = .keepAlways
        add(loading)
        app.terminate()
        app.launchArguments = ["--design-preview=tabs-ui", "--room-hour=13"]
        app.launch()
        XCTAssertTrue(app.otherElements["room-loading"].waitForNonExistence(timeout: 60))
        let tools = app.buttons["방 도구"]
        XCTAssertTrue(tools.waitForExistence(timeout: 10))
        XCTAssertTrue(tools.isHittable)
        tools.tap()
        app.buttons["방 꾸미기"].tap()
        XCTAssertTrue(app.otherElements["decorate-loading"].waitForNonExistence(timeout: 60))
        let done = app.buttons["꾸미기 완료"]
        XCTAssertTrue(done.waitForExistence(timeout: 30))
        let ready = XCTNSPredicateExpectation(predicate: NSPredicate(format: "hittable == true"), object: done)
        XCTAssertEqual(XCTWaiter.wait(for: [ready], timeout: 10), .completed)
        done.tap()
        XCTAssertTrue(tools.waitForExistence(timeout: 30))
        XCTAssertTrue(app.otherElements["room-loading"].waitForNonExistence(timeout: 30))
    }

    private func captureUpdatedLoading(_ app: XCUIApplication, _ name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name; attachment.lifetime = .keepAlways; add(attachment)
    }

    func testLoadingUsesOwnedDollOrCottonForEmptyRoom() {
        let app = XCUIApplication(bundleIdentifier: "com.nayeon.Malrang")
        app.launchArguments = ["--design-preview=room-loading", "--room-loading-time=0.45"]
        app.launch()
        let loading = app.otherElements["room-loading"]
        XCTAssertTrue(loading.waitForExistence(timeout: 30))
        let selected = loading.value as? String ?? ""
        XCTAssertTrue(["귀염둥이", "몽글이", "포근이"].contains(selected))
        Thread.sleep(forTimeInterval: 3)
        XCTAssertEqual(loading.value as? String, selected)
        captureUpdatedLoading(app, "loading-owned-doll")
        app.terminate()
        app.launchArguments = ["--design-preview=room-loading", "--room-loading-time=0.45", "--loading-empty-room"]
        app.launch()
        XCTAssertTrue(loading.waitForExistence(timeout: 30))
        XCTAssertEqual(loading.value as? String, "솜뭉치")
        Thread.sleep(forTimeInterval: 3)
        captureUpdatedLoading(app, "loading-cotton")
    }

    func testSleepingDollLoadingHidesSleepIndicatorAndPreservesRest() {
        continueAfterFailure = false
        let app = XCUIApplication(bundleIdentifier: "com.nayeon.Malrang")
        let fixture = ["--room-hour=20", "--loading-doll=cat", "--sleep-shape=cat", "--bed-occupied"]
        app.launchArguments = ["--design-preview=room-loading", "--room-loading-time=0.45"] + fixture
        app.launch()
        XCTAssertTrue(app.otherElements["room-loading"].waitForExistence(timeout: 30))
        XCTAssertEqual(app.otherElements["room-loading"].value as? String, "귀염둥이")
        XCTAssertFalse(app.staticTexts["z z Z"].exists)
        captureUpdatedLoading(app, "loading-sleeping-doll-awake")
        app.terminate()
        app.launchArguments = ["--design-preview=tabs-ui"] + fixture
        app.launch()
        waitForHomeControls(app)
        XCTAssertTrue(app.staticTexts["z z Z"].waitForExistence(timeout: 10), "The doll must still be sleeping in the room after loading")
        captureUpdatedLoading(app, "loading-sleep-state-restored")
    }

    func testRightWallPhotoIsIndependentAndUndoable() {
        continueAfterFailure = false
        let app = XCUIApplication(bundleIdentifier: "com.nayeon.Malrang")
        app.launchArguments = ["--design-preview=wall-photo", "--both-wall-photos", "--room-hour=13"]
        app.launch()
        XCTAssertTrue(app.buttons["오른쪽 벽"].waitForExistence(timeout: 40))
        XCTAssertTrue(app.otherElements["decorate-loading"].waitForNonExistence(timeout: 60))
        let right = app.buttons["오른쪽 벽"]
        let ready = XCTNSPredicateExpectation(predicate: NSPredicate(format: "enabled == true AND hittable == true"), object: right)
        XCTAssertEqual(XCTWaiter.wait(for: [ready], timeout: 10), .completed)
        right.tap()
        XCTAssertTrue(right.isSelected)
        XCTAssertTrue(app.staticTexts["적용된 사진"].waitForExistence(timeout: 5))
        captureUpdatedLoading(app, "right-wall-photo-applied")
        app.buttons["사진 빼기"].tap()
        XCTAssertTrue(app.staticTexts["오른쪽 벽에서 사진을 뺄까요?"].waitForExistence(timeout: 5))
        app.buttons["빼기"].tap()
        XCTAssertTrue(app.buttons["사진 추가하기"].waitForExistence(timeout: 5))
        app.buttons["왼쪽 벽"].tap()
        XCTAssertTrue(app.staticTexts["적용된 사진"].waitForExistence(timeout: 5))
        app.buttons["오른쪽 벽"].tap()
        app.buttons["되돌리기"].tap()
        XCTAssertTrue(app.staticTexts["적용된 사진"].waitForExistence(timeout: 5))
        app.buttons["컬러"].tap()
        app.buttons["라벤더"].tap()
        app.buttons["사진"].tap()
        XCTAssertTrue(app.buttons["사진 추가하기"].waitForExistence(timeout: 5))
        app.buttons["왼쪽 벽"].tap()
        XCTAssertTrue(app.staticTexts["적용된 사진"].waitForExistence(timeout: 5))
    }

    func testFurniturePhotoRemovalConfirmationAndUndo() {
        let app = launch("desk-photo")
        let remove = app.buttons["사진 빼기"]
        XCTAssertTrue(remove.waitForExistence(timeout: 30))
        remove.tap()
        XCTAssertTrue(app.staticTexts["책상에서 사진을 뺄까요?"].waitForExistence(timeout: 5))
        captureUpdatedLoading(app, "room-photo-removal")
        app.buttons["취소"].tap()
        XCTAssertTrue(app.staticTexts["적용된 사진"].exists)
        remove.tap()
        app.buttons["빼기"].tap()
        XCTAssertTrue(app.buttons["사진 추가하기"].waitForExistence(timeout: 5))
        app.buttons["되돌리기"].tap()
        XCTAssertTrue(app.staticTexts["적용된 사진"].waitForExistence(timeout: 5))
    }

    func testDecoratePreservesHomeFurniturePlacements() {
        continueAfterFailure = false
        let app = XCUIApplication(bundleIdentifier: "com.nayeon.Malrang")
        app.launchArguments = ["--design-preview=tabs-ui", "--room-hour=13", "--room-layout-audit"]
        app.launch()
        waitForHomeControls(app)
        let audit = app.staticTexts["room-layout-audit"]
        XCTAssertTrue(audit.waitForExistence(timeout: 10))
        func furnitureSnapshot() -> String? {
            guard let value = audit.value as? String, let data = value.data(using: .utf8),
                  let placements = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] else { return nil }
            let furniture = placements.filter { !["wall", "floor"].contains($0["kind"] as? String ?? "") }.map { placement in
                var transform = placement
                // Bounds are measured lazily; compare the saved/rendered transforms
                // separately from the explicit rug-containment assertions below.
                transform.removeValue(forKey: "footprint")
                return transform
            }
            return (try? JSONSerialization.data(withJSONObject: furniture, options: [.sortedKeys])).flatMap { String(data: $0, encoding: .utf8) }
        }
        let home = furnitureSnapshot()
        XCTAssertNotNil(home)
        XCTAssertFalse(home?.isEmpty ?? true)
        func assertRugsInsideRoom() {
            let placements = try! JSONSerialization.jsonObject(with: Data((audit.value as! String).utf8)) as! [[String: Any]]
            let rugs = placements.filter { ["rugRound", "rugSquare"].contains($0["kind"] as? String ?? "") }
            XCTAssertFalse(rugs.isEmpty)
            for rug in rugs {
                let footprint = rug["footprint"] as! [Double]
                XCTAssertGreaterThanOrEqual(footprint[0], -1.001)
                XCTAssertGreaterThanOrEqual(footprint[1], -1.001)
                XCTAssertLessThanOrEqual(footprint[2], 1.001)
                XCTAssertLessThanOrEqual(footprint[3], 1.001)
            }
        }
        assertRugsInsideRoom()
        captureUpdatedLoading(app, "layout-home-before")
        app.buttons["방 도구"].tap()
        app.buttons["방 꾸미기"].tap()
        let done = app.buttons["꾸미기 완료"]
        XCTAssertTrue(done.waitForExistence(timeout: 60))
        let ready = XCTNSPredicateExpectation(predicate: NSPredicate(format: "hittable == true"), object: done)
        XCTAssertEqual(XCTWaiter.wait(for: [ready], timeout: 60), .completed)
        XCTAssertTrue(audit.waitForExistence(timeout: 10))
        XCTAssertEqual(furnitureSnapshot(), home, "Opening the editor must preserve every saved and rendered furniture transform")
        assertRugsInsideRoom()
        XCTAssertFalse(app.buttons["초기화"].isEnabled)
        XCTAssertFalse(app.buttons["되돌리기"].isEnabled)
        captureUpdatedLoading(app, "layout-editor-unchanged")
        done.tap()
        waitForHomeControls(app)
        XCTAssertTrue(audit.waitForExistence(timeout: 10))
        XCTAssertEqual(furnitureSnapshot(), home, "Completing without edits must not change the home layout")
        captureUpdatedLoading(app, "layout-home-after")
    }

    func testBackWallDeskRestorationDoesNotRepeat() {
        continueAfterFailure = false
        let app = XCUIApplication(bundleIdentifier: "com.nayeon.Malrang")
        let args = ["--design-preview=tabs-ui", "--room-hour=13", "--room-layout-audit", "--desk-restoration-preview"]
        for alreadyComplete in [false, true] {
            app.launchArguments = args + (alreadyComplete ? ["--desk-restoration-already-complete"] : [])
            app.launch()
            waitForHomeControls(app)
            let audit = app.staticTexts["room-layout-audit"]
            XCTAssertTrue(audit.waitForExistence(timeout: 10))
            let items = try! JSONSerialization.jsonObject(with: Data((audit.value as! String).utf8)) as! [[String: Any]]
            let desk = items.first { $0["kind"] as? String == "desk" }!["saved"] as! [Double]
            let lamp = items.first { $0["kind"] as? String == "lamp" }!["saved"] as! [Double]
            XCTAssertEqual(desk[0], alreadyComplete ? 0.55 : 0.25, accuracy: 0.0001)
            XCTAssertEqual(desk[1], alreadyComplete ? -0.30 : -0.68, accuracy: 0.0001)
            XCTAssertEqual(lamp[0], alreadyComplete ? 0.70 : 0.40, accuracy: 0.0001)
            XCTAssertEqual(lamp[1], alreadyComplete ? -0.18 : -0.56, accuracy: 0.0001)
            if !alreadyComplete { captureUpdatedLoading(app, "desk-restored-back-wall") }
            app.terminate()
        }
    }

    func testFurnitureCategoryTabsCanBeRepeated() {
        let app = launch("decorate")
        let bed = app.buttons["침대 추가"]
        XCTAssertTrue(bed.waitForExistence(timeout: 40))
        let ready = XCTNSPredicateExpectation(predicate: NSPredicate(format: "hittable == true"), object: bed)
        XCTAssertEqual(XCTWaiter.wait(for: [ready], timeout: 40), .completed)
        XCTAssertFalse(app.buttons["되돌리기"].isEnabled)
        XCTAssertFalse(app.buttons["초기화"].isEnabled)
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

    func testFirstRoomGuideHidesTabBarUntilDismissed() {
        let app = XCUIApplication(bundleIdentifier: "com.nayeon.Malrang")
        app.launchArguments = ["--design-preview=tabs-ui", "--room-hour=13", "--furniture-preview=guide"]
        app.launch()
        let done = app.buttons["확인했어요"]
        XCTAssertTrue(done.waitForExistence(timeout: 40))
        for title in ["내 인형", "내 방", "마이", "방 도구"] {
            XCTAssertFalse(app.buttons[title].exists, title)
        }
        done.tap()
        XCTAssertTrue(app.buttons["방 도구"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.buttons["내 인형"].exists)
        XCTAssertTrue(app.buttons["마이"].exists)
    }

    func testRoomToolsStayAboveActionButton() {
        let app = launch("tabs-ui")
        waitForHomeControls(app)
        let tools = app.buttons["방 도구"]
        XCTAssertTrue(tools.waitForExistence(timeout: 40))
        tools.tap()
        let close = app.buttons["방 도구 닫기"]
        let sound = app.buttons["ASMR"]
        XCTAssertTrue(sound.waitForExistence(timeout: 10))
        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = "room-tools-spacing"
        screenshot.lifetime = .keepAlways
        add(screenshot)
        for title in ["인형 만들기", "방 꾸미기", "ASMR"] {
            let button = app.buttons[title]
            XCTAssertTrue(button.isHittable)
            XCTAssertLessThanOrEqual(button.frame.maxY, close.frame.minY - 8, title)
        }
        XCTAssertTrue(app.staticTexts["포근한 방을 준비하고 있어요"].waitForNonExistence(timeout: 40))
        XCTAssertLessThanOrEqual(sound.frame.maxY, close.frame.minY - 8)
        let loaded = XCTAttachment(screenshot: app.screenshot())
        loaded.name = "room-tools-after-loading"
        loaded.lifetime = .keepAlways
        add(loaded)
        close.tap()
        XCTAssertFalse(sound.exists)
    }

    func testRoomDecoratingCanBeRepeated() {
        let app = launch("tabs-ui")
        XCTAssertTrue(app.otherElements["room-loading"].waitForNonExistence(timeout: 60))
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

    func testDollTouchDoesNotOpenFunctionMenu() {
        let app = launch("tabs-profile")
        XCTAssertTrue(app.staticTexts["처음 만난 날"].waitForExistence(timeout: 20))
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.38)).press(forDuration: 1.2)
        XCTAssertFalse(app.buttons["인형 삭제"].exists)
        XCTAssertFalse(app.buttons["예절샷 찍기"].exists)
        XCTAssertTrue(app.buttons["뒤로"].isHittable)
        captureUpdatedLoading(app, "profile-after-long-press")
    }

    func testSliderCanLeaveBothEndpointsWithOneDrag() {
        let app = launch("create-parts")
        let slider = app.sliders["머리 높이"]
        XCTAssertTrue(slider.waitForExistence(timeout: 30))
        slider.adjust(toNormalizedSliderPosition: 0)
        let lower = slider.value as? String
        // Start just outside the endpoint, within the expanded thumb target.
        slider.coordinate(withNormalizedOffset: CGVector(dx: 0, dy: 0.5))
            .withOffset(CGVector(dx: -8, dy: 0))
            .press(forDuration: 0.1, thenDragTo: slider.coordinate(withNormalizedOffset: CGVector(dx: 0.4, dy: 0.5)))
        XCTAssertNotEqual(slider.value as? String, lower)
        slider.adjust(toNormalizedSliderPosition: 1)
        let upper = slider.value as? String
        slider.coordinate(withNormalizedOffset: CGVector(dx: 1, dy: 0.5))
            .withOffset(CGVector(dx: 8, dy: 0))
            .press(forDuration: 0.1, thenDragTo: slider.coordinate(withNormalizedOffset: CGVector(dx: 0.6, dy: 0.5)))
        XCTAssertNotEqual(slider.value as? String, upper)
        captureUpdatedLoading(app, "slider-endpoint-drag")
    }

    func testDecorateShowsCottonLoadingBeforeEditor() {
        let app = launch("decorate")
        let loading = app.otherElements["decorate-loading"]
        XCTAssertTrue(loading.waitForExistence(timeout: 30))
        XCTAssertEqual(loading.value as? String, "솜뭉치")
        captureUpdatedLoading(app, "decorate-cotton-loading")
        XCTAssertTrue(loading.waitForNonExistence(timeout: 60))
        let done = app.buttons["꾸미기 완료"]
        XCTAssertTrue(done.waitForExistence(timeout: 10))
        let ready = XCTNSPredicateExpectation(predicate: NSPredicate(format: "hittable == true"), object: done)
        XCTAssertEqual(XCTWaiter.wait(for: [ready], timeout: 10), .completed)
        captureUpdatedLoading(app, "decorate-ready")
    }

    func testUpdatedTabsAndBoundedRoomRotation() {
        let app = launch("tabs-dolls")
        XCTAssertTrue(app.buttons["인형 만들기"].waitForExistence(timeout: 20))
        XCTAssertTrue(app.buttons["내 인형"].isSelected)
        captureUpdatedLoading(app, "updated-doll-list-tabs")
        app.buttons["내 방"].tap()
        waitForHomeControls(app)
        XCTAssertTrue(app.buttons["내 방"].isSelected)
        app.rotate(.pi * 1.25, withVelocity: 4)
        captureUpdatedLoading(app, "room-rotation-left-limit")
        app.rotate(-.pi * 2, withVelocity: -4)
        captureUpdatedLoading(app, "room-rotation-right-limit")
        XCTAssertTrue(app.buttons["방 도구"].isHittable)
    }

    func testHomeBecomesReadyAfterReturning() {
        let app = launch("tabs-ui")
        func assertHomeReady() {
            waitForHomeControls(app)
            XCTAssertTrue(app.staticTexts["포근한 방을 준비하고 있어요"].waitForNonExistence(timeout: 20))
            let doll = app.buttons["귀염둥이"]
            XCTAssertTrue(doll.waitForExistence(timeout: 20))
            doll.tap()
            XCTAssertTrue(app.buttons["사진 찍기"].waitForExistence(timeout: 5))
            app.buttons["춤추기 닫기"].tap()
        }
        assertHomeReady()
        for title in ["내 인형", "마이", "내 인형"] {
            app.buttons[title].tap()
            app.buttons["내 방"].tap()
            assertHomeReady()
        }
        for _ in 0..<3 {
            app.buttons["방 도구"].tap()
            app.buttons["방 꾸미기"].tap()
            let done = app.buttons["꾸미기 완료"]
            XCTAssertTrue(done.waitForExistence(timeout: 60))
            XCTAssertTrue(app.otherElements["decorate-loading"].waitForNonExistence(timeout: 60))
            let ready = XCTNSPredicateExpectation(predicate: NSPredicate(format: "hittable == true"), object: done)
            XCTAssertEqual(XCTWaiter.wait(for: [ready], timeout: 15), .completed)
            done.tap()
            assertHomeReady()
        }
        XCUIDevice.shared.press(.home)
        app.activate()
        assertHomeReady()
    }

    func testHomeReturnUsesCurrentLoadingUntilSceneIsReady() {
        continueAfterFailure = false
        let app = XCUIApplication(bundleIdentifier: "com.nayeon.Malrang")
        app.launchArguments = ["--design-preview=tabs-ui", "--room-hour=13", "--home-return-loading-preview"]
        app.launch()
        waitForHomeControls(app)
        app.buttons["방 도구"].tap()
        app.buttons["방 꾸미기"].tap()
        let done = app.buttons["꾸미기 완료"]
        XCTAssertTrue(done.waitForExistence(timeout: 60))
        XCTAssertTrue(app.otherElements["decorate-loading"].waitForNonExistence(timeout: 60))
        let ready = XCTNSPredicateExpectation(predicate: NSPredicate(format: "hittable == true"), object: done)
        XCTAssertEqual(XCTWaiter.wait(for: [ready], timeout: 15), .completed)
        done.tap()
        let loading = app.otherElements["room-loading"]
        XCTAssertTrue(loading.waitForExistence(timeout: 3))
        XCTAssertEqual(loading.value as? String, "솜뭉치")
        XCTAssertFalse(app.staticTexts["포근한 방을 준비하고 있어요"].exists)
        captureUpdatedLoading(app, "home-return-current-loading")
        waitForHomeControls(app)
        app.buttons["귀염둥이"].tap()
        XCTAssertTrue(app.buttons["사진 찍기"].waitForExistence(timeout: 5))
        captureUpdatedLoading(app, "home-return-ready")
    }

    private func launch(_ route: String) -> XCUIApplication {
        continueAfterFailure = false
        let app = XCUIApplication(bundleIdentifier: "com.nayeon.Malrang")
        app.launchArguments = ["--design-preview=" + route, "--room-hour=13", "--focus-doll=bear", "--ui-testing"]
        app.launch()
        return app
    }
    func testFreeFloorPlacementDesign() {
        let app = XCUIApplication(bundleIdentifier: "com.nayeon.Malrang")
        app.launchArguments = ["--design-preview=tabs-ui", "--furniture-preview=placement", "--room-hour=13"]
        app.launch()
        XCTAssertTrue(app.staticTexts["인형을 끌거나 놓을 자리를 눌러요."].waitForExistence(timeout: 60))
        let done = app.buttons["완료"]
        XCTAssertTrue(done.isEnabled)
        XCTAssertTrue(app.buttons["취소"].isEnabled)
        XCTAssertFalse(app.buttons["방 도구"].exists)
        captureUpdatedLoading(app, "free-floor-placement")
        app.buttons["취소"].tap()
        XCTAssertTrue(app.buttons["방 도구"].waitForExistence(timeout: 10))
    }

    func testBlockedPlacementCannotComplete() {
        let app = XCUIApplication(bundleIdentifier: "com.nayeon.Malrang")
        app.launchArguments = ["--design-preview=tabs-ui", "--furniture-preview=placement", "--blocked-preview", "--room-hour=13"]
        app.launch()
        let done = app.buttons["완료"]
        XCTAssertTrue(done.waitForExistence(timeout: 40))
        XCTAssertTrue(app.staticTexts["침대 위에는 인형을 놓을 수 없어요."].waitForExistence(timeout: 10))
        XCTAssertFalse(done.isEnabled)
        XCTAssertTrue(app.buttons["취소"].isEnabled)
        captureUpdatedLoading(app, "floor-placement-blocked")
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
        let open = app.buttons["영상 선택하기"]
        XCTAssertTrue(open.waitForExistence(timeout: 40))
        XCTAssertTrue(open.isHittable)
        open.tap()
        XCTAssertTrue(app.staticTexts["플레이리스트"].waitForExistence(timeout: 10))
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
        captureUpdatedLoading(app, "updated-creation-exit-buttons")
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
        XCTAssertTrue(app.buttons["다음"].isHittable)
    }
    func testFillingSelectionBetweenPartsAndName() {
        let app = launch("create-parts")
        XCTAssertTrue(app.sliders["머리 높이"].waitForExistence(timeout: 30))
        app.buttons["다음"].tap()
        XCTAssertTrue(app.staticTexts["속재료 선택하기"].waitForExistence(timeout: 10))
        for title in ["샤베트", "왁스", "슬라임", "크런치"] {
            app.buttons[title].tap()
            XCTAssertTrue(app.buttons[title].isSelected)
        }
        captureUpdatedLoading(app, "filling-outline-icons")
        app.buttons["다음"].tap()
        XCTAssertTrue(app.textFields.firstMatch.waitForExistence(timeout: 10))
        app.buttons["이전"].tap()
        XCTAssertTrue(app.buttons["크런치"].isSelected)
        app.buttons["이전"].tap()
        XCTAssertTrue(app.sliders["머리 높이"].waitForExistence(timeout: 10))
    }
    func testCustomDollIncludesFillingStep() {
        let app = launch("create-filling-custom")
        XCTAssertTrue(app.staticTexts["속재료 선택하기"].waitForExistence(timeout: 30))
        XCTAssertFalse(app.sliders["머리 높이"].exists)
        app.buttons["슬라임"].tap()
        app.buttons["다음"].tap()
        XCTAssertTrue(app.textFields.firstMatch.waitForExistence(timeout: 10))
        app.buttons["이전"].tap()
        XCTAssertTrue(app.buttons["슬라임"].isSelected)
        captureUpdatedLoading(app, "custom-filling-step")
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
        app.buttons["이전"].tap()
        XCTAssertTrue(app.staticTexts["속재료 선택하기"].waitForExistence(timeout: 10))
        app.buttons["이전"].tap()
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
    func testFocusLandscapeKeepsControlsOnLeft() {
        let app = launch("running")
        XCTAssertTrue(app.buttons["일시정지"].waitForExistence(timeout: 30))
        XCUIDevice.shared.orientation = .landscapeLeft
        defer {
            XCUIDevice.shared.orientation = .portrait
            let portrait = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
                app.frame.height > app.frame.width
            }, object: app)
            _ = XCTWaiter.wait(for: [portrait], timeout: 10)
        }
        let landscape = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            app.frame.width > app.frame.height
        }, object: app)
        XCTAssertEqual(XCTWaiter.wait(for: [landscape], timeout: 10), .completed)
        let pause = app.buttons["일시정지"]
        XCTAssertTrue(pause.isHittable)
        XCTAssertLessThan(pause.frame.maxX, app.frame.width / 2)
        XCTAssertGreaterThan(pause.frame.minY, app.staticTexts["오늘 목표"].frame.maxY)
        let shot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        shot.name = "focus-landscape"
        shot.lifetime = .keepAlways
        add(shot)
    }
    func testTwoCouchCompanionsRespectCapacity() {
        let app = launch("couch-choice")
        let bear = app.buttons.containing(.staticText, identifier: "몽글이").firstMatch
        let cat = app.buttons.containing(.staticText, identifier: "귀염둥이").firstMatch
        let rabbit = app.buttons.containing(.staticText, identifier: "포근이").firstMatch
        XCTAssertTrue(bear.waitForExistence(timeout: 15))
        // Normalize the initial selection, then fill both seats.
        for button in [cat, bear, rabbit] where button.isSelected { button.tap() }
        cat.tap()
        bear.tap()
        XCTAssertTrue(cat.isSelected)
        XCTAssertTrue(bear.isSelected)
        XCTAssertFalse(rabbit.isEnabled)
        XCTAssertTrue(app.buttons["다음"].isEnabled)
        cat.tap()
        XCTAssertTrue(rabbit.isEnabled)
        rabbit.tap()
        XCTAssertTrue(rabbit.isSelected)
        XCTAssertTrue(bear.isSelected)
    }
    func testDollDetailHidesTabBar() {
        let app = launch("tabs-profile")
        XCTAssertTrue(app.staticTexts["처음 만난 날"].waitForExistence(timeout: 20))
        XCTAssertFalse(app.buttons["내 인형"].exists)
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
        XCTAssertTrue(app.staticTexts["플레이리스트"].waitForExistence(timeout: 10))
        XCTAssertFalse(app.staticTexts["같이 볼 인형"].exists)
    }

    func testHomeDollPopupOpensSelectedDollPhoto() {
        let app = launch("tabs-ui")
        waitForHomeControls(app)
        let doll = app.buttons["몽글이"]
        XCTAssertTrue(doll.waitForExistence(timeout: 40))
        doll.tap()
        let menu = app.otherElements["home-doll-menu"]
        XCTAssertTrue(app.buttons["사진 찍기"].waitForExistence(timeout: 5))
        XCTAssertEqual(menu.value as? String, "몽글이")
        let popup = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        popup.name = "home-doll-popup"; popup.lifetime = .keepAlways; add(popup)
        app.buttons["사진 찍기"].tap()
        XCTAssertTrue(app.staticTexts["사진 찍기"].waitForExistence(timeout: 10))
        XCTAssertEqual(app.otherElements["etiquette-photo-screen"].value as? String, "몽글이")
        let camera = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        camera.name = "home-doll-photo"; camera.lifetime = .keepAlways; add(camera)
        app.buttons["닫기"].tap()
        XCTAssertTrue(app.buttons["방 도구"].waitForExistence(timeout: 10))
        XCTAssertFalse(app.buttons["사진 찍기"].exists)
        XCTAssertTrue(doll.waitForExistence(timeout: 30))
    }

    func testHomeDollDanceOptionsAndDismissal() {
        let app = launch("tabs-ui")
        waitForHomeControls(app)
        let doll = app.buttons["몽글이"]
        XCTAssertTrue(doll.waitForExistence(timeout: 40))
        doll.tap()
        XCTAssertTrue(app.buttons["춤추기"].waitForExistence(timeout: 5))
        app.buttons["춤추기"].tap()
        XCTAssertTrue(app.buttons["아침체조"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["춤추기"].exists)
        XCTAssertFalse(app.staticTexts["함께 춤춰요"].exists)
        for title in ["아침체조", "댄스댄스", "탭댄스", "씰룩씰룩"] {
            XCTAssertFalse(app.buttons[title].isSelected, "Dance starts only after an explicit choice")
            XCTAssertEqual(app.buttons[title].frame.midY,app.buttons["아침체조"].frame.midY,accuracy:1)
        }
        let panel = app.otherElements["home-doll-dance-picker"]
        XCTAssertGreaterThan(panel.frame.minY, app.frame.height * 0.70)
        XCTAssertLessThan(panel.frame.height, 180)
        XCTAssertFalse(app.buttons["방 도구"].exists, "Navigation must not cover the dance sheet")
        let initial = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        initial.name = "home-doll-dance-default-white"; initial.lifetime = .keepAlways; add(initial)
        for title in ["아침체조", "댄스댄스", "탭댄스", "씰룩씰룩"] {
            app.buttons[title].tap()
            XCTAssertTrue(app.buttons[title].isSelected)
            for other in ["아침체조", "댄스댄스", "탭댄스", "씰룩씰룩"] where other != title {
                XCTAssertFalse(app.buttons[other].isSelected, "Only the chosen dance is selected")
            }
        }
        // Capture the settled chip after UIKit's pressed-state transition.
        Thread.sleep(forTimeInterval: 1)
        let dance = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        dance.name = "home-doll-dance"; dance.lifetime = .keepAlways; add(dance)
        app.buttons["춤추기 닫기"].tap()
        XCTAssertFalse(app.buttons["아침체조"].exists)
        doll.tap()
        XCTAssertTrue(app.buttons["사진 찍기"].waitForExistence(timeout: 5))
    }

    func testARDancePanelSingleRowAndSave() {
        let app = launch("ar-dance-panel")
        let titles = ["아침체조", "댄스댄스", "탭댄스", "씰룩씰룩"]
        XCTAssertTrue(app.buttons[titles[0]].waitForExistence(timeout:15))
        XCTAssertFalse(app.buttons["완료"].isEnabled)
        for title in titles {
            XCTAssertFalse(app.buttons[title].isSelected)
            XCTAssertEqual(app.buttons[title].frame.midY,app.buttons[titles[0]].frame.midY,accuracy:1)
        }
        app.buttons["탭댄스"].tap()
        XCTAssertTrue(app.buttons["탭댄스"].isSelected)
        Thread.sleep(forTimeInterval: 1) // Capture after the pressed character returns to its resting variant.
        captureUpdatedLoading(app,"ar-dance-single-row")
        app.buttons["완료"].tap()
        XCTAssertEqual(app.staticTexts["saved-ar-dance"].label,"탭댄스")
    }

    func testWindowQualityDayNightAndCutout() {
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        let deny = springboard.buttons["허용 안 함"]
        if deny.exists { deny.tap() }
        for (route, hour, weather) in [("window-sky", "13", "0"), ("window-sky", "21", "0"), ("window-sky", "13", "73"), ("cutout-front", "13", "0")] {
            let app = XCUIApplication(bundleIdentifier: "com.nayeon.Malrang")
            app.launchArguments = ["--design-preview=\(route)", "--room-hour=\(hour)", "--window-weather=\(weather)"]
            app.launch()
            // Wait for asynchronous 3D textures and the first visible scene frame.
            Thread.sleep(forTimeInterval: 10)
            XCTAssertEqual(app.state, .runningForeground)
            captureUpdatedLoading(app, "quality-\(route)-\(hour)-\(weather)")
            app.terminate()
        }
    }

    func testFeedbackProfileAndSort() {
        let app = launch("tabs-dolls")
        XCTAssertTrue(app.buttons["인형 정렬"].waitForExistence(timeout: 15))
        app.buttons["인형 정렬"].tap()
        XCTAssertTrue(app.buttons["이름순"].waitForExistence(timeout: 5))
        app.buttons["이름순"].tap()
        XCTAssertEqual(app.buttons["인형 정렬"].value as? String, "이름순")
        let doll = app.buttons["몽글이"]
        XCTAssertTrue(doll.waitForExistence(timeout: 10))
        doll.tap()
        XCTAssertTrue(app.staticTexts["생일"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["만진 횟수"].exists)
        XCTAssertFalse(app.staticTexts["처음 만난 날"].exists)
        app.swipeUp()
        XCTAssertTrue(app.buttons["인형 이름 수정"].waitForExistence(timeout: 5))
        app.buttons["인형 이름 수정"].tap()
        XCTAssertTrue(app.alerts["인형 이름"].waitForExistence(timeout: 5))
        app.alerts.buttons["취소"].tap()
        captureUpdatedLoading(app, "feedback-profile-card")
    }

    func testFeedbackWallSelectionAndUndo() {
        let app = launch("decorate")
        XCTAssertTrue(app.otherElements["decorate-loading"].waitForNonExistence(timeout: 60))
        let wallpaper = app.buttons["벽지"]
        XCTAssertTrue(wallpaper.waitForExistence(timeout: 20))
        let ready = XCTNSPredicateExpectation(predicate: NSPredicate(format: "hittable == true AND enabled == true"), object: wallpaper)
        XCTAssertEqual(XCTWaiter.wait(for: [ready], timeout: 10), .completed)
        wallpaper.tap()
        let right = app.buttons["오른쪽 벽"]
        XCTAssertTrue(right.waitForExistence(timeout: 5))
        right.tap()
        XCTAssertTrue(right.isSelected)
        app.buttons["라벤더"].tap()
        XCTAssertTrue(app.buttons["라벤더"].isSelected)
        app.buttons["되돌리기"].tap()
        XCTAssertTrue(app.buttons["원래 벽지"].isSelected)
        app.buttons["다시하기"].tap()
        XCTAssertTrue(app.buttons["라벤더"].isSelected)
        captureUpdatedLoading(app, "feedback-right-wall")
    }

    func testFeedbackVideoPickerOnly() {
        let app = launch("couch-playlist")
        XCTAssertTrue(app.staticTexts["플레이리스트"].waitForExistence(timeout: 15))
        XCTAssertFalse(app.buttons["그만 보기"].exists)
        let favorite = app.buttons["찜하기"].firstMatch
        XCTAssertTrue(favorite.waitForExistence(timeout: 10))
        favorite.tap()
        XCTAssertTrue(app.buttons["찜 해제"].firstMatch.waitForExistence(timeout: 5))
    }

    private func waitForHomeControls(_ app: XCUIApplication) {
        let tools = app.buttons["방 도구"]
        XCTAssertTrue(tools.waitForExistence(timeout: 40))
        // Controls can appear in accessibility before the first rendered room
        // frame. Wait for the loading overlay before querying their hit targets.
        XCTAssertTrue(app.otherElements["room-loading"].waitForNonExistence(timeout: 60))
        let ready = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            let frame = tools.frame
            return frame.minX.isFinite && frame.minY.isFinite && frame.width > 0
                && tools.isHittable && frame.maxY < app.frame.maxY - 20
        }, object: tools)
        XCTAssertEqual(XCTWaiter.wait(for: [ready], timeout: 15), .completed)
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
        let handle = title.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        handle.press(forDuration: 0.1, thenDragTo: handle.withOffset(CGVector(dx: 0, dy: 160)))
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
