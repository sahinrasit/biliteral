import SwiftUI

struct PaywallView: View {
    @Environment(PurchaseManager.self) private var purchases
    @Environment(\.dismiss) private var dismiss
    @State private var selected: String = ProductID.lifetime

    var body: some View {
        @Bindable var purchases = purchases
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    VStack(spacing: 10) {
                        Image(systemName: "book.pages.fill")
                            .font(.system(size: 56))
                            .foregroundStyle(.tint)
                            .padding(.top, 8)
                        Text("Read any book in two languages")
                            .font(.title.bold())
                            .multilineTextAlignment(.center)
                        Text("Your books, translated on your device. Pay once, keep it forever.")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        Benefit("Unlimited books and articles", systemImage: "books.vertical")
                        Benefit("Side-by-side on-device translation", systemImage: "rectangle.split.2x1")
                        Benefit("Dictionary and one-tap flashcards", systemImage: "rectangle.stack")
                        Benefit("Offline, private, no ads", systemImage: "airplane")
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    VStack(spacing: 12) {
                        if purchases.options.isEmpty {
                            ProgressView()
                                .frame(height: 120)
                        }
                        ForEach(purchases.options) { option in
                            OptionCard(option: option, isSelected: selected == option.id) {
                                selected = option.id
                            }
                        }
                    }

                    Button {
                        guard let option = purchases.options.first(where: { $0.id == selected }) else { return }
                        Task { await purchases.purchase(option) }
                    } label: {
                        Group {
                            if purchases.isPurchasing {
                                ProgressView()
                            } else {
                                Text("Continue")
                            }
                        }
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                    }
                    .prominentButtonStyle()
                    .controlSize(.large)
                    .disabled(purchases.isPurchasing || purchases.options.isEmpty)
                    .accessibilityIdentifier("purchaseButton")

                    VStack(spacing: 8) {
                        Button("Restore Purchases") { Task { await purchases.restore() } }
                            .disabled(purchases.isPurchasing)
                        HStack(spacing: 16) {
                            Link("Terms of Use", destination: Links.terms)
                            Link("Privacy Policy", destination: Links.privacy)
                        }
                        .font(.footnote)
                        Text("The monthly plan renews automatically until cancelled at least 24 hours before the end of the period. Manage it in your App Store account settings.")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding()
                .frame(maxWidth: 520)
                .frame(maxWidth: .infinity)
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Label("Close", systemImage: "xmark")
                    }
                    .accessibilityIdentifier("paywallClose")
                }
            }
            .alert("Purchase", isPresented: .init(get: { purchases.errorMessage != nil },
                                                  set: { if !$0 { purchases.errorMessage = nil } })) {
                Button("OK") {}
            } message: {
                Text(purchases.errorMessage ?? "")
            }
        }
        .accessibilityIdentifier("paywall")
        .onChange(of: purchases.isPro) { _, isPro in
            if isPro { dismiss() }
        }
    }
}

private struct Benefit: View {
    let title: LocalizedStringKey
    let systemImage: String

    init(_ title: LocalizedStringKey, systemImage: String) {
        self.title = title
        self.systemImage = systemImage
    }

    var body: some View {
        Label {
            Text(title)
        } icon: {
            Image(systemName: systemImage)
                .foregroundStyle(.tint)
                .frame(width: 28)
        }
    }
}

private struct OptionCard: View {
    let option: PaywallOption
    let isSelected: Bool
    var onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(alignment: .center, spacing: 12) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(isSelected ? AnyShapeStyle(.tint) : AnyShapeStyle(.secondary))
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(option.kind == .lifetime ? "Lifetime" : "Monthly")
                            .font(.headline)
                        if option.kind == .lifetime {
                            Text("Best value")
                                .font(.caption2.weight(.bold))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(.tint, in: .capsule)
                                .foregroundStyle(.white)
                        }
                    }
                    Text(option.kind == .lifetime ? "Pay once, keep forever" : "Cancel anytime")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                VStack(alignment: .trailing) {
                    Text(option.price)
                        .font(.headline)
                    if option.kind == .monthly {
                        Text("per month").font(.caption).foregroundStyle(.secondary)
                    }
                }
            }
            .padding()
            .background(Color(.secondarySystemBackground), in: .rect(cornerRadius: 16))
            .overlay {
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(isSelected ? Color.accentColor : .clear, lineWidth: 2)
            }
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

extension View {
    /// Liquid Glass on iOS 26, the classic prominent style before.
    @ViewBuilder
    func prominentButtonStyle() -> some View {
        if #available(iOS 26.0, *) {
            buttonStyle(.glassProminent)
        } else {
            buttonStyle(.borderedProminent)
        }
    }
}
