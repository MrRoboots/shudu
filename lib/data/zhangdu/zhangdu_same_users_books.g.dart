// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'zhangdu_same_users_books.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ZhangduSameUsersBooks _$ZhangduSameUsersBooksFromJson(
        Map<String, dynamic> json) =>
    ZhangduSameUsersBooks(
      code: json['code'] as int?,
      data: (json['data'] as List<dynamic>?)
          ?.map((e) =>
              ZhangduSameUsersBooksData.fromJson(e as Map<String, dynamic>))
          .toList(),
      msg: json['msg'] as String?,
      time: json['time'] as int?,
    );

Map<String, dynamic> _$ZhangduSameUsersBooksToJson(
        ZhangduSameUsersBooks instance) =>
    <String, dynamic>{
      'code': instance.code,
      'data': instance.data,
      'msg': instance.msg,
      'time': instance.time,
    };

ZhangduSameUsersBooksData _$ZhangduSameUsersBooksDataFromJson(
        Map<String, dynamic> json) =>
    ZhangduSameUsersBooksData(
      id: json['id'] as int?,
      name: json['name'] as String?,
      picture: json['picture'] as String?,
      score: (json['score'] as num?)?.toDouble(),
      intro: json['intro'] as String?,
      bookType: json['bookType'] as int?,
      wordNum: json['wordNum'] as int?,
      author: json['author'] as String?,
      aliasAuthor: json['aliasAuthor'] as String?,
      protagonist: json['protagonist'] as String?,
      categoryId: json['categoryId'] as int?,
      categoryName: json['categoryName'] as String?,
      zipurl: json['zipurl'] as String?,
    );

Map<String, dynamic> _$ZhangduSameUsersBooksDataToJson(
        ZhangduSameUsersBooksData instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'picture': instance.picture,
      'score': instance.score,
      'intro': instance.intro,
      'bookType': instance.bookType,
      'wordNum': instance.wordNum,
      'author': instance.author,
      'aliasAuthor': instance.aliasAuthor,
      'protagonist': instance.protagonist,
      'categoryId': instance.categoryId,
      'categoryName': instance.categoryName,
      'zipurl': instance.zipurl,
    };