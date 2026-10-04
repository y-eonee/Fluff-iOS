import SwiftUI

struct PrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(Color.app.ink)
            .frame(maxWidth: .infinity, minHeight: 56)
            .background(Color.app.accent, in: RoundedRectangle(cornerRadius: Radius.large, style: .continuous))
            .opacity(isEnabled ? (configuration.isPressed ? 0.8 : 1) : 0.4)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(Color.app.ink)
            .frame(maxWidth: .infinity, minHeight: 56)
            .background(Color.app.surface, in: RoundedRectangle(cornerRadius: Radius.large, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: Radius.large, style: .continuous).stroke(Color.app.ink.opacity(0.15)))
            .opacity(configuration.isPressed ? 0.7 : 1)
    }
}

extension ButtonStyle where Self == PrimaryButtonStyle {
    static var primary: PrimaryButtonStyle { PrimaryButtonStyle() }
}

extension ButtonStyle where Self == SecondaryButtonStyle {
    static var secondary: SecondaryButtonStyle { SecondaryButtonStyle() }
}

/// 선택 상태를 색과 체크 아이콘으로 함께 보여주는 칩
struct Chip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.xxs) {
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.footnote.bold())
                }
                Text(title)
            }
            .font(.body)
            .foregroundStyle(Color.app.ink)
            .padding(.horizontal, Spacing.s)
            .frame(minHeight: 44)
            .background(isSelected ? Color.app.accent : Color.app.surface,
                        in: RoundedRectangle(cornerRadius: Radius.small, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: Radius.small, style: .continuous)
                .stroke(isSelected ? Color.app.ink : Color.app.ink.opacity(0.15)))
        }
        .buttonStyle(.plain)
    }
}

/// 내용이 없거나 실패했을 때 쓰는 안내 카드
struct NoticeCard: View {
    let symbol: String
    let title: String
    let message: String
    var actionTitle: String?
    var action: () -> Void = {}

    var body: some View {
        VStack(spacing: Spacing.s) {
            Image(systemName: symbol)
                .font(.largeTitle)
                .foregroundStyle(Color.app.inkSecondary)
            Text(title)
                .font(.headline)
            Text(message)
                .font(.footnote)
                .foregroundStyle(Color.app.inkSecondary)
                .multilineTextAlignment(.center)
            if let actionTitle {
                Button(actionTitle, action: action)
                    .buttonStyle(.primary)
                    .padding(.top, Spacing.xs)
            }
        }
        .foregroundStyle(Color.app.ink)
        .padding(Spacing.l)
        .cardStyle()
        .padding(.horizontal, Spacing.l)
    }
}

#Preview {
    VStack(spacing: Spacing.m) {
        Button("인형 만들기") {}.buttonStyle(.primary)
        Button("다시 선택") {}.buttonStyle(.secondary)
        HStack {
            Chip(title: "곰인형", isSelected: true) {}
            Chip(title: "별인형", isSelected: false) {}
        }
        NoticeCard(symbol: "teddybear", title: "아직 방이 비어 있어요", message: "갤러리 속 사진으로 첫 인형을 만들어 보세요", actionTitle: "첫 인형 만들러 가기")
    }
    .padding(Spacing.m)
    .background(Color.app.background)
}
