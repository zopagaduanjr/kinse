import 'dart:async';
import 'dart:collection';

import 'package:flutter/material.dart';
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
  late StreamSubscription streamSubscription;
  late Duration movesIntervalDuration;
  List<int> tilesCopy = [];
  ListQueue<int> movesQueue = ListQueue<int>();
  final Stopwatch _stopwatch = Stopwatch();
  Timer? _streamTimer;
  Timer? _callbackTimer;
  Timer? _stopwatchLimitTimer;
  bool isPlaying = false;
  StreamController playbackController = StreamController<int>();
  int speedIndex = 3;
  int speedHistory = 0;
  int millisecondOffset = 0;
  int? millisecondPerMove;
  List<double> speedOptions = [0.1, 0.25, 0.5, 1, 2, 4, 10, 20, 30];

  String millisecondsFormatter(int totalMilliseconds) {
    int minutes = (totalMilliseconds / 1000) ~/ 60;
    String seconds = ((totalMilliseconds / 1000) % 60).toString();
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

  moveTileBackward(int index) {
    //TODO:check which condition will be true, then do the inverse of that
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

  startPlaybackStream() {
    setState(() {
      _stopwatch.start();
      _stopwatchLimitTimer = Timer(
        Duration(
            milliseconds: (((widget.match.millisecondDuration -
                            _stopwatch.elapsedMilliseconds) *
                        (1 / speedOptions[speedIndex])) +
                    speedHistory)
                .toInt()),
        () {
          for (var element in movesQueue) {
            moveTile(element);
          }
          _stopwatch.stop();
          _stopwatch.reset();
          _callbackTimer?.cancel();
          setState(() {
            isPlaying = false;
          });
        },
      );
      _callbackTimer = Timer.periodic(
        const Duration(milliseconds: 15),
        (timer) {
          setState(() {});
        },
      );
      if (movesQueue.isNotEmpty) {
        int theoreticalMovesDone =
            ((_stopwatch.elapsedMilliseconds * speedOptions[speedIndex]) +
                    speedHistory) ~/
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
      _streamTimer = Timer.periodic(movesIntervalDuration, (timer) {
        if (isPlaying && movesQueue.isNotEmpty) {
          playbackController.sink.add(movesQueue.removeFirst());
        }
        if (movesQueue.isEmpty) {
          timer.cancel();
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
        _stopwatchLimitTimer?.cancel();
        _streamTimer?.cancel();
        _callbackTimer?.cancel();
      }
    });
  }

  stepBackward() {
    //WIP
    if (isPlaying) {
      setState(() {
        isPlaying = !isPlaying;
      });
    }
    int difference = widget.match.moves.length - movesQueue.length;
    if (difference > 0) {
      playbackController.sink.add(widget.match.moves[difference - 1]);
      setState(() {
        millisecondOffset = millisecondOffset - 1;
      });
      _stopwatch.stop();
      _stopwatchLimitTimer?.cancel();
      _streamTimer?.cancel();
      _callbackTimer?.cancel();
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
      _stopwatchLimitTimer?.cancel();
      _streamTimer?.cancel();
      _callbackTimer?.cancel();
    } else {
      setState(() {
        tilesCopy = List.from(widget.match.sequence);
        movesQueue = ListQueue.from(widget.match.moves);
        _stopwatch.stop();
        _stopwatch.reset();
        millisecondOffset = 0;
      });
    }
  }

  modifyPlaybackSpeed() {
    setState(() {
      _stopwatch.stop();
      speedHistory = speedHistory +
          (_stopwatch.elapsedMilliseconds * speedOptions[speedIndex]).toInt();
      speedIndex = speedIndex < (speedOptions.length - 1) ? speedIndex + 1 : 0;
      movesIntervalDuration = Duration(
          milliseconds: (widget.match.millisecondDuration *
                  (1 / speedOptions[speedIndex])) ~/
              widget.match.moves.length);
      _stopwatch.reset();
      if (isPlaying) {
        _stopwatch.start();
        _stopwatchLimitTimer?.cancel();
        _streamTimer?.cancel();
        _stopwatchLimitTimer = Timer(
          Duration(
              milliseconds: (((widget.match.millisecondDuration -
                              _stopwatch.elapsedMilliseconds) *
                          (1 / speedOptions[speedIndex])) +
                      speedHistory)
                  .toInt()),
          () {
            for (var element in movesQueue) {
              moveTile(element);
            }
            _stopwatch.stop();
            _stopwatch.reset();
            _callbackTimer?.cancel();
            setState(() {
              isPlaying = false;
            });
          },
        );
        if (movesQueue.isNotEmpty) {
          int theoreticalMovesDone =
              ((_stopwatch.elapsedMilliseconds * speedOptions[speedIndex]) +
                      speedHistory) ~/
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
        _streamTimer = Timer.periodic(movesIntervalDuration, (timer) {
          if (isPlaying && movesQueue.isNotEmpty) {
            playbackController.sink.add(movesQueue.removeFirst());
          }
          if (movesQueue.isEmpty) {
            timer.cancel();
          }
        });
      }
    });
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
  }

  disposeTimers() {
    _streamTimer?.cancel();
    _callbackTimer?.cancel();
    _stopwatchLimitTimer?.cancel();
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
    return SingleChildScrollView(
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
            constraints: const BoxConstraints(
              maxWidth: 175,
              minHeight: 93,
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
          buildInformationText(
              'Time', millisecondsFormatter(widget.match.millisecondDuration)),
          buildInformationText('Sequence', widget.match.sequence.toString()),
          buildInformationText('Parity', widget.match.parity.toString()),
          buildInformationText('Moves', widget.match.moves.length.toString()),
          buildInformationText(
              'TPS',
              (widget.match.moves.length /
                      (widget.match.millisecondDuration / 1000))
                  .toStringAsFixed(3)),
          buildInformationText('Date Played',
              DateFormat("MM/dd/yyyy hh:mm aaa").format(widget.match.date)),
          const SizedBox(height: 50),
        ],
      ),
    );
  }

  buildInformationText(String label, String value) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Text(label),
          const SizedBox(height: 6),
          Text(value),
        ],
      ),
    );
  }

  buildPlaybackOptions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
            onPressed: () => stepBackward(),
            icon: const Icon(Icons.navigate_before)),
        IconButton(
          onPressed: () => playPauseToggle(),
          icon: isPlaying
              ? const Icon(Icons.pause)
              : const Icon(Icons.play_arrow),
        ),
        IconButton(
            onPressed: () => stepForward(),
            icon: const Icon(Icons.navigate_next)),
        TextButton(
            onPressed: () => modifyPlaybackSpeed(),
            child: Text("${speedOptions[speedIndex]}")),
      ],
    );
  }
}
