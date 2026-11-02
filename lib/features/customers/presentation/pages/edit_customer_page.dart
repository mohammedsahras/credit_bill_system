import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/widgets/credit_bill_background.dart';
import '../../../../core/theme/widgets/credit_bill_primary_button.dart';
import '../../../../core/theme/widgets/credit_bill_text_field.dart';
import '../../../../core/theme/credit_bill_theme.dart';
import '../../domain/entities/customer_entity.dart';
import '../bloc/customer_bloc.dart';

class EditCustomerPage extends StatefulWidget {
  final CustomerEntity customer;

  const EditCustomerPage({super.key, required this.customer});

  @override
  State<EditCustomerPage> createState() => _EditCustomerPageState();
}

class _EditCustomerPageState extends State<EditCustomerPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _addressController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.customer.name);
    _phoneController = TextEditingController(text: widget.customer.phone);
    _addressController = TextEditingController(
      text: widget.customer.address ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _onSave() {
    if (!_formKey.currentState!.validate()) return;
    final updated = CustomerEntity(
      id: widget.customer.id,
      name: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      address: _addressController.text.trim().isEmpty
          ? null
          : _addressController.text.trim(),
      createdAt: widget.customer.createdAt,
      isActive: widget.customer.isActive,
    );
    context.read<CustomerBloc>().add(UpdateCustomerEvent(updated));
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
        appBar: AppBar(
          title: const Text('Edit Customer'),
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
                            text: 'Save Changes',
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
