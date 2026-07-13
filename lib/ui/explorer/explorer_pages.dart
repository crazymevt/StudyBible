import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:path/path.dart' as p;

import '../../app/content_providers.dart';
import '../../app/explorer_providers.dart';
import '../../app/media_providers.dart';
import '../../app/people_providers.dart';
import '../../app/place_providers.dart';
import '../../app/prophecy_providers.dart';
import '../../app/reference_providers.dart';
import '../../app/search_providers.dart';
import '../../app/thread_walk_providers.dart';
import '../../app/topic_providers.dart';
import '../../app/user_providers.dart';
import '../../data/app_paths.dart';
import '../../data/content_store.dart';
import '../../data/user_store.dart';
import '../../domain/explorer/explorer_ref.dart';
import '../../domain/prophecy/prophecy.dart';
import '../../domain/prophecy/prophecy_data.dart';
import '../../domain/prophecy/prophecy_index.dart';
import '../../domain/reference/reference_index.dart';
import '../../domain/scripture/passage_citation.dart';
import '../../domain/threads/thread.dart';
import '../../domain/threads/thread_data.dart';
import '../common/skeleton.dart';
import '../reader/image_viewer_dialog.dart';
import '../reader/media_video_list.dart';
import '../reader/pdf_viewer_dialog.dart';
import 'explorer_common.dart';
import 'explorer_index_page.dart';
import 'family_tree_screen.dart';

part 'explorer_prophecy_page.dart';
part 'explorer_thread_page.dart';
part 'explorer_page_widgets.dart';
part 'explorer_person_page.dart';
part 'explorer_place_page.dart';
part 'explorer_event_page.dart';
part 'explorer_topic_page.dart';
part 'explorer_passage_page.dart';
part 'explorer_tag_page.dart';

/// The page body for one trail entry — dispatches on the entity type.
class ExplorerEntityPage extends StatelessWidget {
  const ExplorerEntityPage({super.key, required this.entry});

  final ExplorerRef entry;

  @override
  Widget build(BuildContext context) {
    return switch (entry.type) {
      ExplorerEntityType.person => _PersonPage(personId: entry.id!),
      ExplorerEntityType.place => _PlacePage(placeId: entry.id!),
      ExplorerEntityType.event => _EventPage(eventId: entry.id!),
      ExplorerEntityType.topic => _TopicPage(topicId: entry.id!),
      ExplorerEntityType.passage => _PassagePage(
        book: entry.book!,
        chapter: entry.chapter!,
      ),
      ExplorerEntityType.tag => _TagPage(tagId: entry.tagId!),
      ExplorerEntityType.prophecy => _ProphecyPage(index: entry.id!),
      ExplorerEntityType.thread => _ThreadPage(index: entry.id!),
      ExplorerEntityType.browse => ExplorerIndexPage(
        kind: entry.browseKind!,
        category: entry.browseCategory,
      ),
    };
  }
}
