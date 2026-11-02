import SwiftUI

struct WindowCompanionView: View {
  let dolls: [DollState]
  @Environment(\.dismiss) private var dismiss
  @State private var weather = WindowWeather()
  @State private var bubbleIndex = 0
  @State private var showBubble = true
  private let phrases = ["저 구름 토끼 닮았다!", "같이 보니까 더 좋다", "구름이 천천히 흘러가네"]
  var body: some View {
    GeometryReader { geo in
      TimelineView(.periodic(from: .now, by: 60)) { context in
        let hour = Calendar.current.component(.hour, from: context.date)
        ZStack(alignment: .top) {
          Color.mib.bg.screen.ignoresSafeArea()
          CompanionScene(dolls: dolls, kind: .window(hour: hour, weather: weather.code))
            .frame(maxWidth: .infinity, maxHeight: .infinity).ignoresSafeArea()
            .accessibilityLabel("\(dolls.map(\.name).joined(separator:", "))와 함께 창밖 구경")
          VStack {
            HStack(alignment: .top) {
              D1IconButton(icon: "back", label: "내 방으로") { dismiss() }
              Spacer()
              VStack(alignment: .trailing, spacing: 4) {
                Text(context.date, format: .dateTime.hour().minute())
                Text(weather.label)
              }.pretendard(.medium, 13).padding(12).d1Surface(radius: 14)
            }
            Spacer()
            if showBubble {
              D1Bubble(
                text: hour >= 20 || hour < 6
                  ? "별 보인다! 소원 빌자"
                  : hour >= 17 ? "하늘이 주황색이 됐어" : phrases[bubbleIndex % phrases.count]
              ).frame(maxWidth: 246)
            }
            Spacer().frame(height: geo.size.height * 0.48)
          }.padding(.horizontal, 22).padding(.top, 10)
          VStack {
            Spacer()
            Link("Weather data: Open-Meteo", destination: URL(string: "https://open-meteo.com/")!)
              .pretendard(.medium, 11).foregroundStyle(Color.mib.text.secondary)
          }.padding(.bottom, 8)
        }
      }
    }.background(Color.mib.bg.screen)
      .task {
        weather.start()
        while !Task.isCancelled {
          do { try await Task.sleep(for: .seconds(showBubble ? 6 : 14)) } catch { return }
          showBubble.toggle()
          if showBubble { bubbleIndex += 1 }
        }
      }
  }
}
