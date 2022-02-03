import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:kinse/model/Match.dart';

class LeaderBoardsScreen extends StatefulWidget {
  const LeaderBoardsScreen({Key? key}) : super(key: key);

  @override
  _LeaderBoardsScreenState createState() => _LeaderBoardsScreenState();
}

class _LeaderBoardsScreenState extends State<LeaderBoardsScreen> {
  final Stream<QuerySnapshot> matchesStream =
      FirebaseFirestore.instance.collection('matches').snapshots();

  String millisecondsFormatter(int totalMilliseconds) {
    int minutes = (totalMilliseconds / 1000) ~/ 60;
    String seconds = ((totalMilliseconds / 1000) % 60).toStringAsFixed(3);
    return "$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.dashboard_customize, color: Colors.white),
          tooltip: 'Home',
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.sports_kabaddi),
            tooltip: 'Find Match',
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.leaderboard, color: Colors.black),
            tooltip: 'Leaderboards',
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.settings),
            tooltip: 'Settings',
          )
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: matchesStream,
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.hasError) {
            return Text('Something went wrong');
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Text("Loading");
          }

          return Center(
            child: DataTable(
              columns: const <DataColumn>[
                DataColumn(
                  label: Text(
                    'Name',
                    style: TextStyle(fontStyle: FontStyle.italic),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Time',
                    style: TextStyle(fontStyle: FontStyle.italic),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Moves',
                    style: TextStyle(fontStyle: FontStyle.italic),
                  ),
                ),
              ],
              rows: snapshot.data!.docs.map(
                (doc) {
                  Match matchData =
                      Match.fromJson(doc.data()! as Map<String, dynamic>);
                  return DataRow(cells: [
                    DataCell(Text(matchData.name)),
                    DataCell(
                      Text(
                          millisecondsFormatter(matchData.millisecondDuration)),
                    ),
                    DataCell(
                      Text('${matchData.moves.length}'),
                    )
                  ]);
                },
              ).toList(),
            ),
          );
        },
      ),
    );
  }
}
