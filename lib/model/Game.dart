import 'package:json_annotation/json_annotation.dart';
import 'package:kinse/model/Puzzle.dart';

part 'Game.g.dart';

@JsonSerializable(explicitToJson: true)
class Game {
  String? id;
  String? name;
  int? gameType;
  DateTime? dateSubmitted;
  List<Puzzle>? puzzles;
  bool? isFinished;
  Game({
    this.id,
    this.name,
    this.gameType,
    this.dateSubmitted,
    this.puzzles,
    this.isFinished,
  });

  factory Game.fromJson(Map<String, dynamic> json) => _$GameFromJson(json);

  Map<String, dynamic> toJson() => _$GameToJson(this);
}
