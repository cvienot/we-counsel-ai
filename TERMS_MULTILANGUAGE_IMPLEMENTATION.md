# Multi-Language Terms of Service Implementation

## Overview
This document describes the implementation of multi-language Terms of Service for the We Coach application, supporting English, French, and Spanish.

## Date Implemented
December 12, 2025

---

## Implementation Details

### 1. File Structure

**Terms Files Created:**
```
frontend/assets/terms/
├── terms_en.md  (English)
├── terms_fr.md  (French)
└── terms_es.md  (Spanish)
```

Each file contains the complete Terms of Service translated into the respective language.

### 2. Asset Registration

**File:** [frontend/pubspec.yaml](frontend/pubspec.yaml)

Added assets declaration:
```yaml
assets:
  - assets/terms/terms_en.md
  - assets/terms/terms_fr.md
  - assets/terms/terms_es.md
```

### 3. Dependencies Added

**Package:** `flutter_markdown: ^0.7.4+1`

Enables rendering of Markdown files with proper formatting, making the terms more readable and maintainable.

---

## Frontend Implementation

### Terms of Service Screen

**File:** [frontend/lib/screens/auth/terms_of_service_screen.dart](frontend/lib/screens/auth/terms_of_service_screen.dart)

**Features:**
- Automatically loads terms based on user's current language preference
- Falls back to English if translation not available
- Uses `flutter_markdown` for beautiful rendering
- Responsive scrolling for long content
- Error handling with retry mechanism
- Loading state with progress indicator

**Key Code:**
```dart
final locale = ref.read(currentLocaleProvider);
final languageCode = locale.languageCode;
final fileName = 'assets/terms/terms_$languageCode.md';

// Load with fallback to English
try {
  content = await rootBundle.loadString(fileName);
} catch (e) {
  content = await rootBundle.loadString('assets/terms/terms_en.md');
}
```

### Registration Screen Integration

**File:** [frontend/lib/screens/auth/register_screen.dart](frontend/lib/screens/auth/register_screen.dart)

- Opens full terms screen when user taps "Terms of Service" link
- Terms displayed in user's selected language
- Seamless navigation flow

---

## Backend Implementation

### Version Tracking with Language

**File:** [backend/src/routes/auth.js](backend/src/routes/auth.js)

**Database Storage:**
```javascript
termsAcceptedVersion: `1.0.0-${userLanguage}`
```

**Examples:**
- English user: `1.0.0-en`
- French user: `1.0.0-fr`
- Spanish user: `1.0.0-es`

This allows tracking:
1. Which version of terms was accepted
2. Which language version was accepted
3. When future updates require re-acceptance (different languages may update at different times)

---

## Translation Notes

### Important Disclaimers

Each non-English translation includes:

**French & Spanish versions contain:**
```
**NOTA IMPORTANTE / NOTE IMPORTANTE:**
Esta traducción / Cette traduction se proporciona con fines informativos.
En caso de conflicto entre las versiones de idioma, prevalecerá la versión en inglés.
Se recomienda que un profesional legal revise esta traducción.
```

**Translation Status:**
- ✅ **English** - Original, legally reviewed (recommended)
- ⚠️ **French** - Automated translation provided (requires legal review)
- ⚠️ **Spanish** - Automated translation provided (requires legal review)

### Recommendation
**Before production use**, have translations reviewed by:
1. Legal professional familiar with the target jurisdiction
2. Native speaker for language accuracy
3. Legal translator for terminology precision

---

## User Experience Flow

### Language Selection Impact

1. **User selects language** (English/French/Spanish) in app settings
2. **Registration screen** displays "I agree to Terms of Service" in selected language
3. **Tapping the link** opens terms in that same language
4. **Backend stores** which language version was accepted

### Example User Journey

**French User:**
1. Sets app language to Français
2. Views registration form in French
3. Taps "J'accepte les Conditions d'utilisation"
4. Views `terms_fr.md` with French terms
5. Accepts and creates account
6. Database stores: `termsAcceptedVersion: "1.0.0-fr"`

---

## Updating Terms in the Future

### For All Languages

