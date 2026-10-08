import 'package:user_app/features/home/presentation/widgets/home_banner_carousel.dart';
import 'package:flutter/material.dart';
import 'package:user_app/features/payments/presentation/widgets/wallet_card.dart';
import 'package:user_app/features/profile/presentation/widgets/referral_section.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'preview_data.dart';
import '../../core/theme/app_theme.dart';

const _purple = Color(0xFF5722CE);
const _gradient = LinearGradient(
  colors: [Color(0xFF110747), Color(0xFF6021BA)],
  begin: Alignment.bottomLeft,
  end: Alignment.topRight,
);
String money(num amount) =>
    '₹${NumberFormat.decimalPattern('en_IN').format(amount)}';

class PreviewApp extends StatefulWidget {
  const PreviewApp({super.key});
  @override
  State<PreviewApp> createState() => _PreviewAppState();
}

class _PreviewAppState extends State<PreviewApp> {
  final store = PreviewStore();
  @override
  void dispose() {
    store.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'NextLeads • Test mode',
    debugShowCheckedModeBanner: false,
    theme: AppTheme.light,
    darkTheme: AppTheme.dark,
    themeMode: AppTheme.mode,
    builder: (context, child) => Column(
      children: [
        Material(
          color: const Color(0xFFFFE6A7),
          child: SafeArea(
            bottom: false,
            child: SizedBox(
              width: double.infinity,
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Text(
                  'TEST MODE • Sample data • No real charges',
                  textAlign: TextAlign.center,
                  style: Theme.of(
                    context,
                  ).textTheme.labelSmall?.copyWith(color: Colors.black87),
                ),
              ),
            ),
          ),
        ),
        Expanded(child: child!),
      ],
    ),
    home: PreviewHome(store: store),
  );
}

class PreviewHome extends StatefulWidget {
  final PreviewStore store;
  final int initialPage;
  const PreviewHome({super.key, required this.store, this.initialPage = 0});
  @override
  State<PreviewHome> createState() => _PreviewHomeState();
}

class _PreviewHomeState extends State<PreviewHome> {
  late int page = widget.initialPage;
  String city = 'All Cities', query = '', tab = 'All';
  int? category;
  bool savedOnly = false;
  bool showFeaturePrompt = true;
  PreviewStore get store => widget.store;
  List<PreviewLead> get filtered => store.leads
      .where(
        (l) =>
            (city == 'All Cities' ||
                l.city.toLowerCase() == city.toLowerCase()) &&
            (category == null || l.category == category) &&
            (!savedOnly || l.saved) &&
            '${l.title} ${l.city} ${l.id}'.toLowerCase().contains(
              query.toLowerCase(),
            ) &&
            (tab == 'All' ||
                tab == 'New' && !l.joined && !l.closed ||
                tab == 'Joined' && l.joined ||
                tab == 'Closed' && l.closed),
      )
      .toList();

  bool _exitDialogOpen = false;

