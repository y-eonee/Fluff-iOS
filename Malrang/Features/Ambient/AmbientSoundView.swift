import SwiftUI

struct AmbientSoundView: View {
  enum Sheet: String, Identifiable {
    case timer, sound
    var id: String { rawValue }
  }
  let dolls: [DollState]
  @Environment(\.dismiss) private var dismiss
  @Environment(\.scenePhase) private var scenePhase
  @State private var player: AmbientPlayer
  @State private var chosen = AmbientSound.rain
  @State private var minutes: Int? = 30
  @State private var customMinutes = 30
  @State private var sheet: Sheet?
  private let initialSheet: Sheet?
  private let initiallyScrolled: Bool

  init(dolls: [DollState], player: AmbientPlayer? = nil, initialSheet: Sheet? = nil, initiallyScrolled: Bool = false) {
    self.dolls = dolls
    _player = State(initialValue: player ?? .shared)
    self.initialSheet = initialSheet
    self.initiallyScrolled = initiallyScrolled
  }
  private var choosing: Bool { player.sound == nil }

  var body: some View {
    VStack(spacing: 0) {
      HStack {
        D1IconButton(icon: "back", label: "방으로 돌아가기") { dismiss() }
        Spacer()
        Text("cozy sound").notCliche(28, relativeTo: .title).tracking(-1.12)
        Spacer()
        Color.clear.frame(width: 44, height: 44)
      }.padding(.horizontal, 20).padding(.top, 4).padding(.bottom, 20)
      ScrollViewReader { proxy in
        ScrollView {
          VStack(alignment: .leading, spacing: choosing ? 24 : 16) {
            RadioCompanionPreview(doll: dolls.first, playing: player.isPlaying)
            if choosing {
              VStack(alignment: .leading, spacing: 12) {
                Text("듣고 싶은 소리").pretendard(.bold, 17).frame(height: 26)
                soundGrid(showCheck: false)
              }
              VStack(alignment: .leading, spacing: 12) {
                Text("소리가 꺼지는 시간").pretendard(.bold, 17).frame(height: 26)
                timerChoices
              }
              VStack(alignment: .leading, spacing: 16) {
                Text("재생 시간 설정").pretendard(.bold, 17).frame(height: 26)
                timeStepper
              }.id("custom-time")
            } else { nowPlaying }
            errorMessage
          }.padding(.horizontal, 16).padding(.bottom, 24)
        }.scrollIndicators(.hidden)
          .onAppear { if initiallyScrolled { proxy.scrollTo("custom-time", anchor: .bottom) } }
      }
      bottomButton.padding(.horizontal, choosing ? 24 : 22)
        .padding(.top, 16).padding(.bottom, 6)
    }.background(Color.mib.bg.screen).foregroundStyle(Color.mib.text.primary)
      .onAppear {
        chosen = player.sound ?? chosen
        sheet = initialSheet
      }
      .onDisappear { player.stopPreview() }
      .onChange(of: scenePhase) { _, phase in if phase == .active { player.reconcile() } }
      .onChange(of: player.sound) { _, sound in
        if sound == nil { sheet = nil }
      }
      .sheet(item: $sheet, onDismiss: { player.stopPreview() }) { selectedSheet in
        sheetContent(selectedSheet)
          .presentationDetents([.height(selectedSheet == .timer ? 345 : 409)])
          .presentationDragIndicator(.hidden)
          .presentationCornerRadius(22)
          .presentationBackground(Color.mib.bg.surface)
      }
  }

  @ViewBuilder private var bottomButton: some View {
    if choosing {
      Button("소리 재생하기") { player.start(chosen, minutes: minutes) }.buttonStyle(D1PrimaryStyle())
    } else if player.isPlaying {
      Button("방에서 계속 듣기") { dismiss() }.buttonStyle(D1PrimaryStyle())
    } else {
      Button("방으로 나가기") { dismiss() }.buttonStyle(D1SecondaryStyle())
    }
  }

