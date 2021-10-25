import 'dart:async';
import 'dart:isolate';

import 'package:nop_db/nop_db.dart';
import 'package:useful_tools/common.dart';

import 'base/book_event.dart';
import 'mixin/complex_mixin.dart';
import 'mixin/database_mixin.dart';
import 'mixin/event_messager_mixin.dart';
import 'mixin/network_mixin.dart';
import 'mixin/zhangdu_mixin.dart';

export 'base/constants.dart';
export 'base/repository.dart';

// mixin: 数据库、网络任务
class BookEventIsolate extends BookEventResolveMain
    with DatabaseMixin, NetworkMixin, ComplexMixin, ZhangduEventMixin {
  BookEventIsolate(
      this.sp, this.appPath, this.cachePath, this.useFfi, this.useSqflite3);

  @override
  final SendPort sp;
  @override
  final String appPath;
  @override
  final String cachePath;

  @override
  final bool useSqflite3;
  @override
  final bool useFfi;

  Future<void> initState() async {
    final d = initDb();
    final n = netEventInit();
    await d;
    await n;
  }

  @override
  void onError(error) {
    Log.e(error, onlyDebug: false);
  }

  // @override
  // bool remove(key) {
  //   assert(key is! KeyController || Log.w(key));
  //   return super.remove(key);
  // }

  // @override
  // bool resolve(m) {
  //   return super.resolve(m);
  // }
}

class BookEventMain extends BookEventMessagerMain
    with ComplexMessager, SaveImageMessager {
  BookEventMain(this.sendEvent);
  @override
  final SendEvent sendEvent;
}

void isolateEvent(List args) async {
  final port = args[0];
  final appPath = args[1];
  final cachePath = args[2];
  final useFfi = args[3];
  final useSqflite3 = args[4];
  final receivePort = ReceivePort();

  final db = BookEventIsolate(port, appPath, cachePath, useFfi, useSqflite3);
  await db.initState();

  receivePort.listen((m) {
    if (db.resolve(m)) return;
    Log.e('somthing was error: $m');
  });

  port.send(receivePort.sendPort);
}
