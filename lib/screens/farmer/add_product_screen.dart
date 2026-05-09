import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../providers/auth_provider.dart';
import '../../services/product_service.dart';
import '../../services/asset_image_service.dart';
import '../../models/product_model.dart';
import '../../theme/app_theme.dart';
import '../../utils/constants.dart';
import '../../widgets/custom_text_field.dart';

class AddProductScreen extends StatefulWidget {
  final ProductModel? editProduct;
  const AddProductScreen({super.key, this.editProduct});
  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _quantityCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  String _selectedCategory = 'Wheat';
  String _selectedUnit = 'kg';
  String _selectedLocation = '';

  List<File> _pickedImages = [];         // camera / gallery
  List<File> _selectedAssetImages = [];  // chosen from bundled library
  List<String> _existingImagePaths = []; // when editing

  bool _isLoading = false;
  final _productService = ProductService();

  bool get _isEditing => widget.editProduct != null;
  List<File> get _allNewImages => [..._selectedAssetImages, ..._pickedImages];

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final p = widget.editProduct!;
      _nameCtrl.text = p.name;
      _priceCtrl.text = p.pricePerUnit.toStringAsFixed(0);
      _quantityCtrl.text = p.quantityAvailable.toString();
      _descCtrl.text = p.description;
      _selectedLocation = p.location;
      _selectedCategory = p.category;
      _selectedUnit = p.unit;
      _existingImagePaths = List.from(p.imagePaths);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _priceCtrl.dispose();
    _quantityCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickFromGallery() async {
    final picker = ImagePicker();
    final images = await picker.pickMultiImage(imageQuality: 75);
    if (images.isNotEmpty) {
      setState(() {
        _pickedImages = [..._pickedImages, ...images.map((x) => File(x.path))];
      });
    }
  }

  Future<void> _pickFromCamera() async {
    final picker = ImagePicker();
    final img = await picker.pickImage(source: ImageSource.camera, imageQuality: 75);
    if (img != null) setState(() => _pickedImages.add(File(img.path)));
  }

