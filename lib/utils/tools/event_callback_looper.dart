import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

import '../utils.dart';

typedef FutureOrVoidCallback = FutureOr<void> Function();

typedef WaitCallback = Future<void> Function(
    [FutureOrVoidCallback? closure, String label]);

/// [_TaskEntry._run]
typedef EventCallback<T> = FutureOr<T> Function();

/// async tasks => sync tasks
///
/// 以队列的形式进行 异步任务。
///
/// 异步的本质：将回调函数注册到下一次事件队列中，在本次循环后调用
/// [await]: 由系统注册  (async/future_impl.dart#_thenAwait)
///
/// 在同一次事件循环中执行上一次的异步任务，如果上一次的异步任务过多有可能导致本次循环
/// 占用过多的 cpu 资源，导致渲染无法及时，造成卡顿。
class EventLooper {
  static EventLooper? _instance;
  EventLooper({this.parallels = 1});
  static EventLooper get instance {
    _instance ??= EventLooper();
    return _instance!;
  }

  final int parallels;
  // final now = Stopwatch()..start();

  // int get stopwatch => now.elapsedMicroseconds;

  SchedulerBinding get scheduler => SchedulerBinding.instance!;

  final _taskPool = <_TaskKey, _TaskEntry>{};

  Future<T> _addEventTask<T>(EventCallback<T> callback,
      {bool onlyLastOne = false, Object? newKey}) {
    var _task = _TaskEntry<T>(callback, this,
        onlyLastOne: onlyLastOne, objectKey: newKey);
    final key = _task.key;

    if (!_taskPool.containsKey(key)) {
      _taskPool[key] = _task;
    } else {
      _task = _taskPool[key]! as _TaskEntry<T>;
    }

    run();
    return _task.future;
  }

  /// 安排任务
  ///
  /// 队列模式
  Future<T> addEventTask<T>(EventCallback<T> callback, {Object? key}) =>
      _addEventTask<T>(callback, newKey: key);

  /// [onlyLastOne] 模式
  /// 由于此模式下，可能会丢弃任务，因此无返回值
  Future<void> addOneEventTask(EventCallback<void> callback, {Object? key}) =>
      _addEventTask<void>(callback, onlyLastOne: true, newKey: key);

  Future<void>? _runner;
  Future<void>? get runner => _runner;

  void run() {
    _runner ??= looper()..whenComplete(() => _runner = null);
  }

  @protected
  Future<void> looper() async {
    final parallelTasks = <_TaskKey, Future>{};
    // 由于之前操作都在 `同步` 中执行
    // 在下一次事件循环时处理任务
    await releaseUI;

    while (_taskPool.isNotEmpty) {
      final tasks = List.of(_taskPool.values);
      final last = tasks.last;
      await releaseUI;

      for (final task in tasks) {
        if (!task.onlyLastOne || task == last) {
          if (parallels > 1) {
            // 转移管理权
            // 已完成的任务会自动移除
            parallelTasks.putIfAbsent(task.key, () {
              _taskPool.remove(task.key);
              return eventRun(task)
                ..whenComplete(() => parallelTasks.remove(task.key));
            });

            // 达到 parallels 数                   ||   最后一个
            if (parallelTasks.length >= parallels || task == last) {
              // 任务池中没有任务，等待 parallelTasks 任务
              while (_taskPool.isEmpty || parallelTasks.length >= parallels) {
                if (parallelTasks.isEmpty) break;
                final activeTasks = List.of(parallelTasks.values);
                await Future.any(activeTasks);
                await releaseUI;
              }

              await releaseUI;

              // 所有任务都完成或刷新任务
              break;
            }
          } else {
            await eventRun(task);
            await releaseUI;
          }
        } else {
          task.completed();
        }
      }
    }
    assert(parallelTasks.isEmpty);
  }

  static const _zoneWait = 'eventWait';
  static const _zoneTask = 'eventTask';
  // 运行任务
  //
  // 提供时间消耗及等待其他任务
  Future<void> eventRun(_TaskEntry task) {
    return runZoned(task._run, zoneValues: {_zoneWait: _wait, _zoneTask: task});
  }

  Future<void> _wait([FutureOrVoidCallback? onLoop, String label = '']) async {
    final _task = currentTask;
    if (_task != null && _task.async) {
      var count = 0;
      while (scheduler.hasScheduledFrame) {
        if (count > 5000) break;

        /// 回到事件队列，让出资源
        await releaseUI;
        onLoop?.call();
        if (!_task.async) break;
        count++;
      }
    }
    await releaseUI;
  }

  Future<void> wait([FutureOrVoidCallback? closure, label = '']) async {
    final _w = Zone.current[_zoneWait];
    if (_w is WaitCallback) {
      return _w(closure, label);
    }
    if (closure != null) await closure();
    return releaseUI;
  }

  _TaskEntry? get currentTask {
    final _z = Zone.current[_zoneTask];
    if (_z is _TaskEntry) return _z;
  }

  bool get async {
    final _z = currentTask;
    if (_z is _TaskEntry) return _z.async;
    return false;
  }

  set async(bool v) {
    final _z = currentTask;
    if (_z is _TaskEntry) _z.async = v;
  }
}

class _TaskEntry<T> {
  _TaskEntry(this.callback, this._looper,
      {this.onlyLastOne = false, this.objectKey});

  final EventLooper _looper;
  final EventCallback<T> callback;
  Object? ident;
  final Object? objectKey;
  final bool onlyLastOne;
  late final key = _TaskKey<T>(_looper, callback, onlyLastOne, objectKey);

  final _completer = Completer<T>();
  var async = true;
  Future<T> get future => _completer.future;

  Future<void> _run() async {
    final result = await callback();
    completed(result);
  }

  bool _completed = false;
  void completed([T? result]) {
    assert(!_completed);
    assert(_completed = true);

    assert(!onlyLastOne || result == null);
    _completer.complete(result);
    _looper._taskPool.remove(key);
  }
}

class _TaskKey<T> {
  _TaskKey(this._looper, this.callback, this.onlyLastOne, this.key);
  final EventLooper _looper;
  final EventCallback callback;
  final bool onlyLastOne;
  final Object? key;
  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is _TaskKey<T> &&
            callback == other.callback &&
            _looper == other._looper &&
            onlyLastOne == other.onlyLastOne &&
            key == other.key;
  }

  @override
  int get hashCode => hashValues(callback, _looper, onlyLastOne, T, key);
}

enum EventStatus {
  done,
  ignoreAndRemove,
}

Future<void> get releaseUI => release(Duration.zero);
Future<void> release(Duration time) => Future.delayed(time);
