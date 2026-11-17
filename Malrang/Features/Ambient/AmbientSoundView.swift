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
      }.padding(.horizontal, 20).padding(.top, 4).padding(.bottom, choosing ? 17 : 24)
      ScrollViewReader { proxy in
        ScrollView {
          VStack(alignment: .leading, spacing: choosing ? 24 : 16) {
            RadioCompanionPreview(doll: dolls.first, playing: player.isPlaying)
            if choosing {
              VStack(alignment: .leading, spacing: 12) {
                Text("듣고 싶은 소리").pretendard(.bold, 17, tracking: -0.85).frame(height: 26)
                soundGrid(showCheck: true)
              }
              VStack(alignment: .leading, spacing: 12) {
                Text("소리가 꺼지는 시간").pretendard(.bold, 17, tracking: -0.85).frame(height: 26)
                timerChoices
              }
              VStack(alignment: .leading, spacing: 16) {
                Text("재생 시간 설정").pretendard(.bold, 17, tracking: -0.85).frame(height: 26)
                timeStepper
              }.id("custom-time")
            } else { nowPlaying }
            errorMessage
          }.padding(.horizontal, 16).padding(.bottom, choosing ? 40 : 24).id("radio-content")
        }.scrollIndicators(.hidden)
          .onAppear { if initiallyScrolled { proxy.scrollTo("radio-content", anchor: .bottom) } }
      }
      bottomButton.padding(.horizontal, choosing ? 24 : 22)
        .padding(.top, 16).padding(.bottom, choosing ? 6 : -12)
        .background { if choosing { Color(uiColor: Palette.uiColor("#FBF7EF")).ignoresSafeArea(edges: .bottom) } }
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
      .accessibilityHidden(sheet != nil)
      .overlay {
        if let selectedSheet = sheet {
          GeometryReader { geometry in
            ZStack(alignment: .bottom) {
              Color.rep4.c16.opacity(0.28).ignoresSafeArea()
                .onTapGesture { sheet = nil }
              sheetContent(selectedSheet)
                .frame(height: selectedSheet == .timer ? 345 : 358)
                .padding(.bottom, geometry.safeAreaInsets.bottom)
                .frame(maxWidth: .infinity)
                .background(Color.rep4.c01, in: UnevenRoundedRectangle(topLeadingRadius: 22, topTrailingRadius: 22))
                .simultaneousGesture(DragGesture(minimumDistance: 25).onEnded { value in
                  if value.translation.height > 60 { sheet = nil }
                })
                .accessibilityAction(.escape) { sheet = nil }
                .transition(.move(edge: .bottom))
            }.frame(width: geometry.size.width, height: geometry.size.height + geometry.safeAreaInsets.bottom)
          }
        }
      }
      .onChange(of: sheet) { _, value in if value == nil { player.stopPreview() } }
      .animation(.easeOut(duration: 0.2), value: sheet)

  }

  @ViewBuilder private var bottomButton: some View {
    if choosing {
      Button("소리 재생하기") { player.start(chosen, minutes: minutes) }.buttonStyle(D1PrimaryStyle())
    } else if player.isPlaying {
      Button("방으로 나가기") { dismiss() }.pretendard(.medium, 12).underline().foregroundStyle(Color.rep4.c29).frame(minHeight: 44).offset(y: -8)
    } else {
      Button("방으로 나가기") { dismiss() }.pretendard(.medium, 12).underline().foregroundStyle(Color.rep4.c29).frame(minHeight: 44).offset(y: -8)
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
            HStack(spacing: 4) {
              if showCheck && chosen == sound { D1Icon(name: "check").scaleEffect(0.75).frame(width: 12, height: 12) }
              Text(sound.title).pretendard(sheet == nil ? .regular : .medium, sheet == nil ? 14 : 13, tracking: sheet == nil ? -0.7 : 0)
            }.frame(height: 20.3)
          }.frame(maxWidth: .infinity).frame(height: 96)
            .modifier(RepresentativeSelectionSurface(selected: chosen == sound, radius: 18.29, neutral: sheet == nil ? Color.rep4.c01 : Color(uiColor: Palette.uiColor("#F7F7F7"))))
        }.buttonStyle(.plain).accessibilityAddTraits(chosen == sound ? .isSelected : [])
          .accessibilityHint("잠깐 미리 들어요")
      }
    }
  }

  private var timerChoices: some View {
    HStack(spacing: 8) {
      ForEach([15, 30, 60, 0], id: \.self) { value in
        D1Choice(title: value == 0 ? "계속" : value == 60 ? "1시간" : "\(value)분",
                 selected: minutes == (value == 0 ? nil : value), fillsWidth: true,
                 height: sheet == nil ? 40 : 44, fontSize: 12.743,
                 neutral: sheet == nil ? Color.rep4.c01 : Color(uiColor: Palette.uiColor("#F7F7F7"))) {
          minutes = value == 0 ? nil : value
          if value > 0 { customMinutes = value }
        }
      }
    }
  }

  private var timeStepper: some View {
    HStack(spacing: 0) {
      Button { adjustMinutes(-5) } label: {
        Image("rep4_focus_minus").renderingMode(.template).resizable().frame(width: 24, height: 24)
          .frame(width: 52, height: 52).contentShape(Rectangle())
      }.accessibilityLabel("재생 시간 5분 줄이기").disabled(minutes != nil && customMinutes <= 5)
      Spacer(minLength: 0)
      HStack(alignment: .firstTextBaseline, spacing: 4) {
        Text(minutes == nil ? "계속" : "\(customMinutes)").pretendard(.bold, 17).monospacedDigit()
        if minutes != nil { Text("분").pretendard(.regular, 14) }
      }.foregroundStyle(Color.mib.text.primary)
      Spacer(minLength: 0)
      Button { adjustMinutes(5) } label: {
        Image("rep4_focus_plus").renderingMode(.template).resizable().frame(width: 24, height: 24)
          .frame(width: 52, height: 52).contentShape(Rectangle())
      }.accessibilityLabel("재생 시간 5분 늘리기").disabled(minutes != nil && customMinutes >= 180)
    }.buttonStyle(.plain).foregroundStyle(Color.mib.action.primary)
      .background(sheet == nil ? Color.rep4.c01 : Color.rep4.c11, in: RoundedRectangle(cornerRadius: 14))
      .accessibilityElement(children: .contain)
      .accessibilityLabel("재생 시간").accessibilityValue(minutes.map { "\($0)분" } ?? "계속")
  }
  private func adjustMinutes(_ delta: Int) {
    customMinutes = min(180, max(5, customMinutes + delta))
    minutes = customMinutes
  }

  private var nowPlaying: some View {
    VStack(spacing: 34.69) {
      TimelineView(.periodic(from: .now, by: 1)) { context in
        GeometryReader { geometry in
          let trackWidth = geometry.size.width.isFinite ? max(0, geometry.size.width - 121) : 0
          ZStack(alignment: .topLeading) {
            Text("재생중인 소리").pretendard(.regular, 14, tracking: -0.7).frame(height: 20).offset(x: 24, y: 24)
            Text(player.sound?.title ?? "재생이 끝났어요").pretendard(.bold, 17, tracking: -0.85)
              .frame(height: 26).offset(x: 24, y: 48)
            Text(player.elapsedLabel(at: context.date)).pretendard(.bold, 17, tracking: -0.85).monospacedDigit()
              .frame(height: 26).offset(x: 24, y: 92)
              .accessibilityLabel("누적 재생 시간 \(player.elapsedLabel(at: context.date))")
            ZStack(alignment: .leading) {
              Capsule().fill(Color.rep4.c20).frame(height: 7.936)
                .overlay(Capsule().strokeBorder(Color(uiColor: Palette.uiColor("#7A7A7A")), lineWidth: 0.635))
              Capsule().fill(Color.rep4.c21).frame(width: trackWidth * player.progress(at: context.date), height: 6.735)
            }.frame(width: trackWidth, height: 15).offset(x: 24, y: 123.7)
            HStack {
              Text("재생시간 · \(player.elapsedLabel(at: context.date))")
              Spacer()
              Text("남은 시간 · \(player.timeLabel(at: context.date))")
            }.pretendard(.regular, 10.5).frame(width: trackWidth, height: 15.225)
              .offset(x: 24.73, y: 144.4)
            Button { player.toggle() } label: {
              Group {
                if player.isPlaying {
                  HStack(spacing: 7.2) {
                    Capsule().frame(width: 6, height: 23)
                    Capsule().frame(width: 6, height: 23)
                  }
                } else { D1PlaybackGlyph(paused: true) }
              }.frame(width: 64, height: 64)
                .background(Color.rep4.c30, in: Circle())
                .overlay(Circle().strokeBorder(Color(uiColor: Palette.uiColor("#BDBDBD")), lineWidth: 1))
            }.buttonStyle(.plain).accessibilityLabel(player.isPlaying ? "일시정지" : "다시 재생")
              .offset(x: geometry.size.width - 77, y: 92)
          }
        }.frame(height: 200).background(Color.rep4.c01, in: RoundedRectangle(cornerRadius: 22))
      }
      HStack(spacing: 12) {
        Button("타이머 변경") {
          minutes = player.remaining().map { max(5, Int(($0 / 60).rounded(.up))) }
          customMinutes = minutes ?? 30; sheet = .timer
        }.buttonStyle(D1SecondaryStyle())
        Button("다른 소리") { chosen = player.sound ?? .rain; sheet = .sound }
          .buttonStyle(D1PrimaryStyle())
      }
    }.padding(.top, 14)
  }

  private func sheetContent(_ selectedSheet: Sheet) -> some View {
    VStack(alignment: .leading, spacing: 16) {
      Capsule().fill(Color.rep4.c08).frame(width: 40, height: 4)
        .frame(maxWidth: .infinity).accessibilityHidden(true)
      if selectedSheet == .timer {
        VStack(alignment: .leading, spacing: 12) {
          Text("지금부터 남은 시간").pretendard(.bold, 17, tracking: -0.85).frame(height: 26)
          timerChoices
          timeStepper
          Text(minutes.map { "적용하면 지금부터 \($0)분 후 소리가 꺼져요.\n‘계속’을 선택하면 자동 종료하지 않아요." }
               ?? "‘계속’을 선택하면 자동 종료하지 않아요.")
            .pretendard(.regular, 14, tracking: -0.7).lineSpacing(9.6)
            .frame(minHeight: minutes == nil ? 26.32 : 52.64).foregroundStyle(Color.rep4.c08)
        }
      } else {
        VStack(alignment: .leading, spacing: 12) {
          Text("듣고 싶은 소리를 골라주세요").pretendard(.bold, 17, tracking: -0.85).frame(height: 26)
        }
        soundGrid(showCheck: true)
      }
      errorMessage
      if selectedSheet == .timer { Spacer(minLength: 0) }
      Button("타이머 적용하기") {
        if selectedSheet == .timer { player.setTimer(minutes) }
        else { player.changeSound(chosen) }
        if player.error == nil { sheet = nil }
      }.buttonStyle(D1PrimaryStyle())
    }.padding(.horizontal, 24).padding(.top, 12).padding(.bottom, selectedSheet == .timer ? 6 : 4)
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
        .overlay {
          RepresentativeGradientFill(definition: RepresentativeGradients.selected)
            .mask(RoundedRectangle(cornerRadius: 22).strokeBorder(lineWidth: 12))
        }
    }.frame(height: 312).accessibilityElement(children: .ignore)
      .accessibilityLabel(doll.map { "\($0.name)와 함께 듣는 라디오" } ?? "포근한 라디오")
  }
}

/// D1 playback control: the same two rounded bars as B-6, not a replacement icon family.
struct D1PlaybackGlyph: View {
  let paused: Bool
  var color = Color.rep4.c03
  var body: some View {
    Group {
      if paused {
        Path { p in
          p.move(to: CGPoint(x: 2, y: 0))
          p.addLine(to: CGPoint(x: 20, y: 12))
          p.addLine(to: CGPoint(x: 2, y: 24))
          p.closeSubpath()
        }.fill(color).frame(width: 24, height: 24)
      } else {
        HStack(spacing: 7.56) {
          Capsule().frame(width: 3.24, height: 28.44)
          Capsule().frame(width: 3.24, height: 28.44)
        }.foregroundStyle(color)
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
              .background(Color.rep4.c30, in: Circle())
          }.buttonStyle(.plain).accessibilityLabel(player.isPlaying ? "일시정지" : "재생")
        }.padding(.leading, 13).padding(.trailing, 2).frame(height: 48).d1ImageSurface(radius: 14)
      }
    }
  }
}
