import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'business_details_page.dart' show AccountPageHeader, accountText;
import 'preview_data.dart';
import 'profile_design.dart' show profileBackground;

const _blue = Color(0xFF0066FF), _navy = Color(0xFF072565);
const _categories = [
  ('interior', 'Interior Design'),
  ('painting', 'Painting'),
  ('civil', 'Civil Work'),
  ('plumbing', 'Plumbing'),
  ('electrical', 'Electrical'),
  ('ceiling', 'False Ceiling'),
  ('waterproofing', 'Waterproofing'),
  ('cctv', 'CCTV Installation'),
  ('windows', 'Aluminium & Windows'),
  ('ac', 'AC Repair'),
  ('kitchen', 'Modular Kitchen'),
  ('carpentry', 'Carpentry'),
];
String _kind(String name) {
  final value = name.toLowerCase().replaceAll(' ', '');
  if (value.contains('paint')) return 'painting';
  if (value.contains('renovation')) return 'civil';
  if (value.contains('window') || value.contains('aluminium')) return 'windows';
  if (value.startsWith('ac') || value.contains('aircondition')) return 'ac';
  return _categories
          .where((c) => c.$1 != 'ac' && value.contains(c.$1))
          .firstOrNull
          ?.$1 ??
      '';
}

Widget _svg(String name, {double size = 16, Color? color}) => SvgPicture.asset(
  'assets/figma/service-$name.svg',
  width: size,
  height: size,
  colorFilter: color == null ? null : ColorFilter.mode(color, BlendMode.srcIn),
);

class ServiceCategoriesPage extends StatefulWidget {
  final PreviewStore store;
  const ServiceCategoriesPage({super.key, required this.store});
  @override
  State<ServiceCategoriesPage> createState() => _ServiceCategoriesPageState();
}

class _ServiceCategoriesPageState extends State<ServiceCategoriesPage> {
  late final selected = Set<String>.of(widget.store.serviceCategories);
  String query = '';
  bool saving = false;

  Future<void> save() async {
    if (saving) return;
    if (selected.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select at least one category.')),
      );
      return;
    }
    setState(() => saving = true);
    try {
      await widget.store.saveServiceCategories(selected);
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      Navigator.pop(context);
      messenger.showSnackBar(
        const SnackBar(content: Text('Service categories saved')),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not save categories. Please retry.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final available = widget.store.isLive
        ? widget.store.categories.map((c) => c.name).toList()
        : _categories.map((c) => c.$2).toList();
    final matches = available
        .where(
          (name) =>
              !selected.contains(name) &&
              name.toLowerCase().contains(query.toLowerCase()),
        )
        .toList();
    return Scaffold(
      backgroundColor: profileBackground,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AccountPageHeader(store: widget.store),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(23, 17, 23, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Service Categories',
                          style: accountText(
                            24,
                            color: const Color(0xFF091E42),
                            weight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Choose the services you offer to get\nrelevant leads.',
                          style: accountText(
                            14,
                            color: const Color(0xFF9498A1),
                            weight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 7),
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
                                _svg('banner', size: 48),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Text(
                                    'Select all categories that match your work.',
                                    style: accountText(
                                      13,
                                      color: const Color(0xFF0F172A),
                                      weight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                        Text(
                          'Your selected categories (${selected.length})',
                          style: accountText(
                            14,
                            color: const Color(0xFF091A36),
                            weight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 10),
                        _tiles(selected.toList(), chosen: true),
                      ],
                    ),
                  ),
                  const SizedBox(height: 15),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: _navy,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Explore categories',
                            style: accountText(
                              14,
                              color: Colors.white,
                              weight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 11),
                          TextField(
                            onChanged: (value) => setState(() => query = value),
                            style: accountText(12),
                            decoration: InputDecoration(
                              hintText: 'Search Services Categories',
                              hintStyle: accountText(
                                10,
                                color: const Color(0xFF94A3B8),
                                weight: FontWeight.w400,
                              ),
                              prefixIcon: const Icon(
                                Icons.search,
                                size: 20,
                                color: Color(0xFF94A3B8),
                              ),
                              prefixIconConstraints: const BoxConstraints(
                                minWidth: 36,
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 8,
                                horizontal: 12,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(24),
                                borderSide: const BorderSide(
                                  color: Color(0xFFE2E8F0),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          if (matches.isEmpty)
                            Padding(
                              padding: const EdgeInsets.all(12),
                              child: Text(
                                query.isEmpty
                                    ? available.isEmpty
                                          ? 'No service categories available.'
                                          : 'All available categories selected.'
                                    : 'No matching categories.',
                                style: accountText(12, color: Colors.white),
                              ),
                            )
                          else
                            _tiles(matches),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(23, 24, 22, 29),
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
                              : const Text('Save Categories'),
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
    );
  }

  Widget _tiles(List<String> names, {bool chosen = false}) => LayoutBuilder(
    builder: (context, bounds) {
      final single = MediaQuery.textScalerOf(context).scale(12) > 15;
      return Wrap(
        spacing: 10,
        runSpacing: 10,
        children: names.map((name) {
          final kind = _kind(name);
          final label =
              _categories.where((c) => c.$1 == kind).firstOrNull?.$2 ?? name;
          return SizedBox(
            width: single ? bounds.maxWidth : (bounds.maxWidth - 10) / 2,
            child: Semantics(
              button: true,
              selected: chosen,
              label: name,
              child: Material(
                color: chosen ? const Color(0xFFF0F6FF) : Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: chosen ? _blue : const Color(0xFFE2E8F0),
                  ),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: saving
                      ? null
                      : () => setState(() {
                          chosen ? selected.remove(name) : selected.add(name);
                        }),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 38),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 9,
                      ),
                      child: Row(
                        children: [
                          if (kind.isNotEmpty)
                            _svg(
                              kind,
                              color: chosen
                                  ? const Color(0xFF0F203D)
                                  : Colors.white,
                            )
                          else
                            const Icon(
                              Icons.category_outlined,
                              size: 16,
                              color: Colors.white,
                            ),
                          const SizedBox(width: 7),
                          Expanded(
                            child: Text(
                              label,
                              maxLines: single ? null : 1,
                              overflow: single ? null : TextOverflow.ellipsis,
                              style: accountText(
                                12,
                                color: chosen
                                    ? const Color(0xFF0F203D)
                                    : Colors.white,
                                weight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          if (chosen)
                            _svg('check')
                          else
                            const SizedBox(
                              width: 16,
                              height: 16,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  border: Border.fromBorderSide(
                                    BorderSide(color: _blue),
                                  ),
                                ),
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
        }).toList(),
      );
    },
  );
}
