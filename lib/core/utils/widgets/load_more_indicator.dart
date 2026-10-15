import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../app_colors.dart';

/// The extra last row of a paged `SliverList.builder`. Sliver lists build
/// rows only as they come near the viewport, so this row being built means
/// the user scrolled to the end of the loaded rows: it asks for the next
/// page once. If that load fails it offers a retry instead of looping.
class LoadMoreIndicator extends StatefulWidget {
  const LoadMoreIndicator({
    super.key,
    required this.isLoading,
    required this.onLoadMore,
  });

  final bool isLoading;
  final VoidCallback onLoadMore;

  @override
  State<LoadMoreIndicator> createState() => _LoadMoreIndicatorState();
}

class _LoadMoreIndicatorState extends State<LoadMoreIndicator> {
  @override
  void initState() {
    super.initState();
    if (!widget.isLoading) {
      // Not during build: loading more emits a new cubit state.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.onLoadMore();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: widget.isLoading
            ? const CircularProgressIndicator(color: AppColors.green)
            : TextButton(
                style: TextButton.styleFrom(foregroundColor: AppColors.green),
                onPressed: widget.onLoadMore,
                child: Text('Load more'.tr),
              ),
      ),
    );
  }
}
