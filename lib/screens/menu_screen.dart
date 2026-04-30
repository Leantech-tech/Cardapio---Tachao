import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/category.dart';
import '../models/product.dart';
import '../providers/cart_provider.dart';
import '../providers/menu_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../utils/store_status_helper.dart';
import '../widgets/hero_carousel.dart';
import '../widgets/product_card.dart';
import '../widgets/login_sheet.dart';
import '../widgets/table_link_sheet.dart';
import '../widgets/product_card_grid.dart';
import 'cart_screen.dart';
import 'product_detail_screen.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  String selectedCategoryId = '';
  final ScrollController _productsScrollController = ScrollController();

  List<Product> getFilteredProducts(List<Product> allProducts) {
    return allProducts
        .where((p) => p.categoryId == selectedCategoryId)
        .toList();
  }

  String getSectionTitle(List<Category> categories) {
    if (categories.isEmpty) return '';
    return categories
        .firstWhere(
          (c) => c.id == selectedCategoryId,
          orElse: () => categories.first,
        )
        .name;
  }

  @override
  void dispose() {
    _productsScrollController.dispose();
    super.dispose();
  }

  void _openProductDetail(Product product) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProductDetailScreen(product: product),
      ),
    );
  }

  void _goToCart() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CartScreen()),
    );
  }

  void _openLoginSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const LoginSheet(),
    );
  }

  void _showLogoutMenu(BuildContext context, AuthProvider authProvider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (authProvider.deviceTableNumber.isNotEmpty)
                ListTile(
                  leading: const Icon(Icons.table_restaurant_outlined, color: AppTheme.tachaoRed),
                  title: Text(
                    'Mesa ${authProvider.deviceTableNumber}',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                  },
                ),
              if (authProvider.isLoggedIn && authProvider.deviceTableNumber.isEmpty)
                ListTile(
                  leading: const Icon(Icons.table_restaurant_outlined, color: AppTheme.tachaoRed),
                  title: Text(
                    'Vincular Mesa',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.pop(context);
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: AppTheme.surface(context),
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                      ),
                      builder: (_) => const TableLinkSheet(),
                    );
                  },
                ),
              if (authProvider.isLoggedIn && authProvider.deviceTableNumber.isNotEmpty)
                ListTile(
                  leading: const Icon(Icons.link_off, color: Colors.orange),
                  title: Text(
                    'Desvincular Mesa do Tablet',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: Colors.orange),
                  ),
                  onTap: () async {
                    Navigator.pop(context);
                    await authProvider.unlinkDeviceTable();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Mesa desvinculada do tablet.', style: GoogleFonts.inter(fontSize: 14)),
                          backgroundColor: Colors.orange,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      );
                    }
                  },
                ),
              const Divider(),
              if (!authProvider.isLoggedIn)
                ListTile(
                  leading: const Icon(Icons.login, color: AppTheme.tachaoRed),
                  title: Text(
                    'Login do Garçom',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _openLoginSheet();
                  },
                ),
              if (authProvider.isLoggedIn)
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.red),
                  title: Text(
                    'Sair',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      color: Colors.red,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    authProvider.logout();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Você saiu.', style: GoogleFonts.inter(fontSize: 14)),
                        backgroundColor: AppTheme.tachaoRed,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoBar(BuildContext context, bool isTablet) {
    final storeStatus = StoreStatusHelper.checkStatus(DateTime.now());

    return Container(
      padding: EdgeInsets.all(isTablet ? 16 : 14),
      decoration: BoxDecoration(
        color: AppTheme.inputBg(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border(context)),
      ),
      child: Column(
        children: [
          // Store status banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
            decoration: BoxDecoration(
              color: storeStatus.isOpen
                  ? (storeStatus.isClosingSoon
                      ? const Color(0xFFFFF3E0)
                      : const Color(0xFFE8F5E9))
                  : const Color(0xFFFFEBEE),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: storeStatus.isOpen
                    ? (storeStatus.isClosingSoon
                        ? const Color(0xFFFFB300)
                        : const Color(0xFF4CAF50))
                    : const Color(0xFFE31E24),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: storeStatus.isOpen
                        ? (storeStatus.isClosingSoon
                            ? const Color(0xFFFFB300)
                            : const Color(0xFF4CAF50))
                        : const Color(0xFFE31E24),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${storeStatus.statusText} • ${storeStatus.nextChangeText}',
                    style: GoogleFonts.inter(
                      fontSize: isTablet ? 13 : 12,
                      fontWeight: FontWeight.w600,
                      color: storeStatus.isOpen
                          ? (storeStatus.isClosingSoon
                              ? const Color(0xFFE65100)
                              : const Color(0xFF2E7D32))
                          : const Color(0xFFB71C1C),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Consumer<AuthProvider>(
            builder: (context, authProvider, child) {
              if (!authProvider.isLoggedIn) {
                return const SizedBox.shrink();
              }
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                decoration: BoxDecoration(
                  color: AppTheme.tachaoRed.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppTheme.tachaoRed.withValues(alpha: 0.25),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.person_outline,
                      size: isTablet ? 16 : 14,
                      color: AppTheme.tachaoRed,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        authProvider.userName,
                        style: GoogleFonts.inter(
                          fontSize: isTablet ? 13 : 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.tachaoRed,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          const Divider(height: 16, color: AppTheme.borderGrey),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.access_time,
                size: isTablet ? 18 : 16,
                color: AppTheme.tachaoRed,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Horário de funcionamento',
                      style: GoogleFonts.inter(
                        fontSize: isTablet ? 12 : 11,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary(context),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Domingo à Quinta - 13h00 às 21h00  |  Sexta à Sábado - 13h05 às 22h00',
                      style: GoogleFonts.inter(
                        fontSize: isTablet ? 12 : 11,
                        color: AppTheme.textSecondary(context),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySidebar(BuildContext context, bool isTablet, List<Category> categories) {
    final sidebarWidth = isTablet ? 110.0 : 78.0;

    return Container(
      width: sidebarWidth,
      decoration: BoxDecoration(
        color: AppTheme.inputBg(context),
        border: Border(
          right: BorderSide(color: AppTheme.border(context)),
        ),
      ),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = category.id == selectedCategoryId;
          return GestureDetector(
            onTap: () {
              setState(() {
                selectedCategoryId = category.id;
              });
              if (_productsScrollController.hasClients) {
                _productsScrollController.jumpTo(0);
              }
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.tachaoRed : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    category.icon,
                    size: isTablet ? 26 : 20,
                    color: isSelected ? Colors.white : AppTheme.textSecondary(context),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    category.name,
                    style: GoogleFonts.inter(
                      fontSize: isTablet ? 12 : 9,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: isSelected ? Colors.white : AppTheme.textPrimary(context),
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cartItemCount = context.watch<CartProvider>().totalItems;
    final menuProvider = context.watch<MenuProvider>();

    if (menuProvider.isLoading) {
      return Scaffold(
        backgroundColor: AppTheme.background(context),
        body: const Center(
          child: CircularProgressIndicator(color: AppTheme.tachaoRed),
        ),
      );
    }

    if (menuProvider.error != null) {
      return Scaffold(
        backgroundColor: AppTheme.background(context),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.wifi_off, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                menuProvider.error!,
                style: GoogleFonts.inter(fontSize: 14, color: AppTheme.textSecondary(context)),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: menuProvider.refresh,
                icon: const Icon(Icons.refresh),
                label: const Text('Tentar novamente'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.tachaoRed,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final categories = menuProvider.categories;
    final allProducts = menuProvider.products;

    // Inicializa a categoria selecionada com a primeira disponível
    if (selectedCategoryId.isEmpty && categories.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            selectedCategoryId = categories.first.id;
          });
        }
      });
    }

    final filteredProducts = getFilteredProducts(allProducts);
    final sectionTitle = getSectionTitle(categories);

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final isTablet = width >= 700;
        final isDesktop = width >= 1100;
        final crossAxisCount = isDesktop ? 3 : (isTablet ? 2 : 1);
        final isGrid = crossAxisCount > 1;

        final horizontalPadding = isDesktop
            ? width * 0.08
            : (isTablet ? 32.0 : 16.0);

        final screenHeight = MediaQuery.of(context).size.height;
        final productsAreaHeight = screenHeight * 0.88;

        return Scaffold(
          backgroundColor: AppTheme.background(context),
          body: SafeArea(
            child: RefreshIndicator(
              onRefresh: () async => menuProvider.refresh(),
              color: AppTheme.tachaoRed,
              backgroundColor: AppTheme.surface(context),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header with Logo
                    FadeInDown(
                      duration: const Duration(milliseconds: 500),
                      child: Container(
                        padding: EdgeInsets.fromLTRB(
                          horizontalPadding,
                          16,
                          horizontalPadding,
                          20,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.asset(
                                    'assets/images/logo.png',
                                    height: isTablet ? 72 : 56,
                                    width: isTablet ? 72 : 56,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) =>
                                        Container(
                                      height: isTablet ? 72 : 56,
                                      width: isTablet ? 72 : 56,
                                      decoration: BoxDecoration(
                                        color: AppTheme.inputBg(context),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(
                                        Icons.restaurant,
                                        color: AppTheme.textSecondary(context),
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(width: isTablet ? 18 : 14),
                                Expanded(
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Tachão de Ubatuba',
                                              style: GoogleFonts.poppins(
                                                fontSize: isTablet ? 24 : 20,
                                                fontWeight: FontWeight.w700,
                                                color: AppTheme.textPrimary(context),
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              'Sabores de Ubatuba desde 1977',
                                              style: GoogleFonts.inter(
                                                fontSize: isTablet ? 14 : 13,
                                                color: AppTheme.textSecondary(context),
                                              ),
                                            ),
                                            Consumer<AuthProvider>(
                                              builder: (context, authProvider, child) {
                                                if (authProvider.deviceTableNumber.isEmpty) {
                                                  return const SizedBox.shrink();
                                                }
                                                return Padding(
                                                  padding: const EdgeInsets.only(top: 6),
                                                  child: Row(
                                                    children: [
                                                      Icon(
                                                        Icons.table_restaurant_outlined,
                                                        size: isTablet ? 14 : 12,
                                                        color: AppTheme.textSecondary(context),
                                                      ),
                                                      const SizedBox(width: 4),
                                                      Text(
                                                        'Mesa ${authProvider.deviceTableNumber}',
                                                        style: GoogleFonts.inter(
                                                          fontSize: isTablet ? 13 : 12,
                                                          fontWeight: FontWeight.w500,
                                                          color: AppTheme.textSecondary(context),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                );
                                              },
                                            ),
                                          ],
                                        ),
                                      ),
                                      Consumer<AuthProvider>(
                                        builder: (context, authProvider, child) {
                                          return IconButton(
                                            onPressed: () {
                                              _showLogoutMenu(context, authProvider);
                                            },
                                            icon: Icon(
                                              Icons.settings_outlined,
                                              color: AppTheme.textSecondary(context),
                                            ),
                                            tooltip: 'Configurações',
                                          );
                                        },
                                      ),
                                      IconButton(
                                        onPressed: () => context.read<ThemeProvider>().toggleTheme(),
                                        icon: Icon(
                                          AppTheme.isDark(context)
                                              ? Icons.wb_sunny_outlined
                                              : Icons.dark_mode_outlined,
                                          color: AppTheme.textSecondary(context),
                                        ),
                                        tooltip: 'Alternar tema',
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: isTablet ? 20 : 16),
                            _buildInfoBar(context, isTablet),
                          ],
                        ),
                      ),
                    ),
                    // Hero Carousel
                    FadeIn(
                      duration: const Duration(milliseconds: 600),
                      child: Padding(
                        padding: EdgeInsets.only(
                          top: isTablet ? 8 : 4,
                          bottom: isTablet ? 16 : 12,
                        ),
                        child: HeroCarousel(products: allProducts),
                      ),
                    ),
                    // Search removed
                    // Main content: Sidebar categories + Products (each with independent scroll)
                    if (categories.isEmpty)
                      const SizedBox.shrink()
                    else
                      SizedBox(
                        height: productsAreaHeight,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Category Sidebar - independent scroll
                            _buildCategorySidebar(context, isTablet, categories),
                            // Products area - independent scroll
                            Expanded(
                              child: Padding(
                                padding: EdgeInsets.only(right: horizontalPadding),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Section Title + Product Count
                                    Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                        12,
                                        12,
                                        0,
                                        8,
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            sectionTitle,
                                            style: GoogleFonts.poppins(
                                              fontSize: isTablet ? 20 : 18,
                                              fontWeight: FontWeight.w700,
                                              color: AppTheme.textPrimary(context),
                                            ),
                                          ),
                                          Text(
                                            '${filteredProducts.length} item${filteredProducts.length != 1 ? 's' : ''}',
                                            style: GoogleFonts.inter(
                                              fontSize: 13,
                                              color: AppTheme.textSecondary(context),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Products list with independent scroll
                                    Expanded(
                                      child: filteredProducts.isEmpty
                                          ? Center(
                                              child: Column(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  Icon(
                                                    Icons.restaurant_menu,
                                                    size: 64,
                                                    color: Colors.grey[300],
                                                  ),
                                                  const SizedBox(height: 16),
                                                  Text(
                                                    'Nenhum produto nesta categoria ainda.',
                                                    style: GoogleFonts.inter(
                                                      fontSize: 14,
                                                      color: AppTheme.textSecondary(context),
                                                    ),
                                                    textAlign: TextAlign.center,
                                                  ),
                                                ],
                                              ),
                                            )
                                          : isGrid
                                              ? GridView.builder(
                                                  controller: _productsScrollController,
                                                  padding: const EdgeInsets.fromLTRB(
                                                    12,
                                                    8,
                                                    0,
                                                    32,
                                                  ),
                                                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                                    crossAxisCount: crossAxisCount,
                                                    childAspectRatio: 0.85,
                                                    crossAxisSpacing: 16,
                                                    mainAxisSpacing: 16,
                                                  ),
                                                  itemCount: filteredProducts.length,
                                                  itemBuilder: (context, index) {
                                                    final product = filteredProducts[index];
                                                    return ProductCardGrid(
                                                      product: product,
                                                      index: index,
                                                      onTap: () => _openProductDetail(product),
                                                    );
                                                  },
                                                )
                                              : ListView.builder(
                                                  controller: _productsScrollController,
                                                  padding: const EdgeInsets.fromLTRB(
                                                    12,
                                                    8,
                                                    0,
                                                    32,
                                                  ),
                                                  itemCount: filteredProducts.length,
                                                  itemBuilder: (context, index) {
                                                    final product = filteredProducts[index];
                                                    return ProductCard(
                                                      product: product,
                                                      index: index,
                                                      onTap: () => _openProductDetail(product),
                                                    );
                                                  },
                                                ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    // Bottom padding to give some breathing room at the end of the scroll
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
          // Floating Cart Button with bounce animation
          floatingActionButton: cartItemCount > 0
              ? TweenAnimationBuilder<double>(
                  key: ValueKey(cartItemCount),
                  tween: Tween(begin: 0.8, end: 1.0),
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.elasticOut,
                  builder: (context, scale, child) {
                    return Transform.scale(
                      scale: scale,
                      child: child,
                    );
                  },
                  child: FloatingActionButton.extended(
                    onPressed: _goToCart,
                    backgroundColor: AppTheme.tachaoRed,
                    icon: const Icon(
                      Icons.shopping_bag_outlined,
                      color: Colors.white,
                    ),
                    label: Text(
                      '$cartItemCount',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                )
              : null,
        );
      },
    );
  }
}
