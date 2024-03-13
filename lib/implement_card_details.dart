import 'dart:developer';
import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:new_firebase_login/show_details_screen/view_showdetails.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:new_firebase_login/database_helper.dart';
import 'addcard_screen/card_details.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;



class AddCardScreen extends StatelessWidget {
  final TextEditingController cardNumberController = TextEditingController();
  final TextEditingController cardCompanyController = TextEditingController();
  final TextEditingController totalLimitController = TextEditingController();
  final TextEditingController totalOutstandingController = TextEditingController();
  final TextEditingController billingDateController = TextEditingController();

  var selectedDate = DateTime.now();

  FirebaseMessaging messaging = FirebaseMessaging.instance;

  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final User? user = FirebaseAuth.instance.currentUser;

  // Initialize Flutter Local Notifications Plugin
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  void addCardDetails(BuildContext context) async {
    // Get the cur]rent user
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      // User is signed in, get the UID
      String userUid = user.uid;

      // Store card data under the user document
      FirebaseFirestore.instance.collection('users').doc(userUid).collection('cards').add({
        'cardCompany': cardCompanyController.text,
        'totalLimit': int.parse(totalLimitController.text),
        'totalOutstanding': int.parse(totalOutstandingController.text),
        'billingDate': billingDateController.text,
      }).then((value) {
        Navigator.push(context, MaterialPageRoute(builder: (context) => ShowDetailsScreen()));

        cardNumberController.clear();
        cardCompanyController.clear();
        totalLimitController.clear();
        totalOutstandingController.clear();
        billingDateController.clear();
      }).catchError((error) {
        // Error handling
        print("Failed to add card: $error");
      });
    } else {
      print("no user sign in");
    }

    // Check if the entered values are valid integers
    int? totalLimit = int.tryParse(totalLimitController.text);
    int? totalOutstanding = int.tryParse(totalOutstandingController.text);

