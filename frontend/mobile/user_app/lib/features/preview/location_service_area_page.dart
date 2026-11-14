import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'business_details_page.dart' show AccountPageHeader, accountText;
import 'preview_data.dart';
import 'profile_design.dart' show profileBackground;

const _blue = Color(0xFF0066FF), _navy = Color(0xFF072565);
const _ranges = [
  (10, 'Nearby projects only', 'nearby'),
  (25, 'Recommended for most vendors', 'radius'),
  (50, 'More opportunities across the city', 'city'),
];
Widget _svg(String name, double size) => SvgPicture.asset(
  'assets/figma/location-$name.svg',
  width: size,
  height: size,
);

class LocationServiceAreaPage extends StatefulWidget {
  final PreviewStore store;
  const LocationServiceAreaPage({super.key, required this.store});
  @override
  State<LocationServiceAreaPage> createState() =>
      _LocationServiceAreaPageState();
}

class _LocationServiceAreaPageState extends State<LocationServiceAreaPage> {
  final form = GlobalKey<FormState>(), area = TextEditingController();
  late String city = widget.store.profile['City'] ?? '';
  late int radius = widget.store.serviceRadiusKm;
  late final areas = List<String>.of(widget.store.additionalAreas);
  bool saving = false;

  @override
  void dispose() {
    area.dispose();
    super.dispose();
  }

  void addArea() {
    final value = area.text.trim();
    if (value.isEmpty || saving) return;
    setState(() {
      if (!areas.any((name) => name.toLowerCase() == value.toLowerCase())) {
        areas.add(value);
      }
      area.clear();
    });
  }

