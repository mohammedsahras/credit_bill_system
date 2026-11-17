import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:credit_bill_system/core/theme/credit_bill_theme.dart';
import 'package:credit_bill_system/core/theme/widgets/credit_bill_animated_entrance.dart';
import 'package:credit_bill_system/features/reports/presentation/bloc/reports_bloc.dart';

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  @override
  void initState() {
    super.initState();
    context.read<ReportsBloc>().add(LoadReportsEvent());
  }

  String _fmt(int minor) => 'Rs. ${(minor / 100).toStringAsFixed(2)}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports'),
        backgroundColor: CreditBillColors.primaryBlue,
        foregroundColor: CreditBillColors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () =>
                context.read<ReportsBloc>().add(LoadReportsEvent()),
          ),
        ],
      ),
      body: BlocBuilder<ReportsBloc, ReportsState>(
        builder: (context, state) {
          if (state is ReportsLoadingState || state is ReportsInitialState) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is ReportsErrorState) {
            return Center(
              child: Text(state.message,
                  style: CreditBillTextTheme.errorText),
            );
          }
          final s = state as ReportsLoadedState;
          final items = <(String, String)>[
            ('Total Customers', s.totalCustomers.toString()),
            ('Total Credit', _fmt(s.totalCreditMinor)),
            ('Total Payments', _fmt(s.totalPaidMinor)),
            ('Outstanding Balance', _fmt(s.outstandingMinor)),
            ('Total Transactions', s.totalTransactions.toString()),
          ];
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < items.length; i++)
                  CreditBillAnimatedEntrance(
                    index: i,
                    child: _card(items[i].$1, items[i].$2),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _card(String label, String value) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: CreditBillTextTheme.sectionLabel),
            Text(value,
                style: CreditBillTextTheme.sectionLabel.copyWith(
                    fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}