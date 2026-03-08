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
- **Real-time Video & Voice Calls**: Seamless communication via **Agora RTC** for donors and recipients.
- **Rich Media Messaging**: Share **Images & Videos** in chat with high-speed delivery powered by **Cloudinary**.
- **Interactive Previews**: Send media with **Captions** and enjoy an integrated video player experience.

### 🩸 Smart Blood Request System
- **Patient Photo Support**: Optionally upload the patient's photo to increase the credibility of the request.
- **Hyper-Local Precision**: Integrated with detailed Bangladeshi location data (Division, District, Upazila, Union).
- **Emergency Priority**: High-visibility alerts and push notifications for urgent blood requirements.

### 🏅 Gamification & Management
- **Donor Ranks**: Dynamic milestone-based ranking system from **Newbie** to **Diamond**.
- **PDF History**: Generate professional donation reports and receipts with full Bengali font support.
- **Bi-lingual UI**: Fully localized experience in both **Bangla** and **English**.

---

## 🛠️ Tech Stack & Architecture

- **Frontend**: Flutter (Dart)
- **State Management**: [Riverpod](https://riverpod.dev/) (Scalable & predictable logic)
- **Backend**: Firebase (Firestore, Cloud Messaging, Auth, Storage)
- **Media Hosting**: Cloudinary (Image & Video optimization)
- **RTC Engine**: Agora RTC SDK
- **Design Pattern**: Clean Architecture (Separation of Concerns)

---

## 🚀 Getting Started

1. **Clone the repository**:
   ```bash
   git clone https://github.com/shahanuralamofficial/blood_donate.git
   ```

2. **Setup Services**:
   - Add `google-services.json` to `android/app/`.
   - Update **Agora App ID** and **Cloudinary Credentials** in `core/services/`.

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
  <i>"Your one drop of blood can bring a smile to a family."</i>
</p>
