import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../core/models.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../core/firebase_service.dart';
import '../core/utils.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/services.dart';

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
  final FirebaseService _firebaseService = FirebaseService();
  late AnimationController _animationController;
  late Animation<double> _heightAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _loadFavoriteStatus();
    
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
              child: Image.network(
                widget.cafe.foto_url,
                fit: BoxFit.cover,
                width: double.infinity,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: AppColors.grey,
                  child: const Icon(Icons.image_not_supported, color: Colors.white70, size: 64),
                ),
              ),
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
              right: 64,
              top: 16,
              child: SvgPicture.asset(
                'assets/icons/Share.svg',
                width: 30,
                height: 30,
                color: Colors.white,
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
                      widget.cafe.name.length > 15
                        ? widget.cafe.name.substring(0, 15) + '...'
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
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 22),
                      const SizedBox(width: 4),
                      Text(
                        widget.cafe.rating.toStringAsFixed(1),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                      const SizedBox(width: 2),
                      const Text(' (560)', style: TextStyle(color: Colors.grey, fontSize: 13)),
                    ],
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
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Carousel obrázkov s overlay ikonami
          Stack(
            children: [
              AspectRatio(
                aspectRatio: 1.5,
                child: Image.network(
                  widget.cafe.foto_url,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: AppColors.grey,
                    child: const Icon(Icons.image_not_supported, color: Colors.white70, size: 64),
                  ),
                ),
              ),
              // Overlay ikony
              Positioned(
                left: 16,
                top: 16 + MediaQuery.of(context).padding.top,
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
                right: 64,
                top: 16 + MediaQuery.of(context).padding.top,
                child: SvgPicture.asset(
                  'assets/icons/Share.svg',
                  width: 30,
                  height: 30,
                  color: Colors.white,
                ),
              ),
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
                        widget.cafe.name.length > 15
                          ? widget.cafe.name.substring(0, 15) + '...'
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
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 22),
                        const SizedBox(width: 4),
                        Text(
                          widget.cafe.rating.toStringAsFixed(1),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                        const SizedBox(width: 2),
                        const Text(' (560)', style: TextStyle(color: Colors.grey, fontSize: 13)),
                      ],
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Menu', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
                    TextButton(
                      onPressed: () {},
                      style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size(0, 0)),
                      child: const Text('Je v menu viac produktov?', style: TextStyle(fontSize: 14, color: Colors.black54, decoration: TextDecoration.underline)),
                    ),
                  ],
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
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        'Toto miesto ponúka:',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {},
                          style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size(0, 0)),
                          child: Text(
                            'Myslíte si, že toto miesto ponúka viac?',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.black54,
                              decoration: TextDecoration.underline,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                _ServiceRow(label: 'Wifi'),
                const SizedBox(height: 18),
                _ServiceRow(label: 'Parking'),
                const SizedBox(height: 18),
                _ServiceRow(label: 'Výhľad'),
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
                SizedBox(
                  height: 210,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _ReviewItem(
                        name: 'Mato noob',
                        info: '18 mesiacov na coffite',
                        time: 'pred 2 dňami',
                        rating: 5,
                        text: 'Bola to cislo fantazia, ou je vyhlad po pi, nmmozem z toho asi pridem znova ou je, volam sa llllllubik',
                      ),
                      const SizedBox(width: 24),
                      _ReviewItem(
                        name: 'Mato noob',
                        info: '18 mesiacov na coffite',
                        time: 'pred 2 dňami',
                        rating: 5,
                        text: 'Bola to cislo fantazia, ou je vyhlad po pi, nmmozem z toho asi pridem znova ou je, volam sa llllllubik',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                // Buttony
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF603013),
                      side: const BorderSide(color: Color(0xFF603013), width: 2),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 18),
                    ),
                    child: const Text('Ukázať všetkých 56 recenzií', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {},
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
            ),
          ),
          // Divider
          Center(
            child: Container(
              width: MediaQuery.of(context).size.width * 0.85,
              child: const Divider(thickness: 1, height: 1),
            ),
          ),
          // Kontakt sekcia
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Kontakt', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Icon(Icons.phone, size: 32, color: Colors.black87),
                    const SizedBox(width: 18),
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Text('0915 123 456', style: TextStyle(fontSize: 16)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Icon(Icons.mail, size: 32, color: Colors.black87),
                    const SizedBox(width: 18),
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Text('matonoob@gmail.com', style: TextStyle(fontSize: 16)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF603013),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(vertical: 18),
                    ),
                    child: const Text('Napísať správu', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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
class _ServiceRow extends StatelessWidget {
  final String label;
  const _ServiceRow({required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
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
        Text(label, style: const TextStyle(fontSize: 18)),
      ],
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