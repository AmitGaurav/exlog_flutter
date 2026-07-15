import 'package:in_app_purchase/in_app_purchase.dart';

import '../entities/purchase_plan.dart';

abstract interface class PurchaseRepository {
  Future<bool> isAvailable();

  /// Queries Play Console for the current 3 products/base-plans. Entries
  /// missing from the returned map mean that plan isn't configured yet in
  /// Play Console (or the store is unreachable) — callers should fall back
  /// to static pricing display in that case.
  Future<Map<PurchasePlan, ProductDetails>> queryProducts();

  Future<void> buy(PurchasePlan plan, ProductDetails details);

  Future<void> restorePurchases();

  /// Emits once per purchase update after this repository has attempted
  /// server-side verification (see verifyPlayPurchase Cloud Function).
  Stream<PurchaseResult> get results;

  void dispose();
}
