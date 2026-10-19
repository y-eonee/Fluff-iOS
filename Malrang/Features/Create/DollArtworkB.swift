import SwiftUI

struct DollArtworkB: View {
    let shape: DollShape
    let cutout: Image
    var showsPhoto = true
    var faceScale: CGFloat = 1

    var body: some View {
        GeometryReader { proxy in
            let side = min(proxy.size.width, proxy.size.height)
            let isCat = shape == .cat
            let center = shape == .star ? CGPoint(x: 0.56, y: 0.44) : CGPoint(x: isCat ? 0.47 : 0.40, y: isCat ? 0.39 : 0.33)
            let faceSize = side * (shape == .star ? 0.34 : 0.29)
            ZStack {
                Image("b_doll_\(shape.rawValue)").resizable().scaledToFit()
                if showsPhoto {
                    cutout.resizable().scaledToFill()
                        .frame(width: faceSize, height: faceSize)
                        .scaleEffect(faceScale)
                        .clipShape(Circle())
                        .rotationEffect(.degrees(-18))
                        .position(x: side * center.x, y: side * center.y)
                }
            }
            .frame(width: side, height: side)
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
        .aspectRatio(1, contentMode: .fit)
    }
}

#Preview {
    HStack {
        ForEach([DollShape.bear, .star, .cat], id: \.self) { shape in
            DollArtworkB(shape: shape, cutout: Image(systemName: "photo"), showsPhoto: false)
        }
    }.padding().background(BBackground())
}
