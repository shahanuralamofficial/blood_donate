# রক্তদান - Blood Donate 🩸

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Firebase](https://img.shields.io/badge/Firebase-FFCA28?style=for-the-badge&logo=firebase&logoColor=black)](https://firebase.google.com)
[![Riverpod](https://img.shields.io/badge/Riverpod-00C4B4?style=for-the-badge&logo=dart&logoColor=white)](https://riverpod.dev)
[![Agora](https://img.shields.io/badge/Agora-80C41C?style=for-the-badge&logo=agora&logoColor=white)](https://www.agora.io)
[![Cloudinary](https://img.shields.io/badge/Cloudinary-3448C5?style=for-the-badge&logo=cloudinary&logoColor=white)](https://cloudinary.com)

**Blood Donate** is a high-performance, real-time blood donation ecosystem built to save lives through technology. It features a "Modern Red" aesthetic, robust localization (Bangla/English), real-time communication, and integrated video/voice calling.

---

## 📸 App Showcase

<p align="center">
  <img src="./assets/screenshots/home.png" width="31%" alt="Home Screen" />
  <img src="./assets/screenshots/request.png" width="31%" alt="Request Screen" />
  <img src="./assets/screenshots/donor.png" width="31%" alt="Donor List" />
</p>

<p align="center">
  <img src="./assets/screenshots/profile.png" width="31%" alt="User Profile" />
  <img src="./assets/screenshots/chat.png" width="31%" alt="Chat System" />
  <img src="./assets/screenshots/search.png" width="31%" alt="Search Screen" />
</p>

---

## ✨ Key Features

### 🩸 Smart Blood Requests & Management
- **Hyper-Local Data**: Integrated with comprehensive Bangladeshi division, district, thana, and union data for precise location matching.
- **Intelligent Forms**: Context-aware guidance for quick request creation.
- **WhatsApp Integration**: Automatic fallback to WhatsApp for better communication.
- **Emergency Priority**: High-visibility alerts for urgent blood needs with push notifications.

### 📞 Advanced Communication (Real-time)
- **Voice & Video Calling**: Powered by **Agora RTC** for direct and secure communication between donors and recipients.
- **Smart Chat System**: Real-time messaging with **Image & Video sharing** capabilities.
- **Media Previews**: Send media with captions and preview them before sending.
- **Cloudinary Integration**: Efficient and fast media hosting for chat and profile pictures.

### 🏅 Gamification & Donor Ranks
Encouraging regular donations through a dynamic milestone-based ranking system:
- 🌱 **Newbie** | 🥉 **Bronze** | 🥈 **Silver** | 🥇 **Gold** | 💎 **Platinum** | 👑 **Diamond**

### 📄 Professional Tools
- **PDF Reports**: Professional donation/receipt history generation with Bengali typography support.
- **Profile Customization**: Users can update profile pictures and details seamlessly.
- **Push Notifications**: Instant alerts for nearby requests, messages, and call logs.

---

## 🛠️ Tech Stack & Architecture

This project follows **Clean Architecture** to ensure long-term maintainability.

- **Frontend**: Flutter (Dart)
- **State Management**: [Riverpod](https://riverpod.dev/) (Provider-based logic)
- **Backend**: 
  - **Firebase**: Firestore, Cloud Messaging (FCM), Firebase Auth.
  - **Cloudinary**: Media storage & optimization.
  - **Agora**: Real-time voice and video engine.
- **UI/UX**: 
  - **Theme**: "Modern Red" palette with a focus on accessibility.
  - **Fonts**: Google Fonts (Noto Sans Bengali).
  - **Localization**: Full BN/EN dynamic translation system.

### 📂 Project Structure
```text
lib/
├── core/             # Global Themes, Services (Cloudinary, Agora), Localization
├── data/             # Models, Repositories, and Firebase Data Sources
├── domain/           # Business Logic Interfaces and Entities
└── presentation/     # UI Screens (Auth, Chat, Home, Profile) and Providers
```

---

## 🚀 Getting Started

1. **Clone the repository**:
   ```bash
   git clone https://github.com/shahanuralamofficial/blood_donate.git
   ```

2. **Install dependencies**:
   ```bash
   flutter pub get
   ```

3. **Firebase & Cloudinary Setup**:
   - Place `google-services.json` in `android/app/`.
   - Update `cloudinary_service.dart` with your Cloudinary credentials.
   - Update Agora App ID in your calling service.

4. **Run the app**:
   ```bash
   flutter run
   ```

---

## 📄 License
This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---
<p align="center">
  <b>Developed with ❤️ for the Community.</b><br>
  <i>"Your contribution can save a life today."</i>
</p>
