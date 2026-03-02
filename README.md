# রক্তদান (Blood Donate) 🩸

A full-featured, fintech-aware Blood Donation Mobile Application built with Flutter and Firebase. This application facilitates seamless connections between blood donors and seekers, featuring a professional escrow-based payment system for paid donations, real-time tracking, and administrative oversight.

## 🚀 Key Features

### 1. Authentication & Role-Based Access
- **Multi-Role System:** Donor, Patient, Clinic, and Admin roles.
- **Secure Auth:** Firebase Email/Password authentication.
- **Verification:** Administrative verification for clinics and premium donors.

### 2. Advanced Donor Profiles
- **Comprehensive Data:** Blood group, gender, and last donation date tracking.
- **Donation Types:** Supports both **Free** and **Paid** donation models.
- **Location Intelligence:** Integrated Bangladesh administrative units (Division, District, Thana, Union).

### 3. Location & Map Services 📍
- **Proximity Search:** Find the nearest donors in real-time.
- **Google Maps Integration:** Visual markers for donors and clinics.
- **Priority Filtering:** Free donors are prioritized in search results.

### 4. Fintech & Wallet System 💰
- **Escrow Logic:** Securely hold payments until donation is confirmed.
- **Automatic Fee Split:** Cloud Functions automatically handle the **80% (Donor) / 20% (App Owner)** revenue split.
- **Digital Wallet:** Track earnings, pending withdrawals, and transaction history.
- **Withdrawal Requests:** Formal process for donors to cash out their earnings.

### 5. Blood Request Workflow
- **Emergency Alerts:** One-tap emergency requests that trigger instant FCM push notifications to matching donors.
- **In-App Messaging:** Real-time text coordination between donor and seeker.
- **Status Tracking:** From 'Pending' to 'Accepted' and 'Completed'.

### 6. Clinic & Administrative Tools
- **Clinic Registry:** Verified clinics visible on the map for safe donation environments.
- **Admin Panel:** Comprehensive dashboard for user verification, transaction monitoring, and revenue analytics.
- **Reporting:** Generate and download monthly earnings/donation reports in PDF format.

## 🛠️ Tech Stack

- **Frontend:** Flutter (Latest Stable)
- **State Management:** Riverpod
- **Backend:** Firebase (Auth, Firestore, Storage, Cloud Functions, Messaging)
- **Maps:** Google Maps API & Geolocator
- **Architecture:** Clean Architecture (Data, Domain, Presentation layers)
- **Design:** Material 3 with Noto Sans Bengali typography.

## ⚙️ Installation & Setup

1. **Clone the repository:**
   ```bash
   git clone https://github.com/shahanuralamofficial/blood_donate.git
   ```

2. **Install dependencies:**
   ```bash
   flutter pub get
   ```

3. **Firebase Configuration:**
   - Create a Firebase project and add Android/iOS apps.
   - Download and place `google-services.json` and `GoogleService-Info.plist` in the respective directories.
   - Run `flutterfire configure`.

4. **Google Maps API:**
   - Enable Maps SDK for Android/iOS in Google Cloud Console.
   - Add your API key to `AndroidManifest.xml` and `AppDelegate.swift`.

5. **Cloud Functions:**
   - Deploy the provided functions in the `/functions` directory:
   ```bash
   firebase deploy --only functions
   ```

6. **Run the app:**
   ```bash
   flutter run
   ```

## 🛡️ Security & Ethics
- **Firestore Security Rules:** Granular access control for wallets and personal data.
- **Paid Donation Disclaimer:** Clear ethical guidelines and platform fees disclosure.
- **Admin Oversight:** Ability to ban accounts for misuse or fraudulent requests.

## 📄 License
This project is licensed under the MIT License - see the LICENSE file for details.

---
*Built with ❤️ for a better community.*
