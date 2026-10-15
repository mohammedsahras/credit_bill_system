import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../features/bills/domain/entities/bill_entity.dart';
import '../../features/bills/presentation/bloc/bill_bloc.dart';
import '../../features/bills/presentation/bloc/bill_event.dart';
import '../../features/bills/presentation/bloc/bill_state.dart';
import '../../features/bills/presentation/pages/update_bill_page.dart';
import '../../features/bills/presentation/widgets/bill_countdown_badge.dart';
import '../../features/cards/domain/entities/card_entity.dart';
import '../../features/cards/presentation/pages/wallet_home_page.dart';

class WalletCompositionPage extends StatefulWidget {
  const WalletCompositionPage({super.key});

  @override
  State<WalletCompositionPage> createState() => _WalletCompositionPageState();
}

class _WalletCompositionPageState extends State<WalletCompositionPage> {
  @override
  void initState() {
    super.initState();
    context.read<BillBloc>().add(const LoadActiveBillsEvent());
  }

  Future<BillEntity?> _editBill(
    BuildContext context,
    CardEntity card,
    BillEntity? existingBill,
  ) {
    return Navigator.of(context).push<BillEntity>(
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: context.read<BillBloc>(),
          child: UpdateBillPage(card: card, existingBill: existingBill),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<BillBloc, BillState>(
      listener: (context, state) {
        if (state is BillLoadErrorState) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      },
      builder: (context, state) => WalletHomePage(
        bills: state.bills,
        billBadgeBuilder: (bill) => BillCountdownBadge(bill: bill),
        onEditBill: _editBill,
      ),
    );
  }
}
