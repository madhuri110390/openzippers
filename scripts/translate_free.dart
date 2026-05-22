
import 'dart:convert';
import 'dart:io';
import 'package:translator/translator.dart';

// Supported Languages and their mappings to Google Translate codes
const Map<String, String> languages = {
  'es': 'es', 'fr': 'fr', 'de': 'de', 'it': 'it', 'pt': 'pt',
  'ru': 'ru', 'zh': 'zh-cn', 'zh_Hant': 'zh-tw', 'ja': 'ja', 'ko': 'ko',
  'hi': 'hi', 'ar': 'ar', 'th': 'th', 'vi': 'vi', 'nl': 'nl',
  'sv': 'sv', 'no': 'no', 'da': 'da', 'fi': 'fi', 'pl': 'pl',
  'cs': 'cs', 'hu': 'hu', 'ro': 'ro', 'el': 'el', 'tr': 'tr',
  'id': 'id', 'ms': 'ms', 'fil': 'tl', 'sw': 'sw', 'ur': 'ur', 'bn': 'bn'
};

Future<void> main(List<String> args) async {
  final translator = GoogleTranslator();
  final sourceFile = File('lib/l10n/app_en.arb');

  if (!sourceFile.existsSync()) {
    print('Error: Source file lib/l10n/app_en.arb not found.');
    return;
  }

  print('Reading source English file...');
  final Map<String, dynamic> sourceData = jsonDecode(sourceFile.readAsStringSync());

  // Check if user wants to translate a specific language
  String? specificLang;
  if (args.isNotEmpty) {
    specificLang = args[0];
    if (!languages.containsKey(specificLang) && specificLang != 'all') {
       if (!languages.keys.contains(specificLang)) {
         print('Warning: Language code "$specificLang" not found in predefined list. Using it directly.');
       }
    }
  }

  final targets = specificLang != null && specificLang != 'all' 
      ? [specificLang] 
      : languages.keys.toList();

  print('Starting translation for ${targets.length} languages...');

  print('Starting translation for ${targets.length} languages (PARALLEL MODE)...');

  // Limit concurrency to avoid total system or network overload
  // Process languages in chunks of 5
  int langBatchSize = 5;
  for (var i = 0; i < targets.length; i += langBatchSize) {
    var end = (i + langBatchSize < targets.length) ? i + langBatchSize : targets.length;
    var langBatch = targets.sublist(i, end);
    
    print('Processing parallel batch: $langBatch');

    await Future.wait(langBatch.map((langCode) async {
       final googleLangCode = languages[langCode] ?? langCode; 
       final targetFile = File('lib/l10n/app_$langCode.arb');
       Map<String, dynamic> targetData = {};

       if (targetFile.existsSync()) {
         try {
           targetData = jsonDecode(targetFile.readAsStringSync());
         } catch (e) {
           print('Error reading $langCode file, starting fresh.');
         }
       }

       final missingKeys = <String>[];
       for (final key in sourceData.keys) {
         if (key.startsWith('@')) continue; 
         
         final sourceValue = sourceData[key].toString();
         final targetValue = targetData[key]?.toString();

         bool isFAQPlaceholder = false;
         if (key.startsWith('faqQ') || key.startsWith('faqA')) {
           if (targetValue != null) {
             final faqLower = targetValue.toLowerCase().trim();
             final faqTranslation = (targetData['faq'] ?? 'FAQ').toString().toLowerCase().trim();
             final keyNum = key.replaceAll(RegExp(r'[^0-9]'), '');
             
             final patterns = [
               'faq$keyNum', 'faqq$keyNum', 'faqa$keyNum',
               'faq $keyNum', 'faqq $keyNum', 'faqa $keyNum',
               '$faqTranslation$keyNum', '${faqTranslation}q$keyNum', '${faqTranslation}a$keyNum', '${faqTranslation}p$keyNum',
               '$faqTranslation $keyNum', '$faqTranslation q$keyNum', '$faqTranslation a$keyNum', '$faqTranslation p$keyNum'
             ];

             if (patterns.any((p) => faqLower == p.toLowerCase())) {
               isFAQPlaceholder = true;
             }
           }
         }

         if (targetValue == null || targetValue.isEmpty || (targetValue == sourceValue && sourceValue.length > 3) || targetValue == key || isFAQPlaceholder) {
           missingKeys.add(key);
         }
       }

       if (missingKeys.isEmpty) {
         print('[$langCode] All keys present. Skipping.');
         return;
       }
       
       print('[$langCode] Translating ${missingKeys.length} keys...');

       // Process items in chunks for this language
       int itemBatchSize = 10;
       for (var j = 0; j < missingKeys.length; j += itemBatchSize) {
         var itemEnd = (j + itemBatchSize < missingKeys.length) ? j + itemBatchSize : missingKeys.length;
         var batch = missingKeys.sublist(j, itemEnd);
         
         try {
             await Future.wait(batch.map((key) async {
             final sourceText = sourceData[key] as String;
             try {
                // Preserve placeholders like {count}, {name}, etc.
                final placeholders = <String>[];
                final placeholderRegex = RegExp(r'\{[a-zA-Z0-9_]+\}');
                
                var tempText = sourceText;
                var match = placeholderRegex.firstMatch(tempText);
                int placeholderIndex = 0;
                
                while (match != null) {
                  placeholders.add(match.group(0)!);
                  tempText = tempText.replaceFirst(match.group(0)!, 'PH$placeholderIndex');
                  placeholderIndex++;
                  match = placeholderRegex.firstMatch(tempText);
                }

                // Use a new instance per language/call to avoid any shared state issues
                var translatedObj = await GoogleTranslator().translate(tempText, from: 'en', to: googleLangCode);
                var translatedText = translatedObj.text;
                
                // Restore placeholders
                for (var i = 0; i < placeholders.length; i++) {
                   // Case insensitive replace because translation might change case of 'PH0' to 'Ph0' or 'ph0'
                   translatedText = translatedText.replaceAll(RegExp('PH$i', caseSensitive: false), placeholders[i]);
                   // Also handle potential spacing introduced
                   translatedText = translatedText.replaceAll(RegExp('PH $i', caseSensitive: false), placeholders[i]);
                }
                
                targetData[key] = translatedText;
             } catch (e) {
                // Silent error in parallel to avoid log noise
             }
           }));
         } catch (e) { }
       }
       
       print('[$langCode] Finished.');

       // Sort and Save
       final sortedData = <String, dynamic>{};
       if (!targetData.containsKey('@@locale')) {
         sortedData['@@locale'] = langCode;
       }
       
       for (final key in sourceData.keys) {
         if (targetData.containsKey(key)) {
           sortedData[key] = targetData[key];
         }
       }

       const encoder = JsonEncoder.withIndent('  ');
       targetFile.writeAsStringSync(encoder.convert(sortedData));
    }));
  }

  print('All translations completed successfully!');
}
