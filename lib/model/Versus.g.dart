// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'Versus.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Versus _$VersusFromJson(Map<String, dynamic> json) => Versus(
      id: json['id'] as String?,
      queueStarted: json['queueStarted'] == null
          ? null
          : DateTime.parse(json['queueStarted'] as String),
      queueEnded: json['queueEnded'] == null
          ? null
          : DateTime.parse(json['queueEnded'] as String),
      playerA: json['playerA'] as String?,
      playerB: json['playerB'] as String?,
      gameType: json['gameType'] as int?,
      gameAID: json['gameAID'] as String?,
      gameBID: json['gameBID'] as String?,
      puzzles: (json['puzzles'] as List<dynamic>?)
          ?.map((e) => Puzzle.fromJson(e as Map<String, dynamic>))
          .toList(),
      isFindingMatch: json['isFindingMatch'] as bool?,
    );

Map<String, dynamic> _$VersusToJson(Versus instance) => <String, dynamic>{
      'id': instance.id,
      'queueStarted': instance.queueStarted?.toIso8601String(),
      'queueEnded': instance.queueEnded?.toIso8601String(),
      'playerA': instance.playerA,
      'playerB': instance.playerB,
      'gameType': instance.gameType,
      'gameAID': instance.gameAID,
      'gameBID': instance.gameBID,
      'puzzles': instance.puzzles?.map((e) => e.toJson()).toList(),
      'isFindingMatch': instance.isFindingMatch,
    };
