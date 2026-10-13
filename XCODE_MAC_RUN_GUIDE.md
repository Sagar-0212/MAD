# CareCircle — Mac Xcode Direct Launch Guide

This project is configured for **direct launch** in Xcode on any Mac running macOS Sonoma (14.0+) or macOS Sequoia (15.0+) with Xcode 15 or 16.

---

## 🚀 How to Run in 3 Easy Steps

### Step 1: Open the Project in Xcode
Transfer or clone this `carecircle` folder to your Mac, and double-click:
```
CareCircle.xcodeproj
```

### Step 2: Select a Target & Simulator
In the top Xcode toolbar:
- Scheme: **`CareCircle`** (pre-configured)
- Destination: Select any **iPhone 15 / 16 / SE** simulator running **iOS 17.0+** (or connect your physical iPhone).

### Step 3: Hit Run (`⌘R`)
Press **Command + R** or click the **Play** button in the top left.
Xcode will compile and launch the app in the simulator immediately.

---

## 📱 What You Will See on First Launch

1. **Welcome Screen ([`WelcomeView.swift`](file:///c:/Users/LENOVO/OneDrive/Desktop/carecircle/CareCircle/Views/Auth/WelcomeView.swift))**:
   - Brand mark and three core value pillars (One-tap check-in, 90-min quiet grace period, Private circle).
   - Tap **"Get Started"**.

2. **Phone Number Input ([`PhoneLoginView.swift`](file:///c:/Users/LENOVO/OneDrive/Desktop/carecircle/CareCircle/Views/Auth/PhoneLoginView.swift))**:
   - Country code selector (`+1`, `+44`, `+91`, etc.) and clean phone field.
   - Enter any 10-digit number and tap **"Continue with SMS"**.

3. **6-Digit OTP Verification ([`OTPVerificationView.swift`](file:///c:/Users/LENOVO/OneDrive/Desktop/carecircle/CareCircle/Views/Auth/OTPVerificationView.swift))**:
   - 6 individual PIN cells with auto-advance and haptic feedback.
   - Type any 6 digits (e.g., `123456`) or tap **"Verify & Continue"**.

4. **Role Selection & Profile ([`ProfileSetupView.swift`](file:///c:/Users/LENOVO/OneDrive/Desktop/carecircle/CareCircle/Views/Auth/ProfileSetupView.swift))**:
   - Choose **Parent Mode** (for aging parents) or **Family Caregiver** (for children/caregivers).
   - Enter your name (e.g., "Dad" or "Alice") and tap **"Continue"**.

5. **Family Circle Setup ([`FamilySetupView.swift`](file:///c:/Users/LENOVO/OneDrive/Desktop/carecircle/CareCircle/Views/Auth/FamilySetupView.swift))**:
   - Choose **Create Circle** (e.g., "The Johnsons") or enter a 6-digit invite code (`CARE92`).
   - Tap **"Create Family Circle"**.

6. **Notification Prompt ([`NotificationPermissionView.swift`](file:///c:/Users/LENOVO/OneDrive/Desktop/carecircle/CareCircle/Views/Auth/NotificationPermissionView.swift))**:
   - Pre-permission explanation. Tap **"Turn on Notifications"** or **"Maybe later"**.

7. **Main App Shell**:
   - If **Parent Mode** was selected $\rightarrow$ Opens directly into the high-contrast [ParentHomeView.swift](file:///c:/Users/LENOVO/OneDrive/Desktop/carecircle/CareCircle/Views/ParentMode/ParentHomeView.swift) with the prominent *"I'm okay today."* tactile button and medication checklist.
   - If **Family Caregiver** was selected $\rightarrow$ Opens into the [FamilyDashboardView.swift](file:///c:/Users/LENOVO/OneDrive/Desktop/carecircle/CareCircle/Views/FamilyMode/FamilyDashboardView.swift) with live radial status rings, care schedule, and alerts.

---

## ⚡ Quick Testing & Demo Affordances
- **"Skip to Demo"**: On the first Welcome screen, you will see a bottom floating pill button labeled **"Skip to Demo"**. Tapping this instantly skips onboarding and lands directly on the live family dashboard with sample data pre-filled.
- **"Switch to Parent Mode / Family Dashboard"**: Tap this floating capsule at any time to instantly jump between the two shells.
- **"Test Auth Flow"**: Re-launches the onboarding sequence anytime.
