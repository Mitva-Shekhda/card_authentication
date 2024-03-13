// import 'package:connectivity_plus/connectivity_plus.dart';
// import 'package:flutter/cupertino.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:sqflite/sqflite.dart';
// import 'package:path/path.dart';
// import 'dart:async';
// import 'dart:io';
//
// import 'package:firebase_database/firebase_database.dart';
// import 'package:flutter/material.dart';
//
// import 'addcard_screen/card_details.dart';
//
// class DatabaseHelper {
//   static final _databaseName = "TestDatabase.db";
//   static final _databaseVersion = 1;
//   static final table = 'cards';
//   static final columnId = 'id';
//   static final columnnumber = 'cardNumber';
//   static final columnCompany = 'cardCompany';
//   static final columnTotalLimit = 'totalLimit';
//   static final columnTotalOutstanding = 'totalOutstanding';
//   static final columnBillingDate = 'billingDate';
//
//   static final DatabaseReference _databaseReference =
//       FirebaseDatabase.instance.reference();
//   late Database _database;
//
//   DatabaseHelper._privateConstructor() {
//     _initializeDatabase();
//   }
//
//   factory DatabaseHelper() {
//     _instance._initializeDatabase();
//     return _instance;
//   }
//
//   static final DatabaseHelper _instance = DatabaseHelper._internal();
//
//   DatabaseHelper._internal();
//
//   static DatabaseHelper get instance => _instance;
//
//   _initializeDatabase() async {
//     _database = await initDatabase();
//     Connectivity().onConnectivityChanged.listen((ConnectivityResult result) {
//       if (result == ConnectivityResult.wifi ||
//           result == ConnectivityResult.mobile) {
//
//         syncData();
//       }
//     });
//   }
//
//   static void _onCreate(Database db, int version) async {
//     try {
//       await db.execute('''
//       CREATE TABLE $table (
//         $columnId INTEGER PRIMARY KEY,
//         $columnnumber TEXT NOT NULL,
//         $columnCompany TEXT,
//         $columnTotalLimit INTEGER,
//         $columnTotalOutstanding INTEGER,
//         $columnBillingDate TEXT,
//       )
//     ''');
//       print('Table created successfully: $table');
//     } catch (e) {
//       print('Error creating table: $e');
//     }
//   }
//
//   static void _onUpgrade(Database db, int oldVersion, int newVersion) {
//
//   }
//
//   Future<int> insertCard(CardDetails card) async {
//     try {
//       // Ensure that the database is initialized
//       await _initializeDatabase();
//
//       // Get a reference to the database
//       Database db = await database;
//
//       // Insert the card into the local SQLite database
//       int result = await db.insert(table, card.toMap());
//
//       // Check if the insertion was successful
//       if (result != 0) {
//         print('Insertion successful: $result');
//
//         // Check for internet connectivity
//         ConnectivityResult connectivityResult = await Connectivity().checkConnectivity();
//         if (connectivityResult == ConnectivityResult.wifi ||
//             connectivityResult == ConnectivityResult.mobile) {
//           // If internet connection is available, sync data with Firebase
//           syncData();
//         }
//       } else {
//         print('Insertion failed: $result');
//       }
//
//       // Return the result of the insertion
//       return result;
//     } catch (e) {
//       print('Error inserting card: $e');
//       return 0; // Return 0 to indicate insertion failure
//     }
//   }
//
//   Future<Database> get database async {
//     if (_database.isOpen) return _database;
//
//     _database = await _initDatabase();
//     return _database;
//   }
//
// // Method to insert unsynced records into a local SQLite database table
//   Future<void> insertUnsyncedRecord(Map<String, dynamic> record) async {
//     Database db = await database;
//     await db.insert('unsynced_records', record);
//   }
//
//   // Method to fetch all unsynced records from the local SQLite database table
//   Future<List<Map<String, dynamic>>> getUnsyncedRecordsFromDB() async {
//     Database db = await database;
//     return await db.query('unsynced_records');
//   }
//
//   Future<void> syncData() async {
//     ConnectivityResult connectivityResult =
//     await Connectivity().checkConnectivity();
//
//     await initDatabase();
//
//     Future<List<Map<String, dynamic>>> getUnsyncedRecords() async {
//       Database db = await database;
//       return await db.query('unsynced_records');
//     }
//
//     if (connectivityResult != ConnectivityResult.none) {
//       List<Map<String, dynamic>> unsyncedRecords = await getUnsyncedRecords();
//       for (var record in unsyncedRecords) {
//         try {
//           // Sync data with Firebase
//           await _databaseReference.push().set({
//             columnnumber: record[columnnumber],
//             columnnumber: record[columnnumber],
//           });
//           await updateSyncStatus(record[columnId]);
//         } catch (e) {
//           print('Error syncing record: $e');
//         }
//       }
//     } else {
//       List<Map<String, dynamic>> unsyncedRecords = await getUnsyncedRecords();
//       for (var record in unsyncedRecords) {
//         await insertUnsyncedRecord(record);
//       }
//     }
//   }
//
//
//   // Method to periodically check for internet connectivity and sync queued unsynced records
//   void checkInternetConnectivity() {
//     Connectivity().onConnectivityChanged.listen((ConnectivityResult result) {
//       if (result != ConnectivityResult.none) {
//         // If internet connection is available, sync queued unsynced records
//         syncQueuedRecords();
//       }
//     });
//   }
//
//   // Method to sync queued unsynced records when internet connection is restored
//   Future<void> syncQueuedRecords() async {
//     List<Map<String, dynamic>> unsyncedRecords = await getUnsyncedRecordsFromDB();
//     for (var record in unsyncedRecords) {
//       try {
//         // Sync data with Firebase
//         await _databaseReference.push().set({
//           columnnumber: record[columnnumber],
//           columnnumber: record[columnnumber],
//         });
//         await updateSyncStatus(record[columnId]);
//     // After successful sync, delete the record from the local database
//     Database db = await database;
//     await db.delete('unsynced_records', where: 'id = ?', whereArgs: [record['id']]);
//     } catch (e) {
//     print('Error syncing record: $e');
//     }
//   }
//   }
//
//   // Future<void> syncData() async {
//   //   List<Map<String, dynamic>> unsyncedRecords = await getUnsyncedRecords();
//   //   for (var record in unsyncedRecords) {
//   //     try {
//   //       await _databaseReference.push().set({
//   //         columnnumber: record[columnnumber],
//   //         columnnumber: record[columnnumber],
//   //       });
//   //       await updateSyncStatus(record[columnId]);
//   //     } catch (e) {
//   //       print('Error syncing record: $e');
//   //       // Handle the case where there's no internet connection
//   //       // You can store the unsynced record locally for later sync
//   //     }
//   //   }
//   // }
//
//   Future<Database> initDatabase() async {
//     String path = join(await getDatabasesPath(), 'cards.db');
//     return await openDatabase(
//       path,
//       version: 1,
//       onCreate: (db, version) async {
//         // Create the main table
//         await db.execute('''
//       CREATE TABLE $table (
//         $columnId INTEGER PRIMARY KEY AUTOINCREMENT,
//         $columnnumber TEXT,
//         $columnCompany TEXT,
//         $columnTotalLimit INTEGER,
//         $columnTotalOutstanding INTEGER,
//         $columnBillingDate TEXT
//       )
//     ''');
//
//         // Create the unsynced_records table
//         await db.execute('''
//       CREATE TABLE unsynced_records (
//         $columnId  INTEGER PRIMARY KEY AUTOINCREMENT,
//         $columnnumber TEXT,
//         $columnCompany TEXT,
//         $columnTotalLimit INTEGER,
//         $columnTotalOutstanding INTEGER,
//         $columnBillingDate TEXT
//       )
//     ''');
//       },
//     );
//   }
//
//   Future<List<CardDetails>> getCards() async {
//     Database db = await database;
//     List<Map<String, dynamic>> maps = await db.query('cards');
//     return List.generate(maps.length, (index) {
//       return CardDetails(
//         cardNumber: maps[index]['cardNumber'],
//         cardCompany: maps[index]['cardCompany'],
//         totalLimit: maps[index]['totalLimit'],
//         totalOutstanding: maps[index]['totalOutstanding'],
//         billingDate: maps[index]['billingDate'],
//       );
//     });
//   }
//
//   Future<Database> _initDatabase() async {
//     Directory documentsDirectory = await getApplicationDocumentsDirectory();
//     String path = join(documentsDirectory.path, _databaseName);
//     return openDatabase(path,
//         version: _databaseVersion, onCreate: _onCreate, onUpgrade: _onUpgrade);
//   }
//
//   Future<void> testDatabaseOperations() async {
//     DatabaseHelper databaseHelper = DatabaseHelper();
//
// // Save data
//     CardDetails card = CardDetails(
//       cardNumber: '1234',
//       cardCompany: 'ABC Company',
//       totalLimit: 1000,
//       totalOutstanding: 500,
//       billingDate: '2022-02-28',
//     );
//     await databaseHelper.insertCard(card);
//
// // Retrieve data
//     List<CardDetails> cards = await databaseHelper.getCards();
//
// // Check if cards is not null and not empty before printing
//     if (cards != null && cards.isNotEmpty) {
//
//       for (CardDetails card in cards) {
//         print('Card Number: ${card.cardNumber}');
//         print('Card Company: ${card.cardCompany}');
//         print('Total Limit: ${card.totalLimit}');
//         print('Total Outstanding: ${card.totalOutstanding}');
//         print('Billing Date: ${card.billingDate}');
//         print('------------------------');
//       }
//     } else {
//       print('No cards found in the database.');
//     }
//   }
//
//   updateSyncStatus(int id) async{
//     Database db = await database;
//     await db.update('unsynced_records', {'synced': 1},
//         where: 'id = ?', whereArgs: [id]);
//   }
//
//   getUnsyncedRecords(int id) async{
//     Database db = await database;
//     await db.update('unsynced_records', {'synced': 1},
//         where: 'id = ?', whereArgs: [id]);
//   }
// }
//
// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   await DatabaseHelper().testDatabaseOperations();
// }


