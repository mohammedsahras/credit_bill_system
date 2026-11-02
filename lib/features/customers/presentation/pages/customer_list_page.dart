import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/widgets/credit_bill_background.dart';
import '../../../../core/theme/widgets/credit_bill_primary_button.dart';
import '../../../../core/theme/widgets/credit_bill_text_field.dart';
import '../../../../core/theme/credit_bill_theme.dart';
import '../../domain/entities/customer_entity.dart';
import '../bloc/customer_bloc.dart';
import 'add_customer_page.dart';

class CustomerListPage extends StatefulWidget {
  const CustomerListPage({super.key});

  @override
  State<CustomerListPage> createState() => _CustomerListPageState();
}

class _CustomerListPageState extends State<CustomerListPage> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<CustomerBloc>().add(LoadCustomersEvent());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CreditBillBackground(
        child: Column(
          children: [
            const SizedBox(height: 20),
            Text(
              'Customers',
              style: CreditBillTextTheme.screenHeading,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: CreditBillTextField(
                label: 'Search Customers',
                hint: 'Search by name or phone',
                controller: _searchController,
                suffixIcon: Icons.search,
                onChanged: (v) {
                  context.read<CustomerBloc>().add(SearchCustomersEvent(v));
                },
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: BlocBuilder<CustomerBloc, CustomerState>(
                builder: (context, state) {
                  if (state is CustomerLoadingState) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (state is CustomerErrorState) {
                    return Center(
                      child: Text(
                        state.message,
                        style: CreditBillTextTheme.errorText,
                      ),
                    );
                  }
                  if (state is CustomerLoadedState) {
                    if (state.customers.isEmpty) {
                      return Center(
                        child: Text(
                          'No customers found',
                          style: CreditBillTextTheme.screenSubheading,
                        ),
                      );
                    }
                    return ListView.builder(
                      itemCount: state.customers.length,
                      itemBuilder: (context, index) {
                        final customer = state.customers[index];
                        return _CustomerTile(customer: customer);
                      },
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: CreditBillPrimaryButton(
                text: 'Add New Customer',
                onPressed: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const AddCustomerPage()),
                  );
                  if (context.mounted) {
                    context.read<CustomerBloc>().add(LoadCustomersEvent());
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CustomerTile extends StatelessWidget {
  final CustomerEntity customer;

  const _CustomerTile({required this.customer});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: CreditBillColors.primaryBlue,
          child: Text(
            customer.name.isNotEmpty ? customer.name[0].toUpperCase() : '?',
            style: const TextStyle(
              color: CreditBillColors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(customer.name, style: CreditBillTextTheme.sectionLabel),
        subtitle: Text(customer.phone, style: CreditBillTextTheme.inputLabel),
        trailing: const Icon(
          Icons.chevron_right,
          color: CreditBillColors.secondaryText,
        ),
        onTap: () {
          Navigator.of(context)
              .pushNamed('/customer-detail', arguments: customer);
        },
      ),
    );
  }
}
