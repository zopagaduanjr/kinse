import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:kinse/model/Game.dart';
import 'package:kinse/model/Puzzle.dart';

class MatchDetailWidget extends StatefulWidget {
  final Game game;
  final int? order;
  const MatchDetailWidget({
    Key? key,
    required this.game,
    this.order,
  }) : super(key: key);

  @override
  _MatchDetailWidgetState createState() => _MatchDetailWidgetState();
}

class _MatchDetailWidgetState extends State<MatchDetailWidget> {
  late Duration movesIntervalDuration;
  late StreamSubscription streamSubscription;
  final Stopwatch _stopwatch = Stopwatch();
  bool isPlaying = false;
  int speedIndex = 3,
      speedHistory = 0,
      millisecondOffset = 0,
      currentPuzzle = 0;
  int? millisecondPerMove;
  List<int> tilesCopy = [];
  List<double> speedOptions = [0.1, 0.25, 0.5, 1, 2, 4, 10, 20, 30];
  List<String> directions = [];
  List<Puzzle> puzzles = [];
  ListQueue<int> movesQueue = ListQueue<int>();
  StreamController playbackController = StreamController<int>();
  String formattedSequence = "";
  Timer? _streamTimer;
  Timer? _callbackTimer;

  String millisecondsFormatter(int totalMilliseconds) {
    int minutes = (totalMilliseconds / 1000) ~/ 60;
    String seconds = ((totalMilliseconds / 1000) % 60).toStringAsFixed(3);
    return "${minutes.toString().padLeft(2, '0')}:$seconds";
  }

  String stopwatchFormatter(Duration duration) {
    return duration.toString().substring(2, 11);
  }

  String gameType(int puzzleCount) {
    String type = "";
    if (puzzleCount == 1) {
      type = "Single";
    } else {
      type = "Average of $puzzleCount";
    }
    return type;
  }

  moveTile(int index) {
    if (index >= 0 && index < 16) {
      int whiteIndex = tilesCopy.indexOf(16);
      if (index - 1 == whiteIndex && index % 4 != 0 ||
          index + 1 == whiteIndex && (index + 1) % 4 != 0 ||
          index - 4 == whiteIndex ||
          index + 4 == whiteIndex) {
        setState(() {
          tilesCopy[whiteIndex] = tilesCopy[index];
          tilesCopy[index] = 16;
        });
      }
    }
  }

  backlogChecker() {
    if (movesQueue.isNotEmpty) {
      int theoreticalMovesDone =
          ((_stopwatch.elapsedMilliseconds * speedOptions[speedIndex]) +
                  speedHistory +
                  (millisecondPerMove! * millisecondOffset)) ~/
              millisecondPerMove!;
      int actualMovesDone =
          puzzles[currentPuzzle].moves!.length - movesQueue.length;
      if (theoreticalMovesDone - actualMovesDone != 0) {
        for (int i = 0; i <= theoreticalMovesDone - actualMovesDone; i++) {
          if (movesQueue.isNotEmpty) {
            playbackController.sink.add(movesQueue.removeFirst());
          }
        }
      }
    }
  }

  startPlaybackStream() {
    backlogChecker();
    _stopwatch.start();
    setState(() {
      _callbackTimer = Timer.periodic(
        const Duration(milliseconds: 15),
        (timer) {
          if (mounted) {
            setState(() {});
          } else {
            timer.cancel();
          }
        },
      );
      _streamTimer = Timer.periodic(movesIntervalDuration, (timer) async {
        if (_stopwatch.isRunning && isPlaying == false) {
          _stopwatch.stop();
          timer.cancel();
        } else if (movesQueue.isEmpty) {
          timer.cancel();
          _stopwatch.stop();
          isPlaying = false;
        } else if (isPlaying && movesQueue.isNotEmpty) {
          playbackController.sink.add(movesQueue.removeFirst());
        }
      });
    });
  }

  playPauseToggle() {
    setState(() {
      isPlaying = !isPlaying;
      if (isPlaying) {
        if (movesQueue.isEmpty) {
          setState(() {
            _stopwatch.stop();
            _stopwatch.reset();
            tilesCopy = List.from(puzzles[currentPuzzle].sequence);
            movesQueue = ListQueue.from(puzzles[currentPuzzle].moves!);
            millisecondOffset = 0;
            speedHistory = 0;
          });
        }
        startPlaybackStream();
      } else {
        _stopwatch.stop();
        _streamTimer?.cancel();
        _callbackTimer?.cancel();
      }
    });
  }

