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
//   static final columnStatus = 'status';
//
//   static final DatabaseReference _databaseReference =
//   FirebaseDatabase.instance.reference();
//   late Database _database;
//
//   DatabaseHelper._privateConstructor(){
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
//   static DatabaseHelper get instance => _instance;_initializeDatabase() async {
//     // Initialize your database here
//     _database = await initDatabase(); // Call initDatabase method to create the SQLite database
//   }
//
//   Future<Database> get database async {
//     if (_database.isOpen) return _database;
//
//     _database = await _initDatabase();
//     return _database;
//   }
//
//   Future<Database> _initDatabase() async {
//     Directory documentsDirectory = await getApplicationDocumentsDirectory();
//     String path = join(documentsDirectory.path, _databaseName);
//     return openDatabase(path, version: _databaseVersion, onCreate: _onCreate, onUpgrade: _onUpgrade);
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
//         $columnStatus INTEGER NOT NULL
//       )
//     ''');
//       print('Table created successfully: $table');
//     } catch (e) {
//       print('Error creating table: $e');
//     }
//   }
//
//   static void _onUpgrade(Database db, int oldVersion, int newVersion) {
//     // Handle database upgrades here if needed
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
//         // Query the database to check if the inserted data exists
//         List<Map<String, dynamic>> insertedData = await db.query(
//           table,
//           where: '$columnId = ?',
//           whereArgs: [result], // Assuming 'columnId' is the primary key
//         );
//
//         if (insertedData.isNotEmpty) {
//           print('Inserted data: $insertedData');
//         } else {
//           print('Inserted data not found');
//         }
//
//         // Check for internet connectivity
//         ConnectivityResult connectivityResult = await Connectivity().checkConnectivity();
//         if (connectivityResult == ConnectivityResult.wifi || connectivityResult == ConnectivityResult.mobile) {
//           // If internet connection is available, sync data with Firebase
//           await syncData();
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
//
//   Future<List<Map<String, dynamic>>> getUnsyncedRecords() async {
//     Database db = await database;
//     return await db.query(table, where: '$columnStatus = ?', whereArgs: [0]);
//   }
//
//   Future<void> updateSyncStatus(int id) async {
//     Database db = await database;
//     await db.update(table, {columnStatus: 1}, where: '$columnId = ?', whereArgs: [id]);
//   }
//
//   Future<void> syncData() async {
//     List<Map<String, dynamic>> unsyncedRecords = await getUnsyncedRecords();
//     for (var record in unsyncedRecords) {
//       try {
//         await _databaseReference.push().set({
//           columnnumber: record[columnnumber],
//           columnStatus: record[columnStatus],
//         });
//         await updateSyncStatus(record[columnId]);
//       } catch (e) {
//         print('Error syncing record: $e');
//       }
//     }
//   }
//
//   Future<Database> initDatabase() async {
//     String path = join(await getDatabasesPath(), 'cards.db');
//     return await openDatabase(
//       path,
//       version: 1,
//       onCreate: (db, version) async {
//         await db.execute('''
//           CREATE TABLE $table (
//             $columnId INTEGER PRIMARY KEY AUTOINCREMENT,
//             $columnnumber TEXT,
//            $columnCompany TEXT,
//             $columnTotalLimit INTEGER,
//             $columnTotalOutstanding INTEGER,
//             $columnBillingDate TEXT
//           )
//         ''');
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
//   Future<void> testDatabaseOperations() async {
//     DatabaseHelper databaseHelper = DatabaseHelper();
//
//     // Save data
//     CardDetails card = CardDetails(
//       cardNumber: '1234',
//       cardCompany: 'ABC Company',
//       totalLimit: 1000,
//       totalOutstanding: 500,
//       billingDate: '2022-02-28',
//     );
//     await databaseHelper.insertCard(card);
//
//     // Retrieve data
//     List<CardDetails> cards = await databaseHelper.getCards();
//
//     // Check if cards is not null and not empty before printing
//     if (cards != null && cards.isNotEmpty) {
//       // Print the retrieved data
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
// }
//
// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   await DatabaseHelper().testDatabaseOperations();
// }
//
//
//
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


import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/cupertino.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:async';
import 'dart:io';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

import 'addcard_screen/card_details.dart';