  void _openImageSourceSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ImageSourceSheet(
        category: _selectedCategory,
        selectedAssetImages: _selectedAssetImages,
        onAssetToggled: (file, selected) {
          setState(() {
            if (selected) {
              _selectedAssetImages.add(file);
            } else {
              _selectedAssetImages.removeWhere((f) => f.path == file.path);
            }
          });
        },
        onGallery: () { Navigator.pop(context); _pickFromGallery(); },
        onCamera: () { Navigator.pop(context); _pickFromCamera(); },
      ),
    );
  }

  Future<void> _pickLocation() async {
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _CityPickerSheet(),
    );
    if (result != null) setState(() => _selectedLocation = result);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final user = context.read<AuthProvider>().currentUser!;
    final location = _selectedLocation.isNotEmpty ? _selectedLocation : user.city;
    setState(() => _isLoading = true);
    try {
      final imagesToSave = _allNewImages.isNotEmpty ? _allNewImages : null;
      if (_isEditing) {
        final updated = widget.editProduct!.copyWith(
          name: _nameCtrl.text.trim(),
          category: _selectedCategory,
          pricePerUnit: double.parse(_priceCtrl.text),
          unit: _selectedUnit,
          quantityAvailable: int.parse(_quantityCtrl.text),
          description: _descCtrl.text.trim(),
          location: location,
        );
        await _productService.updateProduct(updated, newImages: imagesToSave);
      } else {
        final product = ProductModel(
          id: '',
          farmerId: user.id,
          farmerName: user.fullName,
          farmerPhone: user.phoneNumber,
          farmerCity: user.city,
          farmerRating: user.rating,
          name: _nameCtrl.text.trim(),
          category: _selectedCategory,
          pricePerUnit: double.parse(_priceCtrl.text),
          unit: _selectedUnit,
          quantityAvailable: int.parse(_quantityCtrl.text),
          location: location,
          imagePaths: [],
          description: _descCtrl.text.trim(),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await _productService.addProduct(product, localImages: imagesToSave);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(_isEditing ? '✅ Product updated!' : '✅ Product added!'),
        backgroundColor: AppTheme.successGreen,
        behavior: SnackBarBehavior.floating,
      ));
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error: ${e.toString()}'),
        backgroundColor: AppTheme.errorRed,
      ));
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    if (_selectedLocation.isEmpty && user != null && user.city.isNotEmpty) {
      _selectedLocation = user.city;
    }

    final allDisplayImages = [
      ..._existingImagePaths.map((p) => _ImgSrc.existing(p)),
      ..._selectedAssetImages.map((f) => _ImgSrc.asset(f)),
      ..._pickedImages.map((f) => _ImgSrc.picked(f)),
    ];

    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Edit Product' : 'Add New Product')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

            // ── Images ────────────────────────────────────────────────────
            Text('Product Images', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text('Select from crop library, gallery, or take a photo',
                style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 10),

            SizedBox(
              height: 102,
              child: Row(children: [
                // Add button
                GestureDetector(
                  onTap: _openImageSourceSheet,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 90, height: 90,
                    decoration: BoxDecoration(
                      color: Color(AppConstants.getCropColor(_selectedCategory)).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: Color(AppConstants.getCropColor(_selectedCategory)).withOpacity(0.5),
                        width: 1.5,
                      ),
                    ),
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      if (allDisplayImages.isEmpty) ...[
                        Text(AppConstants.getCropEmoji(_selectedCategory),
                            style: const TextStyle(fontSize: 30)),
                        const SizedBox(height: 2),
                        const Icon(Icons.add_circle_outline,
                            size: 16, color: AppTheme.primaryGreen),
                        const Text('Add', style: TextStyle(fontSize: 9,
                            color: AppTheme.primaryGreen, fontWeight: FontWeight.w600)),
                      ] else ...[
                        const Icon(Icons.add_photo_alternate_outlined,
                            color: AppTheme.primaryGreen, size: 26),
                        const SizedBox(height: 4),
                        const Text('Add More', style: TextStyle(fontSize: 9,
                            color: AppTheme.primaryGreen, fontWeight: FontWeight.w600)),
                      ],
                    ]),
                  ),
                ),
                const SizedBox(width: 8),

                Expanded(
                  child: allDisplayImages.isEmpty
                      ? Center(
                          child: Text(
                            'Tap ${AppConstants.getCropEmoji(_selectedCategory)} to add images',
                            style: const TextStyle(fontSize: 12, color: AppTheme.textMedium),
                            textAlign: TextAlign.center,
                          ),
                        )
                      : ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: allDisplayImages.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 8),
                          itemBuilder: (_, i) {
                            final src = allDisplayImages[i];
                            return _ImageThumb(
                              child: _buildThumbWidget(src),
                              onRemove: () => _removeImage(src),
                            );
                          },
                        ),
                ),
              ]),
            ),
            const SizedBox(height: 20),

            // ── Category ──────────────────────────────────────────────────
            Text('Crop Category', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            SizedBox(
              height: 82,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: AppConstants.cropCategories.where((c) => c != 'All').length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final cat = AppConstants.cropCategories.where((c) => c != 'All').toList()[i];
                  final isSelected = cat == _selectedCategory;
                  return GestureDetector(
                    onTap: () => setState(() {
                      _selectedCategory = cat;
                      if (_nameCtrl.text.isEmpty) _nameCtrl.text = cat;
                    }),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: 68,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Color(AppConstants.getCropColor(cat)).withOpacity(0.15)
                            : AppTheme.cardWhite,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected ? Color(AppConstants.getCropColor(cat)) : AppTheme.divider,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Text(AppConstants.getCropEmoji(cat), style: const TextStyle(fontSize: 26)),
                        const SizedBox(height: 4),
                        Text(cat, style: TextStyle(
                          fontSize: 10,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected ? Color(AppConstants.getCropColor(cat)) : AppTheme.textMedium,
                        ), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
                      ]),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),

            // ── Name ──────────────────────────────────────────────────────
            CustomTextField(
              controller: _nameCtrl,
              label: 'Product Name',
              hint: 'e.g., Premium Wheat, Basmati Rice',
              prefixIcon: Icons.grass_outlined,
              validator: (v) => v == null || v.trim().isEmpty ? 'Name is required' : null,
            ),
            const SizedBox(height: 14),

            // ── Price & Unit ──────────────────────────────────────────────
            Row(children: [
              Expanded(
                flex: 2,
                child: CustomTextField(
                  controller: _priceCtrl,
                  label: 'Price (PKR)',
                  hint: '2600',
                  prefixIcon: Icons.payments_outlined,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Required';
                    if (double.tryParse(v) == null) return 'Invalid number';
                    if (double.parse(v) <= 0) return 'Must be > 0';
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _selectedUnit,
                  decoration: InputDecoration(
                    labelText: 'Unit',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  ),
                  items: ['kg', '40kg', 'quintal', 'maund', 'ton', 'piece']
                      .map((u) => DropdownMenuItem(value: u, child: Text(u)))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedUnit = v!),
                ),
              ),
            ]),
            const SizedBox(height: 14),

            // ── Quantity ──────────────────────────────────────────────────
            CustomTextField(
              controller: _quantityCtrl,
              label: 'Quantity Available',
              hint: '80',
              prefixIcon: Icons.inventory_2_outlined,
              keyboardType: TextInputType.number,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Required';
                if (int.tryParse(v) == null) return 'Must be whole number';
                if (int.parse(v) <= 0) return 'Must be > 0';
                return null;
              },
            ),
            const SizedBox(height: 14),

            // ── Location ──────────────────────────────────────────────────
            Text('Location', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _pickLocation,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
                decoration: BoxDecoration(
                  color: AppTheme.cardWhite,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.divider),
                ),
                child: Row(children: [
                  const Icon(Icons.location_on_outlined, color: AppTheme.primaryGreen, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _selectedLocation.isEmpty ? 'Select city / district' : _selectedLocation,
                      style: TextStyle(
                        fontSize: 15,
                        color: _selectedLocation.isEmpty ? AppTheme.textMedium : AppTheme.textDark,
                      ),
                    ),
                  ),
                  const Icon(Icons.arrow_drop_down, color: AppTheme.textMedium),
                ]),
              ),
            ),
            const SizedBox(height: 14),

            // ── Description ───────────────────────────────────────────────
            CustomTextField(
              controller: _descCtrl,
              label: 'Product Description',
              hint: 'Quality details, harvest date, storage info...',
              prefixIcon: Icons.description_outlined,
              maxLines: 3,
            ),
            const SizedBox(height: 28),

            // ── Submit ────────────────────────────────────────────────────
            LoadingButton(
              label: _isEditing ? 'Update Product' : 'Submit Product',
              isLoading: _isLoading,
              onPressed: _submit,
            ),
            const SizedBox(height: 32),
          ]),
        ),
      ),
    );
  }

  Widget _buildThumbWidget(_ImgSrc src) {
    File f;
    if (src.path != null) {
      f = File(src.path!);
      if (!f.existsSync()) {
        return Container(
          color: Color(AppConstants.getCropColor(_selectedCategory)).withOpacity(0.1),
          child: Center(child: Text(AppConstants.getCropEmoji(_selectedCategory),
              style: const TextStyle(fontSize: 32))),
        );
      }
    } else {
      f = src.file!;
    }
    return Image.file(f, fit: BoxFit.cover, width: 90, height: 90);
  }

  void _removeImage(_ImgSrc src) {
    setState(() {
      if (src.path != null && src.file == null) {
        _existingImagePaths.remove(src.path);
      } else if (src.isAsset) {
        _selectedAssetImages.removeWhere((f) => f.path == src.file!.path);
      } else {
        _pickedImages.removeWhere((f) => f.path == src.file!.path);
      }
    });
  }
}

