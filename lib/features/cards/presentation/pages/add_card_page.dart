import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/card_entity.dart';
import '../bloc/card_bloc.dart';
import '../bloc/card_event.dart';
import '../bloc/card_state.dart';
import '../widgets/card_gradient_palette.dart';

class AddCardPage extends StatefulWidget {
  const AddCardPage({super.key});

  @override
  State<AddCardPage> createState() => _AddCardPageState();
}

class _AddCardPageState extends State<AddCardPage> {
  final _formKey = GlobalKey<FormState>();

  final _bankNameController = TextEditingController();
  final _nicknameController = TextEditingController();
  final _lastFourController = TextEditingController();
  final _totalLimitController = TextEditingController();
  final _billingDayController = TextEditingController();
  final _dueDayController = TextEditingController();

  String _selectedNetwork = 'Visa';
  int _selectedGradientIdx = 0;

  final List<String> _networks = [
    'Visa',
    'Mastercard',
    'American Express',
    'RuPay',
    'Discover',
    'Diners Club',
  ];

  @override
  void dispose() {
    _bankNameController.dispose();
    _nicknameController.dispose();
    _lastFourController.dispose();
    _totalLimitController.dispose();
    _billingDayController.dispose();
    _dueDayController.dispose();
    super.dispose();
  }

  void _submitForm() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final card = CardEntity(
      id: const Uuid().v4(),
      bankName: _bankNameController.text.trim(),
      nickname: _nicknameController.text.trim(),
      lastFour: _lastFourController.text.trim(),
      network: _selectedNetwork,
      totalLimit: double.parse(_totalLimitController.text.trim()),
      billingDay: int.parse(_billingDayController.text.trim()),
      dueDay: int.parse(_dueDayController.text.trim()),
      colorGradientIdx: _selectedGradientIdx,
      isArchived: false,
      createdAt: DateTime.now().toUtc(),
    );

    context.read<CardBloc>().add(AddCardEvent(card));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Credit Card')),
      body: BlocConsumer<CardBloc, CardState>(
        listener: (context, state) {
          if (state is CardAddedSuccessState) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Card "${state.card.nickname}" added successfully!',
                ),
              ),
            );
            Navigator.of(context).pop();
          } else if (state is CardErrorState) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          final isLoading = state is CardLoadingState;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    key: const Key('bankNameField'),
                    controller: _bankNameController,
                    decoration: const InputDecoration(
                      labelText: 'Issuing Bank Name',
                      hintText: 'e.g. HDFC, Chase, ICICI, Citi',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.account_balance),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Bank name cannot be empty.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    key: const Key('nicknameField'),
                    controller: _nicknameController,
                    decoration: const InputDecoration(
                      labelText: 'Card Nickname',
                      hintText: 'e.g. Daily Rewards, Millennia, Amazon Pay',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.credit_card),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Card nickname cannot be empty.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    key: const Key('lastFourField'),
                    controller: _lastFourController,
                    decoration: const InputDecoration(
                      labelText: 'Last 4 Digits Only',
                      hintText: 'e.g. 4821',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.pin),
                      helperText: 'For your security, never enter full card number or CVV.',
                    ),
                    keyboardType: TextInputType.number,
                    maxLength: 4,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(4),
                    ],
                    validator: (value) {
                      if (value == null || value.trim().length != 4) {
                        return 'Must be exactly 4 digits';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    key: const Key('networkDropdown'),
                    initialValue: _selectedNetwork,
                    decoration: const InputDecoration(
                      labelText: 'Card Network',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.credit_score),
                    ),
                    items: _networks.map((network) {
                      return DropdownMenuItem(
                        value: network,
                        child: Text(network),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedNetwork = value;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    key: const Key('totalLimitField'),
                    controller: _totalLimitController,
                    decoration: const InputDecoration(
                      labelText: 'Total Credit Limit',
                      hintText: 'e.g. 150000',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.currency_rupee),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Credit limit is required.';
                      }
                      final parsed = double.tryParse(value.trim());
                      if (parsed == null || !parsed.isFinite || parsed <= 0) {
                        return 'Credit limit must be greater than zero';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          key: const Key('billingDayField'),
                          controller: _billingDayController,
                          decoration: const InputDecoration(
                            labelText: 'Statement Day',
                            hintText: '1 - 31',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.date_range),
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Required.';
                            }
                            final day = int.tryParse(value.trim());
                            if (day == null || day < 1 || day > 31) {
                              return 'Day must be between 1 and 31';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          key: const Key('dueDayField'),
                          controller: _dueDayController,
                          decoration: const InputDecoration(
                            labelText: 'Payment Due Day',
                            hintText: '1 - 31',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.event_available),
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Required.';
                            }
                            final day = int.tryParse(value.trim());
                            if (day == null || day < 1 || day > 31) {
                              return 'Day must be between 1 and 31';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Card Theme / Gradient Color',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 50,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: CardGradientPalette.gradients.length,
                      itemBuilder: (context, index) {
                        final isSelected = _selectedGradientIdx == index;
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedGradientIdx = index;
                            });
                          },
                          child: Container(
                            width: 60,
                            margin: const EdgeInsets.only(right: 12),
                            decoration: BoxDecoration(
                              gradient: CardGradientPalette.gradients[index],
                              borderRadius: BorderRadius.circular(10),
                              border: isSelected
                                  ? Border.all(color: Colors.amber, width: 3)
                                  : Border.all(
                                      color: Colors.grey.shade400,
                                      width: 1,
                                    ),
                            ),
                            child: isSelected
                                ? const Icon(Icons.check, color: Colors.white)
                                : null,
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 28),
                  ElevatedButton(
                    key: const Key('saveCardButton'),
                    onPressed: isLoading ? null : _submitForm,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text(
                            'Save Card to Wallet',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
