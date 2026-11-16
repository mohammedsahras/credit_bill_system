import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:credit_bill_system/core/theme/widgets/credit_bill_background.dart';
import 'package:credit_bill_system/core/theme/widgets/credit_bill_primary_button.dart';
import 'package:credit_bill_system/core/theme/credit_bill_theme.dart';
import 'package:credit_bill_system/features/customers/domain/entities/customer_entity.dart';
import 'package:credit_bill_system/features/customers/presentation/bloc/customer_detail_bloc.dart';

class CustomerDetailPage extends StatefulWidget {
  final CustomerEntity customer;
  const CustomerDetailPage({super.key, required this.customer});

  @override
  State<CustomerDetailPage> createState() => _CustomerDetailPageState();
}

class _CustomerDetailPageState extends State<CustomerDetailPage> {
  @override
  void initState() {
    super.initState();
    context
        .read<CustomerDetailBloc>()
        .add(LoadCustomerDetailEvent(widget.customer.id));
  }

  String _fmt(int minor) => 'Rs. ${(minor / 100).toStringAsFixed(2)}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.customer.name),
        backgroundColor: CreditBillColors.primaryBlue,
        foregroundColor: CreditBillColors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context
                .read<CustomerDetailBloc>()
                .add(LoadCustomerDetailEvent(widget.customer.id)),
          ),
        ],
      ),
      body: CreditBillBackground(
        child: BlocBuilder<CustomerDetailBloc, CustomerDetailState>(
          builder: (context, state) {
            if (state is CustomerDetailLoadingState ||
                state is CustomerDetailInitialState) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is CustomerDetailErrorState) {
              return Center(
                child: Text(state.message,
                    style: CreditBillTextTheme.errorText),
              );
            }
            final s = state as CustomerDetailLoadedState;
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(s.customer.name,
                              style: CreditBillTextTheme.screenHeading
                                  .copyWith(fontSize: 20)),
                          Text(s.customer.phone,
                              style: CreditBillTextTheme.inputLabel),
                          if (s.customer.address != null &&
                              s.customer.address!.isNotEmpty)
                            Text(s.customer.address!,
                                style: CreditBillTextTheme.inputLabel),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _BalanceRow(
                              label: 'Total Credit',
                              value: _fmt(s.totalCreditMinor),
                              color: CreditBillColors.textDark),
                          const Divider(),
                          _BalanceRow(
                              label: 'Total Paid',
                              value: _fmt(s.totalPaidMinor),
                              color: CreditBillColors.successGreen),
                          const Divider(),
                          _BalanceRow(
                              label: 'Outstanding',
                              value: _fmt(s.outstandingMinor),
                              color: CreditBillColors.errorRed),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  CreditBillPrimaryButton(
                    text: 'Add Credit Bill',
                    onPressed: () => Navigator.of(context)
                        .pushNamed('/add-credit-bill', arguments: s.customer),
                  ),
                  const SizedBox(height: 12),
                  CreditBillPrimaryButton(
                    text: 'Record Payment',
                    color: CreditBillColors.successGreen,
                    onPressed: () => Navigator.of(context)
                        .pushNamed('/record-payment', arguments: s.customer),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: () => Navigator.of(context)
                        .pushNamed('/edit-customer', arguments: s.customer),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Edit Customer'),
                  ),
                  const SizedBox(height: 24),
                  Text('Credit Transactions',
                      style: CreditBillTextTheme.sectionLabel),
                  const SizedBox(height: 8),
                  if (s.transactions.isEmpty)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text('No transactions yet',
                            style: CreditBillTextTheme.screenSubheading),
                      ),
                    )
                  else
                    ...s.transactions.map((t) => Card(
                          child: ListTile(
                            title: Text(_fmt(t.amountMinor)),
                            subtitle: Text(t.description ?? ''),
                            trailing: Text(t.dueDate.toIso8601String().substring(0, 10)),
                          ),
                        )),
                  const SizedBox(height: 16),
                  Text('Payment History',
                      style: CreditBillTextTheme.sectionLabel),
                  const SizedBox(height: 8),
                  if (s.payments.isEmpty)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text('No payments yet',
                            style: CreditBillTextTheme.screenSubheading),
                      ),
                    )
                  else
                    ...s.payments.map((p) => Card(
                          child: ListTile(
                            title: Text(_fmt(p.amountMinor)),
                            subtitle: Text(p.paymentType),
                            trailing: Text(p.paymentDate.toIso8601String().substring(0, 10)),
                          ),
                        )),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _BalanceRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _BalanceRow(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: CreditBillTextTheme.sectionLabel),
          Text(value,
              style: CreditBillTextTheme.sectionLabel.copyWith(
                  color: color, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}