import XCTest
@testable import ExpenseTrackerSwift

final class DateRangeHelperTests: XCTestCase {

    // MARK: - Helpers

    /// Build a fixed Date from components using the current calendar.
    private func makeDate(year: Int, month: Int, day: Int,
                          hour: Int = 0, minute: Int = 0, second: Int = 0) -> Date {
        var components = DateComponents()
        components.year   = year
        components.month  = month
        components.day    = day
        components.hour   = hour
        components.minute = minute
        components.second = second
        return Calendar.current.date(from: components)!
    }

    // MARK: - monthBounds: start

    func testMonthBounds_startIsFirstDayOfMonth() {
        let date = makeDate(year: 2025, month: 3, day: 15, hour: 14, minute: 30)
        let bounds = DateRangeHelper.monthBounds(for: date)

        let expected = makeDate(year: 2025, month: 3, day: 1, hour: 0, minute: 0, second: 0)
        XCTAssertEqual(bounds.start, expected,
                       "Start of month should be March 1, 2025 at midnight")
    }

    // MARK: - monthBounds: end

    func testMonthBounds_endIsLastMomentOfMonth() {
        let date = makeDate(year: 2025, month: 3, day: 15)
        let bounds = DateRangeHelper.monthBounds(for: date)

        let expected = makeDate(year: 2025, month: 3, day: 31, hour: 23, minute: 59, second: 59)
        XCTAssertEqual(bounds.end, expected,
                       "End of March 2025 should be March 31 at 23:59:59")
    }

    func testMonthBounds_december() {
        // December should end on Dec 31, not overflow into January
        let date = makeDate(year: 2025, month: 12, day: 10)
        let bounds = DateRangeHelper.monthBounds(for: date)

        let expectedStart = makeDate(year: 2025, month: 12, day: 1)
        let expectedEnd   = makeDate(year: 2025, month: 12, day: 31, hour: 23, minute: 59, second: 59)

        XCTAssertEqual(bounds.start, expectedStart, "December start should be Dec 1, 2025")
        XCTAssertEqual(bounds.end,   expectedEnd,   "December end should be Dec 31, 2025 at 23:59:59")
    }

    func testMonthBounds_february_leapYear() {
        // 2024 is a leap year — February has 29 days
        let date = makeDate(year: 2024, month: 2, day: 1)
        let bounds = DateRangeHelper.monthBounds(for: date)

        let expectedEnd = makeDate(year: 2024, month: 2, day: 29, hour: 23, minute: 59, second: 59)
        XCTAssertEqual(bounds.end, expectedEnd,
                       "Feb 2024 (leap year) end should be Feb 29 at 23:59:59")
    }

    // MARK: - isSameMonth

    func testIsSameMonth_true() {
        let date1 = makeDate(year: 2025, month: 3, day: 5)
        let date2 = makeDate(year: 2025, month: 3, day: 28)
        XCTAssertTrue(DateRangeHelper.isSameMonth(date1, date2),
                      "Two dates in March 2025 should be in the same month")
    }

    func testIsSameMonth_false_differentMonth() {
        let march = makeDate(year: 2025, month: 3, day: 1)
        let april = makeDate(year: 2025, month: 4, day: 1)
        XCTAssertFalse(DateRangeHelper.isSameMonth(march, april),
                       "March and April 2025 are different months")
    }

    func testIsSameMonth_false_differentYear() {
        let march2025 = makeDate(year: 2025, month: 3, day: 1)
        let march2026 = makeDate(year: 2026, month: 3, day: 1)
        XCTAssertFalse(DateRangeHelper.isSameMonth(march2025, march2026),
                       "March 2025 and March 2026 are different years — not same month")
    }

    // MARK: - monthsBetween

    func testMonthsBetween_threeMonths() {
        let start = makeDate(year: 2025, month: 1, day: 15)
        let end   = makeDate(year: 2025, month: 3, day: 5)

        let months = DateRangeHelper.monthsBetween(start: start, end: end)

        XCTAssertEqual(months.count, 3, "Jan–Mar 2025 should produce 3 month entries")

        // Verify each entry is the first of its month
        let cal = Calendar.current
        XCTAssertEqual(cal.component(.month, from: months[0]), 1)
        XCTAssertEqual(cal.component(.month, from: months[1]), 2)
        XCTAssertEqual(cal.component(.month, from: months[2]), 3)
        XCTAssertEqual(cal.component(.day,   from: months[0]), 1)
    }

    func testMonthsBetween_sameMonth() {
        let start = makeDate(year: 2025, month: 6, day: 10)
        let end   = makeDate(year: 2025, month: 6, day: 25)

        let months = DateRangeHelper.monthsBetween(start: start, end: end)

        XCTAssertEqual(months.count, 1, "Same month range should return exactly 1 entry")
    }
}
