import SwiftUI

struct OnboardingView: View {
    @Environment(\.knotTheme) private var theme
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @State private var page = 0

    private let pages: [(icon: String, title: String, body: String)] = [
        ("calendar.badge.clock",
         "Your schedule, always with you",
         "See your shifts, clock in and out, and know exactly when you're working — all from your phone."),
        ("arrow.triangle.2.circlepath.circle",
         "Stay connected with your team",
         "Message coworkers, request time off, swap shifts, and pick up open shifts without chasing anyone down."),
        ("checkmark.seal",
         "Managers stay in control",
         "Publish schedules, approve requests, and track labor costs — all in one place.")
    ]

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $page) {
                ForEach(Array(pages.enumerated()), id: \.offset) { idx, p in
                    pageView(p.icon, p.title, p.body).tag(idx)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut, value: page)

            VStack(spacing: 16) {
                HStack(spacing: 6) {
                    ForEach(0..<pages.count, id: \.self) { i in
                        Capsule()
                            .fill(i == page ? theme.ink : theme.inkFaint)
                            .frame(width: i == page ? 20 : 6, height: 6)
                            .animation(.spring(duration: 0.3), value: page)
                    }
                }

                Button {
                    if page < pages.count - 1 {
                        withAnimation { page += 1 }
                    } else {
                        hasSeenOnboarding = true
                    }
                } label: {
                    Text(page < pages.count - 1 ? "Next" : "Get started")
                        .font(theme.bodyMedium(16)).foregroundStyle(theme.paper)
                        .frame(maxWidth: .infinity).frame(height: 52)
                        .background(theme.ink, in: Capsule())
                }
                .buttonStyle(.plain)

                if page < pages.count - 1 {
                    Button { hasSeenOnboarding = true } label: {
                        Text("Skip").font(theme.body(14)).foregroundStyle(theme.inkMuted)
                    }
                    .buttonStyle(.plain)
                } else {
                    Color.clear.frame(height: 20)
                }
            }
            .padding(.horizontal, 28)
            .padding(.bottom, 40)
        }
        .background(theme.cream.ignoresSafeArea())
    }

    private func pageView(_ icon: String, _ title: String, _ body: String) -> some View {
        VStack(spacing: 28) {
            Spacer()
            Image(systemName: icon)
                .font(.system(size: 64, weight: .thin))
                .foregroundStyle(theme.rose)
                .frame(width: 120, height: 120)
                .background(theme.roseSoft, in: Circle())
            VStack(spacing: 12) {
                Text(title)
                    .font(theme.display(28)).foregroundStyle(theme.ink)
                    .multilineTextAlignment(.center)
                Text(body)
                    .font(theme.body(16)).foregroundStyle(theme.inkMuted)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            Spacer()
            Spacer()
        }
        .padding(.horizontal, 28)
    }
}

#Preview {
    OnboardingView()
        .environment(\.knotTheme, BakeryCoTheme())
}
