import 'package:flutter/material.dart';
import '../core/models.dart';
import '../core/theme/app_text_styles.dart';
import '../core/theme/app_colors.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'cafe_detail_page.dart';

class CafeCarousel extends StatefulWidget {
  final List<Cafe> cafes;
  final double itemWidth;
  final double itemHeight;
  const CafeCarousel({required this.cafes, this.itemWidth = 200, this.itemHeight = 140, super.key});

  @override
  State<CafeCarousel> createState() => _CafeCarouselState();
}

class _CafeCarouselState extends State<CafeCarousel> {
  Set<String> _favoriteCafes = {};
  String? _userEmail;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    final email = await getCurrentUserEmail();
    if (email == null) return;
    _userEmail = email;
    final prefs = await SharedPreferences.getInstance();
    final key = favoritesKeyForUser(email);
    final jsonStr = prefs.getString(key);
    if (jsonStr != null) {
      final favs = favoritesFromJson(jsonStr);
      setState(() {
        _favoriteCafes = favs.where((f) => f.type == FavoriteType.cafe).map((f) => f.id).toSet();
      });
    }
  }

  Future<void> _toggleFavorite(Cafe cafe) async {
    if (_userEmail == null) return;
    final prefs = await SharedPreferences.getInstance();
    final key = favoritesKeyForUser(_userEmail!);
    final jsonStr = prefs.getString(key);
    List<FavoriteItem> favs = jsonStr != null ? favoritesFromJson(jsonStr) : [];
    final idx = favs.indexWhere((f) => f.type == FavoriteType.cafe && f.id == cafe.name);
    setState(() {
      if (_favoriteCafes.contains(cafe.name)) {
        _favoriteCafes.remove(cafe.name);
        if (idx != -1) favs.removeAt(idx);
      } else {
        _favoriteCafes.add(cafe.name);
        favs.add(FavoriteItem(type: FavoriteType.cafe, id: cafe.name, name: cafe.name, imageUrl: cafe.foto_url));
      }
    });
    await prefs.setString(key, favoritesToJson(favs));
  }

  @override
  Widget build(BuildContext context) {
    if (_userEmail == null) {
      // Loading alebo fallback pre web
      return SizedBox(
        height: widget.itemHeight + 80,
        child: Center(child: CircularProgressIndicator()),
      );
    }
    return SizedBox(
      height: widget.itemHeight + 80,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: widget.cafes.length,
        separatorBuilder: (_, __) => const SizedBox(width: 16),
        itemBuilder: (context, i) {
          final cafe = widget.cafes[i];
          return GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => CafeDetailPage(cafe: cafe),
                ),
              );
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    Container(
                      width: widget.itemWidth,
                      height: widget.itemHeight,
                      decoration: BoxDecoration(
                        color: AppColors.grey,
                        borderRadius: BorderRadius.circular(20),
                        image: cafe.foto_url.isNotEmpty
                            ? DecorationImage(
                                image: NetworkImage(cafe.foto_url),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                    ),
                    Positioned(
                      top: 12,
                      right: 12,
                      child: _userEmail == null
                        ? SvgPicture.asset('assets/icons/bieleHeartEmpty.svg', width: 32, height: 32)
                        : GestureDetector(
                            onTap: () => _toggleFavorite(cafe),
                            child: SvgPicture.asset(
                              _favoriteCafes.contains(cafe.name)
                                ? 'assets/icons/bieleHeartPlne.svg'
                                : 'assets/icons/bieleHeartEmpty.svg',
                              width: 32,
                              height: 32,
                            ),
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: widget.itemWidth,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              cafe.name.length > 17 ? '${cafe.name.substring(0, 17)}...' : cafe.name,
                              style: AppTextStyles.bold12,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            '${cafe.distanceKm.toStringAsFixed(1)} km',
                            style: AppTextStyles.regular12,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Row(
                            children: [
                              SvgPicture.asset(
                                'assets/icons/recenzieHviezdaPlna.svg',
                                width: 16,
                                height: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                cafe.rating.toStringAsFixed(1),
                                style: AppTextStyles.regular12,
                              ),
                            ],
                          ),
                          const Spacer(),
                          Row(
                            children: [
                              SvgPicture.asset(
                                'assets/icons/parkinghnede.svg',
                                width: 16,
                                height: 16,
                              ),
                              const SizedBox(width: 4),
                              SvgPicture.asset(
                                'assets/icons/menuhnede.svg',
                                width: 16,
                                height: 16,
                              ),
                              const SizedBox(width: 4),
                              SvgPicture.asset(
                                'assets/icons/wifihnede.svg',
                                width: 16,
                                height: 16,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
} 