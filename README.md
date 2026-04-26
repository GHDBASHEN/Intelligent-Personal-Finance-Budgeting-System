# Intelligent-Personal-Finance-Budgeting-System
Developing  Intelligent Personal Finance &amp; Budgeting System in Flutter

## Features

- Login / Signup (Firebase Auth)
- Add, edit, delete transactions
- Income & expense categories
- Monthly charts (pie + bar)
- Export CSV reports


## Tech Stack

- Flutter
- Firebase (Auth + Firestore)


## Setup


flutter pub get
flutter run


## Pages

1. **Login** – Email/password
2. **Dashboard** – Balance + charts + recent transactions
3. **Transactions** – Full list with filters
4. **Add/Edit** – Form to add or edit transaction
5. **Export** – Generate CSV

---

## Error Handling

- Network errors → retry button
- Invalid inputs → form validation
- Firestore errors → user-friendly messages

---

## Dependencies

```yaml
firebase_core
firebase_auth
cloud_firestore
csv
share_plus
intl
```
