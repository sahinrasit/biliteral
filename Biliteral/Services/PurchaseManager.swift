import Foundation
import Observation
import RevenueCat
import StoreKit

enum ProductID {
    static let lifetime = "com.sahinrasit.biliteral.lifetime"
    static let monthly = "com.sahinrasit.biliteral.monthly"
    static let all = [lifetime, monthly]
    static let entitlement = "pro"
}

struct PaywallOption: Identifiable, Equatable {
    enum Kind { case lifetime, monthly }
    let id: String
    let kind: Kind
    let price: String

    /// Launch prices from the pricing plan, for UI tests and screenshots where StoreKit has no products.
    static func samples(for locale: Locale) -> [PaywallOption] {
        // Screenshots set only the language, so fall back to the language's main market.
        let languageMarket: String = switch locale.language.languageCode?.identifier {
        case "tr": "TR"
        case "de": "DE"
        case "fr": "FR"
        case "es": "ES"
        case "it": "IT"
        case "nl": "NL"
        default: "US"
        }
        let market = locale.region?.identifier ?? languageMarket
        let (currency, lifetime, monthly): (String, Decimal, Decimal) = switch market {
        case "TR": ("TRY", 399.99, 89.99)
        case "GB": ("GBP", 12.99, 2.99)
        case "DE", "FR", "ES", "IT", "NL", "AT", "BE", "IE", "PT", "FI": ("EUR", 14.99, 2.99)
        default: ("USD", 14.99, 2.99)
        }
        let style = Decimal.FormatStyle.Currency(code: currency, locale: locale)
        return [
            PaywallOption(id: ProductID.lifetime, kind: .lifetime, price: lifetime.formatted(style)),
            PaywallOption(id: ProductID.monthly, kind: .monthly, price: monthly.formatted(style))
        ]
    }
}

/// Unlocks Biliteral Pro. Uses RevenueCat when an API key is configured, otherwise
/// StoreKit 2 directly, so local builds and the `.storekit` file work without a key.
@MainActor
@Observable
final class PurchaseManager {
    private(set) var isPro = false
    private(set) var options: [PaywallOption] = []
    private(set) var isPurchasing = false
    var errorMessage: String?

    private let usesRevenueCat: Bool
    private var rcPackages: [String: Package] = [:]
    private var skProducts: [String: Product] = [:]
    private var updatesTask: Task<Void, Never>?

    init(forcePro: Bool? = nil) {
        let key = (Bundle.main.object(forInfoDictionaryKey: "RevenueCatAPIKey") as? String)?
            .trimmingCharacters(in: .whitespaces) ?? ""
        usesRevenueCat = forcePro == nil && key.hasPrefix("appl_")
        if let forcePro {
            isPro = forcePro
            options = PaywallOption.samples(for: .current)
            return
        }
        if usesRevenueCat {
            Purchases.logLevel = .warn
            Purchases.configure(with: Configuration.Builder(withAPIKey: key)
                .with(storeKitVersion: .storeKit2)
                .build())
        }
        updatesTask = Task { [weak self] in await self?.listenForUpdates() }
    }

    func load() async {
        if usesRevenueCat {
            await loadRevenueCat()
        } else if updatesTask != nil {
            await loadStoreKit()
        }
    }

    func purchase(_ option: PaywallOption) async {
        isPurchasing = true
        defer { isPurchasing = false }
        do {
            if usesRevenueCat, let package = rcPackages[option.id] {
                let result = try await Purchases.shared.purchase(package: package)
                if !result.userCancelled { apply(result.customerInfo) }
            } else if let product = skProducts[option.id] {
                switch try await product.purchase() {
                case .success(let verification):
                    if case .verified(let transaction) = verification {
                        await transaction.finish()
                        await refreshStoreKitEntitlements()
                    }
                case .userCancelled, .pending: break
                @unknown default: break
                }
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func restore() async {
        isPurchasing = true
        defer { isPurchasing = false }
        do {
            if usesRevenueCat {
                apply(try await Purchases.shared.restorePurchases())
            } else {
                try await AppStore.sync()
                await refreshStoreKitEntitlements()
            }
            if !isPro { errorMessage = String(localized: "No previous purchase was found for this Apple Account.") }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: RevenueCat

    private func loadRevenueCat() async {
        if let info = try? await Purchases.shared.customerInfo() { apply(info) }
        guard let offering = try? await Purchases.shared.offerings().current else { return }
        var options: [PaywallOption] = []
        for package in [offering.lifetime, offering.monthly].compactMap({ $0 }) {
            let id = package.storeProduct.productIdentifier
            rcPackages[id] = package
            options.append(PaywallOption(id: id, kind: package.packageType == .lifetime ? .lifetime : .monthly,
                                         price: package.storeProduct.localizedPriceString))
        }
        self.options = options
    }

    private func apply(_ info: CustomerInfo) {
        isPro = info.entitlements[ProductID.entitlement]?.isActive == true
    }

    // MARK: StoreKit 2

    private func loadStoreKit() async {
        await refreshStoreKitEntitlements()
        guard let products = try? await Product.products(for: ProductID.all) else { return }
        for product in products { skProducts[product.id] = product }
        options = ProductID.all.compactMap { id in
            skProducts[id].map {
                PaywallOption(id: id, kind: id == ProductID.lifetime ? .lifetime : .monthly, price: $0.displayPrice)
            }
        }
    }

    private func refreshStoreKitEntitlements() async {
        var active = false
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result, ProductID.all.contains(transaction.productID),
               transaction.revocationDate == nil {
                active = true
            }
        }
        isPro = active
    }

    private func listenForUpdates() async {
        if usesRevenueCat {
            for await info in Purchases.shared.customerInfoStream { apply(info) }
        } else {
            for await result in Transaction.updates {
                if case .verified(let transaction) = result { await transaction.finish() }
                await refreshStoreKitEntitlements()
            }
        }
    }
}
