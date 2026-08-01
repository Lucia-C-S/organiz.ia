import 'package:cloud_firestore/cloud_firestore.dart';

class PantryItem {
  PantryItem({
    required this.id,
    required this.name,
    required this.brand,
    required this.photoUrl,
    required this.expiryDate,
    required this.store,
    required this.location,
    String? locationType,
    this.locationDetail = '',
    this.gridRow,
    this.gridColumn,
    required this.barcode,
    required this.addedBy,
    required this.addedAt,
  }) : locationType = locationType ?? location;

  final String id;
  final String name;
  final String brand;
  final String photoUrl;
  final DateTime expiryDate;
  final String store;
  final String location;
  final String locationType;
  final String locationDetail;
  final int? gridRow;
  final int? gridColumn;
  final String barcode;
  final String addedBy;
  final DateTime addedAt;

  bool get isExpired => expiryDate.isBefore(DateTime.now());

  bool get isExpiringSoon {
    final now = DateTime.now();
    final warningThreshold = now.add(const Duration(days: 3));
    return !isExpired && expiryDate.isBefore(warningThreshold);
  }

  PantryItem copyWith({
    String? id,
    String? name,
    String? brand,
    String? photoUrl,
    DateTime? expiryDate,
    String? store,
    String? location,
    String? locationType,
    String? locationDetail,
    int? gridRow,
    int? gridColumn,
    String? barcode,
    String? addedBy,
    DateTime? addedAt,
  }) {
    return PantryItem(
      id: id ?? this.id,
      name: name ?? this.name,
      brand: brand ?? this.brand,
      photoUrl: photoUrl ?? this.photoUrl,
      expiryDate: expiryDate ?? this.expiryDate,
      store: store ?? this.store,
      location: location ?? this.location,
      locationType: locationType ?? this.locationType,
      locationDetail: locationDetail ?? this.locationDetail,
      gridRow: gridRow ?? this.gridRow,
      gridColumn: gridColumn ?? this.gridColumn,
      barcode: barcode ?? this.barcode,
      addedBy: addedBy ?? this.addedBy,
      addedAt: addedAt ?? this.addedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'brand': brand,
      'photoUrl': photoUrl,
      'expiryDate': expiryDate.toIso8601String(),
      'store': store,
      'location': location,
      'locationType': locationType,
      'locationDetail': locationDetail,
      'gridRow': gridRow,
      'gridColumn': gridColumn,
      'barcode': barcode,
      'addedBy': addedBy,
      'addedAt': addedAt.toIso8601String(),
    };
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'brand': brand,
      'photoUrl': photoUrl,
      'expiryDate': Timestamp.fromDate(expiryDate),
      'store': store,
      'location': location,
      'locationType': locationType,
      'locationDetail': locationDetail,
      'gridRow': gridRow,
      'gridColumn': gridColumn,
      'barcode': barcode,
      'addedBy': addedBy,
      'addedAt': Timestamp.fromDate(addedAt),
    };
  }

  factory PantryItem.fromJson(Map<String, dynamic> json) {
    final location = json['location'] as String? ?? '';
    final locationType = (json['locationType'] as String? ?? '').trim();
    final locationDetail = (json['locationDetail'] as String? ?? '').trim();

    return PantryItem(
      id: json['id'] as String,
      name: json['name'] as String,
      brand: json['brand'] as String,
      photoUrl: json['photoUrl'] as String,
      expiryDate: DateTime.parse(json['expiryDate'] as String),
      store: json['store'] as String,
      location: location,
      locationType: locationType.isNotEmpty ? locationType : location,
      locationDetail: locationDetail,
      gridRow: json['gridRow'] as int?,
      gridColumn: json['gridColumn'] as int?,
      barcode: json['barcode'] as String,
      addedBy: json['addedBy'] as String,
      addedAt: DateTime.parse(json['addedAt'] as String),
    );
  }

  factory PantryItem.fromFirestore(Map<String, dynamic> data, String id) {
    final location = data['location'] as String? ?? '';
    final locationType = (data['locationType'] as String? ?? '').trim();
    final locationDetail = (data['locationDetail'] as String? ?? '').trim();

    return PantryItem(
      id: id,
      name: data['name'] as String? ?? '',
      brand: data['brand'] as String? ?? '',
      photoUrl: data['photoUrl'] as String? ?? '',
      expiryDate: _parseDate(data['expiryDate']),
      store: data['store'] as String? ?? '',
      location: location,
      locationType: locationType.isNotEmpty ? locationType : location,
      locationDetail: locationDetail,
      gridRow: data['gridRow'] as int?,
      gridColumn: data['gridColumn'] as int?,
      barcode: data['barcode'] as String? ?? '',
      addedBy: data['addedBy'] as String? ?? '',
      addedAt: _parseDate(data['addedAt']),
    );
  }

  static DateTime _parseDate(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }
    if (value is String) {
      return DateTime.parse(value);
    }
    if (value is DateTime) {
      return value;
    }
    return DateTime.now();
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is PantryItem &&
            runtimeType == other.runtimeType &&
            id == other.id &&
            name == other.name &&
            brand == other.brand &&
            photoUrl == other.photoUrl &&
            expiryDate == other.expiryDate &&
            store == other.store &&
            location == other.location &&
            locationType == other.locationType &&
            locationDetail == other.locationDetail &&
            barcode == other.barcode &&
            addedBy == other.addedBy &&
            addedAt == other.addedAt &&
            gridRow == other.gridRow &&
            gridColumn == other.gridColumn;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      name,
      brand,
      photoUrl,
      expiryDate,
      store,
      location,
      locationType,
      locationDetail,
      gridRow,
      gridColumn,
      barcode,
      addedBy,
      addedAt,
    );
  }
}
