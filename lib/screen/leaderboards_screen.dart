import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:kinse/model/Game.dart';
import 'package:kinse/model/Puzzle.dart';
import 'package:kinse/model/User.dart';
import 'package:kinse/screen/settings_screen.dart';
import 'package:kinse/screen/versus_screen.dart';
import 'package:kinse/widget/match_detail_widget.dart';

class LeaderBoardsScreen extends StatefulWidget {
  final FirebaseFirestore firestoreInstance;
  final User currentUser;
  const LeaderBoardsScreen({
    Key? key,
    required this.firestoreInstance,
    required this.currentUser,
  }) : super(key: key);

  @override
  _LeaderBoardsScreenState createState() => _LeaderBoardsScreenState();
}

class _LeaderBoardsScreenState extends State<LeaderBoardsScreen> {
  late Stream<QuerySnapshot> gameStream;
  late StreamSubscription<QuerySnapshot> streamSubscription;
  bool leaderboardAscending = true;
  int leaderboardColumnIndex = 0;
  int selectedGameOptionIndex = 0;
  int puzzleOrder = 0;
  Game? selectedGame;
  Puzzle? selectedPuzzle;
  List<Puzzle> historicalPuzzles = [];
  List<Game> historicalGames = [];
  List<String> gameOptions = [
    'Overall',
    'Single',
    'Average of 5',
    'Average of 10',
    'Average of 12',
    'Average of 50',
    'Average of 100',
  ];
  List<int> gameTypeEquivalent = [-1, 1, 5, 10, 12, 50, 100];

  String millisecondsFormatter(int totalMilliseconds) {
    int minutes = (totalMilliseconds / 1000) ~/ 60;
    String seconds = ((totalMilliseconds / 1000) % 60).toStringAsFixed(3);
    return "$minutes:$seconds";
  }

  listenGames() {
    try {
      setState(() {
        gameStream = widget.firestoreInstance
            .collection('games')
            .where('isFinished', isEqualTo: true)
            .snapshots();
        streamSubscription = gameStream.listen((QuerySnapshot snapshot) {
          List<Game> fetchedGames = snapshot.docs
              .map((e) => Game.fromJson(e.data() as Map<String, dynamic>))
              .toList();
          setState(() {
            historicalGames = fetchedGames;
            historicalPuzzles.clear();
            for (var game in historicalGames) {
              if (game.puzzles != null) {
                historicalPuzzles = historicalPuzzles + game.puzzles!;
              }
            }
          });
        });
      });
    } catch (error) {
      print(error.toString());
    }
  }

  int getAverageTime(Game game) {
    int totalMillisecond = 0;
    if (game.puzzles != null) {
      for (var puzzle in game.puzzles!) {
        totalMillisecond = totalMillisecond + puzzle.millisecondDuration!;
      }
      totalMillisecond = totalMillisecond ~/ game.puzzles!.length;
    }
    return totalMillisecond;
  }

  int getTotalMoves(Game game) {
    int totalMoves = 0;
    if (game.puzzles != null) {
      for (var puzzle in game.puzzles!) {
        totalMoves = totalMoves + puzzle.moves!.length;
      }
    }
    return totalMoves;
  }

  @override
  void initState() {
    super.initState();
    listenGames();
  }

