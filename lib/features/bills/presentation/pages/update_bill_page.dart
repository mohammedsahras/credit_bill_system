import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../cards/domain/entities/card_entity.dart';
import '../../domain/entities/bill_entity.dart';
import '../../domain/usecases/bill_date_calculator.dart';
import '../bloc/bill_bloc.dart';
import '../bloc/bill_event.dart';
import '../bloc/bill_state.dart';

class UpdateBillPage extends StatefulWidget {
  final CardEntity card;
  final BillEntity? existingBill;

  const UpdateBillPage({super.key, required this.card, this.existingBill});

  @override
  State<UpdateBillPage> createState() => _UpdateBillPageState();
}

class _UpdateBillPageState extends State<UpdateBillPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _totalController;
  late final TextEditingController _minimumController;
  late DateTime _statementDate;
  late DateTime _dueDate;

  bool get _isSettled =>
      widget.existingBill != null &&
      widget.existingBill!.status != BillStatus.unpaid;

  @override
  void initState() {
    super.initState();
    final existing = widget.existingBill;
    final defaults = const BillDateCalculator().defaultsFor(
      widget.card,
      DateTime(DateTime.now().year, DateTime.now().month),
    );
    _statementDate = existing?.statementDate ?? defaults.statementDate;
    _dueDate = existing?.dueDate ?? defaults.dueDate;
    _totalController = TextEditingController(
      text: existing?.totalAmountDue.toStringAsFixed(2) ?? '',
    );
    _minimumController = TextEditingController(
      text: existing?.minimumAmountDue.toStringAsFixed(2) ?? '',
    );
  }

  @override
  void dispose() {
    _totalController.dispose();
    _minimumController.dispose();
    super.dispose();
  }

  Future<void> _selectDate({required bool statement}) async {
    final existing = widget.existingBill;
    final cycleParts = existing?.cycleMonth.split('-');
    final cycleStart = cycleParts == null
        ? null
        : DateTime(int.parse(cycleParts[0]), int.parse(cycleParts[1]));
    final firstDate = statement
        ? cycleStart ?? DateTime(2000)
        : DateTime(
            _statementDate.year,
            _statementDate.month,
            _statementDate.day,
          );
    final lastDate = statement && cycleStart != null
        ? DateTime(cycleStart.year, cycleStart.month + 1, 0)
        : DateTime.now().add(const Duration(days: 3650));
    final selected = await showDatePicker(
      context: context,
      initialDate: statement ? _statementDate : _dueDate,
      firstDate: firstDate,
      lastDate: lastDate,
    );
    if (selected == null || !mounted) return;
    setState(() {
      if (statement) {
        _statementDate = selected;
        _dueDate = const BillDateCalculator().dueDateAfterStatementChange(
          widget.card,
          _statementDate,
          _dueDate,
        );
      } else {
        _dueDate = selected;
      }
    });
  }

  String? _validateAmount(String? value, {required String label}) {
    final amount = double.tryParse(value?.trim() ?? '');
    if (amount == null || !amount.isFinite || amount < 0) {
      return 'Enter a valid non-negative $label.';
    }
    if (amount > 999999999999) return '$label is too large.';
    return null;
  }

  String? _validateMinimumAmount(String? value) {
    final validation = _validateAmount(value, label: 'minimum amount');
    if (validation != null) return validation;
    final minimum = double.parse(value!.trim());
    final total = double.tryParse(_totalController.text.trim());
    if (total != null && minimum > total) {
      return 'Minimum cannot exceed total amount due.';
    }
    return null;
  }

  void _submit() {
    if (_isSettled || !_formKey.currentState!.validate()) return;
    final total = double.parse(_totalController.text.trim());
    final minimum = double.parse(_minimumController.text.trim());
    if (_dueDate.isBefore(_statementDate)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Due date cannot precede statement date.'),
        ),
      );
      return;
    }
    context.read<BillBloc>().add(
      SaveBillEvent(
        cardId: widget.card.id,
        statementDate: _statementDate,
        dueDate: _dueDate,
        totalAmountDue: total,
        minimumAmountDue: minimum,
      ),
    );
  }

  String _dateLabel(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<BillBloc, BillState>(
      listener: (context, state) {
        if (state is BillSavedSuccessState &&
            state.bill.cardId == widget.card.id) {
          Navigator.of(context).pop(state.bill);
        } else if (state is BillErrorState) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      },
      builder: (context, state) {
        final saving = state is BillSavingState;
        return Scaffold(
          appBar: AppBar(
            title: Text(
              widget.existingBill == null ? 'Log Bill' : 'Update Bill',
            ),
          ),
          body: SafeArea(
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  Text(
                    '${widget.card.bankName} ${widget.card.nickname}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    key: const Key('totalAmountDueField'),
                    controller: _totalController,
                    enabled: !_isSettled && !saving,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'^\d*\.?\d{0,2}'),
                      ),
                    ],
                    decoration: const InputDecoration(
                      labelText: 'Total amount due',
                      prefixText: '₹ ',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) =>
                        _validateAmount(value, label: 'total amount'),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    key: const Key('minimumAmountDueField'),
                    controller: _minimumController,
                    enabled: !_isSettled && !saving,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'^\d*\.?\d{0,2}'),
                      ),
                    ],
                    decoration: const InputDecoration(
                      labelText: 'Minimum amount due',
                      prefixText: '₹ ',
                      border: OutlineInputBorder(),
                    ),
                    validator: _validateMinimumAmount,
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton(
                    key: const Key('statementDateField'),
                    onPressed: _isSettled || saving
                        ? null
                        : () => _selectDate(statement: true),
                    child: Text(
                      'Statement date: ${_dateLabel(_statementDate)}',
                    ),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    key: const Key('billDueDateField'),
                    onPressed: _isSettled || saving
                        ? null
                        : () => _selectDate(statement: false),
                    child: Text('Due date: ${_dateLabel(_dueDate)}'),
                  ),
                  if (_isSettled) ...[
                    const SizedBox(height: 16),
                    const Text(
                      'This bill has a recorded payment and cannot be edited.',
                      key: Key('settledBillEditRestriction'),
                    ),
                  ],
                  const SizedBox(height: 24),
                  FilledButton(
                    key: const Key('saveBillButton'),
                    onPressed: _isSettled || saving ? null : _submit,
                    child: saving
                        ? const CircularProgressIndicator()
                        : Text(
                            widget.existingBill == null
                                ? 'Save Bill'
                                : 'Update Bill',
                          ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
