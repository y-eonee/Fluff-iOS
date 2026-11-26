import SwiftUI

struct PrivacyPolicyView: View {
    private struct Policy: Decodable {
        struct Section: Decodable { let title: String; let body: String }
        let publicURL: String?
        let supportEmail: String?
        let updated: String
        let sections: [Section]
    }
    private var policy: Policy? {
        guard let url = Bundle.main.url(forResource: "PrivacyPolicy", withExtension: "json"),
              let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(Policy.self, from: data)
    }
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                if let policy {
                    Text("최종 수정: \(policy.updated)").pretendard(.regular, 13)
                    ForEach(policy.sections, id: \.title) { section in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(section.title).pretendard(.semiBold, 17)
                            Text(section.body).pretendard(.regular, 15).lineSpacing(5)
                        }
                    }
                }
                if let policy, let address = policy.publicURL, let url = URL(string: address) {
                    Link("웹에서 개인정보처리방침 보기", destination: url)
                }
                if let policy, let email = policy.supportEmail, let url = URL(string: "mailto:" + email) {
                    Link("문의하기 · " + email, destination: url)
                }
                Link("Google 개인정보처리방침", destination: URL(string: "https://policies.google.com/privacy")!)
                Link("YouTube 이용약관", destination: URL(string: "https://www.youtube.com/t/terms")!)
                Link("Google 계정 연결 관리", destination: URL(string: "https://myaccount.google.com/connections")!)
                Link("Open-Meteo 정책", destination: URL(string: "https://open-meteo.com/en/terms")!)
                Link("Apple 로그인 연결 해제 안내", destination: URL(string: "https://support.apple.com/102571")!)
            }.padding(24).textSelection(.enabled)
        }.background(FlowDesign.canvas.ignoresSafeArea())
            .foregroundStyle(Color.mib.text.primary)
            .navigationTitle("개인정보처리방침").navigationBarTitleDisplayMode(.inline)
            .toolbar(.visible, for: .navigationBar)
    }
}
