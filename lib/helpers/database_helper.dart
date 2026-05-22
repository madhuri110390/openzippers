import 'dart:async';
import 'package:path/path.dart' show join; 
import 'package:sqflite/sqflite.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'openzippers.db');
    final db = await openDatabase(
      path,
      version: 19,
      onConfigure: _onConfigure,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
    await _ensureUsersSchema(db);
    return db;
  }

  Future _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  Future<void> _ensureUsersSchema(Database db) async {
    // 1. Check Users Table
    try {
      final userCols = await db.rawQuery('PRAGMA table_info(users)');
      final userColNames = userCols.map((c) => (c['name'] ?? '').toString().toLowerCase()).toSet();
      if (!userColNames.contains('isartist')) {
        try {
          await db.execute('ALTER TABLE users ADD COLUMN isArtist INTEGER DEFAULT 0');
        } catch (e) {
          debugPrint("Note: Column isArtist might already exist: $e");
        }
      }
      
      if (!userColNames.contains('joineddate')) {
        try {
          await db.execute('ALTER TABLE users ADD COLUMN joinedDate TEXT');
        } catch (e) {
          debugPrint("Note: Column joinedDate might already exist: $e");
        }
      }

      if (!userColNames.contains('isonline')) {
        try {
          await db.execute('ALTER TABLE users ADD COLUMN isOnline INTEGER DEFAULT 0');
        } catch (e) {
          debugPrint("Note: Column isOnline might already exist: $e");
        }
      }
      
      if (!userColNames.contains('issubscribed')) {
        try {
          await db.execute('ALTER TABLE users ADD COLUMN isSubscribed INTEGER DEFAULT 0');
        } catch (e) {
          debugPrint("Note: Column isSubscribed might already exist: $e");
        }
      }

      if (!userColNames.contains('isemailverified')) {
        try {
          await db.execute('ALTER TABLE users ADD COLUMN isEmailVerified INTEGER DEFAULT 0');
        } catch (e) {
          debugPrint("Note: Column isEmailVerified might already exist: $e");
        }
      }
    } catch (e) {
      debugPrint("Schema verification error (users): $e");
    }

    // 2. Check Posts Table
    try {
      final postCols = await db.rawQuery('PRAGMA table_info(posts)');
      final postColNames = postCols.map((c) => (c['name'] ?? '').toString().toLowerCase()).toSet();
      
      final missingCols = <String>[];
      if (!postColNames.contains('language')) missingCols.add('language TEXT');
      if (!postColNames.contains('genre')) missingCols.add('genre TEXT');
      if (!postColNames.contains('publishingstatus')) missingCols.add('publishingStatus TEXT');
      if (!postColNames.contains('certificatestatus')) missingCols.add('certificateStatus TEXT');
      if (!postColNames.contains('previewpath')) missingCols.add('previewPath TEXT');
      if (!postColNames.contains('zippfansstatus')) missingCols.add('zippfansStatus INTEGER DEFAULT 0');
      if (!postColNames.contains('streamingstatus')) missingCols.add('streamingStatus INTEGER DEFAULT 1');

      for (final colDef in missingCols) {
        try {
          await db.execute('ALTER TABLE posts ADD COLUMN $colDef');
          debugPrint("Added missing column: $colDef");
        } catch (e) {
          debugPrint("Error adding column $colDef: $e");
        }
      }
    } catch (e) { 
      debugPrint("Schema verification error (posts): $e");
    }

    // 3. Check Cart Items Table
    try {
      final cartCols = await db.rawQuery('PRAGMA table_info(cart_items)');
      final cartColNames = cartCols.map((c) => (c['name'] ?? '').toString().toLowerCase()).toSet();
      
      final missingCartCols = <String>[];
      if (!cartColNames.contains('previewpath')) missingCartCols.add('previewPath TEXT');
      if (!cartColNames.contains('language')) missingCartCols.add('language TEXT');
      if (!cartColNames.contains('genre')) missingCartCols.add('genre TEXT');
      if (!cartColNames.contains('publishingstatus')) missingCartCols.add('publishingStatus TEXT');
      if (!cartColNames.contains('certificatestatus')) missingCartCols.add('certificateStatus TEXT');
      
      for (final colDef in missingCartCols) {
        try {
          await db.execute('ALTER TABLE cart_items ADD COLUMN $colDef');
          debugPrint("Added missing cart_items column: $colDef");
        } catch (e) {
          debugPrint("Error adding cart_items column $colDef: $e");
        }
      }
    } catch (e) {
      debugPrint("Schema verification error (cart_items): $e");
    }

    // 4. Data Patch: Fix missing video paths
    try {
       await db.execute("UPDATE posts SET previewPath = 'https://assets.mixkit.co/videos/preview/mixkit-tree-with-yellow-flowers-1173-large.mp4' WHERE (type = 'Video' OR type = 'Reel' OR type = 'Reels') AND (previewPath IS NULL OR previewPath = '')");
    } catch (e) {
       debugPrint("Data patch error: $e");
    }

    // 5. Check Albums Table for price column
    try {
      final albumCols = await db.rawQuery('PRAGMA table_info(albums)');
      final albumColNames = albumCols.map((c) => (c['name'] ?? '').toString().toLowerCase()).toSet();
      
      if (!albumColNames.contains('price')) {
        try {
          await db.execute('ALTER TABLE albums ADD COLUMN price TEXT');
          debugPrint("Added missing column: price to albums");
        } catch (e) {
          debugPrint("Error adding price column to albums: $e");
        }
      }
      if (!albumColNames.contains('isprivate')) {
        try {
          await db.execute('ALTER TABLE albums ADD COLUMN isPrivate INTEGER DEFAULT 0');
          debugPrint("Added missing column: isPrivate to albums");
        } catch (e) {
          debugPrint("Error adding isPrivate column to albums: $e");
        }
      }
    } catch (e) {
      debugPrint("Schema verification error (albums): $e");
    }
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Restore previous migrations (simplified for brevity as they are cumulative)
    if (oldVersion < 16) {
      try {
        await db.execute('ALTER TABLE posts ADD COLUMN publishingStatus TEXT');
        await db.execute('ALTER TABLE posts ADD COLUMN certificateStatus TEXT');
      } catch (e) { }
    }
    
    if (oldVersion < 17) {
      try {
         await db.execute('ALTER TABLE posts ADD COLUMN language TEXT');
         await db.execute('ALTER TABLE posts ADD COLUMN genre TEXT');
      } catch (e) {
        debugPrint("Error upgrading db to v17: $e");
      }
    }

    if (oldVersion < 18) {
      try {
         await db.execute('ALTER TABLE posts ADD COLUMN previewPath TEXT');
         await db.execute('ALTER TABLE cart_items ADD COLUMN previewPath TEXT');
         // Patch existing mock videos with the preview URL
         await db.execute("UPDATE posts SET previewPath = 'https://assets.mixkit.co/videos/preview/mixkit-tree-with-yellow-flowers-1173-large.mp4' WHERE (type = 'Video' OR type = 'Reel' OR type = 'Reels') AND previewPath IS NULL");
      } catch (e) {
        debugPrint("Error upgrading db to v18: $e");
      }
    }

    if (oldVersion < 19) {
      try {
        await db.execute('ALTER TABLE users ADD COLUMN isEmailVerified INTEGER DEFAULT 0');
      } catch (e) {
        debugPrint("Error upgrading db to v19: $e");
      }
    }
  }

