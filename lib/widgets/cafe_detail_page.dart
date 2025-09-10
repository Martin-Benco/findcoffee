import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../core/models.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../core/firebase_service.dart';
import '../core/utils.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/services.dart';
import 'review_form_dialog.dart';

class CafeDetailPage extends StatefulWidget {
  final Cafe cafe;
  final bool isPreviewMode;
  final VoidCallback? onExpand;
  final VoidCallback? onClose;
  
  const CafeDetailPage({
    super.key, 
    required this.cafe,
    this.isPreviewMode = false,
    this.onExpand,
    this.onClose,
  });

  @override
  State<CafeDetailPage> createState() => _CafeDetailPageState();
}

class _CafeDetailPageState extends State<CafeDetailPage> with TickerProviderStateMixin {
  bool _isFavorite = false;
  bool _isMenuExpanded = false;
  bool _isServicesExpanded = false;
  final FirebaseService _firebaseService = FirebaseService();
  late AnimationController _animationController;
  late Animation<double> _heightAnimation;
  late Animation<double> _opacityAnimation;
  late AnimationController _menuAnimationController;
  late Animation<double> _menuHeightAnimation;
  late AnimationController _servicesAnimationController;
  late Animation<double> _servicesHeightAnimation;

  @override
  void initState() {
    super.initState();
    _loadFavoriteStatus();
    
    // Initialize menu animation controller
    _menuAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _menuHeightAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _menuAnimationController,
      curve: Curves.easeInOut,
    ));

    // Initialize services animation controller
    _servicesAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _servicesHeightAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _servicesAnimationController,
      curve: Curves.easeInOut,
    ));
    
    if (widget.isPreviewMode) {
      _animationController = AnimationController(
        duration: const Duration(milliseconds: 300),
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
  }

  @override
  void dispose() {
    _menuAnimationController.dispose();
    _servicesAnimationController.dispose();
    if (widget.isPreviewMode) {
      _animationController.dispose();
    }
    super.dispose();
  }

  Future<void> _loadFavoriteStatus() async {
    try {
      final isFavorite = await _firebaseService.isFavorite(widget.cafe.id);
      setState(() {
        _isFavorite = isFavorite;
      });
    } catch (e) {
      print('Chyba pri načítaní stavu obľúbených: $e');
    }
  }


  Future<void> _toggleFavorite() async {
    try {
      if (_isFavorite) {
        await _firebaseService.removeFromFavorites(widget.cafe.id);
        setState(() {
          _isFavorite = false;
        });
      } else {
        final favoriteItem = FavoriteItem(
          type: FavoriteType.cafe,
          id: widget.cafe.id,
          name: widget.cafe.name,
          imageUrl: widget.cafe.foto_url,
        );
        await _firebaseService.addToFavorites(favoriteItem);
        setState(() {
          _isFavorite = true;
        });
      }
    } catch (e) {
      print('Chyba pri prepínaní obľúbených: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Chyba: $e')),
      );
    }
  }

  void _handleExpand() {
    if (widget.onExpand != null) {
      widget.onExpand!();
    }
  }

  void _handleClose() {
    if (widget.isPreviewMode) {
      if (widget.onExpand != null) {
        widget.onExpand!();
      }
    } else {
      Navigator.of(context).pop();
    }
  }

  void _handleClosePreview() {
    if (widget.isPreviewMode && widget.onClose != null) {
      widget.onClose!();
    }
  }

  void _toggleMenuExpansion() {
    setState(() {
      _isMenuExpanded = !_isMenuExpanded;
    });
    
    if (_isMenuExpanded) {
      _menuAnimationController.forward();
    } else {
      _menuAnimationController.reverse();
    }
  }

  void _toggleServicesExpansion() {
    setState(() {
      _isServicesExpanded = !_isServicesExpanded;
    });
    
    if (_isServicesExpanded) {
      _servicesAnimationController.forward();
    } else {
      _servicesAnimationController.reverse();
    }
  }

  void _showReviewForm() {
    showDialog(
      context: context,
      builder: (context) => ReviewFormDialog(
        cafeId: widget.cafe.id,
        cafeName: widget.cafe.name,
      ),
    );
  }

  Future<void> _updateService(String serviceName, bool? value) async {
    try {
      await _firebaseService.updateService(widget.cafe.id, serviceName, value);
      print('Služba $serviceName aktualizovaná na hodnotu: $value');
    } catch (e) {
      print('Chyba pri aktualizácii služby $serviceName: $e');
      rethrow; // Re-throw aby sa zobrazil error v UI
    }
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays > 0) {
      return 'pred ${difference.inDays} ${difference.inDays == 1 ? 'dňom' : 'dňami'}';
    } else if (difference.inHours > 0) {
      return 'pred ${difference.inHours} ${difference.inHours == 1 ? 'hodinou' : 'hodinami'}';
    } else if (difference.inMinutes > 0) {
      return 'pred ${difference.inMinutes} ${difference.inMinutes == 1 ? 'minútou' : 'minútami'}';
    } else {
      return 'práve teraz';
    }
  }

  @override
  Widget build(BuildContext context) {
    final content = _buildContent();
    
    if (widget.isPreviewMode) {
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
                  child: GestureDetector(
                    onTap: _handleClose,
                    child: Stack(
                      children: [
                        SingleChildScrollView(
                          physics: const ClampingScrollPhysics(),
                          child: Column(
                            children: [
                              // Preview content - len obrázok a základné info
                              _buildPreviewContent(),
                            ],
                          ),
                        ),
                        // Close button
                        Positioned(
                          top: 16,
                          left: 16,
                          child: GestureDetector(
                            onTap: _handleClosePreview,
                            behavior: HitTestBehavior.opaque,
                            child: SvgPicture.asset(
                              'assets/icons/ArrowLeft.svg',
                              width: 30,
                              height: 30,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      );
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        extendBodyBehindAppBar: true,
        body: content,
      ),
    );
  }

  Widget _buildPreviewContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Obrázok s overlay ikonami
        Stack(
          children: [
            AspectRatio(
              aspectRatio: 1.5,
              child: _buildCafeImage(widget.cafe),
            ),
            // Overlay ikony - rovnaké ako v celej coffee page
            Positioned(
              left: 16,
              top: 16,
              child: GestureDetector(
                onTap: _handleClose,
                child: SvgPicture.asset(
                  'assets/icons/ArrowLeft.svg',
                  width: 30,
                  height: 30,
                  color: Colors.white,
                ),
              ),
            ),
            Positioned(
              right: 16,
              top: 16,
              child: GestureDetector(
                onTap: _toggleFavorite,
                child: SvgPicture.asset(
                  _isFavorite
                    ? 'assets/icons/bieleHeartPlne.svg'
                    : 'assets/icons/bieleHeartEmpty.svg',
                  width: 30,
                  height: 30,
                ),
              ),
            ),
            // Carousel číslovanie
            Positioned(
              right: 18,
              bottom: 18,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  '1/1',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
        // Základné info
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.cafe.name.length > 21
                        ? widget.cafe.name.substring(0, 21) + '...'
                        : widget.cafe.name,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    FutureBuilder<OpeningHours?>(
                      future: _firebaseService.getCurrentDayOpeningHours(widget.cafe.id),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Text(
                            'Načítavam...',
                            style: TextStyle(color: Colors.grey, fontSize: 15),
                          );
                        }
                        
                        if (snapshot.hasError || snapshot.data == null) {
                          return const Text(
                            'Otváracie hodiny nie sú dostupné',
                            style: TextStyle(color: Colors.grey, fontSize: 15),
                          );
                        }
                        
                        final openingHours = snapshot.data!;
                        final isOpen = openingHours.isCurrentlyOpen();
                        final hoursText = openingHours.getFormattedHours();
                        
                        return Text(
                          '$hoursText, ${isOpen ? 'otvorené' : 'zatvorené'}',
                          style: TextStyle(
                            color: isOpen ? Colors.green : Colors.red,
                            fontSize: 15,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  FutureBuilder<List<Review>>(
                    future: _firebaseService.getReviews(widget.cafe.id),
                    builder: (context, snapshot) {
                      double averageRating = 0.0;
                      int reviewCount = 0;
                      
                      if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                        final reviews = snapshot.data!;
                        reviewCount = reviews.length;
                        final totalRating = reviews.fold(0, (sum, review) => sum + review.rating);
                        averageRating = totalRating / reviewCount;
                      } else {
                        averageRating = widget.cafe.rating; // fallback na pôvodný rating
                      }
                      
                      return Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 22),
                          const SizedBox(width: 4),
                          Text(
                            averageRating.toStringAsFixed(1),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                          const SizedBox(width: 2),
                          Text(' ($reviewCount)', style: const TextStyle(color: Colors.grey, fontSize: 13)),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 6),
                  Text(
                    AppUtils.formatDistance(widget.cafe.distanceKm),
                    style: const TextStyle(color: Colors.grey, fontSize: 15),
                  ),
                ],
              ),
            ],
          ),
        ),
        // Divider
        Center(
          child: Container(
            width: MediaQuery.of(context).size.width * 0.85,
            child: const Divider(thickness: 1, height: 1),
          ),
        ),
      ],
    );
  }

  Widget _buildContent() {
    return Stack(
      children: [
        SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Carousel obrázkov s overlay ikonami
              Stack(
                children: [
                  AspectRatio(
                    aspectRatio: 1.5,
                    child: _buildCafeImage(widget.cafe),
                  ),
                  // Overlay ikony (bez šípky späť)
              Positioned(
                right: 16,
                top: 16 + MediaQuery.of(context).padding.top,
                child: GestureDetector(
                  onTap: _toggleFavorite,
                  child: SvgPicture.asset(
                    _isFavorite
                      ? 'assets/icons/bieleHeartPlne.svg'
                      : 'assets/icons/bieleHeartEmpty.svg',
                    width: 30,
                    height: 30,
                  ),
                ),
              ),
              // Carousel číslovanie
              Positioned(
                right: 18,
                bottom: 18,
                child: Text(
                  '1/1',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(
                        color: Colors.black.withOpacity(0.25),
                        offset: Offset(0, 1),
                        blurRadius: 2,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          // Info blok pod obrázkom
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.cafe.name.length > 21
                          ? widget.cafe.name.substring(0, 21) + '...'
                          : widget.cafe.name,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.black,
                        ),
                      ),
                      const SizedBox(height: 4),
                      FutureBuilder<OpeningHours?>(
                        future: _firebaseService.getCurrentDayOpeningHours(widget.cafe.id),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Text(
                              'Načítavam...',
                              style: TextStyle(color: Colors.grey, fontSize: 15),
                            );
                          }
                          
                          if (snapshot.hasError || snapshot.data == null) {
                            return const Text(
                              'Otváracie hodiny nie sú dostupné',
                              style: TextStyle(color: Colors.grey, fontSize: 15),
                            );
                          }
                          
                          final openingHours = snapshot.data!;
                          final isOpen = openingHours.isCurrentlyOpen();
                          final hoursText = openingHours.getFormattedHours();
                          
                          return Text(
                            '$hoursText, ${isOpen ? 'otvorené' : 'zatvorené'}',
                            style: TextStyle(
                              color: isOpen ? Colors.green : Colors.red,
                              fontSize: 15,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    FutureBuilder<List<Review>>(
                      future: _firebaseService.getReviews(widget.cafe.id),
                      builder: (context, snapshot) {
                        double averageRating = 0.0;
                        int reviewCount = 0;
                        
                        if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                          final reviews = snapshot.data!;
                          reviewCount = reviews.length;
                          final totalRating = reviews.fold(0, (sum, review) => sum + review.rating);
                          averageRating = totalRating / reviewCount;
                        } else {
                          averageRating = widget.cafe.rating; // fallback na pôvodný rating
                        }
                        
                        return Row(
                          children: [
                            const Icon(Icons.star, color: Colors.amber, size: 22),
                            const SizedBox(width: 4),
                            Text(
                              averageRating.toStringAsFixed(1),
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                            ),
                            const SizedBox(width: 2),
                            Text(' ($reviewCount)', style: const TextStyle(color: Colors.grey, fontSize: 13)),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 6),
                    Text(
                      AppUtils.formatDistance(widget.cafe.distanceKm),
                      style: const TextStyle(color: Colors.grey, fontSize: 15),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Divider
          Center(
            child: Container(
              width: MediaQuery.of(context).size.width * 0.85,
              child: const Divider(thickness: 1, height: 1),
            ),
          ),
          // Menu sekcia
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Menu header s šípkou
                GestureDetector(
                  onTap: _toggleMenuExpansion,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Menu', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
                      AnimatedRotation(
                        turns: _isMenuExpanded ? 0.5 : 0.0,
                        duration: const Duration(milliseconds: 300),
                        child: const Icon(
                          Icons.keyboard_arrow_down,
                          size: 28,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
                // Expandable menu content
                AnimatedBuilder(
                  animation: _menuHeightAnimation,
                  builder: (context, child) {
                    return ClipRect(
                      child: Align(
                        alignment: Alignment.topCenter,
                        heightFactor: _menuHeightAnimation.value,
                        child: child,
                      ),
                    );
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: () {},
                        style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size(0, 0)),
                        child: const Text('Je v menu viac produktov?', style: TextStyle(fontSize: 14, color: Colors.black54, decoration: TextDecoration.underline)),
                      ),
                      const SizedBox(height: 16),
                      FutureBuilder<List<MenuItem>>(
                        future: _firebaseService.getMenuItems(widget.cafe.id),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          }
                          
                          if (snapshot.hasError) {
                            return const Center(
                              child: Text('Chyba pri načítaní menu', style: TextStyle(color: Colors.grey)),
                            );
                          }
                          
                          final menuItems = snapshot.data ?? [];
                          
                          if (menuItems.isEmpty) {
                            return const Center(
                              child: Text('Žiadne položky v menu', style: TextStyle(color: Colors.grey)),
                            );
                          }
                          
                          // Zoskupíme menu položky podľa kategórie
                          final Map<String, List<MenuItem>> groupedItems = {};
                          for (final item in menuItems) {
                            final category = item.kategoria ?? 'Ostatné';
                            if (!groupedItems.containsKey(category)) {
                              groupedItems[category] = [];
                            }
                            groupedItems[category]!.add(item);
                          }
                          
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: groupedItems.entries.map((entry) {
                              final category = entry.key;
                              final items = entry.value;
                              
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(category, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                                  const SizedBox(height: 10),
                                  ...items.map((item) => _MenuItemRow(
                                    name: item.nazov,
                                    price: item.cena,
                                    desc: item.popis ?? '',
                                    badge: item.badge,
                                  )),
                                  const SizedBox(height: 18),
                                ],
                              );
                            }).toList(),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Divider
          Center(
            child: Container(
              width: MediaQuery.of(context).size.width * 0.85,
              child: const Divider(thickness: 1, height: 1),
            ),
          ),
          // Služby sekcia
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Services header s šípkou
                GestureDetector(
                  onTap: _toggleServicesExpansion,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Toto miesto ponúka:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
                      AnimatedRotation(
                        turns: _isServicesExpanded ? 0.5 : 0.0,
                        duration: const Duration(milliseconds: 300),
                        child: const Icon(
                          Icons.keyboard_arrow_down,
                          size: 28,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
                // Expandable services content
                AnimatedBuilder(
                  animation: _servicesHeightAnimation,
                  builder: (context, child) {
                    return ClipRect(
                      child: Align(
                        alignment: Alignment.topCenter,
                        heightFactor: _servicesHeightAnimation.value,
                        child: child,
                      ),
                    );
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: () {},
                        style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size(0, 0)),
                        child: const Text('Myslíte si, že toto miesto ponúka viac?', style: TextStyle(fontSize: 14, color: Colors.black54, decoration: TextDecoration.underline)),
                      ),
                      const SizedBox(height: 16),
                      FutureBuilder<Map<String, bool?>>(
                        future: _firebaseService.getServices(widget.cafe.id),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          }
                          
                          if (snapshot.hasError) {
                            return const Center(
                              child: Text('Chyba pri načítaní služieb', style: TextStyle(color: Colors.grey)),
                            );
                          }
                          
                          final services = snapshot.data ?? {};
                          
                          if (services.isEmpty) {
                            return const Center(
                              child: Text('Žiadne služby nie sú dostupné', style: TextStyle(color: Colors.grey)),
                            );
                          }
                          
                          return Column(
                            children: services.entries.map((entry) {
                              final serviceName = entry.key;
                              final serviceValue = entry.value;
                              
                              return Column(
                                children: [
                                  _ServiceRow(
                                    label: serviceName,
                                    value: serviceValue,
                                    cafeId: widget.cafe.id,
                                    onValueChanged: _updateService,
                                  ),
                                  const SizedBox(height: 18),
                                ],
                              );
                            }).toList(),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Divider
          Center(
            child: Container(
              width: MediaQuery.of(context).size.width * 0.85,
              child: const Divider(thickness: 1, height: 1),
            ),
          ),
          // Mapa sekcia
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Kde sa kaviareň nachádza?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: SizedBox(
                    height: 220,
                    width: double.infinity,
                    child: _CafeMap(
                      latitude: widget.cafe.latitude,
                      longitude: widget.cafe.longitude,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Divider
          Center(
            child: Container(
              width: MediaQuery.of(context).size.width * 0.85,
              child: const Divider(thickness: 1, height: 1),
            ),
          ),
          // Otváracie hodiny sekcia
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Otváracie hodiny', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                const SizedBox(height: 12),
                FutureBuilder<List<OpeningHours>>(
                  future: _firebaseService.getOpeningHours(widget.cafe.id),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    
                    if (snapshot.hasError) {
                      return const Center(
                        child: Text('Chyba pri načítaní otváracích hodín', style: TextStyle(color: Colors.grey)),
                      );
                    }
                    
                    final openingHours = snapshot.data ?? [];
                    
                    return Column(
                      children: openingHours.map((hours) => _OpeningHoursRow(
                        day: hours.den,
                        hours: hours.hodiny,
                      )).toList(),
                    );
                  },
                ),
              ],
            ),
          ),
          // Divider
          Center(
            child: Container(
              width: MediaQuery.of(context).size.width * 0.85,
              child: const Divider(thickness: 1, height: 1),
            ),
          ),
          // Recenzie sekcia
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FutureBuilder<List<Review>>(
                  future: _firebaseService.getReviews(widget.cafe.id),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    
                    if (snapshot.hasError) {
                      return const Center(
                        child: Text('Chyba pri načítaní recenzií', style: TextStyle(color: Colors.grey)),
                      );
                    }
                    
                    final reviews = snapshot.data ?? [];
                    
                    if (reviews.isEmpty) {
                      return Column(
                        children: [
                          const Center(
                            child: Text(
                              'Zatiaľ žiadne recenzie',
                              style: TextStyle(color: Colors.grey, fontSize: 16),
                            ),
                          ),
                          const SizedBox(height: 32),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _showReviewForm,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF603013),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                padding: const EdgeInsets.symmetric(vertical: 18),
                              ),
                              child: const Text('Pridať prvú recenziu', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                            ),
                          ),
                        ],
                      );
                    }
                    
                    return Column(
                      children: [
                        SizedBox(
                          height: 210,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            children: reviews.take(3).map((review) {
                              return Padding(
                                padding: const EdgeInsets.only(right: 24),
                                child: _ReviewItem(
                                  name: review.userName,
                                  info: review.userInfo ?? 'Nový používateľ',
                                  time: _formatTimeAgo(review.createdAt),
                                  rating: review.rating,
                                  text: review.text,
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                        const SizedBox(height: 32),
                        // Buttony
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: () {
                              // TODO: Implement show all reviews
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF603013),
                              side: const BorderSide(color: Color(0xFF603013), width: 2),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(vertical: 18),
                            ),
                            child: Text('Ukázať všetkých ${reviews.length} recenzií', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _showReviewForm,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF603013),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(vertical: 18),
                            ),
                            child: const Text('Pridať recenziu', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
          
        ],
      ),
        ),
        // Fixná šípka späť - zostane na vrchu aj pri scrollovaní
        Positioned(
          left: 16,
          top: 16 + MediaQuery.of(context).padding.top,
          child: GestureDetector(
            onTap: _handleClose,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                borderRadius: BorderRadius.circular(20),
              ),
              child: SvgPicture.asset(
                'assets/icons/ArrowLeft.svg',
                width: 30,
                height: 30,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
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
          size: 64,
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
                  size: 48,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Foto nedostupné',
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                const Text(
                  'Google Places API foto vypršalo',
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
            size: 64,
          ),
        );
      },
    );
  }
}

class _ServiceItem extends StatelessWidget {
  final String icon;
  final String label;
  
  const _ServiceItem({required this.icon, required this.label});
  
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SvgPicture.asset(icon, width: 24, height: 24),
        const SizedBox(height: 4),
        Text(
          label,
          style: AppTextStyles.regular12,
        ),
      ],
    );
  }
}

// Pridám widget pre menu položku
class _MenuItemRow extends StatelessWidget {
  final String name;
  final String price;
  final String desc;
  final String? badge;
  const _MenuItemRow({required this.name, required this.price, required this.desc, this.badge});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                    if (badge != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Color(0xFFB47B5B),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(badge!, style: const TextStyle(color: Colors.white, fontSize: 12)),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(desc, style: const TextStyle(color: Colors.grey, fontSize: 13)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(price, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

// Pridám widget pre službu
class _ServiceRow extends StatefulWidget {
  final String label;
  final bool? value;
  final String cafeId;
  final Function(String, bool?) onValueChanged;
  
  const _ServiceRow({
    required this.label, 
    this.value, 
    required this.cafeId,
    required this.onValueChanged,
  });

  @override
  State<_ServiceRow> createState() => _ServiceRowState();
}

class _ServiceRowState extends State<_ServiceRow> {
  bool? _currentValue;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _currentValue = widget.value;
  }

  @override
  void didUpdateWidget(_ServiceRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _currentValue = widget.value;
    }
  }

  void _showServiceModal() {
    showDialog(
      context: context,
      builder: (context) => _ServiceSelectionModal(
        serviceName: widget.label,
        currentValue: _currentValue,
        onValueSelected: _updateValue,
      ),
    );
  }

  Future<void> _updateValue(bool? newValue) async {
    if (_isUpdating) return;

    setState(() {
      _isUpdating = true;
    });

    try {
      // Aktualizujeme lokálny stav
      setState(() {
        _currentValue = newValue;
      });

      // Zavoláme callback pre aktualizáciu v databáze
      await widget.onValueChanged(widget.label, newValue);
    } catch (e) {
      // V prípade chyby vrátime pôvodnú hodnotu
      setState(() {
        _currentValue = widget.value;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Chyba pri aktualizácii: $e')),
      );
    } finally {
      setState(() {
        _isUpdating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Určíme farbu a text podľa hodnoty
    Color statusColor;
    String statusText;
    IconData statusIcon;
    
    if (_currentValue == true) {
      statusColor = Colors.green;
      statusText = 'Áno';
      statusIcon = Icons.check_circle;
    } else if (_currentValue == false) {
      statusColor = Colors.red;
      statusText = 'Nie';
      statusIcon = Icons.cancel;
    } else {
      statusColor = Colors.grey;
      statusText = 'Nezadané';
      statusIcon = Icons.help_outline;
    }

    return GestureDetector(
      onTap: _showServiceModal,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: _isUpdating ? Colors.grey.withOpacity(0.1) : null,
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.black12,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Text(
                widget.label, 
                style: const TextStyle(fontSize: 18),
              ),
            ),
            const SizedBox(width: 12),
            if (_isUpdating)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              Row(
                children: [
                  Icon(
                    statusIcon,
                    color: statusColor,
                    size: 20,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    statusText,
                    style: TextStyle(
                      fontSize: 16,
                      color: statusColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

// Widget pre mapu kaviarne
class _CafeMap extends StatelessWidget {
  final double latitude;
  final double longitude;
  const _CafeMap({required this.latitude, required this.longitude});

  @override
  Widget build(BuildContext context) {
    final LatLng cafeLatLng = LatLng(latitude, longitude);
    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: cafeLatLng,
        zoom: 15,
      ),
      markers: {
        Marker(
          markerId: const MarkerId('cafe'),
          position: cafeLatLng,
        ),
      },
      zoomControlsEnabled: false,
      myLocationButtonEnabled: false,
      mapToolbarEnabled: false,
      liteModeEnabled: true,
      onTap: (_) {},
    );
  }
}

// Widget pre otváracie hodiny
class _OpeningHoursRow extends StatelessWidget {
  final String day;
  final String hours;
  const _OpeningHoursRow({required this.day, required this.hours});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text(day, style: const TextStyle(fontSize: 16)),
          ),
          const SizedBox(width: 8),
          Text(hours, style: const TextStyle(fontSize: 16, color: Colors.black87)),
        ],
      ),
    );
  }
}

// Widget pre recenziu
class _ReviewItem extends StatelessWidget {
  final String name;
  final String info;
  final String time;
  final int rating;
  final String text;
  const _ReviewItem({required this.name, required this.info, required this.time, required this.rating, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 320,
      margin: const EdgeInsets.only(right: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.black12,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 16),
              // Meno a info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 2),
                    Text(info, style: const TextStyle(color: Colors.black54, fontSize: 13)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Hviezdičky a čas pod avatarom
          Row(
            children: [
              Row(
                children: List.generate(5, (i) => Icon(
                  i < rating ? Icons.star : Icons.star_border,
                  color: Colors.amber,
                  size: 18,
                )),
              ),
              const SizedBox(width: 8),
              Text(time, style: const TextStyle(color: Colors.black54, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 8),
          // Text recenzie
          Text(text, style: const TextStyle(fontSize: 15)),
          const SizedBox(height: 2),
          TextButton(
            onPressed: () {},
            style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size(0, 0)),
            child: const Text('Ukázať viac', style: TextStyle(fontSize: 14, color: Colors.black54, decoration: TextDecoration.underline)),
          ),
        ],
      ),
    );
  }
}

// Modal pre výber služby
class _ServiceSelectionModal extends StatelessWidget {
  final String serviceName;
  final bool? currentValue;
  final Function(bool?) onValueSelected;

  const _ServiceSelectionModal({
    required this.serviceName,
    required this.currentValue,
    required this.onValueSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Názov služby
            Text(
              serviceName,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.black,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            
            // Tlačidlá pre výber
            Row(
              children: [
                // Áno tlačidlo
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      onValueSelected(true);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text(
                      'Áno',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                
                // Nie tlačidlo
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      onValueSelected(false);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text(
                      'Nie',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Nezadané tlačidlo
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  onValueSelected(null);
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.grey,
                  side: const BorderSide(color: Colors.grey, width: 2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  'Nezadané',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Zrušiť tlačidlo
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text(
                'Zrušiť',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 