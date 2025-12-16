import SwiftUI

extension Color {
    // MARK: - App Colors

    /// Warm cream background
    static let appBackground = Color(red: 0.96, green: 0.95, blue: 0.93)

    /// Paper colors for pages
    static let paperCream = Color(red: 0.98, green: 0.96, blue: 0.91)
    static let paperWhite = Color(red: 0.99, green: 0.99, blue: 0.99)
    static let paperKraft = Color(red: 0.85, green: 0.78, blue: 0.68)
    static let paperGray = Color(red: 0.94, green: 0.94, blue: 0.94)

    /// Accent color - warm terracotta
    static let appAccent = Color(red: 0.82, green: 0.45, blue: 0.35)

    /// Secondary accent - muted sage
    static let appSecondary = Color(red: 0.55, green: 0.62, blue: 0.52)
}

// MARK: - View Extension for App Styling

extension View {
    /// Apply standard app background
    func appBackground() -> some View {
        self.background(Color.appBackground.ignoresSafeArea())
    }
}