  private func soundGrid(showCheck: Bool) -> some View {
    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 3), spacing: 12) {
      ForEach(AmbientSound.allCases) { sound in
        Button {
          chosen = sound
          player.preview(sound)
        } label: {
          VStack(spacing: 8) {
            D1Icon(name: sound.rawValue).frame(width: 40, height: 40)
            Text(sound.title).pretendard(.medium, 13).frame(height: 20)
          }.frame(maxWidth: .infinity).frame(height: 96)
            .background(chosen == sound ? Color.mib.bg.mintSoft : Color.mib.bg.surface,
                        in: RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(
              chosen == sound ? Color.mib.line.selected : Color.mib.line.default,
              lineWidth: chosen == sound && showCheck ? 2 : 1))
            .overlay(alignment: .topTrailing) {
              if showCheck && chosen == sound { D1Icon(name: "check").padding(8) }
            }
        }.buttonStyle(.plain).accessibilityAddTraits(chosen == sound ? .isSelected : [])
          .accessibilityHint("잠깐 미리 들어요")
      }
    }
  }

  private var timerChoices: some View {
    HStack(spacing: 8) {
      ForEach([15, 30, 60, 0], id: \.self) { value in
        D1Choice(title: value == 0 ? "계속" : value == 60 ? "1시간" : "\(value)분",
                 selected: minutes == (value == 0 ? nil : value), fillsWidth: true) {
          minutes = value == 0 ? nil : value
          if value > 0 { customMinutes = value }
        }
      }
    }
  }

  private var timeStepper: some View {
    HStack(spacing: 0) {
      Button { adjustMinutes(-5) } label: {
        Image("d1_minus").renderingMode(.template).resizable().frame(width: 20, height: 20)
          .frame(width: 52, height: 52).contentShape(Rectangle())
      }.accessibilityLabel("재생 시간 5분 줄이기").disabled(minutes != nil && customMinutes <= 5)
      Spacer(minLength: 0)
      HStack(alignment: .firstTextBaseline, spacing: 4) {
        Text(minutes == nil ? "계속" : "\(customMinutes)").pretendard(.bold, 20).monospacedDigit()
        if minutes != nil { Text("분").pretendard(.regular, 16) }
      }.foregroundStyle(Color.mib.text.primary)
      Spacer(minLength: 0)
      Button { adjustMinutes(5) } label: {
        Image("d1_plus").renderingMode(.template).resizable().frame(width: 20, height: 20)
          .frame(width: 52, height: 52).contentShape(Rectangle())
      }.accessibilityLabel("재생 시간 5분 늘리기").disabled(minutes != nil && customMinutes >= 180)
    }.buttonStyle(.plain).foregroundStyle(Color.mib.action.primary)
      .d1Surface(radius: 10)
      .accessibilityElement(children: .contain)
      .accessibilityLabel("재생 시간").accessibilityValue(minutes.map { "\($0)분" } ?? "계속")
  }
  private func adjustMinutes(_ delta: Int) {
    customMinutes = min(180, max(5, customMinutes + delta))
    minutes = customMinutes
  }

  private var nowPlaying: some View {
    TimelineView(.periodic(from: .now, by: 1)) { context in
      VStack(alignment: .leading, spacing: 18) {
        VStack(alignment: .leading, spacing: 4) {
          Text(player.isPlaying ? "지금 재생 중" : "일시정지").pretendard(.medium, 13).frame(height: 20)
          Text(player.sound?.title ?? "재생이 끝났어요").pretendard(.bold, 28).frame(height: 38)
        }
        HStack(spacing: 24) {
          VStack(alignment: .leading, spacing: 12) {
            Text(player.elapsedLabel(at: context.date)).pretendard(.bold, 20).monospacedDigit()
              .frame(height: 28).accessibilityLabel("누적 재생 시간 \(player.elapsedLabel(at: context.date))")
            GeometryReader { geo in
              Capsule().fill(Color.mib.bg.mintSoft)
              Capsule().fill(Color.mib.action.primary)
                .frame(width: geo.size.width * player.progress(at: context.date))
            }.frame(height: 8)
              .accessibilityLabel(player.duration == nil ? "자동 종료 없이 계속 재생" : "남은 시간 \(player.timeLabel(at: context.date))")
          }.frame(maxWidth: .infinity)
          Button { player.toggle() } label: {
            D1PlaybackGlyph(paused: !player.isPlaying).frame(width: 64, height: 64)
              .background(Color.mib.action.primary, in: Circle())
          }.buttonStyle(.plain).accessibilityLabel(player.isPlaying ? "일시정지" : "다시 재생")
        }
        HStack(spacing: 8) {
          D1Choice(title: "타이머 변경", fillsWidth: true) {
            minutes = player.remaining().map { max(5, Int(($0 / 60).rounded(.up))) }
            customMinutes = minutes ?? 30
            sheet = .timer
          }
          D1Choice(title: "다른 소리", fillsWidth: true) {
            chosen = player.sound ?? .rain
            sheet = .sound
          }
          D1Choice(title: "끄기", fillsWidth: true) { player.stop() }
        }
      }.padding(24).d1Surface(radius: 22)
    }
  }

  private func sheetContent(_ selectedSheet: Sheet) -> some View {
    VStack(alignment: .leading, spacing: 16) {
      Capsule().fill(Color.mib.line.default).frame(width: 40, height: 4)
        .frame(maxWidth: .infinity).accessibilityHidden(true)
      if selectedSheet == .timer {
        VStack(alignment: .leading, spacing: 12) {
          Text("지금부터 남은 시간").pretendard(.bold, 17).frame(height: 26)
          timerChoices
          timeStepper
          Text(minutes.map { "적용하면 지금부터 \($0)분 후 소리가 꺼져요.\n‘계속’을 선택하면 자동 종료하지 않아요." }
               ?? "‘계속’을 선택하면 자동 종료하지 않아요.")
            .pretendard(.medium, 13).lineSpacing(4).foregroundStyle(Color.mib.text.secondary)
        }
      } else {
        VStack(alignment: .leading, spacing: 12) {
          Text("듣고 싶은 소리를 골라주세요").pretendard(.bold, 17).frame(height: 26)
          Text("현재 소리 · \(player.sound?.title ?? "")").pretendard(.medium, 13)
            .foregroundStyle(Color.mib.text.secondary).frame(height: 20)
        }
        soundGrid(showCheck: true)
      }
      errorMessage
      Spacer(minLength: 0)
      Button(selectedSheet == .timer ? "타이머 적용하기" : "소리 적용하기") {
        if selectedSheet == .timer { player.setTimer(minutes) }
        else { player.changeSound(chosen) }
        if player.error == nil { sheet = nil }
      }.buttonStyle(D1PrimaryStyle())
    }.padding(.horizontal, 24).padding(.top, 12).padding(.bottom, 6)
      .foregroundStyle(Color.mib.text.primary)
  }

  @ViewBuilder private var errorMessage: some View {
    if let error = player.error { Text(error).pretendard(.medium, 13).foregroundStyle(Color.a.danger) }
  }
}

