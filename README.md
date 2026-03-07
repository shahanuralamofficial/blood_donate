# রক্তদান - Blood Donate 🩸

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Firebase](https://img.shields.io/badge/Firebase-FFCA28?style=for-the-badge&logo=firebase&logoColor=black)](https://firebase.google.com)
[![Riverpod](https://img.shields.io/badge/Riverpod-00C4B4?style=for-the-badge&logo=dart&logoColor=white)](https://riverpod.dev)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg?style=for-the-badge)](https://opensource.org/licenses/MIT)

**Blood Donate** is a modern, real-time blood donation platform designed to bridge the gap between donors and recipients. Built with a focus on user experience, it features a "Modern Red" aesthetic, robust localization (Bangla/English), and a gamified ranking system to encourage life-saving contributions.

---

## 📸 App Showcase

<p align="center">
  <img src="./assets/screenshots/home.png" width="32%" alt="Home Screen" />
  <img src="./assets/screenshots/request.png" width="32%" alt="Request Screen" />
  <img src="./assets/screenshots/search.png" width="32%" alt="Search Screen" />
</p>

<p align="center">
  <img src="./assets/screenshots/profile.png" width="32%" alt="User Profile" />
  <img src="./assets/screenshots/chat.png" width="32%" alt="Chat System" />
</p>

---

## ✨ Key Features

### 🩸 Smart Blood Requests & Management
- **Localized Precision**: Integrated with comprehensive Bangladeshi division/district/thana/union data.
- **Intelligent Forms**: Context-aware hints (e.g., `hospital_hint`, `problem_hint`) guide users through quick request creation.
- **WhatsApp Fallback**: Automated logic uses primary phone numbers for WhatsApp if not provided separately.
- **Emergency Priority**: High-visibility alerts for urgent blood needs with location-based push notifications.

### 🏅 Gamification & Donor Ranks
Encouraging regular donations through a dynamic milestone-based ranking system:
- 🌱 **Newbie** (0 Donations) | 🥉 **Bronze** (1+) | 🥈 **Silver** (5+)
- 🥇 **Gold** (15+) | 💎 **Platinum** (30+) | 👑 **Diamond** (50+)

### 💬 Real-time Communication
- **Direct Messaging**: Secure in-app chat system between donors and recipients.
- **Privacy First**: Optional email verification and secure data handling.
- **Smart Notifications**: Instant alerts for messages, nearby requests, and rank updates.

### 📄 Professional Reporting & History
- **PDF Generation**: Download professional donation/receipt history with proper Bengali typography support.
- **Activity Tracking**: Comprehensive logs of all completed, pending, and cancelled requests.

---

## 🛠️ Tech Stack & Architecture

This project implements **Clean Architecture** principles to ensure scalability, maintainability, and ease of testing.

- **Frontend**: Flutter (Dart)
- **State Management**: [Riverpod](https://riverpod.dev/) (Refined provider-based state handling)
- **Backend Service**: Firebase Ecosystem
  - **Firestore**: Real-time NoSQL database with optimized indexing.
  - **Cloud Messaging (FCM)**: Cross-platform push notifications.
  - **Firebase Auth**: Secure authentication flow.
- **UI/UX**: 
  - **Theme**: "Modern Red" palette (`0xFFE53935`) with rounded design language (20-24px radius).
  - **Fonts**: Google Fonts (Noto Sans Bengali) for native readability.
  - **Localization**: Fully dynamic BN/EN translation system.

### 📂 Project Structure
```text
lib/
├── core/             # Themes, Routing, Localization, Global Services
├── data/             # Models, Repositories, and Data Sources (Firebase)
├── domain/           # Business Logic, Interfaces, and Entities
└── presentation/     # UI Screens, Widgets, and Riverpod Providers
```

---

## 🚀 Installation & Setup

1. **Clone the repository**:
   ```bash
   git clone https://github.com/shahanuralamofficial/blood_donate.git
   ```

2. **Install dependencies**:
   ```bash
   flutter pub get
   ```

3. **Firebase Configuration**:
   - Create a project in the [Firebase Console](https://console.firebase.google.com/).
   - Add an Android app and place the `google-services.json` in `android/app/`.
   - Enable Firestore, Auth (Email/Pass), and Cloud Messaging.

4. **Environment Check**:
   - Ensure your assets folder contains `unions.json` for location data.
   - Run `flutter doctor` to verify your environment.

5. **Run the app**:
   ```bash
   flutter run
   ```

---

## 🎯 Development Roadmap
- [ ] **Map Integration**: Visualizing nearby donors on Google Maps.
- [ ] **Dark Mode**: Implementing a refined dark version of the Modern Red theme.
- [ ] **Advanced Filtering**: Enhanced donor search based on last donation date and availability.
- [ ] **Volunteer Dashboard**: Dedicated interface for blood donation organizations.

---

## 📄 License
This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🤝 Contribution
Contributions are what make the open-source community such an amazing place to learn, inspire, and create. Any contributions you make are **greatly appreciated**.

1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3. Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the Branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

---
<p align="center">
  <b>Developed with ❤️ for the Community.</b><br>
  <i>"Donate Blood, Save Lives"</i>
</p>
