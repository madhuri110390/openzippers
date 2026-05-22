import 'package:sqflite_common_ffi/sqflite_ffi.dart';

// Mock implementation of parts of DatabaseHelper to test logic
class TestDatabaseHelper {
  late Database db;

  Future<void> init() async {
    sqfliteFfiInit();
    var databaseFactory = databaseFactoryFfi;
    db = await databaseFactory.openDatabase(inMemoryDatabasePath);
    await _onCreate(db);
  }

  Future _onCreate(Database db) async {
    await db.execute('''
      CREATE TABLE users (
        username TEXT PRIMARY KEY,
        name TEXT,
        type TEXT
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
  }

  Future<void> insertUser(String username) async {
    await db.insert('users', {'username': username, 'name': username, 'type': 'public'});
  }

  Future<void> followUser(String follower, String followed) async {
    await db.insert(
      'relationships',
      {'follower': follower, 'followed': followed, 'type': 'following'},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> blockUser(String blocker, String blocked) async {
    await db.insert(
      'relationships',
      {'follower': blocker, 'followed': blocked, 'type': 'blocked'},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    // Remove reverse
    await db.delete(
      'relationships',
      where: 'follower = ? AND followed = ?',
      whereArgs: [blocked, blocker],
    );
  }
  
  Future<void> unblockUser(String blocker, String blocked) async {
    await db.delete(
      'relationships',
      where: 'follower = ? AND followed = ?',
      whereArgs: [blocker, blocked],
    );
  }

  Future<Map<String, String>> getRelationships(String username) async {
    // 1. Who do I follow?
    final myActions = await db.query(
      'relationships',
      where: 'follower = ?',
      whereArgs: [username],
    );
    
    // 2. Who follows me?
    final actingOnMe = await db.query(
      'relationships',
      where: 'followed = ?',
      whereArgs: [username],
    );

    final Map<String, String> resultMap = {};
    final Set<String> followers = {};
    final Set<String> blockedBy = {};

    for (var row in actingOnMe) {
        final type = row['type'] as String;
        final person = row['follower'] as String;
        if (type == 'following') {
            followers.add(person);
        } else if (type == 'blocked') {
            blockedBy.add(person);
        }
    }

    for (var row in myActions) {
      final person = row['followed'] as String;
      final type = row['type'] as String;
      
      if (type == 'blocked') {
        resultMap[person] = 'blocked';
      } else if (type == 'following') {
         if (followers.contains(person)) {
             resultMap[person] = 'mutual';
         } else {
             resultMap[person] = 'following';
         }
      }
    }
    
    for (var person in followers) {
        if (!resultMap.containsKey(person)) {
            resultMap[person] = 'follower';
        }
    }
    
    for (var person in blockedBy) {
        if (!resultMap.containsKey(person)) {
            resultMap[person] = 'blocked_by';
        }
    }

    return resultMap;
  }
}

void main() async {
  final helper = TestDatabaseHelper();
  await helper.init();
  
  await helper.insertUser('UserA');
  await helper.insertUser('UserB');

  print('--- Test 1: UserA follows UserB ---');
  await helper.followUser('UserA', 'UserB');
  
  var relA = await helper.getRelationships('UserA');
  print('UserA relations: $relA (Expected: {UserB: following})');
  
  var relB = await helper.getRelationships('UserB');
  print('UserB relations: $relB (Expected: {UserA: follower})');
  
  if (relB['UserA'] != 'follower') {
    print('FAIL: UserB should see UserA as follower');
  }

  print('\n--- Test 2: UserB follows UserA (Mutual) ---');
  await helper.followUser('UserB', 'UserA');
  
  relA = await helper.getRelationships('UserA');
  print('UserA relations: $relA (Expected: {UserB: mutual})');
  
  relB = await helper.getRelationships('UserB');
  print('UserB relations: $relB (Expected: {UserA: mutual})');

  if (relA['UserB'] != 'mutual' || relB['UserA'] != 'mutual') {
    print('FAIL: Mutual relationship not detected');
  }

  print('\n--- Test 3: UserA Blocks UserB ---');
  await helper.blockUser('UserA', 'UserB');
  
  relA = await helper.getRelationships('UserA');
  print('UserA relations: $relA (Expected: {UserB: blocked})');
  
  relB = await helper.getRelationships('UserB');
  print('UserB relations: $relB (Expected: {UserA: blocked_by})');

  // Verify UserB's following link to UserA is GONE
  // With my fix, blockUser deletes reverse link.
  // So UserB no longer follows UserA.
  // BUT User A still appears in User B's list?
  // UserA has 'blocked' UserB.
  // UserB sees 'blocked_by' for UserA?
  // My logic:
  // actingOnMe for UserB: follower=UserA, followed=UserB. UserA blocked UserB.
  // actingOnMe finds (UserA, UserB, blocked).
  // blockedBy adds UserA.
  // resultMap adds UserA -> blocked_by.
  
  if (relA['UserB'] != 'blocked') print('FAIL: UserA should see blocked');
  if (relB['UserA'] != 'blocked_by') print('FAIL: UserB should see blocked_by');
  
  print('\n--- Test 4: UserA Unblocks UserB ---');
  await helper.unblockUser('UserA', 'UserB');
  
  relA = await helper.getRelationships('UserA');
  print('UserA relations: $relA (Expected: {})');
  
  relB = await helper.getRelationships('UserB');
  print('UserB relations: $relB (Expected: {})');
  
  // UserB should NOT be following UserA anymore, because Block removed it.
  
}
