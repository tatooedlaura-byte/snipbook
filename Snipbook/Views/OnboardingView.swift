import SwiftUI

/// Simple onboarding flow shown on first launch
struct OnboardingView: View {
    @Binding var hasCompletedOnboarding: Bool
    @State private var currentPage = 0

    private let pages: [OnboardingPage] = [
        OnboardingPage(
            icon: "scissors",
            title: "Welcome to Snipbook",
            subtitle: "Little Moments, Cut & Kept",
            description: "A calm space to collect everyday moments without any pressure to be perfect."
        ),
        OnboardingPage(
            icon: "square.on.square",
            title: "Pick a Shape",
            subtitle: "Six styles to choose from",
            description: "Stamp, circle, ticket, label, torn paper, or rectangle. Each one gives your moment a unique feel."
        ),
        OnboardingPage(
            icon: "camera",
            title: "Snap or Import",
            subtitle: "See the shape as you shoot",
            description: "Take a photo with the shape overlay, or import from your library. One tap and it's cut."
        ),
        OnboardingPage(
            icon: "book.closed",
            title: "Watch It Grow",
            subtitle: "Your book builds itself",
            description: "Each snip is added to your book automatically. No arranging, no fuss. Just moments, kept."
        )
    ]

    var body: some View {
        ZStack {
            // Background
            Color(red: 0.96, green: 0.95, blue: 0.93)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Page content
                TabView(selection: $currentPage) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        pageView(pages[index])
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                // Page indicator
                HStack(spacing: 8) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        Circle()
                            .fill(index == currentPage ? Color(red: 0.82, green: 0.48, blue: 0.36) : Color.gray.opacity(0.3))
                            .frame(width: 8, height: 8)
                            .animation(.easeInOut(duration: 0.2), value: currentPage)
                    }
                }
                .padding(.bottom, 32)

                // Button
                Button(action: handleButtonTap) {
                    Text(currentPage == pages.count - 1 ? "Get Started" : "Continue")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color(red: 0.82, green: 0.48, blue: 0.36))
                        .cornerRadius(16)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 16)

                // Skip button
                if currentPage < pages.count - 1 {
                    Button("Skip") {
                        completeOnboarding()
                    }
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.bottom, 24)
                } else {
                    Color.clear.frame(height: 44)
                }
            }
        }
    }

    // MARK: - Page View

    private func pageView(_ page: OnboardingPage) -> some View {
        VStack(spacing: 24) {
            Spacer()

            // Icon
            ZStack {
                Circle()
                    .fill(Color(red: 0.91, green: 0.72, blue: 0.62).opacity(0.2))
                    .frame(width: 120, height: 120)

                Image(systemName: page.icon)
                    .font(.system(size: 48))
                    .foregroundColor(Color(red: 0.82, green: 0.48, blue: 0.36))
            }

            // Text content
            VStack(spacing: 12) {
                Text(page.title)
                    .font(.system(size: 28, weight: .semibold))
                    .multilineTextAlignment(.center)

                Text(page.subtitle)
                    .font(.system(size: 17, design: .serif))
                    .italic()
                    .foregroundColor(.secondary)

                Text(page.description)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .padding(.top, 8)
            }

            Spacer()
            Spacer()
        }
        .padding(.horizontal, 24)
    }

    // MARK: - Actions

    private func handleButtonTap() {
        if currentPage < pages.count - 1 {
            withAnimation {
                currentPage += 1
            }
        } else {
            completeOnboarding()
        }
    }

    private func completeOnboarding() {
        withAnimation {
            hasCompletedOnboarding = true
        }
    }
}

// MARK: - Onboarding Page Model

struct OnboardingPage {
    let icon: String
    let title: String
    let subtitle: String
    let description: String
}

// MARK: - Preview

#Preview {
    OnboardingView(hasCompletedOnboarding: .constant(false))
}
