import 'package:flutter/material.dart';
import 'package:ganaderos_utc/services/location_gps_service.dart';

import '../../models/company_models.dart';
import '../../repositories/company_repository.dart';
import '../../utils/validators.dart';

class CompanyForm extends StatefulWidget {
  final Company? company;
  final VoidCallback onSave;

  const CompanyForm({super.key, this.company, required this.onSave});

  @override
  State<CompanyForm> createState() => _CompanyFormState();
}

class _CompanyFormState extends State<CompanyForm> {
  final _formKey = GlobalKey<FormState>();

  final _codeController = TextEditingController();
  final _nameController = TextEditingController();
  final _responsibleController = TextEditingController();
  final _dniController = TextEditingController();
  final _contactController = TextEditingController();
  final _emailController = TextEditingController();

  final _cityController = TextEditingController();
  final _parishController = TextEditingController();

  final _coordinatesController = TextEditingController();
  final _litresController = TextEditingController();
  final _observationController = TextEditingController();

  bool _isLoading = false;
  bool _gettingLocation = false;

  double? lat;
  double? lng;

  final CompanyRepository _repo = CompanyRepository();

  /// Ubicaciones referenciales de Ecuador por ciudad/parroquia
  static final Map<String, (double, double)> _ecuadorLocations = {
    'quito': (-0.1807, -78.4678),
    'guayaquil': (-2.1700, -79.9224),
    'cuenca': (-2.9001, -79.0059),
    'latacunga': (-0.9352, -78.6155),
    'ambato': (-1.2491, -78.6167),
    'riobamba': (-1.6636, -78.6546),
    'loja': (-3.9931, -79.2042),
    'ibarra': (0.3517, -78.1223),
    'santo domingo': (-0.2531, -79.1754),
    'quevedo': (-1.0286, -79.4635),
    'portoviejo': (-1.0546, -80.4545),
    'machala': (-3.2581, -79.9554),
    'esmeraldas': (0.9682, -79.6517),
    'babahoyo': (-1.8022, -79.5344),
    'tena': (-0.9938, -77.8129),
    'puyo': (-1.4920, -78.0026),
    'nueva loja': (0.0847, -76.8828),

    // Zonas útiles para tu proyecto
    'salache': (-0.9917, -78.6167),
    'mulalo': (-0.9170, -78.6970),
    'tanicuchi': (-0.9315, -78.7174),
    'pastocalle': (-0.8500, -78.6333),
    'saquisili': (-0.8399, -78.6670),
    'pujili': (-0.9575, -78.6963),
    'pangua': (-1.0953, -79.2260),
    'la mana': (-0.9409, -79.2219),
    'sigchos': (-0.6992, -78.9037),
    'salcedo': (-1.0455, -78.5906),
    'guaytacama': (-0.9066, -78.6437),
    'poalo': (-0.9169, -78.5618),
    'belisario quevedo': (-0.9810, -78.6200),
    'alaquez': (-0.9794, -78.6686),
    'toacaso': (-0.7758, -78.7538),
  };

