import Foundation

func filterNumericInput(_ text: String, allowDecimal: Bool) -> String {
    var result = ""
    var hasDecimal = false
    for char in text {
        if char.isNumber {
            result.append(char)
        } else if allowDecimal && char == "." && !hasDecimal {
            result.append(char)
            hasDecimal = true
        }
    }
    return result
}
