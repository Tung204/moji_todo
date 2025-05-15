<p align="center">
  <a href="https://github.com/Tung204/dntu_focus">
    <img src="assets/images/logo_moji.png" width="100">
  </a>
</p>

<p align="center">
<a href="https://github.com/Tung204/dntu_focus">
<img alt="Awesome" src="https://cdn.rawgit.com/sindresorhus/awesome/d7305f38d29fed78fa85652e3a63e154dd8e8829/media/badge.svg" />
</a>
<a href="https://github.com/Tung204/dntu_focus/blob/main/LICENSE">
<img alt="Giấy phép: MIT" src="https://img.shields.io/badge/License-MIT-yellow.svg" />
</a>
</p>

[DNTU-Focus](https://github.com/Tung204/dntu_focus) là một ứng dụng di động được xây dựng bằng [Flutter](https://flutter.dev/) để nâng cao năng suất học tập của sinh viên thông qua kỹ thuật [Pomodoro](https://en.wikipedia.org/wiki/Pomodoro_Technique), tích hợp ChatBot AI. Được phát triển bởi sinh viên [Đại học Công nghệ Đồng Nai (DNTU)](https://dntu.edu.vn/), ứng dụng cung cấp quản lý công việc, thông báo, và môi trường học tập không bị phân tâm.
Nếu bạn yêu thích dự án 📱, hãy ủng hộ bằng cách 👍 | ⭐ | 👏 trên [GitHub](https://github.com/Tung204/dntu_focus)!
<p align="center">
  Được phát triển như một dự án nghiên cứu tại Đại học Công nghệ Đồng Nai, DNTU-Focus kết hợp các công nghệ hiện đại để cung cấp công cụ học tập thông minh cho sinh viên.
</p>

## Nhóm dự án

- [Nguyễn Sơn Tùng](https://github.com/Tung204) – Chủ nhiệm dự án  
- [Võ Văn Tín](https://github.com/TINVO04) – Nhà phát triển

## Trình diễn

<div style="text-align: center"><table><tr>
<td style="text-align: center; width: 180">
<a href="https://github.com/Tung204/dntu_focus">
Bộ đếm Pomodoro
</a>
Chu kỳ làm việc/nghỉ tùy chỉnh với Chế độ nghiêm ngặt và Âm thanh nền.
</td>
<td style="text-align: center; width: 180">
<a href="https://github.com/Tung204/dntu_focus">
ChatBot AI
</a>
Quản lý công việc và lịch học bằng lệnh ngôn ngữ tự nhiên qua văn bản/giọng nói.
</td>
<td style="text-align: center; width: 180">
<a href="https://github.com/Tung204/dntu_focus">
Quản lý công việc
</a>
Sắp xếp công việc với dự án và thẻ, đồng bộ qua Firestore.
</td>
</tr></table></div>

## Mục lục

- [Tổng quan](#tổng-quan)
- [Tính năng](#tính-năng)
- [Hướng dẫn sử dụng](#hướng-dẫn-sử-dụng)
- [Thành phần](#thành-phần)
- [Cài đặt](#cài-đặt)
- [Kiến trúc](#kiến-trúc)
- [Đóng góp](#đóng-góp)
- [Giấy phép](#giấy-phép)
- [Liên hệ](#liên-hệ)

## Tổng quan

**DNTU-Focus** là ứng dụng năng suất giúp sinh viên quản lý thời gian và công việc hiệu quả. Được xây dựng bằng [Flutter](https://flutter.dev/), ứng dụng áp dụng kỹ thuật [Pomodoro](https://en.wikipedia.org/wiki/Pomodoro_Technique) để tăng cường tập trung, tích hợp các tính năng như Chế độ nghiêm ngặt, Âm thanh nền, và ChatBot AI sử dụng [Gemini Service](https://ai.google.dev/). Dữ liệu được đồng bộ với [Firebase Firestore](https://firebase.google.com/products/firestore) và lưu cục bộ bằng [Hive](https://pub.dev/packages/hive), đảm bảo truy cập cả khi online và offline.

## Tính năng

- **Bộ đếm Pomodoro** [🔗](https://en.wikipedia.org/wiki/Pomodoro_Technique): Chu kỳ làm việc/nghỉ tùy chỉnh (mặc định: 25/5 phút).
    - **Chế độ nghiêm ngặt**: Chặn ứng dụng gây phân tâm, yêu cầu lật điện thoại, hoặc ngăn thoát ứng dụng.
    - **Âm thanh nền**: Âm thanh môi trường (ví dụ: mưa, quán cà phê) để tăng tập trung.
    - **Chuyển tự động**: Chuyển đổi tự động giữa làm việc và nghỉ.
- **Quản lý công việc** [🔗](https://github.com/Tung204/dntu_focus/tree/main/lib/features/tasks): Sắp xếp công việc với dự án và thẻ, đồng bộ qua Firestore.
- **ChatBot AI** [🔗](https://ai.google.dev/): Lệnh ngôn ngữ tự nhiên (ví dụ: "Học toán 25 phút") với đầu vào văn bản/giọng nói sử dụng [speech_to_text](https://pub.dev/packages/speech_to_text).
- **Chế độ tối**: Giao diện thân thiện với mắt, đồng bộ trên mọi màn hình.
- **Thông báo** [🔗](https://firebase.google.com/products/cloud-messaging): Nhắc nhở công việc và lịch học qua Firebase Messaging.
- **Lịch biểu**: Hiển thị công việc và lịch học trực quan.

## Hướng dẫn sử dụng

### Bắt đầu
- **Thiết lập phiên Pomodoro**:
    - Mở `HomeScreen` và nhấn "Bắt đầu tập trung" để khởi động phiên 25 phút.
    - Tùy chỉnh thời gian trong `TimerModeMenu` (ví dụ: 30 phút làm, 10 phút nghỉ).
- **Sử dụng Chế độ nghiêm ngặt** [🔗](https://github.com/Tung204/dntu_focus/tree/main/lib/features/home/presentation/strict_mode_menu.dart):
    - Bật qua `StrictModeMenu` để chặn ứng dụng hoặc áp dụng quy tắc tập trung.
- **Âm thanh nền** [🔗](https://github.com/Tung204/dntu_focus/tree/main/lib/features/home/presentation/white_noise_menu.dart):
    - Chọn âm thanh môi trường (ví dụ: "Mưa") trong `WhiteNoiseMenu`.

### Quản lý công việc
- **Thêm công việc** [🔗](https://github.com/Tung204/dntu_focus/tree/main/lib/features/tasks):
    - Sử dụng `TaskManageScreen` để tạo công việc với dự án và thẻ.
    - Xem trong `CalendarScreen` hoặc `TaskListScreen`.
- **Đồng bộ dữ liệu**:
    - Công việc được đồng bộ lên Firestore mỗi 15 phút (xem `BackupService` [🔗](https://github.com/Tung204/dntu_focus/tree/main/lib/core/services/backup_service.dart)).

### ChatBot AI
- **Tương tác với ChatBot** [🔗](https://github.com/Tung204/dntu_focus/tree/main/lib/features/ai_chat):
    - Mở `AIChatScreen` và sử dụng lệnh văn bản/giọng nói (ví dụ: "Lên lịch ôn thi ngày mai").
    - Nhận thông báo cho công việc đã lên lịch.

## Thành phần

### Giao diện
- **CustomAppBar** [🔗](https://github.com/Tung204/dntu_focus/blob/main/lib/core/widgets/custom_app_bar.dart) [⭐]: Thanh ứng dụng responsive với tiêu đề gradient và cài đặt.
- **CustomButton** [🔗](https://github.com/Tung204/dntu_focus/blob/main/lib/core/widgets/custom_button.dart) [⭐]: Nút động với hiệu ứng gradient tùy chọn.
- **CustomBottomNavBar** [🔗](https://github.com/Tung204/dntu_focus/blob/main/lib/core/widgets/custom_bottom_nav_bar.dart) [⭐]: Thanh điều hướng động cho chuyển đổi màn hình mượt mà.

### Widget
- **PomodoroTimer** [🔗](https://github.com/Tung204/dntu_focus/blob/main/lib/features/home/presentation/widgets/pomodoro_timer.dart) [⭐]: Bộ đếm chính với Chế độ nghiêm ngặt và Chuyển tự động.
- **WhiteNoiseMenu** [🔗](https://github.com/Tung204/dntu_focus/blob/main/lib/features/home/presentation/white_noise_menu.dart) [⭐]: Bộ chọn âm thanh môi trường để tập trung.
- **TaskCard** [🔗](https://github.com/Tung204/dntu_focus/blob/main/lib/features/home/presentation/widgets/task_card.dart) [⭐]: Hiển thị công việc với hỗ trợ dự án/thẻ.

## Cài đặt

### Điều kiện tiên quyết
- **Flutter** [🔗](https://flutter.dev/docs/get-started/install): Phiên bản 3.10.0 trở lên.
- **Dart** [🔗](https://dart.dev/): Phiên bản 3.0.0 trở lên.
- **IDE**: [Android Studio](https://developer.android.com/studio) hoặc [VS Code](https://code.visualstudio.com/).
- **Firebase CLI** [🔗](https://firebase.google.com/docs/cli): Để cài đặt Firestore/Messaging.
- **File .env**: Thêm khóa API (ví dụ: Gemini) vào thư mục gốc:
  ```
  GEMINI_API_KEY=your_api_key
  ```

### Các bước
1. **Sao chép kho mã nguồn**:
   ```bash
   git clone https://github.com/Tung204/dntu_focus.git
   cd dntu_focus
   ```

2. **Cài đặt phụ thuộc** [🔗](https://pub.dev/):
   ```bash
   flutter pub get
   ```

3. **Cấu hình Firebase** [🔗](https://firebase.google.com/docs/flutter/setup):
    - Tạo dự án Firebase trong [Firebase Console](https://console.firebase.google.com/).
    - Tải `google-services.json` (Android) hoặc `GoogleService-Info.plist` (iOS) và đặt vào `android/app/` hoặc `ios/Runner/`.
    - Chạy:
      ```bash
      flutterfire configure
      ```
    - Cập nhật quy tắc Firestore:
      ```firestore
      rules_version = '2';
      service cloud.firestore {
        match /databases/{database}/documents {
          match /tasks/{taskId} {
            allow read, write: if request.auth != null && request.auth.uid == resource.data.uid;
          }
          match /projects/{projectId} {
            allow read, write: if request.auth != null && request.auth.uid == resource.data.uid;
          }
          match /tags/{tagId} {
            allow read, write: if request.auth != null && request.auth.uid == resource.data.uid;
          }
        }
      }
      ```

4. **Chạy ứng dụng**:
   ```bash
   flutter run
   ```

## Kiến trúc

### Công nghệ
- **Giao diện**: [Flutter](https://flutter.dev/) với [Dart](https://dart.dev/), sử dụng [flutter_bloc](https://pub.dev/packages/flutter_bloc) để quản lý trạng thái và [provider](https://pub.dev/packages/provider) để chuyển đổi giao diện.
- **Hậu cần**: [Firebase Firestore](https://firebase.google.com/products/firestore) để đồng bộ, [Firebase Messaging](https://firebase.google.com/products/cloud-messaging) cho thông báo.
- **Lưu trữ cục bộ**: [Hive](https://pub.dev/packages/hive) cho dữ liệu offline.
- **AI**: [Gemini Service](https://ai.google.dev/) để xử lý ngôn ngữ tự nhiên.
- **Thư viện**: [google_fonts](https://pub.dev/packages/google_fonts), [speech_to_text](https://pub.dev/packages/speech_to_text), [flutter_dotenv](https://pub.dev/packages/flutter_dotenv) (xem [`pubspec.yaml`](pubspec.yaml)).

### Cấu trúc thư mục
```
lib/
├── core/
│   ├── services/        # BackupService, NotificationService
│   ├── themes/         # Theme, ThemeProvider
│   ├── widgets/        # CustomAppBar, CustomButton
├── features/
│   ├── home/           # HomeScreen, PomodoroTimer, WhiteNoiseMenu
│   ├── tasks/          # TaskManageScreen, TaskCubit
│   ├── ai_chat/        # AIChatScreen
│   ├── splash/         # SplashScreen
├── routes/             # AppRoutes
```

## Đóng góp

Chúng tôi hoan nghênh mọi đóng góp để cải thiện DNTU-Focus! Để đóng góp:

1. Fork kho mã nguồn [🔗](https://github.com/Tung204/dntu_focus).
2. Tạo nhánh tính năng:
   ```bash
   git checkout -b feature/your-feature
   ```
3. Commit thay đổi:
   ```bash
   git commit -m 'Thêm tính năng của bạn'
   ```
4. Đẩy lên nhánh:
   ```bash
   git push origin feature/your-feature
   ```
5. Mở Pull Request [🔗](https://github.com/Tung204/dntu_focus/pulls).

### Hướng dẫn
- Tuân theo [hướng dẫn phong cách Flutter](https://dart.dev/guides/language/effective-dart/style).
- Sử dụng `Theme.of(context)` cho giao diện để hỗ trợ Chế độ tối.
- Kiểm tra với [Firebase Emulator](https://firebase.google.com/docs/emulator-suite).
- Ghi chú thay đổi trong Pull Request.

## Giấy phép

Được cấp phép theo [Giấy phép MIT](LICENSE) [🔗](https://github.com/Tung204/dntu_focus/blob/main/LICENSE).

## Liên hệ

**GitHub**: [github.com/Tung204/dntu_focus](https://github.com/Tung204/dntu_focus)  
**Email**: [nst874@gmail.com](mailto:nst874@gmail.com), [tinvo.bh2018@gmail.com](mailto:tinvo.bh2018@gmail.com)

---

Phát triển với ❤️ bởi Sinh viên DNTU