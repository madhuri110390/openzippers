#!/usr/bin/env python3
"""
Script to check which translation keys are missing in non-English ARB files
Run: python3 scripts/check_missing_translations.py
"""

import json
import os
from pathlib import Path

def main():
    l10n_dir = Path('lib/l10n')
    
    # Load English template (the source of truth)
    en_file = l10n_dir / 'app_en.arb'
    if not en_file.exists():
        print(f"❌ English template not found: {en_file}")
        return
    
    with open(en_file, 'r', encoding='utf-8') as f:
        en_data = json.load(f)
    
    # Get all translation keys (ignore metadata keys starting with @)
    en_keys = {k for k in en_data.keys() if not k.startswith('@') and k != '@@locale'}
    
    print(f"📚 English template has {len(en_keys)} translation keys\n")
    
    # Check all other ARB files
    arb_files = list(l10n_dir.glob('app_*.arb'))
    arb_files = [f for f in arb_files if f.name != 'app_en.arb']
    
    all_complete = True
    
    for arb_file in sorted(arb_files):
        lang_code = arb_file.stem.replace('app_', '')
        
        with open(arb_file, 'r', encoding='utf-8') as f:
            lang_data = json.load(f)
        
        lang_keys = {k for k in lang_data.keys() if not k.startswith('@') and k != '@@locale'}
        missing_keys = en_keys - lang_keys
        extra_keys = lang_keys - en_keys
        
        if missing_keys or extra_keys:
            all_complete = False
            print(f"⚠️  Language: {lang_code}")
            
            if missing_keys:
                print(f"   Missing {len(missing_keys)} keys:")
                for key in sorted(list(missing_keys)[:10]):  # Show first 10
                    print(f"      - {key}")
                if len(missing_keys) > 10:
                    print(f"      ... and {len(missing_keys) - 10} more")
            
            if extra_keys:
                print(f"   Extra {len(extra_keys)} keys (not in English):")
                for key in sorted(list(extra_keys)[:5]):
                    print(f"      - {key}")
            print()
    
    if all_complete:
        print("✅ All language files are complete!")
    else:
        print("\n💡 Run: python3 generate_l10n.py to sync translations")
        print("💡 Then run: flutter gen-l10n to regenerate Dart files")

if __name__ == '__main__':
    main()
