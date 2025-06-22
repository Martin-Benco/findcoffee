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
        separatorBuilder: (_, __) => const SizedBox(width: 16),
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
                    child: SvgPicture.asset(
                      'assets/icons/bieleHeartEmpty.svg',
                      width: 32,
                      height: 32,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: itemWidth,
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
          );
        },
      ),
    );
  }
} 