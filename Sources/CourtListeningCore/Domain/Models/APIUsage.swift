import Foundation

/// Tracks API request consumption against CourtListener's free-tier rolling windows.
/// Free tier: 5 requests/minute, 50 requests/hour, 125 requests/day.
///
/// Uses tumbling windows: each window resets the first time a request arrives after the
/// window duration has elapsed. This is conservative — it never under-counts usage.
public struct APIUsage: Sendable, Hashable {
    public let windowStartMinute: Date
    public let windowStartHour: Date
    public let windowStartDay: Date
    public let requestsThisMinute: Int
    public let requestsThisHour: Int
    public let requestsThisDay: Int

    public static let minuteLimit = 5
    public static let hourLimit   = 50
    public static let dayLimit    = 125

    public var minuteRemaining: Int { max(0, Self.minuteLimit - requestsThisMinute) }
    public var hourRemaining: Int   { max(0, Self.hourLimit   - requestsThisHour) }
    public var dayRemaining: Int    { max(0, Self.dayLimit    - requestsThisDay) }

    public var isAtMinuteLimit: Bool { requestsThisMinute >= Self.minuteLimit }
    public var isAtHourLimit: Bool   { requestsThisHour   >= Self.hourLimit }
    public var isAtDayLimit: Bool    { requestsThisDay    >= Self.dayLimit }

    public static let initial = APIUsage(
        windowStartMinute: .distantPast,
        windowStartHour: .distantPast,
        windowStartDay: .distantPast,
        requestsThisMinute: 0,
        requestsThisHour: 0,
        requestsThisDay: 0
    )

    /// Returns a new `APIUsage` with the request at `now` recorded.
    /// Expired windows are reset before incrementing.
    public func recording(at now: Date) -> APIUsage {
        let minuteExpired = now.timeIntervalSince(windowStartMinute) >= 60
        let hourExpired   = now.timeIntervalSince(windowStartHour)   >= 3_600
        let dayExpired    = now.timeIntervalSince(windowStartDay)    >= 86_400
        return APIUsage(
            windowStartMinute: minuteExpired ? now : windowStartMinute,
            windowStartHour:   hourExpired   ? now : windowStartHour,
            windowStartDay:    dayExpired    ? now : windowStartDay,
            requestsThisMinute: minuteExpired ? 1 : requestsThisMinute + 1,
            requestsThisHour:   hourExpired   ? 1 : requestsThisHour   + 1,
            requestsThisDay:    dayExpired    ? 1 : requestsThisDay    + 1
        )
    }
}
