import 'dart:async';

import 'package:flutter/material.dart';

import '../../domain/entities/bill_entity.dart';
import '../../domain/usecases/bill_date_calculator.dart';

class BillCountdownBadge extends StatefulWidget {
  final BillEntity bill;
  final DateTime Function()? clock;

  const BillCountdownBadge({super.key, required this.bill, this.clock});

  @override
  State<BillCountdownBadge> createState() => _BillCountdownBadgeState();
}

class _BillCountdownBadgeState extends State<BillCountdownBadge> {
  Timer? _midnightTimer;
  final _calculator = const BillDateCalculator();

  @override
  void initState() {
    super.initState();
    _scheduleMidnightRefresh();
  }

  @override
  void didUpdateWidget(covariant BillCountdownBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.bill.dueDate != widget.bill.dueDate ||
        oldWidget.bill.status != widget.bill.status) {
      _scheduleMidnightRefresh();
    }
  }

  void _scheduleMidnightRefresh() {
    _midnightTimer?.cancel();
    final now = widget.clock?.call() ?? DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day + 1);
    _midnightTimer = Timer(midnight.difference(now), () {
      if (!mounted) return;
      setState(() {});
      _scheduleMidnightRefresh();
    });
  }

  @override
  void dispose() {
    _midnightTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    if (widget.bill.status == BillStatus.paid) {
      return _badge(context, 'Paid', Colors.green, Colors.white);
    }
    final days = _calculator.daysUntil(
      widget.bill.dueDate,
      widget.clock?.call() ?? DateTime.now(),
    );
    final Color background;
    final String label;
    if (days < 3) {
      background = colors.error;
      label = days < 0
          ? 'Overdue ${-days}d'
          : days == 0
          ? 'Due today'
          : 'Due in $days d';
    } else if (days <= 7) {
      background = Colors.amber.shade800;
      label = 'Due in $days d';
    } else {
      background = Colors.green.shade700;
      label = '$days days left';
    }
    return _badge(context, label, background, Colors.white);
  }

  Widget _badge(
    BuildContext context,
    String label,
    Color background,
    Color foreground,
  ) {
    return Semantics(
      label: 'Bill countdown: $label',
      child: Container(
        key: const Key('billCountdownBadge'),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelMedium
              ?.copyWith(color: foreground, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
