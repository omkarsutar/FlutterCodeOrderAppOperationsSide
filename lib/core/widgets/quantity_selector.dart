import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class QuantitySelector extends StatefulWidget {
  final double quantity;
  final ValueChanged<double> onQuantityChanged;
  final bool isDecimal;
  final FocusNode? focusNode;
  final double height;
  final double width;
  final bool readOnly;

  const QuantitySelector({
    super.key,
    required this.quantity,
    required this.onQuantityChanged,
    this.isDecimal = false,
    this.focusNode,
    this.height = 38,
    this.width = double.infinity,
    this.readOnly = false,
  });

  @override
  State<QuantitySelector> createState() => _QuantitySelectorState();
}

class _QuantitySelectorState extends State<QuantitySelector> {
  late TextEditingController _qtyController;

  @override
  void initState() {
    super.initState();
    _qtyController = TextEditingController(text: _formatQty(widget.quantity));
  }

  @override
  void didUpdateWidget(covariant QuantitySelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.quantity != widget.quantity) {
      final formatted = _formatQty(widget.quantity);
      if (_qtyController.text != formatted) {
        _qtyController.text = formatted;
      }
    }
  }

  @override
  void dispose() {
    _qtyController.dispose();
    super.dispose();
  }

  String _formatQty(double val) {
    if (val == 0) return "0";
    String text = val.toStringAsFixed(1);
    if (text.endsWith('.0')) text = text.substring(0, text.length - 2);
    return text;
  }

  void _handleIncrement(double delta) {
    widget.onQuantityChanged(widget.quantity + delta);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      height: widget.height,
      width: widget.width,
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.05),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.5),
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildButton(
            icon: Icons.remove,
            onPressed: () => _handleIncrement(-1.0),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(8),
              bottomLeft: Radius.circular(8),
            ),
            theme: theme,
            enabled: !widget.readOnly,
          ),
          Expanded(
            child: Container(
              height: widget.height,
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.symmetric(
                  vertical: BorderSide(
                    color: theme.colorScheme.primary.withValues(alpha: 0.3),
                  ),
                ),
              ),
              child: TextFormField(
                controller: _qtyController,
                focusNode: widget.focusNode,
                keyboardType: TextInputType.numberWithOptions(
                  decimal: widget.isDecimal,
                ),
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: widget.readOnly
                      ? theme.colorScheme.onSurface.withValues(alpha: 0.5)
                      : theme.colorScheme.primary,
                ),
                decoration: InputDecoration(
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(
                    vertical:
                        (widget.height - 18) / 2, // Center text vertically
                  ),
                  border: InputBorder.none,
                  enabled: !widget.readOnly,
                ),
                inputFormatters: [
                  if (widget.isDecimal)
                    FilteringTextInputFormatter.allow(
                      RegExp(r'^\d{0,3}(\.\d{0,1})?'),
                    )
                  else
                    FilteringTextInputFormatter.digitsOnly,
                ],
                onChanged: (val) {
                  if (val.isEmpty) return;
                  final d = double.tryParse(val);
                  if (d == null) return;
                  if (d != widget.quantity) {
                    widget.onQuantityChanged(d);
                  }
                },
              ),
            ),
          ),
          _buildButton(
            icon: Icons.add,
            onPressed: () => _handleIncrement(1.0),
            borderRadius: const BorderRadius.only(
              topRight: Radius.circular(8),
              bottomRight: Radius.circular(8),
            ),
            theme: theme,
            enabled: !widget.readOnly,
          ),
        ],
      ),
    );
  }

  Widget _buildButton({
    required IconData icon,
    required VoidCallback onPressed,
    required BorderRadius borderRadius,
    required ThemeData theme,
    bool enabled = true,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onPressed : null,
        borderRadius: borderRadius,
        child: Container(
          width: 44,
          height: widget.height,
          alignment: Alignment.center,
          child: Opacity(
            opacity: enabled ? 1.0 : 0.3,
            child: Icon(icon, size: 22, color: theme.colorScheme.primary),
          ),
        ),
      ),
    );
  }
}
