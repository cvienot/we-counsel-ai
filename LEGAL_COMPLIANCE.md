# Legal Compliance Updates - Relationship Coach vs. Therapy

## Overview
Transitioned the app from "therapy/counseling" language to "relationship coaching/communication support" to comply with mental health regulations in most countries.

## Key Changes Made

### 1. Backend - AI Service (`backend/src/services/aiService.js`)

#### System Prompt Updated
- **Changed from**: "Dr. Sarah, an experienced couples therapist conducting an active therapy session"
- **Changed to**: "Sarah, an AI relationship coach and communication facilitator"

#### Added Disclaimers in Prompt
- Explicitly states: "You are NOT a therapist or mental health professional"
- States service is "relationship communication support and educational guidance only"
- Not a substitute for professional therapy or mental health treatment

#### Crisis Detection System Added
```javascript
// Detects keywords like:
- Suicide/self-harm: "suicide", "kill myself", "self harm", etc.
- Abuse: "abuse", "violent", "hitting", "afraid of", etc.
- Mental health crisis: "panic attack", "can't breathe", "breakdown"
```

#### Crisis Response
When crisis keywords detected, AI immediately responds with:
- Disclaimer that it cannot provide crisis intervention
- Emergency services numbers (112/911)
- Crisis hotlines (suicide prevention, domestic violence, etc.)
- Recommendation to seek professional help

#### Summarization Updated
- Changed from "professional therapist creating summary of counselling session"
- To "relationship communication coach creating summary of couples conversation"

### 2. Backend - Message Routes (`backend/src/routes/messages.js`)
- AI sender name: `Dr. Sarah (AI Coach)` → `Sarah (AI Relationship Coach)`

### 3. Backend - Subscription Service (`backend/src/services/subscriptionService.js`)
- Feature descriptions:
  - `AI coach messages` → `AI relationship coach messages`
  - Updated for all 3 tiers (free, essential, premium)

### 4. Backend - Mock AI Service (`backend/src/services/__mocks__/aiService.js`)
- Updated mock responses to use "AI relationship coach" language
- Maintains consistency with real AI service for testing

### 5. Frontend - Plan Selection (`frontend/lib/screens/plan_selection_screen.dart`)
- Description: `Try the AI coach` → `Try the AI relationship coach`

### 6. Frontend - Terms of Service (`frontend/lib/screens/auth/terms_of_service_screen.dart`)

#### Section 2 Updated - Description of Service
Added prominent warning:
```
⚠️ THIS SERVICE IS NOT THERAPY: We Coach provides communication 
support and educational guidance only. It is not a substitute for 
professional therapy, counseling, or mental health treatment.
```

#### Section 7 Completely Rewritten - AI Features
**New title**: "AI Relationship Coaching Features" (was "AI Coaching Features")

**Added 5 comprehensive disclaimer subsections**:

1. **Not Therapy or Mental Health Treatment**
   - AI is NOT therapy, counseling, or treatment
   - AI is not a licensed professional
   - For informational/educational purposes only

2. **No Substitute for Professional Help**
   - List of situations requiring licensed professionals:
     - Mental health concerns (depression, anxiety, trauma)
     - Relationship crises
     - Abuse, violence, safety concerns
     - Suicidal thoughts or self-harm

3. **Crisis Situations**
   - Emergency numbers (112/911)
   - Crisis hotlines
   - AI cannot provide crisis intervention

4. **Accuracy and Reliability**
   - No guarantee of AI accuracy
   - May contain errors or inappropriate suggestions
   - Use at own risk

5. **Professional Consultation**
   - Always consult licensed professionals for serious issues
   - Service supports communication, not replaces guidance

### 7. Frontend - New Disclaimer Widget (`frontend/lib/widgets/disclaimer_banner.dart`)

#### DisclaimerBanner Widget
- Yellow/amber information banner
- Shows at top of conversation screen
- Key message: "This AI provides relationship communication support only. It is not therapy or a substitute for professional mental health services."
- Dismissible by user

#### CrisisAlertDialog Widget
- Emergency dialog accessible from conversation screen
- Lists emergency resources:
  - Emergency services (112/911)
  - 24/7 crisis hotlines (US, UK, International)
  - Suicide prevention, domestic violence hotlines
