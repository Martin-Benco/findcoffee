import 'package:flutter/material.dart';
import '../core/models.dart';
import '../core/theme/app_text_styles.dart';
import '../core/theme/app_colors.dart';
import 'package:flutter_svg/flutter_svg.dart';

class FoodCarousel extends StatelessWidget {
  final List<Food> foods;
  final double height;
  final double itemSize;
  final Function(String)? onFoodTap;
  
  const FoodCarousel({
    required this.foods, 
    this.height = 140, 
    this.itemSize = 96, 
    this.onFoodTap,
    super.key
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: foods.length,
        separatorBuilder: (_, __) => const SizedBox(width: 20),
        itemBuilder: (context, i) {
          final food = foods[i];
          return GestureDetector(
            onTap: () {
              if (onFoodTap != null) {
                onFoodTap!(food.name);
              }
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Stack(
                  children: [
                    Container(
                      width: itemSize,
                      height: itemSize,
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
                      child: SvgPicture.asset(
                        'assets/icons/bieleHeartEmpty.svg',
                        width: 24,
                        height: 24,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: itemSize,
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