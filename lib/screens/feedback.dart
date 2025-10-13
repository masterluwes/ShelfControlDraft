import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shelf_control/services/firestore_service.dart';
import 'dart:io';

class FeedbackPage extends StatefulWidget {
  const FeedbackPage({super.key});

  @override
  State<FeedbackPage> createState() => _FeedbackPageState();
}

class _FeedbackPageState extends State<FeedbackPage> {
  // Brand palette
  static const Color headerGreen = Color(0xFF2E7D32);
  static const Color softCream = Color(0xFFFFFBE6);
  static const Color mutedGreen = Color(0xFF6D845F);

  // Feedback state
  int? _rating; // 0..4
  String? _category;
  final TextEditingController _comments = TextEditingController();

  final List<String> _categories = const [
    'Bug Report',
    'Feature Request',
    'UI/UX',
    'Performance',
    'Other',
  ];

  File? _pickedFile; // To store the selected image file
  bool _isSubmitting = false; // To manage loading state

  @override
  void dispose() {
    _comments.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        _pickedFile = File(image.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: softCream,
      body: SafeArea(
        child: Column(
          children: [
            // Back row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Row(
                      children: [
                        Icon(Icons.arrow_back, color: headerGreen),
                        SizedBox(width: 4),
                        Text(
                          'Back',
                          style: TextStyle(
                            color: headerGreen,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Body
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 30,
                  vertical: 8,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text(
                      'Feedback',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 33,
                        fontWeight: FontWeight.bold,
                        color: headerGreen,
                        fontFamily: 'Inter',
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Illustration from assets
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 1),
                      alignment: Alignment.center,
                      child: SizedBox(
                        width: 150,
                        height: 150,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Image.asset(
                            'assets/feedback.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),

                    // Rating card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x14000000),
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          const Text(
                            'Please rate your experience',
                            style: TextStyle(
                              color: headerGreen,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              RatingChip(
                                label: 'Excellent',
                                icon: Icons.sentiment_very_satisfied,
                                selected: _rating == 0,
                                onTap: () => setState(() => _rating = 0),
                              ),
                              RatingChip(
                                label: 'Good',
                                icon: Icons.sentiment_satisfied,
                                selected: _rating == 1,
                                onTap: () => setState(() => _rating = 1),
                              ),
                              RatingChip(
                                label: 'Okay',
                                icon: Icons.sentiment_neutral,
                                selected: _rating == 2,
                                onTap: () => setState(() => _rating = 2),
                              ),
                              RatingChip(
                                label: 'Fair',
                                icon: Icons.sentiment_dissatisfied,
                                selected: _rating == 3,
                                onTap: () => setState(() => _rating = 3),
                              ),
                              RatingChip(
                                label: 'Poor',
                                icon: Icons.sentiment_very_dissatisfied,
                                selected: _rating == 4,
                                onTap: () => setState(() => _rating = 4),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 18),

                    // Category (label + dropdown aligned on one row)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Text(
                          'Category',
                          style: TextStyle(
                            color: Colors.black87,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: CategoryPill(
                            value: _category,
                            items: _categories,
                            onChanged: (val) => setState(() => _category = val),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Comments
                    _sectionLabel('Additional Comments'),
                    const SizedBox(height: 6),
                    CommentsBox(controller: _comments),

                    const SizedBox(height: 16),

                    // Upload
                    _sectionLabel('Attach Files (Optional)'),
                    const SizedBox(height: 8),
                    UploadTile(
                      onTap: _pickFile,
                      fileName: _pickedFile?.path.split('/').last, // Display file name
                      onClear: () {
                        setState(() {
                          _pickedFile = null;
                        });
                      },
                    ),

                    const SizedBox(height: 24),

                    // Submit
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: headerGreen,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: _isSubmitting ? null : _handleSubmit,
                        child: _isSubmitting
                            ? const CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              )
                            : const Text(
                                'Submit',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _sectionLabel(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.black87,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  void _handleSubmit() async {
    if (_rating == null || _category == null || _comments.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please provide a rating, category, and comments.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final firestoreService = Provider.of<FirestoreService>(context, listen: false);
    final userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User not logged in. Cannot submit feedback.'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() {
        _isSubmitting = false;
      });
      return;
    }

    String? fileUrl;
    if (_pickedFile != null) {
      final fileName = 'feedback/${userId}_${DateTime.now().millisecondsSinceEpoch}_${_pickedFile!.path.split('/').last}';
      fileUrl = await firestoreService.uploadFile(_pickedFile!, fileName);
    }

    try {
      await firestoreService.addFeedback(
        userId: userId,
        rating: _rating!,
        category: _category!,
        comments: _comments.text.trim(),
        fileUrl: fileUrl,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Feedback submitted successfully!'),
          backgroundColor: headerGreen,
        ),
      );

      // Clear form
      setState(() {
        _rating = null;
        _category = null;
        _comments.clear();
        _pickedFile = null;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to submit feedback: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }
}

/// ---------- Feedback widgets ----------

class RatingChip extends StatelessWidget {
  const RatingChip({super.key, 
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  static const Color headerGreen = _FeedbackPageState.headerGreen;

  @override
  Widget build(BuildContext context) {
    final Color fg = selected ? Colors.white : Colors.black87;
    final Color ic = selected ? Colors.white : Colors.black87;
    final Color bg = selected ? headerGreen : Colors.transparent;

    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Container(
        width: 56,
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Icon(icon, size: 24, color: ic),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: fg),
            ),
          ],
        ),
      ),
    );
  }
}

class CategoryPill extends StatelessWidget {
  const CategoryPill({super.key, 
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String? value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  static const Color headerGreen = _FeedbackPageState.headerGreen;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x11000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: ButtonTheme(
        alignedDropdown:
            true, // <-- makes the menu match button width & align left
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: value,
            isExpanded: true, // <-- fills the pill; overlay uses same width
            alignment: Alignment.centerLeft, // <-- text/overlay left-aligned
            hint: const Text(
              'Select',
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: TextStyle(color: Colors.black54, fontSize: 14),
            ),
            selectedItemBuilder: (context) => items
                .map(
                  (e) => Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      e,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                )
                .toList(),
            items: items
                .map(
                  (e) => DropdownMenuItem<String>(
                    value: e,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        e,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ),
                )
                .toList(),
            onChanged: onChanged,
            icon: const Icon(Icons.keyboard_arrow_down, color: headerGreen),
            menuMaxHeight: 280,
          ),
        ),
      ),
    );
  }
}

class CommentsBox extends StatelessWidget {
  const CommentsBox({super.key, required this.controller});
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 125, // ← adjust the overall height here
      child: TextField(
        controller: controller,
        expands: true, // ← fill the SizedBox height
        maxLines: null,
        minLines: null,
        textAlignVertical: TextAlignVertical.top,
        decoration: InputDecoration(
          hintText: 'Share your thoughts here...',
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.all(14), // ← inner padding
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
          ),
        ),
      ),
    );
  }
}

class UploadTile extends StatelessWidget {
  const UploadTile({
    super.key,
    required this.onTap,
    this.fileName,
    this.onClear,
  });

  final VoidCallback onTap;
  final String? fileName;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 180, // Increased width to accommodate file name
          height: 80,
          decoration: BoxDecoration(
            color: const Color(0xFFF6F0D8),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE9E1C5)),
          ),
          child: Center(
            child: fileName != null
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(left: 12.0),
                          child: Text(
                            fileName!,
                            style: const TextStyle(fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      if (onClear != null)
                        IconButton(
                          icon: const Icon(Icons.close, size: 18),
                          onPressed: onClear,
                        ),
                    ],
                  )
                : const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.cloud_upload_outlined, color: Colors.black54),
                      SizedBox(height: 6),
                      Text('Upload Files', style: TextStyle(fontSize: 12)),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
