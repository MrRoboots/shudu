import 'dart:async';
import 'dart:isolate';

import '../utils/utils.dart';
import 'base/book_event.dart';
import 'mixin/complex_mixin.dart';
import 'mixin/database_mixin.dart';
import 'mixin/network_impl.dart';

// 以数据库为基类
// 网络任务 mixin
class BookEventIsolate extends BookEventResolve
    with DatabaseMixin, NetworkMixin, ComplexMixin {
  BookEventIsolate(this.appPath, this.sp);

  @override
  final SendPort sp;
  @override
  final String appPath;

  Future<void> initState() => init();

  @override
  void sendEnd(error) {
    Log.e(error);
  }

  @override
  bool resolve(m) {
    if (super.resolve(m)) return true;

    Log.e(m);

    return false;
  }
}
