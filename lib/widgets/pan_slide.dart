import 'dart:async';
import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:useful_tools/useful_tools.dart';

abstract class PanSlideState<T extends StatefulWidget> extends State<T>
    with TickerProviderStateMixin {
  late GlobalKey<PanOverlayState> _key;
  PanOverlayState? get _overlay => _key.currentState;

  @override
  void initState() {
    super.initState();
    _key = GlobalKey<PanOverlayState>();
  }

  bool isMounted(Widget child) {
    if (_overlay == null) return false;
    return _overlay!.childIsMounted(child);
  }

  final _entries = Queue<PanSlideController>();
  void _insert(PanSlideController controller) {
    if (_entries.contains(controller)) return;
    if (_overlay != null) {
      _overlay!.insert(controller._entry);
      if (_entries.isNotEmpty && controller.connect)
        _entries.last.next = controller;
      _entries.add(controller);
    }
  }

  void _remove(PanSlideController controller) {
    if (!_entries.contains(controller)) return;
    if (_overlay != null) {
      _entries.remove(controller);
      _overlay!.remove(controller._entry);
      assert(Log.i('remove #${controller.hashCode}'));
    }
  }

  void _removeGroups(PanSlideController controller) {
    if (!_entries.contains(controller)) return;
    if (_overlay != null) {
      for (final e in _entries.where((el) => el.groups == controller.groups)) {
        if (e == controller) continue;
        e._hide();
      }
    }
  }

  void hideAll() {
    for (var el in _entries) {
      el.dispose();
    }
  }

  int get entriesLength => _entries.length;
  Iterable<PanSlideController> get showEntries =>
      _entries.where((element) => !element.controller.isDismissed);

  // 立即删除已经隐藏的
  void removeHide() {
    _entries.removeWhere((element) {
      if (element.controller.isDismissed) {
        element._stop();
        _overlay!.remove(element._entry);
        return true;
      }
      return false;
    });
  }

  void hideLast() {
    removeHide();
    if (_entries.isNotEmpty) _entries.last.dispose();
  }

  Widget wrapOverlay(BuildContext context, Widget overlay);

  @override
  Widget build(context) => wrapOverlay(context, PanOverlay(key: _key));

  @override
  void dispose() {
    for (var el in _entries) {
      el._stop();
    }
    super.dispose();
  }
}

class PanOverlay extends StatefulWidget {
  const PanOverlay({Key? key}) : super(key: key);
  @override
  PanOverlayState createState() => PanOverlayState();
}

class PanOverlayState extends State<PanOverlay> {
  final _children = <Widget>[];

  bool childIsMounted(Widget child) => _children.contains(child);

  void insert(Widget child) {
    if (_children.contains(child)) return;
    setState(() {
      _children.add(child);
    });
  }

  void remove(Widget child) {
    if (_children.contains(child)) {
      setState(() {
        _children.remove(child);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: _children,
    );
  }
}

typedef StatusCallback = void Function(AnimationStatus status);
typedef FutureOrVoidCallback = Future<void> Function();

class PanSlideController {
  PanSlideController({
    required PanSlideState state,
    required Function(BuildContext, PanSlideController) builder,
    this.groups = 'default',
    this.connect = false,
    Duration duration = const Duration(milliseconds: 280),
    this.onhideEnd,
    this.onshowEnd,
    this.onanimating,
    this.onshow,
    this.onhide,
  })  : _pan = state,
        _controller = AnimationController(vsync: state, duration: duration) {
    _controller.addStatusListener(statusListen);
    _entry = Builder(builder: (context) => builder(context, this));
  }

  VoidCallback? onhideEnd;
  VoidCallback? onshowEnd;
  VoidCallback? onanimating;
  FutureOrVoidCallback? onhide;
  FutureOrVoidCallback? onshow;
  late Widget _entry;

  bool get mounted => _pan.isMounted(_entry);

  final PanSlideState _pan;
  PanSlideState get state => _pan;

  final AnimationController _controller;
  AnimationController get controller => _controller;

  bool connect;
  final String groups;
  PanSlideController? next;

  static PanSlideController showPan(State state,
      {VoidCallback? onhideEnd,
      VoidCallback? onshowEnd,
      VoidCallback? onanimating,
      FutureOrVoidCallback? onhide,
      FutureOrVoidCallback? onshow,
      required Widget Function(BuildContext, PanSlideController) builder}) {
    final _state = state is PanSlideState
        ? state
        : state.context.findAncestorStateOfType<PanSlideState>();
    assert(_state != null, 'PanSlideState == null');
    return PanSlideController(
        state: _state!,
        builder: builder,
        onhide: onhide,
        onshow: onshow,
        onanimating: onanimating,
        onhideEnd: onhideEnd,
        onshowEnd: onshowEnd);
  }

  void statusListen(AnimationStatus status) {
    if (status == AnimationStatus.dismissed) {
      _hideCallback?.call();
      _hideCallback = null;

      if (destory) {
        _destory();
      } else {
        onhideEnd?.call();
      }
    } else if (status == AnimationStatus.completed) {
      onshowEnd?.call();
    } else {
      onanimating?.call();
    }
  }

  bool get isShowing =>
      controller.status == AnimationStatus.completed ||
      controller.status == AnimationStatus.forward;
  bool get isAnimating =>
      controller.status == AnimationStatus.forward ||
      controller.status == AnimationStatus.reverse ||
      controller.isAnimating;

  void _removeAfter(bool destory) {
    var child = next;
    if (child != null) {
      if (destory) {
        next = null;
        child.dispose();
      } else {
        child._hide();
      }
    }
  }

  void hide({bool destory = false}) async {
    _hide();
    _removeAfter(destory);
  }

  void _hide() {
    if (!isShowing) return;
    controller.reverse();
  }

  void hideGroup() {
    if (!isShowing) return;
    _hide();
    _pan._removeGroups(this);
  }

  // 注册单次动画完成后回调
  void hideOnCallback([VoidCallback? callback]) {
    _hideCallback ??= callback;
    hide();
  }

  VoidCallback? _hideCallback;

  void init() {
    if (!mounted) _pan._insert(this);
  }

  void show() async {
    if (isShowing || _hideCallback != null || destory) return;
    init();
    controller.forward();
  }

  void trigger({bool immediate = true}) {
    if (isAnimating && !immediate || destory) return;
    if (isShowing) {
      hide();
    } else {
      show();
    }
  }

  bool get close => _state == closeState;
  bool get destory => _state <= destoryState;

  // 已经释放
  static const int closeState = 0;

  // 表示将要释放资源，当前对象将不再可用
  static const int destoryState = 1;

  // 存活
  static const int activeState = 2;

  int _state = activeState;

  /// 释放资源
  void _stop() {
    if (_state != closeState) {
      _state = closeState;
      onhideEnd?.call();
      controller.dispose();
    }
  }

  void _destory() {
    _stop();
    _pan._remove(this);
  }

  // 当前 [State] 结束生命周期时，调用
  void dispose() {
    if (destory) return;
    if (controller.isDismissed) {
      _destory();
    } else {
      // 动画完成之后释放
      hide(destory: true);
      _state = destoryState;
    }
  }

  /// controll state
  void hideAll() => _pan.hideAll();
}
