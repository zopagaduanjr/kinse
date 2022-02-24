import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:kinse/config/constants.dart';
import 'package:kinse/model/Game.dart';
import 'package:kinse/model/Puzzle.dart';
import 'package:kinse/model/User.dart';
import 'package:kinse/model/Versus.dart';
import 'package:kinse/screen/settings_screen.dart';

import 'leaderboards_screen.dart';

class VersusScreen extends StatefulWidget {
  final FirebaseFirestore firestoreInstance;
  final User currentUser;
  const VersusScreen({
    Key? key,
    required this.firestoreInstance,
    required this.currentUser,
  }) : super(key: key);

  @override
  _VersusScreenState createState() => _VersusScreenState();
}

class _VersusScreenState extends State<VersusScreen> {
  final isPurelyWeb = kIsWeb &&
      (defaultTargetPlatform != TargetPlatform.iOS &&
          defaultTargetPlatform != TargetPlatform.android);
  final Stopwatch _stopwatch = Stopwatch();
  final Stopwatch _findMatchStopwatch = Stopwatch();
  late List<GlobalKey> keyList;
  late List<RenderBox> boxList;
  late Stream<QuerySnapshot> versusQueueStream;
  late StreamSubscription<QuerySnapshot> versusQueueSubscription;
  late Stream<DocumentSnapshot> generatedVersusStream;
  late StreamSubscription<DocumentSnapshot> generatedVersusSubscription;
  late Stream<DocumentSnapshot> opponentGameStream;
  late StreamSubscription<DocumentSnapshot> opponentGameSubscription;
  List<int> tilesF = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16];
  List<int> tiles = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16];
  List<int> opponentTiles = [
    1,
    2,
    3,
    4,
    5,
    6,
    7,
    8,
    9,
    10,
    11,
    12,
    13,
    14,
    15,
    16
  ];
  List<int> specificMoves = [];
  List<int> opponentMoves = [];
  List<String> gameOptions = [
    'Single',
    'Average of 5',
    'Average of 10',
    'Average of 12',
    'Average of 50',
    'Average of 100',
  ];
  List<Puzzle> generatedPuzzles = [];
  bool newPuzzle = true;
  bool isFindingMatch = false;
  bool inMatch = false;
  bool finishedMatch = false;
  int selectedGameOptionIndex = 0, currentPuzzleIndex = 0;
  int opponentCurrentPuzzleIndex = 0;
  Timer? _callbackTimer;
  DateTime? dateStarted;
  Versus? generatedVersus;
  Game? generatedGame;
  Game? opponentGame;
  String enemyName = "null";
  List<int>? enemyColorScheme;
  String versusID = "";
  ScrollController mainScrollController = ScrollController();
  ScrollController scrollControllerA = ScrollController();
  ScrollController scrollControllerB = ScrollController();
  ScrollController scrollControllerC = ScrollController();

  listenVersusQueue() {
    try {
      setState(() {
        versusQueueStream = widget.firestoreInstance
            .collection('versus')
            .where('isFindingMatch', isEqualTo: true)
            .snapshots();
        versusQueueSubscription =
            versusQueueStream.listen((QuerySnapshot snapshot) {
          List<Versus> fetchedVersus = snapshot.docs
              .map((e) => Versus.fromJson(e.data() as Map<String, dynamic>))
              .toList();
          if (fetchedVersus.isEmpty) {
            versusQueueSubscription.cancel();
            createVersus();
          } else {
            versusQueueSubscription.cancel();
            acceptVersus(fetchedVersus.first);
          }
        });
      });
    } catch (error) {
      print(error.toString());
    }
  }

  listenGeneratedVersus(Versus versus) {
    try {
      setState(() {
        generatedVersusStream = widget.firestoreInstance
            .collection('versus')
            .doc(versus.id)
            .snapshots();
        generatedVersusSubscription =
            generatedVersusStream.listen((DocumentSnapshot snapshot) {
          if (snapshot.get('isFindingMatch') == false &&
              snapshot.get('gameBID') != null) {
            setState(() {
              generatedVersus =
                  Versus.fromJson(snapshot.data() as Map<String, dynamic>);
              enemyName = generatedVersus!.playerB!;
            });
            _findMatchStopwatch.stop();
            listenEnemyGame(generatedVersus!.gameBID!);
            generatedVersusSubscription.cancel();
          }
        });
      });
    } catch (error) {
      print(error.toString());
    }
  }

  setupCurrentGame() {
    _stopwatch.stop();
    _stopwatch.reset();
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Match Found'),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 3),
      ),
    );
    if (generatedGame != null) {
      setState(() {
        generatedPuzzles = generatedGame!.puzzles!;
        tiles = List.from(generatedPuzzles.first.sequence);
        newPuzzle = true;
        currentPuzzleIndex = 0;
        specificMoves.clear();
      });
    }
  }

  listenEnemyGame(String gameID) async {
    try {
      var game =
          await widget.firestoreInstance.collection('games').doc(gameID).get();
      setState(() {
        opponentGame = Game.fromJson(game.data() as Map<String, dynamic>);
        opponentTiles =
            opponentGame!.puzzles![opponentCurrentPuzzleIndex].sequence;
        opponentMoves =
            opponentGame!.puzzles![opponentCurrentPuzzleIndex].moves!;
        enemyColorScheme = opponentGame!.colorScheme;
      });
      opponentGameStream =
          widget.firestoreInstance.collection('games').doc(gameID).snapshots();
      opponentGameSubscription =
          opponentGameStream.listen((DocumentSnapshot snapshot) async {
        setState(() {
          opponentGame = Game.fromJson(snapshot.data() as Map<String, dynamic>);
        });
        if (isPurelyWeb == true) {
          List<int> updatedMoves = List.from(
              opponentGame!.puzzles![opponentCurrentPuzzleIndex].moves!);
          var sublistedMoves = updatedMoves.sublist(opponentMoves.length);
          if (sublistedMoves.isNotEmpty) {
            int millisPerMove = 1000 ~/ sublistedMoves.length;
            for (var e in sublistedMoves) {
              moveOpponentTile(e);
              await Future.delayed(Duration(milliseconds: millisPerMove));
            }
          }
          setState(() {
            opponentMoves = updatedMoves;
          });
          if (opponentGame!
                  .puzzles![opponentCurrentPuzzleIndex].millisecondDuration !=
              null) {
            if (opponentCurrentPuzzleIndex < 4) {
              setState(() {
                opponentCurrentPuzzleIndex++;
                opponentTiles =
                    opponentGame!.puzzles![opponentCurrentPuzzleIndex].sequence;
                opponentMoves =
                    opponentGame!.puzzles![opponentCurrentPuzzleIndex].moves!;
              });
            } else {
              setState(() {});
              opponentGameSubscription.cancel();
            }
          }
        }
      });
    } catch (error) {
      print(error.toString());
    }
    setupCurrentGame();
    setState(() {
      isFindingMatch = false;
      inMatch = true;
    });
    updatePlayerGame();
  }

  moveOpponentTile(int index) {
    if (index >= 0 && index < 16) {
      int whiteIndex = opponentTiles.indexOf(16);
      if (index - 1 == whiteIndex && index % 4 != 0 ||
          index + 1 == whiteIndex && (index + 1) % 4 != 0 ||
          index - 4 == whiteIndex ||
          index + 4 == whiteIndex) {
        setState(() {
          opponentTiles[whiteIndex] = opponentTiles[index];
          opponentTiles[index] = 16;
        });
      }
    }
  }

  updatePlayerGame() {
    Timer.periodic(const Duration(seconds: 1), (timer) {
      widget.firestoreInstance
          .collection('games')
          .doc(generatedGame!.id)
          .update(generatedGame!.toJson());
      if (finishedMatch) {
        widget.firestoreInstance
            .collection('games')
            .doc(generatedGame!.id)
            .update(generatedGame!.toJson());
        timer.cancel();
      }
    });
  }

  cancelVersusQueue() {
    versusQueueSubscription.cancel();
    if (versusID.isNotEmpty) {
      widget.firestoreInstance.collection('versus').doc(versusID).update({
        'isFindingMatch': false,
      });
    }
  }

  createVersus() {
    List<Puzzle> setupPuzzles = [];
    for (int i = 1; i < 6; i++) {
      setupPuzzles.add(generatePuzzle(i));
    }
    var gameADoc = widget.firestoreInstance.collection('games').doc();
    var versusDoc = widget.firestoreInstance.collection('versus').doc();
    Game game = Game(
      id: gameADoc.id,
      name: widget.currentUser.name,
      gameType: 5,
      puzzles: List.from(setupPuzzles),
      isFinished: false,
      colorScheme: widget.currentUser.colorScheme,
    );
    Versus versus = Versus(
      id: versusDoc.id,
      queueStarted: DateTime.now(),
      playerA: widget.currentUser.name,
      gameType: 5,
      puzzles: List.from(setupPuzzles),
      isFindingMatch: true,
      gameAID: gameADoc.id,
    );
    try {
      widget.firestoreInstance
          .collection('games')
          .doc(gameADoc.id)
          .set(game.toJson());
      widget.firestoreInstance
          .collection('versus')
          .doc(versusDoc.id)
          .set(versus.toJson());
      setState(() {
        generatedGame = game;
        versusID = versusDoc.id;
      });
      listenGeneratedVersus(versus);
    } catch (error) {
      print(error.toString());
    }
  }

  acceptVersus(Versus versus) {
    var gameBDoc = widget.firestoreInstance.collection('games').doc();
    Game game = Game(
      id: gameBDoc.id,
      name: widget.currentUser.name,
      gameType: 5,
      puzzles: List.from(versus.puzzles!),
      isFinished: false,
      colorScheme: widget.currentUser.colorScheme,
    );
    try {
      widget.firestoreInstance
          .collection('games')
          .doc(gameBDoc.id)
          .set(game.toJson());
      widget.firestoreInstance.collection('versus').doc(versus.id).update({
        'isFindingMatch': false,
        'playerB': widget.currentUser.name,
        'gameBID': gameBDoc.id,
        'queueEnded': DateTime.now().toIso8601String(),
      });
      setState(() {
        generatedGame = game;
        generatedVersus = versus;
        enemyName = versus.playerA!;
      });
      _findMatchStopwatch.stop();
      listenEnemyGame(versus.gameAID!);
    } catch (error) {
      print(error.toString());
    }
  }

  Set isSolveable(List<int> puzzle) {
    int inversionCount = 0, row = 5, blankRow = 0;
    int gridWidth = sqrt(puzzle.length).toInt();

    for (int i = 0; i < puzzle.length; i++) {
      if (i % gridWidth == 0) {
        row--;
      }
      if (puzzle[i] == 16) {
        blankRow = row;
      }
      for (int j = i + 1; j < puzzle.length; j++) {
        if (puzzle[i] > puzzle[j] && puzzle[j] != 16 && puzzle[i] != 16) {
          inversionCount++;
        }
      }
    }
    if (gridWidth.isEven) {
      if (blankRow.isEven) {
        return {inversionCount.isOdd, inversionCount};
      } else {
        return {inversionCount.isEven, inversionCount};
      }
    } else {
      return {inversionCount.isEven, inversionCount};
    }
  }

  String stopwatchFormatter(Duration duration) {
    return duration.toString().substring(2, 11);
  }

  String millisecondsFormatter(int totalMilliseconds) {
    int minutes = (totalMilliseconds / 1000) ~/ 60;
    String seconds = ((totalMilliseconds / 1000) % 60).toStringAsFixed(3);
    return "${minutes.toString().padLeft(2, '0')}:${seconds.padLeft(6, '0')}";
  }

  Puzzle generatePuzzle(int order) {
    List<int> newSequence = List.from(tilesF);
    int newLoop = 0, newParity = 0;
    newSequence.shuffle();
    newLoop++;
    Set solveable = isSolveable(newSequence);
    while (solveable.first == false) {
      newSequence.shuffle();
      solveable = isSolveable(newSequence);
      newLoop++;
    }
    newParity = solveable.last;
    return Puzzle(
      order: order,
      parity: newParity,
      loops: newLoop,
      moves: [],
      sequence: newSequence,
    );
  }

  setupGame(int gameIndex) {
    _stopwatch.stop();
    _stopwatch.reset();
    List<int> numberGames = [1, 5, 10, 12, 50, 100];
    List<Puzzle> setupPuzzles = [];
    for (int i = 1; i < numberGames[gameIndex] + 1; i++) {
      setupPuzzles.add(generatePuzzle(i));
    }
    setState(() {
      generatedPuzzles = setupPuzzles;
      tiles = List.from(generatedPuzzles.first.sequence);
      newPuzzle = true;
      currentPuzzleIndex = 0;
      specificMoves.clear();
    });
  }

  createRenderBox() {
    setState(() {
      List<RenderBox> generatedBoxList = [];
      for (var element in keyList) {
        generatedBoxList
            .add(element.currentContext!.findRenderObject() as RenderBox);
      }
      boxList = generatedBoxList;
    });
  }

  runStopwatch() {
    _stopwatch.start();
    setState(() {
      dateStarted = DateTime.now();
      _callbackTimer =
          Timer.periodic(const Duration(milliseconds: 15), (timer) {
        if (mounted) {
          setState(() {});
        }
        if (!_stopwatch.isRunning) {
          timer.cancel();
        }
      });
    });
  }

  moveTile(int index) {
    if (index >= 0 && index < 16 && newPuzzle) {
      int whiteIndex = tiles.indexOf(16);
      if (index - 1 == whiteIndex && index % 4 != 0 ||
          index + 1 == whiteIndex && (index + 1) % 4 != 0 ||
          index - 4 == whiteIndex ||
          index + 4 == whiteIndex) {
        if (inMatch) {
          if (!_stopwatch.isRunning) {
            runStopwatch();
          }
          setState(() {
            tiles[whiteIndex] = tiles[index];
            tiles[index] = 16;
            specificMoves.add(index);
            generatedGame!.puzzles![currentPuzzleIndex].moves!.add(index);
          });
          if (listEquals(tiles, tilesF)) {
            _stopwatch.stop();
            List<int> movesMade = List.from(specificMoves);
            setState(() {
              generatedGame!.puzzles![currentPuzzleIndex].millisecondDuration =
                  _stopwatch.elapsedMilliseconds;
              generatedGame!.puzzles![currentPuzzleIndex].dateStarted =
                  dateStarted;
              generatedGame!.puzzles![currentPuzzleIndex].tps =
                  movesMade.length / (_stopwatch.elapsedMilliseconds / 1000);
              if (generatedPuzzles.length > currentPuzzleIndex + 1) {
                setState(() {
                  currentPuzzleIndex++;
                  tiles =
                      List.from(generatedPuzzles[currentPuzzleIndex].sequence);
                  specificMoves.clear();
                  _stopwatch.reset();
                });
              } else {
                setState(() {
                  generatedGame!.dateSubmitted = DateTime.now();
                  generatedGame!.isFinished = true;
                  newPuzzle = false;
                  finishedMatch = true;
                });
              }
            });
          }
        } else {
          setState(() {
            tiles[whiteIndex] = tiles[index];
            tiles[index] = 16;
          });
          if (listEquals(tiles, tilesF)) {
            setState(() {
              if (generatedPuzzles.length > currentPuzzleIndex + 1) {
                currentPuzzleIndex++;
                tiles =
                    List.from(generatedPuzzles[currentPuzzleIndex].sequence);
              } else {
                generatedPuzzles.add(generatePuzzle(1));
                currentPuzzleIndex++;
                tiles =
                    List.from(generatedPuzzles[currentPuzzleIndex].sequence);
              }
            });
          }
        }
      }
    }
  }

  @override
  void initState() {
    super.initState();
    setupGame(0);
    if (!isPurelyWeb) {
      setState(() {
        keyList = List.generate(16, (index) => GlobalKey());
      });
    }
    WidgetsBinding.instance?.addPostFrameCallback((_) {
      if (!isPurelyWeb) {
        createRenderBox();
      }
    });
  }

  @override
  void dispose() {
    _callbackTimer?.cancel();
    _stopwatch.stop();
    _findMatchStopwatch.stop();
    if (versusID.isNotEmpty) {
      widget.firestoreInstance.collection('versus').doc(versusID).update({
        'isFindingMatch': false,
      });
    }
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
            onPressed: () {
              if (!inMatch && !isFindingMatch) {
                Navigator.pop(context);
              } else {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content:
                        const Text('Currently in Match. Continue to leave?'),
                    behavior: SnackBarBehavior.floating,
                    duration: const Duration(seconds: 3),
                    action: SnackBarAction(
                      label: 'Leave',
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
                  ),
                );
              }
            },
            icon: const Icon(Icons.dashboard_customize),
            tooltip: 'Home',
          ),
          actions: [
            IconButton(
              onPressed: () {},
              icon: const Icon(Icons.sports_kabaddi, color: Colors.black),
              tooltip: 'Find Match',
            ),
            IconButton(
              onPressed: () {
                if (!inMatch && !isFindingMatch) {
                  Navigator.pushReplacement(
                    context,
                    PageRouteBuilder(
                      pageBuilder: (context, animation1, animation2) =>
                          LeaderBoardsScreen(
                        firestoreInstance: widget.firestoreInstance,
                        currentUser: widget.currentUser,
                      ),
                      transitionDuration: Duration.zero,
                      reverseTransitionDuration: Duration.zero,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content:
                          const Text('Currently in Match. Continue to leave?'),
                      behavior: SnackBarBehavior.floating,
                      duration: const Duration(seconds: 3),
                      action: SnackBarAction(
                        label: 'Leave',
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            PageRouteBuilder(
                              pageBuilder: (context, animation1, animation2) =>
                                  LeaderBoardsScreen(
                                firestoreInstance: widget.firestoreInstance,
                                currentUser: widget.currentUser,
                              ),
                              transitionDuration: Duration.zero,
                              reverseTransitionDuration: Duration.zero,
                            ),
                          );
                        },
                      ),
                    ),
                  );
                }
              },
              icon: const Icon(Icons.leaderboard),
              tooltip: 'Leaderboards',
            ),
            IconButton(
              onPressed: () {
                if (!inMatch && !isFindingMatch) {
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
                } else {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content:
                          const Text('Currently in Match. Continue to leave?'),
                      behavior: SnackBarBehavior.floating,
                      duration: const Duration(seconds: 3),
                      action: SnackBarAction(
                        label: 'Leave',
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
                      ),
                    ),
                  );
                }
              },
              icon: const Icon(Icons.settings),
              tooltip: 'Settings',
            )
          ],
        ),
        body: Listener(
          onPointerSignal: (ps) {
            if (isPurelyWeb) {
              if (ps is PointerScrollEvent) {
                final newOffset =
                    mainScrollController.offset + ps.scrollDelta.dy;
                if (ps.scrollDelta.dy.isNegative) {
                  mainScrollController.jumpTo(max(0, newOffset));
                } else {
                  mainScrollController.jumpTo(min(
                      mainScrollController.position.maxScrollExtent,
                      newOffset));
                }
              }
            }
          },
          child: RawKeyboardListener(
            focusNode: FocusNode(),
            autofocus: true,
            onKey: (RawKeyEvent event) async {
              if (event.isKeyPressed(LogicalKeyboardKey.arrowUp)) {
                moveTile(tiles.indexOf(16) + 4);
              } else if (event.isKeyPressed(LogicalKeyboardKey.arrowDown)) {
                moveTile(tiles.indexOf(16) - 4);
              } else if (event.isKeyPressed(LogicalKeyboardKey.arrowLeft)) {
                moveTile(tiles.indexOf(16) + 1);
              } else if (event.isKeyPressed(LogicalKeyboardKey.arrowRight)) {
                moveTile(tiles.indexOf(16) - 1);
              }
            },
            child: SingleChildScrollView(
              physics:
                  isPurelyWeb ? const NeverScrollableScrollPhysics() : null,
              controller: mainScrollController,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Flexible(
                    child: Column(
                      children: [
                        Container(),
                        (inMatch
                            ? _buildEnemyName()
                            : _buildFindMatchSection()),
                        (inMatch
                            ? Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 8),
                                child: Text("Game ${currentPuzzleIndex + 1}"),
                              )
                            : const SizedBox.shrink()),
                        GestureDetector(
                          onVerticalDragUpdate: (_) {},
                          child: Container(
                            constraints: const BoxConstraints(
                              maxWidth: 375,
                              minHeight: 200,
                            ),
                            decoration:
                                const BoxDecoration(color: Colors.transparent),
                            child: ScrollConfiguration(
                              behavior: ScrollConfiguration.of(context)
                                  .copyWith(scrollbars: false),
                              child: GridView.builder(
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 4),
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                controller: scrollControllerA,
                                scrollDirection: Axis.vertical,
                                itemCount: tiles.length,
                                itemBuilder: (context, index) {
                                  return isPurelyWeb
                                      ? _buildWebTile(index)
                                      : _buildMobileTile(index);
                                },
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 35),
                          child: _buildPuzzleStats(generatedPuzzles),
                        ),
                      ],
                    ),
                  ),
                  (inMatch && isPurelyWeb
                      ? _buildEnemyTile()
                      : const SizedBox.shrink()),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  _buildMobileTile(int index) {
    return Listener(
      key: keyList[index],
      onPointerDown: (details) => moveTile(index),
      onPointerMove: (details) {
        if (widget.currentUser.glide) {
          final result = BoxHitTestResult();
          if (boxList[15].hitTest(
            result,
            position: boxList[15].globalToLocal(details.position),
          )) {
            moveTile(15);
          } else if (boxList[14].hitTest(
            result,
            position: boxList[14].globalToLocal(details.position),
          )) {
            moveTile(14);
          } else if (boxList[13].hitTest(
            result,
            position: boxList[13].globalToLocal(details.position),
          )) {
            moveTile(13);
          } else if (boxList[12].hitTest(
            result,
            position: boxList[12].globalToLocal(details.position),
          )) {
            moveTile(12);
          } else if (boxList[11].hitTest(
            result,
            position: boxList[11].globalToLocal(details.position),
          )) {
            moveTile(11);
          } else if (boxList[10].hitTest(
            result,
            position: boxList[10].globalToLocal(details.position),
          )) {
            moveTile(10);
          } else if (boxList[9].hitTest(
            result,
            position: boxList[9].globalToLocal(details.position),
          )) {
            moveTile(9);
          } else if (boxList[8].hitTest(
            result,
            position: boxList[8].globalToLocal(details.position),
          )) {
            moveTile(8);
          } else if (boxList[7].hitTest(
            result,
            position: boxList[7].globalToLocal(details.position),
          )) {
            moveTile(7);
          } else if (boxList[6].hitTest(
            result,
            position: boxList[6].globalToLocal(details.position),
          )) {
            moveTile(6);
          } else if (boxList[5].hitTest(
            result,
            position: boxList[5].globalToLocal(details.position),
          )) {
            moveTile(5);
          } else if (boxList[4].hitTest(
            result,
            position: boxList[4].globalToLocal(details.position),
          )) {
            moveTile(4);
          } else if (boxList[3].hitTest(
            result,
            position: boxList[3].globalToLocal(details.position),
          )) {
            moveTile(3);
          } else if (boxList[2].hitTest(
            result,
            position: boxList[2].globalToLocal(details.position),
          )) {
            moveTile(2);
          } else if (boxList[1].hitTest(
            result,
            position: boxList[1].globalToLocal(details.position),
          )) {
            moveTile(1);
          } else if (boxList[0].hitTest(
            result,
            position: boxList[0].globalToLocal(details.position),
          )) {
            moveTile(0);
          }
        }
      },
      child: Container(
        color: colorChoices[widget.currentUser.colorScheme[tiles[index] - 1]],
        margin: EdgeInsets.zero,
        child: Center(
          child: Text(
            "${tiles[index] == 16 ? "" : tiles[index]}",
            style: TextStyle(
                color: widget.currentUser.colorScheme[tiles[index] - 1] == 7
                    ? Colors.white
                    : null),
          ),
        ),
      ),
    );
  }

  _buildWebTile(int index) {
    return InkWell(
      onHover: (val) {
        if (widget.currentUser.hover) {
          moveTile(index);
        }
      },
      onTap: () => moveTile(index),
      child: Container(
        color: colorChoices[widget.currentUser.colorScheme[tiles[index] - 1]],
        child: Center(
          child: Text(
            "${tiles[index] == 16 ? "" : tiles[index]}",
            style: TextStyle(
                color: widget.currentUser.colorScheme[tiles[index] - 1] == 7
                    ? Colors.white
                    : null),
          ),
        ),
      ),
    );
  }

  _buildPuzzleStats(List<Puzzle> puzzle) {
    return Container(
      constraints: const BoxConstraints(
        maxWidth: 375,
        maxHeight: 375,
      ),
      child: ListView.separated(
        controller: scrollControllerC,
        itemCount: puzzle
            .where((element) => element.millisecondDuration != null)
            .length,
        shrinkWrap: true,
        separatorBuilder: (BuildContext context, int index) => const Divider(),
        itemBuilder: (context, index) {
          index = puzzle
                  .where((element) => element.millisecondDuration != null)
                  .length -
              1 -
              index;
          List<Puzzle> finishedPuzzles = puzzle
              .where((element) => element.millisecondDuration != null)
              .toList();
          return ListTile(
            title: Text(
                'Game ${finishedPuzzles[index].order} - ${millisecondsFormatter(finishedPuzzles[index].millisecondDuration!)}'),
            subtitle: Text(
                'Moves: ${finishedPuzzles[index].moves!.length} TPS: ${finishedPuzzles[index].tps!.toStringAsFixed(3)}'),
          );
        },
      ),
    );
  }

  _buildFindMatchButton() {
    return TextButton(
      onPressed: () {
        setState(() {
          isFindingMatch = !isFindingMatch;
        });
        if (isFindingMatch) {
          _findMatchStopwatch.start();
          listenVersusQueue();
          _callbackTimer =
              Timer.periodic(const Duration(milliseconds: 15), (timer) {
            if (mounted) {
              setState(() {});
            }
            if (!_findMatchStopwatch.isRunning) {
              timer.cancel();
            }
          });
        } else {
          _findMatchStopwatch.stop();
          _findMatchStopwatch.reset();
          _callbackTimer?.cancel();
          cancelVersusQueue();
        }
      },
      child: Text(isFindingMatch ? "Cancel Find Match" : "Find Match"),
    );
  }

  _buildFindMatchSection() {
    if (inMatch) {
      return const SizedBox.shrink();
    } else {
      return Padding(
        padding: const EdgeInsets.only(top: 35),
        child: Column(
          children: [
            _buildFindMatchButton(),
            (isFindingMatch
                ? Padding(
                    padding: const EdgeInsets.only(top: 28, bottom: 16),
                    child: Text(
                      stopwatchFormatter(_findMatchStopwatch.elapsed),
                      style: const TextStyle(fontSize: 16),
                    ),
                  )
                : const SizedBox.shrink()),
          ],
        ),
      );
    }
  }

  _buildEnemyName() {
    if (isPurelyWeb == false) {
      return Padding(
        padding: const EdgeInsets.only(top: 35, bottom: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Enemy: $enemyName'),
            Row(
              children: opponentGame!.puzzles!.map((e) {
                return Icon(
                  Icons.circle,
                  size: 12,
                  color: e.millisecondDuration != null
                      ? Colors.green
                      : Colors.grey,
                );
              }).toList(),
            ),
          ],
        ),
      );
    } else {
      return const SizedBox(height: 35);
    }
  }

  _buildEnemyTile() {
    return Flexible(
      child: Column(
        children: [
          const SizedBox(height: 35),
          Container(),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
                'Enemy: $enemyName | Game: ${opponentCurrentPuzzleIndex + 1}'),
          ),
          Container(
            constraints: const BoxConstraints(
              maxWidth: 375,
              minHeight: 200,
            ),
            decoration: const BoxDecoration(color: Colors.transparent),
            child: ScrollConfiguration(
              behavior:
                  ScrollConfiguration.of(context).copyWith(scrollbars: false),
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4),
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                controller: scrollControllerB,
                scrollDirection: Axis.vertical,
                itemCount: 16,
                itemBuilder: (context, index) {
                  return Container(
                    color: enemyColorScheme != null
                        ? colorChoices[
                            enemyColorScheme![opponentTiles[index] - 1]]
                        : Colors.transparent,
                    child: Center(
                      child: Text(
                        "${opponentTiles[index] == 16 ? "" : opponentTiles[index]}",
                        style: TextStyle(
                            color: enemyColorScheme != null
                                ? (enemyColorScheme![
                                            opponentTiles[index] - 1] ==
                                        7
                                    ? Colors.white
                                    : null)
                                : null),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 35),
            child: _buildPuzzleStats(opponentGame!.puzzles!),
          ),
        ],
      ),
    );
  }
}
