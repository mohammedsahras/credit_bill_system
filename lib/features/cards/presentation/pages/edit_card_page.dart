import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/card_entity.dart';
import '../bloc/card_bloc.dart';
import '../bloc/card_event.dart';
import '../bloc/card_state.dart';
import '../widgets/card_gradient_palette.dart';
import '../widgets/card_item_widget.dart';

class EditCardPage extends StatefulWidget {
  final CardEntity card;

  const EditCardPage({super.key, required this.card});

  @override
  State<EditCardPage> createState() => _EditCardPageState();
}

class _EditCardPageState extends State<EditCardPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _totalLimitController;
  late final TextEditingController _billingDayController;
  late final TextEditingController _dueDayController;
  late int _selectedGradientIdx;
  String? _themeError;

  @override
  void initState() {
    super.initState();
    _totalLimitController = TextEditingController(
      text: widget.card.totalLimit.toString(),
    );
    _billingDayController = TextEditingController(
      text: widget.card.billingDay.toString(),
    );
    _dueDayController = TextEditingController(
      text: widget.card.dueDay.toString(),
    );
    _selectedGradientIdx =
        widget.card.colorGradientIdx >= 0 &&
            widget.card.colorGradientIdx < CardGradientPalette.gradients.length
        ? widget.card.colorGradientIdx
        : -1;
  }

  @override
  void dispose() {
    _totalLimitController.dispose();
    _billingDayController.dispose();
    _dueDayController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedGradientIdx < 0 ||
        _selectedGradientIdx >= CardGradientPalette.gradients.length) {
      setState(() {
        _themeError = 'Select a valid card theme.';
      });
      return;
    }

    context.read<CardBloc>().add(
      UpdateCardEvent(
        CardEntity(
          id: widget.card.id,
          bankName: widget.card.bankName,
          nickname: widget.card.nickname,
          lastFour: widget.card.lastFour,
          network: widget.card.network,
          totalLimit: double.parse(_totalLimitController.text.trim()),
          billingDay: int.parse(_billingDayController.text.trim()),
          dueDay: int.parse(_dueDayController.text.trim()),
          colorGradientIdx: _selectedGradientIdx,
          isArchived: widget.card.isArchived,
          createdAt: widget.card.createdAt,
        ),
      ),
    );
  }

  CardEntity get _previewCard {
    final limit = double.tryParse(_totalLimitController.text.trim());
    final billingDay = int.tryParse(_billingDayController.text.trim());
    final dueDay = int.tryParse(_dueDayController.text.trim());
    return CardEntity(
      id: widget.card.id,
      bankName: widget.card.bankName,
      nickname: widget.card.nickname,
      lastFour: widget.card.lastFour,
      network: widget.card.network,
      totalLimit: limit != null && limit.isFinite ? limit : 0,
      billingDay: billingDay != null && billingDay >= 1 && billingDay <= 31
          ? billingDay
          : 1,
      dueDay: dueDay != null && dueDay >= 1 && dueDay <= 31 ? dueDay : 1,
      colorGradientIdx: _selectedGradientIdx,
      isArchived: widget.card.isArchived,
      createdAt: widget.card.createdAt,
    );
  }

  String? _validateDay(String? value) {
    if (value == null || value.trim().isEmpty) return 'Required.';
    final day = int.tryParse(value.trim());
    if (day == null || day < 1 || day > 31) {
      return 'Day must be between 1 and 31';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Card')),
      body: BlocConsumer<CardBloc, CardState>(
        listener: (context, state) {
          if (state is CardUpdatedSuccessState &&
              state.card.id == widget.card.id) {
            Navigator.of(context).pop(state.card);
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
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  CardItemWidget(
                    card: _previewCard,
                    faceKey: const Key('editCardPreview'),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    key: const Key('editTotalLimitField'),
                    controller: _totalLimitController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Total Credit Limit',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.currency_rupee),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Credit limit is required.';
                      }
                      final limit = double.tryParse(value.trim());
                      if (limit == null || !limit.isFinite || limit <= 0) {
                        return 'Credit limit must be greater than zero';
                      }
                      return null;
                    },
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          key: const Key('editBillingDayField'),
                          controller: _billingDayController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          decoration: const InputDecoration(
                            labelText: 'Statement Day',
                            border: OutlineInputBorder(),
                          ),
                          validator: _validateDay,
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          key: const Key('editDueDayField'),
                          controller: _dueDayController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          decoration: const InputDecoration(
                            labelText: 'Payment Due Day',
                            border: OutlineInputBorder(),
                          ),
                          validator: _validateDay,
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Card Theme / Gradient Color',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 2,
                    runSpacing: 8,
                    children: List.generate(
                      CardGradientPalette.gradients.length,
                      (index) {
                        final isSelected = _selectedGradientIdx == index;
                        final name = CardGradientPalette.themeNames[index];
                        return Semantics(
                          key: Key('editGradientOption_$index'),
                          selected: isSelected,
                          button: true,
                          child: Tooltip(
                            message: name,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(10),
                              onTap: () {
                                setState(() {
                                  _selectedGradientIdx = index;
                                  _themeError = null;
                                });
                              },
                              child: SizedBox(
                                width: 62,
                                child: Column(
                                  children: [
                                    Container(
                                      width: 50,
                                      height: 34,
                                      decoration: BoxDecoration(
                                        gradient: CardGradientPalette
                                            .gradients[index],
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: isSelected
                                              ? Colors.amber
                                              : Colors.grey.shade400,
                                          width: isSelected ? 3 : 1,
                                        ),
                                      ),
                                      child: isSelected
                                          ? const Icon(
                                              Icons.check,
                                              color: Colors.white,
                                              size: 18,
                                            )
                                          : null,
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      name,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: TextAlign.center,
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelSmall,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  if (_themeError != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        _themeError!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    key: const Key('saveCardChangesButton'),
                    onPressed: isLoading ? null : _submit,
                    child: isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Save Changes'),
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
