import 'package:flutter/material.dart';
import '../core/models.dart';
import '../core/theme/app_text_styles.dart';
import '../core/theme/app_colors.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FoodCarousel extends StatefulWidget {
  final List<Food> foods;
  final double height;
  final double itemSize;
  final Function(String)? onFoodTap;
  
  const FoodCarousel({
    required this.foods, 
    this.height = 160, 
    this.itemSize = 130, 
    this.onFoodTap,
    super.key
  });

  @override
  State<FoodCarousel> createState() => _FoodCarouselState();
}

class _FoodCarouselState extends State<FoodCarousel> {
  Set<String> _favoriteFoods = {};
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
        _favoriteFoods = favs.where((f) => f.type == FavoriteType.food).map((f) => f.id).toSet();
      });
    }
  }

  Future<void> _toggleFavorite(Food food) async {
    if (_userEmail == null) return;
    final prefs = await SharedPreferences.getInstance();
    final key = favoritesKeyForUser(_userEmail!);
    final jsonStr = prefs.getString(key);
    List<FavoriteItem> favs = jsonStr != null ? favoritesFromJson(jsonStr) : [];
    final idx = favs.indexWhere((f) => f.type == FavoriteType.food && f.id == food.name);
    setState(() {
      if (_favoriteFoods.contains(food.name)) {
        _favoriteFoods.remove(food.name);
        if (idx != -1) favs.removeAt(idx);
      } else {
        _favoriteFoods.add(food.name);
        favs.add(FavoriteItem(type: FavoriteType.food, id: food.name, name: food.name, imageUrl: food.imageUrl));
      }
    });
    await prefs.setString(key, favoritesToJson(favs));
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: widget.foods.length,
        separatorBuilder: (_, __) => const SizedBox(width: 16),
        itemBuilder: (context, i) {
          final food = widget.foods[i];
          return GestureDetector(
            onTap: () {
              if (widget.onFoodTap != null) {
                widget.onFoodTap!(food.name);
              }
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Stack(
                  children: [
                    Container(
                      width: widget.itemSize,
                      height: widget.itemSize,
                      decoration: BoxDecoration(
                        color: AppColors.grey,
                        borderRadius: BorderRadius.circular(16),
                        image: food.imageUrl.isNotEmpty
                            ? DecorationImage(
                                image: AssetImage(food.imageUrl),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: GestureDetector(
                        onTap: () => _toggleFavorite(food),
                        child: SvgPicture.asset(
                          _favoriteFoods.contains(food.name)
                            ? 'assets/icons/bieleHeartPlne.svg'
                            : 'assets/icons/bieleHeartEmpty.svg',
                          width: 24,
                          height: 24,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: widget.itemSize,
                  child: Text(
                    food.name,
                    style: AppTextStyles.regular12,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
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