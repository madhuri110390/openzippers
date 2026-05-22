---
description: Complete workflow to ensure app-wide localization
---

# Complete Localization Workflow for OpenZippers

This workflow ensures that every screen in your app uses proper localization.

## 🎯 Goal
Replace all hardcoded English strings with localized versions that work across all 31 supported languages.

---

## 📋 Step-by-Step Process

### Step 1: Add Missing Translation Keys
If you find a hardcoded string in your code, first add it to the English template:

**File:** `lib/l10n/app_en.arb`

```json
{
  "yourNewKey": "Your English Text",
  "searchUsers": "Search Users",
  "connections": "Connections"
}
```

### Step 2: Fix Placeholder Issues
// turbo
Run the placeholder fixer to ensure all translations have proper placeholder syntax:

```bash
dart run scripts/fix_placeholders.dart
```

### Step 3: Generate Translations for All Languages
// turbo
Run the Python script to copy translations to all 31 language files:

```bash
python3 generate_l10n.py
```

### Step 4: Generate Dart Localization Files
// turbo
Generate the Dart files that your app uses:

```bash
flutter gen-l10n
```

### Step 5: Verify All Files Are Synced
// turbo
Check if any translations are missing:

```bash
python3 scripts/check_missing_translations.py
```

### Step 6: Find Hardcoded Strings in Code
// turbo
Scan your Dart files for hardcoded strings:

```bash
dart run scripts/find_hardcoded_strings.dart
```

---

## 🔧 How to Use Localization in Code

### Import the helper
```dart
import '../helpers/translations.dart';
```

### Use in your widgets
```dart
// ❌ BAD - Hardcoded
Text('Search Users')

// ✅ GOOD - Localized
Text(context.tr.searchUsers)

// ✅ GOOD - With parameters
Text(context.tr.subscribedTo(userName))
```

### Common patterns
```dart
// AppBar title
AppBar(
  title: Text(context.tr.settings),
)

// Button text
ElevatedButton(
  onPressed: () {},
  child: Text(context.tr.save),
)

// TextField hint
TextField(
  decoration: InputDecoration(
    hintText: context.tr.searchPlaceholder,
  ),
)

// Dialog title
AlertDialog(
  title: Text(context.tr.deletePost),
  content: Text(context.tr.deletePostConfirm),
)
```

---

## 🌍 Supported Languages (31 Total)

- English (en)
- Spanish (es)
- French (fr)
- German (de)
- Italian (it)
- Portuguese (pt)
- Russian (ru)
- Chinese Simplified (zh)
- Chinese Traditional (zh_Hant)
- Japanese (ja)
- Korean (ko)
- Hindi (hi)
- Arabic (ar)
- Thai (th)
- Vietnamese (vi)
- Dutch (nl)
- Swedish (sv)
- Norwegian (no)
- Danish (da)
- Finnish (fi)
- Polish (pl)
- Czech (cs)
- Hungarian (hu)
- Romanian (ro)
- Greek (el)
- Turkish (tr)
- Indonesian (id)
- Malay (ms)
- Filipino (fil)
- Swahili (sw)
- Urdu (ur)
- Bengali (bn)

---

## 🔍 Common Issues & Solutions

### Issue: Text still shows in English when language is changed
**Solution:** Make sure you're using `context.tr.keyName` not hardcoded strings

### Issue: Missing translation error
**Solution:** Run all steps 1-4 above to regenerate translations

### Issue: Placeholder error in ARB file
**Solution:** Run `dart run scripts/fix_placeholders.dart`

### Issue: New key not appearing in other languages
**Solution:** Run `python3 generate_l10n.py` then `flutter gen-l10n`

---

## 📝 Adding a New Screen Checklist

When creating a new screen:

- [ ] Import translations: `import '../helpers/translations.dart';`
- [ ] Use `context.tr.keyName` for all text
- [ ] Add any new keys to `app_en.arb`
- [ ] Run the 4-step generation process (Steps 2-5)
- [ ] Test with `flutter run`
- [ ] Change language in app to verify all text changes

---

## 🚀 Quick Commands (Run in Order)

```bash
# 1. Fix placeholders
dart run scripts/fix_placeholders.dart

# 2. Sync all languages
python3 generate_l10n.py

# 3. Generate Dart files
flutter gen-l10n

# 4. Verify completeness
python3 scripts/check_missing_translations.py

# 5. Find hardcoded strings
dart run scripts/find_hardcoded_strings.dart

# 6. Build and test
flutter run
```

---

## 📖 Example: Localizing a Screen

**Before (Hardcoded):**
```dart
class MyScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Settings')),
      body: Column(
        children: [
          Text('Welcome'),
          ElevatedButton(
            onPressed: () {},
            child: Text('Save'),
          ),
        ],
      ),
    );
  }
}
```

**After (Localized):**
```dart
import '../helpers/translations.dart';

class MyScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.tr.settings)),
      body: Column(
        children: [
          Text(context.tr.welcomeProfile),
          ElevatedButton(
            onPressed: () {},
            child: Text(context.tr.save),
          ),
        ],
      ),
    );
  }
}
```

---

## ✅ Final Verification

After making changes, verify localization works:

1. Run the app: `flutter run`
2. Go to Settings → Language
3. Change to Hindi (or any other language)
4. Navigate through all screens
5. Verify all text changes to the selected language
6. If any text remains in English, that screen needs to be localized

---

**Last Updated:** 2026-02-09
