import 'package:flutter/material.dart';

import '../../app/routes.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final controller = PageController();
  int page = 0;

  final slides = const [
    ('Save from anywhere', 'Instagram reels, LinkedIn posts, YouTube videos, PDFs, links and notes - all saved into one vault.', Icons.ios_share_rounded),
    ('Organized automatically', 'Vaultly suggests collections and tags so your saved content never becomes messy.', Icons.auto_awesome_rounded),
    ('Find it later', 'Search across everything you saved - links, videos, notes, PDFs and documents.', Icons.manage_search_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.pushReplacementNamed(context, AppRoutes.firstCollection),
                  child: const Text('Skip'),
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: controller,
                  onPageChanged: (value) => setState(() => page = value),
                  itemCount: slides.length,
                  itemBuilder: (context, index) {
                    final slide = slides[index];
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 128,
                          height: 128,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(36),
                          ),
                          child: Icon(slide.$3, size: 58, color: Theme.of(context).colorScheme.primary),
                        ),
                        const SizedBox(height: 36),
                        Text(slide.$1, textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800)),
                        const SizedBox(height: 14),
                        Text(slide.$2, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyLarge),
                      ],
                    );
                  },
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < slides.length; i++)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      margin: const EdgeInsets.all(4),
                      width: i == page ? 26 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: i == page ? Theme.of(context).colorScheme.primary : Theme.of(context).dividerColor,
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    if (page == slides.length - 1) {
                      Navigator.pushReplacementNamed(context, AppRoutes.firstCollection);
                    } else {
                      controller.nextPage(duration: const Duration(milliseconds: 240), curve: Curves.easeOut);
                    }
                  },
                  child: Text(page == slides.length - 1 ? 'Create my vault' : 'Continue'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
