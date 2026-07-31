import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Global, remotely-toggleable feature flag — currently just `freeForAll`.
///
/// While true, all premium-tier restrictions (Upgrade-to-Premium prompts,
/// free-tier limit banners) are hidden app-wide in favor of a "Buy me a
/// coffee" appeal; see BuyMeACoffeeSheet and its usages. Backed by the
/// Firestore doc `app_config/global` so an admin can flip it back from the
/// Admin Dashboard without shipping a new app release, and cached in
/// SharedPreferences so reads are instant and work offline.
class AppConfigService {
  static const _collection = 'app_config';
  static const _docId = 'global';
  static const _prefsKey = 'app_config_free_for_all';
  static const defaultFreeForAll = true;

  final FirebaseFirestore _firestore;
  final SharedPreferences _prefs;

  late final ValueNotifier<bool> freeForAll;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _sub;

  AppConfigService(this._firestore, this._prefs)
      : freeForAll = ValueNotifier<bool>(_prefs.getBool(_prefsKey) ?? defaultFreeForAll);

  DocumentReference<Map<String, dynamic>> get _doc => _firestore.collection(_collection).doc(_docId);

  /// Starts listening for live updates (e.g. an admin flipping the flag from
  /// another device); call once at app startup.
  void listen() {
    _sub ??= _doc.snapshots().listen((snap) {
      final value = snap.data()?['freeForAll'] as bool? ?? defaultFreeForAll;
      freeForAll.value = value;
      _prefs.setBool(_prefsKey, value);
    }, onError: (_) {});
  }

  Future<void> setFreeForAll(bool value) => _doc.set({'freeForAll': value}, SetOptions(merge: true));

  void dispose() => _sub?.cancel();
}
