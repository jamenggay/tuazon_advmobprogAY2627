import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../constants.dart';
import '../models/product.dart';
import '../services/product_service.dart';
import '../widgets/custom_text.dart';

class ProductScreen extends StatefulWidget {
  const ProductScreen({super.key});

  @override
  State<ProductScreen> createState() => _ProductScreenState();
}

class _ProductScreenState extends State<ProductScreen> {
  final ProductService _productService = ProductService();

  List<Product> _allProducts = [];
  bool _isLoading = true;
  String _errorMessage = '';
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final products = await _productService.getAllProducts();
      if (!mounted) return;
      setState(() {
        _allProducts = products;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  List<Product> get _filteredProducts {
    if (_searchQuery.isEmpty) {
      return _allProducts;
    }
    return _allProducts
        .where((p) =>
            p.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            p.description.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            p.brand.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Search Bar
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              child: Container(
                height: 48.h,
                decoration: BoxDecoration(
                  color: theme.cardTheme.color,
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  ),
                ),
                child: TextField(
                  onChanged: (val) {
                    setState(() {
                      _searchQuery = val;
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Search products...',
                    hintStyle: TextStyle(
                      fontSize: 14.sp,
                      color: isDark ? AppColors.darkMuted : AppColors.lightMuted,
                      fontFamily: 'Poppins',
                    ),
                    prefixIcon: Icon(
                      Icons.search,
                      color: isDark ? AppColors.darkMuted : AppColors.lightMuted,
                      size: 20.sp,
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 12.h),
                  ),
                ),
              ),
            ),
            Expanded(
              child: _buildMainContent(theme, isDark),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent(ThemeData theme, bool isDark) {
    if (_isLoading) {
      return _buildSkeletonGrid(isDark);
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(24.r),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.wifi_off_rounded,
                size: 64.sp,
                color: isDark ? AppColors.darkMuted : AppColors.lightMuted,
              ),
              SizedBox(height: 16.h),
              CustomText(
                text: 'Oops! Something went wrong',
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
              ),
              SizedBox(height: 8.h),
              CustomText(
                text: _errorMessage,
                fontSize: 13.sp,
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20.h),
              ElevatedButton.icon(
                onPressed: _loadProducts,
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final filtered = _filteredProducts;

    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 64.sp,
              color: isDark ? AppColors.darkMuted : AppColors.lightMuted,
            ),
            SizedBox(height: 16.h),
            CustomText(
              text: 'No products found',
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadProducts,
      child: GridView.builder(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.65,
          crossAxisSpacing: 12.w,
          mainAxisSpacing: 12.h,
        ),
        itemCount: filtered.length,
        itemBuilder: (context, index) {
          final product = filtered[index];
          return _buildProductCard(context, product, theme, isDark);
        },
      ),
    );
  }

  Widget _buildProductCard(BuildContext context, Product product, ThemeData theme, bool isDark) {
    return Card(
      elevation: 0,
      color: theme.cardTheme.color,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.r),
        side: BorderSide(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(
            context,
            '/product-detail',
            arguments: product.id,
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Container
            Expanded(
              child: Container(
                width: double.infinity,
                color: isDark
                    ? AppColors.darkBackground
                    : AppColors.lightBackground,
                padding: EdgeInsets.all(8.r),
                // Image.network for caching
                child: Image.network(
                  product.thumbnail,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                            : null,
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) => Center(
                    child: Icon(
                      Icons.broken_image,
                      color: isDark
                          ? AppColors.darkMuted
                          : AppColors.lightMuted,
                    ),
                  ),
                ),
              ),
            ),

            // Text Info
            Padding(
              padding: EdgeInsets.all(10.r),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tag showing the brand name or product category
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                    child: CustomText(
                      text: product.brand.isNotEmpty ? product.brand : product.category.toUpperCase(),
                      fontSize: 9.sp,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  // Title
                  SizedBox(
                    height: 36.h,
                    child: CustomText(
                      text: product.title,
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  // Show the star icon, average rating, and count of reviews
                  Row(
                    children: [
                      Icon(
                        Icons.star_rounded,
                        color: AppColors.ember,
                        size: 14.sp,
                      ),
                      SizedBox(width: 2.w),
                      CustomText(
                        text: product.averageReviewRating.toStringAsFixed(1),
                        fontSize: 11.sp,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppColors.sand : AppColors.emberDeep,
                      ),
                      SizedBox(width: 4.w),
                      CustomText(
                        text: '(${product.reviews.length})',
                        fontSize: 11.sp,
                        color: isDark ? AppColors.darkMuted : AppColors.lightMuted,
                      ),
                    ],
                  ),
                  SizedBox(height: 6.h),
                  // Price row
                  CustomText(
                    text: '\$${product.price.toStringAsFixed(2)}',
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Builds a skeleton loading screen
  Widget _buildSkeletonGrid(bool isDark) {
    return GridView.builder(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.65,
        crossAxisSpacing: 12.w,
        mainAxisSpacing: 12.h,
      ),
      itemCount: 6,
      itemBuilder: (context, index) {
        return Container(
          // Placeholder outer card shell
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : AppColors.lightCard,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Placeholder for the product image
              Expanded(
                child: Container(
                  margin: EdgeInsets.all(12.r),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSkeleton : AppColors.lightSkeleton,
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(12.r),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Placeholder for brand / category tag
                    Container(
                      width: 50.w,
                      height: 10.h,
                      color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    ),
                    SizedBox(height: 8.h),
                    // Placeholder for product title (first line)
                    Container(
                      width: 120.w,
                      height: 12.h,
                      color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    ),
                    SizedBox(height: 4.h),
                    // Placeholder for product title (second line)
                    Container(
                      width: 80.w,
                      height: 12.h,
                      color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    ),
                    SizedBox(height: 12.h),
                    // Placeholder for product price
                    Container(
                      width: 60.w,
                      height: 14.h,
                      color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}