\# API \& Services Documentation



\## Firebase Configuration



\### 1. Firebase Project Setup



\*\*Project Name\*\*: MoneyManager



\*\*Services Enabled\*\*:

\- Authentication

\- Cloud Firestore

\- Cloud Storage

\- Cloud Messaging

\- Analytics (optional)



\### 2. Firebase Config Files



\*\*Android\*\*: `android/app/google-services.json`



```json

{

&nbsp; "project\_info": {

&nbsp;   "project\_id": "money-manager-xxxxx",

&nbsp;   "project\_number": "123456789012",

&nbsp;   "storage\_bucket": "money-manager-xxxxx.appspot.com"

&nbsp; }

}

```



\*\*iOS\*\*: `ios/Runner/GoogleService-Info.plist` (if supporting iOS later)



\### 3. Environment Variables



Create `.env` file:

```env

FIREBASE\_API\_KEY=your\_api\_key

FIREBASE\_APP\_ID=your\_app\_id

FIREBASE\_MESSAGING\_SENDER\_ID=your\_sender\_id

FIREBASE\_PROJECT\_ID=money-manager-xxxxx

```



---



\## Authentication Service



\### Firebase Auth Methods



\#### 1. Email/Password Authentication



\*\*Sign Up\*\*

```dart

Future<UserCredential> signUp({

&nbsp; required String email,

&nbsp; required String password,

&nbsp; required String displayName,

}) async {

&nbsp; UserCredential credential = await FirebaseAuth.instance

&nbsp;     .createUserWithEmailAndPassword(

&nbsp;       email: email,

&nbsp;       password: password,

&nbsp;     );

&nbsp; 

&nbsp; await credential.user?.updateDisplayName(displayName);

&nbsp; return credential;

}

```



\*\*Sign In\*\*

```dart

Future<UserCredential> signIn({

&nbsp; required String email,

&nbsp; required String password,

}) async {

&nbsp; return await FirebaseAuth.instance.signInWithEmailAndPassword(

&nbsp;   email: email,

&nbsp;   password: password,

&nbsp; );

}

```



\*\*Sign Out\*\*

```dart

Future<void> signOut() async {

&nbsp; await FirebaseAuth.instance.signOut();

}

```



\*\*Password Reset\*\*

```dart

Future<void> resetPassword(String email) async {

&nbsp; await FirebaseAuth.instance.sendPasswordResetEmail(email: email);

}

```



\#### 2. Google Sign-In



```dart

Future<UserCredential> signInWithGoogle() async {

&nbsp; final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

&nbsp; final GoogleSignInAuthentication googleAuth = 

&nbsp;     await googleUser!.authentication;

&nbsp; 

&nbsp; final credential = GoogleAuthProvider.credential(

&nbsp;   accessToken: googleAuth.accessToken,

&nbsp;   idToken: googleAuth.idToken,

&nbsp; );

&nbsp; 

&nbsp; return await FirebaseAuth.instance.signInWithCredential(credential);

}

```



\#### 3. Auth State Listener



```dart

Stream<User?> get authStateChanges => 

&nbsp;   FirebaseAuth.instance.authStateChanges();

```



---



\## Cloud Firestore Structure



\### Collections \& Documents



```

users/

├── {userId}/

│   ├── email: string

│   ├── displayName: string

│   ├── createdAt: timestamp

│   └── lastSyncAt: timestamp

│

│   └── categories/ (subcollection)

│       └── {categoryId}/

│           ├── name: string

│           ├── icon: string

│           ├── color: string

│           ├── type: string ('income' | 'expense')

│           ├── isDefault: boolean

│           └── createdAt: timestamp

│

│   └── transactions/ (subcollection)

│       └── {transactionId}/

│           ├── categoryId: string

│           ├── amount: number

│           ├── type: string ('income' | 'expense')

│           ├── description: string

│           ├── date: timestamp

│           ├── createdAt: timestamp

│           └── updatedAt: timestamp

│

│   └── budgets/ (subcollection)

│       └── {budgetId}/

│           ├── categoryId: string

│           ├── amount: number

│           ├── period: string ('monthly' | 'yearly')

│           ├── month: number (1-12)

│           ├── year: number (2024)

│           └── createdAt: timestamp

│

│   └── settings/ (subcollection)

│       └── preferences/

│           ├── currency: string

│           ├── language: string

│           ├── theme: string ('light' | 'dark')

│           ├── notifications: map

│           │   ├── dailyReminder: boolean

│           │   ├── budgetAlerts: boolean

│           │   └── reminderTime: string ('20:00')

│           ├── security: map

│           │   ├── pinEnabled: boolean

│           │   └── biometricEnabled: boolean

│           └── updatedAt: timestamp

```



