# AskAgain Code Guide and CSM3114 Requirement Map

This guide describes version 1.7.4 of AskAgain and maps the source to the four-page CSM3114 final project brief. Paths are relative to the Flutter project root. The app is an SDG 4 revision notebook; its core learning loop is create questions, review drafts, practise, and schedule the next review.

## How the app fits together

1. `lib/main.dart` starts Flutter, opens `Notebook`, registers reminders, and supplies `Notebook` through `ChangeNotifierProvider.value`.
2. `lib/ui/home_page.dart` owns the four bottom navigation destinations: Home, Subjects, Revision, and Progress. `BuildContext.open` in `lib/ui/common.dart` uses `Navigator.push` for detail screens.
3. UI screens read and write `Notebook` records. `Notebook` stores guest data in `SharedPreferences` and signed-in data at `users/{uid}/records/{recordId}` in Cloud Firestore.
4. AI note creation starts in `lib/ui/upload_page.dart`. `GenerationJob` owns progress and cancellation; `Generation` owns Gemini batches and Firestore writes. Generated questions remain drafts until the user reviews and finalises them.

## State management and data

| File | Responsibility |
| --- | --- |
| `lib/main.dart` | Initializes the app and places `Notebook` in the Provider widget tree. `AskAgain` watches it to rebuild theme and entry screen when state changes. |
| `lib/data/notebook.dart` | Main `ChangeNotifier`: authentication state, profile preferences, records, guest persistence, Firestore loading and CRUD, practice attempts, and `notifyListeners()` after changes. |
| `lib/services/generation_job.dart` | Separate `ChangeNotifier` for the current AI job: stage, progress, result, error, retry, and cancel. `lib/ui/generation_status.dart` listens with `AnimatedBuilder`. |
| `lib/data/review_schedule.dart` | Calculates due dates and mastery from recall ratings. |
| `lib/data/practice_session.dart` | Builds and shuffles practice sessions. |
| `lib/data/study_content.dart` | Filters due/scoped questions and creates local derived blank and matching exercises. |
| `lib/data/attention.dart` | Identifies weak or confused questions for focused revision. |
| `lib/data/answer_formats.dart` | Response format rules and validation. |
| `lib/data/study_rules.dart` | Study intervals, generation allowance, question limits, and numeric answer checks. |
| `lib/data/study_languages.dart` | Optional output language choices and prompt instructions. |
| `lib/data/subject_styles.dart` | Persistent subject colour mapping. |
| `lib/data/appearance.dart` | Theme, font, and text-size preferences. |
| `lib/data/guest_import.dart` | Merges local guest records into an account without duplicating them. |
| `lib/data/heading_case.dart` | App heading capitalisation. |

**State-management answer for the presentation:** Provider distributes the shared `Notebook` to screens. Its `notifyListeners()` calls refresh consumers after CRUD and preference changes. Short-lived form fields use `StatefulWidget`/`setState`. The running AI job uses its own `ChangeNotifier`, observed by `AnimatedBuilder`, because it is independent of notebook records until a set is saved.

## AI, device, and account services

| File | Responsibility |
| --- | --- |
| `lib/services/source_notes.dart` | Picks a PDF, extracts readable numbered pages through Android, validates file/page limits, and fingerprints the notes. |
| `lib/services/generation_input.dart` | Keeps very dense extracted pages within a bounded request size by sampling beginning, middle, and end. Classifies temporary failures for retry. |
| `lib/services/generation.dart` | Plans batches, checks daily allowance, calls Firebase AI Logic, retries temporary failures once, checkpoints completed batches, and saves the draft set. |
| `lib/services/generation_draft.dart` | Checks a model answer against an exact quote from its numbered page and converts accepted answers to question records. The app does not make a second AI verification call. |
| `lib/services/generation_cancellation.dart` | Cancellation signal; stops waiting for an active call and prevents subsequent batches. An already-sent Gemini request cannot be recalled. |
| `lib/services/generation_job.dart` | Visible job lifecycle and user-facing status. Cancelling discards local partial drafts and releases the lock. |
| `lib/services/generation_background.dart` | Android foreground notification/execution while the user switches apps. |
| `lib/services/answer_feedback.dart` | Optional AI feedback on a written practice answer; separate from PDF generation. |
| `lib/services/account_auth.dart` | Account authentication helpers. |
| `lib/services/reminders.dart` | Daily revision notification scheduling. |
| `lib/services/device_time_zone.dart` | Device time zone for reminders. |
| `lib/services/font_licenses.dart` | Registers bundled font licence notices. |

