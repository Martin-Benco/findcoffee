import 'package:flutter/material.dart';
import '../core/models.dart';
import '../core/theme/app_text_styles.dart';
import '../core/theme/app_colors.dart';
import '../core/firebase_service.dart';
import '../core/utils.dart';
import 'package:flutter_svg/flutter_svg.dart';
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
        _favoriteCafes = favorites
            .where((f) => f.type == FavoriteType.cafe)
            .map((f) => f.id)
            .toSet();
      });
    } catch (e) {
      print('Chyba pri načítaní obľúbených kaviarní: $e');
    }
  }

  Future<void> _toggleFavorite(Cafe cafe) async {
    try {
      final favoriteItem = FavoriteItem(
        type: FavoriteType.cafe,
        id: cafe.id,
        name: cafe.name,
        imageUrl: cafe.foto_url,
        address: cafe.address,
      );

      if (_favoriteCafes.contains(cafe.id)) {
        await _firebaseService.removeFromFavorites(cafe.id);
        setState(() {
          _favoriteCafes.remove(cafe.id);
        });
      } else {
        await _firebaseService.addToFavorites(favoriteItem);
        setState(() {
          _favoriteCafes.add(cafe.id);
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
    // Zobrazíme len najbližších 15 kaviarní
    final limitedCafes = widget.cafes.take(15).toList();
    
    return SizedBox(
      height: widget.itemHeight + 80,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: limitedCafes.length,
        separatorBuilder: (_, __) => const SizedBox(width: 16),
        itemBuilder: (context, i) {
          final cafe = limitedCafes[i];
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
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: _buildCafeImage(cafe),
                      ),
                    ),
                    Positioned(
                      top: 12,
                      right: 12,
                      child: GestureDetector(
                        onTap: () => _toggleFavorite(cafe),
                        child: SvgPicture.asset(
                          _favoriteCafes.contains(cafe.id)
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
                            AppUtils.formatDistance(cafe.distanceKm),
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

  Widget _buildCafeImage(Cafe cafe) {
    // Ak nemáme foto_url, zobrazíme fallback ikonu
    if (cafe.foto_url.isEmpty) {
      return Container(
        color: AppColors.grey,
        child: const Icon(
          Icons.local_cafe,
          color: Colors.white70,
          size: 48,
        ),
      );
    }

    // Skontrolujeme, či je to Google Places API URL
    final isGooglePlacesUrl = cafe.foto_url.contains('maps.googleapis.com') || 
                              cafe.foto_url.contains('photoreference');

    // Zobrazíme obrázok z Firebase s error handlingom
    return Image.network(
      cafe.foto_url,
      fit: BoxFit.cover,
      width: widget.itemWidth,
      height: widget.itemHeight,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          color: AppColors.grey,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                      : null,
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white70),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Načítavam...',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        print('Chyba pri načítaní obrázka pre kaviareň ${cafe.name}: $error');
        
        // Ak je to Google Places API chyba, zobrazíme špeciálnu ikonu
        if (isGooglePlacesUrl) {
          return Container(
            color: AppColors.grey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.photo_library_outlined,
                  color: Colors.white70,
                  size: 32,
                ),
                const SizedBox(height: 4),
                const Text(
                  'Foto nedostupné',
                  style: TextStyle(color: Colors.white70, fontSize: 10),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }
        
        // Pre iné chyby zobrazíme generickú ikonu
        return Container(
          color: AppColors.grey,
          child: const Icon(
            Icons.image_not_supported,
            color: Colors.white70,
            size: 48,
          ),
        );
      },
    );
  }
} 