\### Firestore Rules



```javascript

rules\_version = '2';

service cloud.firestore {

&nbsp; match /databases/{database}/documents {

&nbsp;   

&nbsp;   // Helper functions

&nbsp;   function isAuthenticated() {

&nbsp;     return request.auth != null;

&nbsp;   }

&nbsp;   

&nbsp;   function isOwner(userId) {

&nbsp;     return request.auth.uid == userId;

&nbsp;   }

&nbsp;   

&nbsp;   // Users collection

&nbsp;   match /users/{userId} {

&nbsp;     allow read, write: if isAuthenticated() \&\& isOwner(userId);

&nbsp;     

&nbsp;     // Categories subcollection

&nbsp;     match /categories/{categoryId} {

&nbsp;       allow read, write: if isAuthenticated() \&\& isOwner(userId);

&nbsp;     }

&nbsp;     

&nbsp;     // Transactions subcollection

&nbsp;     match /transactions/{transactionId} {

&nbsp;       allow read, write: if isAuthenticated() \&\& isOwner(userId);

&nbsp;     }

&nbsp;     

&nbsp;     // Budgets subcollection

&nbsp;     match /budgets/{budgetId} {

&nbsp;       allow read, write: if isAuthenticated() \&\& isOwner(userId);

&nbsp;     }

&nbsp;     

&nbsp;     // Settings subcollection

&nbsp;     match /settings/{document=\*\*} {

&nbsp;       allow read, write: if isAuthenticated() \&\& isOwner(userId);

&nbsp;     }

&nbsp;   }

&nbsp; }

}

```



\### Firestore Indexes



\*\*Required Composite Indexes\*\*:



1\. \*\*Transactions by date\*\*

```

Collection: users/{userId}/transactions

Fields: date (Descending), createdAt (Descending)

```



2\. \*\*Transactions by category and date\*\*

```

Collection: users/{userId}/transactions

Fields: categoryId (Ascending), date (Descending)

```



3\. \*\*Budgets by period\*\*

```

Collection: users/{userId}/budgets

Fields: year (Ascending), month (Ascending)

```



---



\## Firestore Service Methods



\### Transaction Service



```dart

class TransactionService {

&nbsp; final FirebaseFirestore \_firestore = FirebaseFirestore.instance;

&nbsp; 

&nbsp; // Create transaction

&nbsp; Future<void> addTransaction(String userId, Transaction transaction) async {

&nbsp;   await \_firestore

&nbsp;       .collection('users')

&nbsp;       .doc(userId)

&nbsp;       .collection('transactions')

&nbsp;       .doc(transaction.id)

&nbsp;       .set(transaction.toJson());

&nbsp; }

&nbsp; 

&nbsp; // Get transactions

&nbsp; Stream<List<Transaction>> getTransactions(

&nbsp;   String userId, {

&nbsp;   DateTime? startDate,

&nbsp;   DateTime? endDate,

&nbsp;   String? categoryId,

&nbsp; }) {

&nbsp;   Query query = \_firestore

&nbsp;       .collection('users')

&nbsp;       .doc(userId)

&nbsp;       .collection('transactions')

&nbsp;       .orderBy('date', descending: true);

&nbsp;   

&nbsp;   if (startDate != null) {

&nbsp;     query = query.where('date', isGreaterThanOrEqualTo: startDate);

&nbsp;   }

&nbsp;   if (endDate != null) {

&nbsp;     query = query.where('date', isLessThanOrEqualTo: endDate);

&nbsp;   }

&nbsp;   if (categoryId != null) {

&nbsp;     query = query.where('categoryId', isEqualTo: categoryId);

&nbsp;   }

&nbsp;   

&nbsp;   return query.snapshots().map((snapshot) =>

&nbsp;       snapshot.docs.map((doc) => Transaction.fromJson(doc.data())).toList());

&nbsp; }

&nbsp; 

&nbsp; // Update transaction

&nbsp; Future<void> updateTransaction(

&nbsp;   String userId,

&nbsp;   String transactionId,

&nbsp;   Map<String, dynamic> updates,

&nbsp; ) async {

&nbsp;   updates\['updatedAt'] = FieldValue.serverTimestamp();

&nbsp;   await \_firestore

&nbsp;       .collection('users')

&nbsp;       .doc(userId)

&nbsp;       .collection('transactions')

&nbsp;       .doc(transactionId)

&nbsp;       .update(updates);

&nbsp; }

&nbsp; 

&nbsp; // Delete transaction

&nbsp; Future<void> deleteTransaction(String userId, String transactionId) async {

&nbsp;   await \_firestore

&nbsp;       .collection('users')

&nbsp;       .doc(userId)

&nbsp;       .collection('transactions')

&nbsp;       .doc(transactionId)

&nbsp;       .delete();

&nbsp; }

}

```



