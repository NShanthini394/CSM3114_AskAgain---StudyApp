# AskAgain

An Android revision notebook for an adult university assignment demo, application ID `com.shanthini.askagain`. Open the folder containing `pubspec.yaml` in Android Studio. Run with Flutter 3.50 and Dart 3.14, using an Android phone with USB debugging enabled. Select the phone and run `lib/main.dart`.

## Try it without Firebase

Select **Try as guest** on the sign-in page. Complete the editable display name and education level. Add a subject and a question, then select **Read & Learn** or **Practice**. Existing local notebooks are retained. Their profiles need the one-time setup when updating from version 1.0.1.

The sign-in page includes Google, email/password and registration. These account actions and automatic generation need Firebase configuration. Guest mode remains available to explore the interface before configuration.

The question editor contains Question, Answer and Chapter. Use **View questions** to search, edit and move questions. Choose written/problem solving, fill-in-the-blanks or matching when starting practice. Structured exercises are derived from saved Q&A without replacing the original content. Existing numerical answer keys remain available when the saved answer has not changed.

Guests get one successful generated set per anonymous account. A completed trial is recorded together with the set, so failures do not consume it. A second upload prompts sign-in. Registration upgrades the anonymous identity. Signing into an existing account imports new guest records while retaining the existing account profile and avoiding duplicate document histories. This trial is tied to the anonymous account, not a global identity across devices or reinstalls.

Settings provides sign-in for guests, logout for registered users, and confirmed deletion. Registered deletion requests fresh Google authentication or the current password before deleting cloud records and the Firebase identity.

## Connect the university demo to Firebase

