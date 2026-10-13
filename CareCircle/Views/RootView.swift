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
    @AppStorage("cc.quickSwitcherCollapsed") private var isSwitcherCollapsed: Bool = false

    public init() {}

    public var body: some View {
        ZStack(alignment: .bottomTrailing) {
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
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .animation(CCMotion.gentle, value: currentShell)
            .animation(CCMotion.gentle, value: service.isAuthenticated)
            .animation(CCMotion.gentle, value: showingAuthFlow)

            // Quick Switcher Capsule (For Previews, Simulator & Testing)
            quickSwitcherOverlay
                .padding(.trailing, 16)
                .padding(.bottom, (currentShell == .family && service.isAuthenticated && !showingAuthFlow) ? 72 : 20)
        }
        .paperBackground()
    }

    @ViewBuilder
    private var quickSwitcherOverlay: some View {
        if isSwitcherCollapsed {
            Button(action: {
                withAnimation(CCMotion.snappy) {
                    isSwitcherCollapsed = false
                }
                CCHaptics.selection()
            }) {
                Image(systemName: "arrow.left.arrow.right")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(Color.ccInk)
                    .frame(width: 36, height: 36)
                    .background(Color.ccSurfaceRaised)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.ccHairline, lineWidth: 1))
            }
            .accessibilityLabel("Expand Mode Switcher")
        } else {
            HStack(spacing: 6) {
                // Collapse chevron
                Button(action: {
                    withAnimation(CCMotion.snappy) {
                        isSwitcherCollapsed = true
                    }
                    CCHaptics.selection()
                }) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(Color.ccTextSecondary)
                        .frame(width: 28, height: 28)
                        .background(Color.ccLinen)
                        .clipShape(Circle())
                }
                .accessibilityLabel("Collapse Mode Switcher")

                if !service.isAuthenticated && !showingAuthFlow {
                    Button(action: {
                        withAnimation(CCMotion.gentle) {
                            service.loadDemoData(role: .child)
                            currentShell = .family
                        }
                        CCHaptics.light()
                    }) {
                        HStack(spacing: 5) {
                            Image(systemName: "play.circle.fill")
                                .font(.system(size: 11, weight: .bold))
                            Text("Skip to Demo")
                                .font(.system(size: 12, weight: .semibold, design: .rounded))
                        }
                        .foregroundColor(Color.ccInk)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 7)
                        .background(Color.ccLinen)
                        .clipShape(Capsule())
                    }
                } else {
                    Button(action: {
                        withAnimation(CCMotion.gentle) {
                            if !service.isAuthenticated {
                                service.isAuthenticated = true
                                showingAuthFlow = false
                            } else {
                                showingAuthFlow.toggle()
                            }
                        }
                        CCHaptics.light()
                    }) {
                        HStack(spacing: 5) {
                            Image(systemName: showingAuthFlow ? "app.badge.checkmark" : "person.badge.key")
                                .font(.system(size: 11, weight: .bold))
                            Text(showingAuthFlow ? "Exit Auth" : "Test Auth Flow")
                                .font(.system(size: 12, weight: .semibold, design: .rounded))
                        }
                        .foregroundColor(Color.ccInk)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 7)
                        .background(Color.ccLinen)
                        .clipShape(Capsule())
                    }

                    if !showingAuthFlow {
                        Button(action: {
                            withAnimation(CCMotion.gentle) {
                                currentShell = (currentShell == .parent) ? .family : .parent
                            }
                            CCHaptics.light()
                        }) {
                            HStack(spacing: 5) {
                                Image(systemName: "arrow.left.arrow.right")
                                    .font(.system(size: 11, weight: .bold))
                                Text(currentShell == .parent ? "Family Dashboard" : "Parent Mode")
                                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                            }
                            .foregroundColor(Color.ccInk)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 7)
                            .background(Color.ccLinen)
                            .clipShape(Capsule())
                        }
                    }
                }
            }
            .padding(5)
            .background(Color.ccSurfaceRaised)
            .clipShape(Capsule())
            .overlay(Capsule().stroke(Color.ccHairline, lineWidth: 1))
        }
    }
}

// MARK: - Family Mode Shell Tab View
struct FamilyShellTabView: View {
    @ObservedObject var service: FirebaseService
    @State private var selectedTab: Int = 0

    private var unresolvedAlertsCount: Int {
        service.alerts.filter { !$0.isResolved }.count
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            FamilyDashboardView(service: service)
                .tabItem {
                    Label("Dashboard", systemImage: selectedTab == 0 ? "circle.grid.cross.fill" : "circle.grid.cross")
                }
                .tag(0)

            FamilyCircleView(service: service)
                .tabItem {
                    Label("Circle", systemImage: selectedTab == 1 ? "person.2.fill" : "person.2")
                }
                .tag(1)

            CareScheduleView(service: service)
                .tabItem {
                    Label("Schedule", systemImage: selectedTab == 2 ? "calendar" : "calendar")
                }
                .tag(2)

            HealthLogView(service: service)
                .tabItem {
                    Label("Health Log", systemImage: selectedTab == 3 ? "cross.case.fill" : "cross.case")
                }
                .tag(3)

            AlertsHistoryView(service: service)
                .tabItem {
                    Label("Alerts", systemImage: selectedTab == 4 ? "bell.fill" : "bell")
                }
                .badge(unresolvedAlertsCount)
                .tag(4)
        }
        .tint(Color.ccHearth)
    }
}
