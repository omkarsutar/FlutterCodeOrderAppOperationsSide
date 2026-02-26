import 'dart:convert';

/// Pretty prints any object, handling JSON serialization
void prettyPrint(dynamic entity) {
  final encoder = const JsonEncoder.withIndent('  ');

  if (entity == null) {
    print('null');
    return;
  }

  // Try toJson first, then toMap, else just print the entity
  dynamic data;
  if (entity is Map) {
    data = entity;
  } else {
    try {
      data = (entity as dynamic).toJson();
    } catch (_) {
      try {
        data = (entity as dynamic).toMap();
      } catch (_) {
        data = entity.toString();
      }
    }
  }

  final jsonString = encoder.convert(data);
  print(jsonString);
}

/// Converts any object to a pretty-printed JSON string
String toPrettyJson(dynamic entity) {
  final encoder = const JsonEncoder.withIndent('  ');
  dynamic data;

  if (entity == null) {
    return 'null';
  }

  if (entity is Map) {
    data = entity;
  } else {
    try {
      data = (entity as dynamic).toJson();
    } catch (_) {
      try {
        data = (entity as dynamic).toMap();
      } catch (_) {
        return entity.toString();
      }
    }
  }

  return encoder.convert(data);
}

// How to show Json on page for debugging
/* Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(16),
                          child: SelectableText(
                            toPrettyJson(entity),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontFamily: 'monospace',
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ), */
