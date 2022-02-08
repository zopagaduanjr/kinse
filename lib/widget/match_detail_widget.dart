import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:kinse/model/Match.dart';

class MatchDetailWidget extends StatefulWidget {
  final Match match;
  const MatchDetailWidget({
    Key? key,
    required this.match,
  }) : super(key: key);

  @override
  _MatchDetailWidgetState createState() => _MatchDetailWidgetState();
}

class _MatchDetailWidgetState extends State<MatchDetailWidget> {
  late Duration movesIntervalDuration;
  late StreamSubscription streamSubscription;
  final Stopwatch _stopwatch = Stopwatch();
  bool isPlaying = false;
  int speedIndex = 3;
  int speedHistory = 0;
  int millisecondOffset = 0;
  int? millisecondPerMove;
  List<int> tilesCopy = [];
  List<double> speedOptions = [0.1, 0.25, 0.5, 1, 2, 4, 10, 20, 30];
  List<String> directions = [];
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
      int actualMovesDone = widget.match.moves.length - movesQueue.length;
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
    setState(() {
      backlogChecker();
      _stopwatch.start();
      _callbackTimer = Timer.periodic(
        const Duration(milliseconds: 15),
        (timer) {
          setState(() {});
        },
      );
      _streamTimer = Timer.periodic(movesIntervalDuration, (timer) {
        if (isPlaying && movesQueue.isNotEmpty) {
          playbackController.sink.add(movesQueue.removeFirst());
        }
        if (movesQueue.isEmpty) {
          timer.cancel();
          _stopwatch.stop();
          _callbackTimer?.cancel();
          setState(() {
            isPlaying = false;
          });
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
            tilesCopy = List.from(widget.match.sequence);
            movesQueue = ListQueue.from(widget.match.moves);
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
    int difference = widget.match.moves.length - movesQueue.length;
    if (difference > 0) {
      int currentIndex = difference - 1;
      if (difference == 1) {
        playbackController.sink.add(widget.match.sequence.indexOf(16));
        setState(() {
          movesQueue.addFirst(widget.match.moves[currentIndex]);
          millisecondOffset = 0;
          speedHistory = 0;
        });
        _stopwatch.reset();
      } else {
        playbackController.sink.add(widget.match.moves[difference - 2]);
        setState(() {
          movesQueue.addFirst(widget.match.moves[currentIndex]);
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
      _stopwatch.stop();
      _streamTimer?.cancel();
      speedHistory = speedHistory +
          (_stopwatch.elapsedMilliseconds * speedOptions[speedIndex]).toInt();
      speedIndex = speedIndex < (speedOptions.length - 1) ? speedIndex + 1 : 0;
      movesIntervalDuration = Duration(
          milliseconds: (widget.match.millisecondDuration *
                  (1 / speedOptions[speedIndex])) ~/
              widget.match.moves.length);
      _stopwatch.reset();
      if (isPlaying) {
        backlogChecker();
        _stopwatch.start();
        _streamTimer = Timer.periodic(movesIntervalDuration, (timer) {
          if (isPlaying && movesQueue.isNotEmpty) {
            playbackController.sink.add(movesQueue.removeFirst());
          }
          if (movesQueue.isEmpty) {
            timer.cancel();
            _stopwatch.stop();
            _callbackTimer?.cancel();
            setState(() {
              isPlaying = false;
            });
          }
        });
      }
    });
  }

  movesToDirection() {
    List<int> currentTileConfiguration = List.from(widget.match.sequence);
    List<String> convertedMoves = [];
    for (var index in widget.match.moves) {
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
        formattedSequence = "${widget.match.sequence[0]} "
                "${widget.match.sequence[1]} ${widget.match.sequence[2]} "
                "${widget.match.sequence[3]}/${widget.match.sequence[4]} "
                "${widget.match.sequence[5]} ${widget.match.sequence[6]} "
                "${widget.match.sequence[7]}/${widget.match.sequence[8]} "
                "${widget.match.sequence[9]} ${widget.match.sequence[10]} "
                "${widget.match.sequence[11]}/${widget.match.sequence[12]} "
                "${widget.match.sequence[13]} ${widget.match.sequence[14]} "
                "${widget.match.sequence[15]}"
            .replaceAll('16', '0');
      });
    } catch (error) {
      setState(() {
        formattedSequence =
            widget.match.sequence.toString().replaceAll('16', '0');
      });
    }
  }

  initialSetup() {
    setState(() {
      millisecondPerMove =
          widget.match.millisecondDuration ~/ widget.match.moves.length;
      tilesCopy = List.from(widget.match.sequence);
      movesQueue = ListQueue.from(widget.match.moves);
      movesIntervalDuration = Duration(
          milliseconds: (widget.match.millisecondDuration *
                  (1 / speedOptions[speedIndex])) ~/
              widget.match.moves.length);
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
                widget.match.name,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
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
                    ? millisecondsFormatter(widget.match.millisecondDuration)
                    : stopwatchFormatter(
                        (_stopwatch.elapsed * speedOptions[speedIndex] +
                            (Duration(milliseconds: millisecondPerMove!) *
                                millisecondOffset) +
                            Duration(milliseconds: speedHistory))),
                style: const TextStyle(fontSize: 16),
              ),
            ),
            buildPlaybackOptions(),
            buildInformationText('Time',
                millisecondsFormatter(widget.match.millisecondDuration)),
            buildInformationText(
                'Number of Moves', widget.match.moves.length.toString()),
            buildInformationText(
                'TPS',
                (widget.match.moves.length /
                        (widget.match.millisecondDuration / 1000))
                    .toStringAsFixed(3)),
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
            buildInformationText('Parity', widget.match.parity.toString()),
            buildInformationText(
                'Moves',
                directions
                    .toString()
                    .substring(1, directions.toString().length - 1)),
            buildInformationText('Date Played',
                DateFormat("MM/dd/yyyy hh:mm aaa").format(widget.match.date)),
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
          Text(label, textAlign: TextAlign.center),
          const SizedBox(height: 6),
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
}
