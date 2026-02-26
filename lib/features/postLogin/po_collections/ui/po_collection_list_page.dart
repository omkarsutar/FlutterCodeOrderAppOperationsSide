import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/po_collection_providers.dart';
import 'po_collection_list_tile.dart';

import '../../../../shared/widgets/shared_widget_barrel.dart';

class PoCollectionListPage extends ConsumerStatefulWidget {
  const PoCollectionListPage({super.key});

  @override
  ConsumerState<PoCollectionListPage> createState() =>
      _PoCollectionListPageState();
}

class _PoCollectionListPageState extends ConsumerState<PoCollectionListPage> {
  String _filter = 'all'; // all, cash, online, cheque, sign

  @override
  Widget build(BuildContext context) {
    final collectionsAsync = ref.watch(poCollectionsStreamProvider);

    return Scaffold(
      drawer: const CustomDrawer(),
      appBar: AppBar(
        title: const Text('All Collections'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: collectionsAsync.when(
            data: (collections) {
              final allCount = collections.length;
              final cashCount = collections.where((c) => c.isCash).length;
              final onlineCount = collections.where((c) => c.isOnline).length;
              final chequeCount = collections.where((c) => c.isCheque).length;
              final signCount = collections.where((c) => c.isSign).length;

              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    _buildFilterChip('All', 'all', allCount),
                    const SizedBox(width: 8),
                    _buildFilterChip('Cash', 'cash', cashCount),
                    const SizedBox(width: 8),
                    _buildFilterChip('Online', 'online', onlineCount),
                    const SizedBox(width: 8),
                    _buildFilterChip('Cheque', 'cheque', chequeCount),
                    const SizedBox(width: 8),
                    _buildFilterChip('Credit/Sign', 'sign', signCount),
                  ],
                ),
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ),
      ),
      body: collectionsAsync.when(
        data: (collections) {
          final filteredList = collections.where((c) {
            if (_filter == 'all') return true;
            if (_filter == 'cash') return c.isCash;
            if (_filter == 'online') return c.isOnline;
            if (_filter == 'cheque') return c.isCheque;
            if (_filter == 'sign') return c.isSign;
            return true;
          }).toList();

          if (filteredList.isEmpty) {
            return const Center(child: Text('No collections found.'));
          }

          return ListView.builder(
            itemCount: filteredList.length,
            itemBuilder: (context, index) {
              return PoCollectionListTile(entity: filteredList[index]);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, int count) {
    final isSelected = _filter == value;
    return ChoiceChip(
      label: Text('$label ($count)'),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() => _filter = value);
        }
      },
    );
  }
}
