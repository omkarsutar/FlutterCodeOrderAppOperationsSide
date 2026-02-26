class DropdownSource {
  final String table;
  final String valueKey;
  final String labelKey;
  final String? routeName;

  const DropdownSource({
    required this.table,
    required this.valueKey,
    required this.labelKey,
    this.routeName,
  });

  factory DropdownSource.fromJson(Map<String, dynamic> json) {
    return DropdownSource(
      table: json['table'] as String,
      valueKey: json['valueKey'] as String,
      labelKey: json['labelKey'] as String,
      routeName: json['routeName'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'table': table,
      'valueKey': valueKey,
      'labelKey': labelKey,
      if (routeName != null) 'routeName': routeName,
    };
  }
}
