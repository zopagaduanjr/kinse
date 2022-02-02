import 'package:json_annotation/json_annotation.dart';

part 'Match.g.dart';

@JsonSerializable(explicitToJson: true)
class Match {
  DateTime date;
  int millisecondDuration;
  List<int> moves;
  String name;
  int parity;
  List<int> sequence;
  Match({
    required this.date,
    required this.millisecondDuration,
    required this.moves,
    required this.name,
    required this.parity,
    required this.sequence,
  });

  factory Match.fromJson(Map<String, dynamic> json) => _$MatchFromJson(json);

  Map<String, dynamic> toJson() => _$MatchToJson(this);
}
