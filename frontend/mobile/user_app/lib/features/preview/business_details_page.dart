import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../payments/presentation/widgets/wallet_card.dart';
import 'preview_data.dart';
import 'preview_app.dart' show NotificationsPreview;
import 'profile_design.dart' show profileBackground;

const _blue = Color(0xFF0066FF),
    _navy = Color(0xFF072565),
    _ink = Color(0xFF1E293B),
    _muted = Color(0xFF94A3B8);
TextStyle accountText(
  double size, {
  Color color = _ink,
  FontWeight weight = FontWeight.w500,
}) => TextStyle(
  fontFamily: 'ProfileMontserrat',
  fontSize: size,
  height: 1.3,
  color: color,
  fontWeight: weight,
);
Widget _icon(String name, {double size = 20}) => SvgPicture.asset(
  'assets/figma/business-$name.svg',
  width: size,
  height: size,
);

class EditProfilePreview extends ConsumerStatefulWidget {
  final PreviewStore store;
  final VoidCallback? onWallet;
  const EditProfilePreview({super.key, required this.store, this.onWallet});
  @override
  ConsumerState<EditProfilePreview> createState() => _EditProfilePreviewState();
}

class _EditProfilePreviewState extends ConsumerState<EditProfilePreview> {
  final formKey = GlobalKey<FormState>();
  late final business = TextEditingController(
    text: widget.store.profile['Business name'],
  );
  late final gst = TextEditingController(
    text: widget.store.profile['GST number'],
  );
  late final address = TextEditingController(
    text: widget.store.profile['Business address'],
  );
  late final city = TextEditingController(text: widget.store.profile['City']);
  late final serviceArea = TextEditingController(
    text:
        widget.store.profile['Service area'] ??
        (widget.store.profile['City']?.isNotEmpty == true
            ? '${widget.store.profile['City']} and nearby areas'
            : ''),
  );
  late final website = TextEditingController(
    text: widget.store.profile['Website'],
  );
  late String businessType =
      widget.store.profile['Business type']?.isNotEmpty == true
      ? widget.store.profile['Business type']!
      : 'Sole proprietorship';
  late String experience = widget.store.profile['Years in business'] ?? '';
  bool saving = false;

