import 'dart:async';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';

import '../../domain/entities/purchase_plan.dart';
import '../../domain/repositories/purchase_repository.dart';

class PurchaseRepositoryImpl implements PurchaseRepository {
  final InAppPurchase _iap;
  final FirebaseFunctions _functions;
  final _resultsController = StreamController<PurchaseResult>.broadcast();
  StreamSubscription<List<PurchaseDetails>>? _subscription;

  PurchaseRepositoryImpl({required InAppPurchase iap, required FirebaseFunctions functions})
      : _iap = iap,
        _functions = functions {
    _subscription = _iap.purchaseStream.listen(
      _onPurchaseUpdate,
      onError: (Object e) => _resultsController.add(PurchaseResult(PurchaseResultStatus.error, e.toString())),
    );
  }

  @override
  Stream<PurchaseResult> get results => _resultsController.stream;

  @override
  Future<bool> isAvailable() => _iap.isAvailable();

  @override
  Future<Map<PurchasePlan, ProductDetails>> queryProducts() async {
    final response = await _iap.queryProductDetails({
      PurchasePlan.subscriptionProductId,
      PurchasePlan.lifetimeProductId,
    });

    final map = <PurchasePlan, ProductDetails>{};
    for (final details in response.productDetails) {
      if (details.id == PurchasePlan.lifetimeProductId) {
        map[PurchasePlan.lifetime] = details;
        continue;
      }
      // Querying "premium_subscription" surfaces one GooglePlayProductDetails
      // per base plan — all share id == subscriptionProductId, so the base
      // plan itself is only distinguishable via subscriptionIndex.
      if (details is GooglePlayProductDetails && details.subscriptionIndex != null) {
        final offers = details.productDetails.subscriptionOfferDetails;
        final basePlanId = offers?[details.subscriptionIndex!].basePlanId;
        if (basePlanId == PurchasePlan.monthly.basePlanId) {
          map[PurchasePlan.monthly] = details;
        } else if (basePlanId == PurchasePlan.yearly.basePlanId) {
          map[PurchasePlan.yearly] = details;
        }
      }
    }
    return map;
  }

  @override
  Future<void> buy(PurchasePlan plan, ProductDetails details) async {
    final PurchaseParam param;
    if (details is GooglePlayProductDetails && details.offerToken != null) {
      param = GooglePlayPurchaseParam(productDetails: details, offerToken: details.offerToken);
    } else {
      param = PurchaseParam(productDetails: details);
    }
    await _iap.buyNonConsumable(purchaseParam: param);
  }

  @override
  Future<void> restorePurchases() => _iap.restorePurchases();

  Future<void> _onPurchaseUpdate(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      switch (purchase.status) {
        case PurchaseStatus.pending:
          _resultsController.add(const PurchaseResult(PurchaseResultStatus.pending));
        case PurchaseStatus.error:
          _resultsController.add(PurchaseResult(PurchaseResultStatus.error, purchase.error?.message));
          if (purchase.pendingCompletePurchase) await _iap.completePurchase(purchase);
        case PurchaseStatus.canceled:
          _resultsController.add(const PurchaseResult(PurchaseResultStatus.canceled));
          if (purchase.pendingCompletePurchase) await _iap.completePurchase(purchase);
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          await _verifyAndComplete(purchase);
      }
    }
  }

  Future<void> _verifyAndComplete(PurchaseDetails purchase) async {
    try {
      final isSubscription = purchase.productID == PurchasePlan.subscriptionProductId;
      final callable = _functions.httpsCallable('verifyPlayPurchase');
      await callable.call<Map<String, dynamic>>(<String, dynamic>{
        'purchaseToken': purchase.verificationData.serverVerificationData,
        'isSubscription': isSubscription,
        if (!isSubscription) 'productId': purchase.productID,
      });
      // Only mark the purchase complete once the server has verified +
      // written premiumTier — if verification throws, we deliberately don't
      // complete it below, so Play redelivers this purchase on next launch
      // and verification gets a natural retry.
      if (purchase.pendingCompletePurchase) await _iap.completePurchase(purchase);
      _resultsController.add(const PurchaseResult(PurchaseResultStatus.success));
    } catch (e) {
      _resultsController.add(PurchaseResult(PurchaseResultStatus.error, e.toString()));
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _resultsController.close();
  }
}