  stepBackward() {
    if (isPlaying) {
      setState(() {
        isPlaying = !isPlaying;
        _stopwatch.stop();
        _streamTimer?.cancel();
        _callbackTimer?.cancel();
      });
    }
    int difference = puzzles[currentPuzzle].moves!.length - movesQueue.length;
    if (difference > 0) {
      int currentIndex = difference - 1;
      if (difference == 1) {
        playbackController.sink
            .add(puzzles[currentPuzzle].sequence.indexOf(16));
        setState(() {
          movesQueue.addFirst(puzzles[currentPuzzle].moves![currentIndex]);
          millisecondOffset = 0;
          speedHistory = 0;
        });
        _stopwatch.reset();
      } else {
        playbackController.sink
            .add(puzzles[currentPuzzle].moves![difference - 2]);
        setState(() {
          movesQueue.addFirst(puzzles[currentPuzzle].moves![currentIndex]);
          millisecondOffset = millisecondOffset - 1;
        });
      }
    }
  }

  stepForward() {
    if (isPlaying) {
      setState(() {
        isPlaying = !isPlaying;
      });
    }
    if (movesQueue.isNotEmpty) {
      playbackController.sink.add(movesQueue.removeFirst());
      setState(() {
        millisecondOffset = millisecondOffset + 1;
      });
      _stopwatch.stop();
      _streamTimer?.cancel();
      _callbackTimer?.cancel();
    }
  }

  modifyPlaybackSpeed() {
    setState(() {
      _callbackTimer?.cancel();
      _streamTimer?.cancel();
      _stopwatch.stop();
      speedHistory = speedHistory +
          (_stopwatch.elapsedMilliseconds * speedOptions[speedIndex]).toInt();
      speedIndex = speedIndex < (speedOptions.length - 1) ? speedIndex + 1 : 0;
      movesIntervalDuration = Duration(
          milliseconds: (puzzles[currentPuzzle].millisecondDuration! *
                  (1 / speedOptions[speedIndex])) ~/
              puzzles[currentPuzzle].moves!.length);
      _stopwatch.reset();
    });
    if (isPlaying) {
      startPlaybackStream();
    }
  }

  movesToDirection() {
    List<int> currentTileConfiguration =
        List.from(puzzles[currentPuzzle].sequence);
    List<String> convertedMoves = [];
    for (var index in puzzles[currentPuzzle].moves!) {
      var whiteIndex = currentTileConfiguration.indexOf(16);
      if (index - 1 == whiteIndex && index % 4 != 0) {
        convertedMoves.add('right');
      } else if (index + 1 == whiteIndex && (index + 1) % 4 != 0) {
        convertedMoves.add('left');
      } else if (index - 4 == whiteIndex) {
        convertedMoves.add('down');
      } else if (index + 4 == whiteIndex) {
        convertedMoves.add('up');
      }
      currentTileConfiguration[whiteIndex] = currentTileConfiguration[index];
      currentTileConfiguration[index] = 16;
    }
    setState(() {
      directions = convertedMoves;
    });
  }

  formatSequence() {
    try {
      setState(() {
        formattedSequence = "${puzzles[currentPuzzle].sequence[0]} "
                "${puzzles[currentPuzzle].sequence[1]} ${puzzles[currentPuzzle].sequence[2]} "
                "${puzzles[currentPuzzle].sequence[3]}/${puzzles[currentPuzzle].sequence[4]} "
                "${puzzles[currentPuzzle].sequence[5]} ${puzzles[currentPuzzle].sequence[6]} "
                "${puzzles[currentPuzzle].sequence[7]}/${puzzles[currentPuzzle].sequence[8]} "
                "${puzzles[currentPuzzle].sequence[9]} ${puzzles[currentPuzzle].sequence[10]} "
                "${puzzles[currentPuzzle].sequence[11]}/${puzzles[currentPuzzle].sequence[12]} "
                "${puzzles[currentPuzzle].sequence[13]} ${puzzles[currentPuzzle].sequence[14]} "
                "${puzzles[currentPuzzle].sequence[15]}"
            .replaceAll('16', '0');
      });
    } catch (error) {
      setState(() {
        formattedSequence =
            puzzles[currentPuzzle].sequence.toString().replaceAll('16', '0');
      });
    }
  }

  movePuzzle(int direction) {
    if (currentPuzzle + direction >= 0 &&
        currentPuzzle + direction < puzzles.length) {
      _stopwatch.stop();
      _streamTimer?.cancel();
      _callbackTimer?.cancel();
      setState(() {
        currentPuzzle = currentPuzzle + direction;
        isPlaying = false;
        millisecondPerMove = puzzles[currentPuzzle].millisecondDuration! ~/
            puzzles[currentPuzzle].moves!.length;
        tilesCopy = List.from(puzzles[currentPuzzle].sequence);
        movesQueue = ListQueue.from(puzzles[currentPuzzle].moves!);
        movesIntervalDuration = Duration(
            milliseconds: (puzzles[currentPuzzle].millisecondDuration! *
                    (1 / speedOptions[speedIndex])) ~/
                puzzles[currentPuzzle].moves!.length);
        millisecondOffset = 0;
        speedHistory = 0;
      });
      movesToDirection();
      formatSequence();
      _stopwatch.reset();
    }
  }

