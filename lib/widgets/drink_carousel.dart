import 'package:flutter/material.dart';
import '../core/models.dart';
import '../core/theme/app_text_styles.dart';
import '../core/theme/app_colors.dart';
import 'package:flutter_svg/flutter_svg.dart';

class DrinkCarousel extends StatelessWidget {
  final List<Drink> drinks;
  final double height;
  final double itemSize;
  final Function(String)? onDrinkTap;
  
  const DrinkCarousel({
    required this.drinks, 
    this.height = 140, 
    this.itemSize = 96, 
    this.onDrinkTap,
    super.key
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: drinks.length,
        separatorBuilder: (_, __) => const SizedBox(width: 20),
        itemBuilder: (context, i) {
          final drink = drinks[i];
          return GestureDetector(
            onTap: () {
              if (onDrinkTap != null) {
                onDrinkTap!(drink.name);
              }
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    Container(
                      width: itemSize,
                      height: itemSize,
                      decoration: BoxDecoration(
                        color: AppColors.grey,
                        borderRadius: BorderRadius.circular(16),
                        image: drink.imageUrl.isNotEmpty
                            ? DecorationImage(
                                image: NetworkImage(drink.imageUrl),
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
                    drink.name,
                    style: AppTextStyles.regular12,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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