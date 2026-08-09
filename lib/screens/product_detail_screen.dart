import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../constants.dart';
import '../models/product.dart';
import '../services/product_service.dart';
import '../widgets/custom_text.dart';

class ProductDetailScreen extends StatefulWidget {
  const ProductDetailScreen({super.key});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final ProductService _productService = ProductService();
  Product? _product;
  bool _isLoading = true;
  String _errorMessage = '';
  bool _isInitialized = false;

  bool _isFavorite = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      final productId = ModalRoute.of(context)!.settings.arguments as int;
      _loadProductDetails(productId);
      _isInitialized = true;
    }
  }

  Future<void> _loadProductDetails(int id) async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      final product = await _productService.getProductById(id);
      setState(() {
        _product = product;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get color theme information from context
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: isDark ? AppColors.sand : AppColors.tealDeep),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: _buildSkeletonDetail(theme, isDark),
      );
    }

    if (_errorMessage.isNotEmpty || _product == null) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: isDark ? AppColors.sand : AppColors.tealDeep),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(24.r),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline_rounded, size: 64.sp, color: theme.colorScheme.error),
                SizedBox(height: 16.h),
                CustomText(
                  text: 'Failed to load details',
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                ),
                SizedBox(height: 8.h),
                CustomText(
                  text: _errorMessage.isEmpty ? 'Product details not available' : _errorMessage,
                  fontSize: 13.sp,
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 20.h),
                ElevatedButton.icon(
                  onPressed: () {
                    final productId = ModalRoute.of(context)!.settings.arguments as int;
                    _loadProductDetails(productId);
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final product = _product!;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          // Elegant transparent App Bar with Hero Image
          SliverAppBar(
            expandedHeight: 350.h,
            pinned: true,
            stretch: true,
            leading: Padding(
              padding: EdgeInsets.all(8.r),
              child: CircleAvatar(
                backgroundColor: isDark
                    ? AppColors.darkCard.withValues(alpha: 0.75)
                    : AppColors.lightCard.withValues(alpha: 0.8),
                child: IconButton(
                  icon: Icon(Icons.arrow_back,
                      color: isDark ? AppColors.sand : AppColors.tealDeep, size: 20.sp),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
            actions: [
              Padding(
                padding: EdgeInsets.all(8.r),
                child: CircleAvatar(
                  backgroundColor: isDark
                      ? AppColors.darkCard.withValues(alpha: 0.75)
                      : AppColors.lightCard.withValues(alpha: 0.8),
                  child: IconButton(
                    icon: Icon(
                      _isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: _isFavorite
                          ? AppColors.ember
                          : (isDark ? AppColors.sand : AppColors.tealDeep),
                      size: 20.sp,
                    ),
                    onPressed: () {
                      setState(() {
                        _isFavorite = !_isFavorite;
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: CustomText(
                            text: _isFavorite ? 'Added to Wishlist' : 'Removed from Wishlist',
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w500,
                          ),
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                children: [
                  Positioned.fill(
                    child: Container(
                      color: theme.cardTheme.color,
                      child: product.images.isEmpty
                          ? Center(
                              child: Icon(Icons.image,
                                  size: 80.sp,
                                  color: isDark
                                      ? AppColors.darkMuted
                                      : AppColors.lightMuted))
                          : Image.network(
                              product.images.first,
                              fit: BoxFit.contain,
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Center(
                                  child: CircularProgressIndicator(
                                    value: loadingProgress.expectedTotalBytes != null
                                        ? loadingProgress.cumulativeBytesLoaded /
                                            loadingProgress.expectedTotalBytes!
                                        : null,
                                  ),
                                );
                              },
                              errorBuilder: (context, error, stackTrace) => Center(
                                  child: Icon(Icons.broken_image,
                                      size: 80.sp,
                                      color: isDark
                                          ? AppColors.darkMuted
                                          : AppColors.lightMuted)),
                            ),
                    ),
                  ),
                  // Gradient Overlay for readability
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.tealDeep.withValues(alpha: 0.35),
                            Colors.transparent,
                            AppColors.tealDeep.withValues(alpha: 0.08),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Product Details Body
          SliverList(
            delegate: SliverChildListDelegate([
              Padding(
                padding: EdgeInsets.all(16.r),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Brand & Category Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(6.r),
                          ),
                          child: CustomText(
                            text: product.category.toUpperCase(),
                            fontSize: 11.sp,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                        ),
                        if (product.brand.isNotEmpty)
                          CustomText(
                            text: product.brand,
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                    SizedBox(height: 12.h),

                    // Title
                    CustomText(
                      text: product.title,
                      fontSize: 22.sp,
                      fontWeight: FontWeight.bold,
                    ),
                    SizedBox(height: 8.h),

                    // Price Section
                    CustomText(
                      text: '\$${product.price.toStringAsFixed(2)}',
                      fontSize: 24.sp,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                    SizedBox(height: 12.h),

                    // Stock status
                    Row(
                      children: [
                        Icon(
                          product.stock > 0 ? Icons.check_circle_outline : Icons.remove_circle_outline,
                          color: product.stock > 10
                              ? theme.colorScheme.primary
                              : (product.stock > 0
                                  ? AppColors.ember
                                  : theme.colorScheme.error),
                          size: 18.sp,
                        ),
                        SizedBox(width: 4.w),
                        CustomText(
                          text: product.stock > 10
                              ? 'In Stock (${product.stock})'
                              : (product.stock > 0 ? 'Low Stock (${product.stock} left)' : 'Out of Stock'),
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ],
                    ),
                    Divider(height: 32.h, thickness: 1),

                    // Description Section
                    CustomText(
                      text: 'Description',
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                    ),
                    SizedBox(height: 8.h),
                    CustomText(
                      text: product.description,
                      fontSize: 14.sp,
                      letterSpacing: 0.2,
                    ),
                    SizedBox(height: 16.h),

                    // Specifications Card
                    _buildSectionCard(
                      title: 'Specifications',
                      children: [
                        _buildSpecRow('SKU', product.sku),
                        _buildSpecRow('Weight', '${product.weight} kg'),
                        _buildSpecRow('Dimensions',
                            '${product.dimensions.width}W x ${product.dimensions.height}H x ${product.dimensions.depth}D cm'),
                        _buildSpecRow('Warranty', product.warrantyInformation),
                      ],
                      theme: theme,
                    ),
                    SizedBox(height: 16.h),

                    // Delivery & Return Card
                    _buildSectionCard(
                      title: 'Delivery & Return',
                      children: [
                        _buildSpecRow('Shipping info', product.shippingInformation),
                        _buildSpecRow('Return policy', product.returnPolicy),
                        _buildSpecRow('Min. Order Qty', '${product.minimumOrderQuantity} units'),
                      ],
                      theme: theme,
                    ),
                    SizedBox(height: 24.h),

                    // Reviews Section
                    CustomText(
                      text: 'Customer Reviews (${product.reviews.length})',
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                    ),

                    if (product.reviews.isEmpty)
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 8.h),
                        child: CustomText(
                          text: 'No reviews yet.',
                          fontSize: 13.sp,
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        // Without this, ListView inherits MediaQuery's top/bottom
                        // insets (status bar height) as padding.
                        padding: EdgeInsets.only(top: 8.h),
                        itemCount: product.reviews.length,
                        separatorBuilder: (context, index) => SizedBox(height: 12.h),
                        itemBuilder: (context, index) {
                          final review = product.reviews[index];
                          return Card(
                            elevation: 0,
                            color: theme.cardTheme.color,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10.r),
                              side: BorderSide(
                                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                              ),
                            ),
                            child: Padding(
                              padding: EdgeInsets.all(12.r),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: CustomText(
                                          text: review.reviewerName,
                                          fontSize: 14.sp,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Row(
                                        children: List.generate(
                                          5,
                                          (starIdx) => Icon(
                                            Icons.star_rounded,
                                            size: 14.sp,
                                            color: starIdx < review.rating
                                                ? AppColors.ember
                                                : (isDark
                                                    ? AppColors.darkMuted
                                                    : AppColors.lightMuted),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 4.h),
                                  CustomText(
                                    text: review.reviewerEmail,
                                    fontSize: 11.sp,
                                  ),
                                  SizedBox(height: 8.h),
                                  CustomText(
                                    text: review.comment,
                                    fontSize: 13.sp,
                                  ),
                                  SizedBox(height: 4.h),
                                  Align(
                                    alignment: Alignment.bottomRight,
                                    child: CustomText(
                                      text: _formatDate(review.date),
                                      fontSize: 10.sp,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    SizedBox(height: 24.h),
                  ],
                ),
              ),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required List<Widget> children,
    required ThemeData theme,
  }) {
    final isDark = theme.brightness == Brightness.dark;
    return Card(
      elevation: 0,
      color: theme.cardTheme.color,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
        side: BorderSide(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(16.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomText(
              text: title,
              fontSize: 15.sp,
              fontWeight: FontWeight.bold,
            ),
            SizedBox(height: 12.h),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildSpecRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110.w,
            child: CustomText(
              text: label,
              fontSize: 13.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
          Expanded(
            child: CustomText(
              text: value,
              fontSize: 13.sp,
            ),
          ),
        ],
      ),
    );
  }


  String _formatDate(String dateStr) {
    try {
      final dateTime = DateTime.parse(dateStr);
      return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}';
    } catch (_) {
      return dateStr;
    }
  }

  // skeleton loading
  Widget _buildSkeletonDetail(ThemeData theme, bool isDark) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Placeholder for the product hero image
          Container(
            height: 350.h,
            width: double.infinity,
            color: theme.cardTheme.color,
            child: Center(
              child: Icon(
                Icons.image,
                size: 80.sp,
                color: isDark ? AppColors.darkSkeleton : AppColors.lightSkeleton,
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(16.r),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Placeholder for category / brand tag
                Container(
                  width: 100.w,
                  height: 20.h,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSkeleton : AppColors.lightSkeleton,
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                ),
                SizedBox(height: 12.h),
                // Placeholder for product title
                Container(
                  width: 250.w,
                  height: 24.h,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSkeleton : AppColors.lightSkeleton,
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                ),
                SizedBox(height: 8.h),
                // Placeholder for product price
                Container(
                  width: 80.w,
                  height: 24.h,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSkeleton : AppColors.lightSkeleton,
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                ),
                SizedBox(height: 12.h),
                // Placeholder for stock status indicator
                Row(
                  children: [
                    Container(
                      width: 18.w,
                      height: 18.h,
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkSkeleton : AppColors.lightSkeleton,
                        shape: BoxShape.circle,
                      ),
                    ),
                    SizedBox(width: 4.w),
                    Container(
                      width: 120.w,
                      height: 14.h,
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkSkeleton : AppColors.lightSkeleton,
                        borderRadius: BorderRadius.circular(4.r),
                      ),
                    ),
                  ],
                ),
                Divider(
                  height: 32.h,
                  thickness: 1,
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
                // Placeholder for description header
                Container(
                  width: 100.w,
                  height: 16.h,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSkeleton : AppColors.lightSkeleton,
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                ),
                SizedBox(height: 8.h),
                // Placeholder for description text lines
                Column(
                  children: List.generate(
                    3,
                    (index) => Padding(
                      padding: EdgeInsets.symmetric(vertical: 4.h),
                      child: Container(
                        width: double.infinity,
                        height: 14.h,
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkSkeleton : AppColors.lightSkeleton,
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 24.h),
                // Placeholder for specification details card
                Container(
                  width: double.infinity,
                  height: 120.h,
                  decoration: BoxDecoration(
                    color: theme.cardTheme.color,
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    ),
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
