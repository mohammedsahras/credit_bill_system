import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/widgets/credit_bill_background.dart';
import '../../../../core/theme/credit_bill_theme.dart';
import '../bloc/customer_bloc.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  @override
  void initState() {
    super.initState();
    context.read<CustomerBloc>().add(LoadCustomersEvent());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        backgroundColor: CreditBillColors.primaryBlue,
        foregroundColor: CreditBillColors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              context.read<AuthBloc>().add(LogoutRequestedEvent());
            },
          ),
        ],
      ),
      body: CreditBillBackground(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome to Credit Bill',
                  style: CreditBillTextTheme.screenHeading,
                ),
                const SizedBox(height: 8),
                Text(
                  'Manage your customer credit efficiently',
                  style: CreditBillTextTheme.screenSubheading,
                ),
                const SizedBox(height: 24),
                // Quick Actions
                Text('Quick Actions', style: CreditBillTextTheme.sectionLabel),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _QuickActionCard(
                      icon: Icons.person_add,
                      label: 'Add Customer',
                      onTap: () =>
                          Navigator.of(context).pushNamed('/add-customer'),
                    ),
                    _QuickActionCard(
                      icon: Icons.receipt_long,
                      label: 'Add Credit Bill',
                      onTap: () =>
                          Navigator.of(context).pushNamed('/add-credit-bill'),
                    ),
                    _QuickActionCard(
                      icon: Icons.payment,
                      label: 'Record Payment',
                      onTap: () =>
                          Navigator.of(context).pushNamed('/record-payment'),
                    ),
                    _QuickActionCard(
                      icon: Icons.people,
                      label: 'View Customers',
                      onTap: () =>
                          Navigator.of(context).pushNamed('/customers'),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Customer count card
                BlocBuilder<CustomerBloc, CustomerState>(
                  builder: (context, state) {
                    if (state is CustomerLoadedState) {
                      return Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.people,
                                size: 40,
                                color: CreditBillColors.primaryBlue,
                              ),
                              const SizedBox(width: 16),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Total Customers',
                                    style: CreditBillTextTheme.inputLabel,
                                  ),
                                  Text(
                                    '${state.customers.length}',
                                    style: CreditBillTextTheme.screenHeading,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
                const SizedBox(height: 24),
                // Recent Customers
                Text(
                  'Recent Customers',
                  style: CreditBillTextTheme.sectionLabel,
                ),
                const SizedBox(height: 12),
                BlocBuilder<CustomerBloc, CustomerState>(
                  builder: (context, state) {
                    if (state is CustomerLoadedState) {
                      if (state.customers.isEmpty) {
                        return Center(
                          child: Text(
                            'No customers yet',
                            style: CreditBillTextTheme.screenSubheading,
                          ),
                        );
                      }
                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: state.customers.length > 5
                            ? 5
                            : state.customers.length,
                        itemBuilder: (context, index) {
                          final customer = state.customers[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            elevation: 1,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: CreditBillColors.primaryBlue,
                                child: Text(
                                  customer.name.isNotEmpty
                                      ? customer.name[0].toUpperCase()
                                      : '?',
                                  style: const TextStyle(
                                    color: CreditBillColors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              title: Text(
                                customer.name,
                                style: CreditBillTextTheme.sectionLabel,
                              ),
                              subtitle: Text(
                                customer.phone,
                                style: CreditBillTextTheme.inputLabel,
                              ),
                              trailing: const Icon(
                                Icons.chevron_right,
                                color: CreditBillColors.secondaryText,
                              ),
                              onTap: () {
                                Navigator.of(context).pushNamed(
                                  '/customer-detail',
                                  arguments: customer,
                                );
                              },
                            ),
                          );
                        },
                      );
                    }
                    return const Center(child: CircularProgressIndicator());
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 100,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: CreditBillColors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: CreditBillColors.deepBlue.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 32, color: CreditBillColors.primaryBlue),
            const SizedBox(height: 8),
            Text(
              label,
              style: CreditBillTextTheme.inputLabel,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
