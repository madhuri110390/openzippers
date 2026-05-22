
import 'dart:convert';
import 'dart:io';
import 'package:translator/translator.dart';

// Final batch of languages
const Map<String, String> languages = {
  'id': 'id', 'ms': 'ms', 'fil': 'tl', 'sw': 'sw', 'ur': 'ur', 'bn': 'bn'
};

Future<void> main(List<String> args) async {
  final translator = GoogleTranslator();
  final sourceFile = File('lib/l10n/app_en.arb');
  final sourceData = jsonDecode(sourceFile.readAsStringSync()) as Map<String, dynamic>;
  
  final targets = languages.keys.toList();
  print('Starting FINAL batch translation for ${targets.length} languages...');

  // Process all at once since it's small list (6)
  await Future.wait(targets.map((langCode) async {
     print('[$langCode] Starting...');
     final googleLangCode = languages[langCode] ?? langCode; 
     final targetFile = File('lib/l10n/app_$langCode.arb');
     Map<String, dynamic> targetData = {};

     if (targetFile.existsSync()) {
       try { targetData = jsonDecode(targetFile.readAsStringSync()); } catch (e) {}
     }

     final missingKeys = <String>[];
     for (final key in sourceData.keys) {
       if (key.startsWith('@')) continue; 
       final sourceValue = sourceData[key].toString();
       final targetValue = targetData[key]?.toString();
       if (targetValue == null || targetValue.isEmpty || (targetValue == sourceValue && sourceValue.length > 3)) {
         missingKeys.add(key);
       }
     }

     if (missingKeys.isEmpty) {
       print('[$langCode] All keys present.');
       return;
     }
     
     print('[$langCode] Translating ${missingKeys.length} keys...');

     int itemBatchSize = 10;
     for (var j = 0; j < missingKeys.length; j += itemBatchSize) {
       var itemEnd = (j + itemBatchSize < missingKeys.length) ? j + itemBatchSize : missingKeys.length;
       var batch = missingKeys.sublist(j, itemEnd);
       try {
           await Future.wait(batch.map((key) async {
           final sourceText = sourceData[key] as String;
           try {
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

              var translatedObj = await GoogleTranslator().translate(tempText, from: 'en', to: googleLangCode);
              var translatedText = translatedObj.text;
              for (var i = 0; i < placeholders.length; i++) {
                 translatedText = translatedText.replaceAll(RegExp('PH$i', caseSensitive: false), placeholders[i]);
                 translatedText = translatedText.replaceAll(RegExp('PH $i', caseSensitive: false), placeholders[i]);
              }
              targetData[key] = translatedText;
           } catch (e) {}
         }));
       } catch (e) { }
     }
     
     // Save
     final sortedData = <String, dynamic>{};
     if (!targetData.containsKey('@@locale')) sortedData['@@locale'] = langCode;
     for (final key in sourceData.keys) {
       if (targetData.containsKey(key)) sortedData[key] = targetData[key];
     }
     const encoder = JsonEncoder.withIndent('  ');
     targetFile.writeAsStringSync(encoder.convert(sortedData));
     print('[$langCode] Finished.');
  }));

  print('Final batch completed!');
}
