import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../widgets/song_tile.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  late final TextEditingController _queryController;

  @override
  void initState() {
    super.initState();
    _queryController = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final query = AppScope.of(context).searchQuery;
    if (_queryController.text.isEmpty && query.isNotEmpty) {
      _queryController.text = query;
    }
  }

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    return CustomScrollView(
      slivers: <Widget>[
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 14),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('搜索音乐', style: Theme.of(context).textTheme.displaySmall),
                const SizedBox(height: 8),
                const Text('试听来自 iTunes，开放授权曲目来自 Internet Archive。'),
                const SizedBox(height: 22),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 760),
                  child: Semantics(
                    textField: true,
                    label: '搜索歌曲或歌手',
                    child: SearchBar(
                      controller: _queryController,
                      hintText: '输入歌名、歌手或关键词',
                      leading: const Icon(Icons.search),
                      trailing: <Widget>[
                        if (_queryController.text.isNotEmpty)
                          IconButton(
                            tooltip: '清空',
                            onPressed: () {
                              setState(_queryController.clear);
                              controller.search('');
                            },
                            icon: const Icon(Icons.close),
                          ),
                      ],
                      onSubmitted: controller.search,
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: <Widget>[
                    for (final query in const <String>[
                      '华语流行',
                      '轻音乐',
                      '爵士',
                      '运动',
                    ])
                      ActionChip(
                        label: Text(query),
                        onPressed: () {
                          _queryController.text = query;
                          controller.search(query);
                        },
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 12),
          sliver: SliverToBoxAdapter(
            child: _GequbaoNotice(
              onOpen: () => controller.openGequbaoSearch(_queryController.text),
            ),
          ),
        ),
        if (controller.isSearching)
          const SliverFillRemaining(
            hasScrollBody: false,
            child: Center(child: CircularProgressIndicator()),
          )
        else if (controller.searchError != null)
          SliverFillRemaining(
            hasScrollBody: false,
            child: Semantics(
              liveRegion: true,
              child: _SearchMessage(
                icon: Icons.search_off_rounded,
                title: '没有可显示的结果',
                message: controller.searchError!,
                onRetry: controller.searchQuery.isEmpty
                    ? null
                    : () => controller.search(controller.searchQuery),
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 4, 24, 32),
            sliver: SliverList.separated(
              itemCount: controller.searchResults.length,
              itemBuilder: (context, index) {
                final song = controller.searchResults[index];
                return SongTile(song: song, queue: controller.searchResults);
              },
              separatorBuilder: (_, _) => const SizedBox(height: 8),
            ),
          ),
      ],
    );
  }
}

class _GequbaoNotice extends StatelessWidget {
  const _GequbaoNotice({required this.onOpen});

  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 920),
    child: Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Wrap(
          spacing: 16,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: <Widget>[
            Icon(
              Icons.open_in_browser,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(
              width: 560,
              child: Text(
                '歌曲宝未提供公开 API，且程序请求会被拒绝。为避免不稳定抓取和未经授权下载，仅在系统浏览器中打开用户主动发起的搜索。',
              ),
            ),
            OutlinedButton.icon(
              onPressed: onOpen,
              icon: const Icon(Icons.open_in_new),
              label: const Text('用歌曲宝网页搜索'),
            ),
          ],
        ),
      ),
    ),
  );
}

class _SearchMessage extends StatelessWidget {
  const _SearchMessage({
    required this.icon,
    required this.title,
    required this.message,
    this.onRetry,
  });

  final IconData icon;
  final String title;
  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 52),
          const SizedBox(height: 14),
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 6),
          Text(message, textAlign: TextAlign.center),
          if (onRetry != null) ...<Widget>[
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('重试'),
            ),
          ],
        ],
      ),
    ),
  );
}
