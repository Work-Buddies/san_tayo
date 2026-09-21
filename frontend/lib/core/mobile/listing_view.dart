import 'package:flutter/material.dart';

/// Placeholder listing page. Receives the listing id from dashboard cards.
class ListingView extends StatelessWidget {
  final String listingId;

  const ListingView({
    super.key,
    required this.listingId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        title: const Text('Listing'),
      ),
      body: Center(
        child: Text(
          listingId,
          style: Theme.of(context).textTheme.titleLarge,
        ),
      ),
    );
  }
}