  Future<void> _handleBack() async {
    if (page != 0) {
      setState(() => page = 0);
      return;
    }
    if (_exitDialogOpen) return;
    _exitDialogOpen = true;
    try {
      final shouldExit = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Exit app?'),
          content: const Text('Do you want to exit the app?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('No'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Yes'),
            ),
          ],
        ),
      );
      if (shouldExit == true && mounted) {
        await SystemNavigator.pop();
      }
    } finally {
      _exitDialogOpen = false;
    }
  }

  void categories() => Navigator.push(
    context,
    MaterialPageRoute<void>(
      builder: (_) => CategoryPreview(
        store: store,
        onSelect: (index) {
          setState(() {
            category = index;
            page = 1;
            tab = 'All';
          });
        },
      ),
    ),
  );

  Future<void> filters() async {
    var nextCity = city;
    var nextCategory = category;
    var nextSaved = savedOnly;
    final applied = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, update) => SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Filter leads',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: nextCity,
                  decoration: const InputDecoration(labelText: 'City'),
                  items: ['All Cities', ...store.cities]
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (value) => update(() => nextCity = value!),
                ),
                DropdownButtonFormField<int>(
                  initialValue: nextCategory ?? -1,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: [
                    const DropdownMenuItem(
                      value: -1,
                      child: Text('All Categories'),
                    ),
                    ...List.generate(
                      store.categories.length,
                      (i) => DropdownMenuItem(
                        value: i,
                        child: Text(store.categories[i].name),
                      ),
                    ),
                  ],
                  onChanged: (value) =>
                      update(() => nextCategory = value == -1 ? null : value),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Saved leads only'),
                  value: nextSaved,
                  onChanged: (v) => update(() => nextSaved = v),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Apply filters'),
                ),
                TextButton(
                  onPressed: () {
                    nextCity = 'All Cities';
                    nextCategory = null;
                    nextSaved = false;
                    Navigator.pop(context, true);
                  },
                  child: const Text('Clear filters'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (applied == true && mounted) {
      setState(() {
        city = nextCity;
        category = nextCategory;
        savedOnly = nextSaved;
      });
    }
  }

  @override
  Widget build(BuildContext context) => PopScope<Object?>(
    canPop: page == 0 && (ModalRoute.of(context)?.canPop ?? false),
    onPopInvokedWithResult: (didPop, result) {
      if (!didPop) _handleBack();
    },
    child: ListenableBuilder(
      listenable: store,
      builder: (context, _) => Scaffold(
        // The preview banner already handles the top system inset.
        primary: store.isLive,
        appBar: AppBar(
          primary: store.isLive,
          toolbarHeight: 40,
          centerTitle: false,
          title: page == 0
              ? Image.asset(
                  'assets/Icons/appIcon/nextLeads_logo.png',
                  width: 40,
                  height: 30,
                  fit: BoxFit.contain,
                  semanticLabel: 'NextLeads',
                )
              : Text(
                  ['Home', 'All Leads', 'Payments', 'Profile', 'More'][page],
                ),
          actions: [
            if (page == 0)
              IconButton(
                tooltip: 'My profile',
                icon: const Icon(Icons.account_circle_outlined),
                onPressed: () => setState(() => page = 3),
              ),
            if (page == 0)
              IconButton(
                tooltip: 'Notifications',
                icon: Badge(
                  isLabelVisible: store.unread,
                  child: const Icon(Icons.notifications_outlined),
                ),
                onPressed: () {
                  store.markRead();
                  Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => NotificationsPreview(store: store),
                    ),
                  );
                },
              ),
            if (page == 1)
              IconButton(
                tooltip: 'Filter leads',
                onPressed: filters,
                icon: const Icon(Icons.filter_alt_outlined),
              ),
          ],
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: switch (page) {
              0 => Stack(
                children: [
                  Positioned.fill(child: home()),
                  if (showFeaturePrompt && store.leads.isNotEmpty)
                    Positioned(
                      top: 8,
                      left: 16,
                      right: 16,
                      child: Dismissible(
                        key: const ValueKey('feature-prompt'),
                        direction: DismissDirection.horizontal,
                        onDismissed: (_) =>
                            setState(() => showFeaturePrompt = false),
                        child: Card(
                          elevation: 6,
                          color: Theme.of(context).colorScheme.surface,
                          clipBehavior: Clip.antiAlias,
                          child: InkWell(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute<void>(
                                builder: (_) => LeadDetailsPreview(
                                  lead: store.leads.first,
                                  store: store,
                                ),
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(16, 8, 8, 16),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.tips_and_updates_outlined,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                  ),
                                  const SizedBox(width: 12),
                                  const Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          'Explore your first lead',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        SizedBox(height: 4),
                                        Text(
                                          'Tap to see project details. Swipe left or right to dismiss.',
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    tooltip: 'Dismiss feature prompt',
                                    onPressed: () => setState(
                                      () => showFeaturePrompt = false,
                                    ),
                                    icon: const Icon(Icons.close, size: 20),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              1 => leads(),
              2 => payments(),
              3 => profile(),
              _ => more(),
            },
          ),
        ),
        bottomNavigationBar: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            NavigationBar(
              selectedIndex: page,
              onDestinationSelected: (i) => setState(() => page = i),
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.home_outlined),
                  label: 'Home',
                ),
                NavigationDestination(
                  icon: Icon(Icons.description_outlined),
                  label: 'Leads',
                ),
                NavigationDestination(
                  icon: Icon(Icons.credit_card),
                  label: 'Payments',
                ),
                NavigationDestination(
                  icon: Icon(Icons.person_outline),
                  label: 'Profile',
                ),
                NavigationDestination(
                  icon: Icon(Icons.more_horiz),
                  label: 'More',
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );

  Widget home() => ListView(
    padding: const EdgeInsets.all(16),
    children: [
      const HomeBannerCarousel(),
      const SizedBox(height: 12),
      FilledButton.icon(
        onPressed: () => setState(() {
          page = 1;
          tab = 'New';
        }),
        icon: const Icon(Icons.bolt),
        label: const Text('Get Premium Leads'),
      ),
      const SizedBox(height: 8),
      Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: filters,
              icon: const Icon(Icons.location_on_outlined),
              label: Text(city),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: categories,
              icon: const Icon(Icons.grid_view),
              label: const Text('All Categories'),
            ),
          ),
        ],
      ),
      section('Top Categories', categories),
      LayoutBuilder(
        builder: (context, size) => GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: store.categories.length.clamp(0, 12),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: size.maxWidth < 350 ? 3 : 4,
            mainAxisExtent: 108,
          ),
          itemBuilder: (_, i) => InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => setState(() {
              category = i;
              tab = 'All';
              page = 1;
            }),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CategoryIcon(index: i, store: store),
                const SizedBox(height: 6),
                Text(
                  store.categories[i].name,
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  style: const TextStyle(fontSize: 11),
                ),
              ],
            ),
          ),
        ),
      ),
      section(
        "Today’s Top Leads",
        () => setState(() {
          page = 1;
          tab = 'All';
        }),
      ),
      if (filtered.isEmpty) const EmptyLeads(),
      ...filtered.take(3).map((l) => LeadPreviewCard(lead: l, store: store)),
      TrustStrip(store: store),
    ],
  );

  Widget section(String title, VoidCallback action) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Expanded(
        child: Text(
          title,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
        ),
      ),
      TextButton(onPressed: action, child: const Text('View All')),
    ],
  );

  Widget leads() => Column(
    children: [
      Padding(
        padding: const EdgeInsets.all(12),
        child: TextField(
          onChanged: (v) => setState(() => query = v),
          decoration: const InputDecoration(
            hintText: 'Search project, city or lead ID',
            prefixIcon: Icon(Icons.search),
            border: OutlineInputBorder(),
          ),
        ),
      ),
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: ['All', 'New', 'Joined', 'Closed']
              .map(
                (t) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: ChoiceChip(
                    label: Text(t),
                    selected: tab == t,
                    onSelected: (_) => setState(() => tab = t),
                  ),
                ),
              )
              .toList(),
        ),
      ),
      if (city != 'All Cities' || category != null || savedOnly)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  [
                    city,
                    if (category != null) store.categories[category!].name,
                    if (savedOnly) 'Saved only',
                  ].join(' • '),
                  style: const TextStyle(fontSize: 12),
                ),
              ),
              TextButton(
                onPressed: () => setState(() {
                  city = 'All Cities';
                  category = null;
                  savedOnly = false;
                }),
                child: const Text('Clear'),
              ),
            ],
          ),
        ),
      Expanded(
        child: filtered.isEmpty
            ? const EmptyLeads()
            : ListView(
                padding: const EdgeInsets.all(12),
                children: filtered
                    .map((l) => LeadPreviewCard(lead: l, store: store))
                    .toList(),
              ),
      ),
    ],
  );

  Widget payments() => ListView(
    padding: const EdgeInsets.all(16),
    children: [
      const WalletCard(),
      const SizedBox(height: 24),
      Text(
        store.isLive ? 'Payment history' : 'Test payment history',
        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
      ),
      if (!store.isLive)
        const Text('Simulated receipts only. No money has been charged.'),
      if (store.receipts.isEmpty) const Text('No payments yet.'),
      ...store.receipts.map(
        (r) => Card(
          child: ListTile(
            leading: Icon(
              r.status == 'Paid' ? Icons.check_circle : Icons.currency_exchange,
              color: r.status == 'Paid' ? Colors.green : Colors.orange,
            ),
            title: Text(r.title),
            subtitle: Text(
              '${r.leadId} • ${store.isLive ? r.status : 'Test payment successful'}',
            ),
            trailing: Text(money(r.fee)),
            onTap: () => showDialog<void>(
              context: context,
              builder: (_) => AlertDialog(
                title: Text(store.isLive ? 'Receipt' : 'Test receipt'),
                content: Text(
                  '${r.leadId}\n${r.title}\nAmount: ${money(r.fee)}\nStatus: ${store.isLive ? r.status : 'Simulated success\nNo real transaction was created.'}',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ],
  );

  Widget profile() => ListView(
    padding: const EdgeInsets.all(20),
    children: [
      const CircleAvatar(radius: 36, child: Icon(Icons.person, size: 40)),
      const SizedBox(height: 12),
      Text(
        store.profile['Full name']!,
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
      ),
      Text(
        '${store.profile['Email']}\n${store.profile['City']}, ${store.profile['State']}',
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: 12),
      FilledButton.icon(
        onPressed: () {
          if (store.isLive && store.profile['Full name']!.isEmpty) {
            store.account?.call(context);
            return;
          }
          Navigator.push(
            context,
            MaterialPageRoute<void>(
              builder: (_) => EditProfilePreview(store: store),
            ),
          );
        },
        icon: const Icon(Icons.edit_outlined),
        label: const Text('Edit personal details'),
      ),
      ListTile(
        leading: const Icon(Icons.business_outlined),
        title: Text(store.profile['Business name']!),
        subtitle: Text(store.profile['Service category']!),
      ),
      ListTile(
        leading: const Icon(Icons.phone_outlined),
        title: Text(store.profile['Phone']!),
      ),
      const SizedBox(height: 20),
      Card(
        child: ListTile(
          title: const Text('Joined leads'),
          trailing: Text('${store.leads.where((l) => l.joined).length}'),
          onTap: () => setState(() {
            page = 1;
            tab = 'Joined';
            city = 'All Cities';
            category = null;
            savedOnly = false;
          }),
        ),
      ),
      Card(
        child: ListTile(
          title: const Text('Saved leads'),
          trailing: Text('${store.leads.where((l) => l.saved).length}'),
          onTap: () => setState(() {
            page = 1;
            tab = 'All';
            savedOnly = true;
            city = 'All Cities';
            category = null;
          }),
        ),
      ),
      const SizedBox(height: 16),
      const ReferralSection(),
      const SizedBox(height: 16),
      if (!store.isLive)
        const Text(
          'This sample profile is for reviewing the mockup. Your real account is not used.',
        ),
      if (store.isLive) const Text('Saved leads are kept for this session.'),
    ],
  );

  Widget more() => ListView(
    padding: const EdgeInsets.all(16),
    children: [
      ListTile(
        leading: const Icon(Icons.account_balance_wallet_outlined),
        title: const Text('Wallet'),
        subtitle: const Text('Sample balance · Frontend preview'),
        trailing: Text(
          '₹600',
          style: TextStyle(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        onTap: () => setState(() => page = 2),
      ),
      ListTile(
        leading: const Icon(Icons.card_giftcard_outlined),
        title: const Text('Refer & Earn'),
        subtitle: const Text('Sample referral rewards: ₹100'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute<void>(
            builder: (_) => Scaffold(
              appBar: AppBar(title: const Text('Refer & Earn')),
              body: const SingleChildScrollView(
                padding: EdgeInsets.all(16),
                child: ReferralSection(initiallyExpanded: true),
              ),
            ),
          ),
        ),
      ),
      ListTile(
        leading: const Icon(Icons.grid_view),
        title: const Text('All Categories & Pricing'),
        onTap: categories,
      ),
      ListTile(
        leading: const Icon(Icons.support_agent),
        title: const Text('Chat & Support'),
        subtitle: const Text('Get help from our support team'),
        onTap: () => openSupport(context, store),
      ),
      ListTile(
        leading: const Icon(Icons.notifications_outlined),
        title: const Text('Notifications'),
        onTap: () {
          store.markRead();
          Navigator.push(
            context,
            MaterialPageRoute<void>(
              builder: (_) => NotificationsPreview(store: store),
            ),
          );
        },
      ),
      if (!store.isLive)
        const Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Preview checklist\n\n• Filter by city and category\n• Browse All / New / Joined / Closed\n• Save a lead and copy its summary\n• Try successful, failed and cancelled payments\n• Check unlocked sample contact and receipt\n• Send a simulated support message\n• Reset to repeat the test',
            ),
          ),
        ),
      OutlinedButton.icon(
        onPressed: () {
          if (store.isLive) {
            store.refresh();
            return;
          }
          store.reset();
          setState(() {
            city = 'All Cities';
            category = null;
            savedOnly = false;
            query = '';
            tab = 'All';
            showFeaturePrompt = true;
          });
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Sample data reset')));
        },
        icon: const Icon(Icons.restart_alt),
        label: Text(store.isLive ? 'Refresh data' : 'Reset test data'),
      ),
      if (store.isLive)
        ListTile(
          leading: const Icon(Icons.manage_accounts),
          title: const Text('Account / Sign in'),
          onTap: () => store.account?.call(context),
        ),
      if (!store.isLive)
        const Text(
          'All preview changes live in memory and reset when the app restarts.',
          textAlign: TextAlign.center,
        ),
    ],
  );
}

class EditProfilePreview extends StatefulWidget {
  final PreviewStore store;
  const EditProfilePreview({super.key, required this.store});

  @override
  State<EditProfilePreview> createState() => _EditProfilePreviewState();
}

class _EditProfilePreviewState extends State<EditProfilePreview> {
  bool saving = false;
  final formKey = GlobalKey<FormState>();
  late final controllers = {
    for (final entry in widget.store.profile.entries)
      entry.key: TextEditingController(text: entry.value),
  };

  @override
  void dispose() {
    for (final controller in controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Edit personal details'),
      primary: widget.store.isLive,
    ),
    body: Form(
      key: formKey,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            widget.store.isLive
                ? 'Update your personal and business details.'
                : 'Update your personal and business details. Changes are saved only for this preview session.',
          ),
          const SizedBox(height: 20),
          for (final entry in controllers.entries)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: TextFormField(
                controller: entry.value,
                decoration: InputDecoration(
                  labelText: entry.key,
                  border: const OutlineInputBorder(),
                ),
                keyboardType: entry.key == 'Email'
                    ? TextInputType.emailAddress
                    : entry.key == 'Phone'
                    ? TextInputType.phone
                    : TextInputType.text,
                textCapitalization: entry.key == 'Email'
                    ? TextCapitalization.none
                    : TextCapitalization.words,
                validator: (value) {
                  final text = value?.trim() ?? '';
                  if (text.isEmpty) return 'Enter ${entry.key.toLowerCase()}';
                  if (widget.store.isLive &&
                      entry.key == 'Full name' &&
                      text.split(RegExp(r'\s+')).length < 2) {
                    return 'Enter first and last name';
                  }
                  if (widget.store.isLive &&
                      entry.key == 'Phone' &&
                      !RegExp(r'^[6-9]\d{9}$').hasMatch(text)) {
                    return 'Enter a 10-digit Indian phone number';
                  }
                  if (entry.key == 'Email' &&
                      !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(text)) {
                    return 'Enter a valid email address';
                  }
                  if (entry.key == 'Phone' &&
                      (!RegExp(r'^\+?[0-9 ()-]+$').hasMatch(text) ||
                          text.replaceAll(RegExp(r'\D'), '').length < 10 ||
                          text.replaceAll(RegExp(r'\D'), '').length > 15)) {
                    return 'Enter a valid phone number';
                  }
                  return null;
                },
              ),
            ),
          FilledButton.icon(
            icon: const Icon(Icons.check),
            label: const Text('Save details'),
            onPressed: saving
                ? null
                : () async {
                    if (!formKey.currentState!.validate()) return;
                    setState(() => saving = true);
                    try {
                      await widget.store.saveProfile({
                        for (final entry in controllers.entries)
                          entry.key: entry.value.text.trim(),
                      });
                      if (!context.mounted) return;
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            widget.store.isLive
                                ? 'Profile saved'
                                : 'Profile saved for this preview session',
                          ),
                        ),
                      );
                    } catch (_) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Could not save profile. Please check your details and try again.',
                            ),
                          ),
                        );
                      }
                    } finally {
                      if (mounted) setState(() => saving = false);
                    }
                  },
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    ),
  );
}

