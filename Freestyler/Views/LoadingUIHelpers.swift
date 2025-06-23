import SwiftUI

struct PulseEffect: ViewModifier {
    @State private var scale: CGFloat = 1.0
    func body(content: Content) -> some View {
        content
            .scaleEffect(scale)
            .animation(
                Animation.easeInOut(duration: 0.9).repeatForever(autoreverses: true),
                value: scale
            )
            .onAppear { scale = 1.15 }
    }
}

struct VisualEffectBlur: UIViewRepresentable {
    var blurStyle: UIBlurEffect.Style
    func makeUIView(context: Context) -> UIVisualEffectView {
        return UIVisualEffectView(effect: UIBlurEffect(style: blurStyle))
    }
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {}
} 