// ── Image Source Model ─────────────────────────────────────────────────────

class _ImgSrc {
  final String? path;
  final File? file;
  final bool isAsset;

  const _ImgSrc._({this.path, this.file, required this.isAsset});

  factory _ImgSrc.existing(String p) => _ImgSrc._(path: p, isAsset: false);
  factory _ImgSrc.asset(File f) => _ImgSrc._(file: f, isAsset: true);
  factory _ImgSrc.picked(File f) => _ImgSrc._(file: f, isAsset: false);
}

// ── Image Source Bottom Sheet ──────────────────────────────────────────────

class _ImageSourceSheet extends StatefulWidget {
  final String category;
  final List<File> selectedAssetImages;
  final void Function(File, bool) onAssetToggled;
  final VoidCallback onGallery;
  final VoidCallback onCamera;

  const _ImageSourceSheet({
    required this.category,
    required this.selectedAssetImages,
    required this.onAssetToggled,
    required this.onGallery,
    required this.onCamera,
  });

  @override
  State<_ImageSourceSheet> createState() => _ImageSourceSheetState();
}

class _ImageSourceSheetState extends State<_ImageSourceSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  List<File> _categoryImages = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    _loadImages();
  }

  Future<void> _loadImages() async {
    final imgs = await AssetImageService.getLocalImagesForCategory(widget.category);
    if (mounted) setState(() { _categoryImages = imgs; _loading = false; });
  }

  @override
  void dispose() { _tabCtrl.dispose(); super.dispose(); }

  bool _isSelected(File f) =>
      widget.selectedAssetImages.any((s) => s.path == f.path);

  @override
  Widget build(BuildContext context) {
    final cropColor = Color(AppConstants.getCropColor(widget.category));
    final svgIconPath = AssetImageService.categoryIcons[widget.category];

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(children: [
        const SizedBox(height: 8),
        Container(width: 40, height: 4,
            decoration: BoxDecoration(color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 12),

        // Title row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(children: [
            // Crop icon (SVG or emoji fallback)
            if (svgIconPath != null)
              SvgPicture.asset(svgIconPath, width: 28, height: 28,
                  colorFilter: ColorFilter.mode(cropColor, BlendMode.srcIn))
            else
              Text(AppConstants.getCropEmoji(widget.category),
                  style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 10),
            Expanded(child: Text('Add ${widget.category} Images',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700))),
            IconButton(icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context)),
          ]),
        ),

        // Tabs
        TabBar(
          controller: _tabCtrl,
          labelColor: cropColor,
          unselectedLabelColor: AppTheme.textMedium,
          indicatorColor: cropColor,
          labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          tabs: const [
            Tab(icon: Icon(Icons.collections_bookmark_outlined, size: 18), text: 'Crop Library'),
            Tab(icon: Icon(Icons.photo_library_outlined, size: 18), text: 'Gallery'),
            Tab(icon: Icon(Icons.camera_alt_outlined, size: 18), text: 'Camera'),
          ],
        ),
        const Divider(height: 1),

        Expanded(
          child: TabBarView(
            controller: _tabCtrl,
            children: [

              // ── Tab 1: Crop Library ──────────────────────────────────────
              _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _categoryImages.isEmpty
                      ? _EmptyLibrary(category: widget.category)
                      : Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            // Selected badge
                            if (widget.selectedAssetImages.isNotEmpty)
                              Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: cropColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: cropColor.withOpacity(0.4)),
                                ),
                                child: Text(
                                  '${widget.selectedAssetImages.length} selected — offline ready ✓',
                                  style: TextStyle(fontSize: 12, color: cropColor,
                                      fontWeight: FontWeight.w600),
                                ),
                              ),
                            Text('${widget.category} photos — tap to select (works offline)',
                                style: const TextStyle(fontSize: 12, color: AppTheme.textMedium)),
                            const SizedBox(height: 10),
                            Expanded(
                              child: GridView.builder(
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 3, crossAxisSpacing: 8, mainAxisSpacing: 8),
                                itemCount: _categoryImages.length,
                                itemBuilder: (_, i) {
                                  final f = _categoryImages[i];
                                  final sel = _isSelected(f);
                                  return GestureDetector(
                                    onTap: () {
                                      widget.onAssetToggled(f, !sel);
                                      setState(() {});
                                    },
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 150),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                            color: sel ? cropColor : Colors.transparent, width: 3),
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(10),
                                        child: Stack(fit: StackFit.expand, children: [
                                          Image.file(f, fit: BoxFit.cover),
                                          if (sel)
                                            Container(
                                              color: cropColor.withOpacity(0.25),
                                              child: Center(
                                                child: Container(
                                                  width: 28, height: 28,
                                                  decoration: BoxDecoration(
                                                      color: cropColor, shape: BoxShape.circle),
                                                  child: const Icon(Icons.check,
                                                      color: Colors.white, size: 16),
                                                ),
                                              ),
                                            ),
                                        ]),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            SafeArea(
                              child: Padding(
                                padding: const EdgeInsets.only(top: 10),
                                child: SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: cropColor,
                                      shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12)),
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                    ),
                                    onPressed: () => Navigator.pop(context),
                                    child: Text(
                                      widget.selectedAssetImages.isEmpty
                                          ? 'Close'
                                          : 'Done  (${widget.selectedAssetImages.length} selected)',
                                      style: const TextStyle(
                                          color: Colors.white, fontWeight: FontWeight.w700),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ]),
                        ),

              // ── Tab 2: Gallery ──────────────────────────────────────────
              Center(
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Container(
                    width: 80, height: 80,
                    decoration: BoxDecoration(
                        color: AppTheme.primaryGreen.withOpacity(0.1), shape: BoxShape.circle),
                    child: const Icon(Icons.photo_library_outlined,
                        color: AppTheme.primaryGreen, size: 36),
                  ),
                  const SizedBox(height: 16),
                  const Text('Open Photo Gallery',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  const Text('Select one or multiple product photos',
                      style: TextStyle(color: AppTheme.textMedium, fontSize: 13)),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: widget.onGallery,
                    icon: const Icon(Icons.photo_library_outlined),
                    label: const Text('Open Gallery'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ]),
              ),

              // ── Tab 3: Camera ───────────────────────────────────────────
              Center(
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Container(
                    width: 80, height: 80,
                    decoration: BoxDecoration(
                        color: AppTheme.primaryGreen.withOpacity(0.1), shape: BoxShape.circle),
                    child: const Icon(Icons.camera_alt_outlined,
                        color: AppTheme.primaryGreen, size: 36),
                  ),
                  const SizedBox(height: 16),
                  const Text('Take a Photo',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  const Text('Capture a fresh photo of your product',
                      style: TextStyle(color: AppTheme.textMedium, fontSize: 13)),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: widget.onCamera,
                    icon: const Icon(Icons.camera_alt_outlined),
                    label: const Text('Open Camera'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ]),
              ),
            ],
          ),
        ),
      ]),
    );
  }
}

