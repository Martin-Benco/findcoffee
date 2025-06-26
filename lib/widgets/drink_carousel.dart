import 'package:flutter/material.dart';
import '../core/models.dart';
import '../core/theme/app_text_styles.dart';
import '../core/theme/app_colors.dart';
import '../core/firebase_service.dart';
import 'package:flutter_svg/flutter_svg.dart';

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
  final FirebaseService _firebaseService = FirebaseService();

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    try {
      final favorites = await _firebaseService.getFavorites();
      setState(() {
        _favoriteDrinks = favorites
            .where((f) => f.type == FavoriteType.drink)
            .map((f) => f.id)
            .toSet();
      });
    } catch (e) {
      print('Chyba pri načítaní obľúbených nápojov: $e');
    }
  }

  Future<void> _toggleFavorite(Drink drink) async {
    try {
      final favoriteItem = FavoriteItem(
        type: FavoriteType.drink,
        id: drink.name,
        name: drink.name,
        imageUrl: drink.imageUrl,
      );

      if (_favoriteDrinks.contains(drink.name)) {
        await _firebaseService.removeFromFavorites(drink.name);
        setState(() {
          _favoriteDrinks.remove(drink.name);
        });
      } else {
        await _firebaseService.addToFavorites(favoriteItem);
        setState(() {
          _favoriteDrinks.add(drink.name);
        });
      }
    } catch (e) {
      print('Chyba pri prepínaní obľúbených: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Chyba: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
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
                      child: GestureDetector(
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