\### Category Service



```dart

class CategoryService {

&nbsp; final FirebaseFirestore \_firestore = FirebaseFirestore.instance;

&nbsp; 

&nbsp; // Initialize default categories for new user

&nbsp; Future<void> initializeDefaultCategories(String userId) async {

&nbsp;   final batch = \_firestore.batch();

&nbsp;   

&nbsp;   for (var category in DefaultCategories.getAll()) {

&nbsp;     final docRef = \_firestore

&nbsp;         .collection('users')

&nbsp;         .doc(userId)

&nbsp;         .collection('categories')

&nbsp;         .doc(category.id);

&nbsp;     batch.set(docRef, category.toJson());

&nbsp;   }

&nbsp;   

&nbsp;   await batch.commit();

&nbsp; }

&nbsp; 

&nbsp; // Get categories

&nbsp; Stream<List<Category>> getCategories(String userId, {String? type}) {

&nbsp;   Query query = \_firestore

&nbsp;       .collection('users')

&nbsp;       .doc(userId)

&nbsp;       .collection('categories');

&nbsp;   

&nbsp;   if (type != null) {

&nbsp;     query = query.where('type', isEqualTo: type);

&nbsp;   }

&nbsp;   

&nbsp;   return query.snapshots().map((snapshot) =>

&nbsp;       snapshot.docs.map((doc) => Category.fromJson(doc.data())).toList());

&nbsp; }

&nbsp; 

&nbsp; // Add custom category

&nbsp; Future<void> addCategory(String userId, Category category) async {

&nbsp;   await \_firestore

&nbsp;       .collection('users')

&nbsp;       .doc(userId)

&nbsp;       .collection('categories')

&nbsp;       .doc(category.id)

&nbsp;       .set(category.toJson());

&nbsp; }

}

```



\### Budget Service



```dart

class BudgetService {

&nbsp; final FirebaseFirestore \_firestore = FirebaseFirestore.instance;

&nbsp; 

&nbsp; // Create budget

&nbsp; Future<void> createBudget(String userId, Budget budget) async {

&nbsp;   await \_firestore

&nbsp;       .collection('users')

&nbsp;       .doc(userId)

&nbsp;       .collection('budgets')

&nbsp;       .doc(budget.id)

&nbsp;       .set(budget.toJson());

&nbsp; }

&nbsp; 

&nbsp; // Get budgets for period

&nbsp; Stream<List<Budget>> getBudgets(

&nbsp;   String userId,

&nbsp;   String period,

&nbsp;   int month,

&nbsp;   int year,

&nbsp; ) {

&nbsp;   return \_firestore

&nbsp;       .collection('users')

&nbsp;       .doc(userId)

&nbsp;       .collection('budgets')

&nbsp;       .where('period', isEqualTo: period)

&nbsp;       .where('month', isEqualTo: month)

&nbsp;       .where('year', isEqualTo: year)

&nbsp;       .snapshots()

&nbsp;       .map((snapshot) =>

&nbsp;           snapshot.docs.map((doc) => Budget.fromJson(doc.data())).toList());

&nbsp; }

}

```



---



\## Cloud Storage Service



\### Backup Storage Structure



```

users/

└── {userId}/

&nbsp;   └── backups/

&nbsp;       ├── backup\_2024\_12\_06\_20\_00\_00.json

&nbsp;       ├── backup\_2024\_12\_05\_20\_00\_00.json

&nbsp;       └── ...

```



