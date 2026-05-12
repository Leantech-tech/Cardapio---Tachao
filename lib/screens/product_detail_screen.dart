import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/product.dart';
import '../models/product_option.dart';
import '../providers/cart_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/product_badge.dart';
import '../widgets/product_image.dart';
import '../utils/option_group_helper.dart';

class ProductDetailScreen extends StatefulWidget {
  final Product product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen>
    with SingleTickerProviderStateMixin {
  int quantity = 1;
  final TextEditingController _obsController = TextEditingController();
  bool _added = false;
  late Map<String, List<String>> _selectedOptions;
  late Map<String, double> _selectedOptionPrices;

  double get _totalOptionsPrice {
    return _selectedOptionPrices.values.fold(0.0, (sum, p) => sum + p);
  }

  double get total => (widget.product.price + _totalOptionsPrice) * quantity;

  @override
  void initState() {
    super.initState();
    _selectedOptions = {};
    _selectedOptionPrices = {};
    // Seleciona a(s) primeira(s) opção(ões) de cada grupo por padrão
    for (final group in widget.product.optionGroups) {
      if (group.options.isNotEmpty) {
        if (group.isSingleChoice) {
          // Modificador: seleciona apenas a primeira opção
          final first = group.options.first;
          _selectedOptions[group.id] = [first.id];
          _selectedOptionPrices[first.id] = first.priceModifier;
        } else {
          // Adicional: não pré-seleciona nada (ou respeita qtdMin)
          _selectedOptions[group.id] = [];
        }
      }
    }
  }

  @override
  void dispose() {
    _obsController.dispose();
    super.dispose();
  }

  int _effectiveQtdMax(ProductOptionGroup group) {
    return OptionGroupHelper.effectiveQtdMax(
      group,
      _selectedOptions,
      widget.product.optionGroups,
    );
  }

  void _enforceEffectiveMax() {
    for (final group in widget.product.optionGroups) {
      final effectiveMax = _effectiveQtdMax(group);
      final currentList = _selectedOptions[group.id] ?? [];
      if (currentList.length > effectiveMax) {
        final toRemove = currentList.sublist(effectiveMax);
        for (final id in toRemove) {
          _selectedOptionPrices.remove(id);
        }
        _selectedOptions[group.id] = currentList.sublist(0, effectiveMax);
      }
    }
  }

  bool _isEffectivelyMultipleChoice(ProductOptionGroup group) {
    return _effectiveQtdMax(group) > 1 || group.isMultipleChoice;
  }

  void _toggleOption(ProductOptionGroup group, ProductOption option) {
    setState(() {
      final currentList = _selectedOptions[group.id] ?? [];
      final effectiveMax = _effectiveQtdMax(group);
      final isMulti = _isEffectivelyMultipleChoice(group);

      if (!isMulti) {
        // Comportamento single choice
        if (currentList.isNotEmpty) {
          _selectedOptionPrices.remove(currentList.first);
        }
        _selectedOptions[group.id] = [option.id];
        _selectedOptionPrices[option.id] = option.priceModifier;
      } else {
        // Toggle múltipla escolha
        if (currentList.contains(option.id)) {
          // Remove se já estiver selecionado
          if (currentList.length > group.qtdMin) {
            currentList.remove(option.id);
            _selectedOptionPrices.remove(option.id);
          }
        } else {
          // Adiciona se não exceder o máximo efetivo
          if (currentList.length < effectiveMax) {
            currentList.add(option.id);
            _selectedOptionPrices[option.id] = option.priceModifier;
          }
        }
        _selectedOptions[group.id] = List.from(currentList);
      }
      _enforceEffectiveMax();
    });
  }

  bool _isSelected(ProductOptionGroup group, ProductOption option) {
    final list = _selectedOptions[group.id] ?? [];
    return list.contains(option.id);
  }

  String _getOptionDisplayName() {
    if (_selectedOptions.isEmpty) return '';
    final parts = <String>[];
    for (final group in widget.product.optionGroups) {
      final selectedIds = _selectedOptions[group.id] ?? [];
      for (final id in selectedIds) {
        final option = group.options.firstWhere(
          (o) => o.id == id,
          orElse: () => ProductOption(id: '', name: ''),
        );
        if (option.name.isNotEmpty) parts.add(option.name);
      }
    }
    return parts.join(' / ');
  }

  bool _canAddToCart() {
    for (final group in widget.product.optionGroups) {
      final selectedCount = (_selectedOptions[group.id] ?? []).length;
      final effectiveMax = _effectiveQtdMax(group);
      if (group.isObrigatorio && selectedCount < group.qtdMin) {
        return false;
      }
      if (selectedCount < group.qtdMin) {
        return false;
      }
      if (selectedCount > effectiveMax) {
        return false;
      }
    }
    return true;
  }

  String? _validationMessage() {
    for (final group in widget.product.optionGroups) {
      final selectedCount = (_selectedOptions[group.id] ?? []).length;
      final effectiveMax = _effectiveQtdMax(group);
      if (group.isObrigatorio && selectedCount < group.qtdMin) {
        return 'Selecione pelo menos ${group.qtdMin} opção(ões) em "${group.name}"';
      }
      if (selectedCount < group.qtdMin) {
        return 'Selecione pelo menos ${group.qtdMin} opção(ões) em "${group.name}"';
      }
      if (selectedCount > effectiveMax) {
        return 'Selecione no máximo $effectiveMax opção(ões) em "${group.name}"';
      }
    }
    return null;
  }

  void _addToCart() async {
    final validation = _validationMessage();
    if (validation != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            validation,
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
      return;
    }

    HapticFeedback.lightImpact();

    final cartProvider = context.read<CartProvider>();
    final observation = _obsController.text.trim();

    cartProvider.addItem(
      widget.product,
      quantity,
      observation.isEmpty ? null : observation,
      _selectedOptions,
      _selectedOptionPrices,
      _totalOptionsPrice,
    );

    setState(() => _added = true);

    await Future.delayed(const Duration(milliseconds: 1200));
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${widget.product.name} (x$quantity) adicionado ao carrinho!',
            style: GoogleFonts.inter(fontWeight: FontWeight.w500),
          ),
          backgroundColor: AppTheme.tachaoRed,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Widget _buildProductImage(BuildContext context) {
    return ProductImage(
      product: widget.product,
      fit: BoxFit.cover,
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasOptions = widget.product.optionGroups.isNotEmpty;
    final canAdd = _canAddToCart();

    return Scaffold(
      backgroundColor: AppTheme.background(context),
      body: CustomScrollView(
        slivers: [
          // SliverAppBar with Hero image
          SliverAppBar(
            expandedHeight: 320,
            pinned: true,
            backgroundColor: AppTheme.background(context),
            elevation: 0,
            leading: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  _buildProductImage(context),
                  // Gradient overlay at bottom
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 100,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.5),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ),
                  // Badge
                  if (widget.product.badge != null)
                    Positioned(
                      top: 80,
                      left: 16,
                      child: ProductBadge(badge: widget.product.badge!),
                    ),
                ],
              ),
            ),
          ),
          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name
                  Text(
                    widget.product.name,
                    style: GoogleFonts.poppins(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary(context),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const SizedBox(height: 16),
                  // Price
                  Text(
                    widget.product.priceDisplay,
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.tachaoRed,
                    ),
                  ),
                  if (hasOptions)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        '+ opções',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppTheme.textSecondary(context),
                        ),
                      ),
                    ),
                  const SizedBox(height: 24),
                  Divider(color: AppTheme.border(context), thickness: 1),
                  const SizedBox(height: 20),
                  // Description
                  Text(
                    'Descrição',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary(context),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.product.description,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: AppTheme.textSecondary(context),
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Option Groups
                  if (hasOptions)
                    ...widget.product.optionGroups.map((group) {
                      final selectedCount =
                          (_selectedOptions[group.id] ?? []).length;
                      final effectiveMax = _effectiveQtdMax(group);
                      final isValid = selectedCount >= group.qtdMin &&
                          selectedCount <= effectiveMax;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  group.name,
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.textPrimary(context),
                                  ),
                                ),
                              ),
                              if (group.qtdMin > 0 || effectiveMax > 1)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isValid
                                        ? Colors.green.withValues(alpha: 0.1)
                                        : Colors.orange.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    group.qtdMin == effectiveMax
                                        ? 'Escolha ${group.qtdMin}'
                                        : group.qtdMin > 0
                                            ? 'Min ${group.qtdMin} / Max $effectiveMax'
                                            : 'Max $effectiveMax',
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      color: isValid
                                          ? Colors.green[700]
                                          : Colors.orange[700],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: group.options.map((option) {
                              final isSelected = _isSelected(group, option);
                              return GestureDetector(
                                onTap: () => _toggleOption(group, option),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? AppTheme.tachaoRed
                                        : AppTheme.inputBg(context),
                                    borderRadius: BorderRadius.circular(12),
                                    border: isSelected
                                        ? null
                                        : Border.all(
                                            color: AppTheme.border(context),
                                          ),
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          if (_isEffectivelyMultipleChoice(group))
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                right: 6,
                                              ),
                                              child: Icon(
                                                isSelected
                                                    ? Icons.check_box
                                                    : Icons.check_box_outline_blank,
                                                size: 16,
                                                color: isSelected
                                                    ? Colors.white
                                                    : AppTheme.textSecondary(context),
                                              ),
                                            ),
                                          Text(
                                            option.name,
                                            style: GoogleFonts.inter(
                                              fontSize: 13,
                                              fontWeight: isSelected
                                                  ? FontWeight.w600
                                                  : FontWeight.w500,
                                              color: isSelected
                                                  ? Colors.white
                                                  : AppTheme.textPrimary(context),
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (option.priceModifier > 0)
                                        Text(
                                          '+ R\$ ${option.priceModifier.toStringAsFixed(2).replaceAll('.', ',')}',
                                          style: GoogleFonts.inter(
                                            fontSize: 11,
                                            color: isSelected
                                                ? Colors.white
                                                    .withValues(alpha: 0.85)
                                                : AppTheme.textSecondary(context),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 20),
                        ],
                      );
                    }),
                  // Ingredients
                  Text(
                    'Ingredientes',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary(context),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: widget.product.ingredients.map((ingredient) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.inputBg(context),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          ingredient,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: AppTheme.textSecondary(context),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  // Observation
                  Text(
                    'Observações',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary(context),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _obsController,
                    decoration: InputDecoration(
                      hintText: 'Alguma observação? Ex: Sem açúcar...',
                      hintStyle: GoogleFonts.inter(
                        fontSize: 13,
                        color: Colors.grey[400],
                      ),
                      filled: true,
                      fillColor: AppTheme.inputBg(context),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.all(14),
                    ),
                    maxLines: 2,
                    style: GoogleFonts.inter(fontSize: 14),
                  ),
                  const SizedBox(height: 24),
                  // Quantity
                  Row(
                    children: [
                      Text(
                        'Quantidade',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary(context),
                        ),
                      ),
                      const Spacer(),
                      Container(
                        decoration: BoxDecoration(
                          color: AppTheme.inputBg(context),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            _buildQuantityButton(
                              icon: Icons.remove,
                              onTap: () {
                                if (quantity > 1) {
                                  setState(() => quantity--);
                                }
                              },
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                '$quantity',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textPrimary(context),
                                ),
                              ),
                            ),
                            _buildQuantityButton(
                              icon: Icons.add,
                              onTap: () => setState(() => quantity++),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
      // Bottom floating button
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
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
              if (_selectedOptions.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text(
                    _getOptionDisplayName(),
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppTheme.textSecondary(context),
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ElevatedButton(
                onPressed: (_added || !canAdd) ? null : _addToCart,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _added ? Colors.green[600] : AppTheme.tachaoRed,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _added
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          key: const ValueKey('added'),
                          children: [
                            const Icon(Icons.check_circle, size: 22),
                            const SizedBox(width: 8),
                            Text(
                              'Adicionado!',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          key: const ValueKey('add'),
                          children: [
                            Text(
                              'Adicionar',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'R\$ ${total.toStringAsFixed(2).replaceAll('.', ',')}',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuantityButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        child: Icon(
          icon,
          color: AppTheme.tachaoRed,
          size: 20,
        ),
      ),
    );
  }
}
