import Foundation
import UIKit

enum FeedbackService {
    /// Formspree (or compatible) endpoint from Info.plist. Email is configured only on the form provider — never in the app.
    static var endpointURL: URL? {
        guard let raw = Bundle.main.object(forInfoDictionaryKey: "FeedbackFormEndpoint") as? String else {
            return nil
        }
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty,
              !trimmed.contains("YOUR_FORM_ID"),
              let url = URL(string: trimmed) else {
            return nil
        }
        return url
    }

    static var isConfigured: Bool { endpointURL != nil }

    @MainActor
    static func diagnosticsFooter() -> String {
        let bundle = Bundle.main
        let version = bundle.infoDictionary?["CFBundleShortVersionString"] as? String ?? "-"
        let build = bundle.infoDictionary?["CFBundleVersion"] as? String ?? "-"
        let system = "\(UIDevice.current.systemName) \(UIDevice.current.systemVersion)"
        let model = UIDevice.current.model
        let sync = CloudSyncService.shared.diagnosticsSnapshot
        return """
        ---
        App: \(version) (\(build))
        Device: \(model)
        System: \(system)
        Sync: \(sync)
        """
    }

    static func submit(subject: String, message: String) async throws {
        guard let url = endpointURL else {
            throw FeedbackError.notConfigured
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let diagnostics = await MainActor.run { diagnosticsFooter() }
        let body: [String: String] = [
            "subject": subject,
            "message": message,
            "diagnostics": diagnostics
        ]
        request.httpBody = try JSONEncoder().encode(body)

        let (_, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw FeedbackError.sendFailed
        }
    }
}

enum FeedbackError: LocalizedError {
    case notConfigured
    case sendFailed

    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "Feedback is not configured yet.".localized
        case .sendFailed:
            return "Could not send feedback. Please try again later.".localized
        }
    }
}
