import 'dart:math';

import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/features/events/providers/event_providers.dart';
import 'package:acter/features/news/providers/news_providers.dart';
import 'package:acter/features/pins/providers/pins_provider.dart';
import 'package:acter/features/space/providers/space_navbar_provider.dart';
import 'package:acter/features/space/providers/topic_provider.dart';
import 'package:acter/features/tasks/providers/tasklists_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/mock_updates_providers.dart';
import '../../space/pages/space_details_page_test.dart';

void main() {
  group('SpaceNavbarProvider', () {
    late ProviderContainer container;
    late String testSpaceId;

    setUp(() {
      container = ProviderContainer();
      testSpaceId = 'test-space-id-${Random().nextInt(1000000)}';
    });

    tearDown(() {
      container.dispose();
    });

    group('Shows tabs based for acter spaces features', () {
      final basicOverrides = [
        topicProvider.overrideWith(
          (ref, spaceId) => spaceId == testSpaceId ? 'Test Topic' : null,
        ),
        isActerSpace.overrideWith(
          (ref, spaceId) => spaceId == testSpaceId ? true : false,
        ),
      ];
      test('show overview if it exists', () async {
        // Override the allActivitiesProvider to return our mock activities
        container = ProviderContainer(overrides: [...basicOverrides]);

        await container.pump();
        final next = container.read(tabsProvider(testSpaceId));
        expect(next, equals([TabEntry.overview, TabEntry.members]));
      });

      test('shows only members if nothing exists', () async {
        // Override the allActivitiesProvider to return our mock activities
        container = ProviderContainer(
          overrides: [
            topicProvider.overrideWith((ref, spaceId) => null),
            isActerSpace.overrideWith((ref, spaceId) => true),
          ],
        );

        await container.pump();
        final next = container.read(tabsProvider(testSpaceId));
        expect(next, equals([TabEntry.members]));
      });

      group('updates', () {
        test('shows if any exists', () async {
          // Override the allActivitiesProvider to return our mock activities
          container = ProviderContainer(
            overrides: [
              ...basicOverrides,
              updateListProvider.overrideWith(
                (ref, spaceId) => [MockUpdatesEntry()],
              ),
              acterAppSettingsProvider.overrideWith(
                (ref, spaceId) => MockActerAppSettings(
                  newsActive: true,
                  pinsActive: false,
                  tasksActive: false,
                  eventsActive: false,
                ),
              ),
            ],
          );
          await container.pump();
          final next = container.read(tabsProvider(testSpaceId));
          expect(
            next,
            equals([TabEntry.overview, TabEntry.updates, TabEntry.members]),
          );
        });

        test('hides if none exists', () async {
          // Override the allActivitiesProvider to return our mock activities
          container = ProviderContainer(
            overrides: [
              ...basicOverrides,
              updateListProvider.overrideWith((ref, spaceId) => []),
              acterAppSettingsProvider.overrideWith(
                (ref, spaceId) => MockActerAppSettings(
                  newsActive: true,
                  pinsActive: false,
                  tasksActive: false,
                  eventsActive: false,
                ),
              ),
            ],
          );
          await container.pump();
          final next = container.read(tabsProvider(testSpaceId));
          expect(next, equals([TabEntry.overview, TabEntry.members]));
        });

        test('hides if exists but deactivated', () async {
          // Override the allActivitiesProvider to return our mock activities
          container = ProviderContainer(
            overrides: [
              ...basicOverrides,
              updateListProvider.overrideWith(
                (ref, spaceId) => [MockUpdatesEntry()], // we have an update
              ),
              acterAppSettingsProvider.overrideWith(
                (ref, spaceId) => MockActerAppSettings(
                  newsActive: false, // updates have been deactivated
                  pinsActive: false,
                  tasksActive: false,
                  eventsActive: false,
                ),
              ),
            ],
          );
          await container.pump();
          final next = container.read(tabsProvider(testSpaceId));
          expect(next, equals([TabEntry.overview, TabEntry.members]));
        });
      });

      group('pins', () {
        test('shows if any exists', () async {
          // Override the allActivitiesProvider to return our mock activities
          container = ProviderContainer(
            overrides: [
              ...basicOverrides,
              pinListProvider.overrideWith((ref, spaceId) => [MockActerPin()]),
              acterAppSettingsProvider.overrideWith(
                (ref, spaceId) => MockActerAppSettings(
                  newsActive: false,
                  pinsActive: true,
                  tasksActive: false,
                  eventsActive: false,
                ),
              ),
            ],
          );
          await container.pump();
          final next = container.read(tabsProvider(testSpaceId));
          expect(
            next,
            equals([TabEntry.overview, TabEntry.pins, TabEntry.members]),
          );
        });

        test('hides if none exists', () async {
          // Override the allActivitiesProvider to return our mock activities
          container = ProviderContainer(
            overrides: [
              ...basicOverrides,
              pinListProvider.overrideWith((ref, spaceId) => []),
              acterAppSettingsProvider.overrideWith(
                (ref, spaceId) => MockActerAppSettings(
                  newsActive: false,
                  pinsActive: true,
                  tasksActive: false,
                  eventsActive: false,
                ),
              ),
            ],
          );
          await container.pump();
          final next = container.read(tabsProvider(testSpaceId));
          expect(next, equals([TabEntry.overview, TabEntry.members]));
        });

        test('hides if exists but deactivated', () async {
          // Override the allActivitiesProvider to return our mock activities
          container = ProviderContainer(
            overrides: [
              ...basicOverrides,
              pinListProvider.overrideWith((ref, spaceId) => [MockActerPin()]),
              acterAppSettingsProvider.overrideWith(
                (ref, spaceId) => MockActerAppSettings(
                  newsActive: false,
                  pinsActive: false,
                  tasksActive: false,
                  eventsActive: false,
                ),
              ),
            ],
          );
          await container.pump();
          final next = container.read(tabsProvider(testSpaceId));
          expect(next, equals([TabEntry.overview, TabEntry.members]));
        });
      });

      group('tasks', () {
        test('shows if any exists', () async {
          // Override the allActivitiesProvider to return our mock activities
          container = ProviderContainer(
            overrides: [
              ...basicOverrides,
              taskListsProvider.overrideWith((ref, spaceId) => ['a']),
              acterAppSettingsProvider.overrideWith(
                (ref, spaceId) => MockActerAppSettings(
                  newsActive: false,
                  pinsActive: false,
                  tasksActive: true,
                  eventsActive: false,
                ),
              ),
            ],
          );
          await container.pump();
          final next = container.read(tabsProvider(testSpaceId));
          expect(
            next,
            equals([TabEntry.overview, TabEntry.tasks, TabEntry.members]),
          );
        });

        test('hides if none exists', () async {
          // Override the allActivitiesProvider to return our mock activities
          container = ProviderContainer(
            overrides: [
              ...basicOverrides,
              taskListsProvider.overrideWith((ref, spaceId) => []),
              acterAppSettingsProvider.overrideWith(
                (ref, spaceId) => MockActerAppSettings(
                  newsActive: false,
                  pinsActive: false,
                  tasksActive: true,
                  eventsActive: false,
                ),
              ),
            ],
          );
          await container.pump();
          final next = container.read(tabsProvider(testSpaceId));
          expect(next, equals([TabEntry.overview, TabEntry.members]));
        });

        test('hides if exists but deactivated', () async {
          // Override the allActivitiesProvider to return our mock activities
          container = ProviderContainer(
            overrides: [
              ...basicOverrides,
              taskListsProvider.overrideWith((ref, spaceId) => ['a']),
              acterAppSettingsProvider.overrideWith(
                (ref, spaceId) => MockActerAppSettings(
                  newsActive: false,
                  pinsActive: false,
                  tasksActive: false,
                  eventsActive: false,
                ),
              ),
            ],
          );
          await container.pump();
          final next = container.read(tabsProvider(testSpaceId));
          expect(next, equals([TabEntry.overview, TabEntry.members]));
        });
      });

      group('events', () {
        test('shows if any exists', () async {
          // Override the allActivitiesProvider to return our mock activities
          container = ProviderContainer(
            overrides: [
              ...basicOverrides,
              allEventListProvider.overrideWith(
                (ref, spaceId) => [MockCalendarEvent()],
              ),
              acterAppSettingsProvider.overrideWith(
                (ref, spaceId) => MockActerAppSettings(
                  newsActive: false,
                  pinsActive: false,
                  tasksActive: false,
                  eventsActive: true,
                ),
              ),
            ],
          );
          await container.pump();
          final next = container.read(tabsProvider(testSpaceId));
          expect(
            next,
            equals([TabEntry.overview, TabEntry.events, TabEntry.members]),
          );
        });

        test('hides if none exists', () async {
          // Override the allActivitiesProvider to return our mock activities
          container = ProviderContainer(
            overrides: [
              ...basicOverrides,
              allEventListProvider.overrideWith((ref, spaceId) => []),
              acterAppSettingsProvider.overrideWith(
                (ref, spaceId) => MockActerAppSettings(
                  newsActive: false,
                  pinsActive: false,
                  tasksActive: false,
                  eventsActive: true,
                ),
              ),
            ],
          );
          await container.pump();
          final next = container.read(tabsProvider(testSpaceId));
          expect(next, equals([TabEntry.overview, TabEntry.members]));
        });

        test('hides if exists but deactivated', () async {
          // Override the allActivitiesProvider to return our mock activities
          container = ProviderContainer(
            overrides: [
              ...basicOverrides,
              allEventListProvider.overrideWith(
                (ref, spaceId) => [MockCalendarEvent()],
              ),
              acterAppSettingsProvider.overrideWith(
                (ref, spaceId) => MockActerAppSettings(
                  newsActive: false,
                  pinsActive: false,
                  tasksActive: false,
                  eventsActive: false,
                ),
              ),
            ],
          );
          await container.pump();
          final next = container.read(tabsProvider(testSpaceId));
          expect(next, equals([TabEntry.overview, TabEntry.members]));
        });
      });

      test('shows all if enabled and exists', () async {
        // Override the allActivitiesProvider to return our mock activities
        container = ProviderContainer(
          overrides: [
            ...basicOverrides,
            allEventListProvider.overrideWith(
              (ref, spaceId) => [MockCalendarEvent()],
            ),
            updateListProvider.overrideWith(
              (ref, spaceId) => [MockUpdatesEntry()],
            ),
            pinListProvider.overrideWith((ref, spaceId) => [MockActerPin()]),
            taskListsProvider.overrideWith((ref, spaceId) => ['a']),
            acterAppSettingsProvider.overrideWith(
              (ref, spaceId) => MockActerAppSettings(
                newsActive: true,
                pinsActive: true,
                tasksActive: true,
                eventsActive: true,
              ),
            ),
          ],
        );
        await container.pump();
        final next = container.read(tabsProvider(testSpaceId));
        expect(
          next,
          equals([
            TabEntry.overview,
            TabEntry.updates,
            TabEntry.pins,
            TabEntry.tasks,
            TabEntry.events,
            TabEntry.members,
          ]),
        );
      });

      test('hides all if exists but not an acter space', () async {
        // Override the allActivitiesProvider to return our mock activities
        container = ProviderContainer(
          overrides: [
            topicProvider.overrideWith((ref, spaceId) => 'Test Topic'),
            isActerSpace.overrideWith(
              (ref, spaceId) => false,
            ), // this disable all them
            allEventListProvider.overrideWith(
              (ref, spaceId) => [MockCalendarEvent()],
            ),
            updateListProvider.overrideWith(
              (ref, spaceId) => [MockUpdatesEntry()],
            ),
            pinListProvider.overrideWith((ref, spaceId) => [MockActerPin()]),
            taskListsProvider.overrideWith((ref, spaceId) => ['a']),
          ],
        );
        await container.pump();
        final next = container.read(tabsProvider(testSpaceId));
        expect(next, equals([TabEntry.overview, TabEntry.members]));
      });
    });

    group('Shows tabs based for non acter spaces', () {
      test('show overview if it exists', () async {
        // Override the allActivitiesProvider to return our mock activities
        container = ProviderContainer(
          overrides: [
            topicProvider.overrideWith((ref, spaceId) => 'Test Topic'),
            isActerSpace.overrideWith((ref, spaceId) => false),
          ],
        );

        await container.pump();
        final next = container.read(tabsProvider(testSpaceId));
        expect(next, contains(TabEntry.overview));
        expect(next, contains(TabEntry.members));
      });

      test('shows only members if nothing exists', () async {
        // Override the allActivitiesProvider to return our mock activities
        container = ProviderContainer(
          overrides: [
            topicProvider.overrideWith((ref, spaceId) => null),
            isActerSpace.overrideWith((ref, spaceId) => false),
          ],
        );

        await container.pump();
        final next = container.read(tabsProvider(testSpaceId));
        expect(next, equals([TabEntry.members]));
      });
    });
  });
}
