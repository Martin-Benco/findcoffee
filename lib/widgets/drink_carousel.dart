import 'package:flutter/material.dart';
import '../core/models.dart';
import '../core/theme/app_text_styles.dart';
import '../core/theme/app_colors.dart';

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