#!/bin/bash

# Complete Localization Fix Script
# This runs all necessary commands to ensure app-wide localization

echo "🌍 OpenZippers - Complete Localization Fix"
echo "=========================================="
echo ""

echo "📝 Step 1/5: Fixing placeholder syntax in ARB files..."
dart run scripts/fix_placeholders.dart
if [ $? -ne 0 ]; then
    echo "❌ Placeholder fix failed!"
    exit 1
fi
echo "✅ Placeholders fixed"
echo ""

echo "📝 Step 2/5: Syncing translations to all 31 languages..."
python3 generate_l10n.py
if [ $? -ne 0 ]; then
    echo "❌ Translation sync failed!"
    exit 1
fi
echo "✅ Translations synced"
echo ""

echo "📝 Step 3/5: Generating Dart localization files..."
flutter gen-l10n
if [ $? -ne 0 ]; then
    echo "❌ Dart generation failed!"
    exit 1
fi
echo "✅ Dart files generated"
echo ""

echo "📝 Step 4/5: Checking for missing translations..."
python3 scripts/check_missing_translations.py
echo ""

echo "📝 Step 5/5: Scanning for hardcoded strings..."
dart run scripts/find_hardcoded_strings.dart
echo ""

echo "=========================================="
echo "✅ Localization workflow complete!"
echo ""
echo "💡 Next steps:"
echo "   1. Review any warnings above"
echo "   2. Run: flutter run"
echo "   3. Test language switching in Settings"
echo ""
