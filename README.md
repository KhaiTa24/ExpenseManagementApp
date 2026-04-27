# 💰 Money Manager - Ứng Dụng Quản Lý Chi Tiêu Cá Nhân

<div align="center">
  <img src="https://img.shields.io/badge/Flutter-3.0+-02569B?style=for-the-badge&logo=flutter&logoColor=white" />
  <img src="https://img.shields.io/badge/Dart-3.0+-0175C2?style=for-the-badge&logo=dart&logoColor=white" />
  <img src="https://img.shields.io/badge/Firebase-FFCA28?style=for-the-badge&logo=firebase&logoColor=black" />
  <img src="https://img.shields.io/badge/License-MIT-green?style=for-the-badge" />
</div>

## 📱 Giới Thiệu

Money Manager là ứng dụng quản lý chi tiêu cá nhân được xây dựng bằng Flutter, giúp bạn theo dõi thu chi, lập ngân sách, và phân tích tài chính một cách dễ dàng và hiệu quả.

### ✨ Tính Năng Chính

- 🔐 **Xác thực đa dạng**: Email/Password, Google Sign-In, Biometric
- 💸 **Quản lý giao dịch**: Thêm, sửa, xóa thu chi với đầy đủ thông tin
- 📊 **Báo cáo & Phân tích**: Biểu đồ tròn, phân tích theo danh mục
- 💰 **Quản lý ngân sách**: Theo dõi và cảnh báo ngân sách
- 🏷️ **Danh mục tùy chỉnh**: 12 danh mục mặc định + tạo thêm
- 🔄 **Đồng bộ Cloud**: Tự động sync với Firebase
- 📴 **Offline-first**: Hoạt động ngay cả khi không có mạng
- 🌙 **Dark Mode**: Giao diện sáng/tối
- 🇻🇳 **Tiếng Việt**: Hoàn toàn bằng tiếng Việt

## 🏗️ Kiến Trúc

Dự án được xây dựng theo **Clean Architecture** với các layer:

```
lib/
├── core/                 # Core utilities, constants, themes
├── data/                 # Data sources & repositories implementation
│   ├── datasources/      # Local (SQLite) & Remote (Firebase)
│   ├── models/           # Data models
│   └── repositories/     # Repository implementations
├── domain/               # Business logic
│   ├── entities/         # Domain entities
│   ├── repositories/     # Repository interfaces
│   └── usecases/         # Business use cases
└── presentation/         # UI Layer
    ├── providers/        # State management (Provider)
    ├── screens/          # App screens
    └── widgets/          # Reusable widgets
```

### 🎯 Design Patterns

- **Clean Architecture**: Separation of concerns
- **Repository Pattern**: Data abstraction
- **Provider Pattern**: State management
- **Dependency Injection**: get_it
- **MVVM**: Model-View-ViewModel

## 🚀 Bắt Đầu

### Yêu Cầu

- Flutter SDK: >= 3.0.0
- Dart SDK: >= 3.0.0
- Android Studio / VS Code
- Firebase Account

### Cài Đặt

1. **Clone repository**
```bash
git clone https://github.com/yourusername/money_manager.git
cd money_manager
```

2. **Install dependencies**
```bash
flutter pub get
```

3. **Cấu hình Firebase**
   
   📖 Xem hướng dẫn chi tiết tại: **[FIREBASE_SETUP_GUIDE.md](FIREBASE_SETUP_GUIDE.md)**

4. **Run app**
```bash
# Android
flutter run

# iOS
flutter run -d ios
```

## 📦 Dependencies

### Core
- `provider: ^6.1.1` - State management
- `get_it: ^7.6.4` - Dependency injection

### Database
- `sqflite: ^2.3.0` - Local database
- `path_provider: ^2.1.1` - File paths

### Firebase
- `firebase_core: ^2.24.2`
- `firebase_auth: ^4.15.3`
- `cloud_firestore: ^4.13.6`
- `firebase_storage: ^11.5.6`
- `google_sign_in: ^6.1.6`

