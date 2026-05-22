import SwiftUI

struct QRCodeImageView: View {
    let image: UIImage?

    var body: some View {
        Group {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .interpolation(.none)
                    .scaledToFit()
                    .padding(12)
                    .background(.white, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            } else {
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color.secondary.opacity(0.1))
                    .overlay {
                        Image(systemName: "qrcode")
                            .font(.system(size: 36, weight: .light))
                            .foregroundStyle(.secondary)
                    }
            }
        }
        .frame(maxWidth: .infinity, minHeight: 180)
    }
}
