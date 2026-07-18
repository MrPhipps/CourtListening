import Foundation

/// Tracks API request consumption against CourtListener's rolling windows.
///
/// The limits are **advisory client-side hints** only. The server is the source of truth:
/// it enforces throttling and returns HTTP 429 + a `wait_until` timestamp when exceeded.
/// Actual limits vary by account tier and by temporary promotions (e.g. a base tier of
/// 5/50/125 per minute/hour/day may be doubled during a promo), so they are **injected**
/// per session rather than hardcoded. Defaults reflect the documented free base tier.
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
    public let minuteLimit: Int
    public let hourLimit: Int
    public let dayLimit: Int

    public static let defaultMinuteLimit = 5
    public static let defaultHourLimit   = 50
    public static let defaultDayLimit    = 125

    public init(
        windowStartMinute: Date,
        windowStartHour: Date,
        windowStartDay: Date,
        requestsThisMinute: Int,
        requestsThisHour: Int,
        requestsThisDay: Int,
        minuteLimit: Int = APIUsage.defaultMinuteLimit,
        hourLimit: Int = APIUsage.defaultHourLimit,
        dayLimit: Int = APIUsage.defaultDayLimit
    ) {
        self.windowStartMinute = windowStartMinute
        self.windowStartHour = windowStartHour
        self.windowStartDay = windowStartDay
        self.requestsThisMinute = requestsThisMinute
        self.requestsThisHour = requestsThisHour
        self.requestsThisDay = requestsThisDay
        self.minuteLimit = minuteLimit
        self.hourLimit = hourLimit
        self.dayLimit = dayLimit
    }

    public var minuteRemaining: Int { max(0, minuteLimit - requestsThisMinute) }
    public var hourRemaining: Int   { max(0, hourLimit   - requestsThisHour) }
    public var dayRemaining: Int    { max(0, dayLimit    - requestsThisDay) }

    public var isAtMinuteLimit: Bool { requestsThisMinute >= minuteLimit }
    public var isAtHourLimit: Bool   { requestsThisHour   >= hourLimit }
    public var isAtDayLimit: Bool    { requestsThisDay    >= dayLimit }

    /// Empty usage at the documented base-tier limits.
    public static let initial = APIUsage(
        windowStartMinute: .distantPast,
        windowStartHour: .distantPast,
        windowStartDay: .distantPast,
        requestsThisMinute: 0,
        requestsThisHour: 0,
        requestsThisDay: 0
    )

    /// Empty usage configured for a specific account tier's limits.
    public static func initial(minuteLimit: Int, hourLimit: Int, dayLimit: Int) -> APIUsage {
        APIUsage(
            windowStartMinute: .distantPast,
            windowStartHour: .distantPast,
            windowStartDay: .distantPast,
            requestsThisMinute: 0,
            requestsThisHour: 0,
            requestsThisDay: 0,
            minuteLimit: minuteLimit,
            hourLimit: hourLimit,
            dayLimit: dayLimit
        )
    }

    /// Returns a new `APIUsage` with the request at `now` recorded.
    /// Expired windows are reset before incrementing; the configured limits are preserved.
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
            requestsThisDay:    dayExpired    ? 1 : requestsThisDay    + 1,
            minuteLimit: minuteLimit,
            hourLimit: hourLimit,
            dayLimit: dayLimit
        )
    }
}
