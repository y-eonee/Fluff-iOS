import SwiftUI

struct AmbientSoundView: View {
  let dolls: [DollState]
  @Environment(\.dismiss) private var dismiss
  @Environment(\.scenePhase) private var scenePhase
  @State private var player = AmbientPlayer.shared
  @State private var chosen = AmbientSound.rain
  @State private var minutes: Int? = 30
  @State private var choosing = true
  @State private var changingTimer = false
  var body: some View {
    VStack(spacing: 0) {
      HStack {
        D1IconButton(icon: "back", label: "홈으로") { dismiss() }
        Spacer()
        Text("cozy sound").pretendard(.bold, 17)
        Spacer()
        Color.clear.frame(width: 44, height: 44)
      }.padding(.horizontal, 20).padding(.vertical, 8)
      ScrollView {
        VStack(alignment: .leading, spacing: 12) {
          CompanionScene(dolls: Array(dolls.prefix(1)), kind: .radio(playing: player.isPlaying))
            .frame(height: 312).clipShape(RoundedRectangle(cornerRadius: 22))
            .overlay(alignment: .top) {
              D1Bubble(
                text: player.isPlaying && !choosing
                  ? "\(player.sound?.title ?? "소리") 틀었어! 푹 쉬어" : "어떤 소리 틀어줄까?"
              ).frame(width: 242).padding(.top, 22)
            }
            .accessibilityLabel("솜뭉치와 입체 라디오")
          if choosing { soundChoices } else { nowPlaying }
          if let error = player.error {
            Text(error).pretendard(.medium, 13).accessibilityLabel(error)
          }
        }.padding(.horizontal, 16)
      }.scrollIndicators(.hidden)
      if choosing {
        Button("틀어줘") {
          player.start(chosen, minutes: minutes)
          if player.error == nil { choosing = false }
        }.buttonStyle(D1PrimaryStyle()).padding(.horizontal, 22).padding(.top, 4).padding(.bottom, 12)
      } else {
        Button("홈에서 계속 듣기") { dismiss() }.buttonStyle(D1SecondaryStyle()).padding(.horizontal, 22)
          .padding(.top, 4).padding(.bottom, 12)
      }
    }.background(Color.mib.bg.screen).foregroundStyle(Color.mib.text.primary)
      .onAppear {
        if let sound = player.sound {
          chosen = sound
          choosing = false
        }
      }
      .onDisappear { player.stopPreview() }
      .onChange(of: scenePhase) { _, phase in if phase == .active { player.reconcile() } }
      .sheet(isPresented: $changingTimer) {
        VStack(alignment: .leading, spacing: 22) {
          Text("끄기 타이머").pretendard(.bold, 17)
          timerChoices
          Button("완료") {
            player.setTimer(minutes)
            changingTimer = false
          }.buttonStyle(D1PrimaryStyle())
        }.padding(22).presentationDetents([.height(240)]).presentationBackground(
          Color.mib.bg.surface)
      }
  }
  private var soundChoices: some View {
    VStack(alignment: .leading, spacing: 10) {
      Text("듣고 싶은 소리").pretendard(.bold, 17)
      LazyVGrid(
        columns: Array(repeating: GridItem(.flexible(), spacing: 11), count: 3), spacing: 10
      ) {
        ForEach(AmbientSound.allCases) { sound in
          Button {
            chosen = sound
            player.preview(sound)
          } label: {
            VStack(spacing: 10) {
              D1Icon(name: sound.rawValue).frame(width: 40, height: 40)
              Text(sound.title).pretendard(.medium, 13)
            }
            .frame(maxWidth: .infinity).frame(height: 96)
            .background(
              chosen == sound ? Color.mib.bg.mintSoft : Color.mib.bg.surface,
              in: RoundedRectangle(cornerRadius: 14)
            )
            .overlay(
              RoundedRectangle(cornerRadius: 14).strokeBorder(
                chosen == sound ? Color.mib.line.selected : Color.mib.line.default,
                lineWidth: chosen == sound ? 2 : 1))
          }.buttonStyle(.plain).accessibilityAddTraits(chosen == sound ? .isSelected : [])
            .accessibilityHint("2초 동안 미리 들어요")
        }
      }
      Text("끄기 타이머").pretendard(.medium, 13)
      timerChoices
    }.padding(.horizontal, 6)
  }
  private var timerChoices: some View {
    HStack(spacing: 8) {
      ForEach([15, 30, 60, 0], id: \.self) { value in
        D1Choice(
          title: value == 0 ? "계속" : value == 60 ? "1시간" : "\(value)분",
          selected: minutes == (value == 0 ? nil : value)
        ) { minutes = value == 0 ? nil : value }
      }
    }
  }
  private var nowPlaying: some View {
    TimelineView(.periodic(from: .now, by: 1)) { context in
      VStack(alignment: .leading, spacing: 12) {
        Text("지금 재생 중").pretendard(.medium, 13)
        Text(player.sound?.title ?? "재생이 끝났어요").pretendard(.bold, 20)
        Text(
          player.duration == nil
            ? "끄기 타이머 · 계속" : "끄기 타이머 · \(player.timeLabel(at:context.date)) 남음"
        ).pretendard(.medium, 13)
        GeometryReader { geo in
          Capsule().fill(Color.mib.bg.mintSoft)
          Capsule().fill(Color.mib.action.primary).frame(
            width: geo.size.width * CGFloat(progress(at: context.date)))
        }.frame(height: 6)
        Button {
          player.toggle()
        } label: {
          D1PlaybackGlyph(paused: !player.isPlaying).frame(width: 64, height: 64).background(
            Color.mib.action.primary, in: Circle())
        }.buttonStyle(.plain).frame(maxWidth: .infinity).disabled(player.sound == nil)
          .accessibilityLabel(player.isPlaying ? "일시정지" : "재생")
        HStack(spacing: 8) {
          D1Choice(title: "타이머 변경") { changingTimer = true }
          D1Choice(title: "다른 소리") { choosing = true }
          D1Choice(title: "끄기") {
            player.stop()
            choosing = true
          }
        }.frame(maxWidth: .infinity)
      }.padding(22).d1Surface(radius: 22)
    }
  }
  private func progress(at date: Date) -> Double {
    guard let duration = player.duration, duration > 0, let remaining = player.remaining(at: date)
    else { return 1 }
    return min(1, max(0, remaining / duration))
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
