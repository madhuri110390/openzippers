
import 'dart:convert';
import 'dart:io';

const Map<String, List<String>> englishPlaceholders = {
  'minutesAgo': ['count'],
  'hoursAgo': ['count'],
  'daysAgo': ['count'],
  'weeksAgo': ['count'],
  'monthsAgo': ['count'],
  'streamLoadError': ['error'],
  'refreshedStreamsFound': ['count'],
  'payToUnlock': ['price'],
  'subscribeToUser': ['name'],
  'listenToArtist': ['name'],
  'successfullyDeposited': ['amount'],
  'removeFromCartConfirm': ['item'],
  'payForAvailableItems': ['count'],
  'payForAvailableItemsPlural': ['count'],
  'blockUserConfirm': ['name'],
  'likeNotification': ['count', 'postTitle'],
  'commentNotification': ['author', 'comment'],
  'replyNotification': ['author', 'comment'],
  'tracksCount': ['count'],
  'albumCreated': ['title'],
  'getCertificateCount': ['count'],
  'publishSelectedCount': ['count'],
  'selectedContentCount': ['count'],
  'createdOn': ['date'],
  'publishedOn': ['date'],
  'filesSelectedCount': ['count'],
  'peopleCount': ['count'],
  'loginAsUser': ['name'],
  'errorSavingPost': ['error'],
  'errorAddingToCart': ['error'],
  'liveStreamsCount': ['count'],
  'refreshedStreams': ['count'],
  'errorLoadingPdf': ['error'],
  'subscribedTo': ['name'],
  'subscribedToYou': ['name'],
  'walletDeposit': ['amount'],
  'walletWithdrawal': ['amount'],
  'uploadFileError': ['fileType'],
  'errorCreatingPost': ['error'],
  'replyToAuthor': ['author'],
  'itemOutOfStock': ['item'],
  'commentsCount': ['count'],
  'errorPostingComment': ['error'],
};

bool localizedMatches(String varName, String inner) {
  inner = inner.trim().toLowerCase();
  if (varName == 'amount' && RegExp(r'^(?:montant|monto|importo|määrä|beløb|مقدار|رقم|مبلغ|mizda|сум|金额|kwota|jumlah|суμμα|金額|राशि|मूल्य|قیمत|قیمत pay)$', caseSensitive: false).hasMatch(inner)) return true;
  if (varName == 'price' && RegExp(r'^(?:prix|precio|prezzo|preis|قیمت|मूल्य|السعر|価格|цена|价格|cena|harga|قیمت pay)$', caseSensitive: false).hasMatch(inner)) return true;
  if (varName == 'count' && RegExp(r'^(?:conteo|número|liczba|jumlah|bilangan|antal|saye|số lượng|गिनती|گنتی|عدد|מסفر|shumë|osób|عدد|गिनती|گنتی|گنتی)$', caseSensitive: false).hasMatch(inner)) return true;
  if (varName == 'name' && RegExp(r'^(?:nom|nombre|nome|nimi|navn|نام|نام|名前|имя|名字|nazwa|nama|иmię|imię|имя пользователя|الاسم|नाम|اسم)$', caseSensitive: false).hasMatch(inner)) return true;
  if (varName == 'author' && RegExp(r'^(?:auteur|autor|autore|kirjoittaja|forfatter|लेखक|مصنف|著者|автор|作者|tác giả|المؤلف|작성자|Penulis|Twórca|autor|लेखक|مصنف|المؤلف)$', caseSensitive: false).hasMatch(inner)) return true;
  if (varName == 'comment' && RegExp(r'^(?:commentaire|comentario|commento|kommentti|kommentar|commentaar|komentat|skomentował|टिप्पणी|تبصرہ|コメント|комментарий|评论|komentar|komentarz|تعليق|koment|تعليق|टिप्पणी|تبصرہ)$', caseSensitive: false).hasMatch(inner)) return true;
  if (varName == 'date' && RegExp(r'^(?:datum|fecha|data|päiväm|dato|تاریخ|दिनांक|日付|дата|日期|تاریخ)$', caseSensitive: false).hasMatch(inner)) return true;
  if (varName == 'error' && RegExp(r'^(?:erreur|error|errori|fehler|błąd|błąd ładowania|błędny|خطأ|त्रुटि|エラー|错误|gata|ошибка|غلطی|त्रुटि|غلطی|خطأ|الخطأ|خطأ)$', caseSensitive: false).hasMatch(inner)) return true;
  if (varName == 'title' && RegExp(r'^(?:titre|título|titolo|titel|tytuł|nazwa|عنوان|शीर्षक|タイトル|标题|titlu|название|शीर्षक|عنوان)$', caseSensitive: false).hasMatch(inner)) return true;
  if (varName == 'postTitle' && RegExp(r'^(?:titre du post|título de la publication|titolo del post|beitragstitel|tytuł posta|tytuł wpisu|posttitle|پوسٹ ٹائٹل|پوسٹ ٹائٹل|शीर्षक)$', caseSensitive: false).hasMatch(inner)) return true;
  if (varName == 'item' && RegExp(r'^(?:article|artículo|articolo|artikel|przedmiot|pozycja|element|item|آئٹम|آئیٹم|आइटम|آئٹم)$', caseSensitive: false).hasMatch(inner)) return true;
  if (varName == 'fileType' && RegExp(r'^(?:filetype|tipo de archivo|tipo di file|dateityp|فائل ٹائپ)$', caseSensitive: false).hasMatch(inner)) return true;
  return false;
}

