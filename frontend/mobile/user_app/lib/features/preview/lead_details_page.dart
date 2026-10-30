import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'category_leads_page.dart';
import 'preview_data.dart';

class LeadDetailsPreview extends StatelessWidget {
  final PreviewLead lead;
  final PreviewStore store;
  const LeadDetailsPreview({
    super.key,
    required this.lead,
    required this.store,
  });

  static const _blue = Color(0xFF0066FF);
  static const _navy = Color(0xFF081744);
  static const _muted = Color(0xFF7484A7);

  String get _category =>
      lead.category >= 0 && lead.category < store.categories.length
      ? store.categories[lead.category].name
      : 'Project';

  String get _budget =>
      lead.budgetLabel ??
      (lead.budget > 0 ? '₹ ${lead.budget}' : 'Not specified');

  Future<void> _unlock(BuildContext context) async {
    if (store.isLive) {
      await store.checkout?.call(context, lead);
      return;
    }
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Test checkout'),
        content: Text('${lead.title}\nLead access fee: ₹${lead.fee}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, 'success'),
            child: const Text('Unlock'),
          ),
        ],
      ),
    );
    if (result == 'success' && context.mounted) {
      store.purchase(lead);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lead unlocked. Contact details remain protected.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: store,
    builder: (context, _) {
      final artwork = categoryArtwork(_category);
      final requirements = lead.description
          .split(RegExp(r'(?<=[.!?])\\s+'))
          .where((item) => item.trim().isNotEmpty)
          .toList();
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          titleSpacing: 0,
          leading: IconButton(
            tooltip: 'Back',
            onPressed: () => Navigator.maybePop(context),
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _navy),
          ),
          title: Image.asset(
            'assets/branding/nextlead_wordmark.webp',
            width: 150,
            height: 48,
          ),
          actions: [
            IconButton(
              tooltip: lead.saved ? 'Unsave lead' : 'Save lead',
              onPressed: () => store.toggleSaved(lead),
              icon: Icon(
                lead.saved ? Icons.favorite : Icons.favorite_border,
                color: _navy,
              ),
            ),
            IconButton(
              tooltip: 'Copy lead summary',
              onPressed: () async {
                await Clipboard.setData(
                  ClipboardData(
                    text:
                        '${lead.title} • ${lead.city} • $_budget • ${lead.id}',
                  ),
                );
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Lead summary copied')),
                  );
                }
              },
              icon: const Icon(Icons.more_vert, color: _navy),
            ),
          ],
        ),
        body: SafeArea(
          top: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 132),
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAF3FF),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: artwork == null
                        ? const Icon(
                            Icons.home_work_outlined,
                            color: _blue,
                            size: 54,
                          )
                        : Image.asset(
                            'assets/Nextlead Mobile  App Asetes/$artwork',
                            fit: BoxFit.contain,
                          ),
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _tag(_category),
                        const SizedBox(height: 8),
                        Text(
                          lead.title,
                          style: const TextStyle(
                            color: _navy,
                            fontSize: 22,
                            height: 1.13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on,
                              size: 19,
                              color: _blue,
                            ),
                            const SizedBox(width: 5),
                            Expanded(
                              child: Text(
                                lead.city,
                                style: const TextStyle(
                                  color: _muted,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 17),
              _stats(),
              const SizedBox(height: 23),
              const Text(
                'Project Requirements',
                style: TextStyle(
                  color: _navy,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F8FF),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final item
                        in (requirements.isEmpty
                            ? [
                                'Project requirements will be shared after unlocking this lead.',
                              ]
                            : requirements))
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 5),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.check, color: _blue, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                item.trim(),
                                style: const TextStyle(
                                  color: _muted,
                                  fontSize: 14,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 23),
              const Text(
                'Client Details',
                style: TextStyle(
                  color: _navy,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              _clientPanel(),
              const SizedBox(height: 23),
              const Text(
                'Project Images',
                style: TextStyle(
                  color: _navy,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              _projectImages(artwork),
              const SizedBox(height: 17),
              _unlockPanel(),
            ],
          ),
        ),
        bottomNavigationBar: SafeArea(
          top: false,
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Color(0x12000000),
                  blurRadius: 10,
                  offset: Offset(0, -2),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton.icon(
                    onPressed: lead.joined || lead.closed
                        ? null
                        : () => _unlock(context),
                    style: FilledButton.styleFrom(
                      backgroundColor: _blue,
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.lock_open_outlined),
                    label: Text(
                      lead.joined
                          ? 'Lead Unlocked'
                          : lead.closed
                          ? lead.availabilityLabel
                          : 'Unlock Lead  •  ₹ ${lead.fee}',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'One time payment • Phone number remains private',
                  style: TextStyle(color: _muted, fontSize: 11),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );

  Widget _tag(String value) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: const Color(0xFFE2F0FF),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      value,
      style: const TextStyle(
        color: _blue,
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
    ),
  );

  Widget _stats() => LayoutBuilder(
    builder: (context, box) {
      final items = [
        (Icons.home_outlined, 'Project Type', lead.propertyType),
        (Icons.currency_rupee, 'Estimated Budget', _budget),
        (Icons.square_foot_outlined, 'Area', lead.area),
        (Icons.calendar_month_outlined, 'Timeline', lead.timeline),
      ];
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final item in items)
            SizedBox(
              width: box.maxWidth < 560
                  ? (box.maxWidth - 8) / 2
                  : (box.maxWidth - 24) / 4,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7FAFF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE1EBFA)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(item.$1, color: _navy, size: 22),
                    const SizedBox(height: 5),
                    Text(
                      item.$2,
                      style: const TextStyle(color: _muted, fontSize: 10),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      item.$3.isEmpty ? 'Not specified' : item.$3,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _navy,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      );
    },
  );

  Widget _clientPanel() => Container(
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(
      border: Border.all(color: const Color(0xFFE1EBFA)),
      borderRadius: BorderRadius.circular(14),
    ),
    child: const Column(
      children: [
        Row(
          children: [
            CircleAvatar(
              backgroundColor: Color(0xFFE9F2FF),
              child: Icon(Icons.person_outline, color: _blue),
            ),
            SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Client details protected',
                    style: TextStyle(color: _navy, fontWeight: FontWeight.w700),
                  ),
                  SizedBox(height: 3),
                  Text(
                    'Contact information is not shown in this app.',
                    style: TextStyle(color: _muted, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    ),
  );

  Widget _projectImages(String? artwork) => SizedBox(
    height: 94,
    child: ListView.separated(
      scrollDirection: Axis.horizontal,
      itemCount: 4,
      separatorBuilder: (_, _) => const SizedBox(width: 9),
      itemBuilder: (_, _) => ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: 112,
          color: const Color(0xFFEAF3FF),
          child: artwork == null
              ? const Icon(Icons.image_outlined, color: _blue)
              : Image.asset(
                  'assets/Nextlead Mobile  App Asetes/$artwork',
                  fit: BoxFit.cover,
                ),
        ),
      ),
    ),
  );

  Widget _unlockPanel() => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: const Color(0xFFF0F7FF),
      borderRadius: BorderRadius.circular(14),
    ),
    child: const Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 25,
          backgroundColor: Color(0xFFDCEEFF),
          child: Icon(Icons.lock_outline, color: _blue),
        ),
        SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Unlock Complete Lead Details',
                style: TextStyle(
                  color: _navy,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 5),
              Text(
                'Get full project requirements and additional images.',
                style: TextStyle(color: _muted, fontSize: 13),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
