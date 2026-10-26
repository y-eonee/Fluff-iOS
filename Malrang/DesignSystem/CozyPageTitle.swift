import SwiftUI

extension View {
    func cozyPageTitle(_ title: String) -> some View {
        navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.a.paper, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(title).notCliche(28, relativeTo: .title)
                        .foregroundStyle(Color.a.brown).accessibilityAddTraits(.isHeader)
                }
            }
    }
}