\### Storage Service Methods



```dart

class BackupService {

&nbsp; final FirebaseStorage \_storage = FirebaseStorage.instance;

&nbsp; final FirebaseFirestore \_firestore = FirebaseFirestore.instance;

&nbsp; 

&nbsp; // Create backup

&nbsp; Future<String> createBackup(String userId) async {

&nbsp;   // Gather all user data

&nbsp;   final userData = await \_gatherUserData(userId);

&nbsp;   

&nbsp;   // Convert to JSON

&nbsp;   final jsonData = jsonEncode(userData);

&nbsp;   

&nbsp;   // Create filename with timestamp

&nbsp;   final timestamp = DateTime.now().toIso8601String().replaceAll(':', '\_');

&nbsp;   final filename = 'backup\_$timestamp.json';

&nbsp;   

&nbsp;   // Upload to Firebase Storage

&nbsp;   final ref = \_storage.ref('users/$userId/backups/$filename');

&nbsp;   await ref.putString(jsonData);

&nbsp;   

&nbsp;   // Get download URL

&nbsp;   return await ref.getDownloadURL();

&nbsp; }

&nbsp; 

&nbsp; // Restore from backup

&nbsp; Future<void> restoreBackup(String userId, String backupUrl) async {

&nbsp;   // Download backup file

&nbsp;   final ref = \_storage.refFromURL(backupUrl);

&nbsp;   final data = await ref.getData();

&nbsp;   

&nbsp;   // Parse JSON

&nbsp;   final userData = jsonDecode(utf8.decode(data!));

&nbsp;   

&nbsp;   // Restore data to Firestore

&nbsp;   await \_restoreUserData(userId, userData);

&nbsp; }

&nbsp; 

&nbsp; // List available backups

&nbsp; Future<List<Map<String, dynamic>>> listBackups(String userId) async {

&nbsp;   final ref = \_storage.ref('users/$userId/backups');

&nbsp;   final result = await ref.listAll();

&nbsp;   

&nbsp;   final backups = <Map<String, dynamic>>\[];

&nbsp;   for (var item in result.items) {

&nbsp;     final metadata = await item.getMetadata();

&nbsp;     backups.add({

&nbsp;       'name': item.name,

&nbsp;       'url': await item.getDownloadURL(),

&nbsp;       'size': metadata.size,

&nbsp;       'createdAt': metadata.timeCreated,

&nbsp;     });

&nbsp;   }

&nbsp;   

&nbsp;   return backups;

&nbsp; }

}

```



---



\## Cloud Messaging (FCM)



\### Push Notification Setup



\*\*Android\*\*: Configure in `android/app/src/main/AndroidManifest.xml`



```xml

<meta-data

&nbsp;   android:name="com.google.firebase.messaging.default\_notification\_channel\_id"

&nbsp;   android:value="money\_manager\_channel" />

```



\### Notification Service



