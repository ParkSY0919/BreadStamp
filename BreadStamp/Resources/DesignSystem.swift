import SwiftUI

// MARK: - Colors

extension Color {
    // Brand
    static let brandPrimary = Color("Primary")
    static let brandSecondary = Color("Secondary")
    static let brandAccent = Color("Accent")

    // System
    static let appBackground = Color("Background")
    static let surface = Color("Surface")
    static let textPrimary = Color("TextPrimary")
    static let textSecondary = Color("TextSecondary")
    static let divider = Color("Divider")

    // Semantic
    static let success = Color("Success")
    static let warning = Color("Warning")
    static let error = Color("Error")
    static let info = Color("Info")
}

// MARK: - Typography

extension Font {
    static let appLargeTitle = Font.system(size: 34, weight: .bold)
    static let appTitle = Font.system(size: 24, weight: .bold)
    static let appHeadline = Font.system(size: 20, weight: .semibold)
    static let appBody = Font.system(size: 17, weight: .regular)
    static let appCallout = Font.system(size: 16, weight: .regular)
    static let appSubhead = Font.system(size: 15, weight: .regular)
    static let appFootnote = Font.system(size: 13, weight: .regular)
    static let appCaption = Font.system(size: 12, weight: .regular)
}

// MARK: - Spacing

enum Spacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 24
    static let xxl: CGFloat = 32
}

// MARK: - Corner Radius

enum CornerRadius {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 20
    static let full: CGFloat = 9999
}

// MARK: - Shadow

extension View {
    func shadowSm() -> some View {
        shadow(color: .black.opacity(0.08), radius: 3, y: 1)
    }

    func shadowMd() -> some View {
        shadow(color: .black.opacity(0.12), radius: 8, y: 2)
    }

    func shadowLg() -> some View {
        shadow(color: .black.opacity(0.16), radius: 16, y: 4)
    }
}
