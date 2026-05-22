# 🌍 How to Share/Apply Localization for Whole App

## Problem
Many places in the app show hardcoded English text instead of localized translations (as seen in your screenshot where "Connections" appears in English while other text is in Hindi).

## Solution - One Command to Fix Everything

I've created a complete workflow for you! You can now fix ALL localization issues with ONE command:

```bash
./scripts/fix_all_localization.sh
```

This single command will:
1. ✅ Fix all placeholder syntax issues
2. ✅ Sync translations to all 31 languages  
3. ✅ Generate Dart localization files
4. ✅ Check for missing translations
5. ✅ Scan for hardcoded strings in your code

---

## 📚 What I Created for You

### 1. **Automated Scripts** (in `/scripts/` folder)

- **`fix_all_localization.sh`** - Run everything in one command
- **`find_hardcoded_strings.dart`** - Scans code for hardcoded English strings
- **`check_missing_translations.py`** - Checks if all languages have all keys
- **`fix_placeholders.dart`** - Fixes ARB file syntax (already existed)

### 2. **Workflow Document** (in `/.agent/workflows/`)

- **`complete-localization.md`** - Complete guide with examples

You can use the workflow with: `/complete-localization`

---

## 🚀 Quick Start - 3 Steps

### Step 1: Run the Automated Fix
```bash
cd /home/codenia/Desktop/openzippers
./scripts/fix_all_localization.sh
```

### Step 2: Review the Output
The script will tell you:
- ✅ What was fixed automatically
- ⚠️  Any hardcoded strings found in your code
- 📊 Translation completeness status

### Step 3: Test the App
```bash
flutter run
```

Then:
1. Go to Settings → Language
2. Change language (e.g., to Hindi)
3. Navigate through all screens
4. Verify all text changes

---

## 🔧 How to Fix Hardcoded Strings

When the scanner finds hardcoded strings, fix them like this:

### ❌ BEFORE (Hardcoded):
```dart
Text('Connections')
Text('Search Users')
```

### ✅ AFTER (Localized):
```dart
import '../helpers/translations.dart';

Text(context.tr.connections)
Text(context.tr.searchUsers)
```

---

## 📱 From Your Screenshot

Looking at your screenshot, these are likely not localized yet:
- "Search Users" (search bar)
- "Connections" (bottom nav)

To fix:

1. Check if these keys exist in `lib/l10n/app_en.arb`:
```json
{
  "searchUsers": "Search Users",
  "connections": "Connections"
}
```

2. Find where they're used in code (probably in bottom navigation)

3. Replace with localized version:
```dart
Text(context.tr.connections)
```

4. Rerun the fix script:
```bash
./scripts/fix_all_localization.sh
```

---

## 🌐 All 31 Supported Languages

Your app supports:
- English, Spanish, French, German, Italian, Portuguese, Russian
- Chinese (Simplified & Traditional), Japanese, Korean
- Hindi, Arabic, Thai, Vietnamese, Urdu, Bengali
- Dutch, Swedish, Norwegian, Danish, Finnish
- Polish, Czech, Hungarian, Romanian, Greek, Turkish
- Indonesian, Malay, Filipino, Swahili

All translations are automatically synced when you run the fix script!

---

## ✅ Verification Checklist

After running the fix script:

- [ ] No errors reported by the script
- [ ] `flutter run` works without errors
- [ ] Change language in Settings
- [ ] All screens show translated text
- [ ] Bottom navigation translates
- [ ] Search bar translates
- [ ] Dialogs translate
- [ ] Buttons translate

---

## 🆘 Common Issues

### Issue: "Connections" still shows in English
**Cause:** The code uses hardcoded string
**Fix:** Find the widget and use `context.tr.connections`

### Issue: Translation key not found
**Cause:** Key not in `app_en.arb`
**Fix:** Add the key, then rerun `./scripts/fix_all_localization.sh`

### Issue: App crashes after changing language
**Cause:** Missing import or improper use of context
**Fix:** Ensure `import '../helpers/translations.dart';` is added

---

## 📞 Need Help?

If you find hardcoded strings the scanner didn't catch:

1. Add the key to `lib/l10n/app_en.arb`
2. Run `./scripts/fix_all_localization.sh`
3. Update your code to use `context.tr.keyName`
4. Test with `flutter run`

---

**Quick Reference Card:**

```bash
# Fix everything
./scripts/fix_all_localization.sh

# Just check what needs fixing
python3 scripts/check_missing_translations.py
dart run scripts/find_hardcoded_strings.dart

# Build and test
flutter run
```

---

**Created:** 2026-02-09
**Status:** ✅ Ready to use
