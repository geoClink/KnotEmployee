import MetricKit
import Foundation

final class CrashReporter: NSObject, MXMetricManagerSubscriber {
    static let shared = CrashReporter()

    private var logURL: URL {
        FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("crash_diagnostics.log")
    }

    func start() {
        MXMetricManager.shared.add(self)
    }

    // Called the next launch after a crash — contains stack traces, hangs, disk-write exceptions
    func didReceive(_ payloads: [MXDiagnosticPayload]) {
        for payload in payloads {
            guard let data = try? JSONSerialization.data(
                withJSONObject: payload.dictionaryRepresentation(), options: .prettyPrinted),
                  let text = String(data: data, encoding: .utf8) else { continue }
            appendToLog("--- \(Date()) ---\n\(text)\n\n")
        }
    }

    // Required by protocol — performance metrics, not needed for crash detection
    func didReceive(_ payloads: [MXMetricPayload]) {}

    private func appendToLog(_ text: String) {
        if let data = text.data(using: .utf8) {
            if FileManager.default.fileExists(atPath: logURL.path) {
                if let handle = try? FileHandle(forWritingTo: logURL) {
                    handle.seekToEndOfFile()
                    handle.write(data)
                    try? handle.close()
                }
            } else {
                try? data.write(to: logURL)
            }
        }
    }
}
