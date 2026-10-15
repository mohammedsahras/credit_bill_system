import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../bills/domain/entities/bill_entity.dart';
import '../../domain/entities/card_entity.dart';
import '../bloc/card_bloc.dart';
import '../bloc/card_event.dart';
import '../bloc/card_state.dart';
import '../widgets/card_item_widget.dart';
import 'edit_card_page.dart';

class CardDetailPage extends StatefulWidget {
  final CardEntity card;
  final BillEntity? bill;
  final BillEntity? currentCycleBill;
  final Widget Function(BillEntity bill)? billBadgeBuilder;
  final Future<BillEntity?> Function(BillEntity? existingBill)? onEditBill;

  const CardDetailPage({
    super.key,
    required this.card,
    this.bill,
    this.currentCycleBill,
    this.billBadgeBuilder,
    this.onEditBill,
  });

  @override
  State<CardDetailPage> createState() => _CardDetailPageState();
}

class _CardDetailPageState extends State<CardDetailPage> {
  late CardEntity _card;
  BillEntity? _bill;
  BillEntity? _currentCycleBill;
  bool _isMutating = false;

  @override
  void initState() {
    super.initState();
    _card = widget.card;
    _bill = widget.bill;
    _currentCycleBill = widget.currentCycleBill;
  }

  Future<void> _editBill() async {
    final savedBill = await widget.onEditBill?.call(_currentCycleBill);
    if (savedBill != null && mounted) {
      setState(() {
        _currentCycleBill = savedBill;
        if (savedBill.status != BillStatus.paid) _bill = savedBill;
      });
    }
  }

  Future<void> _editCard() async {
    final updatedCard = await Navigator.of(context).push<CardEntity>(
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: context.read<CardBloc>(),
          child: EditCardPage(card: _card),
        ),
      ),
    );
    if (updatedCard != null && mounted) {
      setState(() {
        _card = updatedCard;
      });
    }
  }

  Future<void> _archiveCard() async {
    final shouldArchive = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Archive Card?'),
        content: Text(
          'Archive "${_card.nickname}" ending in ${_card.lastFour}? '
          'It will leave your active wallet and cannot be restored in this version. '
          'Its stored history will be preserved.',
        ),
        actions: [
          TextButton(
            key: const Key('cancelArchiveCard'),
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            key: const Key('confirmArchiveCard'),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Archive Card'),
          ),
        ],
      ),
    );
    if (shouldArchive == true && mounted) {
      setState(() {
        _isMutating = true;
      });
      context.read<CardBloc>().add(ArchiveCardEvent(_card.id));
    }
  }

  Future<void> _deleteCard() async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Card Permanently?'),
        content: Text(
          'Permanently delete ${_card.bankName} "${_card.nickname}" '
          'ending in ${_card.lastFour}? This cannot be undone.',
        ),
        actions: [
          TextButton(
            key: const Key('cancelDeleteCard'),
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            key: const Key('confirmDeleteCard'),
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: const Text('Delete Permanently'),
          ),
        ],
      ),
    );
    if (shouldDelete == true && mounted) {
      setState(() {
        _isMutating = true;
      });
      context.read<CardBloc>().add(DeleteCardEvent(_card.id));
    }
  }

  void _handleState(BuildContext context, CardState state) {
    if (state is CardUpdatedSuccessState && state.card.id == _card.id) {
      setState(() {
        _card = state.card;
        _isMutating = false;
      });
    } else if (state is CardArchivedSuccessState && state.cardId == _card.id) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('"${_card.nickname}" archived.')));
    } else if (state is CardDeletedSuccessState && state.cardId == _card.id) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('"${_card.nickname}" deleted.')));
    } else if (state is CardErrorState && _isMutating) {
      setState(() {
        _isMutating = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(state.message), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<CardBloc, CardState>(
      listener: _handleState,
      child: Scaffold(
        appBar: AppBar(title: const Text('Card Details')),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            children: [
              CardItemWidget(
                card: _card,
                height: 240,
                faceKey: const Key('cardDetailFace'),
                billBadge: _bill == null
                    ? null
                    : widget.billBadgeBuilder?.call(_bill!),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    FilledButton.icon(
                      key: const Key('logBillAction'),
                      onPressed: _isMutating || widget.onEditBill == null
                          ? null
                          : _editBill,
                      icon: const Icon(Icons.receipt_long),
                      label: Text(
                        _currentCycleBill == null
                            ? 'Log Current Cycle Bill'
                            : 'Update Current Cycle Bill',
                      ),
                    ),
                    const SizedBox(height: 8),
                    FilledButton.icon(
                      key: const Key('editCardAction'),
                      onPressed: _isMutating ? null : _editCard,
                      icon: const Icon(Icons.edit),
                      label: const Text('Edit Card'),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      key: const Key('archiveCardAction'),
                      onPressed: _isMutating ? null : _archiveCard,
                      icon: const Icon(Icons.archive_outlined),
                      label: const Text('Archive Card'),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      key: const Key('deleteCardAction'),
                      onPressed: _isMutating ? null : _deleteCard,
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('Delete Card'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
