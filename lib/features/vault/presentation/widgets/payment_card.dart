import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../models/vault_item.dart';

/// Neon credit card visual (number masked).
class PaymentCardView extends StatelessWidget {
  const PaymentCardView({super.key, required this.item});

  final VaultItem item;

  @override
  Widget build(BuildContext context) {
    final card = item.card!;
    final color = item.category.color;
    return AspectRatio(
      aspectRatio: 1.586,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color.lerp(AppColors.neonBlue, color, 0.4)!,
              const Color(0xFF0A1A44),
              const Color(0xFF050A1A),
            ],
          ),
          border: Border.all(color: AppColors.neonBlueLight.withValues(alpha: 0.7)),
          boxShadow: [BoxShadow(color: AppColors.neonBlue.withValues(alpha: 0.45), blurRadius: 26, spreadRadius: -6)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(item.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                const Spacer(),
                Text(
                  card.brand,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontStyle: FontStyle.italic,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
            const Spacer(),
            const Icon(Icons.memory_rounded, color: Color(0xFFFFD27A), size: 34),
            const SizedBox(height: 10),
            Text(
              card.digits.isEmpty ? '•••• •••• •••• ••••' : '•••• •••• •••• ${card.last4}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                letterSpacing: 2,
                fontFamily: 'monospace',
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Text(
                    card.holder.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white70, letterSpacing: 1),
                  ),
                ),
                Text(card.expiryLabel, style: const TextStyle(color: Colors.white70)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
