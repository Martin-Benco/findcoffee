import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/models.dart';
import '../core/firebase_service.dart';

class ReviewFormDialog extends StatefulWidget {
  final String cafeId;
  final String cafeName;

  const ReviewFormDialog({
    super.key,
    required this.cafeId,
    required this.cafeName,
  });

  @override
  State<ReviewFormDialog> createState() => _ReviewFormDialogState();
}

class _ReviewFormDialogState extends State<ReviewFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _textController = TextEditingController();
  final _firebaseService = FirebaseService();
  
  int _selectedRating = 5;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _submitReview() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      print('DEBUG: Current user: $user');
      print('DEBUG: User UID: ${user?.uid}');
      print('DEBUG: User email: ${user?.email}');
      print('DEBUG: User display name: ${user?.displayName}');
      
      if (user == null) {
        throw Exception('Používateľ nie je prihlásený');
      }

      // Skontrolujeme, či používateľ už napísal recenziu
      final hasReviewed = await _firebaseService.hasUserReviewed(widget.cafeId);
      if (hasReviewed) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Už ste napísali recenziu pre túto kaviareň'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // Vytvoríme recenziu
      final review = Review(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        cafeId: widget.cafeId,
        userId: user.uid,
        userName: user.displayName?.isNotEmpty == true 
            ? user.displayName! 
            : user.email?.split('@').first ?? 'Anonymný používateľ',
        userEmail: user.email ?? '',
        rating: _selectedRating,
        text: _textController.text.trim(),
        createdAt: DateTime.now(),
        userInfo: 'Nový používateľ', // Môžeme to neskôr rozšíriť
      );

      // Pridáme recenziu do databázy
      await _firebaseService.addReview(review);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Recenzia bola úspešne pridaná!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      print('DETAILNÁ CHYBA PRI PRIDÁVANÍ RECENZIE: $e');
      print('Error type: ${e.runtimeType}');
      if (e is FirebaseException) {
        print('Firebase error code: ${e.code}');
        print('Firebase error message: ${e.message}');
      }
      
      if (mounted) {
        String errorMessage = 'Chyba pri pridávaní recenzie';
        if (e is FirebaseException) {
          switch (e.code) {
            case 'permission-denied':
              errorMessage = 'Nemáte oprávnenie na pridanie recenzie';
              break;
            case 'unavailable':
              errorMessage = 'Služba je dočasne nedostupná';
              break;
            default:
              errorMessage = 'Chyba databázy: ${e.message}';
          }
        } else {
          errorMessage = 'Chyba: $e';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Pridať recenziu',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                widget.cafeName,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 24),

              // Rating
              const Text(
                'Hodnotenie:',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: List.generate(5, (index) {
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedRating = index + 1;
                      });
                    },
                    child: Icon(
                      index < _selectedRating ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: 32,
                    ),
                  );
                }),
              ),
              const SizedBox(height: 24),

              // Review text
              const Text(
                'Vaša recenzia:',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _textController,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: 'Napíšte svoju recenziu...',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.all(12),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Prosím napíšte recenziu';
                  }
                  if (value.trim().length < 10) {
                    return 'Recenzia musí mať aspoň 10 znakov';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Zrušiť'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submitReview,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF603013),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text('Pridať recenziu'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
