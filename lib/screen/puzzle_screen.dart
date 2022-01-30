import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class PuzzleScreen extends StatefulWidget {
  const PuzzleScreen({Key? key}) : super(key: key);

  @override
  _PuzzleScreenState createState() => _PuzzleScreenState();
}

class _PuzzleScreenState extends State<PuzzleScreen> {
  List<int> tiles = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16];

  moveTile(int index) {
    //Checks if this tile can move left, up, right, down
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

  isSolveable(List<int> puzzle) {
    int parity = 0, row = 0, blankRow = 0;
    double gridWidth = 4;

    for (int i = 0; i < puzzle.length; i++) {
      if (i % gridWidth == 0) {
        row++;
      }
      if (puzzle[i] == 16) {
        blankRow = row;
        continue;
      }
      for (int j = i + 1; j < puzzle.length; j++) {
        if (puzzle[i] > puzzle[j] && puzzle[j] != 16) {
          parity++;
        }
      }
    }
    if (gridWidth % 2 == 0) {
      if (blankRow % 2 == 0) {
        return parity % 2 == 0;
      } else {
        return parity % 2 != 0;
      }
    } else {
      return parity % 2 == 0;
    }
  }

  shuffle() {
    setState(() {
      tiles.shuffle();
      bool solveable = isSolveable(tiles);
      while (!solveable) {
        tiles.shuffle();
        solveable = isSolveable(tiles);
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
    shuffle();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: (kIsWeb
          ? null
          : AppBar(
              title: const Text('kinse'),
            )),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 250,
              height: 250,
              child: GridView.count(
                shrinkWrap: true,
                crossAxisCount: 4,
                children: List.generate(tiles.length, (index) {
                  return _buildTile(index);
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  _buildTile(int index) {
    return InkWell(
      child: Center(
        child: Text(
          "${tiles[index] == 16 ? "" : tiles[index]}",
        ),
      ),
      onTap: () {
        moveTile(index);
      },
    );
  }
}