  initialSetup() {
    setState(() {
      puzzles = widget.game.puzzles!;
      currentPuzzle = widget.order ?? 0;
      millisecondPerMove = puzzles[currentPuzzle].millisecondDuration! ~/
          puzzles[currentPuzzle].moves!.length;
      tilesCopy = List.from(puzzles[currentPuzzle].sequence);
      movesQueue = ListQueue.from(puzzles[currentPuzzle].moves!);
      movesIntervalDuration = Duration(
          milliseconds: (puzzles[currentPuzzle].millisecondDuration! *
                  (1 / speedOptions[speedIndex])) ~/
              puzzles[currentPuzzle].moves!.length);
      streamSubscription = playbackController.stream.listen((event) {
        moveTile(event as int);
      });
    });
    movesToDirection();
    formatSequence();
  }

  disposeTimers() {
    _streamTimer?.cancel();
    _callbackTimer?.cancel();
    _stopwatch.stop();
    streamSubscription.cancel();
  }

  @override
  void initState() {
    super.initState();
    initialSetup();
  }

  @override
  void dispose() {
    disposeTimers();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
      child: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 25, bottom: 8),
              child: Text(
                '${puzzles[currentPuzzle].name!} - ${gameType(puzzles.length)}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            (puzzles.length == 1
                ? const SizedBox.shrink()
                : buildPuzzlePicker()),
            Container(
              constraints: BoxConstraints(
                maxWidth: kIsWeb ? 375 : 175,
                minHeight: kIsWeb ? 200 : 93,
              ),
              decoration: const BoxDecoration(color: Colors.transparent),
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4),
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                scrollDirection: Axis.vertical,
                itemCount: tilesCopy.length,
                itemBuilder: (context, index) {
                  return Container(
                    color: Colors.transparent,
                    child: Center(
                      child: Text(
                        "${tilesCopy[index] == 16 ? "" : tilesCopy[index]}",
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                movesQueue.isEmpty
                    ? millisecondsFormatter(
                        puzzles[currentPuzzle].millisecondDuration!)
                    : stopwatchFormatter(
                        (_stopwatch.elapsed * speedOptions[speedIndex] +
                            (Duration(milliseconds: millisecondPerMove!) *
                                millisecondOffset) +
                            Duration(milliseconds: speedHistory))),
                style: const TextStyle(fontSize: 16),
              ),
            ),
            buildPlaybackOptions(),
            buildInformationText(
                'Time',
                millisecondsFormatter(
                    puzzles[currentPuzzle].millisecondDuration!)),
            buildInformationText('Number of Moves',
                puzzles[currentPuzzle].moves!.length.toString()),
            buildInformationText(
                'TPS', puzzles[currentPuzzle].tps!.toStringAsFixed(3)),
            GestureDetector(
              onTap: () {
                Clipboard.setData(ClipboardData(text: formattedSequence));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Copied to clipboard'),
                    behavior: SnackBarBehavior.floating,
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              child: buildInformationText('Sequence', formattedSequence),
            ),
            buildInformationText(
                'Parity', puzzles[currentPuzzle].parity.toString()),
            buildInformationText(
                'Moves',
                directions
                    .toString()
                    .substring(1, directions.toString().length - 1)),
            buildInformationText(
                'Date Played',
                DateFormat("MM/dd/yyyy hh:mm aaa")
                    .format(puzzles[currentPuzzle].dateStarted!)),
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }

  buildInformationText(String label, String value) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(label, textAlign: TextAlign.center),
          ),
          Text(value, textAlign: TextAlign.center),
        ],
      ),
    );
  }

  buildPlaybackOptions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Flexible(
          child: IconButton(
              onPressed: () => stepBackward(),
              icon: const Icon(Icons.navigate_before)),
        ),
        Flexible(
          child: IconButton(
            onPressed: () => playPauseToggle(),
            icon: isPlaying
                ? (movesQueue.isEmpty
                    ? const Icon(Icons.restart_alt)
                    : const Icon(Icons.pause))
                : (movesQueue.isEmpty
                    ? const Icon(Icons.rotate_left)
                    : const Icon(Icons.play_arrow)),
          ),
        ),
        Flexible(
          child: IconButton(
              onPressed: () => stepForward(),
              icon: const Icon(Icons.navigate_next)),
        ),
        Flexible(
          child: TextButton(
              onPressed: () => modifyPlaybackSpeed(),
              child: Text("x${speedOptions[speedIndex]}")),
        ),
      ],
    );
  }

  buildPuzzlePicker() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Flexible(
          child: IconButton(
              onPressed: () => movePuzzle(-1),
              icon: const Icon(Icons.navigate_before)),
        ),
        Flexible(
          child: Text("Game ${currentPuzzle + 1}"),
        ),
        Flexible(
          child: IconButton(
              onPressed: () => movePuzzle(1),
              icon: const Icon(Icons.navigate_next)),
        ),
      ],
    );
  }
}
