import 'package:flutter/material.dart';

import '../../../../core/theme/widgets/credit_bill_background.dart';
import '../../../../core/theme/widgets/credit_bill_primary_button.dart';
import '../../../../core/theme/credit_bill_theme.dart';
import '../../domain/entities/customer_entity.dart';

class CustomerDetailPage extends StatelessWidget {
  final CustomerEntity customer;

  const CustomerDetailPage({super.key, required this.customer});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(customer.name),
        backgroundColor: CreditBillColors.primaryBlue,
        foregroundColor: CreditBillColors.white,
      ),
      body: CreditBillBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Customer info card
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundColor: CreditBillColors.primaryBlue,
                            child: Text(
                              customer.name.isNotEmpty
                                  ? customer.name[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                color: CreditBillColors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  customer.name,
                                  style: CreditBillTextTheme.screenHeading
                                      .copyWith(fontSize: 20),
                                ),
                                Text(
                                  customer.phone,
                                  style: CreditBillTextTheme.inputLabel,
                                ),
                                if (customer.address != null &&
                                    customer.address!.isNotEmpty)
                                  Text(
                                    customer.address!,
                                    style: CreditBillTextTheme.inputLabel,
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Balance summary
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _BalanceRow(
                        label: 'Total Credit',
                        value: 'Rs. 0.00',
                        color: CreditBillColors.textDark,
                      ),
                      const Divider(),
                      _BalanceRow(
                        label: 'Total Paid',
                        value: 'Rs. 0.00',
                        color: CreditBillColors.successGreen,
                      ),
                      const Divider(),
                      _BalanceRow(
                        label: 'Outstanding',
                        value: 'Rs. 0.00',
                        color: CreditBillColors.errorRed,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Action buttons
              CreditBillPrimaryButton(
                text: 'Add Credit Bill',
                onPressed: () {
                  Navigator.of(context)
                      .pushNamed('/add-credit-bill', arguments: customer);
                },
              ),
              const SizedBox(height: 12),
              CreditBillPrimaryButton(
                text: 'Record Payment',
                color: CreditBillColors.successGreen,
                onPressed: () {
                  Navigator.of(context)
                      .pushNamed('/record-payment', arguments: customer);
                },
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () {
                  // Edit customer
                  Navigator.of(context)
                      .pushNamed('/edit-customer', arguments: customer);
                },
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Edit Customer'),
              ),
              const SizedBox(height: 24),
              // Transaction history placeholder
              Text(
                'Credit Transactions',
                style: CreditBillTextTheme.sectionLabel,
              ),
              const SizedBox(height: 8),
              Card(
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'No transactions yet',
                    style: CreditBillTextTheme.screenSubheading,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text('Payment History', style: CreditBillTextTheme.sectionLabel),
              const SizedBox(height: 8),
              Card(
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'No payments yet',
                    style: CreditBillTextTheme.screenSubheading,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BalanceRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _BalanceRow({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: CreditBillTextTheme.sectionLabel),
          Text(
            value,
            style: CreditBillTextTheme.sectionLabel.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
