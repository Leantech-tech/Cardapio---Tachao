import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/category.dart';
import '../models/product.dart';

class MenuService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<Category>> fetchCategories() async {
    final response = await _client
        .from('prod_categoria')
        .select('id, nome')
        .eq('empresa_id', 7)
        .eq('is_ativo', true)
        .eq('is_excluido', false)
        .order('nome', ascending: true);

    return (response as List<dynamic>)
        .map((json) => Category.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<List<Product>> fetchProducts() async {
    final response = await _client
        .from('produto')
        .select('id, nome, inf_adicionais, vr_venda, foto_url, categoria_id, is_ativo')
        .eq('empresa_id', 7)
        .eq('is_ativo', true)
        .eq('is_excluido', false)
        .order('nome', ascending: true);

    return (response as List<dynamic>)
        .map((json) => Product.fromJson(json as Map<String, dynamic>))
        .toList();
  }
}
