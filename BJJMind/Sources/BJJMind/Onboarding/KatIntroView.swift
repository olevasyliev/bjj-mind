import SwiftUI

struct KatIntroView: View {
    let belt: Belt
    let onAccept: () -> Void

    @State private var katScale: CGFloat = 0.88
    @State private var katOpacity: Double = 0.0
    @State private var displayedText = ""
    @State private var isTypingDone = false
    @State private var cursorOn = true

    private var fullMessage: String { L10n.KatIntro.message(for: belt) }

    private var cursorChar: String {
        guard !isTypingDone else { return "\"" }
        return cursorOn ? "|" : " "
    }

    var body: some View {
        ZStack {
            Color(hex: "#0f0f14").ignoresSafeArea()

            VStack(spacing: 0) {

                // Eyebrow
                Text(L10n.KatIntro.eyebrow)
                    .font(.nunito(11, weight: .bold))
                    .foregroundColor(.white.opacity(0.4))
                    .tracking(2)
                    .textCase(.uppercase)
                    .padding(.top, 52)
                    .padding(.bottom, 12)

                // Bubble — fixed height, text appears inside
                ZStack(alignment: .topLeading) {
                    // Invisible full text reserves no height — bubble is fixed
                    Text("\"\(fullMessage)\"")
                        .font(.bodyMd)
                        .lineSpacing(4)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .opacity(0)

                    // Visible typewriter text
                    Text("\"\(displayedText)\(cursorChar)")
                        .font(.bodyMd)
                        .foregroundColor(.white)
                        .lineSpacing(4)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .frame(height: 104)                 // ← fixed, never changes
                .background(Color(hex: "#1e1e28"))
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .padding(.horizontal, 24)

                // Tail — outside clipShape, seamlessly connected
                HStack(spacing: 0) {
                    Spacer().frame(width: 64)
                    BubbleTailDown()
                        .fill(Color(hex: "#1e1e28"))
                        .frame(width: 22, height: 12)
                    Spacer()
                }
                .offset(y: -1)

                // Kat — fixed height, never resizes
                Image("kat")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 460)              // ← fixed
                    .scaleEffect(katScale)
                    .opacity(katOpacity)

                // Name + belt — directly below Kat
                VStack(spacing: 4) {
                    Text(L10n.KatIntro.name)
                        .font(.screenTitle)
                        .foregroundColor(.white)
                        .tracking(-0.5)
                    Text(L10n.KatIntro.record)
                        .font(.bodySm)
                        .foregroundColor(.white.opacity(0.45))
                }
                .padding(.top, 6)

                Spacer(minLength: 16)

                // CTA
                VStack(spacing: 10) {
                    Button(action: onAccept) {
                        Text(L10n.KatIntro.cta)
                            .font(.labelXL)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(Color.brand)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    Text(L10n.KatIntro.unlockNote)
                        .font(.bodySm)
                        .foregroundColor(.white.opacity(0.4))
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 44)
            }
        }
        .task {
            withAnimation(.spring(response: 0.55, dampingFraction: 0.72)) {
                katScale = 1.0
                katOpacity = 1.0
            }
            Task { await blinkCursor() }
            try? await Task.sleep(for: .milliseconds(500))
            for char in fullMessage {
                try? await Task.sleep(for: .milliseconds(36))
                displayedText += String(char)
            }
            isTypingDone = true
        }
    }

    private func blinkCursor() async {
        while !isTypingDone {
            try? await Task.sleep(for: .milliseconds(450))
            cursorOn.toggle()
        }
    }
}

private struct BubbleTailDown: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.midX, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        p.closeSubpath()
        return p
    }
}