class DatabaseHelper {
  static final _databaseName = "TestDatabase.db";
  static final _databaseVersion = 1;
  static final table = 'cards';
  static final columnId = 'id';
  static final columnnumber = 'cardNumber';
  static final columnCompany = 'cardCompany';
  static final columnTotalLimit = 'totalLimit';
  static final columnTotalOutstanding = 'totalOutstanding';
  static final columnBillingDate = 'billingDate';

  static final DatabaseReference _databaseReference =
  FirebaseDatabase.instance.reference();
  late Database _database;

  DatabaseHelper._privateConstructor() {
    _initializeDatabase();
  }

  factory DatabaseHelper() {
    _instance._initializeDatabase();
    return _instance;
  }

  static final DatabaseHelper _instance = DatabaseHelper._internal();

  DatabaseHelper._internal();

  static DatabaseHelper get instance => _instance;

  _initializeDatabase() async {
    _database = await initDatabase();
    Connectivity().onConnectivityChanged.listen((ConnectivityResult result) {
      if (result == ConnectivityResult.wifi ||
          result == ConnectivityResult.mobile) {

        syncData();
      }
    });
  }

  // static void _onCreate(Database db, int version) async {
  //   try {
  //     await db.execute('''
  //     CREATE TABLE $table (
  //       $columnId INTEGER PRIMARY KEY,
  //       $columnnumber TEXT NOT NULL,
  //       $columnCompany TEXT,
  //       $columnTotalLimit INTEGER,
  //       $columnTotalOutstanding INTEGER,
  //       $columnBillingDate TEXT,
  //     )
  //   ''');
  //     print('Table created successfully: $table');
  //   } catch (e) {
  //     print('Error creating table: $e');
  //   }
  // }

  static void _onUpgrade(Database db, int oldVersion, int newVersion) {

  }

  Future<int> insertCard(CardDetails card) async {
    try {
      // Ensure that the database is initialized
      await _initializeDatabase();

      // Get a reference to the database
      Database db = await database;

      // Insert the card into the local SQLite database
      int result = await db.insert(table, card.toMap());

      // Check if the insertion was successful
      if (result != 0) {
        print('Insertion successful: $result');

        // Check for internet connectivity
        ConnectivityResult connectivityResult = await Connectivity().checkConnectivity();
        if (connectivityResult == ConnectivityResult.wifi ||
            connectivityResult == ConnectivityResult.mobile) {
          // If internet connection is available, sync data with Firebase
          syncData();
        }
      } else {
        print('Insertion failed: $result');
      }

      // Return the result of the insertion
      return result;
    } catch (e) {
      print('Error inserting card: $e');
      return 0; // Return 0 to indicate insertion failure
    }
  }

  Future<Database> get database async {
    if (_database.isOpen) return _database;

    _database = await _initializeDatabase();
    return _database;
  }

// Method to insert unsynced records into a local SQLite database table
  Future<void> insertUnsyncedRecord(Map<String, dynamic> record) async {
    Database db = await database;
    await db.insert('unsynced_records', record);
  }

  // Method to fetch all unsynced records from the local SQLite database table
  Future<List<Map<String, dynamic>>> getUnsyncedRecordsFromDB() async {
    Database db = await database;
    return await db.query('unsynced_records');
  }

  Future<void> syncData() async {
    ConnectivityResult connectivityResult =
    await Connectivity().checkConnectivity();

    await initDatabase();

    Future<List<Map<String, dynamic>>> getUnsyncedRecords() async {
      Database db = await database;
      return await db.query('unsynced_records');
    }

    if (connectivityResult != ConnectivityResult.none) {
      List<Map<String, dynamic>> unsyncedRecords = await getUnsyncedRecords();
      for (var record in unsyncedRecords) {
        try {
          // Sync data with Firebase
          await _databaseReference.push().set({
            columnnumber: record[columnnumber],
            columnnumber: record[columnnumber],
          });
          await updateSyncStatus(record[columnId]);
        } catch (e) {
          print('Error syncing record: $e');
        }
      }
    } else {
      List<Map<String, dynamic>> unsyncedRecords = await getUnsyncedRecords();
      for (var record in unsyncedRecords) {
        await insertUnsyncedRecord(record);
      }
    }
  }


