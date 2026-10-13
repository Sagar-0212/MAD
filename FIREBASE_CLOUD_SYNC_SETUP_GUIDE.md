# CareCircle — Real Cloud Sync Across Multiple Phones Guide

This step-by-step guide walks you through connecting this project to **Google Firebase** so multiple iPhones (e.g., Parent's phone and Child's phone) sync live in real-time over the cloud with push alerts.

---

## 📋 Overview of What We Will Do
1. Create a free Firebase project in Google Cloud Console.
2. Enable **Firestore Database** & **Phone Authentication**.
3. Register the iOS App and download `GoogleService-Info.plist`.
4. Deploy the included Firestore Security Rules & Cloud Functions.
5. Add the Firebase iOS SDK in Xcode.
6. Test live multi-phone synchronization.

---

## Step 1: Create Your Firebase Project

1. Open your browser and go to the [Firebase Console](https://console.firebase.google.com).
2. Click **"Add project"** (or **"Create a project"**).
3. Name your project (e.g. `carecircle-live`).
4. Disable Google Analytics (optional, to keep it simple) and click **Create Project**.
5. Wait a few seconds until your project is ready, then click **Continue**.

---

## Step 2: Enable Cloud Firestore Database

1. In the left-hand menu under **Build**, click **Firestore Database**.
2. Click **Create database**.
3. Choose a Database ID (leave as `(default)`).
4. Choose a location closest to your users (e.g. `nam5 (us-central)` or `eur3 (europe-west)`).
5. For Security Rules, select **"Start in production mode"** and click **Create**.
   *(We will deploy our verified rules in Step 5).*

---

## Step 3: Enable Phone Authentication (SMS Login)

1. In the left-hand menu under **Build**, click **Authentication**.
2. Click **Get Started**.
3. Under the **Sign-in method** tab, click **Phone**.
4. Toggle the **Enable** switch to ON.
5. **Add Free Test Phone Numbers** *(Recommended so you don't use SMS quotas during testing)*:
   - Expand **Phone numbers for testing**.
   - Add Phone 1 (Parent): `+1 555-111-2222` with Verification Code `123456`.
   - Add Phone 2 (Caregiver): `+1 555-333-4444` with Verification Code `123456`.
6. Click **Save**.

---

## Step 4: Register the iOS App & Download Config

1. Go to **Project Overview** (click the gear icon ⚙️ in top-left $\rightarrow$ **Project settings**).
2. Under **Your apps**, click the **iOS** icon (`</>`).
3. Fill in the iOS app registration:
   - **Apple bundle ID**: `com.carecircle.app` *(Must match Xcode)*
   - **App nickname**: `CareCircle iOS`
4. Click **Register app**.
5. Click **Download GoogleService-Info.plist**.
6. **Move the file into your project**:
   - Drag `GoogleService-Info.plist` into the `CareCircle/` folder in Xcode on your Mac.
   - When prompted in Xcode, make sure **"Copy items if needed"** is checked and **"CareCircle"** target is checked.

---

## Step 5: Deploy the Security Rules & Cloud Functions

Open your terminal in the `carecircle` project folder on your computer:

```bash
# 1. Install Firebase CLI (if not already installed)
npm install -g firebase-tools

# 2. Log in to your Google Account
firebase login

# 3. Associate your project directory with the new Firebase project
firebase use --add
# (Select the project you created in Step 1 from the list, give it alias: default)

# 4. Build the Cloud Functions
cd functions
npm install
npm run build
cd ..

# 5. Deploy Rules and Functions
firebase deploy --only firestore:rules,functions
```

✅ **What this does:**
- Deploys `firestore.rules` which ensures strict family-only data isolation (no stranger can read another family's check-ins).
- Deploys the scheduled grace-period check (`scheduledGracePeriodCheck`) running daily at cutoff time.
- Deploys the automatic missed check-in alert generator (`alertOnMissedCheckin`).

---

## Step 6: Add the Firebase iOS SDK in Xcode

1. Open `CareCircle.xcodeproj` in Xcode on your Mac.
2. Go to **File** $\rightarrow$ **Add Package Dependencies...**
3. In the search box, paste:
   ```
   https://github.com/firebase/firebase-ios-sdk.git
   ```
4. Set Dependency Rule: **Up to Next Major Version** (from `10.24.0` or latest).
5. Click **Add Package**.
6. When the list of package products appears, check:
   - `FirebaseCore`
   - `FirebaseAuth`
   - `FirebaseFirestore`
   - `FirebaseMessaging` (optional, for remote push)
7. Make sure the target is set to **CareCircle**, then click **Add Package**.

---

## Step 7: Testing Live Sync Across 2 Devices

Now you can test real-time cross-device communication!

### Device A (Aging Parent's iPhone or Simulator 1)
1. Launch CareCircle.
2. Enter the Parent test number: `+1 555-111-2222` and code `123456`.
3. Choose **Parent Mode** and name: `Dad (Arthur)`.
4. Choose **Create Circle** with name: `The Johnsons`.
5. You will see your Family Invite Code (e.g. `CARE92`).
6. You are now on the Parent Home screen with the big **"I'm okay today."** button.

### Device B (Adult Child's iPhone or Simulator 2)
1. Launch CareCircle.
2. Enter the Child test number: `+1 555-333-4444` and code `123456`.
3. Choose **Family Caregiver** and name: `Alice`.
4. Choose **Join Circle** and enter the invite code `CARE92`.
5. You are now on the **Family Dashboard**.
6. Dad's avatar circle will show as **"Waiting check-in"** (Amber ring).

### The Magic Moment:
- On **Device A (Parent)**: Tap **"I'm okay today."**
- Look at **Device B (Child)**: **Instantly without refreshing**, Dad's avatar ring transitions to a **solid Hearth Green circle** with the timestamp *"Checked in just now"*!

---

## 🔔 Optional: Setting Up Apple APNs Push Notifications

To receive push notifications on the lock screen when a parent misses their check-in:

1. **Apple Developer Account**:
   - Go to [developer.apple.com](https://developer.apple.com) $\rightarrow$ **Certificates, Identifiers & Profiles** $\rightarrow$ **Keys**.
   - Create an **Apple Push Notifications service (APNs)** key and download the `.p8` file.
2. **Firebase Console**:
   - Go to **Project Settings** $\rightarrow$ **Cloud Messaging** $\rightarrow$ **Apple app configuration**.
   - Upload the `.p8` key, Key ID, and Team ID.
3. **In Xcode**:
   - Select the `CareCircle` target $\rightarrow$ **Signing & Capabilities**.
   - Click `+ Capability` $\rightarrow$ Add **Push Notifications**.
   - Click `+ Capability` $\rightarrow$ Add **Background Modes** (check *Remote notifications*).

---

## 💡 Troubleshooting Tips

- **Missing `GoogleService-Info.plist`**: If the app fails to start with a Firebase error, ensure the plist file is inside the `CareCircle` folder and target membership is set to `CareCircle`.
- **Bundle ID Mismatch**: Make sure the Bundle ID in Xcode (`com.carecircle.app`) exactly matches the Bundle ID registered in Firebase Console.
- **Rules Permission Denied**: Always run `firebase deploy --only firestore:rules` to make sure your Firestore instance has the required membership security rules.
