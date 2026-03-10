# রক্তদান - Blood Donate 🩸

**রক্তদান - Blood Donate** is a premium, life-saving mobile application designed to bridge the gap between blood donors and those in need. Built with a focus on speed, reliability, and a premium user experience, it empowers users to find donors, communicate in real-time, and even leverage AI for medical tasks.

---

## 📱 App Showcase

<p align="center">
  <img src="https://via.placeholder.com/200x400?text=Splash+Screen" width="200" alt="Splash Screen">
  <img src="https://via.placeholder.com/200x400?text=Home+Screen" width="200" alt="Home Screen">
  <img src="https://via.placeholder.com/200x400?text=Donor+Search" width="200" alt="Donor Search">
  <img src="https://via.placeholder.com/200x400?text=AI+Reader" width="200" alt="AI Reader">
</p>

---

## ✨ Key Features

### 🩸 Core Donation Features
*   **Smart Donor Search:** Quickly find blood donors filtered by blood group and specific locations (District/Upazila/Union).
*   **Donor Registration:** Easy-to-use profile setup for volunteers to list themselves as active donors.
*   **Real-time Availability:** See who is available to donate right now.

### 🤖 AI & Health Tools
*   **AI Prescription Reader:** Integrated OCR (Google ML Kit) to scan and extract text from medical prescriptions instantly.
*   **Health Facts:** Daily updated blood donation facts and health tips to keep users informed.
*   **Coming Soon:** Dedicated sections for Hospital and Doctor directories with premium UI.

### 💬 Communication Suite
*   **Real-time Chat:** Secure, instant messaging between donors and recipients.
*   **Voice & Video Calls:** High-quality calling powered by **Agora RTC**, featuring a professional "Ringing" interface.
*   **Smart Call Timeout:** Automatic 60-second ringing timeout to prevent battery drain and improve UX.
*   **Image Sharing:** Share medical reports or photos via Cloudinary-backed secure storage.

### 🛡️ Reliability & UX
*   **Unified Navigation:** A clean, centralized `AppDrawer` for seamless navigation across all features.
*   **Full Localization:** Optimized for both **Bangla** and **English** languages.
*   **Push Notifications:** Stay updated with instant alerts for donation requests or messages.
*   **Secure Auth:** Robust authentication via Firebase.

---

## 🛠️ Tech Stack

*   **Frontend:** [Flutter](https://flutter.dev) (Dart)
*   **State Management:** [Riverpod](https://riverpod.dev) (Modern & Scalable)
*   **Backend:** [Firebase](https://firebase.google.com) (Firestore, Auth, Storage, Messaging)
*   **Real-time Media:** [Agora RTC](https://www.agora.io)
*   **AI Engine:** [Google ML Kit](https://developers.google.com/ml-kit) (Text Recognition)
*   **Networking:** [Dio](https://pub.dev/packages/dio) & [HTTP](https://pub.dev/packages/http)
*   **Image Handling:** [Cloudinary](https://cloudinary.com) & [CachedNetworkImage](https://pub.dev/packages/cached_network_image)
*   **Audio/Haptics:** [Audioplayers](https://pub.dev/packages/audioplayers) & [Vibration](https://pub.dev/packages/vibration)

---

## 🚀 Getting Started

1.  **Clone the Repo:**
    ```bash
    git clone https://github.com/shahanuralamofficial/blood_donate.git
    ```
2.  **Install Dependencies:**
    ```bash
    flutter pub get
    ```
3.  **Firebase Setup:**
    - Place your `google-services.json` (Android) and `GoogleService-Info.plist` (iOS) in the respective directories.
4.  **Run the App:**
    ```bash
    flutter run
    ```

---

## 📂 Project Highlights

*   **Modular Architecture:** Separated into `presentation`, `data`, and `core` layers for high maintainability.
*   **Performance Optimized:** Refactored `RootScreen` and unified widgets to reduce widget rebuilds and code bloat.
*   **Premium Assets:** Custom-tuned ringtones and high-quality UI components.

---

## 📄 License
This project is licensed under the **MIT License**.

---
**Blood Donate App** - *Saving lives through technology.* ❤️
