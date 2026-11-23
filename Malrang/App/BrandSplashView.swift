import SwiftUI

/// Brand artwork from 1928:2; lockup proportions and lettering from 1918:7534.
struct BrandSplashView: View {
    var body: some View {
        ZStack {
            LinearGradient(stops: [
                .init(color: Color(uiColor: Palette.uiColor("#FEFEFE")), location: 0.10938),
                .init(color: Color(uiColor: Palette.uiColor("#C5EFFC")), location: 0.89062)
            ], startPoint: UnitPoint(x: 0.18, y: 0), endPoint: UnitPoint(x: 0.82, y: 1))
            ZStack(alignment: .topLeading) {
                Image("fluff_splash_character").resizable().scaledToFit()
                    .frame(width: 125, height: 125).offset(x: 31, y: 14.81)
                Text("fluff").notCliche(33.897, relativeTo: .title).tracking(-2.3728)
                    .foregroundStyle(Color.rep4.c10).offset(x: 66.54, y: 139.81)
            }.frame(width: 196.087, height: 196.087, alignment: .topLeading)
                .scaleEffect(1.35)
                .dynamicTypeSize(.medium)
        }.ignoresSafeArea().accessibilityElement(children: .ignore)
            .accessibilityLabel("fluff").accessibilityIdentifier("fluff-brand-splash")
    }
}

#Preview { BrandSplashView() }
