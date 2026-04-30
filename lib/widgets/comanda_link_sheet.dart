import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../models/cart_item.dart';
import '../services/comanda_service.dart';
import '../theme/app_theme.dart';

class ComandaLinkSheet extends StatefulWidget {
  final List<CartItem> itens;
  final double total;
  final VoidCallback onSuccess;

  const ComandaLinkSheet({
    super.key,
    required this.itens,
    required this.total,
    required this.onSuccess,
  });

  @override
  State<ComandaLinkSheet> createState() => _ComandaLinkSheetState();
}

class _ComandaLinkSheetState extends State<ComandaLinkSheet> {
  File? _foto;
  String? _numeroExtraido;
  bool _isLoading = false;

  final _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

  @override
  void dispose() {
    _textRecognizer.close();
    super.dispose();
  }

  Future<void> _tirarFoto() async {
    setState(() => _isLoading = true);

    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
        imageQuality: 85,
      );

      if (pickedFile == null) {
        setState(() => _isLoading = false);
        return;
      }

      final foto = File(pickedFile.path);
      final inputImage = InputImage.fromFile(foto);
      final recognizedText = await _textRecognizer.processImage(inputImage);

      // Extrai o primeiro número encontrado no texto
      String? numero;
      for (final block in recognizedText.blocks) {
        for (final line in block.lines) {
          final texto = line.text.replaceAll(RegExp(r'[^0-9]'), '');
          if (texto.isNotEmpty) {
            numero = texto;
            break;
          }
        }
        if (numero != null) break;
      }

      if (!mounted) return;

      setState(() {
        _foto = foto;
        _numeroExtraido = numero;
        _isLoading = false;
      });

      if (numero == null) {
        _showSnackBar('Não consegui ler o número da comanda. Tente novamente com mais foco.', color: Colors.orange);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showSnackBar('Erro ao processar foto: $e');
    }
  }

  Future<void> _confirmar() async {
    final numero = _numeroExtraido;
    if (numero == null || numero.isEmpty) {
      _showSnackBar('Número da comanda não identificado. Tire a foto novamente.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final service = ComandaService();
      const empresaId = 7;

      var comanda = await service.buscarComanda(numero, empresaId);
      comanda ??= await service.criarComanda(numero, empresaId);

      final comandaId = comanda['id'] as int;
      final mesaId = comanda['mesa_id'] as int?;

      await service.adicionarItens(comandaId, empresaId, widget.itens);
      await service.atualizarTotalComanda(comandaId);
      await service.registrarLog(
        comandaId,
        mesaId,
        empresaId,
        'LANCAMENTO_ITEM',
        {
          'numero_comanda': numero,
          'qtd_itens': widget.itens.length,
          'valor_total': widget.total,
        },
      );
      await service.adicionarFilaImpressao(comandaId, empresaId, widget.itens, numero);

      if (!mounted) return;
      Navigator.pop(context);
      widget.onSuccess();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showSnackBar('Erro ao enviar pedido: $e');
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
        crossAxisAlignment: CrossAxisAlignment.center,
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
            'Vincular Comanda',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary(context),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Tire uma foto da comanda com a câmera frontal.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppTheme.textSecondary(context),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),
          if (_foto != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(
                _foto!,
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 12),
            if (_numeroExtraido != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF4CAF50)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check_circle, color: Color(0xFF4CAF50), size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Comanda nº $_numeroExtraido',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF2E7D32),
                      ),
                    ),
                  ],
                ),
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFFF9800)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: Color(0xFFFF9800), size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Número não identificado',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFFE65100),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isLoading ? null : _tirarFoto,
                    icon: const Icon(Icons.camera_alt_outlined),
                    label: Text(
                      'Tirar outra',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.tachaoRed,
                      side: BorderSide(color: AppTheme.tachaoRed),
                      minimumSize: const Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading || _numeroExtraido == null ? null : _confirmar,
                    icon: _isLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                          )
                        : const Icon(Icons.check),
                    label: Text(
                      'Confirmar',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.tachaoRed,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
          ] else ...[
            SizedBox(
              width: double.infinity,
              height: 180,
              child: OutlinedButton.icon(
                onPressed: _isLoading ? null : _tirarFoto,
                icon: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2.5, color: AppTheme.tachaoRed),
                      )
                    : const Icon(Icons.camera_alt_outlined, size: 32),
                label: Text(
                  'Tirar foto da comanda',
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.tachaoRed,
                  side: BorderSide(color: AppTheme.tachaoRed, width: 2),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
          ],
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
