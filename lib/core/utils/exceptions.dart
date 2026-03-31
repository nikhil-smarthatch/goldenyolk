// Custom exceptions for inventory and sales management.
//
// Provides domain-specific exceptions for:
// - InsufficientInventoryException: When attempting to sell more eggs than available
// - OrderCancellationException: When cancellation fails due to order status
// - InvalidOrderStatusException: When an operation is invalid for the current status

/// Exception thrown when attempting to sell more eggs than available inventory.
class InsufficientInventoryException implements Exception {
  final int requested;
  final int available;
  final String? message;

  InsufficientInventoryException({
    required this.requested,
    required this.available,
    this.message,
  });

  @override
  String toString() {
    final msg = message ?? 'Insufficient inventory';
    return '$msg: requested $requested, available $available';
  }
}

class OrderCancellationException implements Exception {
  final String message;
  final int? orderId;

  OrderCancellationException({
    required this.message,
    this.orderId,
  });

  @override
  String toString() => 'Order Cancellation Error: $message';
}

class InvalidOrderStatusException implements Exception {
  final String currentStatus;
  final String attemptedAction;
  final String? message;

  InvalidOrderStatusException({
    required this.currentStatus,
    required this.attemptedAction,
    this.message,
  });

  @override
  String toString() {
    final msg = message ?? 'Invalid operation';
    return '$msg: Cannot $attemptedAction on $currentStatus order';
  }
}
