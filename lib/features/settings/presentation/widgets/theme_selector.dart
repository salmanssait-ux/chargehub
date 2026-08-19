import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/theme_provider.dart';

class ThemeSelector extends ConsumerWidget {
  const ThemeSelector({
    super.key,
  });

  static void show(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) {
        return const ThemeSelector();
      },
    );
  }

  @override
  Widget build(
    BuildContext context,
    WidgetRef ref,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    final selectedTheme = ref.watch(themeProvider);

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(26),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(
        20,
        12,
        20,
        28,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.outline,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Themes',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              'Choose your ChargeHub style',
              style: TextStyle(
                fontSize: 13,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 18),
            RadioGroup<ChargeHubTheme>(
              groupValue: selectedTheme,
              onChanged: (theme) {
                if (theme != null) {
                  ref.read(themeProvider.notifier).setTheme(theme);
                }
              },
              child: Column(
                children: ChargeHubTheme.values.map(
                  (theme) {
                    final selected = selectedTheme == theme;

                    return _ThemeOption(
                      theme: theme,
                      selected: selected,
                    );
                  },
                ).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ThemeOption extends StatelessWidget {
  const _ThemeOption({
    required this.theme,
    required this.selected,
  });

  final ChargeHubTheme theme;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final data = _themeData(theme);

    return Padding(
      padding: const EdgeInsets.only(
        bottom: 8,
      ),
      child: Material(
        color: selected
            ? colorScheme.primary.withValues(
                alpha: 0.10,
              )
            : colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            RadioGroup.maybeOf<ChargeHubTheme>(context)?.onChanged(theme);
          },
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: data.background,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: data.outline,
                    ),
                  ),
                  child: Center(
                    child: Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: data.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data.name,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        data.description,
                        style: TextStyle(
                          fontSize: 11,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Radio<ChargeHubTheme>(
                  value: theme,
                  activeColor: colorScheme.primary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  _ThemePreview _themeData(
    ChargeHubTheme theme,
  ) {
    switch (theme) {
      case ChargeHubTheme.lavender:
        return const _ThemePreview(
          name: 'Lavender',
          description: 'Soft lavender and muted indigo',
          background: Color(0xFFF5F2FB),
          primary: Color(0xFF62698F),
          outline: Color(0xFFC9C5D3),
        );

      case ChargeHubTheme.midnight:
        return const _ThemePreview(
          name: 'Midnight',
          description: 'Dark navy with electric purple',
          background: Color(0xFF151722),
          primary: Color(0xFF9B8AFB),
          outline: Color(0xFF45475A),
        );

      case ChargeHubTheme.eco:
        return const _ThemePreview(
          name: 'Eco',
          description: 'Soft green and natural tones',
          background: Color(0xFFF1F7F1),
          primary: Color(0xFF4E7A59),
          outline: Color(0xFFB7C9B9),
        );

      case ChargeHubTheme.sunset:
        return const _ThemePreview(
          name: 'Sunset',
          description: 'Warm peach and coral tones',
          background: Color(0xFFFBF3EF),
          primary: Color(0xFFB86F62),
          outline: Color(0xFFD2BDB6),
        );
    }
  }
}

class _ThemePreview {
  const _ThemePreview({
    required this.name,
    required this.description,
    required this.background,
    required this.primary,
    required this.outline,
  });

  final String name;
  final String description;
  final Color background;
  final Color primary;
  final Color outline;
}
