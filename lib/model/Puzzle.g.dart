// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'Puzzle.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Puzzle _$PuzzleFromJson(Map<String, dynamic> json) => Puzzle(
      order: json['order'] as int,
      parity: json['parity'] as int,
      loops: json['loops'] as int,
      sequence:
          (json['sequence'] as List<dynamic>).map((e) => e as int).toList(),
      gameID: json['gameID'] as String?,
      dateStarted: json['dateStarted'] == null
          ? null
          : DateTime.parse(json['dateStarted'] as String),
      millisecondDuration: json['millisecondDuration'] as int?,
      moves: (json['moves'] as List<dynamic>?)?.map((e) => e as int).toList(),
      name: json['name'] as String?,
      tps: (json['tps'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$PuzzleToJson(Puzzle instance) => <String, dynamic>{
      'gameID': instance.gameID,
      'order': instance.order,
      'dateStarted': instance.dateStarted?.toIso8601String(),
      'millisecondDuration': instance.millisecondDuration,
      'moves': instance.moves,
      'name': instance.name,
      'parity': instance.parity,
      'loops': instance.loops,
      'sequence': instance.sequence,
      'tps': instance.tps,
    };
