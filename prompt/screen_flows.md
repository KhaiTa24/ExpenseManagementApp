\# Screen Flows \& Navigation



\## Navigation Structure



```

App Root

├── Splash Screen

├── Authentication Flow

│   ├── Welcome Screen

│   ├── Login Screen

│   ├── Register Screen

│   └── Forgot Password Screen

├── Security Setup Flow

│   ├── PIN Setup Screen

│   └── Biometric Setup Screen

└── Main App (Bottom Navigation)

&nbsp;   ├── Home Tab

&nbsp;   ├── Transactions Tab

&nbsp;   ├── Statistics Tab

&nbsp;   ├── Budget Tab

&nbsp;   └── Profile Tab

```



\## Screen Descriptions



\### 1. Splash Screen

\*\*Purpose\*\*: App initialization, check auth status



\*\*Layout\*\*:

\- App logo (center)

\- App name

\- Loading indicator

\- Version number (bottom)



\*\*Logic\*\*:

\- Check if user logged in

\- Load initial data

\- Navigate to Welcome/Security/Home based on status

\- Duration: 2-3 seconds



---



\### 2. Welcome Screen

\*\*Purpose\*\*: First-time user onboarding



\*\*Layout\*\*:

\- Hero image/illustration

\- App tagline: "Quản lý tài chính thông minh"

\- Features highlights (3 cards):

&nbsp; - "Theo dõi thu chi dễ dàng"

&nbsp; - "Đặt ngân sách thông minh"

&nbsp; - "Báo cáo trực quan"

\- Buttons:

&nbsp; - "Đăng nhập" (outlined)

&nbsp; - "Đăng ký" (primary)



\*\*Navigation\*\*:

\- Đăng nhập → Login Screen

\- Đăng ký → Register Screen



---



\### 3. Login Screen

\*\*Purpose\*\*: User authentication



\*\*Layout\*\*:

\- Back button

\- Title: "Đăng nhập"

\- Email input field

\- Password input field (with show/hide toggle)

\- "Quên mật khẩu?" link

\- "Đăng nhập" button

\- Divider with text: "Hoặc"

\- "Đăng nhập với Google" button

\- "Chưa có tài khoản? Đăng ký" link



\*\*Validation\*\*:

\- Email format

\- Password not empty

\- Show error messages below fields



\*\*Navigation\*\*:

\- Success → Security Screen (if first time) or Home

\- Quên mật khẩu → Forgot Password Screen

\- Đăng ký → Register Screen



---



\### 4. Register Screen

\*\*Purpose\*\*: New user registration



\*\*Layout\*\*:

\- Back button

\- Title: "Đăng ký"

\- Display name input

\- Email input

\- Password input (with strength indicator)

\- Confirm password input

\- Terms \& conditions checkbox

\- "Đăng ký" button

\- "Đã có tài khoản? Đăng nhập" link



\*\*Validation\*\*:

\- All fields required

\- Email format

\- Password requirements (see business\_rules.md)

\- Passwords match

\- Terms accepted



\*\*Navigation\*\*:

\- Success → PIN Setup Screen

\- Đăng nhập → Login Screen



---



\### 5. PIN Setup Screen

\*\*Purpose\*\*: Set up 6-digit PIN for app security



\*\*Layout\*\*:

\- Progress indicator (1/2)

\- Title: "Tạo mã PIN"

\- Subtitle: "Nhập 6 chữ số để bảo mật ứng dụng"

\- PIN input (6 circles)

\- Number pad (0-9)

\- Skip button (bottom)



\*\*Flow\*\*:

1\. Enter PIN

2\. Confirm PIN screen

3\. If match → Biometric Setup Screen

4\. If not match → Show error, retry



---



\### 6. Biometric Setup Screen

\*\*Purpose\*\*: Optional biometric authentication



\*\*Layout\*\*:

\- Progress indicator (2/2)

\- Fingerprint/Face icon

\- Title: "Bảo mật sinh trắc học"

\- Description

\- "Bật" button

\- "Bỏ qua" link



\*\*Navigation\*\*:

\- Both options → Home Screen (first time setup complete)



---



\### 7. Home Screen (Tab 1)

\*\*Purpose\*\*: Dashboard overview



\*\*Layout\*\*:

