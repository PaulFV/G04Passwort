import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/routes.dart';
import '../../../core/extensions/context_x.dart';
import '../../../core/theme/app_colors.dart';
import '../../../widgets/app_text_field.dart';
import '../../../widgets/common.dart';
import '../../../widgets/g04_scaffold.dart';
import '../../../widgets/glass_card.dart';
import '../../../widgets/neon_button.dart';
import '../../settings/application/settings_controller.dart';
import '../../vault/application/vault_providers.dart';

/// Circular avatar with initials and neon ring.
class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({super.key, required this.name, this.size = 72});

  final String name;
  final double size;

  @override
  Widget build(BuildContext context) {
    final initials = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .take(2)
        .map((p) => p[0].toUpperCase())
        .join();
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [
            AppColors.neonBlueLight,
            AppColors.neonBlue,
            Color(0xFF0A2A6E),
          ],
        ),
        border: Border.all(color: AppColors.cyan, width: 2),
        boxShadow: const [
          BoxShadow(
            color: AppColors.neonBlue,
            blurRadius: 16,
            spreadRadius: -4,
          ),
        ],
      ),
      alignment: Alignment.center,
      child: initials.isEmpty
          ? Icon(Icons.person_rounded, color: Colors.white, size: size * 0.55)
          : Text(
              initials,
              style: TextStyle(
                color: Colors.white,
                fontSize: size * 0.36,
                fontWeight: FontWeight.w800,
              ),
            ),
    );
  }
}

/// Profil: local display name / e-mail (stored on the device only) and
/// vault statistics.
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  late final _name = TextEditingController(
    text: ref.read(settingsControllerProvider).displayName,
  );
  late final _email = TextEditingController(
    text: ref.read(settingsControllerProvider).email,
  );

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    await ref
        .read(settingsControllerProvider.notifier)
        .setProfile(name: _name.text, email: _email.text);
    if (mounted) context.showSnack('Profil gespeichert');
  }

  @override
  Widget build(BuildContext context) {
    final items = ref.watch(itemsProvider);
    final report = ref.watch(securityReportProvider);
    final settings = ref.watch(settingsControllerProvider);
    final fmt = DateFormat.yMMMd('de_DE');

    return G04Scaffold(
      title: 'Profil',
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          const SizedBox(height: 8),
          Center(child: ProfileAvatar(name: _name.text, size: 92)),
          const SizedBox(height: 18),
          GlassCard(
            child: Column(
              children: [
                AppTextField(
                  controller: _name,
                  label: 'Name',
                  icon: Icons.person_outline_rounded,
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 12),
                AppTextField(
                  controller: _email,
                  label: 'E-Mail',
                  icon: Icons.alternate_email_rounded,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 8),
                Text(
                  'Diese Angaben bleiben lokal auf deinem Gerät.',
                  style: context.text.bodySmall?.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          NeonButton(label: 'Speichern', onPressed: _save),
          const SectionHeader('Statistik'),
          GlassTile(
            icon: Icons.key_rounded,
            title: 'Einträge',
            value: '${items.length}',
          ),
          GlassTile(
            icon: Icons.shield_rounded,
            iconColor: AppColors.success,
            title: 'Sicherheits-Score',
            value: '${report.score}%',
          ),
          GlassTile(
            icon: Icons.backup_rounded,
            title: 'Letztes Backup',
            value: settings.lastBackupAt == null
                ? 'Nie'
                : fmt.format(settings.lastBackupAt!),
            onTap: () => context.push(Routes.backup),
          ),
          GlassTile(
            icon: Icons.password_rounded,
            title: 'Master-Passwort ändern',
            onTap: () => context.push(Routes.changeMasterPassword),
          ),
        ],
      ),
    );
  }
}
