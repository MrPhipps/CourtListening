import SwiftUI

/// The single source of visual truth. Views reference `Design.*` only — no raw `CGFloat`
/// literals, hex colors, or ad-hoc fonts. This keeps the design system refactorable at the
/// type level.
public enum Design {

    public enum Spacing {
        public static let xs: CGFloat = 4
        public static let sm: CGFloat = 8
        public static let md: CGFloat = 16
        public static let lg: CGFloat = 24
        public static let xl: CGFloat = 40
    }

    public enum Size {
        public static let cornerRadius: CGFloat = 12
        public static let iconSmall: CGFloat = 16
        public static let iconMedium: CGFloat = 28
        public static let hairline: CGFloat = 1
        public static let hudBarHeight: CGFloat = 6
        public static let minTapTarget: CGFloat = 44
    }

    public enum Color {
        public static let accent = SwiftUI.Color.accentColor
        public static let primaryText = SwiftUI.Color.primary
        public static let secondaryText = SwiftUI.Color.secondary
        public static let surface = SwiftUI.Color(.sRGB, white: 0.5, opacity: 0.08)
        public static let separator = SwiftUI.Color.gray.opacity(0.3)
        public static let danger = SwiftUI.Color.red
        public static let warning = SwiftUI.Color.orange
        public static let ok = SwiftUI.Color.green
    }

    public enum Font {
        public static let title = SwiftUI.Font.title2.weight(.semibold)
        public static let heading = SwiftUI.Font.headline
        public static let body = SwiftUI.Font.body
        public static let caption = SwiftUI.Font.caption
        public static let mono = SwiftUI.Font.system(.footnote, design: .monospaced)
    }
}
