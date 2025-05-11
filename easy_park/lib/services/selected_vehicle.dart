class SelectedVehicle {
  static final SelectedVehicle _instance = SelectedVehicle._internal();
  factory SelectedVehicle() => _instance;
  SelectedVehicle._internal();

  String? _qrCodeUrl;
  Map<String, dynamic>? _vehicle;

  String? get qrCodeUrl => _qrCodeUrl;
  Map<String, dynamic>? get vehicle => _vehicle;

  void setSelectedVehicle(String qrCodeUrl, Map<String, dynamic> vehicle) {
    _qrCodeUrl = qrCodeUrl;
    _vehicle = vehicle;
  }

  void clearSelectedVehicle() {
    _qrCodeUrl = null;
    _vehicle = null;
  }
}