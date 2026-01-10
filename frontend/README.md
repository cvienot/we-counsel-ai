# We Coach - Frontend

Flutter multi-platform app for couples counselling with AI guidance.

## 🚀 Quick Start - Deployment

### Deploy to AWS Amplify
```bash
./deploy-amplify.sh
```

See [FRONTEND-DEPLOYMENT.md](../FRONTEND-DEPLOYMENT.md) for complete deployment guide.

## 💻 Local Development

### Prerequisites
- Flutter SDK 3.8+
- Backend running on `localhost:3000`

### Run Development Server
```bash
flutter pub get
flutter run -d chrome --web-port 8080
```

## 🏗️ Build for Production

```bash
# Web
flutter build web --release

# iOS (future)
flutter build ios --release

# Android (future)
flutter build appbundle --release
```

## 📁 Project Structure

```
lib/
├── main.dart                 # App entry point
├── config/
│   └── environment.dart      # Environment configuration
├── models/                   # Data models
├── providers/                # State management
├── screens/                  # UI screens
├── services/
│   └── api_service.dart      # API client
├── utils/                    # Utilities
└── widgets/                  # Reusable components
```

## 🔧 Configuration

### Environment Variables
- Development: `.env.development`
- Production: `.env.production`

### API Configuration
Edit `lib/config/environment.dart` or use `--dart-define`:
```bash
flutter build web --dart-define=API_BASE_URL=https://your-api.com/api
```

## 🌐 Multi-Platform Support

- ✅ **Web**: Deployed to AWS Amplify
- 🔄 **iOS**: Ready for App Store
- 🔄 **Android**: Ready for Play Store
- 🔄 **macOS**: Desktop support
- 🔄 **Windows**: Desktop support
- 🔄 **Linux**: Desktop support

## 📚 Documentation

- [Deployment Guide](../FRONTEND-DEPLOYMENT.md)
- [Architecture Overview](../DEPLOYMENT-SUMMARY.md)
- [Backend API](../backend/README.md)

## 🧪 Testing

```bash
# Run tests
flutter test

# Run with coverage
flutter test --coverage
```

## 🎨 Features

- 🔐 Secure authentication
- 💑 Partner connection system
- 💬 Real-time messaging
- 🤖 AI counselor integration
- 📱 Responsive design
- 🌙 Dark mode support
- 🌍 Internationalization ready

## 📄 License

Private project
