import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
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
  List<int> tilesCopy = [];
  final Stopwatch _stopwatch = Stopwatch();
  Timer? _timer;
  bool isPlaying = false;

  moveTile(int index) {
    if (index >= 0 && index < 16) {}
    int whiteIndex = tilesCopy.indexOf(16);
    if (index - 1 == whiteIndex && index % 4 != 0 ||
        index + 1 == whiteIndex && (index + 1) % 4 != 0 ||
        index - 4 == whiteIndex ||
        index + 4 == whiteIndex) {
      if (mounted) {
        setState(() {
          tilesCopy[whiteIndex] = tilesCopy[index];
          tilesCopy[index] = 16;
        });
      }
    }
  }

  String millisecondsFormatter(int totalMilliseconds) {
    int minutes = (totalMilliseconds / 1000) ~/ 60;
    String seconds = ((totalMilliseconds / 1000) % 60).toStringAsFixed(3);
    return "$minutes:$seconds";
  }

  @override
  void initState() {
    super.initState();
    setState(() {
      tilesCopy = List.from(widget.match.sequence);
    });
  }

  @override
  void dispose() {
    super.dispose();
    _timer?.cancel();
    _stopwatch.stop();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(
                onPressed: () {
                  if (!isPlaying) {
                    _stopwatch.start();
                    setState(() {
                      isPlaying = !isPlaying;
                      _timer = Timer.periodic(const Duration(milliseconds: 15),
                          (timer) {
                        setState(() {});
                        if (!_stopwatch.isRunning) {
                          timer.cancel();
                        }
                      });
                    });
                  } else {
                    _stopwatch.stop();
                    setState(() {
                      isPlaying = !isPlaying;
                    });
                  }
                },
                child: Text(isPlaying ? 'Pause' : 'Play'),
              ),
              Text(
                '${_stopwatch.elapsed}',
                style: const TextStyle(fontSize: 16),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Speed: '),
              Slider(
                value: 1,
                min: 0.25,
                max: 2,
                label: "speed",
                onChanged: (double value) async {
                  setState(() {});
                },
              ),
            ],
          ),
          Container(
            constraints: const BoxConstraints(
              maxWidth: 175,
              minHeight: 200,
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
          buildInformationText(
              'Time', millisecondsFormatter(widget.match.millisecondDuration)),
          buildInformationText('Sequence', widget.match.sequence.toString()),
          buildInformationText('Parity', widget.match.parity.toString()),
          buildInformationText('Date', widget.match.parity.toString()),
          buildInformationText('Moves', widget.match.moves.length.toString()),
          SizedBox(height: 50),
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
          Text(value),
        ],
      ),
    );
  }
}
