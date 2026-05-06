// lib/core/services/firestore_service.dart
// Firestore service for Golden Yolk - handles all Firestore operations

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../models/models.dart';

/// Firestore collections enum for type safety
enum FirestoreCollection {
  flocks,
  eggCollections,
  eggSales,
  expenses,
  feedPurchases,
  feedUsage,
  mortalityLogs,
  paymentHistory,
  settings,
}

/// Extension to get collection paths
extension FirestoreCollectionExtension on FirestoreCollection {
  String get path {
    switch (this) {
      case FirestoreCollection.flocks:
        return 'flocks';
      case FirestoreCollection.eggCollections:
        return 'egg_collections';
      case FirestoreCollection.eggSales:
        return 'egg_sales';
      case FirestoreCollection.expenses:
        return 'expenses';
      case FirestoreCollection.feedPurchases:
        return 'feed_purchases';
      case FirestoreCollection.feedUsage:
        return 'feed_usage';
      case FirestoreCollection.mortalityLogs:
        return 'mortality_logs';
      case FirestoreCollection.paymentHistory:
        return 'payment_history';
      case FirestoreCollection.settings:
        return 'settings';
    }
  }
}

/// Central Firestore service class
class FirestoreService {
  static final FirestoreService _instance = FirestoreService._internal();
  factory FirestoreService() => _instance;
  FirestoreService._internal();

  FirebaseFirestore? _db;
  bool _initialized = false;

  /// Initialize Firebase and Firestore
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      await Firebase.initializeApp();
      _db = FirebaseFirestore.instance;
      
      // Enable offline persistence for better performance
      await _db!.enablePersistence(const PersistenceSettings(synchronizeTabs: true));
      
