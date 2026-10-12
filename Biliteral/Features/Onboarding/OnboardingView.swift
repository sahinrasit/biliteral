import SwiftUI

struct OnboardingView: View {
    var onFinish: () -> Void
    @State private var page = 0

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $page) {
                OnboardingPage(title: "Your book. Two languages.",
                               message: "The original on the left, the translation on the right, sentence by sentence. On a phone, the translation sits under each paragraph.") {
                    TwoPageIllustration()
                }
                .tag(0)
                OnboardingPage(title: "Tap a sentence, then a word",
                               message: "The matching sentence lights up. Tap any word for its meaning and the dictionary, and keep it as a flashcard.") {
                    WordIllustration()
                }
                .tag(1)
                OnboardingPage(title: "Offline. Private. Yours.",
                               message: "Translation runs on your device, so nothing you read is uploaded. Open DRM-free EPUB and PDF files, web articles or pasted text.") {
                    PrivacyIllustration()
                }
                .tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .indexViewStyle(.page(backgroundDisplayMode: .always))

            Button {
                if page < 2 {
                    withAnimation { page += 1 }
                } else {
                    onFinish()
                }
            } label: {
                Text(page < 2 ? "Continue" : "Start Reading")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
            }
            .prominentButtonStyle()
            .controlSize(.large)
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
            .frame(maxWidth: 520)
            .accessibilityIdentifier("onboardingContinue")
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
    }
}

private struct OnboardingPage<Illustration: View>: View {
    let title: LocalizedStringKey
    let message: LocalizedStringKey
    @ViewBuilder var illustration: Illustration

    var body: some View {
        VStack(spacing: 28) {
            Spacer(minLength: 12)
            illustration
                .frame(maxWidth: 420, maxHeight: 300)
            VStack(spacing: 12) {
                Text(title)
                    .font(.largeTitle.bold())
                    .multilineTextAlignment(.center)
                Text(message)
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 28)
            .frame(maxWidth: 560)
            Spacer(minLength: 48)
        }
    }
}

/// An open book: "original" lines on the left page, "translation" lines on the right, one pair highlighted.
private struct TwoPageIllustration: View {
    var body: some View {
        HStack(spacing: 0) {
            page(text: ["“Have some wine,” the", "March Hare said in an", "encouraging tone."], highlight: 1)
            Rectangle().fill(.secondary.opacity(0.3)).frame(width: 1)
            page(text: ["—Toma un poco de vino", "—dijo la Liebre de Marzo", "en tono alentador."], highlight: 1)
        }
        .background(Color(.systemBackground), in: .rect(cornerRadius: 18))
        .shadow(color: .black.opacity(0.12), radius: 14, y: 6)
        .padding(.horizontal, 24)
        .accessibilityHidden(true)
    }

    private func page(text: [String], highlight: Int) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(0..<4, id: \.self) { _ in
                RoundedRectangle(cornerRadius: 3).fill(.secondary.opacity(0.2)).frame(height: 7)
            }
            VStack(alignment: .leading, spacing: 2) {
                ForEach(text, id: \.self) { line in
                    Text(line).font(.system(size: 13, design: .serif))
                }
            }
            .padding(6)
            .background(Color.accentColor.opacity(0.18), in: .rect(cornerRadius: 6))
            ForEach(0..<3, id: \.self) { _ in
                RoundedRectangle(cornerRadius: 3).fill(.secondary.opacity(0.2)).frame(height: 7)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity)
    }
}

private struct WordIllustration: View {
    var body: some View {
        VStack(spacing: 16) {
            (Text("“Your hair wants ") + Text("cutting").bold().foregroundColor(.accentColor) + Text(",” said the Hatter."))
                .font(.system(size: 18, design: .serif))
                .padding(12)
                .background(Color.accentColor.opacity(0.12), in: .rect(cornerRadius: 10))
            VStack(alignment: .leading, spacing: 8) {
                Text("cutting").font(.title2.bold())
                Text("corte · cortar").foregroundStyle(.tint)
                Label("Added to flashcards", systemImage: "checkmark.circle.fill")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.green)
            }
            .padding(18)
            .frame(maxWidth: 260, alignment: .leading)
            .background(Color(.systemBackground), in: .rect(cornerRadius: 16))
            .shadow(color: .black.opacity(0.12), radius: 12, y: 5)
        }
        .padding(.horizontal, 24)
        .accessibilityHidden(true)
    }
}

private struct PrivacyIllustration: View {
    var body: some View {
        ZStack {
            Circle().fill(Color.accentColor.opacity(0.12)).frame(width: 220, height: 220)
            Image(systemName: "airplane")
                .font(.system(size: 34, weight: .semibold))
                .foregroundStyle(.tint)
                .offset(x: 78, y: -78)
            Image(systemName: "iphone.gen3")
                .font(.system(size: 110, weight: .thin))
            Image(systemName: "lock.fill")
                .font(.system(size: 30))
                .foregroundStyle(.tint)
                .offset(y: 4)
        }
        .accessibilityHidden(true)
    }
}