```

├── Header

│   ├── User greeting: "Xin chào, \[Name]"

│   ├── Notification icon (badge if has unread)

│   └── Settings icon

├── Balance Card

│   ├── "Số dư hiện tại"

│   ├── Large balance number

│   └── Period selector (Hôm nay/Tuần/Tháng/Năm)

├── Quick Stats (2 columns)

│   ├── Thu nhập card (green)

│   └── Chi tiêu card (red)

├── Quick Actions (2 buttons)

│   ├── "+ Thu nhập" (green)

│   └── "- Chi tiêu" (red)

├── Recent Transactions

│   ├── Section title: "Giao dịch gần đây"

│   ├── List (5 items)

│   │   ├── Category icon + name

│   │   ├── Description

│   │   ├── Date

│   │   └── Amount (colored)

│   └── "Xem tất cả" link

└── Budget Overview Card

&nbsp;   ├── "Ngân sách tháng này"

&nbsp;   ├── Progress bars (top 3 categories)

&nbsp;   └── "Chi tiết" link

```



\*\*Actions\*\*:

\- Notification icon → Notifications Screen

\- Settings icon → Settings Screen

\- Quick Actions → Add Transaction Bottom Sheet

\- Recent transaction item → Transaction Detail Screen

\- "Xem tất cả" → Transactions Tab

\- Budget card → Budget Tab



---



\### 8. Add/Edit Transaction Screen (Bottom Sheet)

\*\*Purpose\*\*: Quick transaction entry



\*\*Layout\*\*:

\- Handle bar (drag to dismiss)

\- Title: "Thêm giao dịch" / "Sửa giao dịch"

\- Type tabs: "Chi tiêu" | "Thu nhập"

\- Amount input (large, center)

&nbsp; - Number pad appears

&nbsp; - Format as typing: 100,000

\- Category selector (horizontal scroll of icons)

\- Date picker field (default: today)

\- Description input (optional)

\- Buttons:

&nbsp; - "Hủy" (text)

&nbsp; - "Lưu" (primary)



\*\*Validation\*\*:

\- Amount > 0

\- Category selected

\- Date valid



\*\*Actions\*\*:

\- Save → Close sheet, refresh home

\- Category icon → Category picker bottom sheet



---



\### 9. Transactions Screen (Tab 2)

\*\*Purpose\*\*: View and manage all transactions



\*\*Layout\*\*:

```

├── Header

│   ├── Title: "Giao dịch"

│   ├── Search icon

│   └── Filter icon (badge if active)

├── Filter Bar

│   ├── Period chips: Hôm nay | Tuần | Tháng | Tùy chỉnh

│   └── Type chips: Tất cả | Thu | Chi

├── Summary Card

│   ├── Total income (green)

│   ├── Total expense (red)

│   └── Net balance

├── Transaction List (grouped by date)

│   ├── Date header: "Hôm nay" / "DD/MM/YYYY"

│   ├── Transaction items

│   │   ├── Category icon (colored circle)

│   │   ├── Category name + description

│   │   ├── Time: "HH:mm"

│   │   └── Amount (signed, colored)

│   └── Load more on scroll

└── FAB: "+" (bottom right)

```



\*\*Actions\*\*:

\- Search icon → Search overlay with input

\- Filter icon → Filter bottom sheet

\- Transaction item → swipe actions:

&nbsp; - Swipe right: Edit (blue)

&nbsp; - Swipe left: Delete (red)

\- Transaction item tap → Transaction Detail Screen

\- FAB → Add Transaction Screen



---



\### 10. Transaction Detail Screen

\*\*Purpose\*\*: View full transaction details



\*\*Layout\*\*:

\- Back button

\- Title: Category name

\- Large amount (colored)

\- Details card:

&nbsp; - Type

&nbsp; - Category

&nbsp; - Date \& Time

&nbsp; - Description

\- Edit button (bottom)

\- Delete button (bottom, outlined, red)



\*\*Actions\*\*:

\- Edit → Edit Transaction Screen

\- Delete → Confirmation dialog → Delete → Back



---



\### 11. Statistics Screen (Tab 3)

\*\*Purpose\*\*: Visual analytics and reports



\*\*Layout\*\*:

