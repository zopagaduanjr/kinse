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
import 'package:kinse/screen/settings_screen.dart';
import 'package:kinse/screen/versus_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'leaderboards_screen.dart';

class PuzzleScreen extends StatefulWidget {
  const PuzzleScreen({Key? key}) : super(key: key);

  @override
  _PuzzleScreenState createState() => _PuzzleScreenState();
}

class _PuzzleScreenState extends State<PuzzleScreen> {
  late List<GlobalKey> keyList;
  late List<RenderBox> boxList;
  List<int> tilesF = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16];
  List<int> tiles = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16];
  List<int> specificMoves = [];
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
  int selectedGameOptionIndex = 0, currentPuzzleIndex = 0;
  FirebaseFirestore firestoreInstance = FirebaseFirestore.instance;
  Timer? _callbackTimer;
  DateTime? dateStarted;
  User? currentUser;
  ScrollController mainScrollController = ScrollController();
  ScrollController scrollControllerA = ScrollController();
  ScrollController scrollControllerB = ScrollController();

  final Stopwatch _stopwatch = Stopwatch();

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
        if (!_stopwatch.isRunning) {
          runStopwatch();
        }
        setState(() {
          tiles[whiteIndex] = tiles[index];
          tiles[index] = 16;
          specificMoves.add(index);
        });
        if (listEquals(tiles, tilesF)) {
          _stopwatch.stop();
          List<int> movesMade = List.from(specificMoves);
          setState(() {
            generatedPuzzles[currentPuzzleIndex].millisecondDuration =
                _stopwatch.elapsedMilliseconds;
            generatedPuzzles[currentPuzzleIndex].dateStarted = dateStarted;
            generatedPuzzles[currentPuzzleIndex].moves = movesMade;
            generatedPuzzles[currentPuzzleIndex].tps =
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
                newPuzzle = false;
              });
              var gameDoc = firestoreInstance.collection('games').doc();
              double totalTime = 0;
              for (var puzzle in generatedPuzzles) {
                totalTime = totalTime + puzzle.millisecondDuration!;
                setState(() {
                  puzzle.gameID = gameDoc.id;
                  puzzle.name = currentUser != null ? currentUser!.name : "egg";
                });
              }
              Game game = Game(
                id: gameDoc.id,
                name: currentUser != null ? currentUser!.name : "egg",
                colorScheme: currentUser != null
                    ? currentUser!.colorScheme
                    : fringeScheme,
                gameType: generatedPuzzles.length,
                dateSubmitted: DateTime.now(),
                puzzles: generatedPuzzles,
                isFinished: true,
              );
              try {
                firestoreInstance
                    .collection('games')
                    .doc(gameDoc.id)
                    .set(game.toJson());
              } catch (error) {
                //hopefully gets called when 50k writes has been reached.
                print(error.toString());
              }
            }
          });
        }
      }
    }
  }

  easyShuffle() {
    var rng = Random();
    List<int> moves = [-1, 1, -4, 4];
    for (var i = 0; i < 95; i++) {
      int whiteIndex = tiles.indexOf(16);
      int randomIndex = whiteIndex + moves[rng.nextInt(4)];
      while (randomIndex < 0 || randomIndex > 15) {
        randomIndex = whiteIndex + moves[rng.nextInt(4)];
      }
      moveTile(randomIndex);
      // await Future.delayed(const Duration(milliseconds: 1));
    }
  }

  readUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final String? name = prefs.getString('name');
    final List<String>? items = prefs.getStringList('userColor');
    final bool? hoverValue = prefs.getBool('hover');
    final bool? arrowKeysValue = prefs.getBool('arrowKeys');
    final bool? glideValue = prefs.getBool('glide');
    List<int> userColorScheme = [];
    if (items != null) {
      userColorScheme = items.map((e) => int.parse(e)).toList();
    } else {
      userColorScheme = fringeScheme;
    }
    setState(() {
      currentUser = User(
        name: name ?? "egg",
        hover: hoverValue ?? true,
        arrowKeys: arrowKeysValue ?? false,
        glide: glideValue ?? true,
        colorScheme: userColorScheme,
      );
    });
  }

  @override
  void initState() {
    super.initState();
    readUserData();
    setupGame(0);
    if (!kIsWeb) {
      setState(() {
        keyList = List.generate(16, (index) => GlobalKey());
      });
    }
    WidgetsBinding.instance?.addPostFrameCallback((_) {
      if (!kIsWeb) {
        createRenderBox();
      }
    });
  }

  @override
  void dispose() {
    _callbackTimer?.cancel();
    _stopwatch.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: IconButton(
          onPressed: () {},
          icon: const Icon(Icons.dashboard_customize, color: Colors.black),
          tooltip: 'Home',
        ),
        actions: [
          IconButton(
            onPressed: () {
              _stopwatch.stop();
              _callbackTimer?.cancel();
              Navigator.push(
                context,
                PageRouteBuilder(
                  pageBuilder: (context, animation1, animation2) =>
                      VersusScreen(
                    firestoreInstance: firestoreInstance,
                    currentUser: currentUser!,
                  ),
                  transitionDuration: Duration.zero,
                  reverseTransitionDuration: Duration.zero,
                ),
              ).then((value) => readUserData());
            },
            icon: const Icon(Icons.sports_kabaddi),
            tooltip: 'Find Match',
          ),
          IconButton(
            onPressed: () {
              _stopwatch.stop();
              _callbackTimer?.cancel();
              Navigator.push(
                context,
                PageRouteBuilder(
                  pageBuilder: (context, animation1, animation2) =>
                      LeaderBoardsScreen(
                    firestoreInstance: firestoreInstance,
                    currentUser: currentUser!,
                  ),
                  transitionDuration: Duration.zero,
                  reverseTransitionDuration: Duration.zero,
                ),
              ).then((value) => readUserData());
            },
            icon: const Icon(Icons.leaderboard),
            tooltip: 'Leaderboards',
          ),
          IconButton(
            onPressed: () {
              _stopwatch.stop();
              _callbackTimer?.cancel();
              Navigator.push(
                context,
                PageRouteBuilder(
                  pageBuilder: (context, animation1, animation2) =>
                      SettingsScreen(
                    firestoreInstance: firestoreInstance,
                    currentUser: currentUser!,
                  ),
                  transitionDuration: Duration.zero,
                  reverseTransitionDuration: Duration.zero,
                ),
              ).then((value) => readUserData());
            },
            icon: const Icon(Icons.settings),
            tooltip: 'Settings',
          )
        ],
      ),
      body: Listener(
        onPointerSignal: (ps) {
          if (kIsWeb) {
            if (ps is PointerScrollEvent) {
              final newOffset = mainScrollController.offset + ps.scrollDelta.dy;
              if (ps.scrollDelta.dy.isNegative) {
                mainScrollController.jumpTo(max(0, newOffset));
              } else {
                mainScrollController.jumpTo(min(
                    mainScrollController.position.maxScrollExtent, newOffset));
              }
            }
          }
        },
        child: RawKeyboardListener(
          focusNode: FocusNode(),
          autofocus: true,
          onKey: (RawKeyEvent event) async {
            if (currentUser != null) {
              if (currentUser!.arrowKeys) {
                if (event.isKeyPressed(LogicalKeyboardKey.arrowUp)) {
                  moveTile(tiles.indexOf(16) + 4);
                } else if (event.isKeyPressed(LogicalKeyboardKey.arrowDown)) {
                  moveTile(tiles.indexOf(16) - 4);
                } else if (event.isKeyPressed(LogicalKeyboardKey.arrowLeft)) {
                  moveTile(tiles.indexOf(16) + 1);
                } else if (event.isKeyPressed(LogicalKeyboardKey.arrowRight)) {
                  moveTile(tiles.indexOf(16) - 1);
                }
              }
            }
          },
          child: SingleChildScrollView(
            physics: kIsWeb ? const NeverScrollableScrollPhysics() : null,
            controller: mainScrollController,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(),
                Padding(
                  padding: const EdgeInsets.only(top: 35),
                  child: _buildGameModeButton(),
                ),
                (selectedGameOptionIndex > 0
                    ? Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text("Game ${currentPuzzleIndex + 1}"),
                      )
                    : const SizedBox.shrink()),
                Padding(
                  padding: const EdgeInsets.only(top: 28, bottom: 16),
                  child: Text(
                    stopwatchFormatter(_stopwatch.elapsed),
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
                GestureDetector(
                  onVerticalDragUpdate: (_) {},
                  child: Container(
                    constraints: const BoxConstraints(
                      maxWidth: 375,
                      minHeight: 200,
                    ),
                    decoration: const BoxDecoration(color: Colors.transparent),
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
                          return kIsWeb
                              ? _buildWebTile(index)
                              : _buildMobileTile(index);
                        },
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 35),
                  child: _buildPuzzleStats(),
                ),
              ],
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
        if (currentUser != null) {
          if (currentUser!.glide) {
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
        }
      },
      child: Container(
        color: currentUser != null
            ? colorChoices[currentUser!.colorScheme[tiles[index] - 1]]
            : Colors.transparent,
        margin: EdgeInsets.zero,
        child: Center(
          child: Text(
            "${tiles[index] == 16 ? "" : tiles[index]}",
            style: TextStyle(
                color: currentUser != null
                    ? (currentUser!.colorScheme[tiles[index] - 1] == 7
                        ? Colors.white
                        : null)
                    : null),
          ),
        ),
      ),
    );
  }

  _buildWebTile(int index) {
    return InkWell(
      onHover: (val) {
        if (currentUser != null) {
          if (currentUser!.hover) {
            moveTile(index);
          }
        }
      },
      onTap: () => moveTile(index),
      child: Container(
        color: currentUser != null
            ? colorChoices[currentUser!.colorScheme[tiles[index] - 1]]
            : Colors.transparent,
        child: Center(
          child: Text(
            "${tiles[index] == 16 ? "" : tiles[index]}",
            style: TextStyle(
                color: currentUser != null
                    ? (currentUser!.colorScheme[tiles[index] - 1] == 7
                        ? Colors.white
                        : null)
                    : null),
          ),
        ),
      ),
    );
  }

  _buildGameModeButton() {
    return TextButton(
      onPressed: () {
        setState(() {
          selectedGameOptionIndex =
              selectedGameOptionIndex < 5 ? selectedGameOptionIndex + 1 : 0;
        });
        setupGame(selectedGameOptionIndex);
      },
      child: Text("Game Mode: ${gameOptions[selectedGameOptionIndex]}"),
    );
  }

  _buildPuzzleStats() {
    return Container(
      constraints: const BoxConstraints(
        maxWidth: 375,
        maxHeight: 375,
      ),
      child: ListView.separated(
        controller: scrollControllerB,
        itemCount: generatedPuzzles
            .where((element) => element.millisecondDuration != null)
            .length,
        shrinkWrap: true,
        separatorBuilder: (BuildContext context, int index) => const Divider(),
        itemBuilder: (context, index) {
          index = generatedPuzzles
                  .where((element) => element.millisecondDuration != null)
                  .length -
              1 -
              index;
          List<Puzzle> finishedPuzzles = generatedPuzzles
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
}