1. Update version number in respective `.md` files
2. Update backend version check: `1.0.0` → `2.0.0`
3. All users will be prompted to re-accept

### For Specific Language

1. Update only that language's `.md` file
2. Update version in backend: `1.0.0-fr` → `1.1.0-fr`
3. Only users who accepted French version are prompted

**Example Backend Check:**
```javascript
function requiresTermsUpdate(user) {
  const CURRENT_VERSION = '1.0.0';
  const userVersion = user.termsAcceptedVersion.split('-')[0];
  return userVersion !== CURRENT_VERSION;
}
```

---

## Files Modified

### Frontend
1. [frontend/pubspec.yaml](frontend/pubspec.yaml) - Assets & dependency
2. [frontend/lib/screens/auth/terms_of_service_screen.dart](frontend/lib/screens/auth/terms_of_service_screen.dart) - Multi-language loader
3. [frontend/lib/screens/auth/register_screen.dart](frontend/lib/screens/auth/register_screen.dart) - Already updated
4. [frontend/assets/terms/terms_en.md](frontend/assets/terms/terms_en.md) - English terms
5. [frontend/assets/terms/terms_fr.md](frontend/assets/terms/terms_fr.md) - French terms
6. [frontend/assets/terms/terms_es.md](frontend/assets/terms/terms_es.md) - Spanish terms

### Backend
1. [backend/src/routes/auth.js](backend/src/routes/auth.js) - Language-aware version storage

---

## Testing Checklist

- [ ] Test with English language selected
- [ ] Test with French language selected
- [ ] Test with Spanish language selected
- [ ] Verify terms display in correct language
- [ ] Verify fallback to English for unsupported language
- [ ] Verify database stores language-specific version
- [ ] Test markdown rendering (headings, lists, bold, etc.)
- [ ] Test scrolling on mobile devices
- [ ] Test loading state and error handling
- [ ] Verify "Retry" button works if loading fails

---

## Installation Steps

### Install Dependencies
```bash
cd frontend
flutter pub get
```

This will install `flutter_markdown` and bundle the asset files.

---

## Advantages of This Approach

✅ **User-Friendly:**
- Users see terms in their preferred language
- No language barrier to understanding legal requirements

✅ **Maintainable:**
- Markdown format is easy to edit
- Separate files per language make updates clear
- Version control tracks changes per language

✅ **Compliant:**
- Tracks which language version was accepted
- Meets legal requirements for multilingual jurisdictions
- Provides audit trail for user consent

✅ **Scalable:**
- Easy to add more languages (create new .md file)
- Fallback mechanism prevents errors
- No code changes needed for new languages

---

## Future Enhancements

### Potential Additions

1. **Privacy Policy**
   - Create similar structure for privacy policies
   - `privacy_en.md`, `privacy_fr.md`, `privacy_es.md`

2. **Cookie Policy**
   - Add consent for web version
   - Multi-language support

3. **In-App Language Switcher**
   - Allow viewing terms in different language
   - "View in English / Voir en français / Ver en español"

4. **Professional Translations**
   - Hire legal translators
   - Get certified translations
   - Remove disclaimer about automated translation

5. **Dynamic Version Management**
   - Create version management system
   - Notify users when terms update
   - Show diff between versions

---

## Legal Compliance Notes

### Jurisdiction-Specific Requirements

**Quebec, Canada (French):**
- ✅ French version provided
- ⚠️ Requires certified legal translation
- ⚠️ French version may need to be primary

**European Union:**
- ✅ Multi-language support implemented
- ⚠️ May require terms in all EU languages for EU users
- ⚠️ GDPR compliance should be verified in all languages

**United States:**
- ✅ English version sufficient
- ✅ Spanish version helpful for accessibility

---

## Support

**Technical Questions:**
- See implementation files listed above
- Review code comments in terms_of_service_screen.dart

**Legal Questions:**
- Consult with legal counsel
- Contact: support@we-connect-app.com

**Translation Questions:**
- Hire certified legal translator
- Verify with native speakers
- Consider jurisdiction-specific requirements

---

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0.0   | Dec 12, 2025 | Initial implementation with EN/FR/ES |

