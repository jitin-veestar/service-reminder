/// Stored subscription tier (payment integration can map to these later).
enum BillingPlan {
  /// No paid plan selected — includes a time-limited trial with full features.
  free,

  /// Paid tier: all app features except WhatsApp automation & PDF receipts.
  pro299,

  /// Full features including WhatsApp automation and PDF receipts.
  pro499,
}

extension BillingPlanX on BillingPlan {
  String get storageValue => switch (this) {
        BillingPlan.free => 'free',
        BillingPlan.pro299 => 'plan299',
        BillingPlan.pro499 => 'plan499',
      };

  static BillingPlan fromStorage(String? raw) {
    switch (raw) {
      case 'plan299':
        return BillingPlan.pro299;
      case 'plan499':
        return BillingPlan.pro499;
      default:
        return BillingPlan.free;
    }
  }

  String get title => switch (this) {
        BillingPlan.free => 'Free trial',
        BillingPlan.pro299 => 'Professional',
        BillingPlan.pro499 => 'Business',
      };

  String get priceLabel => switch (this) {
        BillingPlan.free => '₹0',
        BillingPlan.pro299 => '₹299/mo',
        BillingPlan.pro499 => '₹499/mo',
      };
}
