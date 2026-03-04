<p align="center">
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
- [🏅 Gamification & Ranks](#-gamification--ranks)
- [🛠️ Tech Stack & Architecture](#️-tech-stack--architecture)
- [🚀 Getting Started](#-getting-started)
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
| **PDF Report Generation**     | Download a professional donation history report with **100% correct Bengali typography** (Jukto-borno) support using HTML rendering.      |
| **Public Profiles & Reviews** | Donors have public profiles with their rank, donation stats, and ratings from patients to build trust.                                   |
| **Donor Appreciation**        | A special celebration system that triggers a dialog and badges when a donor completes a donation and level up.                          |
| **Privacy & Security**        | Only owners can see their "Thank You Notes," while "Reviews" are public to maintain a transparent and respectful community.               |

## 🏅 Gamification & Ranks

The app motivates donors through a dynamic ranking system based on their self-donation count:

- 🌱 **Newbie**: Starting point (0 donations)
- 🥉 **Bronze**: 1+ Donations
- 🥈 **Silver**: 5+ Donations
- 🥇 **Gold**: 15+ Donations
- 💎 **Platinum**: 30+ Donations
- 👑 **Diamond**: 50+ Donations

## 🛠️ Tech Stack & Architecture

This project is built with a modern and scalable tech stack to ensure a high-quality user experience.

| Category             | Technology                                                                                                  |
| -------------------- | ----------------------------------------------------------------------------------------------------------- |
| **Framework**        | [Flutter](https://flutter.dev/)                                                                             |
| **Backend**          | [Firebase](https://firebase.google.com/) (Auth, Firestore, Cloud Messaging, Storage)                         |
| **State Management** | [Riverpod](https://riverpod.dev/)                                                                           |
| **Typography**       | Google Fonts (Noto Sans Bengali) for professional report aesthetics.                                        |
| **Reporting**        | [Printing](https://pub.dev/packages/printing) (HTML-to-PDF engine for perfect Bengali rendering)            |

### Project Structure
```text
lib/
├── core/
│   ├── services/         # Notification, Location, Report (PDF) services
│   └── theme/            # Professional App Theme
├── data/
│   ├── models/           # User, Request, Message models
│   └── repositories/     # Firebase implementation logic
└── presentation/
    ├── providers/        # Riverpod state providers
    └── screens/          # All UI screens (Home, Profile, Requests, etc.)
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
   - Place `google-services.json` in `android/app/`.
   - Enable **Email/Phone Auth**, **Firestore**, and **Storage**.

4. **Run the app:**
   ```bash
   flutter run
   ```

## 📄 License

Distributed under the MIT License.

---
<p align="center">
  **Developed with ❤️ for saving lives.**
</p>
