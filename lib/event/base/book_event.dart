import 'dart:async';
import 'dart:typed_data';

import 'package:nop_db/nop_db.dart';

import '../../data/data.dart';
import '../../database/database.dart';
import '../../pages/book_list/cache_manager.dart';
import 'data.dart';
import 'server_event.dart';
import 'zhangdu_event.dart';

export 'data.dart';
export 'server_event.dart';

part 'book_event.g.dart';

@NopIsolateEvent()
@NopIsolateEventItem(connectToIsolate: ['database'])
abstract class BookEvent
    implements CustomEvent, DatabaseEvent, ComplexEvent, ZhangduEvent {
  BookCacheEvent get bookCacheEvent => this;
  BookContentEvent get bookContentEvent => this;
  CustomEvent get customEvent => this;
  DatabaseEvent get databaseEvent => this;
  ComplexEvent get complexEvent => this;
  ZhangduEvent get zhangduEvent => this;
}

abstract class BookContentEvent {
  Stream<List<BookContentDb>?> watchBookContentCid(int bookid);
  FutureOr<int?> deleteCache(int bookId);
}

abstract class BookCacheEvent {
  FutureOr<List<BookCache>?> getMainList();
  Stream<List<BookCache>?> watchMainList();

  FutureOr<int?> updateBook(int id, BookCache book);
  FutureOr<int?> insertBook(BookCache bookCache);
  FutureOr<int?> deleteBook(int id);

  Stream<List<BookCache>?> watchCurrentCid(int id);
  FutureOr<List<CacheItem>?> getCacheItems();
}

@NopIsolateEventItem(separate: true, isolateName: 'database')
abstract class DatabaseEvent
    with BookCacheEvent, BookContentEvent, ServerEvent {}

abstract class CustomEvent implements ServerNetEvent {
  FutureOr<SearchList?> getSearchData(String key);

  @NopIsolateMethod(useTransferType: true)
  FutureOr<Uint8List?> getImageBytes(String img);

  FutureOr<List<BookList>?> getHiveShudanLists(String c);

  FutureOr<List<BookList>?> getShudanLists(String c, int index);
  FutureOr<BookTopData?> getTopLists(String c, String date, int index);
  FutureOr<BookTopData?> getCategLists(int c, String date, int index);

  FutureOr<BookListDetailData?> getShudanDetail(int index);
  FutureOr<List<BookCategoryData>?> getCategoryData();
  FutureOr<int?> updateBookStatus(int id);
}