// ── Empty Library ──────────────────────────────────────────────────────────

class _EmptyLibrary extends StatelessWidget {
  final String category;
  const _EmptyLibrary({required this.category});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text(AppConstants.getCropEmoji(category), style: const TextStyle(fontSize: 48)),
        const SizedBox(height: 12),
        Text('No $category library images yet',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        const Text('Use Gallery or Camera instead',
            style: TextStyle(color: AppTheme.textMedium)),
      ]),
    );
  }
}

// ── Image Thumb ────────────────────────────────────────────────────────────

class _ImageThumb extends StatelessWidget {
  final Widget child;
  final VoidCallback onRemove;
  const _ImageThumb({required this.child, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      Container(
        width: 90, height: 90,
        margin: const EdgeInsets.only(right: 2, top: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppTheme.divider),
        ),
        clipBehavior: Clip.antiAlias,
        child: child,
      ),
      Positioned(
        top: 0, right: 0,
        child: GestureDetector(
          onTap: onRemove,
          child: Container(
            width: 20, height: 20,
            decoration: const BoxDecoration(color: AppTheme.errorRed, shape: BoxShape.circle),
            child: const Icon(Icons.close, color: Colors.white, size: 12),
          ),
        ),
      ),
    ]);
  }
}

// ── City Picker ────────────────────────────────────────────────────────────

