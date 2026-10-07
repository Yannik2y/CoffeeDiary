import SwiftUI
import StoreKit

struct TipJarView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var store = TipStore()

    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Buy me a coffee".localized)
                            .font(.title3.weight(.semibold))
                        Text("If Coffee Diary helps your daily shots, you can leave a small tip. Thank you!".localized)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }

                Section("Choose a tip".localized) {
                    if store.isLoading && store.products.isEmpty {
                        HStack {
                            ProgressView()
                            Text("Loading…".localized)
                                .foregroundStyle(.secondary)
                        }
                    } else if store.products.isEmpty {
                        Text(store.lastErrorMessage ?? "Tips are not available right now.".localized)
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(store.products, id: \.id) { product in
                            Button {
                                Task { await store.purchase(product) }
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(displayName(for: product))
                                            .foregroundStyle(.primary)
                                        Text(product.description)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    if store.purchaseInFlightID == product.id {
                                        ProgressView()
                                    } else {
                                        Text(product.displayPrice)
                                            .fontWeight(.semibold)
                                    }
                                }
                            }
                            .disabled(store.purchaseInFlightID != nil)
                        }
                    }
                }
            }
            .navigationTitle("Support Coffee Diary".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done".localized) { dismiss() }
                }
            }
            .task {
                await store.loadProducts()
            }
            .alert("Thank you!".localized, isPresented: Binding(
                get: { store.thankYouVisible },
                set: { if !$0 { store.dismissThankYou() } }
            )) {
                Button("OK".localized) { store.dismissThankYou() }
            } message: {
                Text("Your tip means a lot.".localized)
            }
            .alert("Error".localized, isPresented: Binding(
                get: { store.lastErrorMessage != nil && !store.products.isEmpty },
                set: { if !$0 { store.clearError() } }
            )) {
                Button("OK".localized, role: .cancel) { store.clearError() }
            } message: {
                if let message = store.lastErrorMessage {
                    Text(message)
                }
            }
        }
    }

    private func displayName(for product: Product) -> String {
        switch product.id {
        case "coffee.tip.small":
            return "Espresso".localized
        case "coffee.tip.medium":
            return "Doppelter Espresso".localized
        case "coffee.tip.large":
            return "Coffee & cake".localized
        case "coffee.tip.linea":
            return "Linea Mini".localized
        default:
            return product.displayName
        }
    }
}
