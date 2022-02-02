// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'Match.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Match _$MatchFromJson(Map<String, dynamic> json) => Match(
      date: DateTime.parse(json['date'] as String),
      millisecondDuration: json['millisecondDuration'] as int,
      moves: (json['moves'] as List<dynamic>).map((e) => e as int).toList(),
      name: json['name'] as String,
      parity: json['parity'] as int,
      sequence:
          (json['sequence'] as List<dynamic>).map((e) => e as int).toList(),
    );

Map<String, dynamic> _$MatchToJson(Match instance) => <String, dynamic>{
      'date': instance.date.toIso8601String(),
      'millisecondDuration': instance.millisecondDuration,
      'moves': instance.moves,
      'name': instance.name,
      'parity': instance.parity,
      'sequence': instance.sequence,
    };
