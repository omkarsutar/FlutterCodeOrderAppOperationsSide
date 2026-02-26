import 'package:flutter/material.dart';

class CollapsibleSearchBar extends StatefulWidget {
  final Widget dropdown;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const CollapsibleSearchBar({
    super.key,
    required this.dropdown,
    required this.controller,
    required this.onChanged,
  });

  @override
  State<CollapsibleSearchBar> createState() => _CollapsibleSearchBarState();
}

class _CollapsibleSearchBarState extends State<CollapsibleSearchBar> {
  bool _isSearchActive = false;
  final FocusNode _searchFocusNode = FocusNode();

  void _toggleSearch() {
    setState(() {
      _isSearchActive = !_isSearchActive;
      if (_isSearchActive) {
        // Request focus when search is activated
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted) _searchFocusNode.requestFocus();
        });
      } else {
        widget.controller.clear();
        widget.onChanged('');
        _searchFocusNode.unfocus();
      }
    });
  }

  @override
  void dispose() {
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        children: [
          // Left side: dropdown or search bar, crossfaded
          Expanded(
            child: AnimatedCrossFade(
              duration: const Duration(milliseconds: 300),
              crossFadeState: _isSearchActive
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              firstChild: widget.dropdown, // stays mounted, no refetch
              secondChild: TextField(
                controller: widget.controller,
                focusNode: _searchFocusNode,
                onChanged: widget.onChanged,
                decoration: InputDecoration(
                  hintText: 'Search...',
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: _toggleSearch,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: theme.colorScheme.surface,
                ),
              ),
            ),
          ),
          // Right side: search icon only when not active
          if (!_isSearchActive)
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: _toggleSearch,
            ),
        ],
      ),
    );
  }
}
