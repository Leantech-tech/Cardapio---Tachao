import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/cart_provider.dart';
import '../theme/app_theme.dart';
import '../services/comanda_service.dart';
import '../widgets/barcode_scanner_screen.dart';
import '../widgets/comanda_order_sheet.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 2));
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  String _extrairNumeroComanda(String barcode) {
    // Extrai apenas números do código de barras
    final numeros = barcode.replaceAll(RegExp(r'[^0-9]'), '');
    if (numeros.isEmpty) return '';

    // PostgreSQL integer max value = 2.147.483.647
    const int maxInt32 = 2147483647;
    final valor = int.tryParse(numeros) ?? 0;

    if (valor > maxInt32) {
      // Se o código de barras for maior que o limite do integer,
      // usa os últimos 9 dígitos (padrão comum em comandas)
      return numeros.substring(numeros.length - 9);
    }
    return numeros;
  }

  Future<void> _sendOrder(CartProvider cart) async {
    final barcode = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const BarcodeScannerScreen()),
    );

    if (barcode == null || barcode.isEmpty) return;

    final numero = _extrairNumeroComanda(barcode);
    if (numero.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Código de barras inválido. Tente novamente.',
              style: GoogleFonts.inter(fontWeight: FontWeight.w500),
            ),
            backgroundColor: Colors.orange[700],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
      return;
    }

    try {
      final service = ComandaService();
      const empresaId = 7;

      var comanda = await service.buscarComanda(numero, empresaId);
      comanda ??= await service.criarComanda(numero, empresaId);

      final comandaId = comanda['id'] as int;
      final mesaId = comanda['mesa_id'] as int?;

      await service.adicionarItens(comandaId, empresaId, cart.items);
      await service.atualizarTotalComanda(comandaId);
      await service.registrarLog(
        comandaId,
        mesaId,
        empresaId,
        'LANCAMENTO_ITEM',
        {
          'numero_comanda': numero,
          'qtd_itens': cart.items.length,
          'valor_total': cart.totalPrice,
        },
      );
      await service.adicionarFilaImpressao(comandaId, empresaId, cart.items, numero);

      if (!mounted) return;

      // Mostra o pedido vinculado à comanda
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: AppTheme.surface(context),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (_) => ComandaOrderSheet(
          numeroComanda: numero,
          itens: cart.items,
          total: cart.totalPrice,
        ),
      );

      _confettiController.play();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Pedido enviado com sucesso!',
            style: GoogleFonts.inter(fontWeight: FontWeight.w500),
          ),
          backgroundColor: Colors.green[600],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
      cart.clear();
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) {
          Navigator.pop(context);
        }
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Erro ao enviar pedido: $e',
            style: GoogleFonts.inter(fontWeight: FontWeight.w500),
          ),
          backgroundColor: Colors.red[600],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  String _formatPrice(double price) {
    return 'R\$ ${price.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  Widget _buildCartItemImage(BuildContext context, String imagePath) {
    if (imagePath.isEmpty) {
      return Container(
        width: 80,
        height: 80,
        color: AppTheme.inputBg(context),
        child: Icon(
          Icons.image_not_supported,
          color: AppTheme.textSecondary(context),
          size: 28,
        ),
      );
    }

    if (imagePath.startsWith('http')) {
      return CachedNetworkImage(
        imageUrl: imagePath,
        width: 80,
        height: 80,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          width: 80,
          height: 80,
          color: AppTheme.inputBg(context),
          child: const Center(
            child: CircularProgressIndicator(color: AppTheme.tachaoRed, strokeWidth: 2),
          ),
        ),
        errorWidget: (context, url, error) {
          debugPrint('Erro ao carregar imagem do carrinho: $url | $error');
          return Container(
            width: 80,
            height: 80,
            color: AppTheme.inputBg(context),
            child: Icon(
              Icons.image_not_supported,
              color: AppTheme.textSecondary(context),
              size: 28,
            ),
          );
        },
      );
    }

    return Image.asset(
      imagePath,
      width: 80,
      height: 80,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => Container(
        width: 80,
        height: 80,
        color: AppTheme.inputBg(context),
        child: Icon(
          Icons.image_not_supported,
          color: AppTheme.textSecondary(context),
          size: 28,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CartProvider>(
      builder: (context, cart, child) {
        final items = cart.items;
        final isEmpty = items.isEmpty;

        return Scaffold(
          backgroundColor: AppTheme.background(context),
          appBar: AppBar(
            backgroundColor: AppTheme.background(context),
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: AppTheme.textPrimary(context)),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              'Meu Carrinho',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary(context),
              ),
            ),
            centerTitle: true,
            actions: [
              if (!isEmpty)
                TextButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: Text(
                          'Limpar carrinho?',
                          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                        ),
                        content: Text(
                          'Todos os itens serão removidos.',
                          style: GoogleFonts.inter(),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: Text(
                              'Cancelar',
                              style: GoogleFonts.inter(color: AppTheme.textSecondary(context)),
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              cart.clear();
                              Navigator.pop(ctx);
                            },
                            child: Text(
                              'Limpar',
                              style: GoogleFonts.inter(
                                color: AppTheme.tachaoRed,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  child: Text(
                    'Limpar',
                    style: GoogleFonts.inter(
                      color: AppTheme.tachaoRed,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          body: Stack(
            children: [
              isEmpty
                  ? _buildEmptyState(context)
                  : _buildCartList(context, cart),
              // Confetti overlay
              Align(
                alignment: Alignment.topCenter,
                child: ConfettiWidget(
                  confettiController: _confettiController,
                  blastDirectionality: BlastDirectionality.explosive,
                  particleDrag: 0.05,
                  emissionFrequency: 0.05,
                  numberOfParticles: 30,
                  gravity: 0.2,
                  shouldLoop: false,
                  colors: const [
                    AppTheme.tachaoRed,
                    AppTheme.honeyGold,
                    Colors.green,
                    Colors.orange,
                    Colors.blue,
                  ],
                ),
              ),
            ],
          ),
          bottomNavigationBar: isEmpty
              ? null
              : _buildBottomBar(context, cart),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shopping_bag_outlined,
              size: 80,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 20),
            Text(
              'Seu carrinho está vazio',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary(context),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Explore o cardápio e adicione seus produtos favoritos!',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppTheme.textSecondary(context),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.tachaoRed,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Ver Cardápio',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartList(BuildContext context, CartProvider cart) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final isTablet = width >= 700;
        final isDesktop = width >= 1100;
        final crossAxisCount = isDesktop ? 2 : 1;
        final horizontalPadding = isDesktop
            ? width * 0.08
            : (isTablet ? 32.0 : 20.0);

        if (crossAxisCount > 1) {
          return GridView.builder(
            padding: EdgeInsets.fromLTRB(
              horizontalPadding,
              8,
              horizontalPadding,
              20,
            ),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              childAspectRatio: 2.8,
              crossAxisSpacing: 16,
              mainAxisSpacing: 12,
            ),
            itemCount: cart.items.length,
            itemBuilder: (context, index) {
              return _buildCartItemCard(context, cart, cart.items[index]);
            },
          );
        }

        return ListView.builder(
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            8,
            horizontalPadding,
            20,
          ),
          itemCount: cart.items.length,
          itemBuilder: (context, index) {
            return _buildCartItemCard(context, cart, cart.items[index]);
          },
        );
      },
    );
  }

  Widget _buildCartItemCard(
    BuildContext context,
    CartProvider cart,
    dynamic item,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.cardBg(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border(context), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: _buildCartItemImage(context, item.imagePath),
          ),
          const SizedBox(width: 14),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary(context),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (item.selectedOptions.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      item.selectedOptionsDisplay,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppTheme.textSecondary(context),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                if (item.observation != null && item.observation!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'Obs: ${item.observation}',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppTheme.textSecondary(context),
                        fontStyle: FontStyle.italic,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                const SizedBox(height: 10),
                Text(
                  _formatPrice(item.unitPrice),
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppTheme.textSecondary(context),
                  ),
                ),
                if (item.optionsPrice > 0)
                  Text(
                    '(+ ${_formatPrice(item.optionsPrice)} em opções)',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: AppTheme.textSecondary(context),
                    ),
                  ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    // Quantity controls
                    Container(
                      decoration: BoxDecoration(
                        color: AppTheme.inputBg(context),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          _buildIconButton(
                            icon: Icons.remove,
                            onTap: () => cart.updateQuantity(
                              item.id,
                              item.quantity - 1,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Text(
                              '${item.quantity}',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textPrimary(context),
                              ),
                            ),
                          ),
                          _buildIconButton(
                            icon: Icons.add,
                            onTap: () => cart.updateQuantity(
                              item.id,
                              item.quantity + 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    // Total price
                    Text(
                      _formatPrice(item.total),
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.tachaoRed,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Remove button
          IconButton(
            onPressed: () => cart.removeItem(item.id),
            icon: Icon(
              Icons.delete_outline,
              color: AppTheme.textSecondary(context),
              size: 22,
            ),
            splashRadius: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        child: Icon(
          icon,
          color: AppTheme.tachaoRed,
          size: 18,
        ),
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context, CartProvider cart) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      decoration: BoxDecoration(
        color: AppTheme.surface(context),
        border: Border(
          top: BorderSide(color: AppTheme.border(context), width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.shadow(context),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Summary row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${cart.totalItems} item${cart.totalItems != 1 ? 's' : ''}',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppTheme.textSecondary(context),
                  ),
                ),
                Row(
                  children: [
                    Text(
                      'Total: ',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        color: AppTheme.textPrimary(context),
                      ),
                    ),
                    Text(
                      _formatPrice(cart.totalPrice),
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.tachaoRed,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),
            // Checkout button
            ElevatedButton(
              onPressed: () => _sendOrder(cart),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.tachaoRed,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 54),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              child: Text(
                'Enviar Pedido',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
