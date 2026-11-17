import 'package:flutter/material.dart';

import '../../../../core/theme/credit_bill_colors.dart';
import '../../../../core/theme/credit_bill_theme.dart';
import '../../../../core/theme/widgets/credit_bill_animated_entrance.dart';
import '../../../../core/theme/widgets/credit_bill_background.dart';
import '../widgets/settings_section_header.dart';

/// Help & Support: an offline FAQ with expandable answers plus a short
/// statement of how the app handles data. Every answer describes shipped
/// behaviour — there is no contact form or link that could dead-end.
class HelpSupportPage extends StatelessWidget {
  const HelpSupportPage({super.key});

  static const List<({String question, String answer})> _faqs = [
    (
      question: 'How do I add a customer?',
      answer:
          'Open Customers from the dashboard (or the "Add Customer" quick '
          'action), fill in the name and phone number, and save. The customer '
          'appears in your list immediately and is stored on this device.',
    ),
    (
      question: 'How do statement bills work?',
      answer:
          'Use "Add Credit Bill" on a card to log its monthly statement with '
          'the statement date, due date and amounts. The card shows a '
          'countdown badge until the due date and a "Paid" badge once the '
          'bill is settled.',
    ),
    (
      question: 'How do I record a payment?',
      answer:
          'Open a customer (or use the "Record Payment" quick action), enter '
          'the amount and date, and choose whether it settles a bill fully or '
          'in part. Payments are allocated to outstanding transactions '
          'automatically and the balance updates right away.',
    ),
    (
      question: 'Where is my data stored?',
      answer:
          'Everything stays on this device in the app\'s local database. '
          'CreditBill makes no network requests: your customers, '
          'transactions, payments and profile are never uploaded anywhere.',
    ),
    (
      question: 'What happens if I forget my password?',
      answer:
          'Use "Forgot password" on the login screen. A recovery code lets '
          'you set a new password; the new password is stored only as a '
          'bcrypt hash, and your old one never is.',
    ),
    (
      question: 'How do I change my name, email or photo?',
      answer:
          'Go to Settings → Edit profile. Changing your email additionally '
          'asks for your current password to confirm it is you. The new '
          'values are saved to this device and shown right away.',
    ),
    (
      question: 'How do I switch between light and dark mode?',
      answer:
          'Open Settings → Theme & Appearance and choose System default, '
          'Light or Dark. The change applies to every screen immediately and '
          'is remembered for your next launch.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Help & Support'),
        backgroundColor: CreditBillColors.primaryBlue,
        foregroundColor: CreditBillColors.white,
      ),
      body: CreditBillBackground(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Answers to the most common questions about CreditBill.',
              style: CreditBillTextTheme.screenSubheading,
            ),
            const SizedBox(height: 16),
            const SettingsSectionHeader(title: 'Frequently asked questions'),
            for (var i = 0; i < _faqs.length; i++)
              CreditBillAnimatedEntrance(
                index: i < 8 ? i : 0,
                child: _FaqTile(
                  question: _faqs[i].question,
                  answer: _faqs[i].answer,
                ),
              ),
            const SizedBox(height: 8),
            const SettingsSectionHeader(title: 'About your data'),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: CreditBillColors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: CreditBillColors.deepBlue.withValues(alpha: 0.08),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Text(
                'CreditBill runs fully offline. Nothing you enter is sent '
                'over the internet, and clearing the app\'s data is the only '
                'way these records leave this device — keep your login '
                'password safe.',
                style: CreditBillTextTheme.inputLabel.copyWith(height: 1.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One expandable FAQ entry, styled to the CreditBill card language.
class _FaqTile extends StatelessWidget {
  final String question;
  final String answer;

  const _FaqTile({required this.question, required this.answer});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: CreditBillColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: CreditBillColors.deepBlue.withValues(alpha: 0.08),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
          iconColor: CreditBillColors.primaryBlue,
          collapsedIconColor: CreditBillColors.secondaryText,
          shape: const Border(),
          collapsedShape: const Border(),
          title: Text(question, style: CreditBillTextTheme.sectionLabel),
          children: [
            Text(
              answer,
              style: CreditBillTextTheme.inputLabel.copyWith(height: 1.55),
            ),
          ],
        ),
      ),
    );
  }
}
