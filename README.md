# We Counsel - Couples Counselling App

We Counsel is a modern couples counselling application that combines the convenience of digital communication with AI-powered guidance to help couples strengthen their relationships.

## ✨ Features

### MVP Features
- **User Authentication**: Secure login/signup with JWT tokens
- **Partner Invitation**: Invite your partner via email to join you on the app
- **Private Conversations**: Secure messaging between partners with AI counsellor participation
- **AI Counsellor**: GPT-powered counsellor that can address both partners or individuals
- **Threaded Discussions**: Organized conversation threads for different topics

### Core Functionality
- Real-time messaging between couples
- AI-powered relationship guidance and advice
- Email invitations with secure token-based acceptance
- Conversation management and organization
- User profile management

## 🏗️ Architecture

### Backend (Node.js/Express)
- **API Framework**: Express.js with comprehensive middleware
- **Authentication**: JWT-based authentication with secure token management
- **Database**: DynamoDB for scalable NoSQL data storage
- **Email Service**: AWS SES for invitation emails
- **AI Integration**: OpenAI GPT-4 for counselling responses
- **Deployment**: AWS App Runner for serverless container deployment

### Frontend (Flutter)
- **Framework**: Flutter with Material Design 3
- **State Management**: Riverpod for reactive state management
- **Navigation**: GoRouter for type-safe navigation
- **API Integration**: Dio HTTP client with automatic token management
- **Secure Storage**: Flutter Secure Storage for token persistence

### Infrastructure
- **Hosting**: AWS App Runner (backend), Flutter Web/Mobile (frontend)
- **Database**: DynamoDB with local development support
- **Email**: AWS SES for transactional emails
- **Security**: JWT tokens, bcrypt password hashing, secure storage

## 🚀 Getting Started

### Prerequisites
- Node.js 18+
- Flutter 3.x
- AWS CLI (for production deployment)
- DynamoDB Local (for development)

### Backend Setup

1. Navigate to the backend directory:
   ```bash
   cd backend
   ```

2. Install dependencies:
   ```bash
   npm install
   ```

3. Copy and configure environment variables:
   ```bash
   cp .env.example .env
   # Edit .env with your configuration
   ```

4. Start DynamoDB Local (for development):
   ```bash
   # Install DynamoDB Local
   java -Djava.library.path=./DynamoDBLocal_lib -jar DynamoDBLocal.jar -sharedDb -port 8000
   ```

5. Start the development server:
   ```bash
   npm run dev
   ```

The API will be available at `http://localhost:3000`

### Frontend Setup

1. Navigate to the frontend directory:
   ```bash
   cd frontend
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Run the app:
   ```bash
   flutter run
   ```

## 📁 Project Structure

```
we-counsel-reboot/
├── backend/                 # Node.js API backend
│   ├── src/
│   │   ├── config/         # Database and service configurations
│   │   ├── middleware/     # Express middleware (auth, error handling)
│   │   ├── models/         # Data models and schemas
│   │   ├── routes/         # API route handlers
│   │   ├── services/       # Business logic (AI, email services)
│   │   └── server.js       # Main server file
│   ├── .env                # Environment variables
│   ├── apprunner.yaml     # AWS App Runner configuration
│   └── package.json
├── frontend/               # Flutter mobile/web app
│   ├── lib/
│   │   ├── models/         # Dart data models
│   │   ├── providers/      # Riverpod state management
│   │   ├── screens/        # UI screens and pages
│   │   ├── services/       # API services and utilities
│   │   ├── utils/          # Helper utilities
│   │   ├── widgets/        # Reusable UI components
│   │   └── main.dart       # App entry point
│   └── pubspec.yaml
└── README.md
```

## 🔧 Configuration

### Backend Environment Variables
```env
# Server Configuration
PORT=3000
NODE_ENV=development

# JWT Configuration
JWT_SECRET=your_jwt_secret_here
JWT_EXPIRE=7d

# AWS Configuration
AWS_REGION=us-east-1
AWS_ACCESS_KEY_ID=your_access_key
AWS_SECRET_ACCESS_KEY=your_secret_key

# DynamoDB Configuration
DYNAMODB_REGION=us-east-1
DYNAMODB_ENDPOINT=http://localhost:8000

# SES Configuration
SES_REGION=us-east-1
SES_FROM_EMAIL=noreply@wecounsel.app

# OpenAI Configuration
OPENAI_API_KEY=your_openai_api_key
```

### Frontend Configuration
Update the API base URL in `lib/services/api_service.dart` for your environment:
```dart
static const String _baseUrl = 'http://localhost:3000/api'; // Development
static const String _baseUrl = 'https://your-app-runner-url.com/api'; // Production
```

## 🚀 Deployment

### Backend Deployment (AWS App Runner)
1. Push code to a Git repository
2. Create an App Runner service in AWS Console
3. Configure the service to use `apprunner.yaml`
4. Set environment variables in App Runner configuration
5. Deploy and monitor

### Frontend Deployment
- **Web**: `flutter build web` and deploy to hosting service
- **Mobile**: Build and publish to app stores
- **Desktop**: `flutter build windows/macos/linux`

## 🔒 Security Features

- JWT token-based authentication
- Password hashing with bcrypt
- Secure token storage on mobile
- Input validation and sanitization
- CORS protection
- Rate limiting and security headers
- **Mandatory Terms of Service acceptance** with version tracking and consent timestamps

## 🤖 AI Counsellor Features

The AI counsellor (Dr. Sarah) provides:
- Relationship guidance and advice
- Communication technique suggestions
- Empathetic and non-judgmental responses
- Individual and couple-focused interactions
- Context-aware conversation management

## 📊 Database Schema

### Users Table
- userId (Primary Key)
- email, firstName, lastName
- partnerId, coupleId
- Authentication and profile data
- **termsAcceptedAt, termsAcceptedVersion** (Terms of Service consent tracking)

### Couples Table
- coupleId (Primary Key)
- partner1Id, partner2Id
- Relationship metadata

### Conversations Table
- conversationId (Primary Key)
- coupleId, title, topic
- Creation and activity tracking

### Messages Table
- messageId (Primary Key)
- conversationId, senderId, content
- Sender type (user/ai), timestamps

### Invitations Table
- invitationId (Primary Key)
- inviterId, email, status
- Invitation management

## 🔮 Future Enhancements

- Real-time messaging with WebSockets
- Voice and video call integration
- Conversation analytics and insights
- Mood tracking and progress monitoring
- Therapist directory and booking
- Couple exercises and activities
- Progress reports and relationship metrics

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🆘 Support

For support, email support@wecounsel.app or create an issue in the repository.