  Future<void> save() async {
    if (saving || !form.currentState!.validate()) return;
    addArea();
    setState(() => saving = true);
    try {
      await widget.store.saveLocation(city, radius, areas);
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      Navigator.pop(context);
      messenger.showSnackBar(
        const SnackBar(content: Text('Location and service area saved')),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not save your location. Please retry.'),
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
            key: form,
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AccountPageHeader(store: widget.store),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(23, 17, 23, 26),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Location & Service Area',
                          style: accountText(
                            24,
                            color: const Color(0xFF0F172A),
                            weight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Choose where you want to receive\nrelevant leads.',
                          style: accountText(
                            14,
                            color: const Color(0xFF9498A1),
                            weight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        DecoratedBox(
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFE57E),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFE0ECFC)),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Row(
                              children: [
                                _svg('banner', 48),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Set your preferred city and service',
                                        style: accountText(
                                          13,
                                          color: const Color(0xFF0F172A),
                                          weight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        'to find nearby projects.',
                                        style: accountText(
                                          12,
                                          weight: FontWeight.w400,
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
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: _navy,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(15, 16, 15, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _label('Primary city'),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            key: const ValueKey('Primary city'),
                            initialValue: city.isEmpty ? null : city,
                            isExpanded: true,
                            icon: const Icon(
                              Icons.keyboard_arrow_down,
                              size: 20,
                              color: Color(0xFF334155),
                            ),
                            style: accountText(14, weight: FontWeight.w600),
                            dropdownColor: Colors.white,
                            decoration: _decoration(
                              'Select your city',
                              Icons.location_on_outlined,
                            ),
                            items: {if (city.isNotEmpty) city, ...widget.store.cities}
                                .map(
                                  (name) => DropdownMenuItem(
                                    value: name,
                                    child: Text(
                                      name == widget.store.profile['City'] &&
                                              (widget.store.profile['State'] ??
                                                      '')
                                                  .isNotEmpty
                                          ? '$name, ${widget.store.profile['State']}'
                                          : name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: saving
                                ? null
                                : (value) => setState(() => city = value!),
                            validator: (value) => value == null || value.isEmpty
                                ? 'Choose your primary city'
                                : null,
                          ),
                          const SizedBox(height: 20),
                          _label('Service area'),
                          const SizedBox(height: 3),
                          Text(
                            "Choose how far you're willing to travel.",
                            style: accountText(
                              12,
                              color: const Color(0xFF64748B),
                              weight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 12),
                          for (final range in _ranges) ...[
                            _range(range),
                            if (range != _ranges.last)
                              const SizedBox(height: 11),
                          ],
                          const SizedBox(height: 20),
                          _label('Additional areas', optional: true),
                          const SizedBox(height: 12),
                          TextField(
                            key: const ValueKey('Additional areas'),
                            controller: area,
                            enabled: !saving,
                            maxLength: 100,
                            textInputAction: TextInputAction.done,
                            style: accountText(13),
                            onSubmitted: (_) => addArea(),
                            onChanged: (_) => setState(() {}),
                            decoration:
                                _decoration(
                                  'Search city or locality',
                                  Icons.search,
                                ).copyWith(
                                  counterText: '',
                                  suffixIcon: area.text.trim().isEmpty
                                      ? null
                                      : IconButton(
                                          tooltip: 'Add area',
                                          onPressed: addArea,
                                          icon: const Icon(
                                            Icons.add,
                                            color: _blue,
                                          ),
                                        ),
                                ),
                          ),
                          if (areas.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 14),
                              child: Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: areas
                                    .map(
                                      (name) => ActionChip(
                                        label: Text(name),
                                        tooltip: 'Remove $name',
                                        onPressed: saving
                                            ? null
                                            : () => setState(
                                                () => areas.remove(name),
                                              ),
                                        backgroundColor: const Color(
                                          0xFFE6F0FF,
                                        ),
                                        side: const BorderSide(
                                          color: Color(0xFFBFDBFE),
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        labelStyle: accountText(
                                          12,
                                          weight: FontWeight.w600,
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                        ),
                                        visualDensity: VisualDensity.compact,
                                        materialTapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                      ),
                                    )
                                    .toList(),
                              ),
                            ),
                          const SizedBox(height: 20),
                          _MapPreview(radius: radius),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(23, 32, 22, 32),
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
                              : const Text('Save Location & Area'),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                          child: OutlinedButton(
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
                              textStyle: accountText(
                                14,
                                weight: FontWeight.w700,
                              ),
                            ),
                            child: const Text('Cancel'),
                          ),
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

  Widget _label(String label, {bool optional = false}) => Text.rich(
    TextSpan(
      children: [
        TextSpan(text: label),
        TextSpan(
          text: optional ? '(optional)' : ' *',
          style: TextStyle(
            color: optional ? const Color(0xFFA6B6CC) : const Color(0xFFEF4444),
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    ),
    style: accountText(14, color: Colors.white, weight: FontWeight.w700),
  );

  InputDecoration _decoration(String hint, IconData icon) => InputDecoration(
    hintText: hint,
    hintStyle: accountText(
      13,
      color: const Color(0xFF94A3B8),
      weight: FontWeight.w600,
    ),
    prefixIcon: Icon(icon, size: 20, color: const Color(0xFF475569)),
    prefixIconConstraints: const BoxConstraints(minWidth: 44),
    filled: true,
    fillColor: Colors.white,
    isDense: true,
    contentPadding: const EdgeInsets.fromLTRB(0, 12, 12, 12),
    errorStyle: accountText(11, color: const Color(0xFFFFC7C7)),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
    ),
  );

  Widget _range((int, String, String) range) {
    final chosen = radius == range.$1;
    return Semantics(
      checked: chosen,
      inMutuallyExclusiveGroup: true,
      label: 'Within ${range.$1} km',
      child: Material(
        color: chosen ? const Color(0xFFF0F7FF) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: chosen ? _blue : const Color(0xFFE2E8F0),
            width: chosen ? 2 : 1,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: saving ? null : () => setState(() => radius = range.$1),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: chosen ? _blue : Colors.white,
                      border: Border.all(
                        color: chosen ? _blue : const Color(0xFF94A3B8),
                        width: 2,
                      ),
                    ),
                    child: chosen
                        ? const Center(
                            child: SizedBox(
                              width: 8,
                              height: 8,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          )
                        : null,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Within ${range.$1} km',
                        style: accountText(14, weight: FontWeight.w700),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        range.$2,
                        style: accountText(12, color: const Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _svg(range.$3, 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MapPreview extends StatelessWidget {
  final int radius;
  const _MapPreview({required this.radius});
  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Illustrative map preview, not a live location',
    child: ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: AspectRatio(
        aspectRatio: 363 / 220,
        child: LayoutBuilder(
          builder: (context, bounds) => Stack(
            fit: StackFit.expand,
            children: [
              SvgPicture.asset(
                'assets/figma/location-map-preview.svg',
                fit: BoxFit.cover,
              ),
              Positioned(top: 8, left: 8, child: _badge('Map preview')),
              Positioned(
                left: bounds.maxWidth * 163 / 363,
                top: bounds.maxHeight * 123 / 220,
                child: _badge('$radius km service radius'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
  Widget _badge(String label) => DecoratedBox(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(15),
      border: Border.all(color: const Color(0xFFBFDBFE)),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
      child: Text(label, style: accountText(9, weight: FontWeight.w700)),
    ),
  );
}
