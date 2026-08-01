import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/glow_button.dart';
import '../domain/memory_item.dart';
import 'memory_providers.dart';

class MemoryScreen extends ConsumerStatefulWidget {
  const MemoryScreen({super.key});

  @override
  ConsumerState<MemoryScreen> createState() => _MemoryScreenState();
}

class _MemoryScreenState extends ConsumerState<MemoryScreen> {
  String _query = '';
  MemoryCategory? _filter;

  @override
  Widget build(BuildContext context) {
    ref.watch(memoriesProvider);
    final notifier = ref.read(memoriesProvider.notifier);
    final results = notifier.search(_query, category: _filter);
    final counts = notifier.categoryCounts;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: const Text('Memory')),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.black,
        onPressed: () => _showAddSheet(context),
        child: const Icon(Icons.add),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, 100),
        children: [
          GlassCard(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.psychology_rounded, color: AppColors.accent, size: 18),
                    const SizedBox(width: 8),
                    Text('Memory core', style: Theme.of(context).textTheme.titleMedium),
                    const Spacer(),
                    Text('${counts.values.fold(0, (a, b) => a + b)} total', style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                ...MemoryCategory.values.map((c) => _CategoryBar(category: c, count: counts[c] ?? 0, max: counts.values.fold(1, (a, b) => a > b ? a : b))),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            onChanged: (v) => setState(() => _query = v),
            decoration: const InputDecoration(prefixIcon: Icon(Icons.search, size: 18), hintText: 'Search memory…'),
            style: const TextStyle(color: Colors.white),
          ),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _FilterChip(label: 'All', selected: _filter == null, onTap: () => setState(() => _filter = null)),
                ...MemoryCategory.values.map(
                  (c) => Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: _FilterChip(label: c.label, selected: _filter == c, onTap: () => setState(() => _filter = c)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          if (results.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
              child: Center(child: Text('No memories found', style: Theme.of(context).textTheme.bodyMedium)),
            )
          else
            ...results.map((m) => _MemoryCard(item: m)),
        ],
      ),
    );
  }

  void _showAddSheet(BuildContext context) {
    final controller = TextEditingController();
    var category = MemoryCategory.general;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              left: AppSpacing.md,
              right: AppSpacing.md,
              bottom: MediaQuery.viewInsetsOf(context).bottom + AppSpacing.md,
              top: AppSpacing.md,
            ),
            child: GlassCard(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('New memory', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: AppSpacing.md),
                  TextField(controller: controller, maxLines: 3, decoration: const InputDecoration(hintText: 'What should JARVIS remember?'), style: const TextStyle(color: Colors.white)),
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: 8,
                    children: MemoryCategory.values
                        .map((c) => ChoiceChip(label: Text(c.label), selected: category == c, onSelected: (_) => setModalState(() => category = c)))
                        .toList(),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Align(
                    alignment: Alignment.centerRight,
                    child: GlowButton(
                      onPressed: () async {
                        if (controller.text.trim().isEmpty) return;
                        await ref.read(memoriesProvider.notifier).add(controller.text.trim(), category);
                        if (context.mounted) Navigator.pop(context);
                      },
                      child: const Text('Save'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CategoryBar extends StatelessWidget {
  const _CategoryBar({required this.category, required this.count, required this.max});
  final MemoryCategory category;
  final int count;
  final int max;

  @override
  Widget build(BuildContext context) {
    final fraction = max == 0 ? 0.0 : count / max;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(width: 74, child: Text(category.label, style: Theme.of(context).textTheme.bodySmall)),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: fraction,
                minHeight: 6,
                backgroundColor: AppColors.glassFillStrong,
                valueColor: const AlwaysStoppedAnimation(AppColors.accent),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text('$count', style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(label: Text(label), selected: selected, onSelected: (_) => onTap());
  }
}

class _MemoryCard extends ConsumerWidget {
  const _MemoryCard({required this.item});
  final MemoryItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: GlassCard(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.content, style: const TextStyle(color: AppColors.textPrimary, fontSize: 13.5, height: 1.4)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _Tag(text: item.category.label),
                      const SizedBox(width: 8),
                      Text(DateFormat.MMMd().format(item.createdAt), style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.textTertiary),
              onPressed: () => ref.read(memoriesProvider.notifier).delete(item.id),
            ),
          ],
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: AppColors.accent.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(AppRadius.pill)),
      child: Text(text, style: const TextStyle(color: AppColors.accent, fontSize: 10, fontWeight: FontWeight.w600)),
    );
  }
}