  // Method to periodically check for internet connectivity and sync queued unsynced records
  void checkInternetConnectivity() {
    Connectivity().onConnectivityChanged.listen((ConnectivityResult result) {
      if (result != ConnectivityResult.none) {
        // If internet connection is available, sync queued unsynced records
        syncQueuedRecords();
      }
    });
  }

  // Method to sync queued unsynced records when internet connection is restored
  Future<void> syncQueuedRecords() async {
    List<Map<String, dynamic>> unsyncedRecords = await getUnsyncedRecordsFromDB();
    for (var record in unsyncedRecords) {
      try {
        // Sync data with Firebase
        await _databaseReference.push().set({
          columnnumber: record[columnnumber],
          columnnumber: record[columnnumber],
        });
        await updateSyncStatus(record[columnId]);
        // After successful sync, delete the record from the local database
        Database db = await database;
        await db.delete('unsynced_records', where: 'id = ?', whereArgs: [record['id']]);
      } catch (e) {
        print('Error syncing record: $e');
      }
    }
  }

  // Future<void> syncData() async {
  //   List<Map<String, dynamic>> unsyncedRecords = await getUnsyncedRecords();
  //   for (var record in unsyncedRecords) {
  //     try {
  //       await _databaseReference.push().set({
  //         columnnumber: record[columnnumber],
  //         columnnumber: record[columnnumber],
  //       });
  //       await updateSyncStatus(record[columnId]);
  //     } catch (e) {
  //       print('Error syncing record: $e');
  //       // Handle the case where there's no internet connection
  //       // You can store the unsynced record locally for later sync
  //     }
  //   }
  // }

  Future<Database> initDatabase() async {
    String path = join(await getDatabasesPath(), 'cards.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        // Create the main table
        await db.execute('''
      CREATE TABLE $table (
        $columnId INTEGER PRIMARY KEY AUTOINCREMENT,
        $columnnumber TEXT,
        $columnCompany TEXT,
        $columnTotalLimit INTEGER,
        $columnTotalOutstanding INTEGER,
        $columnBillingDate TEXT
      )
    ''');

        // Create the unsynced_records table
        await db.execute('''
      CREATE TABLE unsynced_records (
        $columnId  INTEGER PRIMARY KEY AUTOINCREMENT,
        $columnnumber TEXT,
        $columnCompany TEXT,
        $columnTotalLimit INTEGER,
        $columnTotalOutstanding INTEGER,
        $columnBillingDate TEXT
      )
    ''');
      },
    );
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

  // Future<Database> _initDatabase() async {
  //   Directory documentsDirectory = await getApplicationDocumentsDirectory();
  //   String path = join(documentsDirectory.path, _databaseName);
  //   return openDatabase(path,
  //       version: _databaseVersion, onCreate: _onCreate, onUpgrade: _onUpgrade);
  // }

  Future<void> testDatabaseOperations() async {
    DatabaseHelper databaseHelper = DatabaseHelper();

// Save data
    CardDetails card = CardDetails(
      cardNumber: '1234',
      cardCompany: 'ABC Company',
      totalLimit: 1000,
      totalOutstanding: 500,
      billingDate: '2022-02-28',
    );
    await databaseHelper.insertCard(card);

// Retrieve data
    List<CardDetails> cards = await databaseHelper.getCards();

// Check if cards is not null and not empty before printing
    if (cards != null && cards.isNotEmpty) {

      for (CardDetails card in cards) {
        print('Card Number: ${card.cardNumber}');
        print('Card Company: ${card.cardCompany}');
        print('Total Limit: ${card.totalLimit}');
        print('Total Outstanding: ${card.totalOutstanding}');
        print('Billing Date: ${card.billingDate}');
        print('------------------------');
      }
    } else {
      print('No cards found in the database.');
    }
  }

  updateSyncStatus(int id) async{
    Database db = await database;
    await db.update('unsynced_records', {'synced': 1},
        where: 'id = ?', whereArgs: [id]);
  }

  getUnsyncedRecords(int id) async{
    Database db = await database;
    await db.update('unsynced_records', {'synced': 1},
        where: 'id = ?', whereArgs: [id]);
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DatabaseHelper().testDatabaseOperations();
}
