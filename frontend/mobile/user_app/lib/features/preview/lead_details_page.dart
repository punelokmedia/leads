import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'dart:ui' as ui;
import 'package:flutter_svg/flutter_svg.dart';
import 'category_media.dart';
import 'business_details_page.dart' show accountText;
import 'profile_design.dart' show profileBackground;
import 'preview_data.dart';

class LeadDetailsPreview extends StatelessWidget {
  final PreviewLead lead;
  final PreviewStore store;
  final String? categoryName;
  final Map<String, dynamic>? clientDetails;
  final bool contacted, contacting;
  final VoidCallback? onMarkContacted, onReport;
  final void Function(String action, String value)? onClientAction;
  const LeadDetailsPreview({
    super.key,
    required this.lead,
    required this.store,
    this.categoryName,
    this.clientDetails,
    this.contacted = false,
    this.contacting = false,
    this.onMarkContacted,
    this.onReport,
    this.onClientAction,
  });

  static const _blue = Color(0xFF0066FF);
  static const _navy = Color(0xFF072565);
  static const _muted = Color(0xFF64748B);

  String get _category =>
      categoryName ??
      (lead.category >= 0 && lead.category < store.categories.length
          ? store.categories[lead.category].name
          : 'Project');

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

  bool get _referencePhotos =>
      _category.toLowerCase().contains('civil') ||
      _category.toLowerCase().contains('construction');

  String _image(int index) => _referencePhotos
      ? 'assets/figma/lead-view-$index.png'
      : CategoryMedia.getLeadImage(_category, leadId: lead.id, index: index);

