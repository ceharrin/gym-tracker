import SwiftUI
import UIKit

enum ProgressExporter {

    /// Renders a ProgressReportView to a PDF file and returns the URL.
    /// Returns nil if rendering produces no content.
    /// Must be called on the MainActor (SwiftUI button actions satisfy this).
    @MainActor
    static func generatePDF(for activities: [CDActivity], range: ProgressDateRange) -> URL? {
        let reportView = ProgressReportView(activities: activities, range: range)
            .environment(\.colorScheme, .light)

        let renderer = ImageRenderer(content: reportView)
        renderer.scale = 2.0

        guard let image = renderer.uiImage, image.size.width > 0, image.size.height > 0 else {
            return nil
        }

        let bounds = CGRect(origin: .zero, size: image.size)
        let pdfData = NSMutableData()
        UIGraphicsBeginPDFContextToData(pdfData, bounds, nil)
        UIGraphicsBeginPDFPage()
        image.draw(in: bounds)
        UIGraphicsEndPDFContext()

        guard pdfData.length > 0 else { return nil }

        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("GymTracker-Progress.pdf")
        do {
            try (pdfData as Data).write(to: url)
            return url
        } catch {
            return nil
        }
    }
}