class CategoryIcon extends StatelessWidget {
  final int index;
  final PreviewStore store;
  const CategoryIcon({super.key, required this.index, required this.store});
  @override
  Widget build(BuildContext context) {
    final c = store.categories[index];
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: c.color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(c.icon, color: c.color, size: 28),
    );
  }
}

class LeadPreviewCard extends StatelessWidget {
  final PreviewLead lead;
  final PreviewStore store;
  const LeadPreviewCard({super.key, required this.lead, required this.store});
  @override
  Widget build(BuildContext context) => Card(
    color: Theme.of(context).colorScheme.surface,
    margin: const EdgeInsets.only(bottom: 12),
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CategoryIcon(index: lead.category, store: store),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  lead.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  '${lead.city}, ${lead.state}',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Project Budget',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
                Text(
                  (lead.budgetLabel ?? money(lead.budget)),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Wrap(
                  spacing: 12,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text('Vendors ${lead.buyers}/${lead.maxBuyers}'),
                    Text(
                      lead.status,
                      style: TextStyle(
                        color: lead.closed
                            ? Theme.of(context).colorScheme.onSurfaceVariant
                            : Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                    if (lead.saved)
                      Icon(
                        Icons.favorite,
                        color: Theme.of(context).colorScheme.primary,
                        size: 16,
                      ),
                  ],
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: OutlinedButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) =>
                            LeadDetailsPreview(lead: lead, store: store),
                      ),
                    ),
                    child: Text(
                      lead.joined
                          ? 'View Contact'
                          : lead.closed
                          ? 'View Closed Lead'
                          : 'View Lead',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class EmptyLeads extends StatelessWidget {
  const EmptyLeads({super.key});
  @override
  Widget build(BuildContext context) => const Center(
    child: Padding(
      padding: EdgeInsets.all(32),
      child: Text(
        'No leads match these filters.\nTry another city or clear the filters.',
        textAlign: TextAlign.center,
      ),
    ),
  );
}

class TrustStrip extends StatelessWidget {
  final PreviewStore? store;
  const TrustStrip({super.key, this.store});
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.symmetric(vertical: 12),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Wrap(
      alignment: WrapAlignment.center,
      spacing: 16,
      runSpacing: 8,
      children: store?.isLive == true
          ? [
              Text('${store!.categories.length} service categories'),
              Text('${store!.cities.length} cities'),
              const Text('Two buyers per lead'),
              const Text('Support inbox available 24/7'),
            ]
          : const [
              Text('✦ Verified & quality leads'),
              Text('⌖ Pan India • 1000+ cities'),
              Text('✓ Secure platform'),
              Text('Trusted by professionals'),
            ],
    ),
  );
}

class CategoryPreview extends StatefulWidget {
  final PreviewStore store;
  final ValueChanged<int> onSelect;
  const CategoryPreview({
    super.key,
    required this.store,
    required this.onSelect,
  });
  @override
  State<CategoryPreview> createState() => _CategoryPreviewState();
}

class _CategoryPreviewState extends State<CategoryPreview> {
  PreviewStore get store => widget.store;
  bool pricing = true;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('All Categories')),
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.public,
                    color: Theme.of(context).colorScheme.primary,
                    size: 40,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pan India Coverage',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        Text(
                          store.isLive
                              ? '${store.cities.length} cities in our catalog'
                              : 'Leads available in 1000+ cities',
                        ),
                        Text(
                          store.isLive
                              ? 'Select a category to see current availability'
                              : 'Coverage claims shown as mock copy',
                          style: TextStyle(fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SwitchListTile(
              title: const Text('Show pricing table'),
              subtitle: const Text('Switch off to see category lead counts'),
              value: pricing,
              onChanged: (v) => setState(() => pricing = v),
            ),
            if (pricing)
              Container(
                color: _purple,
                padding: const EdgeInsets.all(12),
                child: const Row(
                  children: [
                    Expanded(
                      flex: 4,
                      child: Text(
                        'Category',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(
                        'Project budget',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(
                        'Lead price',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ...List.generate(store.categories.length, (i) {
              final c = store.categories[i];
              return InkWell(
                onTap: () {
                  widget.onSelect(i);
                  Navigator.pop(context);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 8,
                  ),
                  decoration: BoxDecoration(
                    color: i.isEven
                        ? Theme.of(context).colorScheme.surface
                        : Theme.of(context).colorScheme.surfaceContainerLow,
                    border: Border(
                      bottom: BorderSide(
                        color: Theme.of(context).colorScheme.outlineVariant,
                      ),
                    ),
                  ),
                  child: pricing
                      ? Row(
                          children: [
                            Expanded(
                              flex: 4,
                              child: Row(
                                children: [
                                  Icon(c.icon, size: 20, color: c.color),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      c.name,
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              flex: 3,
                              child: Text(
                                c.budget,
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                            Expanded(
                              flex: 3,
                              child: Text(
                                c.fee,
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                          ],
                        )
                      : Row(
                          children: [
                            CategoryIcon(index: i, store: store),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(c.name),
                                  Text(
                                    '${widget.store.leads.where((l) => l.category == i && !l.closed).length} available ${store.isLive ? '' : 'test '}leads',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right),
                          ],
                        ),
                ),
              );
            }),
            const SizedBox(height: 16),
            const Text(
              'Vendor availability and access fees vary by lead',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Prices vary by city and project. See each lead for its access fee.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontSize: 12,
              ),
            ),
            TrustStrip(store: store),
          ],
        ),
      ),
    ),
  );
}

class LeadDetailsPreview extends StatelessWidget {
  final PreviewLead lead;
  final PreviewStore store;
  const LeadDetailsPreview({
    super.key,
    required this.lead,
    required this.store,
  });

  Future<void> checkout(BuildContext context) async {
    if (store.isLive) {
      await store.checkout?.call(context, lead);
      return;
    }
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Test checkout'),
        content: Text(
          '${lead.title}\nLead access fee: ${money(lead.fee)}\n\nChoose an outcome. No payment gateway will open and no money will be charged.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 'cancel'),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 'fail'),
            child: const Text('Simulate failure'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, 'success'),
            child: const Text('Simulate success'),
          ),
        ],
      ),
    );
    if (!context.mounted) return;
    if (result == 'success') {
      final purchased = store.purchase(lead);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            purchased
                ? 'Test payment successful. Sample contact unlocked below.'
                : 'This lead is already joined or closed.',
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result == 'fail'
                ? 'Test payment failed. No slot taken. Try again.'
                : 'Test payment cancelled. No slot taken.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: store,
    builder: (context, _) => Scaffold(
      appBar: AppBar(
        title: const Text('Lead Details'),
        actions: [
          IconButton(
            tooltip: lead.saved ? 'Unsave lead' : 'Save lead',
            onPressed: () => store.toggleSaved(lead),
            icon: Icon(
              lead.saved ? Icons.favorite : Icons.favorite_border,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          IconButton(
            tooltip: 'Share lead summary',
            icon: const Icon(Icons.share_outlined),
            onPressed: () => showDialog<void>(
              context: context,
              builder: (dialogContext) => AlertDialog(
                title: Text(store.isLive ? 'Share lead' : 'Share test lead'),
                content: SelectableText(
                  '${lead.title}\n${lead.city}, ${lead.state}\nBudget: ${(lead.budgetLabel ?? money(lead.budget))}\n${lead.id}\n${store.isLive ? 'NextLeads' : 'NextLeads preview — sample data'}',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    child: const Text('Close'),
                  ),
                  FilledButton(
                    onPressed: () async {
                      await Clipboard.setData(
                        ClipboardData(
                          text:
                              '${lead.title} • ${lead.city} • ${(lead.budgetLabel ?? money(lead.budget))} • ${lead.id}${store.isLive ? '' : ' • TEST DATA'}',
                        ),
                      );
                      if (dialogContext.mounted) Navigator.pop(dialogContext);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              store.isLive
                                  ? 'Lead summary copied'
                                  : 'Test lead summary copied',
                            ),
                          ),
                        );
                      }
                    },
                    child: const Text('Copy summary'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: _gradient,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lead.title,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      lead.propertyType,
                      style: const TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '⌖ ${lead.city}, ${lead.state}   •   ${lead.buyers}/${lead.maxBuyers} vendors',
                      style: const TextStyle(color: Colors.white),
                    ),
                    const SizedBox(height: 18),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Project Budget'),
                                Text(
                                  (lead.budgetLabel ?? money(lead.budget)),
                                  style: TextStyle(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                    fontSize: 26,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            children: [
                              const Text('Lead ID'),
                              Text(
                                lead.id,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              panel(
                context,
                'Project Requirements',
                Text(lead.description, style: const TextStyle(height: 1.6)),
              ),
              panel(
                context,
                'Project Information',
                Column(
                  children: [
                    info(
                      context,
                      Icons.work_outline,
                      'Project Type',
                      store.categories[lead.category].name,
                    ),
                    info(
                      context,
                      Icons.person_outline,
                      'Client Type',
                      lead.clientType,
                    ),
                    info(
                      context,
                      Icons.home_outlined,
                      'Property Type',
                      lead.propertyType,
                    ),
                    info(context, Icons.square_foot, 'Area', lead.area),
                    info(
                      context,
                      Icons.calendar_month,
                      'Project Timeline',
                      lead.timeline,
                    ),
                    info(
                      context,
                      Icons.event_available,
                      'Preferred Starting Date',
                      lead.start,
                    ),
                  ],
                ),
              ),
              panel(
                context,
                'Vendors Joined • ${lead.buyers}/${lead.maxBuyers}',
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LinearProgressIndicator(
                      value: (lead.buyers / lead.maxBuyers).clamp(0.0, 1.0),
                      minHeight: 8,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      lead.reserved
                          ? 'Checkout slots are temporarily reserved. Try again shortly.'
                          : lead.expired
                          ? 'This lead has expired.'
                          : lead.closed
                          ? 'Out of stock. Two buyers have purchased this lead.'
                          : '${lead.availableSlots} slot(s) available. One purchase per buyer.',
                    ),
                  ],
                ),
              ),
              if (lead.joined)
                panel(
                  context,
                  store.isLive
                      ? 'Client Contact'
                      : 'Sample Client Contact • Unlocked',
                  SelectableText(
                    store.isLive
                        ? lead.contact
                        : 'Demo Client\nclient@example.test\nPhone: +91 XXXXX XXXXX\nSample address: Demo Apartment, selected city\n\nTest data only. No real client will be contacted.',
                  ),
                ),
              TrustStrip(store: store),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Lead Access Fee'),
                        Text(
                          money(lead.fee),
                          style: TextStyle(
                            fontSize: 25,
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    flex: 2,
                    child: FilledButton(
                      onPressed: lead.joined || lead.closed
                          ? null
                          : () => checkout(context),
                      child: Text(
                        lead.joined
                            ? 'Contact Unlocked'
                            : lead.closed
                            ? (store.isLive
                                  ? lead.availabilityLabel
                                  : 'Lead Closed')
                            : 'Accept Lead & View Contact',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Text(
              'Up to ${lead.maxBuyers} vendors can access client details',
              style: TextStyle(fontSize: 11),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    ),
  );

  Widget panel(BuildContext context, String title, Widget child) => Card(
    color: Theme.of(context).colorScheme.surface,
    margin: const EdgeInsets.only(top: 14),
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    ),
  );
  Widget info(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Row(
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary, size: 22),
        const SizedBox(width: 10),
        Expanded(child: Text(label)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
          ),
        ),
      ],
    ),
  );
}

void openSupport(BuildContext context, PreviewStore store) {
  if (store.isLive) {
    store.support?.call(context);
    return;
  }
  Navigator.push(
    context,
    MaterialPageRoute<void>(builder: (_) => SupportPreview(store: store)),
  );
}

class SupportBar extends StatelessWidget {
  final PreviewStore store;
  const SupportBar({super.key, required this.store});
  @override
  Widget build(BuildContext context) => Material(
    color: _purple,
    child: SafeArea(
      top: false,
      bottom: false,
      child: Row(
        children: [
          Expanded(
            child: TextButton.icon(
              onPressed: () => openSupport(context, store),
              icon: const Icon(Icons.headset_mic, color: Colors.white),
              label: const Text(
                '24/7 Support',
                style: TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          ),
          Expanded(
            child: TextButton.icon(
              onPressed: () => openSupport(context, store),
              icon: const Icon(Icons.chat_bubble_outline, color: Colors.white),
              label: const Text(
                'Chat with Support',
                style: TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class SupportPreview extends StatefulWidget {
  final PreviewStore store;
  const SupportPreview({super.key, required this.store});
  @override
  State<SupportPreview> createState() => _SupportPreviewState();
}

class _SupportPreviewState extends State<SupportPreview> {
  final input = TextEditingController();
  @override
  void dispose() {
    input.dispose();
    super.dispose();
  }

  void send() {
    widget.store.send(input.text);
    input.clear();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Chat with Support')),
    body: SafeArea(
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(12),
            child: Text(
              '24/7 Support • Simulated replies; messages are not sent.',
            ),
          ),
          Wrap(
            spacing: 8,
            children: ['Payment help', 'Lead quality', 'Account help']
                .map(
                  (t) => ActionChip(
                    label: Text(t),
                    onPressed: () => widget.store.send(t),
                  ),
                )
                .toList(),
          ),
          Expanded(
            child: ListenableBuilder(
              listenable: widget.store,
              builder: (context, _) => ListView(
                reverse: true,
                padding: const EdgeInsets.all(16),
                children: widget.store.chat.reversed
                    .map(
                      (m) => Align(
                        alignment: m.startsWith('You:')
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Card(
                          color: m.startsWith('You:')
                              ? Theme.of(
                                  context,
                                ).colorScheme.surfaceContainerLow
                              : Theme.of(context).colorScheme.surface,
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Text(m),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: input,
                    onSubmitted: (_) => send(),
                    decoration: const InputDecoration(
                      hintText: 'Type a test message',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Send test message',
                  onPressed: send,
                  icon: Icon(
                    Icons.send,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class NotificationsPreview extends StatelessWidget {
  final PreviewStore store;
  const NotificationsPreview({super.key, required this.store});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Notifications')),
    body: ListenableBuilder(
      listenable: store,
      builder: (context, _) => ListView(
        children: store.notifications.isEmpty
            ? [const ListTile(title: Text('No notifications yet'))]
            : store.notifications
                  .map(
                    (n) => ListTile(
                      leading: Icon(
                        Icons.notifications_active_outlined,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      title: Text(n),
                      subtitle: Text(
                        store.isLive ? 'Account update' : 'Test notification',
                      ),
                    ),
                  )
                  .toList(),
      ),
    ),
  );
}