// ... somewhere in the class, adding the new method ...

  Future<int> updatePostStatus(int id, {String? publishingStatus, String? certificateStatus}) async {
    Database db = await database;
    Map<String, dynamic> values = {};
    if (publishingStatus != null) values['publishingStatus'] = publishingStatus;
    if (certificateStatus != null) values['certificateStatus'] = certificateStatus;
    
    if (values.isEmpty) return 0;
    
    return await db.update('posts', values, where: 'id = ?', whereArgs: [id]);
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users (
        username TEXT PRIMARY KEY,
        name TEXT,
        avatar TEXT,
        coverImage TEXT,
        isVerified INTEGER,
        isArtist INTEGER DEFAULT 0,
        bio TEXT,
        type TEXT,
        country TEXT,
        state TEXT,
        city TEXT,
        gender TEXT,
        joinedDate TEXT,
        isOnline INTEGER DEFAULT 0,
        isSubscribed INTEGER DEFAULT 0,
        isEmailVerified INTEGER DEFAULT 0
      )
    ''');


    await db.execute('''
      CREATE TABLE posts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        type TEXT,
        title TEXT,
        price TEXT,
        content TEXT,
        isRichText INTEGER DEFAULT 0,
        author TEXT,
        isUserPost INTEGER,
        date TEXT,
        image TEXT,
        filePath TEXT,
        coverPath TEXT,
        language TEXT,
        genre TEXT,
        likeCount INTEGER DEFAULT 0,
        ratingCount INTEGER DEFAULT 0,
        averageRating REAL DEFAULT 0.0,
        totalRatings INTEGER DEFAULT 0,
        publishingStatus TEXT,
        certificateStatus TEXT,
        previewPath TEXT,
        zippfansStatus INTEGER DEFAULT 0,
        streamingStatus INTEGER DEFAULT 1
      )
    ''');


    await db.execute('''
      CREATE TABLE comments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        postId INTEGER,
        author TEXT,
        text TEXT,
        likes TEXT DEFAULT '[]',
        parentId INTEGER,
        timestamp TEXT,
        FOREIGN KEY (postId) REFERENCES posts (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE user_actions (
        postTitle TEXT,
        postAuthor TEXT,
        actionType TEXT,
        ratingValue INTEGER DEFAULT 0,
        PRIMARY KEY (postTitle, postAuthor, actionType)
      )
    ''');

    await db.execute('''
      CREATE TABLE cart_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT,
        type TEXT,
        title TEXT,
        price TEXT,
        content TEXT,
        author TEXT,
        isUserPost INTEGER,
        date TEXT,
        image TEXT,
        filePath TEXT,
        coverPath TEXT,
        isRichText INTEGER DEFAULT 0,
        quantity INTEGER DEFAULT 1,
        previewPath TEXT
      )
    ''');


    await db.execute('''
      CREATE TABLE wallet_balance (
        username TEXT PRIMARY KEY,
        balance REAL DEFAULT 0.0
      )
    ''');


    await db.execute('''
      CREATE TABLE wallet_transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT,
        type TEXT,
        amount REAL,
        description TEXT,
        date TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE relationships (
        follower TEXT,
        followed TEXT,
        type TEXT,
        PRIMARY KEY (follower, followed)
      )
    ''');

    await db.execute('''
      CREATE TABLE albums (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        author TEXT,
        title TEXT,
        cover TEXT,
        trackCount INTEGER,
        year TEXT,
        media TEXT,
        price TEXT,
        isPrivate INTEGER DEFAULT 0
      )
    ''');
  }


  Future<int> insertUser(Map<String, dynamic> user) async {
    Database db = await database;
    return await db.insert('users', user, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> getUsers() async {
    Database db = await database;
    return await db.query('users');
  }

  Future<int> deleteUser(String username) async {
    Database db = await database;
    return await db.delete('users', where: 'username = ?', whereArgs: [username]);
  }

  Future<Map<String, dynamic>?> getUserByUsername(String username) async {
    Database db = await database;
    final results = await db.query('users', where: 'username = ?', whereArgs: [username]);
    if (results.isNotEmpty) {
      return results.first;
    }
    return null;
  }


  Future<int> updatePost(Map<String, dynamic> post) async {
    return await insertPost(post);
  }

  Future<int> insertPost(Map<String, dynamic> post) async {
    Database db = await database;
    return await db.transaction((txn) async {
      final comments = post['comments'] as List?;
      final postMap = Map<String, dynamic>.from(post)
        ..remove('comments')
        ..remove('readCount')
        ..remove('watchCount');
      
      if (postMap.containsKey('isUserPost')) {
        postMap['isUserPost'] = postMap['isUserPost'] == true ? 1 : 0;
      }
      if (postMap.containsKey('isRichText')) {
        postMap['isRichText'] = postMap['isRichText'] == true ? 1 : 0;
      }
      if (postMap['date'] is DateTime) {
        postMap['date'] = (postMap['date'] as DateTime).toIso8601String();
      }
      
      // Ensure integer values for boolean-like status fields
      if (postMap.containsKey('zippfansStatus')) {
        postMap['zippfansStatus'] = (postMap['zippfansStatus'] == true || postMap['zippfansStatus'] == 1) ? 1 : 0;
      }
      if (postMap.containsKey('streamingStatus')) {
        postMap['streamingStatus'] = (postMap['streamingStatus'] == true || postMap['streamingStatus'] == 1) ? 1 : 0;
      }

      // If we are updating/replacing, manually delete comments first to avoid conflicts
      // This is a safety measure in case FK cascade doesn't trigger immediately within transaction
      if (postMap['id'] != null) {
        await txn.delete('comments', where: 'postId = ?', whereArgs: [postMap['id']]);
      }

      // Insert/Replace the post
      int id = await txn.insert('posts', postMap, conflictAlgorithm: ConflictAlgorithm.replace);

      // Insert comments using the transaction
      if (comments != null) {
        for (var comment in comments) {
          Map<String, dynamic> commentToInsert = Map.from(comment);
          commentToInsert['postId'] = id; // Ensure linked to new/replaced post
          
          if (commentToInsert['likes'] is List) {
            commentToInsert['likes'] = jsonEncode(commentToInsert['likes']);
          }
          if (commentToInsert['timestamp'] is DateTime) {
            commentToInsert['timestamp'] = (commentToInsert['timestamp'] as DateTime).toIso8601String();
          } else if (commentToInsert['timestamp'] == null) {
            commentToInsert['timestamp'] = DateTime.now().toIso8601String();
          }
          
          // Use REPLACE for comments too
          await txn.insert('comments', commentToInsert, conflictAlgorithm: ConflictAlgorithm.replace);
        }
      }
      return id;
    });
  }

  Future<List<Map<String, dynamic>>> getPosts() async {
    Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query('posts', orderBy: 'date DESC');
    
    List<Map<String, dynamic>> results = [];
    for (var map in maps) {
      final post = Map<String, dynamic>.from(map);
      post['isUserPost'] = post['isUserPost'] == 1;
      post['isRichText'] = post['isRichText'] == 1;
      if (post['date'] != null) {
        post['date'] = DateTime.parse(post['date']);
      }
      post['comments'] = await getComments(post['id']);
      results.add(post);
    }
    return results;
  }

  Future<int> deletePost(String title, String date) async {
    Database db = await database;
    int deleted = await db.delete('posts', where: 'title = ? AND date = ?', whereArgs: [title, date]);
    if (deleted == 0) {
      deleted = await db.delete('posts', where: 'title = ?', whereArgs: [title]);
    }
    return deleted;
  }
  
  Future<int> deletePostById(int id) async {
    Database db = await database;
    return await db.delete('posts', where: 'id = ?', whereArgs: [id]);
  }

  Future<Map<String, dynamic>?> getPostById(int id) async {
    Database db = await database;
    final results = await db.query('posts', where: 'id = ?', whereArgs: [id]);
    if (results.isNotEmpty) {
      final post = Map<String, dynamic>.from(results.first);
      post['isUserPost'] = post['isUserPost'] == 1;
      post['isRichText'] = post['isRichText'] == 1;
      if (post['date'] != null) {
        post['date'] = DateTime.parse(post['date']);
      }
      post['comments'] = await getComments(post['id']);
      return post;
    }
    return null;
  }
  Future<int> deletePostsByAuthor(String author) async {
    Database db = await database;
    return await db.delete('posts', where: 'author = ?', whereArgs: [author]);
  }

  Future<int> cleanupUselessPosts() async {
    Database db = await database;
    final uselessPatterns = [
      'hget', 'ddd', 'get', '...', 'etc', 'test', 'temp', 
      'vhhh', 'fvghhh', 'gghj', 'vvbbb', 'vvv', 'bbb', 'ggg', 'hhh', 'jjj', 'fff',
      'aaa', 'ccc', 'eee', 'iii', 'lll', 'mmm', 'nnn', 'ooo', 'ppp', 'qqq', 'rrr', 'sss', 'ttt', 'uuu', 'www', 'xxx', 'yyy', 'zzz'
    ];
    int deletedCount = 0;
    
    for (var pattern in uselessPatterns) {
      final result = await db.delete(
        'posts',
        where: '(LOWER(title) LIKE ? OR LOWER(content) LIKE ?) AND isUserPost = 0',
        whereArgs: ['%$pattern%', '%$pattern%'],
      );
      deletedCount += result;
    }

    final allPosts = await db.query('posts');
    for (var post in allPosts) {
      if (post['isUserPost'] == 1) continue;
      
      final title = (post['title'] as String? ?? '').trim();
      final content = (post['content'] as String? ?? '').trim();
      
      bool shouldDelete = false;
      

      bool isUseless(String text) {
        if (text.isEmpty || text.isEmpty) return true;
        final lowerText = text.toLowerCase();
        

        for (var pattern in uselessPatterns) {
          if (lowerText == pattern || lowerText.contains(pattern)) {
            return true;
          }
        }
        

        if (text.length <= 10) {
          final uniqueChars = text.split('').toSet().length;
          if (uniqueChars == 1) return true;
          if (text.length <= 6 && uniqueChars <= 2) return true;
        }
        

        if (text.length <= 10) {
          final charCounts = <String, int>{};
          for (var char in text.split('')) {
            charCounts[char] = (charCounts[char] ?? 0) + 1;
          }
          final maxCount = charCounts.values.reduce((a, b) => a > b ? a : b);
          if (maxCount / text.length > 0.5) return true;
          final uniqueChars = charCounts.keys.length;
          if (text.length >= 4 && uniqueChars <= 2) return true;
          if (text.length >= 6 && uniqueChars <= 3) return true;
        }
        

        if (text.length <= 8) {
          int consecutiveCount = 1;
          String? lastChar;
          for (var char in text.split('')) {
            if (char == lastChar) {
              consecutiveCount++;
              if (consecutiveCount >= 3) return true;
            } else {
              consecutiveCount = 1;
            }
            lastChar = char;
          }
        }
        

        if (text.length <= 5) {
          final vowels = ['a', 'e', 'i', 'o', 'u'];
          final hasVowel = text.toLowerCase().split('').any((char) => vowels.contains(char));
          if (!hasVowel && text.length >= 3) return true;
        }
        
        return false;
      }
      

      if (isUseless(title) || isUseless(content)) {
        shouldDelete = true;
      }
      

      if (title.isEmpty && content.isEmpty) {
        shouldDelete = true;
      }
      
      if (shouldDelete) {
        await db.delete('posts', where: 'id = ?', whereArgs: [post['id']]);
        deletedCount++;
      }
    }
    
    return deletedCount;
  }


  Future<int> insertComment(int postId, Map<String, dynamic> comment) async {
    Database db = await database;
    Map<String, dynamic> commentToInsert = Map.from(comment);
    commentToInsert['postId'] = postId;
    if (commentToInsert['likes'] is List) {
      commentToInsert['likes'] = jsonEncode(commentToInsert['likes']);
    }
    // Handle timestamp - convert DateTime to ISO string if needed
    if (commentToInsert['timestamp'] is DateTime) {
      commentToInsert['timestamp'] = (commentToInsert['timestamp'] as DateTime).toIso8601String();
    } else if (commentToInsert['timestamp'] == null) {
      commentToInsert['timestamp'] = DateTime.now().toIso8601String();
    }
    return await db.insert('comments', commentToInsert, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<int> updateComment(Map<String, dynamic> comment) async {
    Database db = await database;
    Map<String, dynamic> commentMap = Map.from(comment);
    if (commentMap['likes'] is List) {
      commentMap['likes'] = jsonEncode(commentMap['likes']);
    }
    return await db.update('comments', commentMap, where: 'id = ?', whereArgs: [commentMap['id']]);
  }

  Future<List<Map<String, dynamic>>> getComments(int postId) async {
    Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query('comments', where: 'postId = ?', whereArgs: [postId]);
    
    return maps.map((c) {
      final map = Map<String, dynamic>.from(c);
      if (map['likes'] != null) {
        try {
          map['likes'] = jsonDecode(map['likes']);
        } catch (_) {
          map['likes'] = [];
        }
      } else {
        map['likes'] = [];
      }
      // Parse timestamp from ISO string to DateTime
      if (map['timestamp'] != null && map['timestamp'] is String) {
        try {
          map['timestamp'] = DateTime.parse(map['timestamp']);
        } catch (_) {
          map['timestamp'] = DateTime.now();
        }
      } else if (map['timestamp'] == null) {
        map['timestamp'] = DateTime.now();
      }
      return map;
    }).toList();
  }

  Future<void> deleteComment(int postId, int index) async {
    Database db = await database;

    final comments = await getComments(postId);
    if (index < comments.length) {
      int commentId = comments[index]['id'];
      await db.delete('comments', where: 'id = ?', whereArgs: [commentId]);
    }
  }

  Future<void> deleteCommentById(int id) async {
    Database db = await database;
    await db.delete('comments', where: 'id = ?', whereArgs: [id]);
  }


  Future<void> toggleAction(String title, String author, String type, {int ratingValue = 0}) async {
    Database db = await database;
    if (type == 'bookmark' || type == 'read') {
      final exists = await db.query('user_actions', where: 'postTitle = ? AND postAuthor = ? AND actionType = ?', whereArgs: [title, author, type]);
      if (exists.isNotEmpty) {
        await db.delete('user_actions', where: 'postTitle = ? AND postAuthor = ? AND actionType = ?', whereArgs: [title, author, type]);
      } else {
        await db.insert('user_actions', {
          'postTitle': title,
          'postAuthor': author,
          'actionType': type,
          'ratingValue': 0
        });
      }
    } else {
      await db.insert('user_actions', {
        'postTitle': title,
        'postAuthor': author,
        'actionType': type,
        'ratingValue': ratingValue
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
  }

  Future<void> submitRating(String title, String author, int stars) async {
    Database db = await database;

    await toggleAction(title, author, 'watch', ratingValue: stars);


    final List<Map<String, dynamic>> ratings = await db.query('user_actions', 
      where: 'postTitle = ? AND postAuthor = ? AND actionType = ?', 
      whereArgs: [title, author, 'watch']);
    
    int total = ratings.length;
    double sum = 0;
    for (var r in ratings) {
      sum += (r['ratingValue'] as int? ?? 0);
    }
    double average = total > 0 ? sum / total : 0;

    await db.rawUpdate('''
      UPDATE posts 
      SET ratingCount = ?, averageRating = ?, totalRatings = ? 
      WHERE title = ? AND author = ?
    ''', [total, average, total, title, author]);
  }

  Future<Map<String, dynamic>> getRatingInfo(String title, String author) async {
    Database db = await database;
    final List<Map<String, dynamic>> results = await db.query('posts', 
      columns: ['averageRating', 'totalRatings'],
      where: 'title = ? AND author = ?',
      whereArgs: [title, author]);
    
    if (results.isNotEmpty) {
      return results.first;
    }
    return {'averageRating': 0.0, 'totalRatings': 0};
  }

  Future<List<Map<String, dynamic>>> getActionPosts(String type) async {
    Database db = await database;
    final actions = await db.query('user_actions', where: 'actionType = ?', whereArgs: [type]);
    
    List<Map<String, dynamic>> results = [];
    for (var action in actions) {

      final posts = await db.query('posts', 
        where: 'title = ? AND author = ?', 
        whereArgs: [action['postTitle'], action['postAuthor']]
      );
      if (posts.isNotEmpty) {
        final post = Map<String, dynamic>.from(posts.first);
        post['isUserPost'] = post['isUserPost'] == 1;
        post['date'] = DateTime.parse(post['date']);
        post['comments'] = await getComments(post['id']);
        results.add(post);
      }
    }
    return results;
  }

  Future<void> updatePostCounts(String title, String author, {bool incrementLike = false, bool decrementLike = false, bool incrementRating = false}) async {
    Database db = await database;
    if (incrementLike) {
      await db.rawUpdate('UPDATE posts SET likeCount = likeCount + 1 WHERE title = ? AND author = ?', [title, author]);
    } else if (decrementLike) {

      await db.rawUpdate('UPDATE posts SET likeCount = CASE WHEN likeCount > 0 THEN likeCount - 1 ELSE 0 END WHERE title = ? AND author = ?', [title, author]);
    }
    if (incrementRating) {
      await db.rawUpdate('UPDATE posts SET ratingCount = ratingCount + 1 WHERE title = ? AND author = ?', [title, author]);
    }
  }


  Future<int> addToCart(Map<String, dynamic> item, String username) async {
    // Safety check: Cannot add private items to cart
    if (item['isPrivate'] == 1 || item['isPrivate'] == true) {
      debugPrint("Warning: Attempted to add private item to cart: ${item['title']}");
      return -1;
    }

    Database db = await database;

    final List<Map<String, dynamic>> existing = await db.query('cart_items', 
      where: 'username = ? AND title = ? AND author = ?', 
      whereArgs: [username, item['title'], item['author']]);
    
    if (existing.isNotEmpty) {

      int currentQty = existing.first['quantity'] as int;
      int newQty = currentQty + 1;
      return await db.update('cart_items', {'quantity': newQty}, 
        where: 'username = ? AND title = ? AND author = ?', 
        whereArgs: [username, item['title'], item['author']]);
    } else {

       final itemMap = Map<String, dynamic>.from(item)
        ..remove('comments')
        ..remove('readCount')
        ..remove('watchCount')
        ..remove('likeCount')
        ..remove('ratingCount')
        ..remove('averageRating')
        ..remove('totalRatings');
        
       if (itemMap.containsKey('isUserPost')) {
         itemMap['isUserPost'] = itemMap['isUserPost'] == true ? 1 : 0;
       }
       // Handle isRichText field - convert boolean to integer
       if (itemMap.containsKey('isRichText')) {
         itemMap['isRichText'] = itemMap['isRichText'] == true ? 1 : 0;
       }
       // Ensure content is a string (handle JSON/rich text content)
       if (itemMap.containsKey('content') && itemMap['content'] is List) {
         // If content is a list (JSON array from rich text), convert to JSON string
         try {
           itemMap['content'] = jsonEncode(itemMap['content']);
         } catch (e) {
           // If encoding fails, convert to plain text
           itemMap['content'] = itemMap['content'].toString();
         }
       } else if (itemMap.containsKey('content') && itemMap['content'] != null) {
         // Ensure content is always a string
         itemMap['content'] = itemMap['content'].toString();
       }
       if (itemMap['date'] is DateTime) {
         itemMap['date'] = (itemMap['date'] as DateTime).toIso8601String();
       }
       itemMap['username'] = username;
       itemMap['quantity'] = 1;

       // Filter itemMap to only include keys that exist in the cart_items table
       final validColumns = {
         'username', 'type', 'title', 'price', 'content', 'author', 'isUserPost', 
         'date', 'image', 'filePath', 'coverPath', 'isRichText', 'quantity', 
         'previewPath', 'language', 'genre', 'publishingStatus', 'certificateStatus'
       };
       
       final Map<String, dynamic> filteredItem = {};
       
       itemMap.forEach((key, value) {
         if (validColumns.contains(key)) {
           filteredItem[key] = value;
         }
       });

       return await db.insert('cart_items', filteredItem);
    }
  }

  Future<int> updateCartQuantity(String username, String title, String author, int quantity) async {
    Database db = await database;
    if (quantity <= 0) {
      return await db.delete('cart_items', 
        where: 'username = ? AND title = ? AND author = ?', 
        whereArgs: [username, title, author]);
    }
    return await db.update('cart_items', {'quantity': quantity}, 
      where: 'username = ? AND title = ? AND author = ?', 
      whereArgs: [username, title, author]);
  }

  Future<List<Map<String, dynamic>>> getCartItems(String username) async {
    Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query('cart_items',
      where: 'username = ?',
      whereArgs: [username]);
    
    List<Map<String, dynamic>> results = [];
    for (var map in maps) {
      final item = Map<String, dynamic>.from(map);
      item['isUserPost'] = item['isUserPost'] == 1;
      // Handle isRichText field - convert integer back to boolean
      if (item.containsKey('isRichText')) {
        item['isRichText'] = item['isRichText'] == 1;
      }
      if (item['date'] != null) {
        item['date'] = DateTime.parse(item['date']);
      }
      results.add(item);
    }
    return results;
  }


  Future<double> getWalletBalance(String username) async {
    Database db = await database;
    final results = await db.query('wallet_balance', where: 'username = ?', whereArgs: [username]);
    if (results.isNotEmpty) {
      return (results.first['balance'] as num).toDouble();
    }

    await db.insert('wallet_balance', {'username': username, 'balance': 0.0});
    return 0.0;
  }

  Future<void> updateWalletBalance(String username, double amount) async {
    Database db = await database;
    final currentBalance = await getWalletBalance(username);
    final newBalance = currentBalance + amount;
    await db.insert('wallet_balance', {
      'username': username,
      'balance': newBalance
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> setWalletBalance(String username, double balance) async {
    Database db = await database;
    await db.insert('wallet_balance', {
      'username': username,
      'balance': balance
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<int> addWalletTransaction(String username, String type, double amount, String description) async {
    Database db = await database;
    return await db.insert('wallet_transactions', {
      'username': username,
      'type': type,
      'amount': amount,
      'description': description,
      'date': DateTime.now().toIso8601String(),
    });
  }

  Future<List<Map<String, dynamic>>> getWalletTransactions(String username) async {
    Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'wallet_transactions',
      where: 'username = ?',
      whereArgs: [username],
      orderBy: 'date DESC',
    );
    
    return maps.map((map) {
      final item = Map<String, dynamic>.from(map);
      if (item['date'] != null) {
        item['date'] = DateTime.parse(item['date']);
      }
      return item;
    }).toList();
  }
  Future<void> followUser(String follower, String followed) async {
    final db = await database;
    await db.insert(
      'relationships',
      {'follower': follower, 'followed': followed, 'type': 'following'},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> subscribeToUser(String follower, String followed) async {
    final db = await database;
    await db.insert(
      'relationships',
      {'follower': follower, 'followed': followed, 'type': 'subscribed'},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> unfollowUser(String follower, String followed) async {
    final db = await database;
    await db.delete(
      'relationships',
      where: 'follower = ? AND followed = ?',
      whereArgs: [follower, followed],
    );
  }

  Future<void> unsubscribeFromUser(String follower, String followed) async {
    final db = await database;
    // When unsubscribing, we might want to stay following.
    // However, for simplicity now, let's just downgrade to 'following' or remove entirely.
    // Usually, 'Unsubscribe' means just that.
    await db.insert(
      'relationships',
      {'follower': follower, 'followed': followed, 'type': 'following'},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> blockUser(String blocker, String blocked) async {
    final db = await database;
    await db.insert(
      'relationships',
      {'follower': blocker, 'followed': blocked, 'type': 'blocked'},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    // Remove the reverse relationship (they can no longer follow you)
    await db.delete(
      'relationships',
      where: 'follower = ? AND followed = ?',
      whereArgs: [blocked, blocker],
    );
     // Also remove any existing "following" relationship from me to them (redundant if using replace, but good for safety if we track 'following' vs 'blocked' differently)
    // Here we relied on REPLACE into 'relationships' PK(follower, followed), so my status overrides 'following' with 'blocked'.
    // The delete above converts THEIR status to me from 'following' to 'null'.
  }

  Future<void> unblockUser(String blocker, String blocked) async {
    final db = await database;
    await db.delete(
      'relationships',
      where: 'follower = ? AND followed = ?',
      whereArgs: [blocker, blocked],
    );
  }

  Future<Map<String, String>> getRelationships(String username) async {
    final db = await database;
    
    // 1. Who do I follow? (Or have blocked)
    final myActions = await db.query(
      'relationships',
      where: 'follower = ?',
      whereArgs: [username],
    );
    
    // 2. Who follows me? (Or has blocked me)
    final actingOnMe = await db.query(
      'relationships',
      where: 'followed = ?',
      whereArgs: [username],
    );

    final Map<String, String> resultMap = {};
    final Set<String> followers = {};
    final Set<String> subscribers = {};
    final Set<String> blockedBy = {};

    // Process Incoming Actions
    for (var row in actingOnMe) {
        final type = row['type'] as String;
        final person = row['follower'] as String;
        if (type == 'following') {
            followers.add(person);
        } else if (type == 'subscribed') {
            subscribers.add(person);
            followers.add(person); // Subscribers are also followers
        } else if (type == 'blocked') {
            blockedBy.add(person);
        }
    }

    // Process My Actions and determine final state
    for (var row in myActions) {
      final person = row['followed'] as String;
      final type = row['type'] as String;
      
      if (type == 'blocked') {
        resultMap[person] = 'blocked';
      } else if (type == 'subscribed') {
        resultMap[person] = 'subscribed';
      } else if (type == 'following') {
         if (followers.contains(person)) {
             resultMap[person] = 'mutual';
         } else {
             resultMap[person] = 'following';
         }
      }
    }
    
    // Add those who are purely followers/subscribers (and not already in map as mutual/blocked)
    for (var person in followers) {
        if (!resultMap.containsKey(person)) {
            if (subscribers.contains(person)) {
                resultMap[person] = 'subscriber';
            } else {
                resultMap[person] = 'follower';
            }
        }
    }
    
    // Mark blocked_by (if not already covered by 'blocked' - i.e. we blocked each other? In that case 'blocked' takes precedence for my UI)
    for (var person in blockedBy) {
        if (!resultMap.containsKey(person)) {
            resultMap[person] = 'blocked_by';
        }
    }

    return resultMap;
  }

  // Album methods
  Future<int> insertAlbum(Map<String, dynamic> album) async {
    Database db = await database;
    Map<String, dynamic> albumMap = Map<String, dynamic>.from(album);
    
    // Encode media list to JSON string
    if (albumMap['media'] != null) {
      albumMap['media'] = jsonEncode(albumMap['media'], toEncodable: (item) {
        if (item is DateTime) {
          return item.toIso8601String();
        }
        return item;
      });
    }
    
    return await db.insert('albums', albumMap);
  }

  Future<List<Map<String, dynamic>>> getAlbums({String? username, bool onlyPublic = false}) async {
    Database db = await database;
    final List<Map<String, dynamic>> maps;
    
    if (username != null) {
      if (onlyPublic) {
        maps = await db.query('albums', where: 'author = ? AND (isPrivate IS NULL OR isPrivate = 0)', whereArgs: [username]);
      } else {
        maps = await db.query('albums', where: 'author = ?', whereArgs: [username]);
      }
    } else {
      if (onlyPublic) {
        maps = await db.query('albums', where: 'isPrivate IS NULL OR isPrivate = 0');
      } else {
        maps = await db.query('albums');
      }
    }
    
    return maps.map((map) {
      final album = Map<String, dynamic>.from(map);
      if (album['media'] != null && album['media'] is String) {
        final List<dynamic> decoded = jsonDecode(album['media']);
        album['media'] = decoded.map((item) {
          final track = Map<String, dynamic>.from(item as Map);
          if (track['date'] != null && track['date'] is String) {
            try {
              track['date'] = DateTime.parse(track['date']);
            } catch (e) {
              debugPrint("Error parsing track date: $e");
            }
          }
          return track;
        }).toList();
      }
      return album;
    }).toList();
  }

  Future<int> updateAlbum(Map<String, dynamic> album) async {
    Database db = await database;
    Map<String, dynamic> albumMap = Map<String, dynamic>.from(album);
    
    final id = albumMap['id'];
    if (id == null) return 0;
    
    // Encode media list to JSON string
    if (albumMap['media'] != null) {
      albumMap['media'] = jsonEncode(albumMap['media'], toEncodable: (item) {
        if (item is DateTime) {
          return item.toIso8601String();
        }
        return item;
      });
    }
    
    return await db.update('albums', albumMap, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteAlbum(int id) async {
    Database db = await database;
    return await db.delete('albums', where: 'id = ?', whereArgs: [id]);
  }

  // ===========================================================================
  // DATABASE BACKUP & RESTORE
  // ===========================================================================

  /// Backs up the database database to a file and shares it (e.g., to Drive/Local Storage)
  Future<bool> backupDatabase() async {
    try {
      final dbPath = await getDatabasesPath();
      final String path = join(dbPath, 'openzippers.db');
      final File currentDb = File(path);

      if (!await currentDb.exists()) {
        debugPrint("Database file not found!");
        return false;
      }

      // Create a temporary copy with a timestamp
      final directory = await getTemporaryDirectory();
      final String fileName = 'openzippers_backup_${DateTime.now().millisecondsSinceEpoch}.db';
      final String backupPath = join(directory.path, fileName);
      
      await currentDb.copy(backupPath);

      // Share the file so user can save it
      final result = await Share.shareXFiles(
        [XFile(backupPath)], 
        text: 'OpenZippers Database Backup'
      );
      
      return result.status == ShareResultStatus.success;
    } catch (e) {
      debugPrint("Error backing up database: $e");
      return false;
    }
  }

  /// Restores the database from a user-selected file
  Future<bool> restoreDatabase() async {
    try {
      // Pick the file
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.any, // .db files might not have a specific mime type commonly
      );

      if (result == null || result.files.single.path == null) {
        return false; // User canceled
      }

      final File backupFile = File(result.files.single.path!);
      
      // Basic validation (check extension or magic header potentially, but extension is a weak check)
      if (!backupFile.path.endsWith('.db')) {
        debugPrint("Attached file does not look like a database backup.");
        // We'll proceed cautiously or you could return false here.
      }

      // 1. Close the current database connection
      if (_database != null && _database!.isOpen) {
        await _database!.close();
        _database = null;
      }

      // 2. Get the target path
      final dbPath = await getDatabasesPath();
      final String targetPath = join(dbPath, 'openzippers.db');

      // 3. Overwrite the file
      await backupFile.copy(targetPath);

      // 4. Re-initialize
      await _initDatabase();
      
      return true;
    } catch (e) {
      debugPrint("Error restoring database: $e");
      // Attempt to recover connection if restore failed
      _database = null;
      return false;
    }
  }
}