// import 'package:connectivity_plus/connectivity_plus.dart';
// import 'package:flutter/cupertino.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:sqflite/sqflite.dart';
// import 'package:path/path.dart';
// import 'dart:async';
// import 'dart:io';
//
// import 'package:firebase_database/firebase_database.dart';
// import 'package:flutter/material.dart';
//
// import 'addcard_screen/card_details.dart';
//
// class DatabaseHelper {
//   static final _databaseName = "TestDatabase.db";
//   static final _databaseVersion = 1;
//   static final table = 'cards';
//   static final columnId = 'id';
//   static final columnnumber = 'cardNumber';
//   static final columnCompany = 'cardCompany';
//   static final columnTotalLimit = 'totalLimit';
//   static final columnTotalOutstanding = 'totalOutstanding';
//   static final columnBillingDate = 'billingDate';
//
//   static final DatabaseReference _databaseReference =
//   FirebaseDatabase.instance.reference();
//   late Database _database;
//
//   DatabaseHelper._privateConstructor() {
//     _initializeDatabase();
//   }
//
//   factory DatabaseHelper() {
//     _instance._initializeDatabase();
//     return _instance;
//   }
//
//   static final DatabaseHelper _instance = DatabaseHelper._internal();
//
//   DatabaseHelper._internal();
//
//   static DatabaseHelper get instance => _instance;
//
//   _initializeDatabase() async {
//     _database = await initDatabase();
//     Connectivity().onConnectivityChanged.listen((ConnectivityResult result) {
//       if (result == ConnectivityResult.wifi ||
//           result == ConnectivityResult.mobile) {
//
//         syncData();
//       }
//     });
//   }
//
//   // static void _onCreate(Database db, int version) async {
//   //   try {
//   //     await db.execute('''
//   //     CREATE TABLE $table (
//   //       $columnId INTEGER PRIMARY KEY,
//   //       $columnnumber TEXT NOT NULL,
//   //       $columnCompany TEXT,
//   //       $columnTotalLimit INTEGER,
//   //       $columnTotalOutstanding INTEGER,
//   //       $columnBillingDate TEXT,
//   //     )
//   //   ''');
//   //     print('Table created successfully: $table');
//   //   } catch (e) {
//   //     print('Error creating table: $e');
//   //   }
//   // }
//
//   static void _onUpgrade(Database db, int oldVersion, int newVersion) {
//   }
//
//   Future<int> insertCard(CardDetails card) async {
//     try {
//       // Ensure that the database is initialized
//       await _initializeDatabase();
//
//       // Get a reference to the database
//       Database db = await database;
//
//       // Insert the card into the local SQLite database
//       int result = await db.insert(table, card.toMap());
//
//       // Check if the insertion was successful
//       if (result != 0) {
//         print('Insertion successful: $result');
//
//         // Check for internet connectivity
//         ConnectivityResult connectivityResult = await Connectivity().checkConnectivity();
//         if (connectivityResult == ConnectivityResult.wifi ||
//             connectivityResult == ConnectivityResult.mobile) {
//           // If internet connection is available, sync data with Firebase
//           syncData();
//         }
//       } else {
//         print('Insertion failed: $result');
//       }
//
//       // Return the result of the insertion
//       return result;
//     } catch (e) {
//       print('Error inserting card: $e');
//       return 0; // Return 0 to indicate insertion failure
//     }
//   }
//
//   Future<Database> get database async {
//     if (_database.isOpen) return _database;
//
//     _database = await _initializeDatabase();
//     return _database;
//   }
//
// // Method to insert unsynced records into a local SQLite database table
//   Future<void> insertUnsyncedRecord(Map<String, dynamic> record) async {
//     Database db = await database;
//     await db.insert('unsynced_records', record);
//   }
//
//   // Method to fetch all unsynced records from the local SQLite database table
//   Future<List<Map<String, dynamic>>> getUnsyncedRecordsFromDB() async {
//     Database db = await database;
//     return await db.query('unsynced_records');
//   }
//
//   Future<void> syncData() async {
//     ConnectivityResult connectivityResult =
//     await Connectivity().checkConnectivity();
//
//     await initDatabase();
//
//     Future<List<Map<String, dynamic>>> getUnsyncedRecords() async {
//       Database db = await database;
//       return await db.query('unsynced_records');
//     }
//
//     if (connectivityResult != ConnectivityResult.none) {
//       List<Map<String, dynamic>> unsyncedRecords = await getUnsyncedRecords();
//       for (var record in unsyncedRecords) {
//         try {
//           // Sync data with Firebase
//           await _databaseReference.push().set({
//             columnnumber: record[columnnumber],
//             columnnumber: record[columnnumber],
//           });
//           await updateSyncStatus(record[columnId]);
//         } catch (e) {
//           print('Error syncing record: $e');
//         }
//       }
//     } else {
//       List<Map<String, dynamic>> unsyncedRecords = await getUnsyncedRecords();
//       for (var record in unsyncedRecords) {
//         await insertUnsyncedRecord(record);
//       }
//     }
//   }
//
//
//   // Method to periodically check for internet connectivity and sync queued unsynced records
//   void checkInternetConnectivity() {
//     Connectivity().onConnectivityChanged.listen((ConnectivityResult result) {
//       if (result != ConnectivityResult.none) {
//         // If internet connection is available, sync queued unsynced records
//         syncQueuedRecords();
//       }
//     });
//   }
//
//   // Method to sync queued unsynced records when internet connection is restored
//   Future<void> syncQueuedRecords() async {
//     List<Map<String, dynamic>> unsyncedRecords = await getUnsyncedRecordsFromDB();
//     for (var record in unsyncedRecords) {
//       try {
//         // Sync data with Firebase
//         await _databaseReference.push().set({
//           columnnumber: record[columnnumber],
//           columnnumber: record[columnnumber],
//         });
//         await updateSyncStatus(record[columnId]);
//         // After successful sync, delete the record from the local database
//         Database db = await database;
//         await db.delete('unsynced_records', where: 'id = ?', whereArgs: [record['id']]);
//       } catch (e) {
//         print('Error syncing record: $e');
//       }
//     }
//   }
//
//   // Future<void> syncData() async {
//   //   List<Map<String, dynamic>> unsyncedRecords = await getUnsyncedRecords();
//   //   for (var record in unsyncedRecords) {
//   //     try {
//   //       await _databaseReference.push().set({
//   //         columnnumber: record[columnnumber],
//   //         columnnumber: record[columnnumber],
//   //       });
//   //       await updateSyncStatus(record[columnId]);
//   //     } catch (e) {
//   //       print('Error syncing record: $e');
//   //       // Handle the case where there's no internet connection
//   //       // You can store the unsynced record locally for later sync
//   //     }
//   //   }
//   // }
//
//   Future<Database> initDatabase() async {
//     String path = join(await getDatabasesPath(), 'cards.db');
//     return await openDatabase(
//       path,
//       version: 1,
//       onCreate: (db, version) async {
//         // Create the main table
//         await db.execute('''
//       CREATE TABLE $table (
//         $columnId INTEGER PRIMARY KEY AUTOINCREMENT,
//         $columnnumber TEXT,
//         $columnCompany TEXT,
//         $columnTotalLimit INTEGER,
//         $columnTotalOutstanding INTEGER,
//         $columnBillingDate TEXT
//       )
//     ''');
//
//         // Create the unsynced_records table
//         await db.execute('''
//       CREATE TABLE unsynced_records (
//         $columnId  INTEGER PRIMARY KEY AUTOINCREMENT,
//         $columnnumber TEXT,
//         $columnCompany TEXT,
//         $columnTotalLimit INTEGER,
//         $columnTotalOutstanding INTEGER,
//         $columnBillingDate TEXT
//       )
//     ''');
//       },
//     );
//   }
//
//   Future<List<CardDetails>> getCards() async {
//     Database db = await database;
//     List<Map<String, dynamic>> maps = await db.query('cards');
//     return List.generate(maps.length, (index) {
//       return CardDetails(
//         cardNumber: maps[index]['cardNumber'],
//         cardCompany: maps[index]['cardCompany'],
//         totalLimit: maps[index]['totalLimit'],
//         totalOutstanding: maps[index]['totalOutstanding'],
//         billingDate: maps[index]['billingDate'],
//       );
//     });
//   }
//
//   // Future<Database> _initDatabase() async {
//   //   Directory documentsDirectory = await getApplicationDocumentsDirectory();
//   //   String path = join(documentsDirectory.path, _databaseName);
//   //   return openDatabase(path,
//   //       version: _databaseVersion, onCreate: _onCreate, onUpgrade: _onUpgrade);
//   // }
//
//   Future<void> testDatabaseOperations() async {
//     DatabaseHelper databaseHelper = DatabaseHelper();
//
// // Save data
//     CardDetails card = CardDetails(
//       cardNumber: '1234',
//       cardCompany: 'ABC Company',
//       totalLimit: 1000,
//       totalOutstanding: 500,
//       billingDate: '2022-02-28',
//     );
//     await databaseHelper.insertCard(card);
//
// // Retrieve data
//     List<CardDetails> cards = await databaseHelper.getCards();
//
// // Check if cards is not null and not empty before printing
//     if (cards != null && cards.isNotEmpty) {
//
//       for (CardDetails card in cards) {
//         print('Card Number: ${card.cardNumber}');
//         print('Card Company: ${card.cardCompany}');
//         print('Total Limit: ${card.totalLimit}');
//         print('Total Outstanding: ${card.totalOutstanding}');
//         print('Billing Date: ${card.billingDate}');
//         print('------------------------');
//       }
//     } else {
//       print('No cards found in the database.');
//     }
//   }
//
//   updateSyncStatus(int id) async{
//     Database db = await database;
//     await db.update('unsynced_records', {'synced': 1},
//         where: 'id = ?', whereArgs: [id]);
//   }
//
//   getUnsyncedRecords(int id) async{
//     Database db = await database;
//     await db.update('unsynced_records', {'synced': 1},
//         where: 'id = ?', whereArgs: [id]);
//   }
// }
//
// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   await DatabaseHelper().testDatabaseOperations();
// }


