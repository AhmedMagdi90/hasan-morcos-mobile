import 'package:flutter/material.dart';

import '../models/branch.dart';
import '../services/api_client.dart';

class BranchSelectionScreen extends StatefulWidget {
  const BranchSelectionScreen({
    required this.apiClient,
    required this.onBranchSelected,
    required this.onLogout,
    super.key,
  });

  final ApiClient apiClient;
  final ValueChanged<Branch> onBranchSelected;
  final VoidCallback onLogout;

  @override
  State<BranchSelectionScreen> createState() => _BranchSelectionScreenState();
}

class _BranchSelectionScreenState extends State<BranchSelectionScreen> {
  late Future<List<Branch>> branchesFuture;

  @override
  void initState() {
    super.initState();
    branchesFuture = widget.apiClient.fetchBranches();
  }

  Future<void> refreshBranches() async {
    final nextFuture = widget.apiClient.fetchBranches();

    setState(() {
      branchesFuture = nextFuture;
    });

    try {
      await nextFuture;
    } catch (_) {
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Choose Branch'),
        actions: [
          IconButton(
            tooltip: 'Refresh branches',
            icon: const Icon(Icons.refresh),
            onPressed: refreshBranches,
          ),
          IconButton(
            tooltip: 'Switch customer',
            icon: const Icon(Icons.logout),
            onPressed: widget.onLogout,
          ),
        ],
      ),
      body: FutureBuilder<List<Branch>>(
        future: branchesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Cannot load branches: ${snapshot.error}'),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: refreshBranches,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }

          final branches = snapshot.data ?? [];

          if (branches.isEmpty) {
            return RefreshIndicator(
              onRefresh: refreshBranches,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 160),
                  Center(child: Text('No branches available.')),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: refreshBranches,
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemBuilder: (context, index) {
                final branch = branches[index];

                return Card(
                  child: ListTile(
                    title: Text(branch.displayName),
                    subtitle: Text([branch.city, branch.address].where((value) => value.isNotEmpty).join(' - ')),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => widget.onBranchSelected(branch),
                  ),
                );
              },
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemCount: branches.length,
            ),
          );
        },
      ),
    );
  }
}
