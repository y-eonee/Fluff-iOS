import SwiftUI

extension View {
    func cozyPageTitle(_ title: String) -> some View {
        navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.a.paper, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    CozyTitleText(title: title, size: title == "couch time" || title == "focus together" ? 28 : 25.397)
                        .tracking(title == "making fluff" ? -1.7778 : 0)
                        .offset(y: title == "making fluff" ? 2 : 0)
                        .foregroundStyle(Color.a.brown).accessibilityAddTraits(.isHeader)
                }
            }
    }
}

/// Only Latin letters use the decorative face, even in mixed Korean/English titles.
struct CozyTitleText: View {
    let title: String
    var size: CGFloat = 28
    private var styled: AttributedString {
        var result = AttributedString()
        for character in title {
            let english = character.unicodeScalars.allSatisfy { (65...90).contains($0.value) || (97...122).contains($0.value) }
            var part = AttributedString(String(character))
            part.font = .custom(english ? "GmarketSansTTFMedium" : "Pretendard-SemiBold", size: size, relativeTo: .title)
            result.append(part)
        }
        return result
    }
    var body: some View {
        if title.unicodeScalars.allSatisfy({ $0.value < 128 }) {
            Text(title).notCliche(size, relativeTo: .title)
        } else {
            Text(styled)
        }
    }
}
