import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/theme/widgets/credit_bill_background.dart';
import '../../../../core/theme/widgets/credit_bill_primary_button.dart';
import '../../../../core/theme/widgets/credit_bill_text_field.dart';
import '../../../../core/theme/credit_bill_theme.dart';
import '../../domain/entities/customer_entity.dart';
import '../bloc/customer_bloc.dart';

class AddCustomerPage extends StatefulWidget {
  const AddCustomerPage({super.key});

  @override
  State<AddCustomerPage> createState() => _AddCustomerPageState();
}

class _AddCustomerPageState extends State<AddCustomerPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _amountController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _onSave() {
    if (!_formKey.currentState!.validate()) return;
    final customer = CustomerEntity(
      id: const Uuid().v4(),
      name: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      address: _addressController.text.trim().isEmpty
          ? null
          : _addressController.text.trim(),
      createdAt: DateTime.now(),
    );
    context.read<CustomerBloc>().add(AddCustomerEvent(customer));
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<CustomerBloc, CustomerState>(
      listener: (context, state) {
        if (state is CustomerErrorState) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: CreditBillColors.errorRed,
            ),
          );
        } else if (state is CustomerSuccessState) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: CreditBillColors.successGreen,
            ),
          );
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
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
                    Text(
                      'Add New Customer',
                      style: CreditBillTextTheme.screenHeading,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Register a new customer for credit management',
                      style: CreditBillTextTheme.screenSubheading,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          CreditBillTextField(
                            label: 'Customer Name',
                            hint: 'Enter customer name',
                            controller: _nameController,
                            suffixIcon: Icons.person_outline,
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'Customer name is required.';
                              }
                              if (v.trim().length < 2) {
                                return 'Name must be at least 2 characters.';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 18),
                          CreditBillTextField(
                            label: 'Phone Number',
                            hint: 'Enter phone number',
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            suffixIcon: Icons.phone_outlined,
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'Phone number is required.';
                              }
                              if (!RegExp(r'^[0-9]{10,15}$')
                                  .hasMatch(v.trim())) {
                                return 'Enter a valid phone number (10-15 digits).';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 18),
                          CreditBillTextField(
                            label: 'Address (Optional)',
                            hint: 'Enter address',
                            controller: _addressController,
                            suffixIcon: Icons.location_on_outlined,
                          ),
                          const SizedBox(height: 26),
                          CreditBillPrimaryButton(
                            text: 'Save Customer',
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
      ),
    );
  }
}
