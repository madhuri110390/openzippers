#!/bin/bash
# Auto-translator wrapper for openzippers
# Uses flutter_arb_translator to automatically translate app_en.arb to 31 other languages.

# List of target languages (excluding 'en')
LANGS="es,fr,de,it,pt,ru,zh,zh_Hant,ja,ko,hi,ar,th,vi,nl,sv,no,da,fi,pl,cs,hu,ro,el,tr,id,ms,fil,sw,ur,bn"

# Note: This tool requires a valid API configuration for the selected service.
# Common services: google (Google Cloud), deepl, openai, azure.
# You may be prompted for an API key or need to set environment variables.

echo "Starting Auto-Translation using flutter_arb_translator..."
echo "Source: lib/l10n/app_en.arb"
echo "Targets: $LANGS"

dart run flutter_arb_translator:main \
  --dir lib/l10n \
  --from en \
  --to $LANGS \
  --service google \
  --no-interactive \
  --override # This ensures missing keys are filled

echo "Translation complete. Don't forget to review the changes!"