/// Figma's radio illustration with the user's actual, animated 3D doll layered on top.
private struct RadioCompanionPreview: View {
  let doll: DollState?
  let playing: Bool
  var body: some View {
    GeometryReader { geo in
      let scale = geo.size.width / 358
      ZStack(alignment: .topLeading) {
        Image("radio_backdrop").resizable().frame(width: geo.size.width * 1.3073, height: 312)
          .offset(x: -geo.size.width * 0.3073)
        if let doll {
          CompanionScene(dolls: [doll], kind: .radioArtwork(playing: playing))
            .frame(width: 158 * scale, height: 167)
            .offset(x: 21 * scale, y: 72)
            .allowsHitTesting(false)
        }
      }.frame(width: geo.size.width, height: 312, alignment: .topLeading).clipped()
        .clipShape(RoundedRectangle(cornerRadius: 22))
        .overlay(RoundedRectangle(cornerRadius: 22).strokeBorder(Color.a.blueLight, lineWidth: 12))
    }.frame(height: 312).accessibilityElement(children: .ignore)
      .accessibilityLabel(doll.map { "\($0.name)와 함께 듣는 라디오" } ?? "포근한 라디오")
  }
}

/// D1 playback control: the same two rounded bars as B-6, not a replacement icon family.
struct D1PlaybackGlyph: View {
  let paused: Bool
  var body: some View {
    Group {
      if paused {
        Path { p in
          p.move(to: CGPoint(x: 2, y: 0))
          p.addLine(to: CGPoint(x: 20, y: 12))
          p.addLine(to: CGPoint(x: 2, y: 24))
          p.closeSubpath()
        }.fill(Color.mib.icon.onDark).frame(width: 24, height: 24)
      } else {
        HStack(spacing: 7) {
          Capsule().frame(width: 6, height: 24)
          Capsule().frame(width: 6, height: 24)
        }.foregroundStyle(Color.mib.icon.onDark)
      }
    }.accessibilityHidden(true)
  }
}

struct AmbientMiniPlayer: View {
  let open: () -> Void
  @State private var player = AmbientPlayer.shared
  var body: some View {
    if let sound = player.sound {
      TimelineView(.periodic(from: .now, by: 1)) { context in
        HStack(spacing: 8) {
          Button(action: open) {
            Text("\(sound.title) · \(player.timeLabel(at:context.date))").pretendard(.medium, 13)
              .lineLimit(1).frame(minHeight: 44)
          }.buttonStyle(.plain)
          Button {
            player.toggle()
          } label: {
            D1PlaybackGlyph(paused: !player.isPlaying).scaleEffect(0.5).frame(width: 44, height: 44)
              .background(Color.mib.action.primary, in: Circle())
          }.buttonStyle(.plain).accessibilityLabel(player.isPlaying ? "일시정지" : "재생")
        }.padding(.leading, 13).padding(.trailing, 2).frame(height: 48).d1ImageSurface(radius: 14)
      }
    }
  }
}