  @override
  void dispose() {
    for (final controller in [
      business,
      gst,
      address,
      city,
      serviceArea,
      website,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> save() async {
    if (saving || !formKey.currentState!.validate()) return;
    setState(() => saving = true);
    try {
      await widget.store.saveProfile({
        ...widget.store.profile,
        'Business name': business.text.trim(),
        'Business type': businessType,
        'GST number': gst.text.trim().toUpperCase(),
        'Business address': address.text.trim(),
        'City': city.text.trim(),
        'Service area': serviceArea.text.trim(),
        'Years in business': experience,
        'Website': website.text.trim(),
      });
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      Navigator.pop(context);
      messenger.showSnackBar(
        const SnackBar(content: Text('Business details saved')),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not save business details. Please retry.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: profileBackground,
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AccountPageHeader(
                    store: widget.store,
                    onWallet: widget.onWallet,
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(23, 17, 23, 22),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Business Details',
                          style: accountText(
                            24,
                            color: const Color(0xFF091E42),
                            weight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Manage your company information.',
                          style: accountText(
                            14,
                            color: const Color(0xFF9498A1),
                            weight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 23),
                    child: _banner(),
                  ),
                  Container(
                    margin: const EdgeInsets.fromLTRB(23, 22, 22, 0),
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
                    decoration: BoxDecoration(
                      color: _navy,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _label('Business / Company Name'),
                        _field(
                          'Business name',
                          business,
                          'Enter your business name',
                          'building',
                        ),
                        const SizedBox(height: 14),
                        _label('Business Type'),
                        _dropdown(
                          'Business type',
                          businessType,
                          const [
                            'Sole proprietorship',
                            'Partnership',
                            'Private limited',
                            'Other',
                          ],
                          'briefcase',
                          (v) => setState(() => businessType = v!),
                          iconSize: 17,
                        ),
                        const SizedBox(height: 14),
                        _label('GST Number', optional: true),
                        _field(
                          'GST number',
                          gst,
                          'Enter GSTIN',
                          'tax',
                          optional: true,
                          capitalization: TextCapitalization.characters,
                          validator: (value) =>
                              value!.trim().isNotEmpty &&
                                  !RegExp(
                                    r'^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z][1-9A-Z]Z[0-9A-Z]$',
                                  ).hasMatch(value.trim().toUpperCase())
                              ? 'Enter a valid 15-character GSTIN'
                              : null,
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(8, 7, 0, 14),
                          child: Text(
                            'Optional — add if applicable.',
                            style: accountText(
                              12,
                              color: const Color(0xFF64748B),
                              weight: FontWeight.w400,
                            ),
                          ),
                        ),
                        _label('Business Address'),
                        _field(
                          'Business address',
                          address,
                          'Enter complete business address',
                          'pin',
                          lines: 2,
                        ),
                        const SizedBox(height: 14),
                        _label('City'),
                        _field(
                          'City',
                          city,
                          'Select your city',
                          'pin',
                          suggestions: widget.store.cities,
                        ),
                        const SizedBox(height: 14),
                        _label('Service Area'),
                        _field(
                          'Service area',
                          serviceArea,
                          'Your service area',
                          'map',
                          suggestions: widget.store.cities
                              .map((city) => '$city and nearby areas')
                              .toList(),
                        ),
                        const SizedBox(height: 14),
                        _label('Years in Business'),
                        _dropdown(
                          'Years in business',
                          experience.isEmpty ? null : experience,
                          const [
                            'Less than 1 year',
                            '1–3 years',
                            '3–5 years',
                            '5+ years',
                          ],
                          'calendar',
                          (v) => setState(() => experience = v!),
                          hint: 'Select experience',
                        ),
                        const SizedBox(height: 14),
                        _label('Website', optional: true),
                        _field(
                          'Website',
                          website,
                          'https://yourwebsite.com',
                          'link',
                          optional: true,
                          keyboardType: TextInputType.url,
                          validator: (value) {
                            if (value!.trim().isEmpty) return null;
                            final uri = Uri.tryParse(value.trim());
                            return uri != null &&
                                    ['http', 'https'].contains(uri.scheme) &&
                                    uri.host.contains('.')
                                ? null
                                : 'Enter a full http or https website address';
                          },
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(39, 29, 38, 25),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        FilledButton(
                          onPressed: saving ? null : save,
                          style: FilledButton.styleFrom(
                            backgroundColor: _blue,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(0, 51),
                            shape: const StadiumBorder(),
                            textStyle: accountText(
                              15,
                              color: Colors.white,
                              weight: FontWeight.w700,
                            ),
                          ),
                          child: saving
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('Save Changes'),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton(
                          onPressed: saving
                              ? null
                              : () => Navigator.maybePop(context),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFFEF4444),
                            minimumSize: const Size(0, 29),
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            side: const BorderSide(color: Color(0xFFEF4444)),
                            shape: const StadiumBorder(),
                            textStyle: accountText(14, weight: FontWeight.w700),
                          ),
                          child: const Text('Cancel'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );

  Widget _banner() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    decoration: BoxDecoration(
      color: const Color(0xFFFFE57E),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFE0ECFC)),
    ),
    child: Row(
      children: [
        _icon('banner', size: 48),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Keep your business details updated',
                style: accountText(
                  13,
                  color: const Color(0xFF0F172A),
                  weight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                'to build trust with customers.',
                style: accountText(12, weight: FontWeight.w400),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _label(String label, {bool optional = false}) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text.rich(
      TextSpan(
        children: [
          TextSpan(text: label),
          TextSpan(
            text: optional ? '(Optional)' : ' *',
            style: TextStyle(
              color: optional ? _muted : const Color(0xFFEF4444),
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
      style: accountText(13, color: Colors.white, weight: FontWeight.w700),
    ),
  );

  InputDecoration _decoration(
    String hint,
    String icon, {
    double iconSize = 20,
    Widget? suffix,
  }) => InputDecoration(
    hintText: hint,
    hintStyle: accountText(13, color: _muted, weight: FontWeight.w400),
    prefixIcon: Padding(
      padding: const EdgeInsets.all(12),
      child: _icon(icon, size: iconSize),
    ),
    prefixIconConstraints: const BoxConstraints(minWidth: 44, maxWidth: 44),
    suffixIcon: suffix,
    suffixIconConstraints: const BoxConstraints(minWidth: 40, maxWidth: 40),
    filled: true,
    fillColor: Colors.white,
    isDense: true,
    contentPadding: const EdgeInsets.fromLTRB(0, 15, 12, 15),
    errorStyle: accountText(11, color: const Color(0xFFFFC7C7)),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: _blue, width: 1.5),
    ),
  );

  Widget _field(
    String label,
    TextEditingController controller,
    String hint,
    String icon, {
    bool optional = false,
    int lines = 1,
    List<String>? suggestions,
    TextInputType keyboardType = TextInputType.text,
    TextCapitalization capitalization = TextCapitalization.none,
    String? Function(String?)? validator,
  }) => TextFormField(
    key: ValueKey(label),
    controller: controller,
    minLines: lines,
    maxLines: lines,
    enabled: !saving,
    keyboardType: keyboardType,
    textCapitalization: capitalization,
    style: accountText(13),
    decoration: _decoration(
      hint,
      icon,
      suffix: suggestions == null
          ? null
          : PopupMenuButton<String>(
              tooltip: 'Choose $label',
              enabled: !saving && suggestions.isNotEmpty,
              onSelected: (value) => controller.text = value,
              itemBuilder: (_) => suggestions
                  .toSet()
                  .map(
                    (value) => PopupMenuItem(value: value, child: Text(value)),
                  )
                  .toList(),
              icon: _icon('chevron', size: 16),
            ),
    ),
    validator: (value) => !optional && (value == null || value.trim().isEmpty)
        ? 'This field is required'
        : validator?.call(value),
  );

  Widget _dropdown(
    String label,
    String? value,
    List<String> items,
    String icon,
    ValueChanged<String?> onChanged, {
    String? hint,
    double iconSize = 20,
  }) => DropdownButtonFormField<String>(
    key: ValueKey(label),
    initialValue: value,
    isExpanded: true,
    style: accountText(13),
    dropdownColor: Colors.white,
    decoration: _decoration(
      hint ?? '',
      icon,
      iconSize: iconSize,
    ).copyWith(contentPadding: const EdgeInsets.fromLTRB(0, 10, 12, 10)),
    icon: Padding(
      padding: const EdgeInsets.only(right: 3),
      child: _icon('chevron', size: 16),
    ),
    hint: hint == null
        ? null
        : Text(
            hint,
            style: accountText(13, color: _muted, weight: FontWeight.w400),
          ),
    items: {...items, ?value}
        .map(
          (item) => DropdownMenuItem(
            value: item,
            child: Text(item, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
        )
        .toList(),
    onChanged: saving ? null : onChanged,
    validator: (value) =>
        value == null || value.isEmpty ? 'This field is required' : null,
  );
}

class AccountPageHeader extends ConsumerWidget {
  final PreviewStore store;
  final bool showBack;
  final VoidCallback? onWallet, onBack, onNotifications;
  const AccountPageHeader({
    super.key,
    required this.store,
    this.onWallet,
    this.onBack,
    this.onNotifications,
    this.showBack = true,
  });
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balance = store.isLive
        ? ref
              .watch(walletProvider)
              .when(
                data: (data) =>
                    '₹${((data['balancePaise'] as num? ?? 0) / 100).toStringAsFixed(0)}',
                loading: () => '…',
                error: (_, _) => 'Wallet',
              )
        : '₹500';
    return Container(
      height: showBack ? 64 : 76,
      decoration: BoxDecoration(
        border: showBack
            ? const Border(bottom: BorderSide(color: Color(0x4294A3B8)))
            : null,
      ),
      padding: showBack
          ? const EdgeInsets.symmetric(horizontal: 15)
          : const EdgeInsets.fromLTRB(39, 0, 31, 0),
      child: Row(
        children: [
          if (showBack)
            IconButton(
              tooltip: 'Back',
              onPressed: onBack ?? () => Navigator.maybePop(context),
              icon: _icon('back', size: 24),
            ),
          if (showBack) const SizedBox(width: 22),
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: InkWell(
                onTap: showBack ? null : onBack,
                child: Image.asset(
                  'assets/figma/profile-logo.png',
                  width: 129.75,
                  height: 43.35,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Material(
            color: const Color(0xFFFAFAFA),
            elevation: 2,
            shape: const StadiumBorder(
              side: BorderSide(color: Color(0xFFE2E8F0)),
            ),
            child: InkWell(
              customBorder: const StadiumBorder(),
              onTap:
                  onWallet ??
                  () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => Scaffold(
                        appBar: AppBar(title: const Text('Wallet')),
                        body: WalletCard(onBack: () => Navigator.pop(context)),
                      ),
                    ),
                  ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 7,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SvgPicture.asset(
                      'assets/figma/profile-wallet.svg',
                      width: 24,
                      height: 22,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      balance,
                      style: accountText(10, weight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
          ),
          IconButton(
            tooltip: 'Notifications',
            onPressed:
                onNotifications ??
                () {
                  store.markRead();
                  Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => NotificationsPreview(store: store),
                    ),
                  );
                },
            icon: SvgPicture.asset(
              'assets/figma/profile-bell.svg',
              width: 24,
              height: 26,
            ),
          ),
        ],
      ),
    );
  }
}
