import Foundation
import StoreKit
import Observation

@Observable
@MainActor
final class TipStore {
    static let productIDs = [
        "coffee.tip.small",
        "coffee.tip.medium",
        "coffee.tip.large"
    ]

    private(set) var products: [Product] = []
    private(set) var isLoading = false
    private(set) var purchaseInFlightID: String?
    private(set) var lastErrorMessage: String?
    private(set) var thankYouVisible = false

    private var updatesTask: Task<Void, Never>?

    init() {
        updatesTask = Task { await listenForTransactions() }
    }

    func loadProducts() async {
        isLoading = true
        lastErrorMessage = nil
        defer { isLoading = false }
        do {
            let loaded = try await Product.products(for: Self.productIDs)
            products = loaded.sorted { $0.price < $1.price }
            if products.isEmpty {
                lastErrorMessage = "Tips are not available right now.".localized
            }
        } catch {
            lastErrorMessage = error.localizedDescription
            products = []
        }
    }

    func purchase(_ product: Product) async {
        purchaseInFlightID = product.id
        lastErrorMessage = nil
        defer { purchaseInFlightID = nil }
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await transaction.finish()
                thankYouVisible = true
            case .userCancelled, .pending:
                break
            @unknown default:
                break
            }
        } catch {
            lastErrorMessage = error.localizedDescription
        }
    }

    func dismissThankYou() {
        thankYouVisible = false
    }

    func clearError() {
        lastErrorMessage = nil
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw TipStoreError.failedVerification
        case .verified(let safe):
            return safe
        }
    }

    private func listenForTransactions() async {
        for await update in Transaction.updates {
            if let transaction = try? checkVerified(update) {
                await transaction.finish()
            }
        }
    }
}

enum TipStoreError: LocalizedError {
    case failedVerification

    var errorDescription: String? {
        "Purchase could not be verified.".localized
    }
}
