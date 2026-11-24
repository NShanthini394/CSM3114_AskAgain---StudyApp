import 'package:material_ui/material_ui.dart';

import '../services/generation_job.dart';
import 'common.dart';
import 'review_page.dart';

class GenerationStatusAction extends StatelessWidget {
  const GenerationStatusAction({super.key});

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: GenerationJob.instance,
    builder: (context, _) {
      final job = GenerationJob.instance;
      if (!job.visible) return const SizedBox.shrink();
      return IconButton(
        tooltip: job.running
            ? 'Question generation progress'
            : 'Question generation result',
        icon: Stack(
          alignment: Alignment.center,
          children: [
            Icon(
              job.error != null
                  ? Icons.error_outline
                  : job.resultId != null
                  ? Icons.check_circle_outline
                  : Icons.auto_awesome,
            ),
            if (job.running)
              SizedBox(
                width: 31,
                height: 31,
                child: CircularProgressIndicator(
                  value: job.progress,
                  strokeWidth: 2,
                ),
              ),
          ],
        ),
        onPressed: () => showDialog<void>(
          context: context,
          builder: (dialog) => AnimatedBuilder(
            animation: job,
            builder: (dialog, _) => AlertDialog(
              title: const Text('Creating Questions'),
              scrollable: true,
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(job.stage),
                  const SizedBox(height: 16),
                  LinearProgressIndicator(value: job.progress),
                  const SizedBox(height: 8),
                  Text(
                    job.totalBatches == 0
                        ? 'Preparing…'
                        : '${job.completedBatches} of ${job.totalBatches} batches complete',
                  ),
                  if (job.error != null) ...[
                    const SizedBox(height: 16),
                    Text(job.error!),
                  ],
                ],
              ),
              actions: [
                if ((job.running || job.error != null) &&
                    !job.cancelling &&
                    job.stage != 'Saving question set…')
                  TextButton(
                    onPressed: () {
                      job.cancel();
                      Navigator.pop(dialog);
                    },
                    child: const Text('Cancel'),
                  ),
                TextButton(
                  onPressed: () => Navigator.pop(dialog),
                  child: const Text('Close'),
                ),
                if (job.error != null)
                  TextButton(
                    onPressed: job.coolingDown
                        ? null
                        : () {
                            Navigator.pop(dialog);
                            job.retry();
                          },
                    child: const Text('Retry'),
                  ),
                if (job.resultId != null)
                  FilledButton(
                    onPressed: () {
                      final id = job.resultId!;
                      Navigator.pop(dialog);
                      job.dismiss();
                      context.open(ReviewPage(id: id));
                    },
                    child: const Text('Review Questions'),
                  ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
