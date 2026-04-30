import UIKit

enum PrintCoordinator {
    static func printHTML(_ html: String, jobName: String) {
        let formatter = UIMarkupTextPrintFormatter(markupText: html)

        let info = UIPrintInfo(dictionary: nil)
        info.outputType = .general
        info.jobName = jobName

        let controller = UIPrintInteractionController.shared
        controller.printInfo = info
        controller.printFormatter = formatter
        controller.present(animated: true)
    }

    /// Renders HTML to a PDF file suitable for sharing.
    /// Uses UIMarkupTextPrintFormatter (WebKit) — must be called on the main thread.
    /// Returns nil if rendering produces no pages or writing fails.
    static func htmlToPDF(_ html: String, filename: String) -> URL? {
        guard let pdfData = htmlToPDFData(html) else { return nil }

        let url = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        do {
            try pdfData.write(to: url)
            return url
        } catch {
            return nil
        }
    }

    /// Renders HTML to PDF data suitable for either saving or sharing.
    /// Uses UIMarkupTextPrintFormatter (WebKit) — must be called on the main thread.
    /// Returns nil if rendering produces no pages.
    static func htmlToPDFData(_ html: String) -> Data? {
        let formatter = UIMarkupTextPrintFormatter(markupText: html)

        let renderer = UIPrintPageRenderer()
        renderer.addPrintFormatter(formatter, startingAtPageAt: 0)

        // A4 in points: 595 × 842
        let pageRect = CGRect(x: 0, y: 0, width: 595, height: 842)
        let printableRect = pageRect.insetBy(dx: 40, dy: 60)
        renderer.setValue(NSValue(cgRect: pageRect), forKey: "paperRect")
        renderer.setValue(NSValue(cgRect: printableRect), forKey: "printableRect")

        let pdfData = NSMutableData()
        UIGraphicsBeginPDFContextToData(pdfData, .zero, nil)
        for i in 0..<renderer.numberOfPages {
            UIGraphicsBeginPDFPage()
            renderer.drawPage(at: i, in: UIGraphicsGetPDFContextBounds())
        }
        UIGraphicsEndPDFContext()

        guard pdfData.length > 0 else { return nil }
        return pdfData as Data
    }
}
