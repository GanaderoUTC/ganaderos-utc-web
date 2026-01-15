class Company {
  int? id;
  String companyCode;
  String companyName;
  String responsible;
  String dni;
  String contact;
  String email;
  String? city;
  String? parish;
  String? quarter;
  String? neighborhood;
  String address;
  String? coordinates;
  String? codeAddress;
  double surface;
  double fertilityPercentage;
  double birthRate;
  double mortalityRate;
  double weaningPercentage;
  double litersOfMilk;
  String? observation;

  Company({
    this.id,
    required this.companyCode,
    required this.companyName,
    required this.responsible,
    required this.dni,
    required this.contact,
    required this.email,
    this.city,
    this.parish,
    this.quarter,
    this.neighborhood,
    required this.address,
    this.coordinates,
    this.codeAddress,
    required this.surface,
    required this.fertilityPercentage,
    required this.birthRate,
    required this.mortalityRate,
    required this.weaningPercentage,
    required this.litersOfMilk,
    this.observation,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'company_code': companyCode,
      'company_name': companyName,
      'responsible': responsible,
      'dni': dni,
      'contact': contact,
      'email': email,
      'city': city,
      'parish': parish,
      'quarter': quarter,
      'neighborhood': neighborhood,
      'address': address,
      'coordinates': coordinates,
      'code_address': codeAddress,
      'surface': surface,
      'fertility_percentage': fertilityPercentage,
      'birth_rate': birthRate,
      'mortality_rate': mortalityRate,
      'weaning_percentage': weaningPercentage,
      'liters_of_milk': litersOfMilk,
      'observation': observation,
    };
  }

  factory Company.fromMap(Map<String, dynamic> data) {
    return Company(
      id: data['id'],
      companyCode: data['company_code'] ?? '',
      companyName: data['company_name'] ?? '',
      responsible: data['responsible'] ?? '',
      dni: data['dni'] ?? '',
      contact: data['contact'] ?? '',
      email: data['email'] ?? '',
      city: data['city'],
      parish: data['parish'],
      quarter: data['quarter'],
      neighborhood: data['neighborhood'],
      address: data['address'] ?? '',
      coordinates: data['coordinates'],
      codeAddress: data['code_address'],
      surface: (data['surface'] ?? 0).toDouble(),
      fertilityPercentage: (data['fertility_percentage'] ?? 0).toDouble(),
      birthRate: (data['birth_rate'] ?? 0).toDouble(),
      mortalityRate: (data['mortality_rate'] ?? 0).toDouble(),
      weaningPercentage: (data['weaning_percentage'] ?? 0).toDouble(),
      litersOfMilk: (data['liters_of_milk'] ?? 0).toDouble(),
      observation: data['observation'],
    );
  }
}