```dart

class NotificationService {

&nbsp; final FirebaseMessaging \_messaging = FirebaseMessaging.instance;

&nbsp; final FlutterLocalNotificationsPlugin \_localNotifications =

&nbsp;     FlutterLocalNotificationsPlugin();

&nbsp; 

&nbsp; // Initialize notifications

&nbsp; Future<void> initialize() async {

&nbsp;   // Request permission

&nbsp;   await \_messaging.requestPermission(

&nbsp;     alert: true,

&nbsp;     badge: true,

&nbsp;     sound: true,

&nbsp;   );

&nbsp;   

&nbsp;   // Get FCM token

&nbsp;   final token = await \_messaging.getToken();

&nbsp;   print('FCM Token: $token');

&nbsp;   

&nbsp;   // Initialize local notifications

&nbsp;   const androidSettings = AndroidInitializationSettings('@mipmap/ic\_launcher');

&nbsp;   const iosSettings = DarwinInitializationSettings();

&nbsp;   const settings = InitializationSettings(

&nbsp;     android: androidSettings,

&nbsp;     iOS: iosSettings,

&nbsp;   );

&nbsp;   

&nbsp;   await \_localNotifications.initialize(settings);

&nbsp;   

&nbsp;   // Setup notification channels

&nbsp;   await \_setupNotificationChannels();

&nbsp;   

&nbsp;   // Handle foreground messages

&nbsp;   FirebaseMessaging.onMessage.listen(\_handleForegroundMessage);

&nbsp;   

&nbsp;   // Handle background messages

&nbsp;   FirebaseMessaging.onBackgroundMessage(\_handleBackgroundMessage);

&nbsp; }

&nbsp; 

&nbsp; // Schedule daily reminder

&nbsp; Future<void> scheduleDailyReminder(TimeOfDay time) async {

&nbsp;   await \_localNotifications.zonedSchedule(

&nbsp;     0,

&nbsp;     'Nhắc nhở ghi chép',

&nbsp;     'Đừng quên ghi chép chi tiêu hôm nay!',

&nbsp;     \_nextInstanceOfTime(time),

&nbsp;     const NotificationDetails(

&nbsp;       android: AndroidNotificationDetails(

&nbsp;         'daily\_reminder',

&nbsp;         'Nhắc nhở hằng ngày',

&nbsp;         importance: Importance.high,

&nbsp;       ),

&nbsp;     ),

&nbsp;     androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,

&nbsp;     uiLocalNotificationDateInterpretation:

&nbsp;         UILocalNotificationDateInterpretation.absoluteTime,

&nbsp;     matchDateTimeComponents: DateTimeComponents.time,

&nbsp;   );

&nbsp; }

&nbsp; 

&nbsp; // Show budget alert

&nbsp; Future<void> showBudgetAlert(String categoryName, double percentage) async {

&nbsp;   String title;

&nbsp;   String body;

&nbsp;   

&nbsp;   if (percentage >= 100) {

&nbsp;     title = 'Vượt ngân sách!';

&nbsp;     body = 'Bạn đã chi vượt ngân sách $categoryName';

&nbsp;   } else if (percentage >= 80) {

&nbsp;     title = 'Cảnh báo ngân sách';

&nbsp;     body = 'Bạn đã chi ${percentage.toStringAsFixed(0)}% ngân sách $categoryName';

&nbsp;   } else {

&nbsp;     return;

&nbsp;   }

&nbsp;   

&nbsp;   await \_localNotifications.show(

&nbsp;     categoryName.hashCode,

&nbsp;     title,

&nbsp;     body,

&nbsp;     const NotificationDetails(

&nbsp;       android: AndroidNotificationDetails(

&nbsp;         'budget\_alerts',

&nbsp;         'Cảnh báo ngân sách',

&nbsp;         importance: Importance.high,

&nbsp;         priority: Priority.high,

&nbsp;       ),

&nbsp;     ),

&nbsp;   );

&nbsp; }

}

```



---



\## Data Sync Service



\### Sync Strategy



\*\*Two-way sync between SQLite (local) and Firestore (cloud)\*\*



```dart

class SyncService {

&nbsp; final FirebaseFirestore \_firestore = FirebaseFirestore.instance;

&nbsp; final DatabaseHelper \_localDb = DatabaseHelper.instance;

&nbsp; 

&nbsp; // Sync all data

&nbsp; Future<void> syncAll(String userId) async {

&nbsp;   await syncCategories(userId);

&nbsp;   await syncTransactions(userId);

&nbsp;   await syncBudgets(userId);

&nbsp;   await syncSettings(userId);

&nbsp; }

&nbsp; 

&nbsp; // Sync transactions (example)

&nbsp; Future<void> syncTransactions(String userId) async {

&nbsp;   // Get last sync timestamp

&nbsp;   final lastSync = await \_getLastSyncTime(userId, 'transactions');

&nbsp;   

&nbsp;   // 1. Push local changes to cloud

&nbsp;   final localChanges = await \_localDb.getTransactionsModifiedAfter(lastSync);

&nbsp;   for (var transaction in localChanges) {

&nbsp;     await \_firestore

&nbsp;         .collection('users/$userId/transactions')

&nbsp;         .doc(transaction.id)

&nbsp;         .set(transaction.toJson(), SetOptions(merge: true));

&nbsp;   }

&nbsp;   

&nbsp;   // 2. Pull cloud changes to local

&nbsp;   final cloudChanges = await \_firestore

&nbsp;       .collection('users/$userId/transactions')

&nbsp;       .where('updatedAt', isGreaterThan: lastSync)

&nbsp;       .get();

&nbsp;   

&nbsp;   for (var doc in cloudChanges.docs) {

&nbsp;     final transaction = Transaction.fromJson(doc.data());

&nbsp;     await \_localDb.insertOrUpdateTransaction(transaction);

&nbsp;   }

&nbsp;   

&nbsp;   // 3. Update last sync time

&nbsp;   await \_updateLastSyncTime(userId, 'transactions');

&nbsp; }

&nbsp; 

&nbsp; // Conflict resolution (last-write-wins)

&nbsp; Future<void> resolveConflict(Transaction local, Transaction cloud) async {

&nbsp;   if (cloud.updatedAt.isAfter(local.updatedAt)) {

&nbsp;     // Cloud version is newer, use it

&nbsp;     await \_localDb.insertOrUpdateTransaction(cloud);

&nbsp;   } else {

&nbsp;     // Local version is newer, push to cloud

&nbsp;     await \_firestore

&nbsp;         .collection('users/${local.userId}/transactions')

&nbsp;         .doc(local.id)

&nbsp;         .set(local.toJson());

&nbsp;   }

&nbsp; }

}

```