  Widget _photo(BuildContext context, int index, double size) => ClipRRect(
    borderRadius: BorderRadius.circular(12),
    child: Image.asset(
      _image(index),
      width: size,
      height: size,
      fit: BoxFit.cover,
      cacheHeight: _referencePhotos
          ? (size * MediaQuery.devicePixelRatioOf(context)).ceil()
          : null,
    ),
  );

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: store,
    builder: (context, _) {
      final requirements = lead.description
          .split(RegExp(r'(?<=[.!?])\s+|\n+'))
          .where((item) => item.trim().isNotEmpty)
          .toList();
      return Scaffold(
        backgroundColor: profileBackground,
        appBar: AppBar(
          backgroundColor: profileBackground,
          elevation: 0,
          scrolledUnderElevation: 0,
          toolbarHeight: 65,
          leadingWidth: 68,
          titleSpacing: 21.5,
          leading: Padding(
            padding: const EdgeInsets.only(top: 11),
            child: IconButton(
              tooltip: 'Back',
              onPressed: () => Navigator.maybePop(context),
              icon: const Icon(Icons.chevron_left, color: Color(0xFF0F172A)),
            ),
          ),
          title: Padding(
            padding: const EdgeInsets.only(top: 11),
            child: Image.asset(
              'assets/figma/profile-logo.png',
              width: 130,
              height: 43.35,
            ),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(top: 11),
              child: IconButton(
                tooltip: lead.saved ? 'Unsave lead' : 'Save lead',
                onPressed: () => store.toggleSaved(lead),
                icon: Icon(
                  lead.saved ? Icons.bookmark : Icons.bookmark_border,
                  color: const Color(0xFF10B981),
                  size: 20,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 11),
              child: IconButton(
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
                icon: const Icon(
                  Icons.more_vert,
                  color: Color(0xFF1E293B),
                  size: 20,
                ),
              ),
            ),
            const SizedBox(width: 44),
          ],
        ),
        body: SafeArea(
          top: false,
          bottom: false,
          child: ListView(
            key: const ValueKey('lead-details-scroll'),
            padding: const EdgeInsets.only(bottom: 20),
            children: [
              Container(
                margin: const EdgeInsets.fromLTRB(2, 0, 1, 0),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _navy,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    summary(context),
                    const SizedBox(height: 16),
                    _heading('Project Images'),
                    const SizedBox(height: 10),
                    _projectImages(context),
                    const SizedBox(height: 16),
                    _heading('Client Details'),
                    const SizedBox(height: 10),
                    clientDetails == null
                        ? _clientPanel()
                        : _unlockedClientPanel(),
                    const SizedBox(height: 16),
                    _heading('Project Requirements'),
                    const SizedBox(height: 10),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: _blue),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        child: Column(
                          children: [
                            for (final text
                                in requirements.isEmpty
                                    ? [
                                        'Project requirements will be shared after unlocking this lead.',
                                      ]
                                    : requirements)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 5,
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(
                                      Icons.check,
                                      color: _blue,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        text.trim(),
                                        style: accountText(
                                          13,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (!lead.joined)
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 16, 21, 0),
                  child: _unlockPanel(),
                ),
            ],
          ),
        ),
        bottomNavigationBar: clientDetails != null
            ? _contactActions()
            : SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 10, 21, 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FilledButton(
                        onPressed: lead.joined || lead.closed
                            ? null
                            : () => _unlock(context),
                        style: FilledButton.styleFrom(
                          backgroundColor: _blue,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 50),
                          shape: const StadiumBorder(),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          textStyle: accountText(
                            15,
                            color: Colors.white,
                            weight: FontWeight.w700,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              lead.joined
                                  ? Icons.lock_open_outlined
                                  : Icons.lock_outline,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                lead.joined
                                    ? 'Lead Unlocked'
                                    : lead.closed
                                    ? lead.availabilityLabel
                                    : 'Unlock Lead',
                              ),
                            ),
                            if (!lead.joined && !lead.closed) ...[
                              Text(
                                '₹ ${lead.fee}',
                                style: accountText(
                                  14,
                                  color: Colors.white,
                                  weight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.arrow_forward, size: 16),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'One time payment · Get full access to this lead',
                        style: accountText(10, color: _muted),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          const Expanded(
                            child: Divider(color: Color(0xFFE2E8F0)),
                          ),
                          const SizedBox(width: 10),
                          const Icon(
                            Icons.verified_user,
                            color: _blue,
                            size: 13,
                          ),
                          const SizedBox(width: 5),
                          Flexible(
                            flex: 3,
                            child: Text(
                              'Trusted by 10,000+ Vendors',
                              style: accountText(10, color: _muted),
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Divider(color: Color(0xFFE2E8F0)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
      );
    },
  );

  Widget _contactActions() => SafeArea(
    top: false,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(19, 20, 19, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FilledButton.icon(
            onPressed: contacting || contacted ? null : onMarkContacted,
            style: FilledButton.styleFrom(
              backgroundColor: _blue,
              foregroundColor: Colors.white,
              minimumSize: const Size(0, 48),
              textStyle: accountText(14, weight: FontWeight.w700),
              shape: const StadiumBorder(),
            ),
            icon: contacting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(
                    contacted
                        ? Icons.check_circle_outline
                        : Icons.assignment_turned_in_outlined,
                    size: 20,
                  ),
            label: Text(
              contacting
                  ? 'Saving…'
                  : contacted
                  ? 'Contacted'
                  : 'Mark as Contacted',
            ),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: onReport,
            style: OutlinedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFFEF4444),
              minimumSize: const Size(0, 44),
              side: const BorderSide(color: Color(0xFFCBD5E1)),
              shape: const StadiumBorder(),
              textStyle: accountText(13, weight: FontWeight.w600),
            ),
            icon: const Icon(Icons.block, size: 17),
            label: const Text('Report Issue'),
          ),
        ],
      ),
    ),
  );

  Widget _unlockedClientPanel() {
    final data = clientDetails!;
    String value(String key) => '${data[key] ?? ''}'.trim();
    final phone = value('primaryPhone').isEmpty
        ? value('phone')
        : value('primaryPhone');
    final location = [
      value('areaLocality'),
      value('city'),
    ].where((s) => s.isNotEmpty).join(', ');
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: LayoutBuilder(
          builder: (context, bounds) {
            final columns =
                bounds.maxWidth < 280 ||
                    MediaQuery.textScalerOf(context).scale(11) > 14
                ? 1
                : 2;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Wrap(
                  spacing: 12,
                  runSpacing: 16,
                  children: [
                    for (final field in [
                      (Icons.person, 'Name', value('customerName')),
                      (Icons.phone, 'Phone Number', phone),
                      (Icons.location_on, 'Location', location),
                      (Icons.mail, 'Email Address', value('email')),
                    ])
                      SizedBox(
                        width: (bounds.maxWidth - 12 * (columns - 1)) / columns,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              radius: 16,
                              backgroundColor: const Color(0xFFEFF6FF),
                              child: Icon(field.$1, size: 17, color: _blue),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    field.$2,
                                    style: accountText(
                                      10,
                                      color: const Color(0xFF94A3B8),
                                    ),
                                  ),
                                  SelectableText(
                                    field.$3.isEmpty
                                        ? 'Not provided'
                                        : field.$3,
                                    style: accountText(
                                      12,
                                      weight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final action in [
                      ('Call Now', Icons.phone, _blue, 'call', phone),
                      (
                        'WhatsApp',
                        Icons.chat_outlined,
                        const Color(0xFF10B981),
                        'whatsapp',
                        phone,
                      ),
                      (
                        'Send Message',
                        Icons.share_outlined,
                        const Color(0xFF10B981),
                        'sms',
                        phone,
                      ),
                    ])
                      FilledButton.icon(
                        onPressed: action.$5.isEmpty
                            ? null
                            : () => onClientAction?.call(action.$4, action.$5),
                        style: FilledButton.styleFrom(
                          backgroundColor: action.$3,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(0, 30),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 6,
                          ),
                          textStyle: accountText(11, weight: FontWeight.w600),
                        ),
                        icon: Icon(action.$2, size: 14),
                        label: Text(action.$1),
                      ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _heading(String title) => Text(
    title,
    style: accountText(15, color: Colors.white, weight: FontWeight.w700),
  );

  String _posted() {
    final age = DateTime.now().difference(lead.postedAt!);
    return age.inDays > 0
        ? 'Posted ${age.inDays} days ago'
        : age.inHours > 0
        ? 'Posted ${age.inHours} hours ago'
        : 'Posted just now';
  }

  Widget _stats() => LayoutBuilder(
    builder: (context, bounds) {
      final columns =
          bounds.maxWidth < 300 ||
              MediaQuery.textScalerOf(context).scale(10) > 12
          ? 2
          : 4;
      final items = [
        (Icons.home_outlined, 'Project\nType', lead.propertyType),
        (Icons.currency_rupee, 'Estimated\nBudget', _budget),
        (Icons.crop_free, 'Area', lead.area),
        (Icons.calendar_month_outlined, 'Timeline', lead.timeline),
      ];
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: items
            .map(
              (item) => SizedBox(
                width: (bounds.maxWidth - 8 * (columns - 1)) / columns,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 90),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFF),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFEFF6FF)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 9,
                      ),
                      child: Column(
                        children: [
                          Icon(item.$1, color: _blue, size: 16),
                          const SizedBox(height: 3),
                          SizedBox(
                            height:
                                MediaQuery.textScalerOf(context).scale(20) *
                                1.3,
                            child: Text(
                              item.$2,
                              textAlign: TextAlign.center,
                              style: accountText(
                                10,
                                color: const Color(0xFF94A3B8),
                                weight: FontWeight.w400,
                              ),
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            item.$3.isEmpty ? 'Not specified' : item.$3,
                            textAlign: TextAlign.center,
                            style: accountText(
                              10,
                              color: const Color(0xFF0C1E3C),
                              weight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            )
            .toList(),
      );
    },
  );

  Widget _clientPanel() => Semantics(
    label:
        'Client details protected. Contact information is not shown in this app.',
    child: Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ExcludeSemantics(
              child: ImageFiltered(
                imageFilter: ui.ImageFilter.blur(sigmaX: 3, sigmaY: 3),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.person,
                          color: Color(0xFF93C5FD),
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: _redacted()),
                        const SizedBox(width: 16),
                        const Icon(
                          Icons.phone,
                          color: Color(0xFF93C5FD),
                          size: 26,
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: _redacted()),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          color: Color(0xFF93C5FD),
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        SizedBox(width: 100, child: _redacted()),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Client details protected',
              style: accountText(10, color: _muted),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _redacted() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const SizedBox(
        width: 60,
        height: 6,
        child: ColoredBox(color: Color(0xFFE2E8F0)),
      ),
      const SizedBox(height: 8),
      const SizedBox(
        width: 100,
        height: 10,
        child: ColoredBox(color: Color(0xFF64748B)),
      ),
    ],
  );

  Widget _projectImages(BuildContext context) => SizedBox(
    height: 78,
    child: Stack(
      clipBehavior: Clip.none,
      children: [
        ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: 4,
          separatorBuilder: (_, _) => const SizedBox(width: 10),
          itemBuilder: (_, index) => InkWell(
            onTap: () => _gallery(context, index + 1),
            child: _photo(context, index + 1, 78),
          ),
        ),
        Positioned(
          right: -4,
          top: 23,
          child: SizedBox(
            width: 32,
            height: 32,
            child: IconButton.filled(
              tooltip: 'View project images',
              style: IconButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: _blue,
              ),
              onPressed: () => _gallery(context, 0),
              padding: EdgeInsets.zero,
              icon: const Icon(Icons.chevron_right, size: 20),
            ),
          ),
        ),
      ],
    ),
  );

  void _gallery(BuildContext context, int initial) => showDialog<void>(
    context: context,
    builder: (context) => Dialog(
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.6,
        child: Stack(
          children: [
            PageView.builder(
              itemCount: 5,
              itemBuilder: (_, index) => InteractiveViewer(
                child: Image.asset(
                  _image((index + initial) % 5),
                  fit: BoxFit.contain,
                ),
              ),
            ),
            Positioned(
              right: 4,
              top: 4,
              child: IconButton(
                tooltip: 'Close gallery',
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _unlockPanel() => DecoratedBox(
    decoration: BoxDecoration(
      color: const Color(0xFFFFE57E),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Padding(
      padding: const EdgeInsets.all(17),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SvgPicture.asset(
                'assets/figma/lead-view-unlock.svg',
                width: 48,
                height: 48,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Unlock Complete Lead Details',
                      style: accountText(
                        14,
                        color: const Color(0xFF0F172A),
                        weight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Get full project requirements and additional images.',
                      style: accountText(11, weight: FontWeight.w400),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 26),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: ['Full Requirements', 'Protected contact', 'More Images']
                .map(
                  (label) => DecoratedBox(
                    decoration: BoxDecoration(
                      color: const Color(0xEEFFFFFF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.check_circle,
                            color: _blue,
                            size: 14,
                          ),
                          const SizedBox(width: 6),
                          Text(label, style: accountText(10)),
                        ],
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    ),
  );

  Widget summary(BuildContext context) => Material(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
    child: Padding(
      padding: const EdgeInsets.all(15),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  _photo(context, 0, 112),
                  Positioned(
                    left: 6,
                    bottom: 6,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: const Color(0xAA292524),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        child: Text(
                          '1/5',
                          style: accountText(10, color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEF5FF),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        child: Text(
                          _category,
                          style: accountText(
                            11,
                            color: _blue,
                            weight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      lead.title,
                      style: accountText(
                        15,
                        color: const Color(0xFF0F172A),
                        weight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(Icons.location_on, color: _blue, size: 14),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            lead.city,
                            style: accountText(11, weight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                    if (lead.postedAt != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.schedule,
                              color: Color(0xFF94A3B8),
                              size: 13,
                            ),
                            const SizedBox(width: 5),
                            Expanded(
                              child: Text(
                                _posted(),
                                style: accountText(
                                  11,
                                  color: _muted,
                                  weight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (clientDetails != null)
                      Container(
                        margin: const EdgeInsets.only(top: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFECFDF5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.check,
                              size: 13,
                              color: Color(0xFF10B981),
                            ),
                            const SizedBox(width: 5),
                            Flexible(
                              child: Text(
                                'Unlocked',
                                style: accountText(
                                  11,
                                  color: const Color(0xFF10B981),
                                  weight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.only(top: 20, bottom: 12),
            child: Divider(height: 1, color: Color(0xFFF1F5F9)),
          ),
          _stats(),
        ],
      ),
    ),
  );
}