### Security
- `flutter_secure_storage: ^9.0.0`
- `local_auth: ^2.1.7`

### UI/UX
- `fl_chart: ^0.65.0` - Charts
- `intl: ^0.18.1` - Internationalization

### Utilities
- `uuid: ^4.2.2`
- `shared_preferences: ^2.2.2`
- `timezone: ^0.9.2`

## 📱 Screens

### ✅ Đã Hoàn Thành (8 screens)

1. **Splash Screen** - Màn hình khởi động
2. **Login Screen** - Đăng nhập Email/Google
3. **Register Screen** - Đăng ký tài khoản
4. **Home Screen** - Dashboard với balance, quick actions, recent transactions
5. **Add Transaction Screen** - Thêm giao dịch thu/chi
6. **Transaction List Screen** - Danh sách giao dịch, filter, group by date
7. **Report Screen** - Báo cáo với pie chart, category analysis
8. **Settings Screen** - Cài đặt, dark mode, logout

## 🗂️ Database Schema

### SQLite Tables
- `users` - User information
- `categories` - Income/Expense categories
- `transactions` - All transactions
- `budgets` - Budget tracking
- `wallets` - Multiple wallets
- `recurring_transactions` - Recurring transactions
- `settings` - App settings

### Firestore Collections
- `users` - User profiles
- `categories` - Synced categories
- `transactions` - Synced transactions
- `budgets` - Synced budgets

## 🔒 Security

- Firebase Authentication
- Secure Storage for sensitive data
- Biometric authentication support
- PIN code protection (ready)
- Firestore Security Rules
- Storage Security Rules

## 📝 Business Rules

### Transaction
- Minimum amount: 1,000 VND
- Maximum amount: 999,999,999,999 VND
- Date: Cannot be in the future
- Description: Max 200 characters

### Category
- Name: 2-50 characters
- Maximum: 50 categories per user
- No duplicate names in same type

### Budget
- Minimum: 10,000 VND
- Maximum: 999,999,999 VND
- Alert thresholds: 80% (warning), 100% (danger)

### Password
- Minimum: 8 characters
- Must contain: uppercase, lowercase, number, special character

## 📊 Project Status

### ✅ Hoàn Thành (100%)

- **Core Layer**: 17 files
- **Data Layer**: 25 files
- **Domain Layer**: 50+ files
- **Presentation Layer**: 40+ files

**Tổng cộng: 140+ files - Không có lỗi compile!**

### 🎯 Tính Năng

- ✅ Authentication (Email, Google Sign-In)
- ✅ Transaction Management (CRUD)
- ✅ Category Management (12 default categories)
- ✅ Budget Management & Alerts
- ✅ Reports & Analytics (Pie charts)
- ✅ Cloud Sync (Firebase)
- ✅ Dark Mode
- ✅ Offline-first Architecture
- ✅ Dependency Injection
- ✅ State Management
- ✅ Error Handling
- ✅ Validation Layer

## 🚀 Quick Start

```bash
# 1. Install dependencies
flutter pub get

# 2. Setup Firebase (see FIREBASE_SETUP_GUIDE.md)

# 3. Run app
flutter run
```

## 📖 Documentation

- 📘 [Firebase Setup Guide](FIREBASE_SETUP_GUIDE.md) - Hướng dẫn cấu hình Firebase chi tiết
- 📗 [Project Structure](PROJECT_STRUCTURE.md) - Cấu trúc dự án
- 📙 [API Documentation](prompt/api_documentation.md) - Firebase API docs
- 📕 [Business Rules](prompt/business_rules.md) - Quy tắc nghiệp vụ

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## 📄 License

This project is licensed under the MIT License.

## 👨‍💻 Author

**Your Name**
- GitHub: [@yourusername](https://github.com/yourusername)
- Email: your.email@example.com

## 🙏 Acknowledgments

- Flutter Team for the amazing framework
- Firebase for backend services
- Material Design for UI guidelines
- All open-source contributors

---

<div align="center">
  Made with ❤️ using Flutter
</div>
