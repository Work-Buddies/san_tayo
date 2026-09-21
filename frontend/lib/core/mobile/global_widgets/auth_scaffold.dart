import 'package:flutter/material.dart';

/// Logo, wordmark and motto block shown above the form panel.
class BrandHeader extends StatelessWidget {
  const BrandHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        spacing: 16,
        children: [
          Image.asset(
            'assets/images/logo/logo.png',
            height: 100,
          ),
          Column(
            children: [
              Text("Sa'n Tayo?",
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              Text("\"Application Motto Insert Here!\"",
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Brand header on top, maroon form panel pinned below it. The whole page scrolls
/// once the keyboard opens so the taller Sign Up form never overflows.
class AuthScaffold extends StatelessWidget {
  final List<Widget> panelChildren;

  const AuthScaffold({
    super.key,
    required this.panelChildren,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Column(
                  children: [
                    const Expanded(child: BrandHeader()),
                    Container(
                      width:   double.infinity,
                      padding: const EdgeInsets.fromLTRB(32, 36, 32, 32),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: const BorderRadius.only(
                          topLeft:  Radius.circular(40),
                          topRight: Radius.circular(40),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: panelChildren,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