## Screen inventory

These are **25 screen widgets**, exceeding the brief's minimum of 10. Some are reached through a tab and others through `Navigator` routes. Small reusable widgets are listed separately below.

| Screen/widget | File | Purpose |
| --- | --- | --- |
| Splash | `lib/ui/splash_page.dart` | Startup and initialization error. |
| Sign In / Register | `lib/ui/auth_page.dart` | Guest, Google, email login, and account creation. |
| Profile Setup | `lib/ui/profile_setup_page.dart` | First-use display name and education level. |
| Tutorial | `lib/ui/tutorial_page.dart` | First-use walkthrough with Skip. |
| Home | `lib/ui/home_page.dart` | Daily revision, subjects, exams, bottom navigation. |
| Subjects | `lib/ui/subjects_page.dart` | Subject folder grid. |
| Subject Detail | `lib/ui/subjects_page.dart` | Subject actions and chapters. |
| Chapter Detail | `lib/ui/chapter_page.dart` | Chapter questions and study actions. |
| Add Question Choice | `lib/ui/create_question_page.dart` | Manual entry, PDF, or pasted notes. |
| Question Editor | `lib/ui/question_editor.dart` | Add/edit a manual or generated question. |
| Question Bank | `lib/ui/question_bank_page.dart` | Search, filter, and move questions. |
| Create from Notes | `lib/ui/upload_page.dart` | Select PDF/text, pages, difficulty, count, and language. AI chooses the question type. |
| Review Question Set | `lib/ui/review_page.dart` | Inspect, edit, approve, and finalise generated drafts. |
| Note Reviews | `lib/ui/note_reviews_page.dart` | Open generated question sets. |
| Read & Learn | `lib/ui/learning_page.dart` | Flashcards and recall ratings. |
| Practice | `lib/ui/practice_page.dart` | Choose practice format. |
| Revision | `lib/ui/revision_page.dart` | Written and structured revision session. |
| Needs Attention | `lib/ui/attention_page.dart` | Weakness-based revision. |
| Progress | `lib/ui/progress_page.dart` | Study metrics and recent history. |
| Revision History | `lib/ui/revision_history_page.dart` | Session history list. |
| Session Details | `lib/ui/revision_history_page.dart` | Attempts in one session. |
| Exam Goals | `lib/ui/exams_page.dart` | Exam list and actions. |
| Exam Editor | `lib/ui/exam_editor_page.dart` | Add/edit an exam goal. |
| Profile and Settings | `lib/ui/profile_page.dart` | Appearance, reminders, account controls. |
| About AskAgain | `lib/ui/about_page.dart` | Purpose, credits, and package licences. |

Reusable UI files: `lib/ui/common.dart` (navigation and dialog helpers), `app_theme.dart` and `app_palette.dart` (visual theme), `chapter_selector.dart` and `chapter_section.dart` (chapter widgets), `subject_folders.dart` (consistent folder grid), `generation_status.dart` (job icon/dialog), `structured_answer.dart` (blanks/matching input), `study_language_selector.dart` (language field), and `study_text_scaler.dart` (accessibility scaling).

## Firebase model and platform files