  @override
  void initState() {
    super.initState();
    if (widget.company != null) {
      _fillForm(widget.company!);
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    _nameController.dispose();
    _responsibleController.dispose();
    _dniController.dispose();
    _contactController.dispose();
    _emailController.dispose();
    _cityController.dispose();
    _parishController.dispose();
    _coordinatesController.dispose();
    _litresController.dispose();
    _observationController.dispose();
    super.dispose();
  }

  String _capitalizeFirst(String text) {
    final value = text.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (value.isEmpty) return value;
    return value[0].toUpperCase() + value.substring(1).toLowerCase();
  }

  String _normalizeForCompare(String text) {
    return text.trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();
  }

  String _normalizeLocation(String? text) {
    if (text == null) return '';
    return text.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  }

  (double?, double?) _getCoordsFromCityOrParish() {
    final cityKey = _normalizeLocation(_cityController.text);
    final parishKey = _normalizeLocation(_parishController.text);

    if (cityKey.isNotEmpty && _ecuadorLocations.containsKey(cityKey)) {
      final coords = _ecuadorLocations[cityKey]!;
      return (coords.$1, coords.$2);
    }

    if (parishKey.isNotEmpty && _ecuadorLocations.containsKey(parishKey)) {
      final coords = _ecuadorLocations[parishKey]!;
      return (coords.$1, coords.$2);
    }

    return (null, null);
  }

  Future<void> _getLocation() async {
    setState(() => _gettingLocation = true);

    final pos = await LocationGpsService.getCurrentLocation();

    if (!mounted) return;
    setState(() => _gettingLocation = false);

    if (pos == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo obtener la ubicación actual'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      lat = pos.latitude;
      lng = pos.longitude;
      _coordinatesController.text =
          '${lat!.toStringAsFixed(6)},${lng!.toStringAsFixed(6)}';
    });
  }

  void _fillForm(Company c) {
    _codeController.text = c.companyCode;
    _nameController.text = _capitalizeFirst(c.companyName);
    _responsibleController.text = _capitalizeFirst(c.responsible);
    _dniController.text = c.dni;
    _contactController.text = c.contact;
    _emailController.text = c.email.trim().toLowerCase();

    _cityController.text = c.city != null ? _capitalizeFirst(c.city!) : '';
    _parishController.text =
        c.parish != null ? _capitalizeFirst(c.parish!) : '';

    _coordinatesController.text = c.coordinatesString ?? '';
    _litresController.text = _formatNullableNumber(c.litersOfMilk);

    _observationController.text =
        c.observation != null ? _capitalizeFirst(c.observation!) : '';

    lat = c.lat;
    lng = c.lng;
  }

  Future<String?> _validateDuplicates() async {
    final companies = await _repo.getAll();
    final currentId = widget.company?.id;

    final code = _normalizeForCompare(_codeController.text);
    final name = _normalizeForCompare(_nameController.text);
    final responsible = _normalizeForCompare(_responsibleController.text);
    final dni = _dniController.text.trim();
    final contact = _contactController.text.trim();
    final email = _emailController.text.trim().toLowerCase();

    if (code.isNotEmpty) {
      final codeExists = companies.any((c) {
        if (currentId != null && c.id == currentId) return false;
        return _normalizeForCompare(c.companyCode) == code;
      });
      if (codeExists) return 'El código ya se encuentra registrado';
    }

    if (name.isNotEmpty) {
      final nameExists = companies.any((c) {
        if (currentId != null && c.id == currentId) return false;
        return _normalizeForCompare(c.companyName) == name;
      });
      if (nameExists) {
        return 'El nombre de la hacienda ya se encuentra registrado';
      }
    }

    if (responsible.isNotEmpty) {
      final responsibleExists = companies.any((c) {
        if (currentId != null && c.id == currentId) return false;
        return _normalizeForCompare(c.responsible) == responsible;
      });
      if (responsibleExists) return 'El responsable ya se encuentra registrado';
    }

    if (dni.isNotEmpty) {
      final dniExists = companies.any((c) {
        if (currentId != null && c.id == currentId) return false;
        return c.dni.trim() == dni;
      });
      if (dniExists) return 'La cédula ya se encuentra registrada';
    }

    if (contact.isNotEmpty) {
      final contactExists = companies.any((c) {
        if (currentId != null && c.id == currentId) return false;
        return c.contact.trim() == contact;
      });
      if (contactExists) {
        return 'El número de teléfono ya se encuentra registrado';
      }
    }

    if (email.isNotEmpty) {
      final emailExists = companies.any((c) {
        if (currentId != null && c.id == currentId) return false;
        return c.email.trim().toLowerCase() == email;
      });
      if (emailExists) return 'El correo ya se encuentra registrado';
    }

    return null;
  }

