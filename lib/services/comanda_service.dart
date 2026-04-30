import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/cart_item.dart';

class ComandaService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<Map<String, dynamic>?> buscarComanda(String numero, int empresaId) async {
    final response = await _client
        .from('comanda')
        .select()
        .eq('empresa_id', empresaId)
        .eq('numero', int.tryParse(numero) ?? 0)
        .maybeSingle();
    return response;
  }

  Future<Map<String, dynamic>> criarComanda(String numero, int empresaId, {int? mesaId}) async {
    final response = await _client
        .from('comanda')
        .insert({
          'empresa_id': empresaId,
          'numero': int.tryParse(numero) ?? 0,
          'mesa_id': mesaId,
          'status': 'ABERTA',
          'hora_abertura': DateTime.now().toIso8601String(),
          'hora_ultimo_pedido': DateTime.now().toIso8601String(),
          'valor_total': 0,
          'is_ativo': true,
        })
        .select()
        .single();
    return response;
  }

  Future<void> adicionarItens(int comandaId, int empresaId, List<CartItem> itens) async {
    for (final item in itens) {
      final response = await _client
          .from('comanda_item')
          .insert({
            'empresa_id': empresaId,
            'comanda_id': comandaId,
            'produto_id': int.tryParse(item.productId) ?? 0,
            'quantidade': item.quantity,
            'valor_unitario': item.unitPrice,
            'valor_total_item': item.total,
            'observacao': item.observation,
            'status': 'ATIVO',
            'created_at': DateTime.now().toIso8601String(),
          })
          .select()
          .single();

      final comandaItemId = response['id'] as int;

      if (item.selectedOptions.isNotEmpty) {
        final modificadores = item.selectedOptions.entries.map((entry) {
          return {
            'comanda_item_id': comandaItemId,
            'grupo_modificador_item_id': int.tryParse(entry.value) ?? 0,
            'quantidade': 1,
            'vr_adicional': 0,
            'created_at': DateTime.now().toIso8601String(),
          };
        }).toList();

        await _client.from('comanda_item_modificador').insert(modificadores);
      }
    }
  }

  Future<void> atualizarTotalComanda(int comandaId) async {
    final response = await _client
        .from('comanda_item')
        .select('valor_total_item')
        .eq('comanda_id', comandaId)
        .eq('status', 'ATIVO');

    double total = 0;
    for (final row in response as List) {
      total += (row['valor_total_item'] as num?)?.toDouble() ?? 0;
    }

    await _client.from('comanda').update({
      'valor_total': total,
      'hora_ultimo_pedido': DateTime.now().toIso8601String(),
    }).eq('id', comandaId);
  }

  Future<void> registrarLog(int comandaId, int? mesaId, int empresaId, String acao, Map<String, dynamic> detalhes) async {
    await _client.from('comanda_log').insert({
      'empresa_id': empresaId,
      'comanda_id': comandaId,
      'mesa_id': mesaId,
      'acao': acao,
      'detalhes': detalhes,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<void> adicionarFilaImpressao(int comandaId, int empresaId, List<CartItem> itens, String numeroComanda) async {
    final buffer = StringBuffer();
    buffer.writeln('=== NOVO PEDIDO - COMANDA $numeroComanda ===');
    for (final item in itens) {
      buffer.writeln('${item.quantity}x ${item.name}');
      if (item.selectedOptions.isNotEmpty) {
        buffer.writeln('   Opções: ${item.selectedOptions.values.join(', ')}');
      }
      if (item.observation != null && item.observation!.isNotEmpty) {
        buffer.writeln('   Obs: ${item.observation}');
      }
    }

    await _client.from('fila_impressao').insert({
      'empresa_id': empresaId,
      'setor': 'Cozinha',
      'conteudo': buffer.toString(),
      'impresso': false,
      'criado_em': DateTime.now().toIso8601String(),
    });
  }
}
