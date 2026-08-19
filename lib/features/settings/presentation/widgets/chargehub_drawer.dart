import 'package:flutter/material.dart';
import 'theme_selector.dart';

class ChargeHubDrawer extends StatelessWidget {
  const ChargeHubDrawer({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Drawer(
      backgroundColor: colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(
                24,
                28,
                20,
                24,
              ),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainer,
              ),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withValues(
                        alpha: 0.12,
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.ev_station_rounded,
                      color: colorScheme.primary,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ChargeHub',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Find. Charge. Go.',
                        style: TextStyle(
                          fontSize: 12,
                          color:
                          colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            _DrawerItem(
              icon: Icons.home_rounded,
              title: 'Home',
              selected: true,
              onTap: () {
                Navigator.pop(context);
              },
            ),

            _DrawerItem(
              icon: Icons.ev_station_rounded,
              title: 'Charging Stations',
              onTap: () {
                Navigator.pop(context);
              },
            ),

            const SizedBox(height: 8),

            Divider(
              color: colorScheme.outlineVariant,
              height: 1,
            ),

            const SizedBox(height: 8),

            _DrawerItem(
              icon: Icons.palette_rounded,
              title: 'Themes',
              onTap: () {
                Navigator.pop(context);

                Future.delayed(
                  const Duration(milliseconds: 180),
                  () {
                    if (context.mounted) {
                      ThemeSelector.show(context);
                    }
                  },
                );
              },
            ),

            _DrawerItem(
              icon: Icons.settings_rounded,
              title: 'Settings',
              onTap: () {
                Navigator.pop(context);
              },
            ),

            _DrawerItem(
              icon: Icons.info_outline_rounded,
              title: 'About ChargeHub',
              onTap: () {
                Navigator.pop(context);
              },
            ),

            const Spacer(),

            Divider(
              color: colorScheme.outlineVariant,
              height: 1,
            ),

            _DrawerItem(
              icon: Icons.person_outline_rounded,
              title: 'Account',
              onTap: () {
                Navigator.pop(context);
              },
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(
                24,
                4,
                24,
                20,
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'ChargeHub',
                  style: TextStyle(
                    fontSize: 11,
                    color:
                    colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  const _DrawerItem({
    required this.icon,
    required this.title,
    required this.onTap,
    this.selected = false,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 2,
      ),
      child: Material(
        color: selected
            ? colorScheme.primary.withValues(
          alpha: 0.10,
        )
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 21,
                  color: selected
                      ? colorScheme.primary
                      : colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: selected
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: selected
                          ? colorScheme.primary
                          : colorScheme.onSurface,
                    ),
                  ),
                ),
                if (selected)
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 19,
                    color: colorScheme.primary,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}