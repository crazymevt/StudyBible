import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/app_state.dart';
import '../app_drawer.dart';
import 'journals_list_panel.dart';
import 'journal_editor_panel.dart';
import 'prayer_tracker_panel.dart';
import 'action_items_panel.dart';
import '../common/search_title_bar.dart';
import '../common/breakpoints.dart';
import '../common/sync_button.dart';

class JournalsPrayersScreen extends ConsumerStatefulWidget {
  const JournalsPrayersScreen({super.key});

  @override
  ConsumerState<JournalsPrayersScreen> createState() =>
      _JournalsPrayersScreenState();
}

class _JournalsPrayersScreenState extends ConsumerState<JournalsPrayersScreen>
    with TickerProviderStateMixin {
  late final TabController _mobileTabController;
  late final TabController _desktopTabController;

  @override
  void initState() {
    super.initState();
    final initialTab = ref.read(journalsActiveTabProvider);
    
    int mobileIndex = 0;
    if (initialTab == JournalsActiveTab.prayers) mobileIndex = 1;
    if (initialTab == JournalsActiveTab.actions) mobileIndex = 2;
    
    int desktopIndex = 0;
    if (initialTab == JournalsActiveTab.actions) desktopIndex = 1;

    _mobileTabController = TabController(
        initialIndex: mobileIndex, length: 3, vsync: this);
    _desktopTabController = TabController(
        initialIndex: desktopIndex, length: 2, vsync: this);
  }

  @override
  void dispose() {
    _mobileTabController.dispose();
    _desktopTabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.sizeOf(context).width > Breakpoints.compact;

    ref.listen(journalsActiveTabProvider, (prev, next) {
      if (isDesktop) {
        if (next == JournalsActiveTab.prayers) {
          _desktopTabController.animateTo(0);
        } else if (next == JournalsActiveTab.actions) {
          _desktopTabController.animateTo(1);
        }
      } else {
        if (next == JournalsActiveTab.journals) {
          _mobileTabController.animateTo(0);
        } else if (next == JournalsActiveTab.prayers) {
          _mobileTabController.animateTo(1);
        } else if (next == JournalsActiveTab.actions) {
          _mobileTabController.animateTo(2);
        }
      }
    });

    if (isDesktop) {
      return Scaffold(
        drawer: const AppDrawer(),
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
          centerTitle: true,
          title: const SearchTitleBar(),
          actions: const [SyncButton()],
        ),
        body: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 2,
              child: _buildPanelCard(
                context,
                title: 'Journal Entries',
                icon: Icons.book,
                child: const JournalsListPanel(),
              ),
            ),
            Expanded(
              flex: 4,
              child: _buildPanelCard(
                context,
                title: 'Editor',
                icon: Icons.edit_document,
                child: const JournalEditorPanel(),
              ),
            ),
            Expanded(
              flex: 3,
              child: _buildTabbedCard(
                context,
                controller: _desktopTabController,
                tabs: const [
                  Tab(text: 'Prayers'),
                  Tab(text: 'Actions'),
                ],
                views: const [PrayerTrackerPanel(), ActionItemsPanel()],
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
        centerTitle: true,
        title: const SearchTitleBar(),
        actions: const [SyncButton()],
        bottom: TabBar(
          controller: _mobileTabController,
          tabs: const [
            Tab(text: 'Journals'),
            Tab(text: 'Prayers'),
            Tab(text: 'Actions'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _mobileTabController,
        children: const [
          JournalsListPanel(),
          PrayerTrackerPanel(),
          ActionItemsPanel(),
        ],
      ),
    );
  }

  Widget _buildPanelCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.all(8),
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              border: Border(
                bottom: BorderSide(
                  color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, size: 20, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }

  /// Like [_buildPanelCard] but the header is a [TabBar] that switches between
  /// the supplied [views] — used to fit Prayers and Actions into one column.
  Widget _buildTabbedCard(
    BuildContext context, {
    required TabController controller,
    required List<Tab> tabs,
    required List<Widget> views,
  }) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.all(8),
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest
                  .withValues(alpha: 0.5),
              border: Border(
                bottom: BorderSide(
                  color:
                      theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                ),
              ),
            ),
            child: TabBar(controller: controller, tabs: tabs),
          ),
          Expanded(child: TabBarView(controller: controller, children: views)),
        ],
      ),
    );
  }
}
