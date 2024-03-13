import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../database_helper.dart';

class CardDetails {
  final String cardNumber;
  final String cardCompany;
  final int totalLimit;
  final int totalOutstanding;
  final String billingDate;

  CardDetails({
    required this.cardNumber,
    required this.cardCompany,
    required this.totalLimit,
    required this.totalOutstanding,
    required this.billingDate,
  });

  // Convert CardDetails to a Map for storing in Firestore
  Map<String, dynamic> toMap() {
    return {
      'cardNumber': cardNumber,
      'cardCompany': cardCompany,
      'totalLimit': totalLimit,
      'totalOutstanding': totalOutstanding,
      'billingDate': billingDate,
    };
  }
}
class YourApp extends StatefulWidget {
  @override
  _YourAppState createState() => _YourAppState();
}

class _YourAppState extends State<YourApp> {
  final TextEditingController cardNumberController = TextEditingController();
  final TextEditingController cardCompanyController = TextEditingController();
  final TextEditingController totalLimitController = TextEditingController();
  final TextEditingController totalOutstandingController = TextEditingController();
  final TextEditingController billingDateController = TextEditingController();

  Future<void> addCardDetails() async {
    CardDetails card = CardDetails(
      cardNumber: cardNumberController.text,
      cardCompany: cardCompanyController.text,
      totalLimit: int.parse(totalLimitController.text),
      totalOutstanding: int.parse(totalOutstandingController.text),
      billingDate: billingDateController.text,
    );

    int result = await DatabaseHelper.instance.insertCard(card);

    if (result != 0) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Card added successfully')));
      // Clear text controllers
      cardNumberController.clear();
      cardCompanyController.clear();
      totalLimitController.clear();
      totalOutstandingController.clear();
      billingDateController.clear();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to add card')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: Text('Add Card')),
        body: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(controller: cardNumberController, decoration: InputDecoration(labelText: 'Card Number')),
              TextField(controller: cardCompanyController, decoration: InputDecoration(labelText: 'Card Company')),
              TextField(controller: totalLimitController, decoration: InputDecoration(labelText: 'Total Limit')),
              TextField(controller: totalOutstandingController, decoration: InputDecoration(labelText: 'Total Outstanding')),
              TextField(controller: billingDateController, decoration: InputDecoration(labelText: 'Billing Date')),
              SizedBox(height: 16),
              ElevatedButton(onPressed: addCardDetails, child: Text('Add Card')),
            ],
          ),
        ),
      ),
    );
  }
}

void main() {
  runApp(YourApp());
}



