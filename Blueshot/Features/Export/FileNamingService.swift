import Foundation

/// Resolves naming template variables to produce a filename.
/// Pure, stateless, and fully unit-testable.
struct FileNamingService {

    /// Available template variables:
    ///   ${YYYY} — 4-digit year
    ///   ${MM}   — 2-digit month
    ///   ${DD}   — 2-digit day
    ///   ${hh}   — 2-digit hour (24h)
    ///   ${mm}   — 2-digit minute
    ///   ${ss}   — 2-digit second
    ///   ${index}— zero-padded counter (provided externally, defaults to "001")
    func resolve(template: String, date: Date, index: Int?) -> String {
        let cal = Calendar.current
        let c = cal.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)

        var result = template
        result = result.replacingOccurrences(of: "${YYYY}", with: String(format: "%04d", c.year ?? 0))
        result = result.replacingOccurrences(of: "${MM}",   with: String(format: "%02d", c.month ?? 0))
        result = result.replacingOccurrences(of: "${DD}",   with: String(format: "%02d", c.day ?? 0))
        result = result.replacingOccurrences(of: "${hh}",   with: String(format: "%02d", c.hour ?? 0))
        result = result.replacingOccurrences(of: "${mm}",   with: String(format: "%02d", c.minute ?? 0))
        result = result.replacingOccurrences(of: "${ss}",   with: String(format: "%02d", c.second ?? 0))
        result = result.replacingOccurrences(of: "${index}", with: String(format: "%03d", index ?? 1))
        return result
    }
}
