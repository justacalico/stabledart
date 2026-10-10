import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../models/civit_models.dart';
import '../../../state/model_browser_store.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/number_format.dart';
import '../../widgets/app_network_image.dart';
import '../civit_detail_page.dart';

class CivitAiBrowserView extends StatefulWidget {
  const CivitAiBrowserView({super.key});

  @override
  State<CivitAiBrowserView> createState() => _CivitAiBrowserViewState();
}

class _CivitAiBrowserViewState extends State<CivitAiBrowserView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final store = context.read<CivitAiBrowserStore>();
      if (store.status == LoadStatus.idle) store.search();
    });
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<CivitAiBrowserStore>();
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: 260,
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: 'Search CivitAI',
                    prefixIcon: Icon(Icons.search, size: 20),
                  ),
                  onChanged: store.setQuery,
                  onSubmitted: (_) => store.search(),
                ),
              ),
              _Dropdown<CivitModelType>(
                value: store.type,
                hint: 'Type',
                items: [
                  for (final t in CivitModelType.values)
                    DropdownMenuItem(value: t, child: Text(t.displayName)),
                ],
                onChanged: (v) => store.setType(v ?? CivitModelType.all),
              ),
              _Dropdown<CivitSort>(
                value: store.sort,
                hint: 'Sort',
                items: [
                  for (final s in CivitSort.values)
                    DropdownMenuItem(value: s, child: Text(_sortName(s))),
                ],
                onChanged: (v) => store.setSort(v ?? CivitSort.mostDownloaded),
              ),
              _Dropdown<CivitPeriod>(
                value: store.period,
                hint: 'Period',
                items: [
                  for (final p in CivitPeriod.values)
                    DropdownMenuItem(value: p, child: Text(_periodName(p))),
                ],
                onChanged: (v) => store.setPeriod(v ?? CivitPeriod.allTime),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('NSFW', style: TextStyle(fontSize: 12)),
                  Switch(value: store.nsfw, onChanged: store.setNsfw),
                ],
              ),
            ],
          ),
        ),
        Expanded(child: _buildBody(store)),
      ],
    );
  }

  String _sortName(CivitSort s) => switch (s) {
    CivitSort.highestRated => 'Highest Rated',
    CivitSort.mostDownloaded => 'Most Downloaded',
    CivitSort.mostLiked => 'Most Liked',
    CivitSort.mostDiscussed => 'Most Discussed',
    CivitSort.newest => 'Newest',
    CivitSort.oldest => 'Oldest',
  };

  String _periodName(CivitPeriod p) => switch (p) {
    CivitPeriod.allTime => 'All Time',
    CivitPeriod.year => 'Year',
    CivitPeriod.month => 'Month',
    CivitPeriod.week => 'Week',
    CivitPeriod.day => 'Day',
  };

  Widget _buildBody(CivitAiBrowserStore store) {
    switch (store.status) {
      case LoadStatus.idle:
      case LoadStatus.loading:
        return const Center(child: CircularProgressIndicator());
      case LoadStatus.failed:
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                store.errorMessage ?? 'Failed to load',
                style: const TextStyle(color: AppColors.red),
              ),
              const SizedBox(height: 12),
              FilledButton(onPressed: store.search, child: const Text('Retry')),
            ],
          ),
        );
      case LoadStatus.success:
        if (store.models.isEmpty) {
          return const Center(child: Text('No models found'));
        }
        return Column(
          children: [
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(24),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 260,
                  mainAxisExtent: 280,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                ),
                itemCount: store.models.length,
                itemBuilder: (context, i) =>
                    _CivitModelCard(model: store.models[i]),
              ),
            ),
            if (store.canLoadMore)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: OutlinedButton(
                  onPressed: store.loadMore,
                  child: const Text('Load More'),
                ),
              ),
          ],
        );
    }
  }
}

class _CivitModelCard extends StatelessWidget {
  final CivitModel model;

  const _CivitModelCard({required this.model});

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => CivitDetailPage(model: model)),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: SizedBox(
                width: double.infinity,
                child: AppNetworkImage(url: model.thumbnailUrl),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    model.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          model.type,
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.accent,
                          ),
                        ),
                      ),
                      const Spacer(),
                      const Icon(
                        Icons.download,
                        size: 13,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        formatNumber(
                          model.downloadCount,
                          NumberFormatMode.comma,
                        ),
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Dropdown<T> extends StatelessWidget {
  final T value;
  final String hint;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  const _Dropdown({
    required this.value,
    required this.hint,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.border),
      ),
      child: DropdownButton<T>(
        value: value,
        items: items,
        onChanged: onChanged,
        underline: const SizedBox(),
        isDense: true,
        style: const TextStyle(fontSize: 13),
      ),
    );
  }
}
