import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../core/models.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class CafeDetailPage extends StatefulWidget {
  final Cafe cafe;
  
  const CafeDetailPage({super.key, required this.cafe});

  @override
  State<CafeDetailPage> createState() => _CafeDetailPageState();
}

class _CafeDetailPageState extends State<CafeDetailPage> {
  bool _isFavorite = false;
  String? _userEmail;

  @override
  void initState() {
    super.initState();
    _loadFavoriteStatus();
  }

  Future<void> _loadFavoriteStatus() async {
    final email = await getCurrentUserEmail();
    if (email == null) return;
    _userEmail = email;
    
    final prefs = await SharedPreferences.getInstance();
    final key = favoritesKeyForUser(email);
    final jsonStr = prefs.getString(key);
    if (jsonStr != null) {
      final favs = favoritesFromJson(jsonStr);
      setState(() {
        _isFavorite = favs.any((f) => f.type == FavoriteType.cafe && f.id == widget.cafe.name);
      });
    }
  }

  Future<void> _toggleFavorite() async {
    if (_userEmail == null) return;
    
    final prefs = await SharedPreferences.getInstance();
    final key = favoritesKeyForUser(_userEmail!);
    final jsonStr = prefs.getString(key);
    List<FavoriteItem> favs = jsonStr != null ? favoritesFromJson(jsonStr) : [];
    
    setState(() {
      if (_isFavorite) {
        favs.removeWhere((f) => f.type == FavoriteType.cafe && f.id == widget.cafe.name);
        _isFavorite = false;
      } else {
        favs.add(FavoriteItem(
          type: FavoriteType.cafe,
          id: widget.cafe.name,
          name: widget.cafe.name,
          imageUrl: widget.cafe.foto_url,
        ));
        _isFavorite = true;
      }
    });
    
    await prefs.setString(key, favoritesToJson(favs));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
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
                    left: 12,
                    top: 12 + MediaQuery.of(context).padding.top,
                    child: GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.85),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Center(child: Text('<', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold))),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 64,
                    top: 12 + MediaQuery.of(context).padding.top,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.85),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(child: Text('S', style: TextStyle(fontWeight: FontWeight.bold))),
                    ),
                  ),
                  Positioned(
                    right: 12,
                    top: 12 + MediaQuery.of(context).padding.top,
                    child: GestureDetector(
                      onTap: _toggleFavorite,
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.85),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(_isFavorite ? '♥' : '♡', style: const TextStyle(fontSize: 20)),
                        ),
                      ),
                    ),
                  ),
                  // Carousel číslovanie
                  Positioned(
                    right: 16,
                    bottom: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text('1/1', style: TextStyle(color: Colors.white)),
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
                          Text(
                            'Presov, hlavna...', // TODO: neskôr dynamicky
                            style: const TextStyle(color: Colors.grey, fontSize: 15),
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
                            const Text(' (560)', style: TextStyle(color: Colors.grey, fontSize: 13)), // TODO: dynamicky
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${widget.cafe.distanceKm.toStringAsFixed(1)} km',
                          style: const TextStyle(color: Colors.grey, fontSize: 15),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Divider
              const Divider(thickness: 1, height: 1),
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
                    // Káva sekcia
                    const Text('Káva', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    const SizedBox(height: 10),
                    _MenuItemRow(name: 'Espresso', price: '1.20 €', desc: 'Nevies co preso debile?'),
                    _MenuItemRow(name: 'Latte', price: '1.20 €', desc: 'Nevies co preso debile?', badge: 'Populárne'),
                    _MenuItemRow(name: 'Lungo', price: '1.20 €', desc: 'Nevies co preso debile?'),
                    _MenuItemRow(name: 'Doppio', price: '1.20 €', desc: 'Nevies co preso debile?'),
                    const SizedBox(height: 18),
                    // Limonády sekcia
                    const Text('Limonády', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    const SizedBox(height: 10),
                    _MenuItemRow(name: 'Baza s maslom', price: '8.30 €', desc: 'Nedavaj si'),
                    _MenuItemRow(name: 'Baza s maslom', price: '8.30 €', desc: 'Nedavaj si'),
                    _MenuItemRow(name: 'Baza s maslom', price: '8.30 €', desc: 'Nedavaj si'),
                    _MenuItemRow(name: 'Baza s maslom', price: '8.30 €', desc: 'Nedavaj si'),
                  ],
                ),
              ),
              // Divider
              const Divider(thickness: 1, height: 1),
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
              const Divider(thickness: 1, height: 1),
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
              const Divider(thickness: 1, height: 1),
              // Otváracie hodiny sekcia
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Otváracie hodiny', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                    const SizedBox(height: 12),
                    _OpeningHoursRow(day: 'Po', hours: '9:00 – 16.15'),
                    _OpeningHoursRow(day: 'Ut', hours: '9:00 – 16.15'),
                    _OpeningHoursRow(day: 'St', hours: '9:00 – 16.15'),
                    _OpeningHoursRow(day: 'Št', hours: '9:00 – 16.15'),
                    _OpeningHoursRow(day: 'Pi', hours: '9:00 – 16.15'),
                    _OpeningHoursRow(day: 'So', hours: '9:00 – 16.15'),
                    _OpeningHoursRow(day: 'Ne', hours: '9:00 – 16.15'),
                  ],
                ),
              ),
              // Divider
              const Divider(thickness: 1, height: 1),
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
                            name: 'Lubo Gay',
                            info: '18 mesiacov na coffite',
                            time: 'pred 2 dňami',
                            rating: 5,
                            text: 'Bola to cislo fantazia, ou je vyhlad po pi, nmmozem z toho asi pridem znova ou je, volam sa llllllubik',
                          ),
                          const SizedBox(width: 24),
                          _ReviewItem(
                            name: 'Lubo Gay',
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
              const Divider(thickness: 1, height: 1),
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
                            child: Text('lubogay@gmail.com', style: TextStyle(fontSize: 16)),
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
        ),
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