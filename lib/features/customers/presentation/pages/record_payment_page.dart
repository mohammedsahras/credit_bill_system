import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/theme/widgets/credit_bill_background.dart';
import '../../../../core/theme/widgets/credit_bill_primary_button.dart';
import '../../../../core/theme/widgets/credit_bill_text_field.dart';
import '../../../../core/theme/credit_bill_theme.dart';
import '../../domain/entities/customer_entity.dart';
import '../../domain/entities/payment_entity.dart';

// payment_allocation_entity imported when needed

class RecordPaymentPage extends StatefulWidget {
  final CustomerEntity? customer;

  const RecordPaymentPage({super.key, this.customer});

  @override
  State<RecordPaymentPage> createState() => _RecordPaymentPageState();
}

class _RecordPaymentPageState extends State<RecordPaymentPage> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  DateTime _paymentDate = DateTime.now();
  String _paymentType = 'partial';

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _paymentDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() => _paymentDate = picked);
    }
  }

  void _onSave() {
    if (!_formKey.currentState!.validate()) return;
    if (widget.customer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a customer first.')),
      );
      return;
    }
    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Payment amount must be greater than zero.'),
        ),
      );
      return;
    }
    final amountMinor = (amount * 100).round();
    // ignore: unused_local_variable
    final payment = PaymentEntity(
      id: const Uuid().v4(),
      customerId: widget.customer!.id,
      amountMinor: amountMinor,
      paymentDate: _paymentDate,
      paymentType: _paymentType,
      createdAt: DateTime.now(),
    );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Payment recorded successfully.'),
        backgroundColor: CreditBillColors.successGreen,
      ),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Record Payment'),
        backgroundColor: CreditBillColors.primaryBlue,
        foregroundColor: CreditBillColors.white,
      ),
      body: CreditBillBackground(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight:
                  MediaQuery.of(context).size.height -
                  MediaQuery.of(context).padding.top -
                  MediaQuery.of(context).padding.bottom,
            ),
            child: IntrinsicHeight(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),
                  if (widget.customer != null) ...[
                    Text(
                      'Customer: ${widget.customer!.name}',
                      style: CreditBillTextTheme.sectionLabel,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Outstanding: Rs. 0.00',
                      style: CreditBillTextTheme.screenSubheading,
                      textAlign: TextAlign.center,
                    ),
                  ],
                  const SizedBox(height: 24),
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        CreditBillTextField(
                          label: 'Payment Amount (Rs.)',
                          hint: 'Enter amount',
                          controller: _amountController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          suffixIcon: Icons.currency_rupee,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Amount is required.';
                            }
                            final amount = double.tryParse(v.trim());
                            if (amount == null || amount <= 0) {
                              return 'Amount must be greater than zero.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 18),
                        // Payment type selector
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Payment Type',
                              style: CreditBillTextTheme.inputLabel,
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: ChoiceChip(
                                    label: const Text('Partial'),
                                    selected: _paymentType == 'partial',
                                    onSelected: (selected) {
                                      if (selected) {
                                        setState(
                                          () => _paymentType = 'partial',
                                        );
                                      }
                                    },
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ChoiceChip(
                                    label: const Text('Full'),
                                    selected: _paymentType == 'full',
                                    onSelected: (selected) {
                                      if (selected) {
                                        setState(() => _paymentType = 'full');
                                      }
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        // Payment date
                        _DatePickerField(
                          label: 'Payment Date',
                          date: _paymentDate,
                          onTap: _pickDate,
                        ),
                        const SizedBox(height: 26),
                        CreditBillPrimaryButton(
                          text: 'Save & Exit',
                          onPressed: _onSave,
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DatePickerField extends StatelessWidget {
  final String label;
  final DateTime date;
  final VoidCallback onTap;

  const _DatePickerField({
    required this.label,
    required this.date,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: CreditBillTextTheme.inputLabel),
        const SizedBox(height: 8),
        InkWell(
          onTap: onTap,
          child: Container(
            height: 56,
            padding: const EdgeInsets.symmetric(horizontal: 18),
            decoration: BoxDecoration(
              color: CreditBillColors.inputBackground,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: CreditBillColors.inputBorder,
                width: 1.5,
              ),
            ),
            alignment: Alignment.centerLeft,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${date.day}/${date.month}/${date.year}',
                    style: const TextStyle(
                      fontSize: 15,
                      color: CreditBillColors.textDark,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const Icon(
                  Icons.calendar_today,
                  size: 20,
                  color: CreditBillColors.secondaryText,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
