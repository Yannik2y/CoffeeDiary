import SwiftUI

struct FeedbackFormView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var subject = ""
    @State private var message = ""
    @State private var isSending = false
    @State private var errorMessage: String?
    @State private var didSend = false

    private var canSend: Bool {
        FeedbackService.isConfigured
            && !subject.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !isSending
    }

    var body: some View {
        NavigationStack {
            Form {
                if !FeedbackService.isConfigured {
                    Section {
                        Text("Feedback is not configured yet.".localized)
                            .foregroundStyle(.secondary)
                    }
                }

                Section("Subject".localized) {
                    TextField("Subject".localized, text: $subject)
                        .disabled(!FeedbackService.isConfigured)
                }

                Section("Message".localized) {
                    TextEditor(text: $message)
                        .frame(minHeight: 140)
                        .disabled(!FeedbackService.isConfigured)
                }

                Section {
                    Text("Device and app version are included automatically. Your email address is never shown in the app.".localized)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Send Feedback".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel".localized) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    if isSending {
                        ProgressView()
                    } else {
                        Button("Send".localized) {
                            Task { await send() }
                        }
                        .disabled(!canSend)
                    }
                }
            }
            .alert("Thanks!".localized, isPresented: $didSend) {
                Button("OK".localized) { dismiss() }
            } message: {
                Text("Your feedback was sent.".localized)
            }
            .alert("Error".localized, isPresented: Binding(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )) {
                Button("OK".localized, role: .cancel) { errorMessage = nil }
            } message: {
                if let errorMessage {
                    Text(errorMessage)
                }
            }
        }
    }

    private func send() async {
        isSending = true
        defer { isSending = false }
        do {
            try await FeedbackService.submit(
                subject: subject.trimmingCharacters(in: .whitespacesAndNewlines),
                message: message.trimmingCharacters(in: .whitespacesAndNewlines)
            )
            didSend = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
