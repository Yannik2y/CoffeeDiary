import SwiftUI

struct BrandPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedBrandId: String?
    @Binding var brandName: String

    @State private var searchText = ""
    @State private var visibleCount = 20

    private var filtered: [CoffeeBrand] {
        BrandDatabase.search(searchText)
    }

    private var visible: [CoffeeBrand] {
        Array(filtered.prefix(visibleCount))
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(visible) { brand in
                    Button {
                        selectedBrandId = brand.id
                        brandName = brand.name
                        dismiss()
                    } label: {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(brand.name)
                                    .foregroundStyle(AppTheme.textPrimary)
                                if let country = brand.country {
                                    Text(country)
                                        .font(.caption)
                                        .foregroundStyle(AppTheme.textSecondary)
                                }
                            }
                            Spacer()
                            if selectedBrandId == brand.id {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(AppTheme.accent)
                            }
                        }
                    }
                }

                if visibleCount < filtered.count {
                    Button("Load More".localized) {
                        visibleCount += 20
                    }
                }
            }
            .searchable(text: $searchText, prompt: Text("Search brands".localized))
            .navigationTitle("Select Brand".localized)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel".localized) { dismiss() }
                }
            }
        }
    }
}