---



\## Error Handling



\### Error Codes



```dart

class FirebaseErrorHandler {

&nbsp; static String getErrorMessage(String errorCode) {

&nbsp;   switch (errorCode) {

&nbsp;     case 'user-not-found':

&nbsp;       return 'Không tìm thấy tài khoản';

&nbsp;     case 'wrong-password':

&nbsp;       return 'Mật khẩu không đúng';

&nbsp;     case 'email-already-in-use':

&nbsp;       return 'Email đã được sử dụng';

&nbsp;     case 'invalid-email':

&nbsp;       return 'Email không hợp lệ';

&nbsp;     case 'weak-password':

&nbsp;       return 'Mật khẩu quá yếu';

&nbsp;     case 'network-request-failed':

&nbsp;       return 'Lỗi kết nối mạng';

&nbsp;     case 'too-many-requests':

&nbsp;       return 'Quá nhiều yêu cầu, vui lòng thử lại sau';

&nbsp;     default:

&nbsp;       return 'Đã xảy ra lỗi, vui lòng thử lại';

&nbsp;   }

&nbsp; }

}

```



---



\## Rate Limiting \& Quotas



\### Firestore Quotas (Free Tier)

\- \*\*Reads\*\*: 50,000/day

\- \*\*Writes\*\*: 20,000/day

\- \*\*Deletes\*\*: 20,000/day

\- \*\*Storage\*\*: 1 GB



\### Optimization Strategies

1\. Cache frequently accessed data locally

2\. Use pagination for lists

3\. Batch writes when possible

4\. Implement exponential backoff for retries



---



\## Security Best Practices



1\. \*\*Never store sensitive data in plain text\*\*

&nbsp;  - Use Flutter Secure Storage for PIN, tokens

&nbsp;  

2\. \*\*Validate all inputs on client and server\*\*

&nbsp;  - Firestore rules provide server-side validation

&nbsp;  

3\. \*\*Use HTTPS only\*\*

&nbsp;  - Firebase handles this by default

&nbsp;  

4\. \*\*Implement proper authentication checks\*\*

&nbsp;  - Always verify user identity before operations

&nbsp;  

5\. \*\*Encrypt backups\*\*

&nbsp;  - Encrypt backup files before uploading to Storage



---



\## Testing



\### Mock Services for Unit Tests



```dart

class MockFirebaseAuth extends Mock implements FirebaseAuth {}

class MockFirebaseFirestore extends Mock implements FirebaseFirestore {}

class MockFirebaseStorage extends Mock implements FirebaseStorage {}



// Usage in tests

final mockAuth = MockFirebaseAuth();

when(mockAuth.signInWithEmailAndPassword(

&nbsp; email: 'test@test.com',

&nbsp; password: 'password123',

)).thenAnswer((\_) async => mockUserCredential);

```



\### Integration Test Setup



Use Firebase Emulator Suite for local testing:



```bash

firebase emulators:start --only auth,firestore,storage

```



Configure in app:

```dart

void useEmulator() {

&nbsp; FirebaseAuth.instance.useAuthEmulator('localhost', 9099);

&nbsp; FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8080);

&nbsp; FirebaseStorage.instance.useStorageEmulator('localhost', 9199);

}

```

