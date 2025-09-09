import 'package:flutter/material.dart';
import '../core/models.dart';
import '../core/theme/app_colors.dart';
import 'cafe_detail_page.dart';

class CafeInfoBottomSheet extends StatefulWidget {
  final Cafe cafe;
  final VoidCallback? onClose;
  const CafeInfoBottomSheet({Key? key, required this.cafe, this.onClose}) : super(key: key);

  @override
  State<CafeInfoBottomSheet> createState() => _CafeInfoBottomSheetState();
}

class _CafeInfoBottomSheetState extends State<CafeInfoBottomSheet> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _heightAnimation;
  late Animation<double> _opacityAnimation;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    
    _heightAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    
    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _expandToFullScreen() {
    setState(() {
      _isExpanded = true;
    });
    
    // Navigate to full screen
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => CafeDetailPage(
          cafe: widget.cafe,
          isPreviewMode: false,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 1),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            )),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    ).then((_) {
      // Reset state when returning from full screen
      setState(() {
        _isExpanded = false;
      });
    });
  }

  void _closeSheet() {
    _animationController.reverse().then((_) {
      if (mounted) {
        if (widget.onClose != null) {
          widget.onClose!();
        } else {
          Navigator.of(context).pop();
        }
      }
    });
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
      width: double.infinity,
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
                  style: TextStyle(color: Colors.white70, fontSize: 12),
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

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, (1 - _heightAnimation.value) * 100),
          child: Opacity(
            opacity: _opacityAnimation.value,
            child: Container(
              height: MediaQuery.of(context).size.height * 0.4,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 8,
                    offset: Offset(0, -2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                child: CafeDetailPage(
                  cafe: widget.cafe,
                  isPreviewMode: true,
                  onExpand: _expandToFullScreen,
                  onClose: _closeSheet,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
} 