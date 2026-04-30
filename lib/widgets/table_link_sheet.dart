import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';

class TableLinkSheet extends StatefulWidget {
  const TableLinkSheet({super.key});

  @override
  State<TableLinkSheet> createState() => _TableLinkSheetState();
}

class _TableLinkSheetState extends State<TableLinkSheet> {
  final TextEditingController _tableController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _tableController.dispose();
    super.dispose();
  }

  Future<void> _linkTable() async {
    final tableNumber = _tableController.text.trim();

    if (tableNumber.isEmpty) {
      _showSnackBar('Informe o número da mesa.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      await context.read<AuthProvider>().linkTable(tableNumber);
      if (!mounted) return;
      setState(() => _isLoading = false);
      Navigator.pop(context);
      _showSnackBar('Mesa $tableNumber vinculada com sucesso!', color: const Color(0xFF4CAF50));
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showSnackBar('Erro ao vincular mesa: $e');
    }
  }

  void _showSnackBar(String message, {Color color = Colors.red}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.inter(fontSize: 14)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.border(context),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Vincular Mesa',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary(context),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Informe o número da mesa que você está atendendo.',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppTheme.textSecondary(context),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _tableController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: 'Número da mesa',
              hintStyle: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.grey[400],
              ),
              filled: true,
              fillColor: AppTheme.inputBg(context),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.all(14),
              prefixIcon: Icon(
                Icons.table_restaurant_outlined,
                color: AppTheme.textSecondary(context),
              ),
            ),
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppTheme.textPrimary(context),
            ),
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _linkTable(),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _linkTable,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.tachaoRed,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      'Confirmar',
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
