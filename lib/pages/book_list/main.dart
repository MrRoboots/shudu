import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:useful_tools/useful_tools.dart';

import '../setting/setting.dart';
import 'book_history.dart';
import 'booklist.dart';
import 'cache_manager.dart';
import 'category.dart';
import 'top.dart';

class ListMainPage extends StatelessWidget {
  const ListMainPage({Key? key}) : super(key: key);

  bool isLight(BuildContext context) =>
      Theme.of(context).brightness == Brightness.light;

  @override
  Widget build(BuildContext context) {
    final light = isLight(context);
    Widget _builder(String text, VoidCallback onTap) {
      return btn1(
        radius: 10.0,
        bgColor: light ? null : Color.fromRGBO(25, 25, 25, 1),
        splashColor: light ? null : Color.fromRGBO(60, 60, 60, 1),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Center(
            child: Text(
          text,
          style: TextStyle(
              color: light ? Colors.grey.shade700 : Colors.grey.shade400),
        )),
        onTap: onTap,
      );
    }

    var v = 0;
    return Container(
      color: light ? Colors.grey.shade100 : Colors.grey.shade900,
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Expanded(
                child: _builder('书单', () {
                  Navigator.of(context)
                      .push(MaterialPageRoute(builder: (context) {
                    return BooklistPage();
                  }));
                }),
              ),
              const SizedBox(width: 5),
              Expanded(
                child: _builder('分类', () {
                  Navigator.of(context)
                      .push(MaterialPageRoute(builder: (context) {
                    return RepaintBoundary(child: ListCatetoryPage());
                  }));
                }),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Row(children: [
            Expanded(
              child: _builder('缓存管理', () {
                Navigator.of(context)
                    .push(MaterialPageRoute(builder: (context) {
                  return RepaintBoundary(child: CacheManager());
                }));
              }),
            ),
            const SizedBox(width: 5),
            Expanded(
              child: _builder('浏览历史', () {
                Navigator.of(context)
                    .push(MaterialPageRoute(builder: (context) {
                  return RepaintBoundary(child: BookHistory());
                }));
              }),
            ),
          ]),
          const SizedBox(height: 5),
          Row(children: [
            Expanded(
              child: _builder('榜单', () {
                Navigator.of(context)
                    .push(MaterialPageRoute(builder: (context) {
                  return RepaintBoundary(child: TopPage());
                }));
              }),
            ),
            const SizedBox(width: 5),
            Expanded(
              child: _builder('设置', () {
                Navigator.of(context)
                    .push(MaterialPageRoute(builder: (context) {
                  return Setting();
                }));
              }),
            )
          ]),
        ],
      ),
    );
  }
}
