class Transaction {
  final String id;
  final String type;
  final double amount;
  final DateTime date;
  final String? orderId;
  final String? userId;

  Transaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.date,
    this.orderId,
    this.userId,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['_id'] ?? '',
      type: json['type'] ?? '',
      amount: json['amount']?.toDouble() ?? 0.0,
      date:
          json['date'] != null ? DateTime.parse(json['date']) : DateTime.now(),
      orderId: json['orderId'],
      userId: json['userId'],
    );
  }

  // Helper to determine if transaction is a credit or debit
  bool get isCredit => type == 'DEPOSIT' || (type == 'REFUND' && amount > 0);

  // For UI representation
  String get displayType => isCredit ? 'Credit' : 'Debit';

  // For getting user-friendly name
  String get customerName => userId ?? 'Unknown';

  // Format the date for display
  String get formattedDate {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
