# Blood Donate – Find Blood Donors 🩸

**Blood Donate – Find Blood Donors** is a premium, life-saving mobile application designed to bridge the gap between blood donors and those in need. Built with Flutter and Firebase, it offers a seamless experience for finding donors, managing requests, and staying connected within the community.

---

## 📱 App Showcase

<p align="center">
  <img src="assets/screenshots/home.png" width="250" alt="Home Screen">
  <img src="assets/screenshots/search.png" width="250" alt="Search Donors">
  <img src="assets/screenshots/donor.png" width="250" alt="Donor Profile">
</p>

<p align="center">
  <img src="assets/screenshots/request.png" width="250" alt="Blood Request">
  <img src="assets/screenshots/chat.png" width="250" alt="Real-time Chat">
  <img src="assets/screenshots/profile.png" width="250" alt="User Profile">
</p>

---

## ✨ Key Features

### 🩸 Core Donation Features
*   **Smart Donor Search:** Quickly find blood donors filtered by blood group and specific locations (District/Upazila/Union).
*   **Emergency Requests:** Post urgent blood requirements that notify nearby matching donors.
*   **Donor Availability:** Volunteers can list themselves as active or hidden from the donor list.
*   **Rank System:** Rewarding frequent donors with badges (Newbie to Diamond) based on their contributions.

### 🤖 AI & Health Tools
*   **Prescription Reader:** Manage your medications easily. Currently supports manual entry with an AI-powered OCR scanner in development.
*   **Medicine Reminders:** Set alarms for your doses (e.g., 1+0+1) to never miss a medicine.
*   **Donation Facts:** Daily updated health tips and facts about blood donation.

### 💬 Communication Suite
*   **Real-time Chat:** Secure, instant messaging between donors and recipients.
*   **Voice & Video Calls:** High-quality calling powered by **Agora RTC**, featuring a professional ringing interface.
*   **Image Sharing:** Secure storage for sharing medical reports or patient photos.

### 🛡️ Reliability & UX
*   **Full Localization:** Native support for both **Bangla** and **English**.
*   **App Drawer Navigation:** A clean, centralized navigation system.
*   **Push Notifications:** Instant alerts for new messages, donation requests, and rank updates.
*   **Secure Authentication:** Robust login and registration via Firebase.

---

## 🛠️ Tech Stack

*   **Frontend:** [Flutter](https://flutter.dev) (Dart)
*   **State Management:** [Riverpod](https://riverpod.dev)
*   **Backend:** [Firebase](https://firebase.google.com) (Firestore, Auth, Storage, Messaging)
*   **Real-time Media:** [Agora RTC](https://www.agora.io)
*   **Networking:** [Dio](https://pub.dev/packages/dio)
*   **Image Processing:** [Google ML Kit](https://developers.google.com/ml-kit) (OCR)
*   **Local Storage:** [Shared Preferences](https://pub.dev/packages/shared_preferences)

---

## 🚀 Getting Started

1.  **Clone the Repository:**
    ```bash
    git clone https://github.com/shahanuralamofficial/blood_donate.git
    ```
2.  **Install Dependencies:**
    ```bash
    flutter pub get
    ```
3.  **App Icon Generation:**
    ```bash
    flutter pub run flutter_launcher_icons
    ```
4.  **Firebase Setup:**
    - Place your `google-services.json` (Android) and `GoogleService-Info.plist` (iOS) in the respective directories.
5.  **Run the App:**
    ```bash
    flutter run
    ```

---

## 📂 Project Structure

*   `lib/presentation`: UI screens, widgets, and Riverpod providers.
*   `lib/data`: Models and repository implementations.
*   `lib/core`: App themes, constants, and localization logic.
*   `assets`: Images, sounds, and local data files (unions, donation facts).

---

## 📄 License
This project is licensed under the **MIT License**.

---
**Blood Donate – Find Blood Donors** - *Saving lives through technology.* ❤️
