# Smart UMIS - University Management Information System

A complete full-stack application with Flutter frontend and Node.js backend using SQLite for authentication and data management.

## 🏗️ Project Structure

```
smart-umis/
├── backend/                 # Node.js Backend
│   ├── server.js           # Main server file
│   ├── package.json        # Node dependencies
│   ├── smart_umis.db       # SQLite database file
│   └── .env               # Environment variables
│
└── frontend/               # Flutter Frontend
    ├── lib/
    │   └── main.dart      # Main Flutter application
    └── pubspec.yaml       # Flutter dependencies
```

## 🚀 Features

- ✅ User Registration (Student/Staff roles)
- ✅ User Login with JWT authentication
- ✅ Username or Email login support
- ✅ Password encryption with bcrypt
- ✅ Protected routes with JWT verification
- ✅ Profile management
- ✅ Password change functionality
- ✅ Role-based access control
- ✅ Responsive Flutter UI
- ✅ Lightweight SQLite database

## 📋 Prerequisites

### Backend Requirements
- **Node.js** (v14 or higher)
- **npm** or **yarn**
- SQLite (automatically included with node)

### Frontend Requirements
- **Flutter SDK** (v3.0 or higher)
- **Android Studio** / **Xcode** (for mobile development)
- **VS Code** or **Android Studio** (IDE)

## 🔧 Backend Setup

### 1. SQLite Database

**No installation required!** SQLite is file-based and will be automatically created when you first run the backend.

The database file `smart_umis.db` will be created in the backend folder on first run.

### 2. Setup Backend

```bash
# Navigate to backend directory
cd smart_umis_backend

# Install dependencies
npm install

# Create .env file (if not exists)
# Add the following content:
# PORT=3000
# JWT_SECRET=your_secret_key_here_min_32_characters

# Start the server
npm start

# For development with auto-reload
npm run dev
```

The backend will run on `http://localhost:3000`

The SQLite database file `smart_umis.db` will be automatically created on first run.

### 3. Test Backend API

```bash
# Health check
curl http://localhost:3000/api/health

# Register a new user
curl -X POST http://localhost:3000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "fullName": "John Doe",
    "username": "johndoe",
    "email": "john@example.com",
    "password": "password123",
    "role": "Student"
  }'

# Login
curl -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "username": "johndoe",
    "password": "password123"
  }'
```

## 📱 Frontend Setup

### 1. Install Flutter

