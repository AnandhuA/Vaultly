import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../collections/collections_screen.dart';
import '../profile/profile_screen.dart';
import '../search/search_screen.dart';
import 'home_screen.dart';
import 'save_bottom_sheet.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key, this.initialIndex = 0});

  final int initialIndex;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  late int index = widget.initialIndex < 0
      ? 0
      : widget.initialIndex > 4
      ? 4
      : widget.initialIndex;

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.sizeOf(context).width >= 900;
    final pages = [
      HomeScreen(onSearchTap: () => setState(() => index = 3)),
      const CollectionsScreen(),
      const SizedBox.shrink(),
      const SearchScreen(),
      const ProfileScreen(),
    ];
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (index != 0) {
          setState(() => index = 0);
          return;
        }
        SystemNavigator.pop();
      },
      child: Scaffold(
        body: isDesktop
            ? _DesktopShell(
                index: index,
                child: pages[index == 2 ? 0 : index],
                onSelected: (value) => setState(() => index = value),
                onSave: _showSaveSheet,
              )
            : pages[index],
        bottomNavigationBar: isDesktop
            ? null
            : NavigationBar(
                selectedIndex: index,
                onDestinationSelected: (value) {
                  if (value == 2) {
                    _showSaveSheet();
                  } else {
                    setState(() => index = value);
                  }
                },
                destinations: const [
                  NavigationDestination(
                    icon: Icon(Icons.home_outlined),
                    selectedIcon: Icon(Icons.home_rounded),
                    label: 'Home',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.folder_outlined),
                    selectedIcon: Icon(Icons.folder_rounded),
                    label: 'Collections',
                  ),
                  NavigationDestination(
                    icon: _SaveNavIcon(),
                    selectedIcon: _SaveNavIcon(),
                    label: 'Save',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.search_rounded),
                    label: 'Search',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.person_outline_rounded),
                    selectedIcon: Icon(Icons.person_rounded),
                    label: 'Profile',
                  ),
                ],
              ),
      ),
    );
  }

  void _showSaveSheet() {
    final isDesktop = MediaQuery.sizeOf(context).width >= 900;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      constraints: isDesktop ? const BoxConstraints(maxWidth: 560) : null,
      builder: (_) => const SaveBottomSheet(),
    );
  }
}

class _DesktopShell extends StatelessWidget {
  const _DesktopShell({
    required this.index,
    required this.child,
    required this.onSelected,
    required this.onSave,
  });

  final int index;
  final Widget child;
  final ValueChanged<int> onSelected;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final selectedRailIndex = switch (index) {
      1 => 1,
      3 => 2,
      4 => 3,
      _ => 0,
    };
    final destinations = const [
      NavigationRailDestination(
        icon: Icon(Icons.home_outlined),
        selectedIcon: Icon(Icons.home_rounded),
        label: Text('Home'),
      ),
      NavigationRailDestination(
        icon: Icon(Icons.folder_outlined),
        selectedIcon: Icon(Icons.folder_rounded),
        label: Text('Collections'),
      ),
      NavigationRailDestination(
        icon: Icon(Icons.search_rounded),
        label: Text('Search'),
      ),
      NavigationRailDestination(
        icon: Icon(Icons.person_outline_rounded),
        selectedIcon: Icon(Icons.person_rounded),
        label: Text('Profile'),
      ),
    ];
    return Row(
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            border: Border(
              right: BorderSide(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
          ),
          child: SafeArea(
            child: SizedBox(
              width: 112,
              child: Column(
                children: [
                  const SizedBox(height: 14),
                  FilledButton.tonalIcon(
                    onPressed: onSave,
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Save'),
                  ),
                  const SizedBox(height: 18),
                  Expanded(
                    child: NavigationRail(
                      selectedIndex: selectedRailIndex,
                      labelType: NavigationRailLabelType.all,
                      onDestinationSelected: (value) {
                        onSelected(switch (value) {
                          1 => 1,
                          2 => 3,
                          3 => 4,
                          _ => 0,
                        });
                      },
                      destinations: destinations,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Expanded(child: child),
      ],
    );
  }
}

class _SaveNavIcon extends StatelessWidget {
  const _SaveNavIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.add_rounded, color: Colors.white, size: 20),
    );
  }
}
