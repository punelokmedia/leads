import 'package:flutter/material.dart';

import 'preview_data.dart';

class EditProfilePreview extends StatefulWidget {
  final PreviewStore store;
  const EditProfilePreview({super.key, required this.store});

  @override
  State<EditProfilePreview> createState() => _EditProfilePreviewState();
}

class _EditProfilePreviewState extends State<EditProfilePreview> {
  static const _blue = Color(0xFF0047FF);
  static const _navy = Color(0xFF0A2342);
  static const _muted = Color(0xFF475569);
  final formKey = GlobalKey<FormState>();
  late final business = TextEditingController(
    text: widget.store.profile['Business name'],
  );
  late final gst = TextEditingController();
  late final address = TextEditingController(
    text: widget.store.profile['State'],
  );
  late final city = TextEditingController(text: widget.store.profile['City']);
  late final serviceArea = TextEditingController(
    text: widget.store.profile['City']?.isEmpty == false
        ? '${widget.store.profile['City']} and nearby areas'
        : '',
  );
  late final website = TextEditingController();
  String businessType = 'Sole proprietorship';
  String experience = '';
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
    if (!formKey.currentState!.validate() || saving) return;
    setState(() => saving = true);
    try {
      await widget.store.saveProfile({
        ...widget.store.profile,
        'Business name': business.text.trim(),
        'City': city.text.trim(),
        'State': address.text.trim(),
      });
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Business details saved')));
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
    backgroundColor: const Color(0xFFF9FBFF),
    body: SafeArea(
      child: Form(
        key: formKey,
        child: Stack(
          children: [
            ListView(
              padding: const EdgeInsets.fromLTRB(16, 7, 16, 142),
              children: [
                Row(
                  children: [
                    IconButton(
                      tooltip: 'Back',
                      onPressed: () => Navigator.maybePop(context),
                      icon: const Icon(Icons.arrow_back, color: _navy),
                    ),
                    Image.asset(
                      'assets/branding/nextlead_wordmark.webp',
                      width: 150,
                      height: 48,
                    ),
                    const Spacer(),
                    const Icon(Icons.notifications_outlined, color: _navy),
                  ],
                ),
                const SizedBox(height: 15),
                const Text(
                  'Business Details',
                  style: TextStyle(
                    color: _navy,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Manage your company information.',
                  style: TextStyle(color: _muted, fontSize: 14),
                ),
                const SizedBox(height: 20),
                _infoBanner(),
                const SizedBox(height: 24),
                _label('Business / Company Name'),
                _field(
                  business,
                  'Enter your business name',
                  Icons.business_outlined,
                  required: true,
                ),
                _label('Business Type'),
                _dropdown(
                  value: businessType,
                  items: const [
                    'Sole proprietorship',
                    'Partnership',
                    'Private limited',
                    'Other',
                  ],
                  icon: Icons.business_center_outlined,
                  onChanged: (value) => setState(() => businessType = value!),
                ),
                _label('GST Number', optional: true),
                _field(gst, 'Enter GSTIN', Icons.article_outlined),
                const Padding(
                  padding: EdgeInsets.only(top: 5, bottom: 18),
                  child: Text(
                    'ⓘ  Optional — add if applicable.',
                    style: TextStyle(color: _muted, fontSize: 12),
                  ),
                ),
                _label('Business Address'),
                _field(
                  address,
                  'Enter complete business address',
                  Icons.location_on_outlined,
                  required: true,
                ),
                _label('City'),
                _field(
                  city,
                  'Enter your city',
                  Icons.location_on_outlined,
                  required: true,
                ),
                _label('Service Area'),
                _field(
                  serviceArea,
                  'Your service area',
                  Icons.map_outlined,
                  required: true,
                ),
                _label('Years in Business'),
                _dropdown(
                  value: experience.isEmpty ? null : experience,
                  hint: 'Select experience',
                  items: const [
                    'Less than 1 year',
                    '1–3 years',
                    '3–5 years',
                    '5+ years',
                  ],
                  icon: Icons.calendar_month_outlined,
                  onChanged: (value) => setState(() => experience = value!),
                  required: true,
                ),
                _label('Website', optional: true),
                _field(
                  website,
                  'https://yourwebsite.com',
                  Icons.link_rounded,
                  keyboardType: TextInputType.url,
                ),
              ],
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: SafeArea(
                top: false,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
                  color: Colors.white,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: double.infinity,
                        height: 51,
                        child: FilledButton(
                          onPressed: saving ? null : save,
                          style: FilledButton.styleFrom(backgroundColor: _blue),
                          child: saving
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  'Save Changes',
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                        ),
                      ),
                      TextButton(
                        onPressed: saving
                            ? null
                            : () => Navigator.maybePop(context),
                        child: const Text('Cancel'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _infoBanner() => Container(
    padding: const EdgeInsets.all(17),
    decoration: BoxDecoration(
      color: const Color(0xFFEAF3FF),
      borderRadius: BorderRadius.circular(13),
    ),
    child: const Row(
      children: [
        CircleAvatar(
          backgroundColor: Color(0xFFD8E9FF),
          child: Icon(Icons.business_outlined, color: _blue),
        ),
        SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Keep your business details updated',
                style: TextStyle(
                  color: _navy,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 3),
              Text(
                'to build trust with customers.',
                style: TextStyle(color: _muted, fontSize: 13),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _label(String label, {bool optional = false}) => Padding(
    padding: const EdgeInsets.only(bottom: 7, top: 17),
    child: RichText(
      text: TextSpan(
        style: const TextStyle(
          color: _navy,
          fontSize: 15,
          fontWeight: FontWeight.w700,
        ),
        children: [
          TextSpan(text: label),
          TextSpan(
            text: optional ? '  (Optional)' : '  *',
            style: TextStyle(
              color: optional ? _muted : Colors.red,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    ),
  );

  InputDecoration _decoration(String hint, IconData icon) => InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: _muted, fontSize: 14),
    prefixIcon: Icon(icon, color: _muted),
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(vertical: 15),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(9),
      borderSide: const BorderSide(color: Color(0xFFD4DFEF)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(9),
      borderSide: const BorderSide(color: Color(0xFFD4DFEF)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(9),
      borderSide: const BorderSide(color: _blue, width: 1.5),
    ),
  );

  Widget _field(
    TextEditingController controller,
    String hint,
    IconData icon, {
    bool required = false,
    TextInputType keyboardType = TextInputType.text,
  }) => TextFormField(
    controller: controller,
    keyboardType: keyboardType,
    style: const TextStyle(color: _navy, fontSize: 14),
    decoration: _decoration(hint, icon),
    validator: required
        ? (value) => value == null || value.trim().isEmpty
              ? 'This field is required'
              : null
        : null,
  );

  Widget _dropdown({
    String? value,
    required List<String> items,
    required IconData icon,
    required ValueChanged<String?> onChanged,
    String? hint,
    bool required = false,
  }) => DropdownButtonFormField<String>(
    initialValue: value,
    isExpanded: true,
    decoration: _decoration(hint ?? '', icon),
    hint: hint == null
        ? null
        : Text(hint, style: const TextStyle(color: _muted, fontSize: 14)),
    style: const TextStyle(color: _navy, fontSize: 14),
    items: items
        .map((item) => DropdownMenuItem(value: item, child: Text(item)))
        .toList(),
    onChanged: onChanged,
    validator: required
        ? (value) =>
              value == null || value.isEmpty ? 'This field is required' : null
        : null,
  );
}
