import 'cylinder.dart';
import 'gateway.dart';

class NigerianAddress {
  final String? street;
  final String? area;
  final String? localGovernment;
  final String? state;

  NigerianAddress({this.street, this.area, this.localGovernment, this.state});

  factory NigerianAddress.fromJson(Map<String, dynamic> json) => NigerianAddress(
        street: json['street'] as String?,
        area: json['area'] as String?,
        localGovernment: json['localGovernment'] as String?,
        state: json['state'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'street': street,
        'area': area,
        'localGovernment': localGovernment,
        'state': state,
      };

  String get displayString {
    final parts = [street, area, localGovernment, state].where((p) => p != null && p.isNotEmpty);
    return parts.join(', ');
  }
}

class Site {
  final String id;
  final String name;
  final NigerianAddress? address;
  final double? latitude;
  final double? longitude;
  final String userId;
  final String? companyId;
  final List<CylinderSummary>? cylinders;
  final List<Gateway>? gateways;

  Site({
    required this.id,
    required this.name,
    this.address,
    this.latitude,
    this.longitude,
    required this.userId,
    this.companyId,
    this.cylinders,
    this.gateways,
  });

  factory Site.fromJson(Map<String, dynamic> json) => Site(
        id: json['id'] as String,
        name: json['name'] as String,
        address: json['address'] != null
            ? NigerianAddress.fromJson(json['address'] as Map<String, dynamic>)
            : null,
        latitude: (json['latitude'] as num?)?.toDouble(),
        longitude: (json['longitude'] as num?)?.toDouble(),
        userId: json['userId'] as String,
        companyId: json['companyId'] as String?,
        cylinders: (json['cylinders'] as List<dynamic>?)
            ?.map((e) => CylinderSummary.fromJson(e as Map<String, dynamic>))
            .toList(),
        gateways: (json['gateways'] as List<dynamic>?)
            ?.map((e) => Gateway.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class CreateSiteRequest {
  final String name;
  final NigerianAddress? address;
  final double? latitude;
  final double? longitude;

  CreateSiteRequest({required this.name, this.address, this.latitude, this.longitude});

  Map<String, dynamic> toJson() => {
        'name': name,
        if (address != null) 'address': address!.toJson(),
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
      };
}
