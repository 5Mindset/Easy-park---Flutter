class User {
  final int id;
  final String name;
  final String email;
  final String? phoneNumber;
  final String? address;
  final String? profilePhotoUrl;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.phoneNumber,
    this.address,
    this.profilePhotoUrl,
  });

  // Factory constructor to create a User object from JSON
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      phoneNumber: json['phone_number'],
      address: json['address'],
      profilePhotoUrl: json['profile_photo_url'],
    );
  }

  // Method to convert User object to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone_number': phoneNumber,
      'address': address,
      'profile_photo_url': profilePhotoUrl,
    };
  }
}