      _initialized = true;
      print('Firebase initialized successfully');
    } catch (e) {
      print('Firebase initialization error: $e');
      rethrow;
    }
  }

  /// Check if Firebase is initialized
  bool get isInitialized => _initialized;

  /// Get Firestore instance
  FirebaseFirestore get db {
    if (!_initialized) {
      throw StateError('Firebase not initialized. Call initialize() first.');
    }
    return _db!;
  }

  // ==================== FLOCKS ====================

  /// Get all flocks stream (real-time)
  Stream<List<Flock>> getFlocksStream() {
    return db
        .collection(FirestoreCollection.flocks.path)
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Flock.fromFirestore(doc.data(), doc.id))
            .toList());
  }

  /// Get all flocks (one-time)
  Future<List<Flock>> getFlocks() async {
    final snapshot = await db
        .collection(FirestoreCollection.flocks.path)
        .orderBy('created_at', descending: true)
        .get();
    return snapshot.docs
        .map((doc) => Flock.fromFirestore(doc.data(), doc.id))
        .toList();
  }

  /// Add a new flock
  Future<String> addFlock(Flock flock) async {
    final docRef = await db.collection(FirestoreCollection.flocks.path).add(flock.toFirestore());
    return docRef.id;
  }

  /// Update a flock
  Future<void> updateFlock(Flock flock) async {
    if (flock.id == null) throw ArgumentError('Flock ID cannot be null');
    await db
        .collection(FirestoreCollection.flocks.path)
        .doc(flock.id.toString())
        .update(flock.toFirestore());
  }

  /// Delete a flock
  Future<void> deleteFlock(int id) async {
    await db.collection(FirestoreCollection.flocks.path).doc(id.toString()).delete();
  }

  // ==================== EGG SALES / ORDERS ====================

  /// Get all egg sales stream (real-time)
  Stream<List<EggSale>> getEggSalesStream() {
    return db
        .collection(FirestoreCollection.eggSales.path)
        .orderBy('order_date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => EggSale.fromFirestore(doc.data(), doc.id))
            .toList());
  }

  /// Get all egg sales (one-time)
  Future<List<EggSale>> getEggSales() async {
    final snapshot = await db
        .collection(FirestoreCollection.eggSales.path)
        .orderBy('order_date', descending: true)
        .get();
    return snapshot.docs
        .map((doc) => EggSale.fromFirestore(doc.data(), doc.id))
        .toList();
  }

  /// Add a new egg sale/order
  Future<String> addEggSale(EggSale sale) async {
    final docRef = await db.collection(FirestoreCollection.eggSales.path).add(sale.toFirestore());
    return docRef.id;
  }

  /// Update an egg sale/order
  Future<void> updateEggSale(EggSale sale) async {
    if (sale.id == null) throw ArgumentError('Sale ID cannot be null');
    await db
        .collection(FirestoreCollection.eggSales.path)
        .doc(sale.id.toString())
        .update(sale.toFirestore());
  }

  /// Delete an egg sale/order
  Future<void> deleteEggSale(int id) async {
    await db.collection(FirestoreCollection.eggSales.path).doc(id.toString()).delete();
  }

  // ==================== EGG COLLECTIONS ====================

  /// Get all egg collections stream (real-time)
  Stream<List<EggCollection>> getEggCollectionsStream() {
    return db
        .collection(FirestoreCollection.eggCollections.path)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => EggCollection.fromFirestore(doc.data(), doc.id))
            .toList());
  }

  /// Get all egg collections (one-time)
  Future<List<EggCollection>> getEggCollections() async {
    final snapshot = await db
        .collection(FirestoreCollection.eggCollections.path)
        .orderBy('date', descending: true)
        .get();
    return snapshot.docs
        .map((doc) => EggCollection.fromFirestore(doc.data(), doc.id))
        .toList();
  }

  /// Add a new egg collection
  Future<String> addEggCollection(EggCollection collection) async {
    final docRef = await db.collection(FirestoreCollection.eggCollections.path).add(collection.toFirestore());
    return docRef.id;
  }

  /// Update an egg collection
  Future<void> updateEggCollection(EggCollection collection) async {
    if (collection.id == null) throw ArgumentError('Collection ID cannot be null');
    await db
        .collection(FirestoreCollection.eggCollections.path)
        .doc(collection.id.toString())
        .update(collection.toFirestore());
  }

  /// Delete an egg collection
  Future<void> deleteEggCollection(int id) async {
    await db.collection(FirestoreCollection.eggCollections.path).doc(id.toString()).delete();
  }

  // ==================== EXPENSES ====================

  /// Get all expenses stream (real-time)
  Stream<List<Expense>> getExpensesStream() {
    return db
        .collection(FirestoreCollection.expenses.path)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Expense.fromFirestore(doc.data(), doc.id))
            .toList());
  }

  /// Get all expenses (one-time)
  Future<List<Expense>> getExpenses() async {
    final snapshot = await db
        .collection(FirestoreCollection.expenses.path)
        .orderBy('date', descending: true)
        .get();
    return snapshot.docs
        .map((doc) => Expense.fromFirestore(doc.data(), doc.id))
        .toList();
  }

  /// Add a new expense
  Future<String> addExpense(Expense expense) async {
    final docRef = await db.collection(FirestoreCollection.expenses.path).add(expense.toFirestore());
    return docRef.id;
  }

  /// Update an expense
  Future<void> updateExpense(Expense expense) async {
    if (expense.id == null) throw ArgumentError('Expense ID cannot be null');
    await db
        .collection(FirestoreCollection.expenses.path)
        .doc(expense.id.toString())
        .update(expense.toFirestore());
  }

  /// Delete an expense
  Future<void> deleteExpense(int id) async {
    await db.collection(FirestoreCollection.expenses.path).doc(id.toString()).delete();
  }

  // ==================== FEED PURCHASES ====================

  /// Get all feed purchases stream (real-time)
  Stream<List<FeedPurchase>> getFeedPurchasesStream() {
    return db
        .collection(FirestoreCollection.feedPurchases.path)
        .orderBy('purchase_date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => FeedPurchase.fromFirestore(doc.data(), doc.id))
            .toList());
  }

  /// Get all feed purchases (one-time)
  Future<List<FeedPurchase>> getFeedPurchases() async {
    final snapshot = await db
        .collection(FirestoreCollection.feedPurchases.path)
        .orderBy('purchase_date', descending: true)
        .get();
    return snapshot.docs
        .map((doc) => FeedPurchase.fromFirestore(doc.data(), doc.id))
        .toList();
  }

  /// Add a new feed purchase
  Future<String> addFeedPurchase(FeedPurchase purchase) async {
    final docRef = await db.collection(FirestoreCollection.feedPurchases.path).add(purchase.toFirestore());
    return docRef.id;
  }

  /// Update a feed purchase
  Future<void> updateFeedPurchase(FeedPurchase purchase) async {
    if (purchase.id == null) throw ArgumentError('Purchase ID cannot be null');
    await db
        .collection(FirestoreCollection.feedPurchases.path)
        .doc(purchase.id.toString())
        .update(purchase.toFirestore());
  }

  /// Delete a feed purchase
  Future<void> deleteFeedPurchase(int id) async {
    await db.collection(FirestoreCollection.feedPurchases.path).doc(id.toString()).delete();
  }

  // ==================== FEED USAGE ====================

  /// Get all feed usage stream (real-time)
  Stream<List<FeedUsage>> getFeedUsageStream() {
    return db
        .collection(FirestoreCollection.feedUsage.path)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => FeedUsage.fromFirestore(doc.data(), doc.id))
            .toList());
  }

  /// Get all feed usage (one-time)
  Future<List<FeedUsage>> getFeedUsage() async {
    final snapshot = await db
        .collection(FirestoreCollection.feedUsage.path)
        .orderBy('date', descending: true)
        .get();
    return snapshot.docs
        .map((doc) => FeedUsage.fromFirestore(doc.data(), doc.id))
        .toList();
  }

  /// Add a new feed usage record
  Future<String> addFeedUsage(FeedUsage usage) async {
    final docRef = await db.collection(FirestoreCollection.feedUsage.path).add(usage.toFirestore());
    return docRef.id;
  }

  /// Update a feed usage record
  Future<void> updateFeedUsage(FeedUsage usage) async {
    if (usage.id == null) throw ArgumentError('Usage ID cannot be null');
    await db
        .collection(FirestoreCollection.feedUsage.path)
        .doc(usage.id.toString())
        .update(usage.toFirestore());
  }

  /// Delete a feed usage record
  Future<void> deleteFeedUsage(int id) async {
    await db.collection(FirestoreCollection.feedUsage.path).doc(id.toString()).delete();
  }

  // ==================== MORTALITY LOGS ====================

  /// Get all mortality logs stream (real-time)
  Stream<List<MortalityLog>> getMortalityLogsStream() {
    return db
        .collection(FirestoreCollection.mortalityLogs.path)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MortalityLog.fromFirestore(doc.data(), doc.id))
            .toList());
  }

  /// Get all mortality logs (one-time)
  Future<List<MortalityLog>> getMortalityLogs() async {
    final snapshot = await db
        .collection(FirestoreCollection.mortalityLogs.path)
        .orderBy('date', descending: true)
        .get();
    return snapshot.docs
        .map((doc) => MortalityLog.fromFirestore(doc.data(), doc.id))
        .toList();
  }

  /// Add a new mortality log
  Future<String> addMortalityLog(MortalityLog log) async {
    final docRef = await db.collection(FirestoreCollection.mortalityLogs.path).add(log.toFirestore());
    return docRef.id;
  }

  /// Update a mortality log
  Future<void> updateMortalityLog(MortalityLog log) async {
    if (log.id == null) throw ArgumentError('Log ID cannot be null');
    await db
        .collection(FirestoreCollection.mortalityLogs.path)
        .doc(log.id.toString())
        .update(log.toFirestore());
  }

  /// Delete a mortality log
  Future<void> deleteMortalityLog(int id) async {
    await db.collection(FirestoreCollection.mortalityLogs.path).doc(id.toString()).delete();
  }

  // ==================== PAYMENT HISTORY ====================

  /// Get all payment history for an order
  Stream<List<PaymentHistory>> getPaymentHistoryStream(int orderId) {
    return db
        .collection(FirestoreCollection.paymentHistory.path)
        .where('order_id', isEqualTo: orderId)
        .orderBy('payment_date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PaymentHistory.fromFirestore(doc.data(), doc.id))
            .toList());
  }

  /// Add a payment record
  Future<String> addPayment(PaymentHistory payment) async {
    final docRef = await db.collection(FirestoreCollection.paymentHistory.path).add(payment.toFirestore());
    return docRef.id;
  }

  /// Delete a payment record
  Future<void> deletePayment(int id) async {
    await db.collection(FirestoreCollection.paymentHistory.path).doc(id.toString()).delete();
  }
}
