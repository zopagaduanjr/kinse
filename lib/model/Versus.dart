import 'package:json_annotation/json_annotation.dart';

import 'Puzzle.dart';

part 'Versus.g.dart';

@JsonSerializable(explicitToJson: true)
class Versus {
  String? id;
  DateTime? queueStarted;
  DateTime? queueEnded;
  String? playerA;
  String? playerB;
  int? gameType;
  String? gameAID;
  String? gameBID;
  List<Puzzle>? puzzles;
  bool? isFindingMatch;
  Versus({
    this.id,
    this.queueStarted,
    this.queueEnded,
    this.playerA,
    this.playerB,
    this.gameType,
    this.gameAID,
    this.gameBID,
    this.puzzles,
    this.isFindingMatch,
  });

  factory Versus.fromJson(Map<String, dynamic> json) => _$VersusFromJson(json);

  Map<String, dynamic> toJson() => _$VersusToJson(this);
}
