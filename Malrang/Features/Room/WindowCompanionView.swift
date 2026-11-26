import SwiftUI

struct WindowCompanionView: View {
  let dolls: [DollState]
  var frameColor: String? = nil
  @Environment(\.dismiss) private var dismiss
  @State private var weather = WindowWeather()
  @State private var bubbleIndex = 0
  @State private var showBubble = true
  @State private var speechAnchor: CGPoint?
  @State private var speechSize = CGSize(width:246,height:52)
  private let phrases = ["저 구름 토끼 닮았다!", "같이 보니까 더 좋다", "구름이 천천히 흘러가네"]
  var body: some View {
    GeometryReader { geo in
      TimelineView(.periodic(from: .now, by: 60)) { _ in
        let hour = RoomDaylight.at(RoomDaylight.currentDate).hour
        ZStack(alignment: .top) {
          Color.mib.bg.screen.ignoresSafeArea()
          CompanionScene(dolls: dolls, kind: .window(hour: hour, weather: weather.code), windowFrameColor: frameColor, onSpeechAnchor: { speechAnchor = $0 })
            .frame(maxWidth: .infinity, maxHeight: .infinity).ignoresSafeArea()
            .accessibilityLabel("\(dolls.map(\.name).joined(separator:", "))와 함께 창밖 구경")
          VStack {
            HStack(alignment: .top) {
              D1IconButton(icon: "back", label: "내 방으로") { dismiss() }
              Spacer()
              VStack(alignment: .trailing, spacing: 4) {
                Text(RoomDaylight.currentDate, format: .dateTime.hour().minute())
                Text(weather.label)
              }.pretendard(.medium, 13).padding(.horizontal,14).padding(.vertical,10)
                .foregroundStyle(Color.rep4.c08)
                .glassEffect(.regular.tint(.white.opacity(0.24)), in: RoundedRectangle(cornerRadius:18))
                .overlay(RoundedRectangle(cornerRadius:18).strokeBorder(CozyHomeStyle.glassHighlight,lineWidth:0.65))
                .accessibilityIdentifier("window-time-weather")
            }
            Spacer()
          }.padding(.horizontal,22).padding(.top,10)
          if showBubble, let anchor = speechAnchor {
            Text(hour >= 20 || hour < 6 ? "별 보인다! 소원 빌자"
                 : hour >= 17 ? "하늘이 주황색이 됐어" : phrases[bubbleIndex % phrases.count])
              .pretendard(.medium,13).multilineTextAlignment(.center)
              .foregroundStyle(Color.rep4.c08)
              .padding(.horizontal,16).padding(.vertical,11).padding(.bottom,8)
              .frame(maxWidth:min(246,geo.size.width-44))
              .glassEffect(.regular.tint(.white.opacity(0.24)), in: WindowSpeechShape())
              .overlay(WindowSpeechShape().stroke(CozyHomeStyle.glassHighlight,lineWidth:0.65))
              .onGeometryChange(for:CGSize.self, of: { $0.size }) { speechSize = $0 }
              .position(x:min(max(anchor.x,speechSize.width/2+16),geo.size.width-speechSize.width/2-16),
                        y:max(120,anchor.y-geo.safeAreaInsets.top-10-speechSize.height/2))
              .allowsHitTesting(false)
              .accessibilityIdentifier("window-character-speech")
          }
          VStack {
            Spacer()
            Link("Weather data: Open-Meteo", destination: URL(string: "https://open-meteo.com/")!)
              .pretendard(.medium, 11).foregroundStyle(Color.mib.text.secondary)
          }.padding(.bottom, 8)
        }
      }
    }.background(Color.mib.bg.screen)
      .task { weather.start() }
      .task(id: speechAnchor != nil) {
        guard speechAnchor != nil else { return }
        showBubble = true
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("--window-bubble-preview") { return }
        #endif
        while !Task.isCancelled {
          do { try await Task.sleep(for: .seconds(showBubble ? 6 : 14)) } catch { return }
          showBubble.toggle()
          if showBubble { bubbleIndex += 1 }
        }
      }
  }
}

/// One continuous glass outline includes the small tail pointing to the speaking doll.
private struct WindowSpeechShape: Shape {
  func path(in rect: CGRect) -> Path {
    let r: CGFloat = 18, bottom = rect.maxY-8, center = rect.midX
    var p = Path()
    p.move(to:CGPoint(x:r,y:0));p.addLine(to:CGPoint(x:rect.maxX-r,y:0))
    p.addQuadCurve(to:CGPoint(x:rect.maxX,y:r),control:CGPoint(x:rect.maxX,y:0))
    p.addLine(to:CGPoint(x:rect.maxX,y:bottom-r))
    p.addQuadCurve(to:CGPoint(x:rect.maxX-r,y:bottom),control:CGPoint(x:rect.maxX,y:bottom))
    p.addLine(to:CGPoint(x:center+8,y:bottom))
    p.addQuadCurve(to:CGPoint(x:center+2,y:bottom+7),control:CGPoint(x:center+4,y:bottom+6))
    p.addQuadCurve(to:CGPoint(x:center-2,y:bottom+7),control:CGPoint(x:center,y:bottom+9))
    p.addQuadCurve(to:CGPoint(x:center-8,y:bottom),control:CGPoint(x:center-4,y:bottom+6))
    p.addLine(to:CGPoint(x:r,y:bottom))
    p.addQuadCurve(to:CGPoint(x:0,y:bottom-r),control:CGPoint(x:0,y:bottom))
    p.addLine(to:CGPoint(x:0,y:r))
    p.addQuadCurve(to:CGPoint(x:r,y:0),control:CGPoint(x:0,y:0))
    p.closeSubpath();return p
  }
}
