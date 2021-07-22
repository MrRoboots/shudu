import 'dart:async';
import 'dart:ui' as ui;
import 'package:meta/meta.dart';
import '../utils/utils.dart';

// import '../utils/utils.dart';

class PictureInfo {
  PictureInfo.picture(ui.Picture pic, ui.Size size)
      : _picture = PictureRef._(pic, size) {
    _picture.add(this);
  }
  PictureInfo(this._picture);
  final PictureRef _picture;

  void drawPicture(ui.Canvas canvas) {
    assert(!_picture._dispose);
    canvas.drawPicture(_picture.picture);
  }

  ui.Size get size {
    assert(!_picture._dispose);
    return _picture.size;
  }

  PictureInfo clone() {
    final _clone = PictureInfo(_picture);
    _picture.add(_clone);
    return _clone;
  }

  bool isCloneOf(PictureInfo info) {
    return _picture == info._picture;
  }

  bool get close => _picture._dispose;

  void dispose() {
    _picture.dispose(this);
  }
}

class PictureRef {
  PictureRef._(this.picture, this.size);
  final ui.Picture picture;
  final ui.Size size;
  final Set<PictureInfo> _list = <PictureInfo>{};

  void add(PictureInfo info) {
    assert(!_dispose);
    _list.add(info);
  }

  bool _dispose = false;
  void dispose(PictureInfo info) {
    assert(!_dispose);
    _list.remove(info);
    if (_list.isEmpty) {
      _dispose = true;
      picture.dispose();
    }
  }
}

typedef PictureListenerCallback = void Function(
    PictureInfo? image, bool error, bool sync);

class PictureStream {
  PictureStream({this.onRemove});
  PictureInfo? _image;
  bool _error = false;

  final void Function(PictureStream stream)? onRemove;

  /// 理论上监听者数量不会太多
  bool get defLoad => _list.any((element) {
        final def = element.load;
        return def != null && def();
      });

  bool _done = false;

  bool get done => _done;
  bool get success => _done && _image != null && !_error;

  void setPicture(PictureInfo? img, bool error) {
    assert(!_done);
    _done = true;
    final list = List.of(_list);
    // _list.clear();
    _error = error;

    list.forEach((listener) {
      final callback = listener.onDone;

      callback(img?.clone(), error, false);
    });

    if (_dispose) {
      img?.dispose();
      return;
    } else {
      assert(!schedule);
      _image = img;
      if (list.isEmpty && onRemove != null) onRemove!(this);
    }
  }

  final _list = <PictureListener>[];

  void addListener(PictureListener callback) {
    assert(!_dispose);
    // assert(Log.e('add: $hashCode'));
    _list.add(callback);

    if (!_done) return;

    callback.onDone(_image?.clone(), _error, true);
  }

  void removeListener(PictureListener callback) {
    _list.remove(callback);
    // assert(Log.e('remove: $hashCode'));

    if (!hasListener && !_dispose && onRemove != null && _done) {
      if (schedule) return;
      // assert(Log.w('_will dispose..  $hashCode'));
      scheduleMicrotask(() {
        schedule = false;
        // assert(Log.w('start... $hashCode'));
        if (!hasListener && !_dispose) {
          // assert(Log.w('end.... $hashCode'));
          onRemove!(this);
        }
      });
      schedule = true;
    }
  }

  @visibleForTesting
  bool schedule = false;

  bool get hasListener => _list.isNotEmpty;

  bool get close => _image?.close == true;
  bool get active => _image?.close != false;

  bool _dispose = false;

  void dispose() {
    if (_dispose) return;

    _dispose = true;
    _image?.dispose();
  }
}

class PictureListener {
  PictureListener(this.onDone, {this.load});
  final DeffLoad? load;
  final PictureListenerCallback onDone;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is PictureListener &&
            load == other.load &&
            onDone == other.onDone;
  }

  @override
  int get hashCode => ui.hashValues(load, onDone);
}
