import 'dart:collection';
import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:realm_dart/realm.dart';

part 'settings.g.dart';

@RealmModel()
class _Setting {
  @PrimaryKey()
  late final String key;
  late String value;
}

class _KeyIterator with IterableMixin<String> {
  final Realm _realm;

  _KeyIterator(this._realm);

  @override
  Iterator<String> get iterator => _realm.all<Setting>().map((e) => e.key).iterator;

  @override
  int get length => _realm.all<Setting>().length;

  @override
  bool contains(Object? element) {
    // I know, the interface of Map sucks ¯\_(ツ)_/¯ (see: https://github.com/dart-lang/sdk/issues/9893)
    if (element is! String) throw ArgumentError();
    return _realm.find(element) != null;
  }
}

class Settings with MapMixin<String, String> {
  final Realm _realm;

  Settings(Directory storageDirectory) : _realm = _initRealm(storageDirectory);

  static Realm _initRealm(Directory storageDirectory) {
    final filePath = path.join(storageDirectory.path, 'settings');
    return Realm(Configuration.local([Setting.schema], path: filePath));
  }

  @override
  String? operator [](Object? key) {
    // I know, the interface of Map sucks ¯\_(ツ)_/¯ (see: https://github.com/dart-lang/sdk/issues/9893)
    if (key is! String) throw ArgumentError();
    return _realm.find<Setting>(key)?.value;
  }

  @override
  void operator []=(String key, String value) {
    // While we wait for upserts to land
    _realm.write(() => (_realm.find<Setting>(key) ?? _realm.add(Setting(key, value))).value = value);
  }

  @override
  void clear() {
    _realm.write(() => _realm.deleteAll<Setting>());
  }

  @override
  Iterable<String> get keys => _KeyIterator(_realm);

  @override
  String? remove(Object? key) {
    // I know, the interface of Map sucks ¯\_(ツ)_/¯ (see: https://github.com/dart-lang/sdk/issues/9893)
    if (key is! String) throw ArgumentError();
    final found = _realm.find<Setting>(key);
    if (found != null) {
      _realm.write(() => _realm.delete(found));
    }
    return found?.value;
  }
}
