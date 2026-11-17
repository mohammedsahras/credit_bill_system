import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../../core/theme/credit_bill_colors.dart';
import '../../../../core/theme/credit_bill_theme.dart';

/// Settings profile header: avatar (photo or initials fallback), name,
/// email and phone — or an "Add phone" hint when no number is stored yet.
/// Tapping it opens the profile editor.
class ProfileHeader extends StatelessWidget {
  final String name;
  final String? email;
  final String? phone;
  final String? photo;
  final VoidCallback? onTap;

  const ProfileHeader({
    super.key,
    required this.name,
    this.email,
    this.phone,
    this.photo,
    this.onTap,
  });

  /// Up to two uppercase initials, e.g. "Ada Lovelace" -> "AL".
  static String initialsOf(String name) {
    final parts =
        name.trim().split(RegExp(r'\s+')).where((part) => part.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final hasPhone = phone != null && phone!.trim().isNotEmpty;

    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: CreditBillColors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: CreditBillColors.deepBlue.withValues(alpha: 0.12),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              ProfileAvatar(name: name, photo: photo),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: CreditBillTextTheme.sectionLabel.copyWith(
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 2),
                    if (email != null && email!.isNotEmpty)
                      Text(
                        email!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: CreditBillTextTheme.inputLabel,
                      ),
                    const SizedBox(height: 4),
                    if (hasPhone)
                      Row(
                        children: [
                          const Icon(
                            Icons.phone_outlined,
                            size: 14,
                            color: CreditBillColors.secondaryText,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              phone!.trim(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: CreditBillTextTheme.inputLabel.copyWith(
                                color: CreditBillColors.textDark,
                              ),
                            ),
                          ),
                        ],
                      )
                    else
                      Row(
                        children: [
                          const Icon(
                            Icons.add_circle_outline,
                            size: 14,
                            color: CreditBillColors.primaryBlue,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              'Add phone',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: CreditBillTextTheme.linkText.copyWith(
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: CreditBillColors.secondaryText,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ProfileAvatar extends StatelessWidget {
  final String name;
  final String? photo;
  final double size;

  const ProfileAvatar({
    super.key,
    required this.name,
    this.photo,
    this.size = 56,
  });

  @override
  Widget build(BuildContext context) {
    Uint8List? bytes;
    final encoded = photo?.trim();
    if (encoded != null && encoded.isNotEmpty) {
      try {
        bytes = base64Decode(encoded);
      } catch (_) {
        bytes = null; // Corrupt payload -> initials fallback below.
      }
    }

    final fallback = Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: CreditBillColors.primaryBlue,
        shape: BoxShape.circle,
      ),
      child: Text(
        ProfileHeader.initialsOf(name),
        style: TextStyle(
          color: CreditBillColors.white,
          fontSize: size * 0.34,
          fontWeight: FontWeight.w700,
        ),
      ),
    );

    if (bytes == null) return fallback;

    return ClipOval(
      child: SizedBox(
        width: size,
        height: size,
        child: Image.memory(
          bytes,
          fit: BoxFit.cover,
          // A corrupt/undecodable image falls back to the initials avatar.
          errorBuilder: (_, _, _) => fallback,
        ),
      ),
    );
  }
}
