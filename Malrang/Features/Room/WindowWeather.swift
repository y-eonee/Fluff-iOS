import CoreLocation
import Observation

@MainActor @Observable
final class WindowWeather: NSObject, CLLocationManagerDelegate {
  var label = "현재 위치의 날씨"
  var code = 0
  private let manager = CLLocationManager()
  private var request: Task<Void, Never>?
  override init() {
    super.init()
    manager.delegate = self
    manager.desiredAccuracy = kCLLocationAccuracyThreeKilometers
  }
  func start() {
    switch manager.authorizationStatus {
    case .notDetermined: manager.requestWhenInUseAuthorization()
    case .authorizedAlways, .authorizedWhenInUse: manager.requestLocation()
    default: label = "위치 권한 없이 구경 중"
    }
  }
  func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
    if manager.authorizationStatus == .authorizedWhenInUse
      || manager.authorizationStatus == .authorizedAlways
    {
      manager.requestLocation()
    } else if manager.authorizationStatus != .notDetermined {
      label = "위치 권한 없이 구경 중"
    }
  }
  func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
    label = "날씨를 불러올 수 없어요"
  }
  func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    guard let location = locations.last else { return }
    request?.cancel()
    request = Task {
      do {
        let coordinate = location.coordinate
        var url = URLComponents(string: "https://api.open-meteo.com/v1/forecast")!
        url.queryItems = [
          .init(name: "latitude", value: String(format: "%.2f", coordinate.latitude)),
          .init(name: "longitude", value: String(format: "%.2f", coordinate.longitude)),
          .init(name: "current", value: "temperature_2m,weather_code"),
        ]
        var query = URLRequest(url: url.url!)
        query.timeoutInterval = 12
        let (data, response) = try await URLSession.shared.data(for: query)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
          throw URLError(.badServerResponse)
        }
        let result = try JSONDecoder().decode(Response.self, from: data)
        guard !Task.isCancelled else { return }
        code = result.current.weather_code
        let name =
          code == 0
          ? "맑음"
          : code <= 3
            ? "흐림"
            : (71...77).contains(code) || code == 85 || code == 86 ? "눈" : code >= 51 ? "비" : "안개"
        label = "\(name) · \(Int(result.current.temperature_2m.rounded()))°"
      } catch { if !Task.isCancelled { label = "날씨를 불러올 수 없어요" } }
    }
  }
  private struct Response: Decodable {
    let current: Current
    struct Current: Decodable {
      let temperature_2m: Double
      let weather_code: Int
    }
  }
}