```

├── Header

│   ├── Title: "Thống kê"

│   └── Period selector

├── Tab bar

│   ├── Chi tiêu

│   └── Thu nhập

├── Expense/Income Tab Content

│   ├── Total card (large number)

│   ├── Chart selector chips

│   │   ├── Pie chart

│   │   ├── Bar chart

│   │   └── Line chart

│   ├── Chart area (interactive)

│   ├── Category breakdown list

│   │   ├── Category icon + name

│   │   ├── Percentage bar

│   │   ├── Amount

│   │   └── Percentage (%)

│   └── Comparison card

│       ├── "So với tháng trước"

│       └── Percentage change (colored)

```



\*\*Features\*\*:

\- Period selector: Tháng này, Tháng trước, 3 tháng, 6 tháng, Năm, Tùy chỉnh

\- Chart interactions: tap to highlight, show tooltip

\- Category item tap → filter transactions by category



---



\### 12. Budget Screen (Tab 4)

\*\*Purpose\*\*: Budget management



\*\*Layout\*\*:

```

├── Header

│   ├── Title: "Ngân sách"

│   ├── Period selector: Tháng | Năm

│   └── Add icon

├── Summary Card

│   ├── "Tổng ngân sách"

│   ├── Total budget amount

│   ├── Total spent (with percentage)

│   └── Remaining amount

├── Budget List

│   ├── Budget Item Card

│   │   ├── Category icon + name

│   │   ├── Budget amount vs Spent

│   │   ├── Progress bar (colored by threshold)

│   │   ├── Remaining amount

│   │   └── Days left in period

│   └── Empty state: "Chưa có ngân sách"

├── Suggestions Card (if no budgets)

│   ├── "Đề xuất ngân sách"

│   ├── Based on spending history

│   └── "Áp dụng" buttons

└── FAB: "+" (bottom right)

```



\*\*Budget Item Colors\*\*:

\- Green: < 80% spent

\- Yellow: 80-99% spent

\- Red: 100%+ spent



\*\*Actions\*\*:

\- Add icon / FAB → Add Budget Screen

\- Budget item tap → Budget Detail Screen

\- Budget item long press → Edit/Delete menu



---



\### 13. Add/Edit Budget Screen

\*\*Purpose\*\*: Create or modify budget



\*\*Layout\*\*:

\- Back button

\- Title: "Thêm ngân sách" / "Sửa ngân sách"

\- Category selector

\- Period selector: Tháng này | Năm này

\- Amount input

\- "Gợi ý dựa trên chi tiêu" card (if editing)

\- Save button



\*\*Validation\*\*:

\- Category selected

\- Amount > 0

\- No duplicate budget for same category + period



---



\### 14. Budget Detail Screen

\*\*Purpose\*\*: View budget performance



\*\*Layout\*\*:

\- Back button

\- Category name + icon

\- Large progress circle (percentage)

\- Budget vs Spent vs Remaining

\- Daily average card

\- Transactions in this category (this period)

\- Edit button

\- Delete button



---



\### 15. Profile Screen (Tab 5)

\*\*Purpose\*\*: User settings and account management



\*\*Layout\*\*:

```

├── Header

│   └── Title: "Cá nhân"

├── User Info Card

│   ├── Avatar (initial or image)

│   ├── Display name

│   ├── Email

│   └── Edit profile icon

├── Settings Sections

│   ├── Tài khoản

│   │   ├── Thông tin cá nhân

│   │   └── Đổi mật khẩu

│   ├── Bảo mật

│   │   ├── Mã PIN

│   │   └── Sinh trắc học (toggle)

│   ├── Dữ liệu

│   │   ├── Sao lưu \& Đồng bộ

│   │   ├── Xuất dữ liệu

│   │   └── Xóa dữ liệu

│   ├── Thông báo

│   │   ├── Nhắc nhở hằng ngày (toggle)

│   │   ├── Cảnh báo ngân sách (toggle)

│   │   └── Cài đặt thời gian

│   ├── Giao diện

│   │   ├── Chế độ tối (toggle)

│   │   └── Ngôn ngữ

│   ├── Về ứng dụng

│   │   ├── Phiên bản

│   │   ├── Điều khoản sử dụng

│   │   └── Chính sách bảo mật

│   └── Đăng xuất (red text)

```



