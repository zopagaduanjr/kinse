import 'package:json_annotation/json_annotation.dart';

part 'Puzzle.g.dart';

@JsonSerializable(explicitToJson: true)
class Puzzle {
  String? gameID;
  int order;
  DateTime? dateStarted;
  int? millisecondDuration;
  List<int>? moves;
  String? name;
  int parity;
  int loops;
  List<int> sequence;
  double? tps;
  Puzzle({
    required this.order,
    required this.parity,
    required this.loops,
    required this.sequence,
    this.gameID,
    this.dateStarted,
    this.millisecondDuration,
    this.moves,
    this.name,
    this.tps,
  });

  factory Puzzle.fromJson(Map<String, dynamic> json) => _$PuzzleFromJson(json);

  Map<String, dynamic> toJson() => _$PuzzleToJson(this);
}
