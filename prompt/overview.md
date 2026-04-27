Tổng Quan Dự Án

1\. Thông Tin Dự Án



Tên ứng dụng: Money Manager



Platform: Flutter (Android)



IDE: Android Studio



Ngôn ngữ: Dart



Database: SQLite (Local) + Firebase Firestore (Cloud)



Authentication: Firebase Auth



2\. Kiến Trúc Ứng Dụng

Kiến Trúc Tổng Thể

money\_manager/

├── lib/

│   ├── main.dart

│   ├── app.dart

│   ├── core/

│   │   ├── constants/

│   │   ├── theme/

│   │   ├── utils/

│   │   └── routes/

│   ├── data/

│   │   ├── models/

│   │   ├── repositories/

│   │   └── services/

│   ├── domain/

│   │   ├── entities/

│   │   └── usecases/

│   └── presentation/

│       ├── screens/

│       ├── widgets/

│       └── providers/

├── assets/

│   ├── images/

│   ├── icons/

│   └── fonts/

└── test/



3\. Design Pattern



Clean Architecture



Provider/Riverpod (State management)



Repository Pattern



MVVM



4\. Tech Stack

dependencies:

&nbsp; flutter:

&nbsp;   sdk: flutter



&nbsp; # State Management

&nbsp; provider: ^6.1.1



&nbsp; # Local Database

&nbsp; sqflite: ^2.3.0

&nbsp; path\_provider: ^2.1.1



&nbsp; # Firebase

&nbsp; firebase\_core: ^2.24.2

&nbsp; firebase\_auth: ^4.15.3

&nbsp; google\_sign\_in: ^6.1.6

&nbsp; cloud\_firestore: ^4.13.6

&nbsp; firebase\_storage: ^11.5.6

&nbsp; firebase\_messaging: ^14.7.9



&nbsp; # Security

&nbsp; flutter\_secure\_storage: ^9.0.0

&nbsp; local\_auth: ^2.1.7



&nbsp; # Charts

&nbsp; fl\_chart: ^0.65.0



&nbsp; # Notifications

&nbsp; flutter\_local\_notifications: ^16.3.0



&nbsp; # UI

&nbsp; intl: ^0.18.1

&nbsp; flutter\_slidable: ^3.0.1

&nbsp; shimmer: ^3.0.0



&nbsp; # Utilities

&nbsp; uuid: ^4.2.2

&nbsp; shared\_preferences: ^2.2.2

