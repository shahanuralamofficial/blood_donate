# রক্তদান - Blood Donate 🩸

একটি আধুনিক এবং জীবনরক্ষাকারী রক্তদান অ্যাপ, যা রক্তদাতা এবং গ্রহীতাদের মধ্যে দ্রুত সংযোগ স্থাপন করে। এতে রয়েছে রিয়েল-টাইম চ্যাট, অডিও/ভিডিও কল এবং ক্লাউড স্টোরেজ সুবিধা।

## ✨ মূল ফিচারসমূহ (Features)

*   **🩸 রক্ত অনুসন্ধান (Donor Search):** এলাকা এবং ব্লাড গ্রুপ অনুযায়ী দ্রুত রক্তদাতা খুঁজে পাওয়ার সুবিধা।
*   **💬 চ্যাট সিস্টেম (Real-time Chat):** চ্যাট অপশনের মাধ্যমে রক্তদাতার সাথে সরাসরি কথা বলার সুযোগ।
*   **📞 অডিও ও ভিডিও কল (Agora RTC):** সরাসরি অ্যাপের ভেতর থেকেই হাই-কোয়ালিটি অডিও এবং ভিডিও কল করার সুবিধা।
*   **🔔 রিংটোন ও ভাইব্রেশন:** কল আসলে প্রফেশনাল রিংটোন এবং ভাইব্রেশন অ্যালার্ট।
*   **🖼️ ইমেজ শেয়ারিং (Cloudinary):** চ্যাটে ছবি আদান-প্রদান এবং ক্লাউড স্টোরেজ সাপোর্ট।
*   **📍 লোকেশন ভিত্তিক সেবা:** ব্যবহারকারীর নিকটস্থ রক্তদাতাদের তালিকা দেখা।
*   **🔒 নিরাপদ লগইন:** ফায়ারবেস অথেন্টিকেশন (Firebase Authentication) এর মাধ্যমে নিরাপদ অ্যাক্সেস।

## 🛠️ ব্যবহৃত প্রযুক্তি (Tech Stack)

*   **Framework:** Flutter (Android & iOS)
*   **Backend:** Firebase (Firestore, Auth, Storage)
*   **Real-time Audio/Video:** Agora SDK
*   **Image Management:** Cloudinary
*   **State Management:** Provider
*   **Local Audio:** Audioplayers & Vibration

## 🚀 সেটআপ করার নিয়ম (Getting Started)

১. রিপোজিটরি ক্লোন করুন:
   ```bash
   git clone https://github.com/yourusername/blood_donate.git
   ```

২. ডিপেনডেন্সি ইনস্টল করুন:
   ```bash
   flutter pub get
   ```

৩. অ্যাসেট ফোল্ডারে আপনার রিংটোন ফাইলগুলো যোগ করুন:
   - `assets/sounds/incoming_call.mp3`
   - `assets/sounds/outgoing_call.mp3`

৪. অ্যাপটি রান করুন:
   ```bash
   flutter run
   ```

## 📂 প্রোজেক্ট স্ট্রাকচার

*   `lib/presentation`: UI এবং স্টেট ম্যানেজমেন্ট।
*   `lib/data`: মডেল এবং রিপোজিটরি (Firestore Integration)।
*   `assets`: ইমেজ এবং সাউন্ড ফাইল।

## 📄 লাইসেন্স
এই প্রোজেক্টটি [MIT License](LICENSE) এর অধীনে লাইসেন্সকৃত।

---
**Blood Donate App** - জীবন বাঁচাই হাতে হাত রেখে। ❤️
