import 'package:flutter/foundation.dart';

class OnStay {
  final String id;
  final String locationName;
  final String? stayType;
  final String? address;
  final DateTime? checkInDate;
  final DateTime? checkOutDate;
  final String? checkInTime;
  final String? checkOutTime;
  final double cost;
  final String currency;
  final String? contactName;
  final String? contactPhone;
  final String? contactEmail;
  final String status;
  final String paymentStatus;
  final String? notes;
  final List<String>? files;
  final String? createdBy;
  final DateTime? createdDate;
  final DateTime? updatedDate;
  final bool isSample;

  OnStay({
    required this.id,
    required this.locationName,
    this.stayType,
    this.address,
    this.checkInDate,
    this.checkOutDate,
    this.checkInTime,
    this.checkOutTime,
    required this.cost,
    required this.currency,
    this.contactName,
    this.contactPhone,
    this.contactEmail,
    required this.status,
    required this.paymentStatus,
    this.notes,
    this.files,
    this.createdBy,
    this.createdDate,
    this.updatedDate,
    this.isSample = false,
  });

  factory OnStay.fromJson(Map<String, dynamic> json) {
    debugPrint('🏨 OnStay.fromJson - Raw JSON: $json');

    // Handle both old and new schema field names
    final locationName = json['location_name'] ?? json['title'] ?? '';
    final address = json['address'] ?? json['location'] ?? '';
    final contactName = json['contact_name'] ?? json['client'] ?? '';
    final cost = json['cost'] ?? json['daily_rate'] ?? json['total_amount'] ?? 0;
    final checkInDate = json['check_in_date'] ?? json['start_date'];
    final checkOutDate = json['check_out_date'] ?? json['end_date'];

    debugPrint('🏨 OnStay.fromJson - locationName: $locationName');
    debugPrint('🏨 OnStay.fromJson - contactName: $contactName');
    debugPrint('🏨 OnStay.fromJson - address: $address');
    debugPrint('🏨 OnStay.fromJson - cost: $cost');
    debugPrint('🏨 OnStay.fromJson - checkInDate: $checkInDate');
    debugPrint('🏨 OnStay.fromJson - checkOutDate: $checkOutDate');

    return OnStay(
      id: json['id'] ?? '',
      locationName: locationName,
      stayType: json['stay_type'] ?? json['accommodation'],
      address: address,
      checkInDate: checkInDate != null
          ? DateTime.parse(checkInDate)
          : null,
      checkOutDate: checkOutDate != null
          ? DateTime.parse(checkOutDate)
          : null,
      checkInTime: json['check_in_time'],
      checkOutTime: json['check_out_time'],
      cost: (cost).toDouble(),
      currency: json['currency'] ?? 'USD',
      contactName: contactName,
      contactPhone: json['contact_phone'],
      contactEmail: json['contact_email'],
      status: json['status'] ?? 'pending',
      paymentStatus: json['payment_status'] ?? 'unpaid',
      notes: json['notes'],
      files: json['files'] != null 
          ? List<String>.from(json['files']) 
          : null,
      createdBy: json['created_by'],
      createdDate: json['created_date'] != null 
          ? DateTime.parse(json['created_date']) 
          : null,
      updatedDate: json['updated_date'] != null 
          ? DateTime.parse(json['updated_date']) 
          : null,
      isSample: json['is_sample'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    debugPrint('🏨 OnStay.toJson - Converting to old schema format');
    return {
      // Use old schema field names for compatibility
      'title': locationName,
      'location': address ?? '',
      'start_date': checkInDate?.toIso8601String().split('T')[0],
      'end_date': checkOutDate?.toIso8601String().split('T')[0],
      'accommodation': stayType,
      'daily_rate': cost,
      'total_amount': cost,
      'client': contactName,
      'status': status,
      'notes': notes,

      // Also include new schema fields for future compatibility
      'location_name': locationName,
      'stay_type': stayType,
      'address': address,
      'check_in_date': checkInDate?.toIso8601String().split('T')[0],
      'check_out_date': checkOutDate?.toIso8601String().split('T')[0],
      'check_in_time': checkInTime,
      'check_out_time': checkOutTime,
      'cost': cost,
      'currency': currency,
      'contact_name': contactName,
      'contact_phone': contactPhone,
      'contact_email': contactEmail,
      'payment_status': paymentStatus,
      'files': files,
      'created_by': createdBy,
      'is_sample': isSample,
    };
  }

  static const String tableName = 'OnStay';

  // Helper method to get formatted date range
  String get dateRange {
    if (checkInDate == null && checkOutDate == null) return 'No dates set';
    if (checkInDate == null) return 'Check-out: ${_formatDate(checkOutDate!)}';
    if (checkOutDate == null) return 'Check-in: ${_formatDate(checkInDate!)}';
    return '${_formatDate(checkInDate!)} - ${_formatDate(checkOutDate!)}';
  }

  // Helper method to get formatted time range
  String get timeRange {
    if (checkInTime == null && checkOutTime == null) return '';
    if (checkInTime == null) return 'Check-out: $checkOutTime';
    if (checkOutTime == null) return 'Check-in: $checkInTime';
    return '$checkInTime - $checkOutTime';
  }

  // Helper method to get formatted cost
  String get formattedCost {
    return '$currency ${cost.toStringAsFixed(2)}';
  }

  // Helper method to get status color
  String get statusColor {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return '#4CAF50'; // Green
      case 'pending':
        return '#FF9800'; // Orange
      case 'cancelled':
        return '#F44336'; // Red
      case 'completed':
        return '#2196F3'; // Blue
      default:
        return '#9E9E9E'; // Grey
    }
  }

  // Helper method to get payment status color
  String get paymentStatusColor {
    switch (paymentStatus.toLowerCase()) {
      case 'paid':
        return '#4CAF50'; // Green
      case 'unpaid':
        return '#F44336'; // Red
      case 'partial':
        return '#FF9800'; // Orange
      default:
        return '#9E9E9E'; // Grey
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  // Copy with method for easy updates
  OnStay copyWith({
    String? id,
    String? locationName,
    String? stayType,
    String? address,
    DateTime? checkInDate,
    DateTime? checkOutDate,
    String? checkInTime,
    String? checkOutTime,
    double? cost,
    String? currency,
    String? contactName,
    String? contactPhone,
    String? contactEmail,
    String? status,
    String? paymentStatus,
    String? notes,
    List<String>? files,
    String? createdBy,
    DateTime? createdDate,
    DateTime? updatedDate,
    bool? isSample,
  }) {
    return OnStay(
      id: id ?? this.id,
      locationName: locationName ?? this.locationName,
      stayType: stayType ?? this.stayType,
      address: address ?? this.address,
      checkInDate: checkInDate ?? this.checkInDate,
      checkOutDate: checkOutDate ?? this.checkOutDate,
      checkInTime: checkInTime ?? this.checkInTime,
      checkOutTime: checkOutTime ?? this.checkOutTime,
      cost: cost ?? this.cost,
      currency: currency ?? this.currency,
      contactName: contactName ?? this.contactName,
      contactPhone: contactPhone ?? this.contactPhone,
      contactEmail: contactEmail ?? this.contactEmail,
      status: status ?? this.status,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      notes: notes ?? this.notes,
      files: files ?? this.files,
      createdBy: createdBy ?? this.createdBy,
      createdDate: createdDate ?? this.createdDate,
      updatedDate: updatedDate ?? this.updatedDate,
      isSample: isSample ?? this.isSample,
    );
  }
}
