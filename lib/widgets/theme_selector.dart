import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/theme_provider.dart';

/// Theme selector widget for settings screen
class ThemeSelector extends ConsumerWidget {
  const ThemeSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTheme = ref.watch(themeNotifierProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            'Utseende',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            children: AppThemeMode.values.map((mode) {
              return RadioListTile<AppThemeMode>(
                title: Row(
                  children: [
                    Icon(mode.icon, size: 20),
                    const SizedBox(width: 12),
                    Text(mode.displayName),
                  ],
                ),
                subtitle: _getSubtitle(mode),
                value: mode,
                groupValue: currentTheme,
                onChanged: (value) {
                  if (value != null) {
                    ref
                        .read(themeNotifierProvider.notifier)
                        .setThemeMode(value);
                  }
                },
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget? _getSubtitle(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.light:
        return const Text('Alltid ljust tema');
      case AppThemeMode.dark:
        return const Text('Alltid mörkt tema');
      case AppThemeMode.system:
        return const Text('Följer telefonens inställning');
    }
  }
}

/// Alternative: Simple ListTile version (more compact)
class ThemeSelectorCompact extends ConsumerWidget {
  const ThemeSelectorCompact({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTheme = ref.watch(themeNotifierProvider);

    return ListTile(
      leading: Icon(currentTheme.icon),
      title: const Text('Tema'),
      subtitle: Text(currentTheme.displayName),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => _showThemeDialog(context, ref, currentTheme),
    );
  }

  void _showThemeDialog(
    BuildContext context,
    WidgetRef ref,
    AppThemeMode currentTheme,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Välj tema'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: AppThemeMode.values.map((mode) {
            return RadioListTile<AppThemeMode>(
              title: Row(
                children: [
                  Icon(mode.icon, size: 20),
                  const SizedBox(width: 12),
                  Text(mode.displayName),
                ],
              ),
              value: mode,
              groupValue: currentTheme,
              onChanged: (value) {
                if (value != null) {
                  ref.read(themeNotifierProvider.notifier).setThemeMode(value);
                  Navigator.pop(context);
                }
              },
            );
          }).toList(),
        ),
      ),
    );
  }
}

/// Alternative: Segmented button version (iOS style)
class ThemeSelectorSegmented extends ConsumerWidget {
  const ThemeSelectorSegmented({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTheme = ref.watch(themeNotifierProvider);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tema',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          SegmentedButton<AppThemeMode>(
            segments: AppThemeMode.values.map((mode) {
              return ButtonSegment<AppThemeMode>(
                value: mode,
                icon: Icon(mode.icon, size: 20),
                label: Text(mode.displayName),
              );
            }).toList(),
            selected: {currentTheme},
            onSelectionChanged: (Set<AppThemeMode> selection) {
              if (selection.isNotEmpty) {
                ref
                    .read(themeNotifierProvider.notifier)
                    .setThemeMode(selection.first);
              }
            },
            showSelectedIcon: false,
          ),
        ],
      ),
    );
  }
}
