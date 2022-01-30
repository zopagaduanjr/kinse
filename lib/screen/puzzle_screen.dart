import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class PuzzleScreen extends StatefulWidget {
  const PuzzleScreen({Key? key}) : super(key: key);

  @override
  _PuzzleScreenState createState() => _PuzzleScreenState();
}

class _PuzzleScreenState extends State<PuzzleScreen> {
  List<int> tiles = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: (kIsWeb
          ? null
          : AppBar(
              title: const Text('kinse'),
            )),
      body: Center(
        child: SizedBox(
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
      ),
    );
  }

  moveTile(int index) {
    //Checks if this tile can move left, up, right, down
    int whiteIndex = tiles.indexOf(16);
    if (index - 1 == whiteIndex ||
        index + 1 == whiteIndex ||
        index - 4 == whiteIndex ||
        index + 4 == whiteIndex) {
      setState(() {
        tiles[whiteIndex] = tiles[index];
        tiles[index] = 16;
      });
    }

    //last 4 index: can't move down
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