1. Open the [Firebase console](https://console.firebase.google.com/) and create a project named AskAgain. Analytics is optional. Keep the no-cost Spark plan and do not link Cloud Billing for the selected free-tier setup. See [Firebase AI Logic pricing](https://firebase.google.com/docs/ai-logic/pricing).
2. In Project settings > General, add an Android app with package name `com.shanthini.askagain` and nickname AskAgain Android. Register the app. Add the debug certificate fingerprints below to this Android app's SHA certificate fingerprints. These are public fingerprints extracted from the current testing APK, not passwords or signing keys.

   SHA-1: `33:52:0E:59:10:B4:CC:36:73:AC:1A:5C:5D:A1:DA:57:DE:22:E3:70`

   SHA-256: `00:35:6F:11:80:74:0B:AB:A8:76:13:B9:B0:45:EF:E9:B7:6F:3C:2A:6C:12:EB:85:44:FA:39:59:D9:81:07:D7`

3. In Authentication > Sign-in method, enable Email/Password, Google and Anonymous. For Google, choose a support email and save. Then return to Project settings > General > Your apps and download the updated `google-services.json`. It must include the Google web OAuth client, so download it after enabling Google. Save it at `C:\Users\shant\Downloads\GP\FW\askagain\android\app\google-services.json`, without a `(1)` suffix. The app already loads Android configuration through its Gradle build; do not duplicate console SDK snippets or add a private service-account key. See [Android configuration](https://firebase.google.com/docs/android/setup) and [Google sign-in](https://firebase.google.com/docs/auth/flutter/federated-auth).
4. In Firestore Database, create the `(default)` database using Standard edition. Singapore (`asia-southeast1`) is a nearby option for Malaysia. Start in production mode, open Rules, replace the rules with this repository's complete `firestore.rules`, and Publish. These rules allow each signed-in identity, including anonymous guests, access to its own notebook. See [Firestore setup](https://firebase.google.com/docs/firestore/quickstart) and [locations](https://firebase.google.com/docs/firestore/locations).
5. Open AI Services > AI Logic > Get started. Choose Gemini Developer API and let the wizard enable its required APIs and associated resources. The app uses Firebase AI Logic rather than embedding a separate Gemini API secret. Its default model is `gemini-3.8-flash`, currently listed among supported models without required billing. See [AI Logic setup](https://firebase.google.com/docs/ai-logic/get-started?platform=flutter) and [supported models](https://firebase.google.com/docs/ai-logic/models).
6. After the configuration file is saved, rebuild and install the connected debug APK over the existing app. Connect the phone with USB debugging, open Android Studio > Logcat, select the phone and search for `DebugAppCheckProvider`. In Firebase Security > App Check > Apps, open the Android app's three-dot menu > Manage debug tokens and add the token from that log. Keep this token private. AI Logic now enforces App Check as part of setup; generation will not work until the test device is registered. No emulator is needed. See [App Check debug setup](https://firebase.google.com/docs/app-check/flutter/debug-provider). Production distribution uses Play Integrity instead of debug tokens.
7. Try guest mode, email registration and Google sign-in. Check Authentication > Users and Firestore records. Generate a small, selectable-text PDF first, review evidence and finalise the set. Test reminders from Profile, allow notifications, leave a question due and tap the reminder to choose a revision mode. Delivery uses Android's inexact scheduling.

## Study and practice in version 1.7.4

- A subject contains chapters and an Unassigned chapter for older questions. Add or rename chapters from the subject page. Removing a chapter moves its content to Unassigned. In View questions, select questions and use Move to chapter.
- Home, Subjects and Revise by Subject use the same shaded folder grid in two columns, with a single column for narrow screens or very large accessibility text. A colour index stored with each subject keeps its folders and Learn & Recall cards consistent through renaming, deletion of other subjects, reordering and reopening. Existing subjects receive their former list-index colours on upgrade. Upcoming exams retain their list layout. The Revision tab's subject folders open the practice-format chooser.
- Both themes use explicit card fills and outlined borders to separate learning, attention and progress cards from the page background.
- Settings offers Inter (default), Roboto, Open Sans, Lexend and Libre Baskerville, plus Small (90%), Standard (100%), Large (115%) and Extra large (130%) text sizes. Preferences apply immediately throughout the app and persist on the phone. Text size multiplies Android's accessibility scaling. Very long content remains scrollable; the learning card uses its compact layout on short screens.
- General practice difficulties are Forgot and Confused Concepts. The former Incomplete answer option is removed from new attempts; existing history is preserved. Maths and code retain their specialised difficulty choices. App-owned headings use title case with short linking words such as by, of and and lowercased. User-authored study text and names retain their original spelling and case.
- Font assets are bundled for offline use, with regular, semibold and bold weights. Licences are accessible inside Settings > About AskAgain rather than through a standalone settings shortcut. Bundled copyright and licence notices are retained. See `assets/fonts/SOURCES.md` and the pinned preparation script `tool/prepare_fonts.py`.
- Home's Start Revision, the Revision tab's Open Revision and reminder taps all open the format chooser for due questions only. An empty daily queue shows a clear message and disabled mode buttons. Exam subject revision also opens the chooser. Subject/chapter practice remains available for all questions in that scope, including future reviews.
- Both subject and chapter overviews offer Read & Learn and Practice. Subject sessions cover the whole subject; chapter sessions cover only the selected chapter. Note generation drafts are accessible through the subject toolbar's Note reviews button.
- Read & Learn presents one card at a time with completed/total progress. Short questions and answers are centred in the available content area; longer paragraphs and code remain readable and scrollable. Show answer flips the card. Fully remembered, Partially remembered and Didn't remember record recall and advance to the next card. Full recall on three separate dates earns mastery; repeated ratings on the same day do not inflate it. Forgetting resets this run.
- Tapping a practice format immediately starts a shuffled session using all suitable questions in scope. Fill-in-the-blanks is derived locally from saved answers; original words are the case-insensitive answer keys. Programming, numerical and unsuitable long answers are excluded from this format, with an explanation shown.
- Matching automatically groups all suitable distinct short Q&A into rounds of 2–4. Tap a left question and a right answer to pair them. Both share a colour and pair number. Tap a paired box to unpair it. Submit before seeing correctness. Duplicate or unsuitable pairs are excluded and reported.
- Derived practice updates the original question schedules without replacing their text. Matching applies the student's recall rating to the source questions in the round.
- Progress shows the latest three sessions. View history opens the full history, grouped by session, subject and chapter. Older attempts are grouped by day and subject.
- Needs attention is on the Revision tab. Tap a difficulty to see its questions with subject and chapter, learn an individual question, or learn/practise the whole filtered group. Each current question counts once, using its latest practice difficulty. A subsequent practice attempt replaces that difficulty; mastery removes the question from the list. Recall sessions do not erase practice difficulties. New matching attempts retain all source question links; older attempts use their existing single question reference.
- Written answers have self-assessed answer checkpoints and an optional Check my answer with AI action. That action sends the response and scheme to Gemini after confirmation and uses an additional request. It needs Firebase configuration. AI feedback is advisory and does not set the recall rating.
- Profile setup only asks for display name and education level. Optional Q&A language selection is on the generation page and starts at Same as uploaded notes for each new visit. Choices also include English, Bahasa Melayu, Tamil and Simplified Chinese. Generation instructions explicitly follow each source passage's language by default, including multilingual documents, or the selected translation language. Evidence stays in its original language. App menus remain English.

## Source processing

Text extraction runs on the phone using Android PDFBox. The selected text goes to Gemini on confirmation. Image-only PDFs, handwriting and image-only equations require transcription. Each batch uses one generation request and checks returned source quotes locally, without a second AI verification request. Dense pages are sampled from their beginning, middle and end so each request stays within a text budget. Choose a narrower page range when complete coverage of dense pages matters. A temporary 502/503/504 error or timeout triggers at most one automatic retry after 15 seconds. Each attempt counts against the daily allowance. Review and edit generated material before studying it. Unsupported items can reduce the returned count. Generated references use original PDF page numbers. The app does not retain the full PDF in cloud storage.

The generation form no longer asks students to choose question types; Gemini infers an appropriate type from the material. The progress dialog has Close (keep working) and Cancel (stop the job). Cancel prevents further batches, discards the job's saved partial draft, and releases its lock. An already-sent Gemini request may still complete or count against quota because the Firebase AI Logic SDK does not expose cancellation for that request.

Per user: one active generation and up to 16 attempted generation requests per local calendar day. Per document: 80 meaningful pages and up to 100 questions subject to a content-based cap. A completed set cannot be regenerated. After interruption choose the same document and settings to use saved batches. The generation lock lasts ten minutes and is renewed before each AI attempt. Cloud service quotas also apply. Client-enforced quotas are designed for this assignment demo; a public service should enforce budgets at a trusted server boundary.

## Structure and checks

- `lib/ui` contains the individual screens and shared navigation/form widgets.
- `lib/data` handles notebook persistence and review intervals.
- `lib/services` handles source extraction, generation and reminders.
- `android/app/src/main/kotlin` contains the Android PDF reader bridge.
- `test/study_flow_test.dart` covers persistence, source limits and programming answer reveal.
- Standalone `test/*checks.dart` scripts cover scheduling, exercise derivation, shuffling, scope, language migration and other domain logic. Run each with Dart; these do not require the Flutter test runner.
- `pubspec.yaml` lists the packages. Android PDFBox is declared in the app Gradle file.

Run `flutter analyze`, `flutter test` and `flutter build apk --debug`. The APK is for device testing. Play Store distribution requires your release signing configuration and a separate review of the audience, AI terms, data disclosures and account deletion.

See `docs/CODE_GUIDE.md` for the screen inventory, code responsibilities, state management explanation, and CSM3114 requirement map. Live Gemini reliability still depends on Google's service availability and remaining project quota.

See [Firebase AI Logic setup](https://firebase.google.com/docs/ai-logic/get-started), [App Check debug provider](https://firebase.google.com/docs/app-check/flutter/debug-provider) and [Gemini API terms](https://ai.google.dev/gemini-api/terms).
