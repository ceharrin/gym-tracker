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
}
