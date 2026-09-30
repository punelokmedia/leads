import 'package:flutter/material.dart';

class PreviewCategory {
  final String name, budget, fee;
  final IconData icon;
  final Color color;
  const PreviewCategory(
    this.name,
    this.budget,
    this.fee,
    this.icon,
    this.color,
  );
}

const previewCategories = [
  PreviewCategory(
    'Interior Design',
    '₹2L – ₹25L',
    '₹400 – ₹1200',
    Icons.chair,
    Colors.deepPurple,
  ),
  PreviewCategory(
    'Home Renovation / Civil Work',
    '₹1L – ₹20L',
    '₹300 – ₹1000',
    Icons.home_work,
    Colors.orange,
  ),
  PreviewCategory(
    'Painting',
    '₹50K – ₹5L',
    '₹150 – ₹400',
    Icons.format_paint,
    Colors.pink,
  ),
  PreviewCategory(
    'Plumbing',
    '₹10K – ₹2L',
    '₹80 – ₹250',
    Icons.plumbing,
    Colors.blue,
  ),
  PreviewCategory(
    'Electrical Work',
    '₹20K – ₹3L',
    '₹100 – ₹300',
    Icons.bolt,
    Colors.amber,
  ),
  PreviewCategory(
    'Carpentry / Modular Furniture',
    '₹50K – ₹10L',
    '₹200 – ₹700',
    Icons.door_sliding,
    Colors.brown,
  ),
  PreviewCategory(
    'CCTV Installation',
    '₹15K – ₹3L',
    '₹100 – ₹350',
    Icons.videocam,
    Colors.green,
  ),
  PreviewCategory(
    'AC Service & Repair',
    '₹2K – ₹50K',
    '₹50 – ₹150',
    Icons.ac_unit,
    Colors.blue,
  ),
  PreviewCategory(
    'Modular Kitchen',
    '₹1.5L – ₹8L',
    '₹300 – ₹900',
    Icons.kitchen,
    Colors.deepPurple,
  ),
  PreviewCategory(
    'False Ceiling (POP)',
    '₹40K – ₹4L',
    '₹120 – ₹350',
    Icons.roofing,
    Colors.pink,
  ),
  PreviewCategory(
    'Home Automation',
    '₹50K – ₹10L',
    '₹200 – ₹600',
    Icons.settings_remote,
    Colors.teal,
  ),
  PreviewCategory(
    'Waterproofing',
    '₹15K – ₹2L',
    '₹100 – ₹250',
    Icons.water_drop,
    Colors.blue,
  ),
  PreviewCategory(
    'Construction',
    '₹10L – ₹1Cr',
    '₹500 – ₹1500',
    Icons.construction,
    Colors.orange,
  ),
  PreviewCategory(
    'Architecture',
    '₹2L – ₹30L',
    '₹300 – ₹1000',
    Icons.architecture,
    Colors.green,
  ),
  PreviewCategory(
    'MEP',
    '₹1L – ₹20L',
    '₹200 – ₹800',
    Icons.settings,
    Colors.teal,
  ),
  PreviewCategory(
    'Landscaping',
    '₹50K – ₹10L',
    '₹200 – ₹600',
    Icons.park,
    Colors.green,
  ),
  PreviewCategory(
    'Flooring',
    '₹50K – ₹8L',
    '₹200 – ₹600',
    Icons.grid_on,
    Colors.orange,
  ),
];

class PreviewLead {
  final String id, title, city, state, description;
  final int category, budget;
  final num fee;
  final String clientType, propertyType, area, timeline, start;
  int buyers;
  bool joined, saved;
  final int maxBuyers;
  final int reservedSlots;
  final String backendId, contact, backendStatus;
  final String? budgetLabel;
  PreviewLead({
    required this.id,
    this.backendId = '',
    this.contact = '',
    this.backendStatus = 'ACTIVE',
    this.budgetLabel,
    this.maxBuyers = 2,
    this.reservedSlots = 0,
    required this.title,
    required this.category,
    required this.city,
    required this.state,
    required this.budget,
    required this.fee,
    required this.description,
    this.buyers = 0,
    this.joined = false,
    this.saved = false,
    this.clientType = 'Individual',
    this.propertyType = 'Apartment',
    this.area = '1200 – 1500 sq.ft.',
    this.timeline = '30 – 45 days',
    this.start = 'Within 15 days',
  });
  bool get closed => buyers >= maxBuyers || backendStatus != 'ACTIVE';
  bool get reserved => backendStatus == 'RESERVED';
  bool get expired => backendStatus == 'EXPIRED';
  int get availableSlots =>
      (maxBuyers - buyers - reservedSlots).clamp(0, maxBuyers);
  String get availabilityLabel => reserved
      ? 'Currently unavailable'
      : expired
      ? 'Lead expired'
      : 'Out of stock';
  String get status => joined
      ? 'JOINED'
      : reserved
      ? 'RESERVED'
      : expired
      ? 'EXPIRED'
      : closed
      ? 'CLOSED'
      : 'NEW';
}

