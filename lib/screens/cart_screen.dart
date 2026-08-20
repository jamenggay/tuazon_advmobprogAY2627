import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../constants.dart';
import '../models/cart.dart';
import '../services/cart_service.dart';
import '../services/user_service.dart';
import '../widgets/custom_text.dart';

// shows the cart of the user 
class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  // talks to the API
  final CartService _cartService = CartService();
  // ENHANCEMENT 3
  // used user service to load the specific user's own cart
  final UserService _userService = UserService();

  // stores the cart items from the API.
  Cart? _cart;
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    // Gets the cart when the screen opens
    _loadUserCart();
  }

  // renderd the cart that belongs to the current user 
  Future<void> _loadUserCart() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Read the saved user first, then use their id to get their cart.
      final user = await _userService.getUser();
      final carts = await _cartService.getCartsByUserId(user.id);
      if (!mounted) return;
      setState(() {
        _cart = carts.isNotEmpty ? carts.first : null;
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

  // Adds up the quantity of every item 
  int get _totalQuantity {
    var count = 0;
    for (final item in _cart!.products) {
      count += item.quantity;
    }
    return count;
  }

  // Adds up the price before discount of every item
  double get _subtotal {
    var sum = 0.0;
    for (final item in _cart!.products) {
      sum += item.total;
    }
    return sum;
  }

  // Adds up the price after discount of every item
  double get _discountedSubtotal {
    var sum = 0.0;
    for (final item in _cart!.products) {
      sum += item.discountedTotal;
    }
    return sum;
  }

  // Runs when the plus or minus button is pressed for quantity increase or decrease
  void _changeQuantity(CartProduct item, int change) {
    final newQuantity = item.quantity + change;
    if (newQuantity < 1) return;
    setState(() {
      item.updateQuantity(newQuantity);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: _buildMainContent(theme, isDark),
      ),
    );
  }

  Widget _buildMainContent(ThemeData theme, bool isDark) {
    if (_isLoading) {
      return _buildSkeletonList(isDark);
    }

    // shows the error and a Try Again button if API call failed
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
                onPressed: _loadUserCart,
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

    final cart = _cart;

    // if user has no cart or the cart has no items
    if (cart == null || cart.products.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.remove_shopping_cart_outlined,
              size: 64.sp,
              color: isDark ? AppColors.darkMuted : AppColors.lightMuted,
            ),
            SizedBox(height: 16.h),
            CustomText(
              text: 'Your cart is empty',
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // number of cart items
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              CustomText(
                text: '$_totalQuantity items',
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.darkMuted : AppColors.lightMuted,
              ),
            ],
          ),
        ),
        // list of products inside the cart.
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadUserCart,
            child: ListView.separated(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
              itemCount: cart.products.length,
              separatorBuilder: (context, index) => SizedBox(height: 12.h),
              itemBuilder: (context, index) {
                //one card for each product in the cart
                final item = cart.products[index];
                return _buildCartItemCard(context, item, theme, isDark);
              },
            ),
          ),
        ),
        // total
        _buildSummary(cart, theme, isDark),
      ],
    );
  }

  // opens the product detail screen from the cart item card.
  Widget _buildCartItemCard(
    BuildContext context,
    CartProduct item,
    ThemeData theme,
    bool isDark,
  ) {
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
            arguments: item.id,
          );
        },
        child: Padding(
          padding: EdgeInsets.all(10.r),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product thumbnail
              Container(
                width: 80.w,
                height: 80.h,
                padding: EdgeInsets.all(4.r),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkBackground
                      : AppColors.lightBackground,
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Image.network(
                  item.thumbnail,
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
                      color:
                          isDark ? AppColors.darkMuted : AppColors.lightMuted,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              // Item info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomText(
                      text: item.title,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 6.h),
                    Row(
                      children: [
                        CustomText(
                          text: '\$${item.price.toStringAsFixed(2)}',
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w500,
                        ),
                        SizedBox(width: 6.w),
                        Icon(
                          Icons.local_offer_outlined,
                          size: 13.sp,
                          color: AppColors.ember,
                        ),
                        SizedBox(width: 4.w),
                        CustomText(
                          text:
                              '${item.discountPercentage.toStringAsFixed(0)}% off',
                          fontSize: 11.sp,
                          color: isDark ? AppColors.sand : AppColors.emberDeep,
                        ),
                      ],
                    ),
                    SizedBox(height: 6.h),
                    // The minus button
                    Row(
                      children: [
                        _buildQuantityButton(
                          icon: Icons.remove,
                          theme: theme,
                          isDark: isDark,
                          onPressed: item.quantity > 1
                              ? () => _changeQuantity(item, -1)
                              : null,
                        ),
                        // Shows the current quantity of this product
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12.w),
                          child: CustomText(
                            text: '${item.quantity}',
                            fontSize: 14.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        // Plus button
                        _buildQuantityButton(
                          icon: Icons.add,
                          theme: theme,
                          isDark: isDark,
                          onPressed: () => _changeQuantity(item, 1),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  CustomText(
                    text: '\$${item.discountedTotal.toStringAsFixed(2)}',
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                  SizedBox(height: 2.h),
                  CustomText(
                    text: '\$${item.total.toStringAsFixed(2)}',
                    fontSize: 11.sp,
                    color: isDark ? AppColors.darkMuted : AppColors.lightMuted,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildQuantityButton({
    required IconData icon,
    required ThemeData theme,
    required bool isDark,
    required VoidCallback? onPressed,
  }) {
    final isDisabled = onPressed == null;

    return InkWell(
     // opens the product detail screen.
      onTap: onPressed ?? () {},
      borderRadius: BorderRadius.circular(8.r),
      child: Container(
        width: 28.w,
        height: 28.h,
        decoration: BoxDecoration(
          color: isDisabled
              ? (isDark ? AppColors.darkSkeleton : AppColors.lightSkeleton)
              : theme.colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
        child: Icon(
          icon,
          size: 16.sp,
          color: isDisabled
              ? (isDark ? AppColors.darkMuted : AppColors.lightMuted)
              : theme.colorScheme.onPrimaryContainer,
        ),
      ),
    );
  }

  //total section at the bottom of the cart screen
  Widget _buildSummary(Cart cart, ThemeData theme, bool isDark) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
      ),
      child: Column(
        children: [
          // How many different products are in the cart
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CustomText(
                text: 'Total products',
                fontSize: 13.sp,
              ),
              CustomText(
                text: '${cart.totalProducts}',
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
              ),
            ],
          ),
          SizedBox(height: 4.h),
          // Total price before the discount
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CustomText(
                text: 'Subtotal',
                fontSize: 13.sp,
              ),
              CustomText(
                text: '\$${_subtotal.toStringAsFixed(2)}',
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
              ),
            ],
          ),
          SizedBox(height: 4.h),
          // Final total price after the discount
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CustomText(
                text: 'Discounted total',
                fontSize: 15.sp,
                fontWeight: FontWeight.bold,
              ),
              CustomText(
                text: '\$${_discountedSubtotal.toStringAsFixed(2)}',
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // skeleton loading (tama ba tong term na to hahaha?)
  Widget _buildSkeletonList(bool isDark) {
    return ListView.separated(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
      itemCount: 5,
      separatorBuilder: (context, index) => SizedBox(height: 12.h),
      itemBuilder: (context, index) {
        return Container(
          padding: EdgeInsets.all(10.r),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : AppColors.lightCard,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // container for the item thumbnail
              Container(
                width: 80.w,
                height: 80.h,
                decoration: BoxDecoration(
                  color:
                      isDark ? AppColors.darkSkeleton : AppColors.lightSkeleton,
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // container for the item title
                    Container(
                      width: 140.w,
                      height: 12.h,
                      color:
                          isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    ),
                    SizedBox(height: 8.h),
                    // container for the price row
                    Container(
                      width: 90.w,
                      height: 12.h,
                      color:
                          isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    ),
                    SizedBox(height: 8.h),
                    // container for the discount row
                    Container(
                      width: 60.w,
                      height: 12.h,
                      color:
                          isDark ? AppColors.darkBorder : AppColors.lightBorder,
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
