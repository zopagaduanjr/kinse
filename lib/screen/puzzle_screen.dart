import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

class PuzzleScreen extends StatefulWidget {
  const PuzzleScreen({Key? key}) : super(key: key);

  @override
  _PuzzleScreenState createState() => _PuzzleScreenState();
}

class _PuzzleScreenState extends State<PuzzleScreen> {
  List<int> tiles = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16];
  List<GlobalKey> keyList = [];
  List<RenderBox> boxList = [];

  createRenderBox() {
    setState(() {
      for (var element in keyList) {
        boxList.add(element.currentContext!.findRenderObject() as RenderBox);
      }
    });
  }

  moveTile(int index) {
    if (index >= 0 && index < 16) {
      int whiteIndex = tiles.indexOf(16);
      if (index - 1 == whiteIndex && index % 4 != 0 ||
          index + 1 == whiteIndex && (index + 1) % 4 != 0 ||
          index - 4 == whiteIndex ||
          index + 4 == whiteIndex) {
        setState(() {
          tiles[whiteIndex] = tiles[index];
          tiles[index] = 16;
        });
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
      int loop = 1;
      Set solveable = isSolveable(tiles);
      while (!solveable.first) {
        tiles.shuffle();
        solveable = isSolveable(tiles);
        loop++;
      }
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

  @override
  void initState() {
    super.initState();
    // shuffle();
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
      appBar: (kIsWeb
          ? null
          : AppBar(
              title: const Text('kinse'),
            )),
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
            children: [
              SizedBox(
                width: 450,
                height: 450,
                child: GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 4,
                  children: List.generate(tiles.length, (index) {
                    return kIsWeb
                        ? _buildWebTile(index)
                        : _buildMobileTile(index);
                  }),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  _buildMobileTile(int index) {
    return Listener(
      key: keyList[index],
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
        color: Colors.transparent,
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
