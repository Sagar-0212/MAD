import SwiftUI

// MARK: - App Shell Mode
public enum AppShellMode: String, CaseIterable {
    case parent = "Parent Mode"
    case family = "Family Mode"
}

// MARK: - Root View
// Handles switching between the two independent shells:
// 1. Parent Mode: Single primary Home screen, minimal, high-contrast, zero clutter.
// 2. Family Mode: Dashboard with bottom tabs (Dashboard, Circle, Schedule, Health Log, Alerts).

public struct RootView: View {
    @StateObject private var service = FirebaseService.shared
    @State private var currentShell: AppShellMode = .family
    @State private var showingAuthFlow: Bool = false

    public init() {}

    public var body: some View {
        ZStack(alignment: .bottom) {
            // Shell Container
            Group {
                if !service.isAuthenticated || showingAuthFlow {
                    AuthFlowCoordinatorView(service: service) { role in
                        showingAuthFlow = false
                        currentShell = (role == .parent) ? .parent : .family
                    }
                } else {
                    switch currentShell {
                    case .parent:
                        ParentHomeView(service: service)
                    case .family:
                        FamilyShellTabView(service: service)
                    }
                }
            }

            // Quick Switcher Capsule (For Xcode Previews, Simulator & Testing)
            HStack(spacing: 8) {
                if !service.isAuthenticated && !showingAuthFlow {
                    Button(action: {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            service.loadDemoData(role: .child)
                            currentShell = .family
                        }
                        let generator = UIImpactFeedbackGenerator(style: .light)
                        generator.impactOccurred()
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "play.circle.fill")
                                .font(.system(size: 11, weight: .bold))
                            Text("Skip to Demo")
                                .font(.system(size: 12, weight: .semibold, design: .rounded))
                        }
                        .foregroundColor(Color.ccInk)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.ccLinen)
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(Color.ccHairline, lineWidth: 1))
                    }
                } else {
                    Button(action: {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            if !service.isAuthenticated {
                                service.isAuthenticated = true
                                showingAuthFlow = false
                            } else {
                                showingAuthFlow.toggle()
                            }
                        }
                        let generator = UIImpactFeedbackGenerator(style: .light)
                        generator.impactOccurred()
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: showingAuthFlow ? "app.badge.checkmark" : "person.badge.key")
                                .font(.system(size: 11, weight: .bold))
                            Text(showingAuthFlow ? "Exit Auth" : "Test Auth Flow")
                                .font(.system(size: 12, weight: .semibold, design: .rounded))
                        }
                        .foregroundColor(Color.ccInk)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.ccLinen)
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(Color.ccHairline, lineWidth: 1))
                    }

                    if !showingAuthFlow {
                        Button(action: {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                currentShell = (currentShell == .parent) ? .family : .parent
                            }
                            let generator = UIImpactFeedbackGenerator(style: .light)
                            generator.impactOccurred()
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: "arrow.left.arrow.right")
                                    .font(.system(size: 11, weight: .bold))
                                Text(currentShell == .parent ? "Family Dashboard" : "Parent Mode")
                                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                            }
                            .foregroundColor(Color.ccInk)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.ccLinen)
                            .clipShape(Capsule())
                            .overlay(Capsule().stroke(Color.ccHairline, lineWidth: 1))
                        }
                    }
                }
            }
            .padding(.bottom, (currentShell == .family && service.isAuthenticated && !showingAuthFlow) ? 64 : 16)
        }
        .paperBackground()
    }
}

// MARK: - Family Mode Shell Tab View
struct FamilyShellTabView: View {
    @ObservedObject var service: FirebaseService
    @State private var selectedTab: Int = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            FamilyDashboardView(service: service)
                .tabItem {
                    Label("Dashboard", systemImage: "circle.grid.cross")
                }
                .tag(0)

            FamilyCircleView(service: service)
                .tabItem {
                    Label("Circle", systemImage: "person.2")
                }
                .tag(1)

            CareScheduleView(service: service)
                .tabItem {
                    Label("Schedule", systemImage: "calendar")
                }
                .tag(2)

            HealthLogView(service: service)
                .tabItem {
                    Label("Health Log", systemImage: "cross.case")
                }
                .tag(3)

            AlertsHistoryView(service: service)
                .tabItem {
                    Label("Alerts", systemImage: "bell.badge")
                }
                .tag(4)
        }
        .tint(Color.ccHearth)
    }
}