import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/cupertino.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

import 'addcard_screen/card_details.dart';
import 'package:firebase_database/firebase_database.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();

  factory DatabaseHelper() {
    return _instance;
  }

  static DatabaseHelper get instance => _instance;

  DatabaseHelper._internal();

  static Database? _database;
  static final DatabaseReference _databaseReference =
  FirebaseDatabase.instance.reference().child('cards');

  List<Map<String, dynamic>> _unsyncedRecords = [];

  Future<Database> get database async {
    if (_database != null) return _database!;

    _database = await initDatabase();
    return _database!;
  }

  Future<Database> initDatabase() async {
    String path = join(await getDatabasesPath(), 'cards.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE cards (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            cardNumber TEXT,
            cardCompany TEXT,
            totalLimit INTEGER,
            totalOutstanding INTEGER,
            billingDate TEXT
          )
        ''');
      },
    );
  }

  Future<int> insertCard(CardDetails card) async {
    if (await checkInternetConnectivity()) {
      try {
        await _databaseReference.push().set(card.toMap());
        return 1;
      } catch (e) {
        print('Error storing data to Firebase: $e');
        return 0;
      }
    } else {
      Database db = await database;
      int result = await db.insert('cards', card.toMap());
      if (result != 0) {
        _unsyncedRecords.add(card.toMap());
        print('Data stored to SQLite.');
      }
      return result;
    }
  }

  Future<List<CardDetails>> getCards() async {
    Database db = await database;
    List<Map<String, dynamic>> maps = await db.query('cards');
    return List.generate(maps.length, (index) {
      return CardDetails(
        cardNumber: maps[index]['cardNumber'],
        cardCompany: maps[index]['cardCompany'],
        totalLimit: maps[index]['totalLimit'],
        totalOutstanding: maps[index]['totalOutstanding'],
        billingDate: maps[index]['billingDate'],
      );
    });
  }

  Future<bool> checkInternetConnectivity() async {
    var connectivityResult = await Connectivity().checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }

  Future<void> syncData() async {
    if (await checkInternetConnectivity()) {
      for (var record in _unsyncedRecords) {
        try {
          await _databaseReference.push().set(record);
        } catch (e) {
          print('Error syncing record: $e');
        }
      }

      _unsyncedRecords.clear();
    }
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  var dbHelper = DatabaseHelper.instance;
  var card = CardDetails(
    cardNumber: '1234',
    cardCompany: 'ABC Company',
    totalLimit: 1000,
    totalOutstanding: 500,
    billingDate: '2022-02-28',
  );
  var result = await dbHelper.insertCard(card);
  if (result == 1) {
    print('Data stored to Firebase.');
  } else {
    print('Data stored to SQLite.');
  }

  await dbHelper.syncData();
}
