# রক্তদান - Blood Donate 🩸

A modern and life-saving blood donation app that quickly connects blood donors and recipients. It includes real-time chat, audio/video calling, and cloud storage features.

## 📱 App Showcase

<p align="center">
  <img src="https://via.placeholder.com/200x400?text=Login+Screen" width="200" alt="Login Screen">
  <img src="https://via.placeholder.com/200x400?text=Home+Screen" width="200" alt="Home Screen">
  <img src="https://via.placeholder.com/200x400?text=Chat+Screen" width="200" alt="Chat Screen">
  <img src="https://via.placeholder.com/200x400?text=Call+Screen" width="200" alt="Call Screen">
</p>

## ✨ Key Features

*   **🩸 Donor Search:** Easily find blood donors by area and blood group.
*   **💬 Real-time Chat:** Communicate directly with donors through the in-app chat.
*   **📞 Audio & Video Calls (Agora RTC):** High-quality audio and video calling directly within the app.
*   **🔔 Ringtone & Vibration:** Professional ringtone and vibration alerts for incoming calls.
*   **🖼️ Image Sharing (Cloudinary):** Send and receive images in chat with cloud storage support.
*   **📍 Location-based Services:** View a list of nearby blood donors.
*   **🔒 Secure Login:** Safe access via Firebase Authentication.

## 🛠️ Tech Stack

*   **Framework:** Flutter (Android & iOS)
*   **Backend:** Firebase (Firestore, Auth, Storage)
*   **Real-time Audio/Video:** Agora SDK
*   **Image Management:** Cloudinary
*   **State Management:** Provider
*   **Local Audio:** Audioplayers & Vibration

## 🚀 Getting Started

1. Clone the repository:
   ```bash
   git clone https://github.com/shahanuralamofficial/blood_donate.git
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Add your ringtone files to the assets folder:
   - `assets/sounds/incoming_call.mp3`
   - `assets/sounds/outgoing_call.mp3`

4. Run the app:
   ```bash
   flutter run
   ```

## 📂 Project Structure

*   `lib/presentation`: UI and state management.
*   `lib/data`: Models and repositories (Firestore Integration).
*   `assets`: Image and sound files.

## 📄 License
This project is licensed under the [MIT License](LICENSE).

---
**Blood Donate App** - Saving lives, hand in hand. ❤️
