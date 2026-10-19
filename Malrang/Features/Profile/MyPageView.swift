import SwiftData
import SwiftUI

/// 마이페이지: 프로필, 친구 코드, 공개 범위, 앱 설정, 계정
struct MyPageView: View {
    @AppStorage("isSignedIn") private var isSignedIn = false
    @AppStorage("nickname") private var nickname = ""
    @AppStorage("avatarData") private var avatarData = Data()
    @AppStorage("friendCode") private var friendCode = ""
    @AppStorage("roomVisibility") private var visibility = Visibility.friends
    @AppStorage("acceptsFriendRequests") private var acceptsRequests = true
    @AppStorage("hapticOn") private var hapticOn = true
    @AppStorage("soundOn") private var soundOn = true
    @AppStorage("notificationsOn") private var notificationsOn = true
    @AppStorage("designVariant") private var variant = DesignVariant.a
    @Environment(\.openURL) private var openURL
    @State private var isChoosingVisibility = false
    @State private var isConfirmingLogout = false
    @State private var didCopy = false

    enum Visibility: String {
        case friends = "친구만"
        case privateRoom = "비공개"
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.l) {
                profileCard
                section("공유·공개 설정") {
                    Button {
                        isChoosingVisibility = true
                    } label: {
                        row("내 방 공개 범위") {
                            Text(visibility.rawValue).foregroundStyle(Color.app.inkSecondary)
                            Image(systemName: "chevron.right").foregroundStyle(Color.app.inkSecondary)
                        }
                    }
                    Toggle("친구 요청 받기", isOn: $acceptsRequests).frame(minHeight: 52)
                }
                section("디자인 시안") {
                    Picker("디자인 시안", selection: $variant) {
                        Text("시안 A").tag(DesignVariant.a)
                        Text("시안 B").tag(DesignVariant.b)
                    }
                    .pickerStyle(.segmented)
                    Text("내 방, 솜뭉치 만들기, 방 꾸미기 화면이 바뀌어요. 시안 B는 준비 중이라 지금은 기존 디자인으로 보여요")
                        .appFont(.footnote)
                        .foregroundStyle(Color.app.inkSecondary)
                        .padding(.top, Spacing.xs)
                }
                section("앱 설정") {
                    Toggle("햅틱(진동)", isOn: $hapticOn).frame(minHeight: 52)
                    Toggle("사운드", isOn: $soundOn).frame(minHeight: 52)
                    Toggle("알림 허용", isOn: $notificationsOn).frame(minHeight: 52)
                    Button {
                        if let url = URL(string: UIApplication.openSettingsURLString) { openURL(url) }
                    } label: {
                        row("사진·카메라 접근") {
                            Text("기기 설정").foregroundStyle(Color.app.inkSecondary)
                            Image(systemName: "chevron.right").foregroundStyle(Color.app.inkSecondary)
                        }
                    }
                    row("앱 버전") {
                        Text(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0")
                            .foregroundStyle(Color.app.inkSecondary)
                    }
                }
                Button("로그아웃") { isConfirmingLogout = true }
                .appFont(.footnote)
                .foregroundStyle(Color.app.inkSecondary)
                .frame(maxWidth: .infinity, minHeight: 44)
            }
            .tint(Color.app.accent)
            .foregroundStyle(Color.app.ink)
            .padding(Spacing.m)
        }
        .background { AppBackground() }
        .navigationTitle("마이페이지")
        .notebookTabBar()
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if friendCode.isEmpty {
                friendCode = String("ABCDEFGHJKLMNPQRSTUVWXYZ23456789".shuffled().prefix(7))
            }
        }
        .confirmationDialog("내 방을 누구에게 보여줄까요?", isPresented: $isChoosingVisibility, titleVisibility: .visible) {
            Button("친구만") { visibility = .friends }
            Button("비공개") { visibility = .privateRoom }
        }
        .confirmationDialog("로그아웃할까요?", isPresented: $isConfirmingLogout, titleVisibility: .visible) {
            Button("로그아웃", role: .destructive) { isSignedIn = false }
        } message: {
            Text("인형과 방은 그대로 남아 있어요")
        }
        .sensoryFeedback(.success, trigger: didCopy)
    }

    private var profileCard: some View {
        VStack(alignment: .leading, spacing: Spacing.m) {
            NavigationLink {
                ProfileEditView()
            } label: {
                HStack(spacing: Spacing.s) {
                    ProfileAvatar(data: avatarData, size: 64)
                    VStack(alignment: .leading, spacing: Spacing.xxs) {
                        Text(nickname).appFont(.headline)
                        Text("프로필 편집 ›").appFont(.footnote).foregroundStyle(Color.app.inkSecondary)
                    }
                    Spacer()
                }
                .frame(minHeight: 64)
            }
            Divider()
            HStack {
                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    Text("내 친구 코드").appFont(.footnote).foregroundStyle(Color.app.inkSecondary)
                    Text(friendCode).appFont(.title2, .bold).tracking(2)
                    Text("친구를 추가하고 친구의 방을 구경하고 함께 방을 꾸며보세요")
                        .appFont(.footnote)
                        .foregroundStyle(Color.app.inkSecondary)
                }
                Spacer()
                Button(didCopy ? "복사됨" : "복사") {
                    UIPasteboard.general.string = friendCode
                    didCopy = true
                }
                .buttonStyle(.bordered)
                .frame(minHeight: 44)
            }
            ShareLink(item: "Fluff에서 내 방에 놀러 와요! 친구 코드: \(friendCode)") {
                Text("초대 링크 공유하기")
            }
            .buttonStyle(.primary)
        }
        .padding(Spacing.m)
        .cardStyle()
    }

    private func section(_ title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title).appFont(.headline).padding(.bottom, Spacing.xs)
            content()
        }
    }

    private func row(_ title: String, @ViewBuilder trailing: () -> some View) -> some View {
        HStack(spacing: Spacing.xxs) {
            Text(title)
            Spacer()
            trailing()
        }
        .appFont(.body)
        .frame(minHeight: 52)
    }
}

#Preview {
    NavigationStack { MyPageView() }
        .modelContainer(.preview)
}
