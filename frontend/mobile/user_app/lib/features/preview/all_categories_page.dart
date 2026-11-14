import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../app/app_router.dart';
import 'category_leads_page.dart';
import 'figma_widgets.dart';
import 'preview_data.dart';

class CategoryPreview extends StatefulWidget {
  final PreviewStore store;
  final ValueChanged<int?> onSelect;
  const CategoryPreview({
    super.key,
    required this.store,
    required this.onSelect,
  });
  @override
  State<CategoryPreview> createState() => _CategoryPreviewState();
}

class _CategoryPreviewState extends State<CategoryPreview> {
  String query = '';
  String? _art(String name) {
    final n = name.toLowerCase();
    if (n.contains('interior')) return '750-2861-imgGroup15';
    if (n.contains('paint')) return '750-2861-imgVector2';
    if (n.contains('plumb')) return '750-2861-imgVector3';
    if (n.contains('ceiling') || n.contains('pop')) return '750-2861-imgLayer1';
    if (n.contains('electric')) return '750-2861-imgLayer7';
    if (n.contains('ac service')) return '750-2861-imgLayer6';
    if (n.replaceAll(' ', '').contains('waterproof')) {
      return '750-2861-imgLayer2';
    }
    if (n.contains('civil') || n.contains('construction')) {
      return '750-2861-imgLayer3';
    }
    if (n.contains('aluminium') || n.contains('window')) {
      return '750-2861-imgLayer4';
    }
    if (n.contains('cctv')) return '750-2861-imgLayer5';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final shown = List.generate(widget.store.categories.length, (i) => i)
        .where(
          (i) => widget.store.categories[i].name.toLowerCase().contains(
            query.toLowerCase(),
          ),
        )
        .toList();
    // Match the category order in the design; retain extra backend categories below it.
    const order = [
      'interior',
      'paint',
      'plumb',
      'ceiling',
      'electric',
      'ac service',
      'waterproof',
      'civil',
      'aluminium',
      'cctv',
    ];
    int rank(int i) {
      final n = widget.store.categories[i].name.toLowerCase();
      final r = order.indexWhere(n.contains);
      return r < 0 ? order.length : r;
    }

    shown.sort((a, b) => rank(a).compareTo(rank(b)));
    return Scaffold(
      backgroundColor: figmaBackground,
      bottomNavigationBar: FigmaBottomNav(
        selected: -1,
        onSelect: (i) {
          final router = GoRouter.maybeOf(context);
          if (router != null) {
            Navigator.pop(context);
            router.go(
              [
                AppRouter.homePath,
                AppRouter.leadsPath,
                AppRouter.cartPath,
                AppRouter.membershipPath,
                AppRouter.profilePath,
              ][i],
            );
          } else {
            Navigator.pop(context);
            if (i == 1) widget.onSelect(null);
          }
        },
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton(
                  tooltip: 'Back',
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back, color: figmaInk),
                ),
                Image.asset(
                  'assets/figma/home-imgNextLeadRibbonArrowLogo3.png',
                  width: 130,
                  height: 43,
                  fit: BoxFit.cover,
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'All Categories',
                    style: TextStyle(
                      color: figmaInk,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    'Find leads from various service categories\nand grow your business.',
                    style: TextStyle(
                      color: figmaMuted,
                      fontSize: 14,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 18),
                  TextField(
                    onChanged: (v) => setState(() => query = v),
                    style: const TextStyle(fontSize: 14, color: figmaInk),
                    decoration: InputDecoration(
                      hintText:
                          'Search leads by service, location or keyword...',
                      hintStyle: const TextStyle(
                        fontSize: 14,
                        color: figmaMuted,
                      ),
                      prefixIcon: const Icon(Icons.search, size: 18),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                      isDense: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(28),
                        borderSide: const BorderSide(color: Color(0xFFD2DEF2)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: shown.isEmpty
                  ? const Center(child: Text('No categories found.'))
                  : GridView.builder(
                      padding: const EdgeInsets.fromLTRB(24, 4, 24, 20),
                      itemCount: shown.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 14,
                            mainAxisSpacing: 14,
                            childAspectRatio: 1.05,
                          ),
                      itemBuilder: (context, index) {
                        final i = shown[index];
                        final cat = widget.store.categories[i];
                        final art = _art(cat.name);
                        final existing = categoryArtwork(cat.name);
                        final count = widget.store.leads
                            .where((l) => l.category == i)
                            .length;
                        return Material(
                          color: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(9),
                            side: const BorderSide(color: Color(0xFF0153FD)),
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(9),
                            onTap: () {
                              widget.onSelect(i);
                              Navigator.pop(context);
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(10),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Align(
                                    alignment: Alignment.topRight,
                                    child: figmaSvg(
                                      '750-2861-imgVector1',
                                      size: 10,
                                    ),
                                  ),
                                  Expanded(
                                    child: Center(
                                      child: art != null
                                          ? figmaSvg(art, size: 48)
                                          : existing != null
                                          ? Image.asset(
                                              'assets/Nextlead Mobile  App Asetes/$existing',
                                              width: 48,
                                              height: 48,
                                            )
                                          : Icon(
                                              cat.icon,
                                              size: 32,
                                              color: figmaBlue,
                                            ),
                                    ),
                                  ),
                                  Text(
                                    cat.name,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: figmaInk,
                                      fontSize: 14,
                                      height: 1.2,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  Text(
                                    '$count Leads',
                                    style: const TextStyle(
                                      color: figmaMuted,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
