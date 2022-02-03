import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:kinse/model/Match.dart';

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
  List<int> sequence = [];
  bool newPuzzle = true;
  int parity = 0, rawMS = 0, loops = 0;
  Duration elapsedTime = const Duration();
  final Stopwatch _stopwatch = Stopwatch();

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

  runStopwatchHackishCallback() {
    if (specificMoves.isEmpty) {
      _stopwatch.reset();
    }
    _stopwatch.start();
    Timer.periodic(const Duration(milliseconds: 15), (timer) {
      setState(() {});
      if (!_stopwatch.isRunning) {
        timer.cancel();
      }
    });
  }

  moveTile(int index) {
    if (index >= 0 && index < 16) {}
    int whiteIndex = tiles.indexOf(16);
    if (index - 1 == whiteIndex && index % 4 != 0 ||
        index + 1 == whiteIndex && (index + 1) % 4 != 0 ||
        index - 4 == whiteIndex ||
        index + 4 == whiteIndex) {
      if (!_stopwatch.isRunning && newPuzzle) {
        runStopwatchHackishCallback();
      }
      setState(() {
        tiles[whiteIndex] = tiles[index];
        tiles[index] = 16;
        specificMoves.add(index);
      });
      if (newPuzzle && listEquals(tiles, tilesF)) {
        _stopwatch.stop();
        setState(() {
          newPuzzle = false;
          elapsedTime = _stopwatch.elapsed;
        });
        Match result = Match(
          name: "badong2",
          date: DateTime.now(),
          millisecondDuration: elapsedTime.inMilliseconds,
          moves: specificMoves,
          parity: parity,
          sequence: sequence,
        );
        FirebaseFirestore.instance.collection('matches').add(result.toJson());
      }
    }
  }

  Set isSolveable(List<int> puzzle) {
    int parity = 0, row = 5, blankRow = 0;
    int gridWidth = sqrt(puzzle.length).toInt();

    for (int i = 0; i < puzzle.length - 1; i++) {
      if (i % gridWidth == 0) {
        row--;
      }
      if (puzzle[i] == 16) {
        blankRow = row;
      }
      for (int j = i + 1; j < puzzle.length; j++) {
        if (puzzle[i] > puzzle[j] && puzzle[j] != 16 && puzzle[i] != 16) {
          parity++;
        }
      }
    }
    if (gridWidth.isEven) {
      if (blankRow.isEven) {
        return {parity.isOdd, parity};
      } else {
        return {parity.isEven, parity};
      }
    } else {
      return {parity.isEven, parity};
    }
  }

  shuffle() {
    setState(() {
      tiles.shuffle();
      loops++;
      Set solveable = isSolveable(tiles);
      while (!solveable.first || solveable.last > 30) {
        tiles.shuffle();
        solveable = isSolveable(tiles);
        loops++;
      }
      parity = solveable.last;
      sequence = List.from(tiles);
    });
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

  timerApproach1() {
    Timer.periodic(const Duration(milliseconds: 1), (timer) {
      setState(() => rawMS++);
    });
  }

  @override
  void initState() {
    super.initState();
    shuffle();
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
            onPressed: () {},
            icon: const Icon(Icons.sports_kabaddi),
            tooltip: 'Find Match',
          ),
          IconButton(
            onPressed: () {
              _stopwatch.stop();
              Navigator.push(
                context,
                PageRouteBuilder(
                  pageBuilder: (context, animation1, animation2) =>
                      const LeaderBoardsScreen(),
                  transitionDuration: Duration.zero,
                  reverseTransitionDuration: Duration.zero,
                ),
              );
            },
            icon: const Icon(Icons.leaderboard),
            tooltip: 'Leaderboards',
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.settings),
            tooltip: 'Settings',
          )
        ],
      ),
      body: RawKeyboardListener(
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
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 50),
              Center(
                child: Text(
                  '${_stopwatch.elapsed}',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
              const SizedBox(height: 25),
              Flexible(
                child: Container(
                  constraints: const BoxConstraints(
                    maxWidth: 375,
                    minHeight: 200,
                  ),
                  decoration: const BoxDecoration(color: Colors.transparent),
                  child: GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 4),
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
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
              const SizedBox(height: 50),
            ],
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
      },
      child: Container(
        margin: EdgeInsets.all(0),
        color: tiles[index] == 16 ? Colors.transparent : Colors.white,
        child: Center(
          child: Text(
            "${tiles[index] == 16 ? "" : tiles[index]}",
          ),
        ),
      ),
    );
  }

  _buildWebTile(int index) {
    return InkWell(
      onHover: (val) => moveTile(index),
      onTap: () => moveTile(index),
      child: Container(
        color: Colors.transparent,
        child: Center(
          child: Text(
            "${tiles[index] == 16 ? "" : tiles[index]}",
          ),
        ),
      ),
    );
  }
}
