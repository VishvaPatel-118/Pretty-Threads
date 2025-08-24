import 'package:flutter/material.dart';
import 'package:pretty_threads/services/api.dart';
import 'package:pretty_threads/services/favorites.dart';
import 'package:pretty_threads/user/home/product_details_page.dart';
import 'package:pretty_threads/theme/app_theme.dart';

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  final _fav = FavoritesService();
  bool _loading = true;
  List<Map<String, dynamic>> _items = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final list = await _fav.getFavorites();
    if (!mounted) return;
    setState(() {
      _items = list;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Container(
      decoration: const BoxDecoration(
        gradient: AppTheme.backgroundGradient,
      ),
      child: RefreshIndicator(
        onRefresh: _load,
        child: MediaQuery.removePadding(
          context: context,
          removeTop: true,
          child: CustomScrollView(
            slivers: [
              _buildSliverHeader(context),
              if (_items.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _buildEmptyState(context),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.72,
                    ),
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final it = _items[index];
                      return _FavoriteCard(
                        slug: (it['slug'] ?? '').toString(),
                        name: (it['name'] ?? '').toString(),
                        price: (it['price'] is num) ? (it['price'] as num).toDouble() : double.tryParse((it['price'] ?? '0').toString()) ?? 0,
                        imageUrl: ApiService.normalizeImageUrl((it['image_url'] ?? '').toString()),
                        onRemoved: () async {
                          await _fav.removeFavorite((it['slug'] ?? '').toString());
                          await _load();
                        },
                        onOpen: () async {
                          final slug = (it['slug'] ?? '').toString();
                          try {
                            final data = await ApiService.getProductBySlug(slug);
                            final p = (data['data'] ?? data) as Map<String, dynamic>;
                            final images = <String>[];
                            final rawImg = (p['image_url'] ?? '').toString();
                            if (rawImg.isNotEmpty) images.add(rawImg);
                            await Navigator.of(context).push(MaterialPageRoute(
                              builder: (_) => ProductDetailsPage(
                                slug: p['slug']?.toString() ?? slug,
                                name: p['name']?.toString() ?? (it['name'] ?? 'Product').toString(),
                                price: (p['price'] is num) ? (p['price'] as num).toDouble() : double.tryParse((p['price'] ?? '0').toString()) ?? 0,
                                description: p['description']?.toString() ?? '',
                                images: images,
                              ),
                            ));
                          } catch (_) {}
                        },
                      );
                    }, childCount: _items.length),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  SliverAppBar _buildSliverHeader(BuildContext context) {
    final count = _items.length;
    return SliverAppBar(
      pinned: true,
      floating: false,
      snap: false,
      elevation: 0,
      expandedHeight: 110,
      collapsedHeight: 80,
      toolbarHeight: 0,
      primary: false,
      automaticallyImplyLeading: false,
      leading: null,
      backgroundColor: AppTheme.primary,
      flexibleSpace: Container(
        color: AppTheme.primary,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(Icons.favorite, color: Colors.white),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Favorites', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
                    Text('$count items you love', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                ),
              ),
              IconButton(
                onPressed: _load,
                icon: const Icon(Icons.refresh, color: Colors.white),
                tooltip: 'Refresh',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.favorite_border, size: 72, color: Colors.purple.shade300),
            const SizedBox(height: 12),
            const Text('No favorites yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            const Text('Tap the heart on a product to save it here.'),
          ],
        ),
      ),
    );
  }
}

class _FavoriteCard extends StatelessWidget {
  final String slug;
  final String name;
  final double price;
  final String imageUrl;
  final VoidCallback onRemoved;
  final VoidCallback onOpen;

  const _FavoriteCard({
    required this.slug,
    required this.name,
    required this.price,
    required this.imageUrl,
    required this.onRemoved,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onOpen,
      borderRadius: BorderRadius.circular(14),
      child: Ink(
        decoration: AppTheme.cardBoxDecoration(radius: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _ImageThumb(url: imageUrl),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 0),
              child: Text(
                name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 6, 10, 4),
              child: Row(
                children: [
                  Text('₹ ${price.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w700)),
                  const Spacer(),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    onPressed: onRemoved,
                    icon: Icon(Icons.favorite, color: Colors.purple.shade400),
                    tooltip: 'Remove',
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

class _ImageThumb extends StatelessWidget {
  final String url;
  const _ImageThumb({required this.url});

  @override
  Widget build(BuildContext context) {
    final radius = const BorderRadius.vertical(top: Radius.circular(14));
    if (url.isEmpty) {
      return Container(
        height: 140,
        decoration: BoxDecoration(
          color: Colors.purple.shade50,
          borderRadius: radius,
        ),
        child: Icon(Icons.favorite, color: Colors.purple.shade200, size: 48),
      );
    }
    if (url.startsWith('assets/')) {
      return ClipRRect(
        borderRadius: radius,
        child: Image.asset(url, height: 140, fit: BoxFit.cover),
      );
    }
    return ClipRRect(
      borderRadius: radius,
      child: Image.network(
        url,
        height: 140,
        fit: BoxFit.cover,
        errorBuilder: (c, e, s) => Container(
          height: 140,
          decoration: BoxDecoration(
            color: Colors.purple.shade50,
            borderRadius: radius,
          ),
          child: const Icon(Icons.broken_image),
        ),
      ),
    );
  }
}
