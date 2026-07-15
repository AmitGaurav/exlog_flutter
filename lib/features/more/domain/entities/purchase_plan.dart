/// The 3 purchasable plans, matching the Play Console product scheme
/// documented in PLAY_BILLING_SETUP.md: one subscription product
/// ("premium_subscription") with two base plans (monthly/yearly), and one
/// one-time managed product ("premium_lifetime").
enum PurchasePlan {
  monthly,
  yearly,
  lifetime;

  static const subscriptionProductId = 'premium_subscription';
  static const lifetimeProductId = 'premium_lifetime';

  /// The Play Console product ID to query/purchase for this plan.
  String get productId => switch (this) {
        PurchasePlan.monthly => subscriptionProductId,
        PurchasePlan.yearly => subscriptionProductId,
        PurchasePlan.lifetime => lifetimeProductId,
      };

  /// The base plan ID within [subscriptionProductId] — null for lifetime,
  /// which isn't a subscription.
  String? get basePlanId => switch (this) {
        PurchasePlan.monthly => 'monthly',
        PurchasePlan.yearly => 'yearly',
        PurchasePlan.lifetime => null,
      };

  bool get isSubscription => this != PurchasePlan.lifetime;

  String get displayName => switch (this) {
        PurchasePlan.monthly => 'Monthly',
        PurchasePlan.yearly => 'Yearly',
        PurchasePlan.lifetime => 'Lifetime',
      };
}

enum PurchaseResultStatus { pending, success, canceled, error }

class PurchaseResult {
  final PurchaseResultStatus status;
  final String? message;
  const PurchaseResult(this.status, [this.message]);
}
