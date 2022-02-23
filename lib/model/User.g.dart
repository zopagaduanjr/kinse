// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'User.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

User _$UserFromJson(Map<String, dynamic> json) => User(
      name: json['name'] as String?,
      colorScheme:
          (json['colorScheme'] as List<dynamic>).map((e) => e as int).toList(),
      hover: json['hover'] as bool,
      arrowKeys: json['arrowKeys'] as bool,
      glide: json['glide'] as bool,
    );

Map<String, dynamic> _$UserToJson(User instance) => <String, dynamic>{
      'name': instance.name,
      'colorScheme': instance.colorScheme,
      'hover': instance.hover,
      'arrowKeys': instance.arrowKeys,
      'glide': instance.glide,
    };