class _CityPickerSheet extends StatefulWidget {
  const _CityPickerSheet();
  @override
  State<_CityPickerSheet> createState() => _CityPickerSheetState();
}

class _CityPickerSheetState extends State<_CityPickerSheet> {
  final _searchCtrl = TextEditingController();
  List<String> _filtered = AppConstants.allPakistanCities;

  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  void _filter(String q) => setState(() {
    _filtered = q.isEmpty
        ? AppConstants.allPakistanCities
        : AppConstants.allPakistanCities
            .where((c) => c.toLowerCase().contains(q.toLowerCase()))
            .toList();
  });

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85, maxChildSize: 0.95, minChildSize: 0.5,
      expand: false,
      builder: (_, sc) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(children: [
          const SizedBox(height: 8),
          Container(width: 40, height: 4,
              decoration: BoxDecoration(color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2))),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Select Location', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 10),
              TextField(
                controller: _searchCtrl,
                autofocus: true,
                onChanged: _filter,
                decoration: InputDecoration(
                  hintText: 'Search city or district...',
                  prefixIcon: const Icon(Icons.search, color: AppTheme.primaryGreen),
                  suffixIcon: _searchCtrl.text.isNotEmpty
                      ? IconButton(icon: const Icon(Icons.clear, size: 18),
                          onPressed: () { _searchCtrl.clear(); _filter(''); })
                      : null,
                  filled: true, fillColor: AppTheme.background,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
              const SizedBox(height: 6),
              Text('${_filtered.length} locations available',
                  style: const TextStyle(fontSize: 12, color: AppTheme.textMedium)),
            ]),
          ),
          const Divider(height: 1),
          Expanded(
            child: _filtered.isEmpty
                ? const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('🔍', style: TextStyle(fontSize: 36)),
                      SizedBox(height: 8),
                      Text('No results found', style: TextStyle(color: AppTheme.textMedium)),
                    ]))
                : ListView.separated(
                    controller: sc,
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                    itemCount: _filtered.length,
                    separatorBuilder: (_, __) => const Divider(height: 1, color: AppTheme.divider),
                    itemBuilder: (_, i) => ListTile(
                      dense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                      leading: const Icon(Icons.location_on_outlined,
                          color: AppTheme.primaryGreen, size: 20),
                      title: Text(_filtered[i], style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w500)),
                      onTap: () => Navigator.pop(context, _filtered[i]),
                    ),
                  ),
          ),
        ]),
      ),
    );
  }
}
