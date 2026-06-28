import 'package:flutter/material.dart';

import '../models/branch.dart';
import '../services/api_client.dart';

class BranchSelectionScreen extends StatelessWidget {
  const BranchSelectionScreen({
    required this.apiClient,
    required this.onBranchSelected,
    super.key,
  });

  final ApiClient apiClient;
  final ValueChanged<Branch> onBranchSelected;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Choose Branch')),
      body: FutureBuilder<List<Branch>>(
        future: apiClient.fetchBranches(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Cannot load branches: ${snapshot.error}'));
          }

          final branches = snapshot.data ?? [];

          if (branches.isEmpty) {
            return const Center(child: Text('No branches available.'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemBuilder: (context, index) {
              final branch = branches[index];

              return Card(
                child: ListTile(
                  title: Text(branch.displayName),
                  subtitle: Text([branch.city, branch.address].where((value) => value.isNotEmpty).join(' - ')),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => onBranchSelected(branch),
                ),
              );
            },
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemCount: branches.length,
          );
        },
      ),
    );
  }
}
