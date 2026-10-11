# Project files after the list browsing phase

Dashboard source, tests, frozen seed and retained platform scaffolding. Generated build/cache files are excluded. Production content remains separately in LOCALAPPDATA.

```text
.flutter-plugins-dependencies
.gitignore
.idea/.gitignore
.idea/caches/deviceStreaming.xml
.idea/libraries/Dart_Packages.xml
.idea/libraries/Dart_SDK.xml
.idea/libraries/Flutter_Plugins.xml
.idea/libraries/KotlinJavaRuntime.xml
.idea/markdown.xml
.idea/modules.xml
.idea/runConfigurations/main_dart.xml
.idea/workspace.xml
.metadata
README.md
analysis_options.yaml
assets/seed/media/assets/icons/blueprint.svg
assets/seed/media/assets/icons/cplusplus.svg
assets/seed/media/assets/icons/csharp.svg
assets/seed/media/assets/icons/dart.svg
assets/seed/media/assets/icons/figma.svg
assets/seed/media/assets/icons/firebase.svg
assets/seed/media/assets/icons/flutter.svg
assets/seed/media/assets/icons/git.svg
assets/seed/media/assets/icons/github.svg
assets/seed/media/assets/icons/laravel.svg
assets/seed/media/assets/icons/linkedin.svg
assets/seed/media/assets/icons/mysql.svg
assets/seed/media/assets/icons/php.svg
assets/seed/media/assets/icons/postman.svg
assets/seed/media/assets/icons/unity.svg
assets/seed/media/assets/icons/unreal.svg
assets/seed/media/assets/icons/unreal_engine.svg
assets/seed/media/assets/icons/whatsapp.svg
assets/seed/media/assets/icons/x.svg
assets/seed/media/assets/images/aflam_pair1_landscape.jpg
assets/seed/media/assets/images/aflam_pair2_landscape.jpg
assets/seed/media/assets/images/aflam_pair3_landscape.jpg
assets/seed/media/assets/images/findway1.png
assets/seed/media/assets/images/findway10.png
assets/seed/media/assets/images/findway11.png
assets/seed/media/assets/images/findway12.png
assets/seed/media/assets/images/findway2.png
assets/seed/media/assets/images/findway3.png
assets/seed/media/assets/images/findway4.png
assets/seed/media/assets/images/findway5.png
assets/seed/media/assets/images/findway6.png
assets/seed/media/assets/images/findway7.png
assets/seed/media/assets/images/findway8.png
assets/seed/media/assets/images/findway9.png
assets/seed/media/assets/images/flower_app.png
assets/seed/media/assets/images/flower_driver.png
assets/seed/media/assets/images/happy_paw.png
assets/seed/media/assets/images/memory_game.png
assets/seed/media/assets/images/profile.jpeg
assets/seed/media/assets/images/todo_app.png
assets/seed/media/assets/images/yummy_test.png
assets/seed/media/web/cv.pdf
assets/seed/portfolio.json
docs/CONTENT_ANALYSIS.md
docs/CONTENT_MANAGEMENT.md
docs/CREATED_FILES.md
docs/LIST_BROWSING.md
docs/LOCAL_DATA.md
docs/MEDIA_MANAGEMENT.md
docs/PHASE_2.md
docs/PROJECTS_MANAGEMENT.md
docs/VERIFICATION.md
lib/data/json_portfolio_store.dart
lib/data/open_local_portfolio.dart
lib/main.dart
lib/models/content_validation.dart
lib/models/image_import.dart
lib/models/list_browse_state.dart
lib/models/portfolio_content.dart
lib/models/portfolio_models.dart
lib/models/project_validation.dart
lib/models/record_ids.dart
lib/navigation/dashboard_destination.dart
lib/pages/content/content_editor.dart
lib/pages/content/content_forms.dart
lib/pages/content/content_management_page.dart
lib/pages/content_page.dart
lib/pages/media/media_library.dart
lib/pages/overview_page.dart
lib/pages/projects/project_details.dart
lib/pages/projects/project_editor.dart
lib/pages/projects/project_image.dart
lib/pages/projects/projects_page.dart
lib/repositories/local_portfolio_repository.dart
lib/repositories/portfolio_repository.dart
lib/services/image_selection.dart
lib/theme/dashboard_theme.dart
lib/widgets/dashboard_components.dart
lib/widgets/dashboard_shell.dart
lib/widgets/dashboard_sidebar.dart
lib/widgets/list_controls.dart
lib/widgets/portfolio_bootstrap.dart
portfolio_admin_dashboard.iml
pubspec.lock
pubspec.yaml
test/content_management_test.dart
test/content_repository_test.dart
test/dashboard_navigation_test.dart
test/fixture_repository.dart
test/list_browse_state_test.dart
test/list_browsing_test.dart
test/local_repository_test.dart
test/media_management_test.dart
test/media_repository_test.dart
test/portfolio_bootstrap_test.dart
test/projects_management_test.dart
tool/content_process_check.dart
tool/import_website.py
tool/repository_process_check.dart
windows/.gitignore
windows/CMakeLists.txt
windows/flutter/CMakeLists.txt
windows/flutter/generated_plugin_registrant.cc
windows/flutter/generated_plugin_registrant.h
windows/flutter/generated_plugins.cmake
windows/runner/CMakeLists.txt
windows/runner/Runner.rc
windows/runner/flutter_window.cpp
windows/runner/flutter_window.h
windows/runner/main.cpp
windows/runner/resource.h
windows/runner/resources/app_icon.ico
windows/runner/runner.exe.manifest
windows/runner/utils.cpp
windows/runner/utils.h
windows/runner/win32_window.cpp
windows/runner/win32_window.h
```

## Overview and analytics phase additions

- `lib/services/website_analytics.dart`
- `lib/pages/website_analytics_page.dart`
- `test/overview_analytics_test.dart`
- `docs/ANALYTICS.md`

Updated Overview, DashboardShell, README and verification documentation.

## Data transfer phase additions

- `lib/models/portfolio_transfer.dart`
- `lib/services/transfer_files.dart`
- `lib/widgets/data_transfer_panel.dart`
- `test/data_transfer_test.dart`
- `test/data_transfer_panel_test.dart`
- `tool/transfer_process_check.dart`
- `docs/DATA_TRANSFER.md`

Updated the existing store, repository interface/implementation, Settings content page, README and verification documentation. No website files or dependencies changed.

## Firebase readiness phase additions

- `lib/repositories/media_repository.dart`
- `docs/FIREBASE_READINESS.md`

Narrowed ProjectImage and image-selection dependencies to MediaRepository; PortfolioRepository inherits that contract. Updated documentation only otherwise. No Firebase implementation or dependencies added.

## Reliability review additions

- `test/transfer_validation_test.dart`
- `docs/RELIABILITY_REVIEW.md`

Updated the local store and regression tests for media repair and snapshot-history validation.

## Local Windows finalization

Created `docs/LOCAL_RELEASE.md`; updated README and verification documentation. Rebuilt and verified the Windows release bundle.
