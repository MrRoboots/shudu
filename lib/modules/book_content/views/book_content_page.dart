import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:nop/event_queue.dart';
import 'package:useful_tools/useful_tools.dart';

import '../../../api/api.dart';
import '../../../routes/routes.dart';
import '../../../widgets/page_animation.dart';
import '../../home.dart';
import '../../setting/setting.dart';
import '../providers/content_notifier.dart';
import '../providers/content_notifier/content_base.dart';
import '../widgets/page_view.dart';

enum SettingView { indexs, setting, none }

class BookContentPage extends StatefulWidget {
  const BookContentPage({Key? key}) : super(key: key);

  static Object? _lock;
  static Future push(BuildContext context, int newBookid, int cid, int page,
      ApiType api) async {
    if (_lock != null) return;
    _lock = const Object();
    try {
      final bloc = context.getType<ContentNotifier>();
      await bloc.touchBook(newBookid, cid, page, api: api);
    } catch (_) {}
    _lock = null;
    return NavRoutes.bookContentPage().go;
    // return Nav.push(MaterialPageRoute(builder: (context) {
    //   return AnnotatedRegion<SystemUiOverlayStyle>(
    //       value: getOverlayStyle(dark: context.isDarkMode, statusDark: true),
    //       child: const RepaintBoundary(child: BookContentPage()));
    // }));
  }

  @override
  BookContentPageState createState() => BookContentPageState();
}

class BookContentPageState extends State<BookContentPage>
    with WidgetsBindingObserver, PageAnimationMixin {
  late ContentNotifier bloc;
  late BookCacheNotifier blocCache;
  late ValueListenable<Color?> notifyColor;
  late OptionsNotifier notifier;
  late OverlayObserverState observer;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance!.addObserver(this);
    observer = OverlayObserverState(overlayGetter: overlayGetter);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    bloc = context.getType<ContentNotifier>();
    blocCache = context.getType<BookCacheNotifier>();
    notifier = context.getType();
    notifyColor = bloc.config.select((parent) => parent.value.bgcolor);
  }

  @override
  void dispose() {
    WidgetsBinding.instance!.removeObserver(this);
    super.dispose();
  }

  @override
  void initOnceTask() {
    super.initOnceTask();
    if (bloc.config.value.orientation!) {
      tqGlobal.pushOne(() async {
        if (!bloc.uiOverlayShow) await uiOverlay();
      });
    }
  }

  Timer? errorTimer;
  @override
  Widget build(context) {
    bloc.metricsChange(MediaQuery.of(context));
    Widget child = AnimatedBuilder(
      animation: notifyColor,
      builder: (context, child) {
        return Material(color: notifyColor.value, child: child);
      },
      child: RepaintBoundary(
        child: Stack(
          fit: StackFit.expand,
          children: [
            const Positioned.fill(
                child: RepaintBoundary(child: ContentPageView())),
            Positioned.fill(
              child: RepaintBoundary(
                child: AnimatedBuilder(
                  animation: bloc.listenable,
                  builder: (context, _) {
                    if (bloc.error.value.error) {
                      errorTimer?.cancel();
                      errorTimer = Timer(const Duration(seconds: 2), () {
                        bloc.notifyState(error: NotifyMessage.hide);
                      });

                      return GestureDetector(
                        onTap: () =>
                            bloc.notifyState(error: NotifyMessage.hide),
                        child: Center(
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(6.0),
                              color: Colors.grey.shade100,
                            ),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12.0, vertical: 6.0),
                            child: Text(
                              bloc.error.value.msg,
                              style: TextStyle(
                                  color: Colors.grey.shade700, fontSize: 13.0),
                              overflow: TextOverflow.fade,
                            ),
                          ),
                        ),
                      );
                    } else if (bloc.loading.value) {
                      return IgnorePointer(
                        child: RepaintBoundary(
                          child: AnimatedBuilder(
                            animation: bloc.loading,
                            builder: (context, child) {
                              if (bloc.loading.value) return child!;

                              return const SizedBox.shrink();
                            },
                            child: loadingIndicator(),
                          ),
                        ),
                      );
                    }
                    return const SizedBox();
                  },
                ),
              ),
            ),
            Positioned.fill(child: RepaintBoundary(child: Overlay(key: key))),
          ],
        ),
      ),
    );

    return WillPopScope(
        onWillPop: onWillPop,
        child: MediaQuery.removePadding(
            context: context,
            removeTop: true,
            child: Nop<OverlayObserver>.value(value: observer, child: child)));
  }

  final key = GlobalKey<OverlayState>();

  OverlayState? get getOverlay {
    if (!mounted) {
      throw OverlayGetterError('退出');
    }
    return key.currentState;
  }

  OverlayState? overlayGetter() {
    return getOverlay;
  }

  int getLength() {
    return observer.entriesState.length;
  }

  Future<bool> onWillPop() async {
    bloc.showCname.value = false;
    if (getLength() > 1) {
      observer.hideLast();
      return false;
    }

    await bloc.onOut();
    tqGlobal.pushOne(() => uiOverlay(hide: false));

    await blocCache.load();
    // 横屏处理
    if (!bloc.config.value.orientation!) setOrientation(true);
    return true;
  }
}