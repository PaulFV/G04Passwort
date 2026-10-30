import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/responsive.dart';
import '../../../app/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/vault_item_type.dart';
import '../../../widgets/common.dart';
import '../../../widgets/g04_scaffold.dart';
import '../../../widgets/neon_button.dart';
import '../../vault/application/vault_providers.dart';
import '../../vault/presentation/item_detail_screen.dart' show formatBytes;

/// Dokumente (design screen 10): passports, licences, contracts with
/// encrypted file attachments.
class DocumentsScreen extends ConsumerWidget {
  const DocumentsScreen({super.key});

  static const _colors = {
    'Reisepass': AppColors.danger,
    'Führerschein': Color(0xFF7C5CFF),
    'Personalausweis': AppColors.neonBlue,
    'Vertrag': Color(0xFFFF8A3D),
    'Versicherung': AppColors.success,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final docs = ref.watch(itemsByTypeProvider(VaultItemType.document));
    return G04Scaffold(
      title: 'Dokumente',
      wide: true,
      body: Column(
        children: [
          Expanded(
            child: docs.isEmpty
                ? const EmptyState(
                    icon: Icons.description_rounded,
                    title: 'Keine Dokumente',
                    message:
                        'Reisepass, Führerschein, Verträge – Daten und PDFs verschlüsselt ablegen.',
                  )
                : ListView(
                    children: [
                      ResponsiveGrid(
                        minItemWidth: 340,
                        children: [
                      for (final d in docs)
                        GlassTile(
                          icon: Icons.picture_as_pdf_rounded,
                          iconColor:
                              _colors[d.document!.documentType] ??
                              const Color(0xFFFFC857),
                          title: d.title,
                          subtitle: [
                            if (d.document!.attachments.isNotEmpty)
                              d.document!.attachments.first.extension.isEmpty
                                  ? 'Datei'
                                  : d.document!.attachments.first.extension,
                            if (d.document!.totalSize > 0)
                              formatBytes(d.document!.totalSize),
                            if (d.document!.attachments.isEmpty)
                              d.document!.documentType,
                          ].join(' · '),
                          onTap: () => context.push(Routes.item(d.id)),
                        ),
                        ],
                      ),
                    ],
                  ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: NeonButton(
              label: 'Neues Dokument',
              icon: Icons.add_rounded,
              onPressed: () => context.push('${Routes.newItem}?type=document'),
            ),
          ),
        ],
      ),
    );
  }
}
