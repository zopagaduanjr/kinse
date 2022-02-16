// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'Game.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Game _$GameFromJson(Map<String, dynamic> json) => Game(
      id: json['id'] as String?,
      name: json['name'] as String?,
      gameType: json['gameType'] as int?,
      dateSubmitted: json['dateSubmitted'] == null
          ? null
          : DateTime.parse(json['dateSubmitted'] as String),
      puzzles: (json['puzzles'] as List<dynamic>?)
          ?.map((e) => Puzzle.fromJson(e as Map<String, dynamic>))
          .toList(),
      averageTime: (json['averageTime'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$GameToJson(Game instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'gameType': instance.gameType,
      'dateSubmitted': instance.dateSubmitted?.toIso8601String(),
      'puzzles': instance.puzzles?.map((e) => e.toJson()).toList(),
      'averageTime': instance.averageTime,
    };
