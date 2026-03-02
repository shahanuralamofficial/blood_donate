# Blood Donate 🩸

A comprehensive, professional, and full-featured Blood Donation Mobile Application built with Flutter and Firebase. This app connects blood seekers with nearby donors in real-time, featuring a gamified rank system, integrated chat, and professional reporting.

## 🌟 Key Features

### 🚀 Core Functionalities
- **Real-time Blood Requests:** Create emergency blood requests that are instantly visible to nearby donors.
- **Smart Donor Search:** Find donors based on blood group and location (District/Thana) with distance calculation.
- **In-App Messaging:** Secure real-time chat between donors and patients to coordinate blood donation.
- **Push Notifications:** Stay updated with alerts for nearby requests, new messages, and status updates.
- **Saved Donors:** Save your preferred donors for quick access during future emergencies.

### 🏆 Gamification & Trust
- **Professional Rank System:** Dynamic user ranks (Newbie, Bronze, Silver, Gold, etc.) based on donation history.
- **Donor Reviews & Ratings:** Patients can rate and review donors after a successful or failed donation attempt.
- **Public Profiles:** View a donor's track record, rank, and reviews before reaching out.

### 📊 Utility & UX
- **PDF Report Generation:** Download a professional donation/request history report directly to your phone's File Manager.
- **Daily Donation Tips:** Insightful, daily rotating tips to educate and encourage the community.
- **Activity Tracking:** Comprehensive history of all requests, donations, and cancelled tasks.
- **Modern UI/UX:** A "Premium" feel with clean cards, smooth animations, and a professional color palette.

## 🛠️ Tech Stack
- **Framework:** [Flutter](https://flutter.dev/)
- **Backend:** [Firebase](https://firebase.google.com/) (Auth, Firestore, Cloud Messaging, Storage)
- **State Management:** [Riverpod](https://riverpod.dev/)
- **Location Services:** Geolocator & Geocoding
- **PDF Engine:** PDF & Printing packages
- **Local Storage:** Path Provider & Permission Handler

## 📁 Project Structure
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
    └── screens/          # Home, Chat, Request, Profile, Donor screens
```

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (latest version)
- Firebase Account
- Google Maps API Key (for location features)

### Installation
1. **Clone the repository:**
   ```bash
   git clone https://github.com/yourusername/blood_donate.git
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
   - Enable Email/Phone Auth and Firestore.

4. **Run the app:**
   ```bash
   flutter run
   ```

## 📸 Screenshots
*(Add your app screenshots here to make the repository look professional)*

## 🤝 Contributing
Contributions are welcome! If you'd like to improve the app, please:
1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3. Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the Branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📄 License
Distributed under the MIT License. See `LICENSE` for more information.

---
**Developed with ❤️ for saving lives.**
