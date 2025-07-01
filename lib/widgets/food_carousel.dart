import 'package:flutter/material.dart';
import '../core/models.dart';
import '../core/theme/app_text_styles.dart';
import '../core/theme/app_colors.dart';

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