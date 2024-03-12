
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:new_firebase_login/database_helper.dart';

import '../addcard_screen/card_details.dart';


class ShowDetailsScreen extends StatelessWidget {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final User? user = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    DatabaseHelper databaseHelper = DatabaseHelper();

    if (user == null) {
      // User is not logged in
      return Scaffold(
        body: Center(
          child: Text('User not logged in.'),
        ),
      );
    }

    final CollectionReference userCardsCollection =
    firestore.collection('users').doc(user!.uid).collection('cards');

    return Scaffold(
      appBar: AppBar(title: Text('Card Details')),
      body: FutureBuilder<List<CardDetails>>(
        future: databaseHelper.getCards(), // Fetch card details asynchronously
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else {
            final List<CardDetails> cardDetailsList = snapshot.data ?? [];
            if (cardDetailsList.isEmpty) {
              return Center(child: Text('No card details found.'));
            } else {
              return StreamBuilder<QuerySnapshot>(
                stream: userCardsCollection.snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  } else {
                    final cards = snapshot.data!.docs;
                    return ListView.builder(
                      itemCount: cards.length,
                      itemBuilder: (context, index) {
                        final cardData = cards[index].data() as Map<
                            String,
                            dynamic>;
                        return ListTile(
                          title: Text(cardData['cardCompany']),
                          subtitle: Text(
                              'Card Number: ${cardData['cardNumber']}, Limit: ${cardData['totalLimit']}'),
                        );
                      },
                    );
                  }
                },
              );
            }
          }
        },
      ),
    );
  }

}