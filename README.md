# রক্তদান - Blood Donate 🩸

**A premium, real-time blood donation application designed to save lives through seamless connectivity.**

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Firebase](https://img.shields.io/badge/Firebase-FFCA28?style=for-the-badge&logo=firebase&logoColor=black)](https://firebase.google.com)
[![Riverpod](https://img.shields.io/badge/Riverpod-00C4B4?style=for-the-badge&logo=dart&logoColor=white)](https://riverpod.dev)
[![Agora](https://img.shields.io/badge/Agora-80C41C?style=for-the-badge&logo=agora&logoColor=white)](https://www.agora.io)
[![Cloudinary](https://img.shields.io/badge/Cloudinary-3448C5?style=for-the-badge&logo=cloudinary&logoColor=white)](https://cloudinary.com)

---

## 📸 App Showcase

| Home Screen | Donor Search | Blood Request |
| :---: | :---: | :---: |
| <img src="./assets/screenshots/home.png" width="100%" alt="Home" /> | <img src="./assets/screenshots/donor.png" width="100%" alt="Donor" /> | <img src="./assets/screenshots/request.png" width="100%" alt="Request" /> |

| Real-time Chat | User Profile | Advanced Search |
| :---: | :---: | :---: |
| <img src="./assets/screenshots/chat.png" width="100%" alt="Chat" /> | <img src="./assets/screenshots/profile.png" width="100%" alt="Profile" /> | <img src="./assets/screenshots/search.png" width="100%" alt="Search" /> |

---

## ✨ Key Features

### 🚀 Advanced Communication
- **Real-time Video & Voice Calls**: Direct and secure communication between donors and recipients via **Agora RTC**.
- **Rich Messaging Engine**: Chat with support for **Images & Videos**, powered by **Cloudinary**.
- **Interactive Media Previews**: Preview images/videos with captions before sending.

### 🩸 Smart Donor Ecosystem
- **Hyper-Local Precision**: Integrated with detailed Bangladeshi location data (Division, District, Upazila, Union).
- **Gamified Ranking System**: Incentivizing donors with ranks from **Newbie** to **Diamond**.
- **Instant Emergency Alerts**: High-visibility blood request cards with location-based notifications.

### 📄 Professional Management
- **PDF Generation**: Download professional donation history reports with full Bengali font support.
- **Dynamic Profile System**: Upload and manage profile pictures with ease.
- **Bi-lingual Interface**: Fully localized experience in both **Bangla** and **English**.

---

## 🛠️ Tech Stack & Architecture

- **Frontend**: Flutter (Dart)
- **State Management**: [Riverpod](https://riverpod.dev/) (Refined logic and data flow)
- **Real-time Backend**: Firebase (Firestore, Cloud Messaging, Auth, Storage)
- **Media Engine**: Cloudinary (High-speed image/video hosting)
- **RTC Engine**: Agora RTC SDK
- **Architecture**: Clean Architecture (Layered separation of concerns)

---

## 🚀 Getting Started

1. **Clone the repository**:
   ```bash
   git clone https://github.com/shahanuralamofficial/blood_donate.git
   ```

2. **Configure Services**:
   - Update `google-services.json` in `android/app/`.
   - Update your **Agora App ID** and **Cloudinary Credentials** in the `core/services` folder.

3. **Install & Run**:
   ```bash
   flutter pub get
   flutter run
   ```

---

## 📄 License
This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---
<p align="center">
  <b>Developed with ❤️ for the Community.</b><br>
  <i>"Your one drop of blood can save a life today."</i>
</p>