    if (totalLimit == null || totalOutstanding == null) {
      // Show error message if the entered values are not valid integers
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Total Limit and Total Outstanding must be valid integers')),
      );
      return;
    }
    // Create a CardDetails object with the entered data
    CardDetails card = CardDetails(
      cardNumber: cardNumberController.text,
      cardCompany: cardCompanyController.text,
      totalLimit: int.parse(totalLimitController.text),
      totalOutstanding: int.parse(totalOutstandingController.text),
      billingDate: billingDateController.text,
    );

    DatabaseHelper databaseHelper = DatabaseHelper();

    int result = await DatabaseHelper.instance.insertCard(card);

    if (result != 0) {
      // Data inserted successfully
      //print('result' $result);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Card added successfully')),
      );
      cardNumberController.clear();
      cardCompanyController.clear();
      totalLimitController.clear();
      totalOutstandingController.clear();
      billingDateController.clear();

    } else {
      // Failed to insert data
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add card')),
      );
    }
  }

  void requestNotificationPermission() async {
    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    final bool? grantedNotificationPermission = await androidImplementation?.requestExactAlarmsPermission() ?? false;

    log('grantedNotificationPermission: $grantedNotificationPermission');
    NotificationSettings settings = await messaging.requestPermission(
        alert: true,
        announcement: true,
        badge: true,
        carPlay: true,
        criticalAlert: true,
        provisional: true,
        sound: true);

    if (kDebugMode) {
      print('Permission granted: ${settings.authorizationStatus}');
    }

    // if(settings.authorizationStatus == AuthorizationStatus.authorized){
    //   print('User granted Permission');
    // }else if(settings.authorizationStatus == AuthorizationStatus.authorized) {
    //   print('enter granted permision');
    // }else{
    //   print('user denide permision');
    // }
  }

  void scheduleNotifications(DateTime dueDate, BuildContext context) async {
    try {
      const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
          final InitializationSettings initializationSettings = InitializationSettings(
            android: initializationSettingsAndroid,
          );
          await flutterLocalNotificationsPlugin.initialize(initializationSettings,
              onDidReceiveNotificationResponse: onDidReceiveNotificationResponse);
      tz.initializeTimeZones(); // added this to initialize timezones ref: https://pub.dev/packages/flutter_local_notifications#scheduling-a-notification
      log('dueDate: $dueDate');
      log('selectedDate: $selectedDate');
      log("scheduledDate _nextInstanceOfDate: ${_nextInstanceOfDate(dueDate)}");
      log("scheduledDate _nextInstanceOfDate: ${_nextInstanceOfDate(selectedDate)}");
      // Schedule notification for due date
      await flutterLocalNotificationsPlugin.zonedSchedule(
        0, // Unique ID for due date notification
        'Due Date Notification',
        'Your payment is due today!',
        _nextInstanceOfDate(dueDate),
        androidScheduleMode: AndroidScheduleMode.alarmClock,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'payment_reminder_channel', // Your channel ID
            'Payment Reminders', // Your channel name
            //'your channel description',
            importance: Importance.max,
            priority: Priority.high,
            showWhen: true,
              icon: '@mipmap/ic_launcher',
          ),
        ),
        androidAllowWhileIdle: true,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      );

      // Calculate three days before the due date
      DateTime threeDaysBeforeDueDate = dueDate.subtract(Duration(days: 3));

      // Check if threeDaysBeforeDueDate is before the current date and time
      if (threeDaysBeforeDueDate.isBefore(DateTime.now())) {
        // If it is less, make it 10 minutes after the current date and time
        threeDaysBeforeDueDate = DateTime.now().add(Duration(minutes: 1));
      }

      // Schedule notification for three days before due date
      await flutterLocalNotificationsPlugin.zonedSchedule(
        1, // Unique ID for three days before notification
        'Reminder h',
        'Your payment is due in 3 days.',
        _nextInstanceOfDate(threeDaysBeforeDueDate),
        androidScheduleMode: AndroidScheduleMode.alarmClock,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'payment_reminder_channel', // Same channel ID as above
            'Payment Reminders', // Same channel name as above
            // 'your channel description',
            importance: Importance.max,
            priority: Priority.high,
            showWhen: true,
              icon: '@mipmap/ic_launcher',
          ),
        ),
        androidAllowWhileIdle: true,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      );

      print("Notifications scheduled successfully");
      // Get the list of pending notifications
      List<PendingNotificationRequest> pendingNotifications =
          await flutterLocalNotificationsPlugin.pendingNotificationRequests();
      print('Pending Notifications: $pendingNotifications');
    } catch (e) {
      print("Error scheduling notifications: $e");
    }
  }

  tz.TZDateTime _nextInstanceOfDate(DateTime scheduledDate) {
    log('_nextInstanceOfDate scheduledDate : $scheduledDate');
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    late tz.TZDateTime scheduledDateTZ;
    scheduledDateTZ = tz.TZDateTime(
        tz.local, scheduledDate.year, scheduledDate.month, scheduledDate.day, scheduledDate.hour, scheduledDate.minute);
    if (scheduledDateTZ.isBefore(now)) {
      scheduledDateTZ = scheduledDateTZ.add(Duration(days: 1));
    }
    log('_nextInstanceOfDate scheduledDateTZ : $scheduledDateTZ');
    return scheduledDateTZ;
  }

  void onDidReceiveNotificationResponse(NotificationResponse notificationResponse) async {
    final String? payload = notificationResponse.payload;
    if (notificationResponse.payload != null) {
      debugPrint('notification payload: $payload');
    }
    print("object");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // floatingActionButton: FloatingActionButton(
      //   onPressed: () async {
      //     const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
      //     final InitializationSettings initializationSettings = InitializationSettings(
      //       android: initializationSettingsAndroid,
      //     );
      //     await flutterLocalNotificationsPlugin.initialize(initializationSettings,
      //         onDidReceiveNotificationResponse: onDidReceiveNotificationResponse);
      //     const AndroidNotificationDetails androidNotificationDetails = AndroidNotificationDetails(
      //       'your channel id',
      //       'your channel name',
      //       channelDescription: 'your channel description',
      //       importance: Importance.max,
      //       priority: Priority.high,
      //       ticker: 'ticker',
      //       icon: '@mipmap/ic_launcher',
      //     );
      //     const NotificationDetails notificationDetails = NotificationDetails(android: androidNotificationDetails);
      //     await flutterLocalNotificationsPlugin.show(0, 'plain title', 'plain body', notificationDetails,
      //         payload: 'item x');
      //     List<PendingNotificationRequest> pendingNotifications =
      //         await flutterLocalNotificationsPlugin.pendingNotificationRequests();
      //     pendingNotifications.forEach((element) {
      //       print('Pending Notifications: ${element.id}');
      //       print('Pending Notifications: ${element.title}');
      //       print('Pending Notifications: ${element.body}');
      //       print('Pending Notifications: ${element.payload}');
      //     });

        //   print(_nextInstanceOfDate(DateTime.now()));
        // },
        // child: Icon(Icons.arrow_back),
      //),
      appBar: AppBar(title: Text('Add Card'), automaticallyImplyLeading: false),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(controller: cardNumberController, decoration: InputDecoration(labelText: 'Card Number')),
              TextField(controller: cardCompanyController, decoration: InputDecoration(labelText: 'Card Company')),
              TextField(
                  controller: totalLimitController,
                  decoration: InputDecoration(labelText: 'Total Limit'),
                  keyboardType: TextInputType.number),
              TextField(
                  controller: totalOutstandingController,
                  decoration: InputDecoration(labelText: 'Total Outstanding'),
                  keyboardType: TextInputType.number),
              TextField(
                  controller: billingDateController,
                  decoration: InputDecoration(labelText: 'Billing Date'),
                  keyboardType: TextInputType.datetime,
                  onTap: () {
                    selectDateTime(context);
                  }),
              SizedBox(height: 16),
              ElevatedButton(
                  onPressed: () {
                    addCardDetails(context);
                    //requestNotificationPermission();
                    //scheduleNotifications(selectedDate, context);
                    DatabaseHelper ();
                  },
                  child: Text('Add Card')),
              ElevatedButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ShowDetailsScreen()),
                ),
                child: Text('Show Details'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> selectDateTime(BuildContext context) async {
    final todayDate = DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(todayDate.year, todayDate.month, todayDate.day),
      lastDate: DateTime(todayDate.year + 1, todayDate.month, todayDate.day),
    );

    if (pickedDate != null) {
      selectedDate = pickedDate; // Update selectedDate with the picked date

      // Update the text in the DateTime text field when a date and time are selected
      billingDateController.text = "${DateFormat('dd-MM-yyyy').format(selectedDate)}";
    }
  }
}