Follow instructions at [Flutter Install Guide](https://docs.flutter.dev/get-started/install)

Verify installation:
```bash
flutter doctor
```

### 2. Setup Flutter Project

```bash
# Navigate to frontend directory
cd smart_umis_frontend

# Get dependencies
flutter pub get

# Run on connected device/emulator
flutter run

# For web
flutter run -d chrome

# For specific device
flutter devices  # List available devices
flutter run -d <device-id>
```

### 3. Configure API URL

In `lib/main.dart`, update the API URL based on your setup:

```dart
// For Android Emulator
final String apiUrl = 'http://10.0.2.2:3000/api';

// For iOS Simulator
final String apiUrl = 'http://localhost:3000/api';

// For Physical Device (use your computer's IP)
final String apiUrl = 'http://192.168.x.x:3000/api';

// For Production
final String apiUrl = 'https://your-api-domain.com/api';
```

**To find your IP address:**
```bash
# Windows
ipconfig

# Mac/Linux
ifconfig
```

## 🔐 API Endpoints

### Public Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/auth/register` | Register new user |
| POST | `/api/auth/login` | Login user |
| GET | `/api/health` | Health check |

### Protected Endpoints (Require JWT Token)

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/auth/profile` | Get user profile |
| PUT | `/api/auth/profile` | Update profile |
| PUT | `/api/auth/change-password` | Change password |
| GET | `/api/users` | Get all users (Staff only) |
| DELETE | `/api/users/:id` | Delete user (Staff only) |

## 📊 Database Schema

### Users Table (SQLite)

```sql
CREATE TABLE users (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  fullName TEXT NOT NULL,
  username TEXT UNIQUE NOT NULL,
  email TEXT UNIQUE NOT NULL,
  password TEXT NOT NULL,
  role TEXT CHECK(role IN ('Student', 'Staff')) NOT NULL,
  createdAt DATETIME DEFAULT CURRENT_TIMESTAMP
);
```

## 🔒 Security Features

- **Password Hashing**: bcrypt with salt rounds
- **JWT Authentication**: 7-day token expiration
- **Input Validation**: Server-side validation
- **Role-Based Access**: Staff vs Student permissions
- **Secure Headers**: CORS enabled
- **Environment Variables**: Sensitive data protected
- **SQLite**: Lightweight, serverless database

## 🎨 UI Screens

1. **Welcome Screen**: Initial landing page
2. **Login Screen**: Username/Email and password login
3. **Register Screen**: New user registration with role selection
4. **Dashboard Screen**: User dashboard after login

## 🧪 Testing

### Test User Accounts

After registration, you can create test accounts:

**Student Account:**
- Username: `student1`
- Email: `student1@example.com`
- Password: `password123`
- Role: Student

**Staff Account:**
- Username: `staff1`
- Email: `staff1@example.com`
- Password: `password123`
- Role: Staff

## 📦 Dependencies

### Backend Dependencies
- `express`: Web framework
- `sqlite3`: SQLite database driver
- `bcryptjs`: Password hashing
- `jsonwebtoken`: JWT authentication
- `cors`: Cross-origin resource sharing
- `dotenv`: Environment variables

### Frontend Dependencies
- `http`: HTTP requests
- `flutter/material`: UI framework

## 🐛 Troubleshooting

### Backend Issues

**Database File Not Created:**
```bash
# Ensure you have write permissions in backend folder
# The smart_umis.db file will be created automatically on first run
```

**Port Already in Use:**
```bash
# Change PORT in .env file
PORT=3001
```

**SQLite Database Locked:**
```bash
# Stop the server and restart
# Make sure only one instance is running
```

### Frontend Issues

**Connection Refused:**
- Ensure backend is running on `http://localhost:3000`
- Check API URL configuration
- For Android emulator, use `10.0.2.2` instead of `localhost`
- For physical device, use your computer's IP address

**Flutter Dependencies Error:**
```bash
flutter clean
flutter pub get
```

## 📁 Database Management

### View SQLite Database

**Using DB Browser for SQLite (Recommended):**
1. Download from [DB Browser for SQLite](https://sqlitebrowser.org/)
2. Open `smart_umis.db` file from backend folder
3. Browse tables, run queries, view data

**Using Command Line:**
```bash
# Navigate to backend folder
cd smart_umis_backend

# Open SQLite CLI
sqlite3 smart_umis.db

# View all tables
.tables

# Query users
SELECT * FROM users;

# Exit
.quit
```

### Backup Database

```bash
# Create backup
cp smart_umis.db smart_umis_backup.db

# Or use SQLite backup command
sqlite3 smart_umis.db ".backup 'backup.db'"
```

### Reset Database

```bash
# Stop the backend server first
# Delete the database file
rm smart_umis.db  # Mac/Linux
del smart_umis.db  # Windows

# Restart server - a new database will be created
```

## 🚀 Deployment

### Backend Deployment (Example: Heroku)

```bash
# Install Heroku CLI
heroku login
heroku create smart-umis-api

# Set environment variables
heroku config:set JWT_SECRET="your_secret_key_here"
heroku config:set PORT=3000

# Deploy
git push heroku main

# Note: SQLite database will be created on the server
# For production, consider using PostgreSQL or MySQL
```

### Frontend Deployment

**Web:**
```bash
flutter build web
# Deploy to Firebase Hosting, Netlify, or Vercel
```

**Android:**
```bash
flutter build apk --release
# Or for Play Store
flutter build appbundle --release
```

**iOS:**
```bash
flutter build ios --release
```

## ⚠️ Important Notes

- **SQLite is file-based**: The database file `smart_umis.db` will be in your backend folder
- **Backup regularly**: Copy the `.db` file to backup your data
- **Not in .gitignore**: If you want to share an empty database structure, keep the file. If you want team members to start fresh, add `*.db` to `.gitignore`
- **Production**: For production deployment with multiple servers, consider migrating to PostgreSQL or MySQL

## 📝 Environment Variables

Create a `.env` file in the backend folder:

```env
PORT=5000
JWT_SECRET=your_super_secret_key_at_least_32_characters_long
```

## 👥 Contributors

- HARHSA VARDHINI N
- DHAARANI S
- AVINASH RK
- KARTHIK PRAKASH M

## 📝 License

MIT License

---

## 🆘 Need Help?

If you encounter any issues:
1. Check the Troubleshooting section above
2. Ensure all dependencies are installed
3. Verify backend is running before starting frontend
4. Check console logs for error messages
5. Make sure SQLite database file has proper permissions