  Future<void> _saveForm() async {
    if (_isLoading) return;

    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final duplicateError = await _validateDuplicates();

      if (!mounted) return;

      if (duplicateError != null) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(duplicateError),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      final coordsText = _coordinatesController.text.trim();
      var coords = _parseCoordinates(coordsText);

      // Si no escribieron coordenadas, intentar asignar por ciudad/parroquia
      if (coords.$1 == null || coords.$2 == null) {
        coords = _getCoordsFromCityOrParish();
      }

      final finalLat = coords.$1;
      final finalLng = coords.$2;

      final finalCoordinates =
          (finalLat != null && finalLng != null)
              ? '${finalLat.toStringAsFixed(6)},${finalLng.toStringAsFixed(6)}'
              : null;

      final isEditing = widget.company != null;

      final company = Company(
        id: widget.company?.id,
        companyCode: _codeController.text.trim(),
        companyName: _capitalizeFirst(_nameController.text),
        responsible: _capitalizeFirst(_responsibleController.text),
        dni: _dniController.text.trim(),
        contact: _contactController.text.trim(),
        email: _emailController.text.trim().toLowerCase(),
        city: _nullIfEmpty(_capitalizeFirst(_cityController.text)),
        parish: _nullIfEmpty(_capitalizeFirst(_parishController.text)),
        quarter: isEditing ? widget.company?.quarter : null,
        neighborhood: isEditing ? widget.company?.neighborhood : null,
        address: isEditing ? (widget.company?.address ?? '') : '',
        codeAddress: isEditing ? widget.company?.codeAddress : null,
        surface: isEditing ? widget.company?.surface : null,
        fertilityPercentage:
            isEditing ? widget.company?.fertilityPercentage : null,
        birthRate: isEditing ? widget.company?.birthRate : null,
        mortalityRate: isEditing ? widget.company?.mortalityRate : null,
        weaningPercentage: isEditing ? widget.company?.weaningPercentage : null,
        coordinates: finalCoordinates,
        litersOfMilk: _toNullableDouble(_litresController.text) ?? 0.0,
        lat: finalLat,
        lng: finalLng,
        observation: _nullIfEmpty(
          _capitalizeFirst(_observationController.text),
        ),
      );

      bool ok = false;

      if (isEditing) {
        ok = await _repo.update(company);
      } else {
        ok = await _repo.create(company);
      }

      if (!mounted) return;

      setState(() => _isLoading = false);

      if (!ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo guardar la hacienda. Revisa los datos.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isEditing
                ? 'Hacienda actualizada correctamente'
                : 'Hacienda registrada correctamente',
          ),
          backgroundColor: Colors.green,
        ),
      );

      widget.onSave();
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ocurrió un error al guardar la hacienda: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.company == null ? "Registrar Hacienda" : "Editar Hacienda",
      ),
      content: SizedBox(
        width: 650,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                _buildField(
                  _codeController,
                  "Código",
                  Icons.code,
                  required: true,
                  validator: (v) {
                    final text = v?.trim() ?? '';
                    if (text.isEmpty) return "Campo obligatorio";
                    if (text.length < 2) return "Código muy corto";
                    if (text.length > 30) return "Código muy largo";
                    return null;
                  },
                ),
                _buildField(
                  _nameController,
                  "Nombre Hacienda",
                  Icons.business,
                  required: true,
                  validator: (v) {
                    final text = v?.trim() ?? '';
                    if (text.isEmpty) return "Campo obligatorio";
                    if (text.length < 2) return "Nombre muy corto";
                    if (text.length > 120) return "Nombre muy largo";
                    return null;
                  },
                ),
                _buildField(
                  _responsibleController,
                  "Responsable",
                  Icons.person,
                  required: true,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return "Campo obligatorio";
                    }
                    return Validators.name(v);
                  },
                ),
                _buildField(
                  _dniController,
                  "Cédula",
                  Icons.badge,
                  required: true,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return "Campo obligatorio";
                    }
                    return Validators.cedulaEC(v);
                  },
                ),
                _buildField(
                  _contactController,
                  "Teléfono",
                  Icons.phone,
                  required: true,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return "Campo obligatorio";
                    }
                    if (!RegExp(r'^\d{7,15}$').hasMatch(v.trim())) {
                      return "Teléfono inválido";
                    }
                    return null;
                  },
                ),
                _buildField(
                  _emailController,
                  "Correo",
                  Icons.email,
                  required: true,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return "Campo obligatorio";
                    }
                    if (!RegExp(
                      r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                    ).hasMatch(v.trim())) {
                      return "Correo inválido";
                    }
                    if (v.trim().length > 120) {
                      return "Correo muy largo";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 8),
                _buildField(_cityController, "Ciudad", Icons.location_city),
                _buildField(_parishController, "Parroquia", Icons.map_outlined),
                const SizedBox(height: 8),
                _buildField(
                  _coordinatesController,
                  "Coordenadas (lat,lng)",
                  Icons.explore,
                  validator: (v) {
                    final text = v?.trim() ?? '';
                    if (text.isEmpty) return null;

                    final parsed = _parseCoordinates(text);
                    if (parsed.$1 == null || parsed.$2 == null) {
                      return 'Formato inválido. Usa: lat,lng';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 8),

                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _gettingLocation ? null : _getLocation,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                          foregroundColor: Colors.white,
                        ),
                        icon:
                            _gettingLocation
                                ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                                : const Icon(Icons.my_location),
                        label: Text(
                          _gettingLocation ? "Obteniendo..." : "Obtener GPS",
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),
                _buildNumericField(
                  _litresController,
                  "Producción de leche (litros)",
                ),
                _buildField(
                  _observationController,
                  "Observaciones",
                  Icons.notes,
                  maxLines: 3,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          style: TextButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: Colors.red,
          ),
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text("Cancelar"),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
          ),
          onPressed: _isLoading ? null : _saveForm,
          child:
              _isLoading
                  ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                  : const Text("Guardar"),
        ),
      ],
    );
  }

  Widget _buildField(
    TextEditingController c,
    String label,
    IconData icon, {
    bool required = false,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: c,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: const OutlineInputBorder(),
        ),
        validator:
            validator ??
            (v) {
              if (required && (v == null || v.trim().isEmpty)) {
                return "Campo obligatorio";
              }
              return null;
            },
      ),
    );
  }

  Widget _buildNumericField(TextEditingController c, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: c,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.local_drink),
          border: const OutlineInputBorder(),
        ),
        validator: (v) {
          final text = v?.trim() ?? '';
          if (text.isEmpty) return null;

          final value = double.tryParse(text);
          if (value == null) return 'Ingrese un número válido';
          if (value < 0) return 'La producción no puede ser negativa';
          if (value > 100000) return 'La producción excede el límite permitido';
          return null;
        },
      ),
    );
  }

  static String? _nullIfEmpty(String? value) {
    if (value == null) return null;
    final clean = value.trim();
    return clean.isEmpty ? null : clean;
  }

  static double? _toNullableDouble(String value) {
    final text = value.trim();
    if (text.isEmpty) return null;
    return double.tryParse(text);
  }

  static String _formatNullableNumber(double? value) {
    if (value == null) return '';
    if (value % 1 == 0) return value.toInt().toString();
    return value.toString();
  }

  static (double?, double?) _parseCoordinates(String raw) {
    final cleaned = raw.replaceAll(';', ',').replaceAll(' ', ',');
    final parts =
        cleaned
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();

    if (parts.length < 2) return (null, null);

    final lat = double.tryParse(parts[0]);
    final lng = double.tryParse(parts[1]);

    if (lat == null || lng == null) return (null, null);
    if (lat < -90 || lat > 90) return (null, null);
    if (lng < -180 || lng > 180) return (null, null);

    return (lat, lng);
  }
}
