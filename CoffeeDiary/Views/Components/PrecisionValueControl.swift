import SwiftUI

/// Precise numeric entry: large tappable field plus stepper. Slider is not used
/// because brew metrics need exact grams/seconds, not a relative position.
struct PrecisionValueControl: View {
    @Binding var value: Double
    var step: Double = 0.1
    var unit: String
    var suggestedRange: ClosedRange<Double>? = nil
    var rangeHint: String? = nil
    var fractionDigits: Int = 1

    @State private var text: String = ""
    @FocusState private var isFocused: Bool

    private var stepperRange: ClosedRange<Double> {
        let suggested = suggestedRange ?? 0...10_000
        let lower = min(suggested.lowerBound, min(value, 0))
        let upper = max(suggested.upperBound, value)
        return lower...upper
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    TextField("", text: $text)
                        .keyboardType(.decimalPad)
                        .focused($isFocused)
                        .font(.system(.title2, design: .rounded, weight: .semibold).monospacedDigit())
                        .multilineTextAlignment(.trailing)
                        .frame(minWidth: 72, minHeight: 44)
                        .accessibilityLabel(unit)
                    Text(unit)
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity, minHeight: 44)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color(.secondarySystemFill))
                )

                Stepper("", value: stepperBinding, in: stepperRange, step: step)
                    .labelsHidden()
                    .frame(minWidth: 44, minHeight: 44)
                    .accessibilityLabel(unit)
            }

            if let rangeHint, !rangeHint.isEmpty {
                Text(rangeHint)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .onAppear { syncTextFromValue() }
        .onChange(of: value) { _, _ in
            if !isFocused { syncTextFromValue() }
        }
        .onChange(of: isFocused) { _, focused in
            if !focused { commitText() }
        }
        .onChange(of: text) { _, newValue in
            guard isFocused else { return }
            let normalized = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
                .replacingOccurrences(of: ",", with: ".")
            guard !normalized.isEmpty else { return }
            if let parsed = Formatters.number.number(from: normalized)?.doubleValue
                ?? Double(normalized) {
                value = parsed
            }
        }
    }

    private var stepperBinding: Binding<Double> {
        Binding(
            get: { value },
            set: { newValue in
                value = newValue
                HapticFeedback.selection()
                if !isFocused { syncTextFromValue() }
            }
        )
    }

    private func syncTextFromValue() {
        text = formatted(value)
    }

    private func commitText() {
        let normalized = text.replacingOccurrences(of: ",", with: ".")
        if let parsed = Formatters.number.number(from: normalized)?.doubleValue
            ?? Double(normalized) {
            value = parsed
        }
        syncTextFromValue()
    }

    private func formatted(_ number: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = fractionDigits
        return formatter.string(from: NSNumber(value: number)) ?? String(number)
    }
}
