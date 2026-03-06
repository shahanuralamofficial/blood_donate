# Blood Donate 🩸 | জীবনের প্রয়োজনে রক্তদান

[![Flutter](https://img.shields.io/badge/Flutter-3.x-blue.svg?style=for-the-badge&logo=flutter)](https://flutter.dev)
[![Firebase](https://img.shields.io/badge/Firebase-Auth%20|%20Firestore%20|%20Cloud%20Messaging-orange.svg?style=for-the-badge&logo=firebase)](https://firebase.google.com)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg?style=for-the-badge)](https://opensource.org/licenses/MIT)

**Blood Donate** একটি আধুনিক এবং রিয়েল-টাইম মোবাইল অ্যাপ্লিকেশন যা রক্তদাতা এবং রক্তগ্রহীতাদের মধ্যে দূরত্ব কমিয়ে জীবন বাঁচাতে সাহায্য করে। এটি শুধুমাত্র একটি ব্লাড রিকোয়েস্ট অ্যাপ নয়, বরং এতে রয়েছে গ্যামিফিকেশন, প্রফেশনাল রিপোর্ট জেনারেশন এবং সিকিউর চ্যাটিং সিস্টেম।

---

## 📸 App Showcase

<p align="center">
  <img src="https://via.placeholder.com/200x400?text=Login+UI" width="22%" />
  <img src="https://via.placeholder.com/200x400?text=Home+UI" width="22%" />
  <img src="https://via.placeholder.com/200x400?text=Chat+UI" width="22%" />
  <img src="https://via.placeholder.com/200x400?text=Profile+UI" width="22%" />
</p>

---

## ✨ Key Features

### 🩸 Smart Blood Requests
- **Location-Based Alerts**: বিভাগ, জেলা এবং থানা অনুযায়ী নোটিফিকেশন সিস্টেম।
- **Urgent Filtering**: রক্তের গ্রুপ এবং এরিয়া অনুযায়ী দ্রুত ডোনার খুঁজে পাওয়ার সুবিধা।
- **Real-time Updates**: আবেদনের বর্তমান অবস্থা (পেন্ডিং, একসেপ্টেড, কমপ্লিটেড) সাথে সাথে দেখা যায়।

### 🏅 Gamification & Donor Ranks
ডোনারদের উৎসাহিত করতে আমরা একটি ডায়নামিক র‍্যাঙ্কিং সিস্টেম ব্যবহার করি:
- 🌱 **Newbie**: ০ টি রক্তদান।
- 🥉 **Bronze**: ১ টি রক্তদান।
- 🥈 **Silver**: ৫ টি রক্তদান।
- 🥇 **Gold**: ১৫ টি রক্তদান।
- 💎 **Platinum**: ৩০ টি রক্তদান।
- 👑 **Diamond**: ৫০ টি রক্তদান।

### 💬 Seamless Communication
- **In-App Chat**: ডোনার এবং রোগীর পরিবারের মধ্যে সরাসরি এবং নিরাপদ কথা বলার সুযোগ।
- **Push Notifications**: নতুন মেসেজ বা ব্লাড রিকোয়েস্টের জন্য ইনস্ট্যান্ট অ্যালার্ট।

### 📄 Professional Reporting
- **PDF Report**: আপনার করা সমস্ত রক্তদান এবং গ্রহণের হিস্ট্রি প্রফেশনাল PDF আকারে ডাউনলোড করার সুবিধা।
- **Bengali Typography**: যুক্তবর্ণ এবং বাংলা ফন্ট সম্বলিত নিখুঁত বাংলা রিপোর্ট জেনারেশন।

---

## 🛠️ Tech Stack & Architecture

এই অ্যাপটি আধুনিক **Clean Architecture** অনুসরণ করে তৈরি করা হয়েছে যা মেইনটেইন করা এবং স্কেল করা সহজ।

- **State Management**: [Riverpod](https://riverpod.dev/) (Scalable and testable state management)
- **Database**: [Firebase Firestore](https://firebase.google.com/docs/firestore) (Real-time NoSQL)
- **Authentication**: Firebase Auth (Phone & Email)
- **Typography**: Google Fonts (Noto Sans Bengali)
- **Design Pattern**: Feature-driven Folder Structure

### 📂 Project Structure
```text
lib/
├── core/             # থিম, রাউটিং, ইউটিলস এবং গ্লোবাল সার্ভিসেস
├── data/             # মডেলস এবং ডাটা সোর্স (Firebase implementation)
├── domain/           # বিজনেস লজিক এবং রিপোজিটরি ইন্টারফেস
└── presentation/     # UI স্ক্রিন এবং রিভারপড প্রোভাইডার
```

---

## 🚀 Installation & Setup

১. আপনার কম্পিউটারে রিপোজিটরি ক্লোন করুন:
   ```bash
   git clone https://github.com/shahanuralamofficial/blood_donate.git
   ```

২. প্রয়োজনীয় প্যাকেজগুলো ইনস্টল করুন:
   ```bash
   flutter pub get
   ```

৩. ফায়ারবেস কনফিগারেশন:
   - [Firebase Console](https://console.firebase.google.com/) থেকে একটি নতুন প্রজেক্ট তৈরি করুন।
   - `google-services.json` ফাইলটি `android/app/` ফোল্ডারে রাখুন।

৪. অ্যাপটি রান করুন:
   ```bash
   flutter run
   ```

---

## 🎯 Upcoming Features (Roadmap)
- [ ] গুগল ম্যাপ ইন্টিগ্রেশন (কাছের ডোনারদের ম্যাপে দেখা)।
- [ ] ডার্ক মোড সাপোর্ট।
- [ ] ডোনার রিভিউ এবং রেটিং সিস্টেমের আরও উন্নত ফিল্টারিং।
- [ ] স্বেচ্ছাসেবী সংগঠনগুলোর জন্য আলাদা ড্যাশবোর্ড।

---

## 📄 License
এই প্রজেক্টটি MIT লাইসেন্সের অধীনে প্রকাশিত। বিস্তারিত জানতে [LICENSE](LICENSE) ফাইলটি দেখুন।

## 🤝 Contribution
আপনি যদি এই প্রজেক্টে অবদান রাখতে চান, তবে নির্দ্বিধায় **Pull Request** পাঠান অথবা **Issues** সেকশনে আপনার মতামত জানান।

---
<p align="center">
  <b>Developed with ❤️ for the Community.</b><br>
  <i>"রক্ত দিন, জীবন বাঁচান"</i>
</p>
