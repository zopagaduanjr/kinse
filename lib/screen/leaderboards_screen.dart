import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
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
  late Stream<QuerySnapshot> matchesStream;
  late StreamSubscription<QuerySnapshot> streamSubscription;
  bool leaderboardAscending = true;
  int leaderboardColumnIndex = 0;
  Match? selectedMatch;
  List<Match> historicalMatches = [];

  String millisecondsFormatter(int totalMilliseconds) {
    int minutes = (totalMilliseconds / 1000) ~/ 60;
    String seconds = ((totalMilliseconds / 1000) % 60).toStringAsFixed(3);
    return "$minutes:$seconds";
  }

  listenMatches() {
    try {
      setState(() {
        matchesStream =
            widget.firestoreInstance.collection('matches').snapshots();
        streamSubscription = matchesStream.listen((QuerySnapshot snapshot) {
          List<Match> fetchedMatches = snapshot.docs
              .map((e) => Match.fromJson(e.data() as Map<String, dynamic>))
              .toList();
          setState(() {
            historicalMatches = fetchedMatches;
          });
        });
      });
    } catch (error) {
      //hopefully gets called when 50k reads has been reached.
      print(error.toString());
    }
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
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 28, bottom: 16),
            child: Text('Leaderboards'),
          ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.max,
              children: [
                Container(
                  alignment: Alignment.topCenter,
                  child: SingleChildScrollView(
                    controller: ScrollController(),
                    child: DataTable(
                      showCheckboxColumn: false,
                      sortAscending: leaderboardAscending,
                      sortColumnIndex: leaderboardColumnIndex,
                      showBottomBorder: true,
                      columns: [
                        const DataColumn(label: Text('Name')),
                        DataColumn(
                          label: const Text('Time'),
                          onSort: (index, ascending) {
                            setState(() {
                              leaderboardColumnIndex = index;
                              leaderboardAscending = ascending;
                              historicalMatches.sort((a, b) => a
                                  .millisecondDuration
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
                              historicalMatches.sort((a, b) =>
                                  a.moves.length.compareTo(b.moves.length));
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
                          selected: (selectedMatch == e),
                          onSelectChanged: (selected) async {
                            if (kIsWeb) {
                              if (selectedMatch != e) {
                                setState(() {
                                  selectedMatch = e;
                                });
                              } else {
                                setState(() {
                                  selectedMatch = null;
                                });
                              }
                            } else {
                              await showModalBottomSheet(
                                  context: context,
                                  isDismissible: true,
                                  builder: (context) {
                                    return Scaffold(
                                      body: MatchDetailWidget(match: e),
                                    );
                                  });
                            }
                          },
                          cells: [
                            DataCell(Text(e.name)),
                            DataCell(Text(
                                millisecondsFormatter(e.millisecondDuration))),
                            DataCell(Text(e.moves.length.toString())),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
                (selectedMatch != null
                    ? Flexible(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24.0),
                          child: SizedBox(
                            width: 350,
                            child: MatchDetailWidget(
                              match: selectedMatch!,
                              key: UniqueKey(),
                            ),
                          ),
                        ),
                      )
                    : const SizedBox.shrink()),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
