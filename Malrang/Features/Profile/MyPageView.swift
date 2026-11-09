import SwiftData
import SwiftUI

struct MyPageView: View {
    @AppStorage("nickname") private var nickname = ""
    @AppStorage("avatarData") private var avatarData = Data()
    @AppStorage("hapticOn") private var hapticOn = true
    @AppStorage("soundOn") private var soundOn = true
    @Environment(AppState.self) private var appState
    @Environment(\.openURL) private var openURL

    var body: some View {
        VStack(spacing: 24) {
            Text("my page").notCliche(28, relativeTo: .title).tracking(-1.12).frame(height: 44)
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    NavigationLink { ProfileEditView() } label: {
                        HStack(spacing: 12) {
                            ProfileAvatar(data: avatarData, size: 64)
                            VStack(alignment: .leading, spacing: 4) {
                                Text(nickname.isEmpty ? "나의 인형 방" : nickname).pretendard(.bold, 17)
                                Text("프로필 편집").pretendard(.medium, 13).foregroundStyle(Color.mib.text.secondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right").font(.system(size: 13, weight: .medium)).accessibilityHidden(true)
                        }.padding(16).d1Surface(radius: 14)
                    }.buttonStyle(.plain)
                    VStack(alignment: .leading, spacing: 12) {
                        Text("앱 설정").pretendard(.bold, 17)
                        VStack(spacing: 0) {
                            Toggle("햅틱(진동)", isOn: $hapticOn).frame(minHeight: 52)
                            separator
                            Toggle("사운드", isOn: $soundOn).frame(minHeight: 52)
                            separator
                            Button {
                                if let url = URL(string: UIApplication.openSettingsURLString) { openURL(url) }
                            } label: {
                                HStack {
                                    Text("사진·카메라 접근")
                                    Spacer()
                                    Text("기기 설정").pretendard(.medium, 13).foregroundStyle(Color.mib.text.secondary)
                                    Image(systemName: "chevron.right").font(.system(size: 13, weight: .medium)).accessibilityHidden(true)
                                }.frame(minHeight: 52).contentShape(Rectangle())
                            }.buttonStyle(.plain)
                            separator
                            HStack {
                                Text("앱 버전")
                                Spacer()
                                Text(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0").foregroundStyle(Color.mib.text.secondary)
                            }.frame(minHeight: 52)
                        }.pretendard(.regular, 16).padding(.horizontal, 16).d1Surface(radius: 14)
                    }
                }.padding(.horizontal, 22).padding(.bottom, 24)
            }.scrollIndicators(.hidden)
        }.foregroundStyle(Color.mib.text.primary).tint(Color.mib.action.primary).background(Color.mib.bg.screen)
            .toolbar(.hidden, for: .navigationBar)
    }

    private var separator: some View { Rectangle().fill(Color.mib.line.default).frame(height: 1) }
}

#Preview { NavigationStack { MyPageView() }.environment(AppState()).modelContainer(.preview) }
