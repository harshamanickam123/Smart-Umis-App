# Smart UMIS - University Management Information System

A complete full-stack application with Flutter frontend and Node.js backend using MongoDB for authentication and data management.

## 🏗️ Project Structure

```
smart-umis/
├── backend/                 # Node.js Backend
│   ├── server.js           # Main server file
│   ├── package.json        # Node dependencies
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

## 📋 Prerequisites

### Backend Requirements
- **Node.js** (v14 or higher)
- **MongoDB** (Local or MongoDB Atlas)
- **npm** or **yarn**

### Frontend Requirements
- **Flutter SDK** (v3.0 or higher)
- **Android Studio** / **Xcode** (for mobile development)
- **VS Code** or **Android Studio** (IDE)

## 🔧 Backend Setup

### 1. Install MongoDB

**Option A: Local MongoDB**
- Download from [MongoDB Official Site](https://www.mongodb.com/try/download/community)
- Install and start MongoDB service

**Option B: MongoDB Atlas (Cloud)**
- Create free account at [MongoDB Atlas](https://www.mongodb.com/cloud/atlas)
- Create a cluster and get connection string

### 2. Setup Backend

```bash
# Navigate to backend directory
cd backend

# Install dependencies
npm install

# Create .env file
cp .env.example .env

# Edit .env file with your configurations
# Update MONGODB_URI with your connection string
# Update JWT_SECRET with a random secure string

# Start the server
npm start

# For development with auto-reload
npm run dev
```

The backend will run on `http://localhost:3000`

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
cd frontend

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

In `lib/main.dart`, update the API URL:

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

### User Collection

```javascript
{
  _id: ObjectId,
  fullName: String (required),
  username: String (required, unique),
  email: String (required, unique),
  password: String (hashed, required),
  role: String (enum: ['Student', 'Staff']),
  createdAt: Date
}
```

## 🔒 Security Features

- **Password Hashing**: bcrypt with salt rounds
- **JWT Authentication**: 7-day token expiration
- **Input Validation**: Server-side validation
- **Role-Based Access**: Staff vs Student permissions
- **Secure Headers**: CORS enabled
- **Environment Variables**: Sensitive data protected

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
- `mongoose`: MongoDB ODM
- `bcryptjs`: Password hashing
- `jsonwebtoken`: JWT authentication
- `cors`: Cross-origin resource sharing
- `dotenv`: Environment variables

### Frontend Dependencies
- `http`: HTTP requests
- `flutter/material`: UI framework

## 🐛 Troubleshooting

### Backend Issues

**MongoDB Connection Error:**
```bash
# Check if MongoDB is running
mongosh

# For Windows
net start MongoDB

# For Mac/Linux
sudo systemctl start mongod
```

**Port Already in Use:**
```bash
# Change PORT in .env file
PORT=3001
```

### Frontend Issues

**Connection Refused:**
- Ensure backend is running
- Check API URL configuration
- For Android emulator, use `10.0.2.2` instead of `localhost`

**Flutter Dependencies Error:**
```bash
flutter clean
flutter pub get
```

## 🚀 Deployment

### Backend Deployment (Example: Heroku)

```bash
# Install Heroku CLI
heroku login
heroku create smart-umis-api

# Set environment variables
heroku config:set MONGODB_URI="your_mongodb_atlas_uri"
heroku config:set JWT_SECRET="your_secret_key"

# Deploy
git push heroku main
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
# Or
flutter build appbundle --release
```

**iOS:**
```bash
flutter build ios --release
```

## 📝 License

MIT License

## 👥 Contributors

HARHSA VARDHINI N
DHAARANI S
AVINASH RK
KARTHIK PRAKASH M
