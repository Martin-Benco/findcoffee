import 'package:flutter/material.dart';
import '../core/models.dart';
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