class HistoryModel {
  final String id;
  final String type; // ✅ Changed from Enum to String
  final String title;
  final double amount;
  final String currency;
  final String paymentLabel;
  final String subtitle;
  
  // PAYMENT specific
  final String fullname;
  final String status;
  final String date;

  // LEAD specific
  final String orderId;
  final String city;
  final String customerName;
  final String phone;
  final bool isDownloaded;

  HistoryModel({
    required this.id,
    required this.type,
    required this.title,
    required this.amount,
    required this.currency,
    required this.paymentLabel,
    this.fullname = '',
    this.subtitle='',
    this.status = '',
    this.date = '',
    this.orderId = '',
    this.city = '',
    this.customerName = '',
    this.phone = '',
    this.isDownloaded = false,
  });

  factory HistoryModel.fromJson(Map<String, dynamic> json) {
    // Format date if available
    String rawDate = json['paidAt'] ?? json['createdAt'] ?? '';
    String formattedDate = 'Recent'; 
    if (rawDate.isNotEmpty && rawDate.length >= 10) {
      formattedDate = rawDate.substring(0, 10); 
    }

    return HistoryModel(
      id: json['id'] ?? '',
      type: json['type'] ?? 'UNKNOWN',
      title: json['title'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      currency: json['currency'] ?? 'INR',
      paymentLabel: json['paymentLabel'] ?? '',
      subtitle: json['subtitle']??'',
      
      // Payment specific
      fullname: json['fullname'] ?? '',
      status: json['status'] ?? 'PENDING',
      date: formattedDate,

      // Lead specific
      orderId: json['orderId'] ?? '',
      city: json['city'] ?? '',
      customerName: json['customerName'] ?? '',
      phone: json['phone'] ?? '',
      isDownloaded: json['isDownloaded'] ?? false,
    );
  }
}