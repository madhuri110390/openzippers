import 'dart:io';

/// Script to find hardcoded English strings that should be localized
/// Run: dart run scripts/find_hardcoded_strings.dart

void main() {
  final libDir = Directory('lib');
  final violations = <String>[];
  
  // Common UI strings that should be localized
  final commonStrings = [
    'Search Users',
    'All Posts',
    'My Posts',
    'Bookmarks',
    'Albums',
    'Create Post',
    'Connections',
    'Profile',
    'Home',
    'Settings',
    'Search',
    'Cancel',
    'Save',
    'Delete',
    'Edit',
    'Submit',
    'Loading',
    'Error',
    'Success',
    'You',
    'Songs',
    'Videos',
    'Free',
    'Paid',
  ];
  
  print('🔍 Scanning for hardcoded strings...\n');
  
  if (!libDir.existsSync()) {
    print('❌ lib directory not found!');
    return;
  }
  
  final dartFiles = libDir
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .where((f) => !f.path.contains('/l10n/generated/'))
      .where((f) => !f.path.contains('zego'))  // Skip Zego plugin
      .where((f) => !f.path.contains('plugin'))  // Skip other plugins
      .toList();
  
  for (final file in dartFiles) {
    final lines = file.readAsLinesSync();
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      final lineNumber = i + 1;
      
      // Skip comments
      if (line.trim().startsWith('//')) continue;
      
      // Check for hardcoded strings in Text widgets
      for (final str in commonStrings) {
        final patterns = [
          "Text('$str'",
          'Text("$str"',
          "Text( '$str'",
          'Text( "$str"',
          "label: Text('$str'",
          'label: Text("$str"',
          "title: Text('$str'",
          'title: Text("$str"',
          "hintText: '$str'",
          'hintText: "$str"',
          "labelText: '$str'",
          'labelText: "$str"',
        ];
        
        for (final pattern in patterns) {
          if (line.contains(pattern)) {
            final relativePath = file.path.replaceFirst('lib/', '');
            violations.add('📍 $relativePath:$lineNumber - Found: "$str"');
          }
        }
      }
    }
  }
  
  if (violations.isEmpty) {
    print('✅ No common hardcoded strings found!');
  } else {
    print('⚠️  Found ${violations.length} potential violations:\n');
    for (final violation in violations) {
      print(violation);
    }
    print('\n💡 Tip: Use context.tr.yourKey instead of hardcoded strings');
  }
}
