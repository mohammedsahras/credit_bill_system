import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/theme/widgets/credit_bill_background.dart';
import '../../../../core/theme/widgets/credit_bill_primary_button.dart';
import '../../../../core/theme/widgets/credit_bill_text_field.dart';
import '../../../../core/theme/credit_bill_theme.dart';
import '../../domain/entities/customer_entity.dart';
import '../../domain/entities/payment_entity.dart';
import '../../domain/repositories/credit_transaction_repository.dart';
import '../../domain/repositories/payment_repository.dart';

// payment_allocation_entity imported when needed

class RecordPaymentPage extends StatefulWidget {
  final CustomerEntity? customer;
  final PaymentRepository? paymentRepository;
  final CreditTransactionRepository? creditTransactionRepository;

  const RecordPaymentPage({
    super.key,
    this.customer,
    this.paymentRepository,
    this.creditTransactionRepository,
  });

  @override
  State<RecordPaymentPage> createState() => _RecordPaymentPageState();
}

class _RecordPaymentPageState extends State<RecordPaymentPage> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  DateTime _paymentDate = DateTime.now();
  String _paymentType = 'partial';
  bool _isSaving = false;
  int _outstandingMinor = 0;

  @override
  void initState() {
    super.initState();
    _loadOutstanding();
  }

  Future<void> _loadOutstanding() async {
    final c = widget.customer;
    final txRepo = widget.creditTransactionRepository;
    final payRepo = widget.paymentRepository;
    if (c == null || txRepo == null || payRepo == null) {
      return;
    }
    final txRes = await txRepo.getTransactionsByCustomer(c.id);
    final paidRes = await payRepo.getCustomerTotalPaid(c.id);
    final txs = txRes.fold((_) => <dynamic>[], (v) => v);
    final totalCredit =
        txs.fold<int>(0, (sum, t) => sum + (t.amountMinor as int));
    final totalPaid = paidRes.fold((_) => 0, (v) => v);
    setState(() {
      _outstandingMinor = totalCredit - totalPaid;
    });
  }

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

  Future<void> _onSave() async {
    if (_isSaving) return;
    if (!_formKey.currentState!.validate()) return;
    if (widget.customer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a customer first.')),
      );
      return;
    }
    final repo = widget.paymentRepository;
    if (repo == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payment service unavailable.')),
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
    if (_outstandingMinor > 0 && amountMinor > _outstandingMinor) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Payment cannot exceed outstanding balance.'),
        ),
      );
      return;
    }
    setState(() => _isSaving = true);
    final payment = PaymentEntity(
      id: const Uuid().v4(),
      customerId: widget.customer!.id,
      amountMinor: amountMinor,
      paymentDate: _paymentDate,
      paymentType: _paymentType,
      createdAt: DateTime.now(),
    );
    final result = await repo.recordPayment(payment: payment, allocations: []);
    setState(() => _isSaving = false);
    result.fold(
      (failure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(failure.message)),
        );
      },
      (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment recorded successfully.'),
            backgroundColor: CreditBillColors.successGreen,
          ),
        );
        Navigator.of(context).pop();
      },
    );
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
                      'Outstanding: Rs. ${(_outstandingMinor / 100).toStringAsFixed(2)}',
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
                                        setState(() {
                                          _paymentType = 'full';
                                          _amountController.text =
                                              (_outstandingMinor / 100)
                                                  .toStringAsFixed(2);
                                        });
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
                          text: _isSaving ? 'Saving...' : 'Save & Exit',
                          onPressed: _isSaving ? null : _onSave,
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