\*\*Actions\*\*:

\- Each item → Respective settings screen

\- Đăng xuất → Confirmation dialog → Logout → Welcome Screen



---



\### 16. Categories Management Screen

\*\*Purpose\*\*: View and manage categories



\*\*Layout\*\*:

\- Back button

\- Title: "Danh mục"

\- Tabs: Chi tiêu | Thu nhập

\- Category list:

&nbsp; - Category icon + name + color

&nbsp; - Transaction count

&nbsp; - Swipe to edit/delete

\- FAB: "+"



\*\*Actions\*\*:

\- Add → Add Category Screen

\- Edit → Edit Category Screen

\- Delete → Confirmation (if has transactions, show warning)



---



\### 17. Add/Edit Category Screen

\*\*Purpose\*\*: Create or modify category



\*\*Layout\*\*:

\- Back button

\- Title: "Thêm danh mục" / "Sửa danh mục"

\- Type selector (if adding): Chi tiêu | Thu nhập

\- Name input

\- Icon selector (grid of Material Icons)

\- Color picker (pre-defined colors)

\- Save button



\*\*Validation\*\*:

\- Name required, 2-50 characters

\- No duplicate names in same type



---



\### 18. Search Screen

\*\*Purpose\*\*: Search transactions



\*\*Layout\*\*:

\- Search input (auto-focus)

\- Recent searches chips

\- Filters:

&nbsp; - Date range

&nbsp; - Amount range

&nbsp; - Category

&nbsp; - Type

\- Search results list (same as transaction list)

\- Empty state: "Không tìm thấy giao dịch"



---



\### 19. Notifications Screen

\*\*Purpose\*\*: View app notifications



\*\*Layout\*\*:

\- Back button

\- Title: "Thông báo"

\- Notification list:

&nbsp; - Icon (colored by type)

&nbsp; - Title

&nbsp; - Description

&nbsp; - Time

&nbsp; - Read/Unread indicator

\- Empty state: "Chưa có thông báo"



\*\*Notification Types\*\*:

\- Budget alert (yellow/red)

\- Daily reminder (blue)

\- Sync status (green/red)



---



\## Navigation Patterns



\### Bottom Navigation Tabs

```

Home | Transactions | Statistics | Budget | Profile

```

\- Always visible in main app

\- Active tab highlighted

\- Badge on notification icon



\### Back Navigation

\- Hardware back button supported

\- Back arrow in app bar

\- Swipe from left edge (iOS-style)



\### Deep Linking

```

moneymanager://transaction/{id}

moneymanager://budget/{id}

moneymanager://category/{id}

```



\### Modal Patterns

\- Bottom sheets: Quick actions, forms

\- Dialogs: Confirmations, alerts

\- Full screen: Detail views, settings



\## Gestures



\### Swipe Actions

\- \*\*Transaction list\*\*: 

&nbsp; - Swipe right → Edit (blue)

&nbsp; - Swipe left → Delete (red)

\- \*\*Budget list\*\*: Long press → menu



\### Pull to Refresh

\- Home screen

\- Transaction list

\- Statistics charts



\### Scroll Behaviors

\- Scroll to hide/show app bar (optional)

\- Infinite scroll for transaction lists

\- Sticky date headers



\## Loading States



\### Skeleton Screens

\- Transaction list loading

\- Chart loading

\- Balance card loading



\### Progress Indicators

\- Full screen: Login, data sync

\- Inline: Saving, deleting

\- Pull to refresh indicator



\### Error States

\- Network error: Retry button

\- Empty states: Call to action

\- Validation errors: Inline messages



\## Animations



\### Screen Transitions

\- Push/Pop: Slide from right

\- Bottom sheet: Slide up with backdrop

\- Tabs: Fade crossfade



\### Micro-interactions

\- Button press: Scale down slightly

\- Success: Checkmark animation

\- Delete: Fade out + slide

\- Number changes: Count up animation



\## Accessibility



\### Screen Reader Support

\- All buttons labeled

\- Images have descriptions

\- Form inputs have hints



\### Touch Targets

\- Minimum 44x44 dp

\- Adequate spacing between buttons



\### Color Contrast

\- WCAG AA compliance

\- High contrast mode support