class _instance {
}



// import 'dart:developer';
//
// import 'package:firebase_messaging/firebase_messaging.dart';
// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'package:new_firebase_login/show_details_screen/view_showdetails.dart';
// import 'package:intl/intl.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:new_firebase_login/database_helper.dart';
// import 'package:path/path.dart';
// import 'addcard_screen/card_details.dart';
// import 'package:timezone/data/latest_all.dart' as tz;
// import 'package:timezone/timezone.dart' as tz;
//
//
// class AddCardScreen extends StatelessWidget {
//   final TextEditingController cardNumberController = TextEditingController();
//   final TextEditingController cardCompanyController = TextEditingController();
//   final TextEditingController totalLimitController = TextEditingController();
//   final TextEditingController totalOutstandingController = TextEditingController();
//   final TextEditingController billingDateController = TextEditingController();
//
//   var selectedDate = DateTime.now();
//
//   FirebaseMessaging messaging = FirebaseMessaging.instance;
//
//   final FirebaseFirestore firestore = FirebaseFirestore.instance;
//   final User? user = FirebaseAuth.instance.currentUser;
//
//   // Initialize Flutter Local Notifications Plugin
//   final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
//   Future<void> main() async {
//     WidgetsFlutterBinding.ensureInitialized();
//
//     const AndroidInitializationSettings initializationSettingsAndroid =
//     AndroidInitializationSettings('@mipmap/ic_launcher');
//     final InitializationSettings initializationSettings =
//     InitializationSettings(android: initializationSettingsAndroid);
//
//     await flutterLocalNotificationsPlugin.initialize(
//       initializationSettings,
//       onSelectNotification: (String? payload) async {
//         if (payload != null) {
//           debugPrint('notification payload: $payload');
//         }
//       },
//     );
//     final DateTime now = DateTime.now();
//     final DateTime scheduledDate = DateTime(now.year, now.month, now.day, 10, 0); // Example: 10:00 AM today
//
//
//     Future<void> scheduleNotification(DateTime scheduledDate, BuildContext context) async {
//       final location = tz.getLocation('Your Timezone Here'); // Example: 'America/New_York'
//       final scheduledDateTime = tz.TZDateTime.from(scheduledDate, location);
//
//       const AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
//         'your channel id',
//         'your channel name',
//         channelDescription: 'your channel description',
//         importance: Importance.max,
//         priority: Priority.high,
//       );
//       const NotificationDetails platformChannelSpecifics = NotificationDetails(android: androidPlatformChannelSpecifics);
//
//       await flutterLocalNotificationsPlugin.zonedSchedule(
//         0, // Notification ID
//         'Scheduled Title', // Notification title
//         'Scheduled Body', // Notification body
//         scheduledDateTime, // Scheduled date and time
//         platformChannelSpecifics,
//         uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
//         androidAllowWhileIdle: true,
//         matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
//       );
//     }
//
//
//     void addCardDetails(BuildContext context) async {
//     // Get the current user
//     User? user = FirebaseAuth.instance.currentUser;
//
//     if (user != null) {
//       // User is signed in, get the UID
//       String userUid = user.uid;
//
//       // Store card data under the user document
//       FirebaseFirestore.instance.collection('users').doc(userUid).collection('cards').add({
//         'cardNumber': cardNumberController.text,
//         'cardCompany': cardCompanyController.text,
//         'totalLimit': int.parse(totalLimitController.text),
//         'totalOutstanding': int.parse(totalOutstandingController.text),
//         'billingDate': billingDateController.text,
//       }).then((value) {
//         Navigator.push(context, MaterialPageRoute(builder: (context) => ShowDetailsScreen()));
//
//         cardNumberController.clear();
//         cardCompanyController.clear();
//         totalLimitController.clear();
//         totalOutstandingController.clear();
//         billingDateController.clear();
//       }).catchError((error) {
//         // Error handling
//         print("Failed to add card: $error");
//       });
//     } else {
//       print("no user sign in");
//     }
//
//     // Check if the entered values are valid integers
//     int? totalLimit = int.tryParse(totalLimitController.text);
//     int? totalOutstanding = int.tryParse(totalOutstandingController.text);
//
//     if (totalLimit == null || totalOutstanding == null) {
//       // Show error message if the entered values are not valid integers
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Total Limit and Total Outstanding must be valid integers')),
//       );
//       return;
//     }
//     // Create a CardDetails object with the entered data
//     CardDetails card = CardDetails(
//       cardNumber: cardNumberController.text,
//       cardCompany: cardCompanyController.text,
//       totalLimit: int.parse(totalLimitController.text),
//       totalOutstanding: int.parse(totalOutstandingController.text),
//       billingDate: billingDateController.text,
//     );
//
//     // Instantiate the DatabaseHelper
//     DatabaseHelper databaseHelper = DatabaseHelper();
//
//     // Insert the card data into the SQLite database
//     int result = await databaseHelper.insertCard(card);
//
//     if (result != 0) {
//       // Data inserted successfully
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Card added successfully')),
//       );
//
//       // Clear text controllers
//       cardNumberController.clear();
//       cardCompanyController.clear();
//       totalLimitController.clear();
//       totalOutstandingController.clear();
//       billingDateController.clear();
//
//       // Navigate to the show details screen
//       // Navigator.push(
//       //   context,
//       //   MaterialPageRoute(builder: (context) => ShowDetailsScreen()),
//       // );
//     } else {
//       // Failed to insert data
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Failed to add card')),
//       );
//     }
//     // // Schedule notifications
//     // DateTime selectedDate = DateTime
//     //     .now();
//     // scheduleDueDateNotification(selectedDate);
//     // scheduleThreeDaysBeforeNotification(selectedDate);
//   }
//
//   void requestNotificationPermission() async {
//     final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
//     flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
//     final bool? grantedNotificationPermission = await androidImplementation?.requestExactAlarmsPermission() ?? false;
//
//     log('grantedNotificationPermission: $grantedNotificationPermission');
//     NotificationSettings settings = await messaging.requestPermission(
//         alert: true,
//         announcement: true,
//         badge: true,
//         carPlay: true,
//         criticalAlert: true,
//         provisional: true,
//         sound: true);
//
//     if (kDebugMode) {
//       print('Permission granted: ${settings.authorizationStatus}');
//     }
//
//     // if(settings.authorizationStatus == AuthorizationStatus.authorized){
//     //   print('User granted Permission');
//     // }else if(settings.authorizationStatus == AuthorizationStatus.authorized) {
//     //   print('enter granted permision');
//     // }else{
//     //   print('user denide permision');
//     // }
//   }
//
//   // void scheduleNotifications(DateTime dueDate, BuildContext context) async {
//   //   try {
//   //     const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
//   //     final InitializationSettings initializationSettings = InitializationSettings(
//   //       android: initializationSettingsAndroid,
//   //     );
//   //     await flutterLocalNotificationsPlugin.initialize(initializationSettings,
//   //         onDidReceiveNotificationResponse: onDidReceiveNotificationResponse);
//   //     tz.initializeTimeZones(); // added this to initialize timezones ref: https://pub.dev/packages/flutter_local_notifications#scheduling-a-notification
//   //     log('dueDate: $dueDate');
//   //     log('selectedDate: $selectedDate');
//   //     log("scheduledDate _nextInstanceOfDate: ${_nextInstanceOfDate(dueDate)}");
//   //     log("scheduledDate _nextInstanceOfDate: ${_nextInstanceOfDate(selectedDate)}");
//   //     // Schedule notification for due date
//   //     await flutterLocalNotificationsPlugin.zonedSchedule(
//   //       0, // Unique ID for due date notification
//   //       'Due Date Notification',
//   //       'Your payment is due today!',
//   //       _nextInstanceOfDate(dueDate),
//   //       androidScheduleMode: AndroidScheduleMode.alarmClock,
//   //       const NotificationDetails(
//   //         android: AndroidNotificationDetails(
//   //           'payment_reminder_channel', // Your channel ID
//   //           'Payment Reminders', // Your channel name
//   //           //'your channel description',
//   //           importance: Importance.max,
//   //           priority: Priority.high,
//   //           showWhen: true,
//   //           icon: '@mipmap/ic_launcher',
//   //         ),
//   //       ),
//   //       androidAllowWhileIdle: true,
//   //       uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
//   //     );
//   //
//   //     // Calculate three days before the due date
//   //     DateTime threeDaysBeforeDueDate = dueDate.subtract(Duration(days: 3));
//   //
//   //     // Check if threeDaysBeforeDueDate is before the current date and time
//   //     if (threeDaysBeforeDueDate.isBefore(DateTime.now())) {
//   //       // If it is less, make it 10 minutes after the current date and time
//   //       threeDaysBeforeDueDate = DateTime.now().add(Duration(minutes: 1));
//   //     }
//   //
//   //     // Schedule notification for three days before due date
//   //     await flutterLocalNotificationsPlugin.zonedSchedule(
//   //       1, // Unique ID for three days before notification
//   //       'Reminder h',
//   //       'Your payment is due in 3 days.',
//   //       _nextInstanceOfDate(threeDaysBeforeDueDate),
//   //       androidScheduleMode: AndroidScheduleMode.alarmClock,
//   //       const NotificationDetails(
//   //         android: AndroidNotificationDetails(
//   //           'payment_reminder_channel', // Same channel ID as above
//   //           'Payment Reminders', // Same channel name as above
//   //           // 'your channel description',
//   //           importance: Importance.max,
//   //           priority: Priority.high,
//   //           showWhen: true,
//   //           icon: '@mipmap/ic_launcher',
//   //         ),
//   //       ),
//   //       androidAllowWhileIdle: true,
//   //       uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
//   //     );
//   //
//   //     print("Notifications scheduled successfully");
//   //     // Get the list of pending notifications
//   //     List<PendingNotificationRequest> pendingNotifications =
//   //     await flutterLocalNotificationsPlugin.pendingNotificationRequests();
//   //     print('Pending Notifications: $pendingNotifications');
//   //   } catch (e) {
//   //     print("Error scheduling notifications: $e");
//   //   }
//   // }
//   //
//   // tz.TZDateTime _nextInstanceOfDate(DateTime scheduledDate) {
//   //   log('_nextInstanceOfDate scheduledDate : $scheduledDate');
//   //   final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
//   //   late tz.TZDateTime scheduledDateTZ;
//   //   scheduledDateTZ = tz.TZDateTime(
//   //       tz.local, scheduledDate.year, scheduledDate.month, scheduledDate.day, scheduledDate.hour, scheduledDate.minute);
//   //   if (scheduledDateTZ.isBefore(now)) {
//   //     scheduledDateTZ = scheduledDateTZ.add(Duration(days: 1));
//   //   }
//   //   log('_nextInstanceOfDate scheduledDateTZ : $scheduledDateTZ');
//   //   return scheduledDateTZ;
//   // }
//   //
//   // void onDidReceiveNotificationResponse(NotificationResponse notificationResponse) async {
//   //   final String? payload = notificationResponse.payload;
//   //   if (notificationResponse.payload != null) {
//   //     debugPrint('notification payload: $payload');
//   //   }
//   //   print("object");
//   // }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       // floatingActionButton: FloatingActionButton(
//       //   onPressed: () async {
//       //     const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
//       //     final InitializationSettings initializationSettings = InitializationSettings(
//       //       android: initializationSettingsAndroid,
//       //     );
//       //     await flutterLocalNotificationsPlugin.initialize(initializationSettings,
//       //         onDidReceiveNotificationResponse: onDidReceiveNotificationResponse);
//       //     const AndroidNotificationDetails androidNotificationDetails = AndroidNotificationDetails(
//       //       'your channel id',
//       //       'your channel name',
//       //       channelDescription: 'your channel description',
//       //       importance: Importance.max,
//       //       priority: Priority.high,
//       //       ticker: 'ticker',
//       //       icon: '@mipmap/ic_launcher',
//       //     );
//       //     const NotificationDetails notificationDetails = NotificationDetails(android: androidNotificationDetails);
//       //     await flutterLocalNotificationsPlugin.show(0, 'plain title', 'plain body', notificationDetails,
//       //         payload: 'item x');
//       //     List<PendingNotificationRequest> pendingNotifications =
//       //         await flutterLocalNotificationsPlugin.pendingNotificationRequests();
//       //     pendingNotifications.forEach((element) {
//       //       print('Pending Notifications: ${element.id}');
//       //       print('Pending Notifications: ${element.title}');
//       //       print('Pending Notifications: ${element.body}');
//       //       print('Pending Notifications: ${element.payload}');
//       //     });
//
//       //   print(_nextInstanceOfDate(DateTime.now()));
//       // },
//       // child: Icon(Icons.arrow_back),
//       //),
//       appBar: AppBar(title: Text('Add Card'), automaticallyImplyLeading: false),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: SingleChildScrollView(
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.stretch,
//             children: [
//               TextField(controller: cardNumberController, decoration: InputDecoration(labelText: 'Card Number')),
//               TextField(controller: cardCompanyController, decoration: InputDecoration(labelText: 'Card Company')),
//               TextField(
//                   controller: totalLimitController,
//                   decoration: InputDecoration(labelText: 'Total Limit'),
//                   keyboardType: TextInputType.number),
//               TextField(
//                   controller: totalOutstandingController,
//                   decoration: InputDecoration(labelText: 'Total Outstanding'),
//                   keyboardType: TextInputType.number),
//               TextField(
//                   controller: billingDateController,
//                   decoration: InputDecoration(labelText: 'Billing Date'),
//                   keyboardType: TextInputType.datetime,
//                   onTap: () {
//                     selectDateTime(context);
//                   }),
//               SizedBox(height: 16),
//               ElevatedButton(
//                   onPressed: () {
//                     addCardDetails(context);
//                     requestNotificationPermission();
//                     final DateTime now = DateTime.now();
//                     final DateTime scheduledDate = DateTime(now.year, now.month, now.day, 10, 0); // Example: 10:00 AM today
//                     scheduleNotification(scheduledDate, context);
//                   },
//                   child: Text('Add Card')),
//               ElevatedButton(
//                 onPressed: () => Navigator.push(
//                   context,
//                   MaterialPageRoute(builder: (context) => ShowDetailsScreen()),
//                 ),
//                 child: Text('Show Details'),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
//
//   Future<void> selectDateTime(BuildContext context) async {
//     final todayDate = DateTime.now();
//     final pickedDate = await showDatePicker(
//       context: context,
//       initialDate: selectedDate,
//       firstDate: DateTime(todayDate.year, todayDate.month, todayDate.day),
//       lastDate: DateTime(todayDate.year + 1, todayDate.month, todayDate.day),
//     );
//
//     if (pickedDate != null) {
//       selectedDate = pickedDate; // Update selectedDate with the picked date
//
//       // Update the text in the DateTime text field when a date and time are selected
//       billingDateController.text = "${DateFormat('dd-MM-yyyy').format(selectedDate)}";
//     }
//   }
// }
//
//   @override
//   Widget build(BuildContext context) {
//     // TODO: implement build
//     throw UnimplementedError();
//   }
// }
//