class PreviewReceipt {
  final String leadId, title;
  final num fee;
  final String status;
  const PreviewReceipt(
    this.leadId,
    this.title,
    this.fee, {
    this.status = 'Paid',
  });
}

class PreviewStore extends ChangeNotifier {
  bool get isLive => false;
  List<PreviewCategory> get categories => previewCategories;
  List<String> get cities => ['Mumbai', 'Pune', 'Bangalore', 'Hyderabad'];
  Future<void> saveProfile(Map<String, String> details) async =>
      updateProfile(details);
  Future<void> refresh() async {}
  Future<void> Function(BuildContext, PreviewLead)? checkout;
  void Function(BuildContext)? support;
  void Function(BuildContext)? account;
  PreviewStore.empty() {
    leads = [];
    profile = {
      for (final key in [
        'Full name',
        'Email',
        'Phone',
        'Business name',
        'Service category',
        'City',
        'State',
      ])
        key: '',
    };
    unread = false;
  }
  late Map<String, String> profile;

  void updateProfile(Map<String, String> details) {
    profile = Map.of(details);
    notifyListeners();
  }

  late List<PreviewLead> leads;
  final List<PreviewReceipt> receipts = [];
  final List<String> notifications = [];
  final List<String> chat = [];
  bool unread = true;
  PreviewStore() {
    reset();
  }

  void reset() {
    profile = {
      'Full name': 'Demo Vendor',
      'Email': 'vendor@example.test',
      'Phone': '9999999999',
      'Business name': 'Demo Interiors',
      'Service category': 'Interior Design',
      'City': 'Mumbai',
      'State': 'Maharashtra',
    };
    leads = List.generate(
      previewCategories.length,
      (i) => PreviewLead(
        id: 'NL${24351 + i}',
        title: i == 0
            ? 'Interior Design Project'
            : '${previewCategories[i].name} Project',
        category: i,
        city: ['Mumbai', 'Pune', 'Bangalore', 'Hyderabad'][i % 4],
        state: ['Maharashtra', 'Maharashtra', 'Karnataka', 'Telangana'][i % 4],
        budget: i == 0
            ? 850000
            : i == 12
            ? 2500000
            : 100000 + i * 50000,
        fee: i == 0 ? 500 : [350, 300, 200, 100][i % 4],
        buyers: i == 2
            ? 2
            : i == 0 || i == 3
            ? 1
            : 0,
        joined: i == 3,
        description: i == 0
            ? 'Full interior design and execution for a 3BHK flat including modular kitchen, wardrobes, false ceiling, lighting and decor.'
            : 'Complete ${previewCategories[i].name.toLowerCase()} work required. Please discuss materials, site measurements and a detailed quotation with the sample client.',
      ),
    );
    receipts.clear();
    receipts.add(PreviewReceipt(leads[3].id, leads[3].title, leads[3].fee));
    notifications
      ..clear()
      ..add('New interior design lead available in Mumbai.');
    chat
      ..clear()
      ..add(
        'Support: Welcome! This is a simulated support conversation. Choose a topic or send a message.',
      );
    unread = true;
    notifyListeners();
  }

  void toggleSaved(PreviewLead lead) {
    lead.saved = !lead.saved;
    notifyListeners();
  }

  bool purchase(PreviewLead lead) {
    if (lead.joined || lead.closed) return false;
    lead.buyers++;
    lead.joined = true;
    receipts.insert(0, PreviewReceipt(lead.id, lead.title, lead.fee));
    notifications.insert(
      0,
      'Test payment successful. Contact unlocked for ${lead.id}.',
    );
    unread = true;
    notifyListeners();
    return true;
  }

  void markRead() {
    unread = false;
    notifyListeners();
  }

  void send(String message) {
    if (message.trim().isEmpty) return;
    chat.add('You: ${message.trim()}');
    chat.add(
      'Support (simulation): We received your message. For this preview, payments and contact details are sample data. No support request was sent.',
    );
    notifyListeners();
  }
}