- Emphasizes app is communication support only

### 8. Frontend - Registration Screen (`frontend/lib/screens/auth/register_screen.dart`)

**Added prominent disclaimer box** above terms checkbox:
```
ℹ️ This service provides relationship communication support only. 
It is NOT therapy or a substitute for professional mental health services.
```

### 9. Frontend - Conversation Screen (`frontend/lib/screens/conversations/conversation_screen.dart`)

**Two additions**:
1. **Disclaimer Banner**: Shows when conversation is empty
2. **Crisis Resources Button**: Health icon in app bar
   - Opens crisis resources dialog
   - Always accessible during conversations

## Legal Positioning

### What We Now Say ✅
- "Relationship communication support"
- "AI relationship coach"
- "Communication facilitator"
- "Educational guidance"
- "Communication exercises"

### What We Avoid ❌
- "Therapy" or "therapist"
- "Counseling" or "counselor" (minimized)
- "Mental health treatment"
- "Clinical services"
- "Medical advice"

## Crisis Safety Features

### Automatic Detection
- Backend AI service scans every message for crisis keywords
- Immediate response with professional resources
- Prevents AI from attempting crisis intervention

### User-Initiated Help
- Crisis resources button always visible in conversation
- Provides comprehensive emergency contact information
- Clear disclaimer about app limitations

### Professional Referral
- All crisis responses encourage seeking licensed help
- Provides specific hotlines and emergency numbers
- International coverage (US, UK, EU)

## Regulatory Compliance

### Countries Addressed
These changes help comply with regulations in:
- **United States**: Unlicensed practice laws, state medical boards
- **European Union**: GDPR health data, mental health regulations
- **United Kingdom**: Professional standards for therapy
- **Australia/Canada**: Mental health service regulations

### Key Protections
1. **Clear disclaimers** - Users know it's not therapy
2. **Crisis detection** - Dangerous situations trigger professional resources
3. **Scope limitation** - AI constrained to communication support only
4. **Professional referral** - Encourages seeking licensed help when needed

## Testing Impact

### E2E Tests
- Mock AI service updated with new language
- Tests continue to pass
- Crisis detection not triggered in normal test scenarios

### User Experience
- Slightly more prominent disclaimers
- Crisis resources easily accessible
- Core functionality unchanged

## Recommendations for Going Forward

### Before Launch
1. **Legal review**: Have attorney review terms and disclaimers
2. **Insurance**: Consider professional liability insurance
3. **User testing**: Ensure disclaimers are clear but not alarming

### Marketing Language
- Emphasize "relationship communication tool"
- Highlight "AI-powered conversation support"
- Avoid therapy/counseling claims
- Focus on couples communication improvement

### Future Considerations
1. **Licensed oversight option**: Allow users to connect with licensed therapists
2. **Geographic restrictions**: May need to restrict service in certain jurisdictions
3. **Professional network**: Partner with licensed therapists for referrals
4. **Enhanced crisis detection**: Expand keyword list, add sentiment analysis

## Documentation Updated
- ✅ AI system prompt
- ✅ Terms of service
- ✅ Feature descriptions
- ✅ UI labels and text
- ✅ Crisis resources
- ✅ User disclaimers

## Files Modified (15 total)
1. `backend/src/services/aiService.js` - Main AI service
2. `backend/src/services/__mocks__/aiService.js` - Mock AI for testing
3. `backend/src/services/subscriptionService.js` - Subscription features
4. `backend/src/routes/messages.js` - AI sender name
5. `frontend/lib/screens/auth/terms_of_service_screen.dart` - Legal terms
6. `frontend/lib/screens/auth/register_screen.dart` - Registration disclaimer
7. `frontend/lib/screens/conversations/conversation_screen.dart` - Conversation disclaimers
8. `frontend/lib/screens/plan_selection_screen.dart` - Subscription descriptions
9. `frontend/lib/widgets/disclaimer_banner.dart` - NEW: Disclaimer widgets

## Summary

The app now clearly positions itself as a **relationship communication support tool** rather than therapy. This reduces legal risk while maintaining the core value proposition. Users receive clear disclaimers at multiple touchpoints, crisis situations are detected and handled appropriately, and the service encourages professional help when needed.

**The app is now much safer to operate legally in most countries.**
