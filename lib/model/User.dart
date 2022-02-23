import 'package:json_annotation/json_annotation.dart';

part 'User.g.dart';

@JsonSerializable(explicitToJson: true)
class User {
  String? name;
  List<int> colorScheme;
  bool hover;
  bool arrowKeys;
  bool glide;
  User({
    this.name,
    required this.colorScheme,
    required this.hover,
    required this.arrowKeys,
    required this.glide,
  });

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);

  Map<String, dynamic> toJson() => _$UserToJson(this);
}