- `lib/data/notebook.dart` reads and writes `users/{uid}/records/{recordId}`. Records use `kind` values such as `profile`, `subject`, `chapter`, `question`, `document`, `exam`, and `attempt`. The same collection also holds generation usage/lock/trial records.
- `firestore.rules` restricts each user subtree to its authenticated UID. Authentication includes guest/anonymous and registered accounts.
- `android/app/src/main/kotlin/com/shanthini/askagain/MainActivity.kt` bridges Android PDF text extraction to Flutter's `askagain/pdf` method channel.
- `pubspec.yaml` lists Flutter packages and bundled fonts. `assets/fonts/SOURCES.md` and `lib/ui/about_page.dart` provide third-party licence information.
- `test/` contains domain checks and Flutter tests. Run analysis and tests before producing a new APK.

## CSM3114 Section 4 checklist

| Requirement | App evidence | Status |
| --- | --- | --- |
| Flutter and at least 10 screens | `pubspec.yaml`, 25 screen widgets above | Implemented |
| Navigator and Drawer and/or bottom navigation | `BuildContext.open`/`Navigator` in `lib/ui/common.dart`; four-destination `NavigationBar` in `lib/ui/home_page.dart` | Implemented |
| Provider state management | `ChangeNotifierProvider.value` in `lib/main.dart`, `Notebook extends ChangeNotifier` | Implemented |
| Forms with validation for every user input | Required account, profile, question, and exam fields have validation; PDF size, readable text, page range, and generation choices are checked. Optional study text and filter inputs use lighter checks. A literal every-field validation claim needs a final UI audit. | Substantially implemented; audit before submission |
| Dynamic ListView or GridView | `PageBody` uses `ListView`; question, exam, and history pages build data-driven lists. Subject folders use a responsive two-column `Wrap`. | Implemented |
| Firebase Authentication and Firestore CRUD | `Notebook` uses Firebase Auth and Firestore record reads, batched writes, updates, and deletions; `firestore.rules` protects user records | Implemented; verify with the demo account |
| Original work; list packages | Package list in `pubspec.yaml`; About screen opens licence list. Originality must be attested by the developer, not inferred from a code scan. | Package disclosure implemented; originality is a submission responsibility |

The brief separately requires proposal and report content, diagrams, testing evidence, a business analysis, and a 1–5 minute video demo. Those are **submission deliverables**, not Flutter screens. Existing wireframe/navigation PDFs are in `output/pdf/`; review them against the final interface. The written report must include a use-case diagram, widget tree, navigation flow, Firestore model, tests with expected and actual results, APA references, and the specified formatting. A successful build alone does not establish those deliverables.

## Demo explanation and limits

- **Innovation:** Note-to-question drafting with source-page evidence combined with active recall, spaced repetition, multiple practice modes, and weakness-based revision.
- **Data choice:** Firebase Authentication identifies a user; Firestore records are grouped by UID for synchronisation. Local preferences support guest use and device appearance settings.
- **AI limit:** Gemini availability and the project's free quota are external. A 503 can still occur. A Cancel action stops the app job immediately, but a request already sent to Gemini may still complete and consume quota. Generated material remains a draft for user review.
- **Security limit:** Current Firestore rules isolate users but do not enforce a server-side generation budget or schema. The client quota is suitable for the assignment demo; a public release needs trusted server-side limits.

## Maintainability notes

The source is organised by data rules, services, and UI screens. In this change, source validation and record construction moved into `generation_draft.dart`, cancellation into `generation_cancellation.dart`, and the generation page no longer carries a large question-type options table. This keeps the UI, job state, and model workflow separate.

Some existing files are still relatively long: `revision_page.dart` (session UI), `notebook.dart` (shared persistence and state), and `upload_page.dart` (note form). Length alone does not mean spaghetti code, but those are the first places to split into smaller widgets or repositories if future features make them harder to navigate. Avoid a broad rewrite before the assignment demo because it would put working revision behaviour at risk.
