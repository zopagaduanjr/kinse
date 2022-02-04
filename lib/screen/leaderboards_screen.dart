import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:kinse/model/Match.dart';
import 'package:kinse/widget/match_detail_widget.dart';

class LeaderBoardsScreen extends StatefulWidget {
  final FirebaseFirestore firestoreInstance;
  const LeaderBoardsScreen({
    Key? key,
    required this.firestoreInstance,
  }) : super(key: key);

  @override
  _LeaderBoardsScreenState createState() => _LeaderBoardsScreenState();
}

class _LeaderBoardsScreenState extends State<LeaderBoardsScreen> {
  late Stream<QuerySnapshot> matchesStream =
      widget.firestoreInstance.collection('matches').snapshots();
  late StreamSubscription<QuerySnapshot> streamSubscription;
  bool leaderboardAscending = true;
  int leaderboardColumnIndex = 0;

  List<Match> historicalMatches = [];

  String millisecondsFormatter(int totalMilliseconds) {
    int minutes = (totalMilliseconds / 1000) ~/ 60;
    String seconds = ((totalMilliseconds / 1000) % 60).toStringAsFixed(3);
    return "$minutes:$seconds";
  }

  void listenMatches() {
    streamSubscription = matchesStream.listen((QuerySnapshot snapshot) {
      List<Match> fetchedMatches = snapshot.docs
          .map((e) => Match.fromJson(e.data() as Map<String, dynamic>))
          .toList();
      setState(() {
        historicalMatches = fetchedMatches;
      });
    });
  }

  @override
  void initState() {
    super.initState();
    listenMatches();
  }

  @override
  void dispose() {
    streamSubscription.cancel();
    super.dispose();
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
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 50),
          const Text('Leaderboards'),
          const SizedBox(height: 25),
          Center(
            child: SingleChildScrollView(
              child: DataTable(
                showCheckboxColumn: false,
                sortAscending: leaderboardAscending,
                sortColumnIndex: leaderboardColumnIndex,
                columns: [
                  const DataColumn(label: Text('Name')),
                  DataColumn(
                    label: const Text('Time'),
                    onSort: (index, ascending) {
                      setState(() {
                        leaderboardColumnIndex = index;
                        leaderboardAscending = ascending;
                        historicalMatches.sort((a, b) => a.millisecondDuration
                            .compareTo(b.millisecondDuration));
                        if (ascending) {
                          historicalMatches =
                              historicalMatches.reversed.toList();
                        }
                      });
                    },
                  ),
                  DataColumn(
                    label: const Text('Moves'),
                    onSort: (index, ascending) {
                      setState(() {
                        leaderboardColumnIndex = index;
                        leaderboardAscending = ascending;
                        historicalMatches.sort(
                            (a, b) => a.moves.length.compareTo(b.moves.length));
                        if (ascending) {
                          historicalMatches =
                              historicalMatches.reversed.toList();
                        }
                      });
                    },
                  ),
                ],
                rows: historicalMatches.map((e) {
                  return DataRow(
                    onSelectChanged: (selectedMatch) async {
                      await showModalBottomSheet(
                          context: context,
                          isDismissible: true,
                          builder: (context) {
                            return MatchDetailWidget(match: e);
                          });
                    },
                    cells: [
                      DataCell(Text(e.name)),
                      DataCell(
                          Text(millisecondsFormatter(e.millisecondDuration))),
                      DataCell(Text(e.moves.length.toString())),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
