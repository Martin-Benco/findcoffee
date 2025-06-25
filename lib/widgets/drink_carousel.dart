import 'package:flutter/material.dart';
import '../core/models.dart';
import '../core/theme/app_text_styles.dart';
import '../core/theme/app_colors.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DrinkCarousel extends StatefulWidget {
  final List<Drink> drinks;
  final double height;
  final double itemSize;
  final Function(String)? onDrinkTap;
  
  const DrinkCarousel({
    required this.drinks, 
    this.height = 160, 
    this.itemSize = 130, 
    this.onDrinkTap,
    super.key
  });

  @override
  State<DrinkCarousel> createState() => _DrinkCarouselState();
}

class _DrinkCarouselState extends State<DrinkCarousel> {
  Set<String> _favoriteDrinks = {};
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
        _favoriteDrinks = favs.where((f) => f.type == FavoriteType.drink).map((f) => f.id).toSet();
      });
    }
  }

  Future<void> _toggleFavorite(Drink drink) async {
    if (_userEmail == null) return;
    final prefs = await SharedPreferences.getInstance();
    final key = favoritesKeyForUser(_userEmail!);
    final jsonStr = prefs.getString(key);
    List<FavoriteItem> favs = jsonStr != null ? favoritesFromJson(jsonStr) : [];
    final idx = favs.indexWhere((f) => f.type == FavoriteType.drink && f.id == drink.name);
    setState(() {
      if (_favoriteDrinks.contains(drink.name)) {
        _favoriteDrinks.remove(drink.name);
        if (idx != -1) favs.removeAt(idx);
      } else {
        _favoriteDrinks.add(drink.name);
        favs.add(FavoriteItem(type: FavoriteType.drink, id: drink.name, name: drink.name, imageUrl: drink.imageUrl));
      }
    });
    await prefs.setString(key, favoritesToJson(favs));
  }

  @override
  Widget build(BuildContext context) {
    if (_userEmail == null) {
      return SizedBox(
        height: widget.height,
        child: Center(child: CircularProgressIndicator()),
      );
    }
    return SizedBox(
      height: widget.height,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: widget.drinks.length,
        separatorBuilder: (_, __) => const SizedBox(width: 16),
        itemBuilder: (context, i) {
          final drink = widget.drinks[i];
          return GestureDetector(
            onTap: () {
              if (widget.onDrinkTap != null) {
                widget.onDrinkTap!(drink.name);
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
                        image: drink.imageUrl.isNotEmpty
                            ? DecorationImage(
                                image: AssetImage(drink.imageUrl),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: _userEmail == null
                        ? SvgPicture.asset('assets/icons/bieleHeartEmpty.svg', width: 24, height: 24)
                        : GestureDetector(
                            onTap: () => _toggleFavorite(drink),
                            child: SvgPicture.asset(
                              _favoriteDrinks.contains(drink.name)
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
                    drink.name,
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