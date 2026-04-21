import Foundation

enum Units {
    #if DEBUG
    static var _testOverrideIsMetric: Bool? = nil
    #endif

    static var isMetric: Bool {
        #if DEBUG
        if let override = _testOverrideIsMetric { return override }
        #endif
        return Locale.current.measurementSystem != .us
    }

    // MARK: - Weight

    static var weightUnit: String { isMetric ? "kg" : "lbs" }

    static func weightValue(fromKg kg: Double) -> Double {
        isMetric ? kg : kg * 2.20462
    }

    static func kgFromInput(_ value: Double) -> Double {
        isMetric ? value : value / 2.20462
    }

    static func displayWeight(kg: Double) -> String {
        String(format: "%.1f \(weightUnit)", weightValue(fromKg: kg))
    }

    // MARK: - Height

    static func displayHeight(cm: Double) -> String {
        guard cm > 0 else { return "—" }
        if isMetric {
            return String(format: "%.0f cm", cm)
        } else {
            let totalInches = cm / 2.54
            let feet = Int(totalInches / 12)
            let inches = Int(totalInches.truncatingRemainder(dividingBy: 12))
            return "\(feet)' \(inches)\""
        }
    }

    static func heightFeet(fromCm cm: Double) -> Int {
        Int(cm / 2.54) / 12
    }

    static func heightInches(fromCm cm: Double) -> Int {
        Int(cm / 2.54) % 12
    }

    static func cmFromFeetInches(feet: Int, inches: Int) -> Double {
        (Double(feet) * 12.0 + Double(inches)) * 2.54
    }

    // MARK: - Distance

    static var distanceUnit: String { isMetric ? "km" : "mi" }

    static func distanceValue(fromMeters meters: Double) -> Double {
        isMetric ? meters / 1000.0 : meters / 1609.344
    }

    static func metersFromInput(_ value: Double) -> Double {
        isMetric ? value * 1000.0 : value * 1609.344
    }

    static func displayDistance(meters: Double) -> String {
        String(format: "%.2f \(distanceUnit)", distanceValue(fromMeters: meters))
    }
}
