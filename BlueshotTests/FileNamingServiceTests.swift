import Testing
import Foundation
@testable import Blueshot

@Suite("FileNamingService")
struct FileNamingServiceTests {
    private let service = FileNamingService()

    // Fixed reference date: 2026-03-26 15:30:45 JST (UTC+9)
    private var referenceDate: Date {
        var components = DateComponents()
        components.year = 2026
        components.month = 3
        components.day = 26
        components.hour = 15
        components.minute = 30
        components.second = 45
        components.timeZone = TimeZone.current
        return Calendar.current.date(from: components)!
    }

    @Test func replacesDateVariables() {
        let cal = Calendar.current
        let c = cal.dateComponents([.year, .month, .day, .hour, .minute, .second], from: referenceDate)
        let result = service.resolve(
            template: "Screenshot_${YYYY}${MM}${DD}_${hh}${mm}${ss}",
            date: referenceDate,
            index: nil
        )
        let expected = String(format: "Screenshot_%04d%02d%02d_%02d%02d%02d",
                              c.year!, c.month!, c.day!, c.hour!, c.minute!, c.second!)
        #expect(result == expected)
    }

    @Test func replacesIndexVariable() {
        let result = service.resolve(template: "shot_${index}", date: referenceDate, index: 42)
        #expect(result == "shot_042")
    }

    @Test func defaultIndexIsOne() {
        let result = service.resolve(template: "shot_${index}", date: referenceDate, index: nil)
        #expect(result == "shot_001")
    }

    @Test func templateWithNoVariablesPassesThrough() {
        let result = service.resolve(template: "my-screenshot", date: referenceDate, index: nil)
        #expect(result == "my-screenshot")
    }

    @Test func emptyTemplateProducesEmptyString() {
        let result = service.resolve(template: "", date: referenceDate, index: nil)
        #expect(result == "")
    }
}
