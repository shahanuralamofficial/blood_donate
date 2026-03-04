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
</p>

---

## 📜 Table of Contents
- [About The Project](#about-the-project)
- [✨ Key Features](#-key-features)
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
| **PDF Report Generation**     | Download a professional donation history report with **100% correct Bengali typography** support.                                        |
| **Gamification & Ranks**      | A dynamic user ranking system (Newbie, Bronze, Silver, etc.) to motivate and reward active donors.                                         |
| **Public Profiles & Reviews** | Donors have public profiles with their rank, donation stats, and ratings from patients to build trust.                                   |
| **Modern & Professional UI**  | A "Premium" feel with clean cards, smooth animations, and a user-friendly design.                                                        |

## 🛠️ Tech Stack & Architecture

This project is built with a modern and scalable tech stack to ensure a high-quality user experience.

| Category             | Technology                                                                                                  |
| -------------------- | ----------------------------------------------------------------------------------------------------------- |
| **Framework**        | [Flutter](https://flutter.dev/)                                                                             |
| **Backend**          | [Firebase](https://firebase.google.com/) (Auth, Firestore, Cloud Messaging, Storage)                         |
| **State Management** | [Riverpod](https://riverpod.dev/)                                                                           |
| **Services**         | Geolocator, Geocoding, Permission Handler, Path Provider                                                    |
| **Reporting**        | [Printing](https://pub.dev/packages/printing) (HTML-to-PDF engine for perfect Bengali rendering)            |

### Project Structure
```text
lib/
├── core/
│   ├── services/         # Notification, Location, Report (PDF) services
│   └── theme/            # Professional App Theme
├── data/
│   ├── models/           # User, Donor, Request, Message models
│   └── repositories/     # Firebase implementation logic
└── presentation/
    ├── providers/        # Riverpod state providers
    └── screens/          # All UI screens for each feature
```

## 🚀 Getting Started

Follow these instructions to get a copy of the project up and running on your local machine.

### Prerequisites
- Flutter SDK (latest version)
- Firebase Account
- Google Maps API Key (for location features)

### Installation
1. **Clone the repository:**
   ```bash
   git clone https://github.com/shahanuralamofficial/blood_donate.git
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

4. **Run the app:**
   ```bash
   flutter run
   ```

## 🤝 Contributing

Contributions, issues, and feature requests are welcome! 
1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3. Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the Branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📄 License

Distributed under the MIT License.

---
<p align="center">
  **Developed with ❤️ for saving lives.**
</p>
