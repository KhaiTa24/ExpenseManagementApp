\# Business Rules \& Logic



\## 1. Transaction Rules



\### Amount Validation

\- \*\*Minimum\*\*: 1,000 VND (0.001 với hệ số nhân 1000)

\- \*\*Maximum\*\*: 999,999,999,999 VND

\- \*\*Decimal places\*\*: Tối đa 2 chữ số thập phân

\- \*\*Format display\*\*: #,###,### VND



\### Date Rules

\- Transaction date không được vượt quá ngày hiện tại

\- Có thể nhập giao dịch trong quá khứ (không giới hạn)

\- Default date: Ngày hiện tại

\- Format: DD/MM/YYYY



\### Transaction Types

\- \*\*Income\*\*: Các khoản thu nhập

\- \*\*Expense\*\*: Các khoản chi tiêu

\- Không cho phép amount = 0



\## 2. Category Rules



\### Default Categories



\*\*Income Categories:\*\*

```

\- Lương (Salary) - Icon: wallet, Color: #4CAF50

\- Thưởng (Bonus) - Icon: gift, Color: #FF9800

\- Đầu tư (Investment) - Icon: trending\_up, Color: #2196F3

\- Thu nhập khác (Other Income) - Icon: attach\_money, Color: #00BCD4

```



\*\*Expense Categories:\*\*

```

\- Ăn uống (Food \& Drink) - Icon: restaurant, Color: #FF5722

\- Mua sắm (Shopping) - Icon: shopping\_cart, Color: #E91E63

\- Đi lại (Transportation) - Icon: directions\_car, Color: #9C27B0

\- Hóa đơn (Bills) - Icon: receipt, Color: #F44336

\- Giải trí (Entertainment) - Icon: movie, Color: #673AB7

\- Y tế (Healthcare) - Icon: local\_hospital, Color: #009688

\- Giáo dục (Education) - Icon: school, Color: #3F51B5

\- Chi phí khác (Other Expense) - Icon: more\_horiz, Color: #795548

```



\### Category Management Rules

\- Không được xóa category đã có transactions

\- Khi xóa category: chuyển transactions sang "Uncategorized"

\- Maximum categories per user: 50

\- Category name: 2-50 ký tự

\- Không được trùng tên trong cùng type



\## 3. Budget Rules



\### Budget Configuration

\- \*\*Period types\*\*: Monthly, Yearly

\- \*\*Minimum budget\*\*: 10,000 VND

\- \*\*Maximum budget\*\*: 999,999,999 VND

\- Một category chỉ có 1 budget active cho 1 period



\### Budget Alerts

\- \*\*Warning threshold\*\*: 80% budget spent → Yellow alert

\- \*\*Danger threshold\*\*: 100% budget spent → Red alert

\- \*\*Over budget\*\*: >100% → Critical notification



\### Budget Calculation

```

Spent Amount = SUM(transactions.amount) 

&nbsp; WHERE category\_id = budget.category\_id

&nbsp; AND type = 'expense'

&nbsp; AND date BETWEEN period\_start AND period\_end



Remaining = Budget Amount - Spent Amount

Percentage = (Spent Amount / Budget Amount) \* 100

```



\## 4. Balance Calculation



\### Current Balance Formula

```

Total Income = SUM(amount WHERE type = 'income')

Total Expense = SUM(amount WHERE type = 'expense')

Current Balance = Total Income - Total Expense

```



\### Period Balance

```

Period Income = SUM(amount WHERE type = 'income' AND date IN period)

Period Expense = SUM(amount WHERE type = 'expense' AND date IN period)

Period Balance = Period Income - Period Expense

```



\## 5. Authentication Rules



\### Email/Password

\- \*\*Email format\*\*: Valid email regex

\- \*\*Password requirements\*\*:

&nbsp; - Minimum 8 characters

&nbsp; - At least 1 uppercase letter

&nbsp; - At least 1 lowercase letter

&nbsp; - At least 1 number

&nbsp; - At least 1 special character



\### PIN Code

\- \*\*Length\*\*: Exactly 6 digits

\- \*\*Retry limit\*\*: 5 attempts

\- \*\*Lockout duration\*\*: 30 minutes after 5 failed attempts

\- \*\*PIN change\*\*: Require old PIN or biometric verification



\### Biometric Authentication

\- Fallback to PIN if biometric fails

\- Maximum 3 biometric attempts

\- Re-authentication required after 30 minutes of inactivity



\## 6. Data Sync Rules



\### Sync Priority

1\. User settings

2\. Categories

3\. Transactions

4\. Budgets



\### Conflict Resolution

\- \*\*Last-write-wins\*\* for settings and categories

\- \*\*Merge strategy\*\* for transactions (based on created\_at timestamp)

\- Auto-sync every 5 minutes when online

\- Manual sync button available



\### Offline Mode

\- All CRUD operations work offline

\- Queue sync operations

\- Show sync status indicator

\- Sync when connection restored



\## 7. Backup Rules



\### Auto Backup

\- \*\*Frequency\*\*: Daily at 2:00 AM

\- \*\*Storage\*\*: Firebase Storage

\- \*\*Retention\*\*: Keep last 30 backups

\- \*\*Format\*\*: Encrypted JSON



\### Manual Backup

\- User can trigger anytime

\- Export to local storage (CSV/JSON)

\- Include all data except credentials



\## 8. Notification Rules



\### Daily Reminder

\- \*\*Default time\*\*: 20:00

\- \*\*Message\*\*: "Đừng quên ghi chép chi tiêu hôm nay!"

\- User can customize time or disable



\### Budget Alerts

\- Notify immediately when threshold reached

\- Max 1 notification per category per day

\- Can be disabled per category



\### Transaction Reminder

\- Notify if no transaction in 3 days

\- Can be disabled in settings



\## 9. Data Retention \& Privacy



\### Data Deletion

\- User can delete account

\- All data removed within 30 days

\- Backup data deleted immediately

\- Anonymous usage stats may be retained



\### Data Export

\- User can export all data anytime

\- Format: JSON or CSV

\- Includes all transactions, categories, budgets



\## 10. Performance Rules



\### Pagination

\- Transactions list: 50 items per page

\- Infinite scroll loading

\- Cache first 100 transactions



\### Caching Strategy

\- Cache categories and budgets locally

\- Refresh cache on app start

\- Cache timeout: 1 hour



\### Image/Icon Handling

\- Category icons: Vector icons only (Material Icons)

\- No image uploads (prevent storage bloat)

\- Max 100 custom colors



\## 11. Validation Messages



\### Vietnamese Error Messages

```dart

'amount\_required': 'Vui lòng nhập số tiền',

'amount\_min': 'Số tiền tối thiểu là 1,000 VND',

'amount\_max': 'Số tiền vượt quá giới hạn',

'category\_required': 'Vui lòng chọn danh mục',

'date\_invalid': 'Ngày không hợp lệ',

'date\_future': 'Không thể chọn ngày trong tương lai',

'description\_max': 'Mô tả không quá 200 ký tự',

'budget\_exists': 'Ngân sách cho danh mục này đã tồn tại',

'network\_error': 'Lỗi kết nối, vui lòng thử lại',

'sync\_failed': 'Đồng bộ thất bại',

```



\## 12. Currency Settings



\### Default Currency

\- \*\*Currency\*\*: VND (Vietnamese Dong)

\- \*\*Symbol\*\*: ₫

\- \*\*Position\*\*: Suffix (100,000₫)

\- \*\*Separator\*\*: Comma (,)



\### Future Multi-Currency Support

\- Prepare structure for currency conversion

\- Store exchange rates

\- Display in user's preferred currency

