# Terms of Service Implementation Summary

## Overview
This document summarizes the implementation of mandatory Terms of Service acceptance during user registration for the We Counsel application.

## Date Implemented
December 12, 2025

## Changes Made

### 1. Terms of Service Document
**File:** [TERMS_OF_SERVICE.md](TERMS_OF_SERVICE.md)

Created comprehensive Terms of Service document covering:
- Acceptance of terms
- Service description
- User accounts and registration requirements
- Privacy and data protection
- User conduct guidelines
- Intellectual property rights
- AI counselling disclaimers
- Service modifications and termination
- Liability limitations
- Dispute resolution
- Governing law
- Contact information

**Version:** 1.0.0

---

### 2. Database Schema Updates
**File:** [backend/src/database/schema.js](backend/src/database/schema.js#L23-L24)

Added two new fields to the Users table:
- `termsAcceptedAt`: ISO timestamp when user accepted terms
- `termsAcceptedVersion`: Version of terms accepted (e.g., "1.0.0")

These fields enable:
- Tracking when users accepted terms
- Managing future terms updates
- Compliance with legal requirements

---

### 3. Backend API Changes
**File:** [backend/src/routes/auth.js](backend/src/routes/auth.js)

**Registration Endpoint Updates:**
- Added validation to require `termsAccepted` field in registration request
- Returns 400 error if terms are not accepted
- Stores acceptance timestamp and version in user record
- Error message: "You must accept the Terms of Service to create an account"

**Code Changes:**
```javascript
// Validation check
if (!termsAccepted) {
  return res.status(400).json({
    error: 'Validation error',
    message: 'You must accept the Terms of Service to create an account'
  });
}

// Store in database
termsAcceptedAt: currentTimestamp,
termsAcceptedVersion: '1.0.0'
```

---

### 4. Frontend UI Components

#### 4.1 Terms of Service Screen
**File:** [frontend/lib/screens/auth/terms_of_service_screen.dart](frontend/lib/screens/auth/terms_of_service_screen.dart)

New dedicated screen displaying complete Terms of Service with:
- Clean, readable formatting
- Section-by-section breakdown
- Scrollable content
- Professional styling matching app theme
- Highlighted acceptance notice at bottom

#### 4.2 Registration Screen Updates
**File:** [frontend/lib/screens/auth/register_screen.dart](frontend/lib/screens/auth/register_screen.dart)

**Changes:**
- Added `_termsAccepted` boolean state variable
- Added checkbox for terms acceptance
- Added clickable "Terms of Service" link that opens full terms screen
- Added validation before registration submission
- Shows error message if user tries to register without accepting terms

**UI Layout:**
```
[✓] I agree to the Terms of Service
     (clickable link underlined in primary color)
```

**Validation:**
- Client-side check prevents API call if terms not accepted
- Shows SnackBar error: "You must accept the Terms of Service to create an account"
- Backend validates as secondary safety measure

---

### 5. API Service Updates
**File:** [frontend/lib/services/api_service.dart](frontend/lib/services/api_service.dart#L165-L180)

**Changes:**
- Added `termsAccepted` boolean parameter to `register()` method
- Default value: `false`
- Sends `termsAccepted` field to backend API

---

### 6. Auth Provider Updates
**File:** [frontend/lib/providers/auth_provider.dart](frontend/lib/providers/auth_provider.dart#L84-L102)

**Changes:**
- Added `termsAccepted` boolean parameter to `register()` method
- Passes parameter through to API service
- Default value: `false`

---

## User Flow

### Registration with Terms Acceptance

1. User navigates to registration screen
2. User fills in: First Name, Last Name, Email, Password, Confirm Password
3. User must check "I agree to the Terms of Service" checkbox
4. User can click "Terms of Service" link to view full terms in dedicated screen
5. If user attempts to register without accepting:
   - Client shows error: "You must accept the Terms of Service to create an account"
   - Registration is blocked
6. When checkbox is checked and form is valid:
   - API call includes `termsAccepted: true`
   - Backend validates and stores acceptance timestamp + version
   - User record includes: `termsAcceptedAt` and `termsAcceptedVersion`

---

## Data Stored Per User

When a user registers and accepts terms, the following is stored in DynamoDB:

```json
{
  "userId": "uuid",
  "email": "user@example.com",
  "firstName": "John",
  "lastName": "Doe",
  "passwordHash": "hashed_password",
  "language": "en",
  "createdAt": "2025-12-12T10:00:00.000Z",
  "termsAcceptedAt": "2025-12-12T10:00:00.000Z",
  "termsAcceptedVersion": "1.0.0",
  "isActive": true
}
```

---

## Future Enhancements

### Handling Terms Updates

When terms are updated in the future:

1. **Update Version Number:**
   - Increment version in [TERMS_OF_SERVICE.md](TERMS_OF_SERVICE.md)
   - Update version in backend registration (currently "1.0.0")

2. **Detect Outdated Acceptance:**
   - Compare user's `termsAcceptedVersion` with current version
   - Prompt users with old versions to review and accept new terms

3. **Re-acceptance Flow:**
   - Create middleware to check terms version on protected routes
   - Redirect users to terms acceptance screen if outdated
   - Update `termsAcceptedAt` and `termsAcceptedVersion` after acceptance

### Suggested Implementation:
```javascript
// Backend middleware
function requireCurrentTerms(req, res, next) {
  const CURRENT_VERSION = '1.0.0';
  if (req.user.termsAcceptedVersion !== CURRENT_VERSION) {
    return res.status(403).json({
      error: 'Terms acceptance required',
      message: 'Please accept the updated Terms of Service',
      currentVersion: CURRENT_VERSION,
      userVersion: req.user.termsAcceptedVersion
    });
  }
  next();
}
```

---

## Testing Checklist

- [ ] Verify registration fails when terms checkbox is unchecked
- [ ] Verify registration succeeds when terms checkbox is checked
- [ ] Verify "Terms of Service" link opens full terms screen
- [ ] Verify terms screen displays all sections correctly
- [ ] Verify terms screen is scrollable on mobile devices
- [ ] Verify database stores `termsAcceptedAt` timestamp
- [ ] Verify database stores `termsAcceptedVersion` as "1.0.0"
- [ ] Verify backend returns 400 error if `termsAccepted` is false
- [ ] Verify client shows appropriate error messages

---

## Compliance Notes

This implementation provides:
- ✅ Explicit user consent before account creation
- ✅ Clear presentation of terms before acceptance
- ✅ Audit trail with acceptance timestamps
- ✅ Version tracking for future terms updates
- ✅ Cannot proceed without acceptance (mandatory)

---

## Files Modified

### Backend
1. [backend/src/database/schema.js](backend/src/database/schema.js) - Added consent fields
2. [backend/src/routes/auth.js](backend/src/routes/auth.js) - Added validation and storage

### Frontend
1. [frontend/lib/screens/auth/register_screen.dart](frontend/lib/screens/auth/register_screen.dart) - Added UI and validation
2. [frontend/lib/screens/auth/terms_of_service_screen.dart](frontend/lib/screens/auth/terms_of_service_screen.dart) - New screen
3. [frontend/lib/services/api_service.dart](frontend/lib/services/api_service.dart) - Added parameter
4. [frontend/lib/providers/auth_provider.dart](frontend/lib/providers/auth_provider.dart) - Added parameter

### Documentation
1. [TERMS_OF_SERVICE.md](TERMS_OF_SERVICE.md) - Terms document
2. [TERMS_IMPLEMENTATION.md](TERMS_IMPLEMENTATION.md) - This file

---

## Support Contact

For questions about Terms of Service implementation:
- Technical: See code files listed above
- Legal/Content: support@wecounsel.com
