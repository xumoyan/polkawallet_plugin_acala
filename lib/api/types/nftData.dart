import 'package:json_annotation/json_annotation.dart';

part 'nftData.g.dart';

@JsonSerializable()
class NFTData extends _NFTData {
  static NFTData fromJson(Map<String, dynamic> json) => _$NFTDataFromJson(json);
}

abstract class _NFTData {
  String description;
  String image = "";
  String name = "";
}
