<p align="center">
  <!-- <img src="assets/logo.png" alt="Blood Donate Logo" width="120"/> -->
  <h1 align="center">Blood Donate 🩸</h1>
</p>

<p align="center">
  A comprehensive, professional, and full-featured Blood Donation Mobile Application built with Flutter and Firebase.
</p>

<p align="center">
  <img src="https://img.shields.io/badge/License-MIT-blue.svg" alt="License: MIT">
  <img src="https://img.shields.io/badge/Flutter-3.x-blue.svg" alt="Flutter">
  <img src="https://img.shields.io/badge/Platform-Android%20%7C%20iOS-green.svg" alt="Platform">
  <img src="https://img.shields.io/github/stars/shahanuralamofficial/blood_donate?style=social" alt="GitHub Stars">
</p>

---

## 📜 Table of Contents
- [About The Project](#about-the-project)
- [✨ Key Features](#-key-features)
- [📸 Screenshots](#-screenshots)
- [🛠️ Tech Stack & Architecture](#️-tech-stack--architecture)
- [🚀 Getting Started](#-getting-started)
- [🤝 Contributing](#-contributing)
- [📄 License](#-license)

## About The Project

**Blood Donate** is a modern, real-time mobile application designed to bridge the gap between blood donors and recipients. It provides a seamless platform for users to request blood during emergencies and for donors to find nearby requests. With a gamified ranking system, integrated chat, and professional reporting, the app aims to build a reliable and engaged community of lifesavers.

## ✨ Key Features

| Feature                       | Description                                                                                                                              |
| ----------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------- |
| **Real-time Blood Requests**  | Create and view emergency requests that are instantly visible to nearby donors.                                                          |
| **Smart Donor/Patient Search**| Find donors or active requests using filters for blood group and location.                                                                |
| **In-App Messaging**          | Secure real-time chat between donors and patients with real user names and profile pictures.                                               |
| **Push Notifications**        | A professional notification center with alerts for nearby requests, messages, and donation status updates.                                 |
| **PDF Report Generation**     | Download a professional donation history report directly to the phone's Download folder.                                                   |
| **Gamification & Ranks**      | A dynamic user ranking system (Newbie, Bronze, Silver, etc.) to motivate and reward active donors.                                         |
| **Public Profiles & Reviews** | Donors have public profiles with their rank, donation stats, and ratings from patients to build trust.                                   |
| **Accountability System**     | Patients can review donors and report no-shows, ensuring a reliable community.                                                           |
| **Modern & Professional UI**  | A "Premium" feel with clean cards, smooth animations, and a user-friendly design.                                                        |

## 📸 Screenshots

<!-- Replace with your actual screenshots -->
<p align="center">
  <img src="" alt="Home Screen" width="200"/>
  <img src="" alt="Donor Profile" width="200"/>
  <img src="" alt="Chat List" width="200"/>
  <img src="" alt="Notifications" width="200"/>
</p>

## 🛠️ Tech Stack & Architecture

This project is built with a modern and scalable tech stack to ensure a high-quality user experience.

| Category             | Technology                                                                                                  |
| -------------------- | ----------------------------------------------------------------------------------------------------------- |
| **Framework**        | [Flutter](https://flutter.dev/)                                                                             |
| **Backend**          | [Firebase](https://firebase.google.com/) (Auth, Firestore, Cloud Messaging, Storage)                         |
| **State Management** | [Riverpod](https://riverpod.dev/)                                                                           |
| **Services**         | Geolocator, Geocoding, Permission Handler, Path Provider                                                    |
| **UI & Other**       | Google Fonts, Intl, URL Launcher, PDF                                                                       |

### Project Structure
```text
lib/
├── core/
│   ├── services/         # Notification, Location, Report services
│   └── theme/            # Professional App Theme
├── data/
│   ├── models/           # User, Donor, Request, Message models
│   └── repositories/     # Firebase implementation logic
├── domain/
│   └── repositories/     # Repository interfaces
└── presentation/
    ├── providers/        # Riverpod state providers
    └── screens/          # All UI screens for each feature
```

## 🚀 Getting Started

Follow these instructions to get a copy of the project up and running on your local machine for development and testing purposes.

### Prerequisites
- Flutter SDK (latest version)
- Firebase Account
- Google Maps API Key (for location features)

### Installation
1. **Clone the repository:**
   ```bash
   git clone https://github.com/shahanuralamofficial/blood_donate.git
   cd blood_donate
   ```

2. **Install dependencies:**
   ```bash
   flutter pub get
   ```

3. **Firebase Setup:**
   - Create a new Firebase project.
   - Add Android/iOS apps in Firebase Console.
   - Download and place `google-services.json` in `android/app/`.
   - Enable **Email/Phone Auth**, **Firestore**, and **Storage**.
   - For Push Notifications, you will need to upload your APNs certificate (for iOS) and configure FCM.

4. **Run the app:**
   ```bash
   flutter run
   ```

## 🤝 Contributing

Contributions, issues, and feature requests are welcome! Feel free to check the [issues page](https://github.com/shahanuralamofficial/blood_donate/issues).
1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3. Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the Branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📄 License

Distributed under the MIT License. See `LICENSE` for more information.

---
<p align="center">
  **Developed with ❤️ for saving lives.**
</p>
