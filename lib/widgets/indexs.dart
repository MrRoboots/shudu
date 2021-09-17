import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_sticky_header/flutter_sticky_header.dart';
import 'package:provider/provider.dart';
import 'package:useful_tools/useful_tools.dart';

import '../data/data.dart';
import '../provider/provider.dart';

class IndexsWidget extends StatelessWidget {
  const IndexsWidget({Key? key, required this.onTap}) : super(key: key);
  final void Function(BuildContext context, int id, int cid) onTap;

  @override
  Widget build(BuildContext context) {
    return MediaQuery.removePadding(
      removeTop: true,
      removeBottom: true,
      context: context,
      child: DefaultTextStyle(
        style: context
            .read<TextStyleConfig>()
            .title3
            .copyWith(color: Colors.grey.shade800),
        child: GestureDetector(
          onTap: () {},
          child: RepaintBoundary(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final height = constraints.maxHeight;
                const extent = 32.0;
                const headerextent = 21.0;
                final halfHeight = (height - extent - headerextent) / 2;

                return _Indexs(
                  headerextent: headerextent,
                  extent: extent,
                  halfHeight: halfHeight,
                  height: height,
                  onTap: onTap,
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _Indexs extends StatefulWidget {
  const _Indexs({
    Key? key,
    required this.headerextent,
    required this.extent,
    required this.halfHeight,
    required this.height,
    required this.onTap,
  }) : super(key: key);

  final double headerextent;
  final double extent;
  final double halfHeight;
  final double height;
  final void Function(BuildContext context, int id, int cid) onTap;

  @override
  State<_Indexs> createState() => _IndexsState();
}

class _IndexsState extends State<_Indexs> {
  ScrollController? controller;

  @override
  void dispose() {
    controller?.dispose();
    indexBloc?.removeRegisterKey(lKey);
    indexBloc?.removeListener(_listenOnUpdate);
    super.dispose();
  }

  BookIndexNotifier? indexBloc;
  final lKey = Object();
  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    indexBloc
      ?..removeRegisterKey(lKey)
      ..removeListener(_listenOnUpdate);

    indexBloc = context.read<BookIndexNotifier>();

    indexBloc
      ?..addRegisterKey(lKey)
      ..addListener(_listenOnUpdate);
    setController();
  }

  void setController() {
    if (controller == null && indexBloc!.data?.isValid == true) {
      final offset = _compute();
      controller = ScrollController(initialScrollOffset: offset);
    }
  }

  double _compute() {
    final data = indexBloc!.data;

    if (data == null || !data.isValid) {
      return 0;
    }

    final indexs = data.chapters!;
    final volIndex = data.volIndex!;
    final index = data.index!;
    final vols = data.vols!;

    var offset = 0.0;
    offset = widget.headerextent * volIndex;
    for (var i = 0; i < volIndex; i++) {
      offset += indexs[i].length * widget.extent;
    }
    offset += index * widget.extent - widget.halfHeight;

    final allChapters = data.allChapters!;

    final max =
        allChapters.length * widget.extent + vols.length * widget.headerextent;

    offset = math.max(0.0, math.min(offset, max - widget.height));
    return offset;
  }

  void _listenOnUpdate() {
    setController();
    if (controller?.hasClients == true) {
      final offset = _compute();
      final position = controller!.offset;
      if ((position - offset).abs() <= 100) {
        controller!.animateTo(offset,
            duration: const Duration(milliseconds: 300), curve: Curves.ease);
      } else {
        controller!.jumpTo(offset);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
        animation: indexBloc!,
        builder: (context, _) {
          final data = indexBloc!.data;

          if (data == null) {
            return loadingIndicator();
          } else if (!data.isValid) {
            return reloadBotton(indexBloc!.loadIndexs);
          }

          final indexs = data.chapters!;
          final vols = data.vols!;

          return Scrollbar(
            controller: controller,
            interactive: true,
            thickness: 8,
            radius: const Radius.circular(5),
            child: CustomScrollView(
              controller: controller,
              slivers: [
                for (var i = 0; i < indexs.length; i++)
                  SliverStickyHeader.builder(
                    builder: (context, st) {
                      return Container(
                        height: widget.headerextent,
                        color: const Color.fromRGBO(150, 180, 160, 1),

                        child: Center(child: Text(vols[i])),
                        // height: headerextent,
                      );
                    },
                    sliver: _StickyBody(
                        l: indexs[i],
                        bookid: data.bookid!,
                        indexBloc: indexBloc!,
                        onTap: widget.onTap,
                        extent: widget.extent),
                  ),
              ],
            ),
          );
        });
  }
}

class _StickyBody extends StatelessWidget {
  const _StickyBody({
    Key? key,
    required this.l,
    required this.indexBloc,
    required this.onTap,
    required this.extent,
    required this.bookid,
  }) : super(key: key);

  final List<BookIndexChapter> l;
  final BookIndexNotifier indexBloc;
  final void Function(BuildContext context, int id, int cid) onTap;
  final double extent;
  final int bookid;
  @override
  Widget build(BuildContext context) {
    return SliverFixedExtentList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          return btn1(
            padding: const EdgeInsets.only(left: 10, right: 10),
            radius: 6,
            child: Row(
              textBaseline: TextBaseline.ideographic,
              children: [
                Expanded(
                  child: Text(
                    l[index].name ?? '',
                    softWrap: false,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (indexBloc.contains(l[index].id))
                  Text(
                    '已缓存',
                    softWrap: false,
                    overflow: TextOverflow.ellipsis,
                    style: context.read<TextStyleConfig>().body3,
                  )
              ],
            ),
            splashColor: Colors.grey[500],
            background: false,
            onTap: () {
              final id = l[index].id;
              if (id != null) onTap(context, bookid, id);
            },
          );
        },
        childCount: l.length,
      ),
      itemExtent: extent,
    );
  }
}