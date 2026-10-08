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

/// 편집을 끝낼 때 어디서나 같은 모양으로 쓰는 취소(보조) + 완료(주요) 쌍
struct CancelConfirmButtons: View {
    var confirmTitle = "완료"
    let onCancel: () -> Void
    let onConfirm: () -> Void

    var body: some View {
        HStack(spacing: Spacing.s) {
            Button("취소", action: onCancel)
                .buttonStyle(.secondary)
            Button(confirmTitle, action: onConfirm)
                .buttonStyle(.primary)
        }
    }
}

/// 추가하기 버튼. 메뉴가 열리면 X로 바뀐다.
struct FloatingAddButton: View {
    let label: String
    var isOpen = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "plus")
                .font(.title2.bold())
                .foregroundStyle(Color.app.ink)
                .rotationEffect(.degrees(isOpen ? 45 : 0))
                .frame(width: 56, height: 56)
                .background(Color.app.accent, in: Circle())
        }
        .accessibilityLabel(isOpen ? "닫기" : label)
        .animation(.spring, value: isOpen)
    }
}

/// 화면 위에 잠깐 띄우는 어두운 안내 말풍선
struct HintCapsule: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.footnote.bold())
            .foregroundStyle(Color.app.surface)
            .padding(.horizontal, Spacing.m)
            .frame(minHeight: 32)
            .background(Color.app.ink, in: Capsule())
    }
}

/// 선택 상태를 색과 체크 아이콘으로 함께 보여주는 칩
struct Chip: View {
    let title: String
    let isSelected: Bool
    /// 여러 칩을 한 줄에 같은 너비로 놓을 때 쓴다.
    var isCompact = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.xxs) {
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.caption.bold())
                }
                Text(title)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .font(isCompact ? .footnote : .body)
            .foregroundStyle(Color.app.ink)
            .frame(maxWidth: isCompact ? .infinity : nil)
            .padding(.horizontal, isCompact ? Spacing.xxs : Spacing.s)
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
