import 'package:material_ui/material_ui.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'common.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('About AskAgain')),
    body: PageBody([
      const Center(child: Icon(Icons.menu_book_rounded, size: 72)),
      const Center(child: TitleLine('AskAgain')),
      Center(
        child: FutureBuilder<PackageInfo>(
          future: PackageInfo.fromPlatform(),
          builder: (_, snapshot) => Text(
            snapshot.hasData
                ? 'Version ${snapshot.data!.version} (${snapshot.data!.buildNumber})'
                : 'Version information unavailable',
          ),
        ),
      ),
      const TitleLine('About the App'),
      const Text(
        'AskAgain helps university learners remember course material through active recall and spaced revision. It supports UN Sustainable Development Goal 4: Quality Education.',
      ),
      const TitleLine('Study Features'),
      const Text(
        'Create Q&A manually or generate draft questions from readable PDF and pasted notes. Read flashcards, practise written answers, fill in the blanks and matching, then review questions again when they are due.',
      ),
      const TitleLine('Academic Project'),
      const Text(
        'Developed by Shanthini Nadeson for CSM3114 Framework Based Mobile Application Development, Fakulti Sains Komputer dan Matematik (FSKM), Universiti Malaysia Terengganu (UMT).',
      ),
      const TitleLine('Built With'),
      const Text(
        'Flutter, Dart, Provider, Firebase Authentication, Cloud Firestore and Firebase AI Logic.',
      ),
      OutlinedButton.icon(
        onPressed: () =>
            showLicensePage(context: context, applicationName: 'AskAgain'),
        icon: const Icon(Icons.info_outline),
        label: const Text('Third-Party Packages & Licenses'),
      ),
      const TitleLine('Study Accuracy'),
      const Text(
        'Check generated answers and extracted notes against your official course materials before studying from them.',
      ),
    ]),
  );
}
