class ProductCategory {
  final String slug;
  final String name;
  final String url;

  ProductCategory({
    required this.slug,
    required this.name,
    required this.url,
  });
  // Supports category objects returned by the API.

  factory ProductCategory.fromJson(dynamic json) {
    if (json is String) {
      return ProductCategory(
        slug: json,
        name: _titleCase(json),
        url: '',
      );
    }

    final map = Map<String, dynamic>.from(json as Map);
    final slug = map['slug'] ?? '';

    return ProductCategory(
      slug: slug,
      name: map['name'] ?? _titleCase(slug),
      url: map['url'] ?? '',
    );
  }

  static String _titleCase(String slug) {
    if (slug.isEmpty) return slug;
    return slug
        .split('-')
        .map((word) =>
            word.isEmpty ? word : '${word[0].toUpperCase()}${word.substring(1)}')
        .join(' ');
  }
}
