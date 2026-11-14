import 'package:flutter/material.dart';
import 'figma_widgets.dart';
import 'preview_data.dart';

class MyLeadsPage extends StatefulWidget {
  final PreviewStore store;
  final VoidCallback onWallet, onNotifications;
  final ValueChanged<PreviewLead> onLead;
  const MyLeadsPage({
    super.key,
    required this.store,
    required this.onWallet,
    required this.onNotifications,
    required this.onLead,
  });
  @override
  State<MyLeadsPage> createState() => _MyLeadsPageState();
}

class _MyLeadsPageState extends State<MyLeadsPage> {
  String query = '';
  String? category;
  @override
  Widget build(BuildContext context) {
    final purchased = widget.store.leads.where((l) => l.joined).toList();
    String categoryName(PreviewLead l) =>
        l.category >= 0 && l.category < widget.store.categories.length
        ? widget.store.categories[l.category].name
        : '';
    final shown = purchased
        .where(
          (l) =>
              (category == null || categoryName(l) == category) &&
              '${l.title} ${l.city} ${l.id}'.toLowerCase().contains(
                query.toLowerCase(),
              ),
        )
        .toList();
    return SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FigmaHeader(
            onWallet: widget.onWallet,
            onNotifications: widget.onNotifications,
            unread: widget.store.unread,
            live: widget.store.isLive,
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 18, 24, 20),
              children: [
                const Text(
                  'My Leads',
                  style: TextStyle(
                    color: figmaInk,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  "Track and manage all the leads you've unlocked.",
                  style: TextStyle(color: figmaMuted, fontSize: 14),
                ),
                const SizedBox(height: 18),
                TextField(
                  onChanged: (v) => setState(() => query = v),
                  style: const TextStyle(color: figmaInk, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Search your leads...',
                    hintStyle: const TextStyle(fontSize: 14, color: figmaMuted),
                    prefixIcon: const Icon(Icons.search, size: 18),
                    filled: true,
                    fillColor: Colors.white,
                    isDense: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      ChoiceChip(
                        label: Text('All (${purchased.length})'),
                        selected: category == null,
                        onSelected: (_) => setState(() => category = null),
                      ),
                      ...purchased
                          .map(categoryName)
                          .where((c) => c.isNotEmpty)
                          .toSet()
                          .map(
                            (c) => Padding(
                              padding: const EdgeInsets.only(left: 7),
                              child: ChoiceChip(
                                label: Text(c),
                                selected: category == c,
                                onSelected: (_) => setState(() => category = c),
                              ),
                            ),
                          ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                if (shown.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 48),
                    child: Text(
                      'No unlocked leads found.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: figmaMuted),
                    ),
                  ),
                ...shown.map(
                  (l) => FigmaLeadCard(
                    lead: l,
                    store: widget.store,
                    purchased: true,
                    onTap: () => widget.onLead(l),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
