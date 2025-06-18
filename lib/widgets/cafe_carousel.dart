import 'package:flutter/material.dart';
import '../core/models.dart';
import '../core/theme/app_text_styles.dart';
import '../core/theme/app_colors.dart';
import 'package:flutter_svg/flutter_svg.dart';

class CafeCarousel extends StatelessWidget {
  final List<Cafe> cafes;
  final double itemWidth;
  final double itemHeight;
  const CafeCarousel({required this.cafes, this.itemWidth = 200, this.itemHeight = 140, super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: itemHeight + 80,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: cafes.length,
        separatorBuilder: (_, __) => const SizedBox(width: 24),
        itemBuilder: (context, i) {
          final cafe = cafes[i];
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  Container(
                    width: itemWidth,
                    height: itemHeight,
                    decoration: BoxDecoration(
                      color: AppColors.grey,
                      borderRadius: BorderRadius.circular(20),
                      image: cafe.imageUrl.isNotEmpty
                          ? DecorationImage(
                              image: NetworkImage(cafe.imageUrl),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                  ),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: SvgPicture.asset(
                      'assets/icons/bieleHeartEmpty.svg',
                      width: 32,
                      height: 32,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: itemWidth,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            cafe.name,
                            style: AppTextStyles.bold12,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${cafe.distanceKm.toStringAsFixed(1)} km',
                            style: AppTextStyles.regular8,
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        SvgPicture.asset(
                          'assets/icons/recenzieHviezdaPlna.svg',
                          width: 24,
                          height: 24,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          cafe.rating.toStringAsFixed(1),
                          style: AppTextStyles.regular12,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
} 