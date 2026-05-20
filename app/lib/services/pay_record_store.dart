import 'package:flutter_riverpod/flutter_riverpod.dart';

class PayRecord {
  final String xianzhong;
  final String dangci;
  final String year;
  final String amount;
  final String target;
  final String? dailiName;
  final String status;
  final DateTime createdAt;
  final String flowId;

  const PayRecord({
    required this.xianzhong,
    required this.dangci,
    required this.year,
    required this.amount,
    required this.target,
    this.dailiName,
    required this.status,
    required this.createdAt,
    required this.flowId,
  });
}

class PayRecordsNotifier extends Notifier<List<PayRecord>> {
  @override
  List<PayRecord> build() => [];

  void add(PayRecord record) {
    state = [record, ...state];
  }
}

final payRecordsProvider =
    NotifierProvider<PayRecordsNotifier, List<PayRecord>>(
        PayRecordsNotifier.new);