void main() {
  final l10nDir = Directory('lib/l10n');
  if (!l10nDir.existsSync()) {
    print('Directory lib/l10n does not exist');
    return;
  }

  for (final entity in l10nDir.listSync()) {
    if (entity is File && entity.path.endsWith('.arb') && !entity.path.endsWith('app_en.arb')) {
      _fixPlaceholders(entity);
    }
  }
}

void _fixPlaceholders(File file) {
  try {
    final contentText = file.readAsStringSync();
    Map<String, dynamic> data = jsonDecode(contentText);
    bool fileModified = false;

    print('Processing: ${file.path}');
    for (var key in englishPlaceholders.keys) {
      if (data.containsKey(key)) {
        String originalText = data[key].toString();
        String text = originalText;
        final expectedVars = englishPlaceholders[key]!;
        
        // 1. Pass 1: Fix localized or clearly malformed placeholders
        for (var varName in expectedVars) {
           final correctPlaceholder = '{$varName}';
           
           // Match placeholders carefully. If it has a closing brace, it's easier.
           // Use greedy matching for the inner part to avoid matching only first char.
           text = text.replaceAllMapped(RegExp(r'\$?\{[^}\n,"]+?\}'), (match) {
             String matched = match.group(0)!;
             String inner = matched.replaceAll('\$', '').replaceAll('{', '').replaceAll('}', '').trim().toLowerCase();
             
             if (inner == varName.toLowerCase() || localizedMatches(varName, inner)) {
               return correctPlaceholder;
             }
             return matched;
           });
        }
        
        // 2. Pass 2: Handle $varName
        for (var varName in expectedVars) {
           text = text.replaceAll(RegExp('\\\$' + varName + r'(?!\w)'), '{$varName}');
        }
        
        // 3. Pass 3: Fallback for missing expected vars - look for unclosed braces or other broken ones
        for (var varName in expectedVars) {
           if (!text.contains('{$varName}')) {
              // Look for something that looks like a placeholder but might be unclosed
              // We stop at space, newline, comma, quote, or colon
              text = text.replaceFirstMapped(RegExp(r'\{[^}\n, ":]+'), (match) {
                 String matched = match.group(0)!;
                 String inner = matched.replaceAll('{', '').trim().toLowerCase();
                 if (localizedMatches(varName, inner) || inner == varName.toLowerCase() || inner.contains(varName.toLowerCase())) {
                    return '{$varName}';
                 }
                 return matched;
              });
           }
        }
        
        // 4. Pass 4: If STILL missing, just find ANY leftover { ... and replace first one
        for (var varName in expectedVars) {
           if (!text.contains('{$varName}')) {
              text = text.replaceFirst(RegExp(r'\{[^}\n,"]+?\}?'), '{$varName}');
           }
        }
        
        // 5. Pass 5: CLEANUP duplicates and extraneous braces
        // If we expect 1 var but have 2 placeholders, and one is the correct one, remove the other.
        final allMatches = RegExp(r'\{[^}\n]+?\}?').allMatches(text).toList();
        if (allMatches.length > expectedVars.length) {
           // Identify which ones are "correct"
           List<int> correctIndices = [];
           for (int i = 0; i < allMatches.length; i++) {
             String matched = allMatches[i].group(0)!;
             for (var varName in expectedVars) {
               if (matched == '{$varName}') {
                 correctIndices.add(i);
                 break;
               }
             }
           }
           
           // If we have correct ones, remove the others (strip braces)
           if (correctIndices.isNotEmpty) {
              String newText = '';
              int lastEnd = 0;
              for (int i = 0; i < allMatches.length; i++) {
                newText += text.substring(lastEnd, allMatches[i].start);
                String matched = allMatches[i].group(0)!;
                if (correctIndices.contains(i)) {
                  newText += matched;
                } else {
                  // Strip braces
                  newText += matched.replaceAll('{', '').replaceAll('}', '');
                }
                lastEnd = allMatches[i].end;
              }
              newText += text.substring(lastEnd);
              text = newText;
           }
        }
        
        // Final sanity check: strip any remaining UNCLOSED braces at end of string or before spaces
        text = text.replaceAllMapped(RegExp(r'\{[^}\n ]+(?=\s|$)'), (match) {
           String matched = match.group(0)!;
           // If it's not a valid placeholder (it's unclosed), strip it
           if (!matched.endsWith('}')) {
              return matched.replaceAll('{', '');
           }
           return matched;
        });

        // Ensure no ${var}
        for (var varName in expectedVars) {
          text = text.replaceAll('\${$varName}', '{$varName}');
        }

        if (originalText != text) {
          data[key] = text;
          fileModified = true;
          print('  ${file.path} [$key]: "$originalText" -> "$text"');
        }
      }
    }

    if (fileModified) {
      const encoder = JsonEncoder.withIndent('  ');
      file.writeAsStringSync(encoder.convert(data));
      print('Fixed placeholders in ${file.path}');
    }
  } catch (e) {
    print('Error processing ${file.path}: $e');
  }
}
