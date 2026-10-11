# Existing portfolio content analysis

Source: sibling `../portfolio_app`, inspected during Phase 1. The website was not modified.

## Current architecture

`lib/main.dart` launches `PortfolioApp` in `lib/app.dart`. The app owns an in-memory light/dark theme toggle and a single scrolling page. GlobalKeys identify seven sections for callback-driven navigation. Shared widgets live in `lib/widgets/common`; colors, typography, spacing and breakpoints live in `lib/theme/app_theme.dart` and `lib/utils/core`.

Content is held in Dart constants and static lists. There is no persistence layer, API, repository, or content backend. The website depends directly on Flutter, cupertino_icons, flutter_svg and url_launcher. Its pubspec declares Dart >=3.3.0 <4.0.0; its existing lockfile requires Dart >=3.11.0 and Flutter >=3.38.0. The installed Flutter 3.47.1 / Dart 3.13.1 is reused by the dashboard without upgrading the website.

## Future manageable sections

All source paths in this table are relative to the website root.

| Section | Current source and data | Future editable content |
| --- | --- | --- |
| Hero | `lib/utils/core/app_strings.dart`, `app_assets.dart`, `lib/widgets/sections/hero_section.dart` | Name, professional title, tagline, profile photo, CTA labels and destinations; optional orbit icon selection. |
| About | `lib/widgets/sections/about_section.dart`: heading, bio, `personalInfo` (3 maps) | Biography and labeled name/email/phone details. |
| Skills | `lib/widgets/sections/skills_section.dart`: `categories` (4 categories, 15 skills) | Category titles/order; skill label, icon, color, theme-adaptive flag and order. Categories are Mobile Development, Backend & Database, Game Development, and Tools. |
| Projects | `lib/widgets/sections/projects_section.dart`: `projects` (8 Project objects) | Titles, descriptions, ordered screenshots, technology tags, optional GitHub/live links and display order. |
| Education | `lib/widgets/sections/education_section.dart`: `educationList` (5 Education objects) | Degree/course, institution, duration, location, current status, optional certificate URL and order. |
| Experience | `lib/widgets/sections/experience_section.dart`: `experiences` (3 Experience objects; 1 nested milestone) | Role, company, duration, location, highlights, current status, nested career milestones and order. |
| Contact | `lib/widgets/sections/contact_section.dart`: heading/subtitle, email, phone, location, GitHub/LinkedIn/WhatsApp links | Contact copy, recipient email, contact details and social links. Location is declared but currently not rendered. |
| Shared site content | `lib/utils/core/app_strings.dart`, `lib/widgets/common/app_navbar.dart`, `web/index.html`, `web/cv.pdf` | Branding, navigation labels, CV file/download name, browser title and description. |

Section headings/subtitles can also become editable. Layout, breakpoints, theme implementation and animation code remain presentation concerns. No future editor or data contract is implemented in this phase.

## Existing model fields

- `lib/models/project.dart` — Project: title, description, imagePaths, techStack, nullable liveUrl and githubUrl.
- `lib/models/education.dart` — Education: degree, institution, duration, location, isCurrent (default false), nullable certificateUrl.
- `lib/models/experience.dart` — Experience: role, company, duration, location, highlights, milestones (default empty), isCurrent (default false).
- Same file — ExperienceMilestone: title, duration, type (default Promotion), highlights (default empty).

These are const-constructible classes with final fields. They have no IDs, serialization or persistence behavior. Skills and personal details use maps rather than dedicated models. Durations are display strings rather than structured dates. A later phase will need to decide storage and website consumption before implementing editing.

## Image and document inventory

There are 22 raster images under `assets/images/`:

- `profile.jpeg`: hero photo.
- `findway1.png` through `findway12.png`: BA_FindWay gallery (12).
- `aflam_pair1_landscape.jpg` through `aflam_pair3_landscape.jpg`: Aflam Night gallery (3).
- `flower_driver.png`: Flowery Driver App.
- `flower_app.png`: Flower App.
- `todo_app.png`: Todo App.
- `happy_paw.png`: Happy Paws.
- `yummy_test.png`: Yummy Taste.
- `memory_game.png`: Memory Game.

There are 19 SVGs under `assets/icons/`: blueprint, cplusplus, csharp, dart, figma, firebase, flutter, git, github, laravel, linkedin, mysql, php, postman, unity, unreal, unreal_engine, whatsapp and x. Their paths and hero/precache lists are defined in `lib/utils/core/app_assets.dart`. The website pubspec bundles both asset directories. `web/cv.pdf` is a separate downloadable file.

## Existing behavior and content caveats

- Project galleries cycle every three seconds; optional external links render only when supplied.
- Education entries optionally show certificate links; experience entries show nested career milestones.
- Contact form uses `mailto:` to open the visitor's email application. There is no stored message inbox to manage.
- CV download uses a conditional web implementation with a no-op non-web fallback.
- About and Contact duplicate email/phone values; a future content source should keep these consistent.
- BA_FindWay currently duplicates Aflam Night's description despite Unity/C# tags.
- The hero name constant includes formatting characters and is reused for the CV download filename; future content should separate plain values from presentation.
- The website README still marks completed sections as placeholders.
- `web/index.html` references a manifest and icons absent from the source web folder.
- The raster precache list omits the FindWay and Aflam Night galleries.

These observations are documented only. No website fixes, data migration, Firebase, CRUD, additional dashboard screens, or website connection were implemented.
