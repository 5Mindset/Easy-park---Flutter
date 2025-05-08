class Vehicle {
  final int? id;
  final String plateNumber;
  final String brand;
  final String model;
  final String color;

  Vehicle({
    this.id,
    required this.plateNumber,
    required this.brand,
    required this.model,
    required this.color,
  });

  factory Vehicle.fromJson(Map<String, dynamic> json) {
    return Vehicle(
      id: json['id'],
      plateNumber: json['plate_number'],
      brand: json['brand'],
      model: json['model'],
      color: json['color'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'plate_number': plateNumber,
      'brand': brand,
      'model': model,
      'color': color,
    };
  }
}
