import 'package:flutter/material.dart';

import '../models/list_browse_state.dart';

class ListControls extends StatefulWidget {
  const ListControls({
    super.key,
    required this.name,
    required this.state,
    required this.onChanged,
    required this.searchLabel,
    this.filters = const {},
    this.filterLabel = 'Filter',
    this.sorts = const {
      'order': 'Saved order',
      'title': 'Title A-Z',
      'title-desc': 'Title Z-A',
    },
    this.enabled = true,
  });
  final String name, searchLabel, filterLabel;
  final ListBrowseState state;
  final VoidCallback onChanged;
  final Map<String, String> filters, sorts;
  final bool enabled;
  @override
  State<ListControls> createState() => _ListControlsState();
}

class _ListControlsState extends State<ListControls> {
  late final _query = TextEditingController(text: widget.state.query);
  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  void _change(VoidCallback update) {
    update();
    widget.state.page = 0;
    widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final filters = {
      '': 'All',
      ...widget.filters,
      if (state.filter.isNotEmpty && !widget.filters.containsKey(state.filter))
        state.filter: 'Unavailable selection (reset to clear)',
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          key: ValueKey('search-${widget.name}'),
          controller: _query,
          enabled: widget.enabled,
          onChanged: (v) => _change(() => state.query = v),
          decoration: InputDecoration(
            labelText: widget.searchLabel,
            prefixIcon: const Icon(Icons.search),
            border: const OutlineInputBorder(),
            suffixIcon: state.query.isEmpty
                ? null
                : IconButton(
                    tooltip: 'Clear search',
                    onPressed: !widget.enabled
                        ? null
                        : () => _change(() {
                            _query.clear();
                            state.query = '';
                          }),
                    icon: const Icon(Icons.close),
                  ),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            if (widget.filters.isNotEmpty || state.filter.isNotEmpty)
              SizedBox(
                width: 230,
                child: DropdownButtonFormField<String>(
                  key: ValueKey('filter-${widget.name}-${state.filter}'),
                  initialValue: state.filter,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: widget.filterLabel,
                    border: const OutlineInputBorder(),
                  ),
                  items: [
                    for (final entry in filters.entries)
                      DropdownMenuItem(
                        value: entry.key,
                        child: Text(
                          entry.value,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  onChanged: !widget.enabled
                      ? null
                      : (v) => _change(() => state.filter = v ?? ''),
                ),
              ),
            SizedBox(
              width: 230,
              child: DropdownButtonFormField<String>(
                key: ValueKey('sort-${widget.name}-${state.sort}'),
                initialValue: state.sort,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Sort',
                  border: OutlineInputBorder(),
                ),
                items: [
                  for (final entry in widget.sorts.entries)
                    DropdownMenuItem(
                      value: entry.key,
                      child: Text(entry.value),
                    ),
                ],
                onChanged: !widget.enabled
                    ? null
                    : (v) => _change(() => state.sort = v ?? 'order'),
              ),
            ),
            TextButton.icon(
              key: ValueKey('reset-${widget.name}'),
              onPressed: !widget.enabled || state.isDefault
                  ? null
                  : () {
                      state.reset();
                      _query.clear();
                      widget.onChanged();
                    },
              icon: const Icon(Icons.filter_alt_off_outlined),
              label: const Text('Reset filters'),
            ),
          ],
        ),
      ],
    );
  }
}

class ListPager extends StatelessWidget {
  const ListPager({
    super.key,
    required this.name,
    required this.state,
    required this.total,
    required this.matched,
    required this.onChanged,
    this.size = 20,
    this.enabled = true,
  });
  final String name;
  final ListBrowseState state;
  final int total, matched, size;
  final VoidCallback onChanged;
  final bool enabled;
  @override
  Widget build(BuildContext context) {
    final pages = matched == 0 ? 1 : (matched + size - 1) ~/ size;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Wrap(
        spacing: 12,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text('$matched of $total results', key: ValueKey('results-$name')),
          if (pages > 1) ...[
            OutlinedButton(
              key: ValueKey('previous-$name'),
              onPressed: !enabled || state.page == 0
                  ? null
                  : () {
                      state.page--;
                      onChanged();
                    },
              child: const Text('Previous'),
            ),
            Text('Page ${state.page + 1} of $pages'),
            OutlinedButton(
              key: ValueKey('next-$name'),
              onPressed: !enabled || state.page >= pages - 1
                  ? null
                  : () {
                      state.page++;
                      onChanged();
                    },
              child: const Text('Next'),
            ),
          ],
        ],
      ),
    );
  }
}