  @override
  void dispose() {
    streamSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.dashboard_customize, color: Colors.white),
            tooltip: 'Home',
          ),
          actions: [
            IconButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  PageRouteBuilder(
                    pageBuilder: (context, animation1, animation2) =>
                        VersusScreen(
                      firestoreInstance: widget.firestoreInstance,
                      currentUser: widget.currentUser,
                    ),
                    transitionDuration: Duration.zero,
                    reverseTransitionDuration: Duration.zero,
                  ),
                );
              },
              icon: const Icon(Icons.sports_kabaddi),
              tooltip: 'Find Match',
            ),
            IconButton(
              onPressed: () {},
              icon: const Icon(Icons.leaderboard, color: Colors.black),
              tooltip: 'Leaderboards',
            ),
            IconButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  PageRouteBuilder(
                    pageBuilder: (context, animation1, animation2) =>
                        SettingsScreen(
                      firestoreInstance: widget.firestoreInstance,
                      currentUser: widget.currentUser,
                    ),
                    transitionDuration: Duration.zero,
                    reverseTransitionDuration: Duration.zero,
                  ),
                );
              },
              icon: const Icon(Icons.settings),
              tooltip: 'Settings',
            )
          ],
        ),
        body: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 28, bottom: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton(
                      onPressed: () {
                        setState(() {
                          selectedPuzzle = null;
                          selectedGame = null;
                          selectedGameOptionIndex = selectedGameOptionIndex < 6
                              ? selectedGameOptionIndex + 1
                              : 0;
                        });
                      },
                      child: Text(gameOptions[selectedGameOptionIndex]),
                    ),
                    const Text(' Leaderboards'),
                  ],
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.max,
                children: [
                  Flexible(child: _buildLeaderboardTable()),
                  (selectedGame != null
                      ? Flexible(
                          child: Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 24.0),
                            child: SizedBox(
                              width: 350,
                              child: MatchDetailWidget(
                                game: selectedGame!,
                                order: puzzleOrder,
                                key: UniqueKey(),
                              ),
                            ),
                          ),
                        )
                      : const SizedBox.shrink()),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  _buildLeaderboardTable() {
    List<DataColumn> dataColumns = [
      const DataColumn(label: Text('Name')),
      DataColumn(
        label: Text(selectedGameOptionIndex < 2 ? 'Time' : 'Average Time'),
        onSort: (index, ascending) {
          setState(() {
            leaderboardColumnIndex = index;
            leaderboardAscending = ascending;
            if (selectedGameOptionIndex < 2) {
              historicalPuzzles.sort((a, b) =>
                  a.millisecondDuration!.compareTo(b.millisecondDuration!));
              if (ascending) {
                historicalGames = historicalGames.reversed.toList();
              }
            } else {
              historicalGames.sort(
                  (a, b) => getAverageTime(a).compareTo(getAverageTime(b)));
              if (ascending) {
                historicalGames = historicalGames.reversed.toList();
              }
            }
          });
        },
      ),
      DataColumn(
        label: Text(selectedGameOptionIndex < 2 ? 'Moves' : 'Total Moves'),
        onSort: (index, ascending) {
          setState(() {
            leaderboardColumnIndex = index;
            leaderboardAscending = ascending;
            if (selectedGameOptionIndex < 2) {
              historicalPuzzles
                  .sort((a, b) => a.moves!.length.compareTo(b.moves!.length));
              if (ascending) {
                historicalGames = historicalGames.reversed.toList();
              }
            } else {
              historicalGames
                  .sort((a, b) => getTotalMoves(a).compareTo(getTotalMoves(b)));
              if (ascending) {
                historicalGames = historicalGames.reversed.toList();
              }
            }
            historicalPuzzles
                .sort((a, b) => a.moves!.length.compareTo(b.moves!.length));
            if (ascending) {
              historicalPuzzles = historicalPuzzles.reversed.toList();
            }
          });
        },
      ),
    ];
    List<DataRow> dataRows = [];
    if (selectedGameOptionIndex < 1) {
      dataRows = historicalPuzzles.map((puzzle) {
        return DataRow(
          selected: (selectedPuzzle == puzzle),
          onSelectChanged: (selected) async {
            if (kIsWeb) {
              if (selectedPuzzle != puzzle) {
                setState(() {
                  selectedPuzzle = puzzle;
                  selectedGame = historicalGames
                      .where((element) => element.id == puzzle.gameID)
                      .first;
                  puzzleOrder =
                      puzzle.order > 0 ? puzzle.order - 1 : puzzle.order;
                });
              } else {
                setState(() {
                  selectedGame = null;
                  selectedPuzzle = null;
                  puzzleOrder = 0;
                });
              }
            } else {
              await showModalBottomSheet(
                  context: context,
                  isDismissible: true,
                  builder: (context) {
                    return Scaffold(
                      body: MatchDetailWidget(
                        game: historicalGames
                            .where((element) => element.id! == puzzle.gameID)
                            .first,
                        order: puzzle.order,
                      ),
                    );
                  });
            }
          },
          cells: [
            DataCell(Text('${puzzle.name}')),
            DataCell(Text(millisecondsFormatter(puzzle.millisecondDuration!))),
            DataCell(Text(puzzle.moves!.length.toString())),
          ],
        );
      }).toList();
    } else {
      dataRows = historicalGames
          .where((element) =>
              element.gameType == gameTypeEquivalent[selectedGameOptionIndex])
          .map((game) {
        return DataRow(
          selected: (selectedGame == game),
          onSelectChanged: (selected) async {
            if (kIsWeb) {
              if (selectedGame != game) {
                setState(() {
                  selectedGame = game;
                  puzzleOrder = 0;
                });
              } else {
                setState(() {
                  selectedGame = null;
                  puzzleOrder = 0;
                });
              }
            } else {
              await showModalBottomSheet(
                  context: context,
                  isDismissible: true,
                  builder: (context) {
                    return Scaffold(
                      body: MatchDetailWidget(game: game, order: puzzleOrder),
                    );
                  });
            }
          },
          cells: [
            DataCell(Text(game.name!)),
            DataCell(Text(millisecondsFormatter(getAverageTime(game)))),
            DataCell(Text(getTotalMoves(game).toString())),
          ],
        );
      }).toList();
    }
    return Column(
      children: [
        FittedBox(
          child: DataTable(
            showCheckboxColumn: false,
            showBottomBorder: true,
            sortAscending: leaderboardAscending,
            sortColumnIndex: leaderboardColumnIndex,
            columns: dataColumns,
            rows: dataRows,
          ),
        ),
        (selectedGameOptionIndex > 0 &&
                historicalGames
                    .where((element) =>
                        element.gameType ==
                        gameTypeEquivalent[selectedGameOptionIndex])
                    .isEmpty
            ? const Padding(
                padding: EdgeInsets.all(28.0),
                child: Text("No records."),
              )
            : const SizedBox(height: 24)),
      ],
    );
  }
}
