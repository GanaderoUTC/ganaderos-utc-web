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
  final _quarterController = TextEditingController();
  final _neighborhoodController = TextEditingController();
  final _addressController = TextEditingController();
  final _codeAddressController = TextEditingController();

  final _coordinatesController = TextEditingController();

  final _surfaceController = TextEditingController();
  final _fertilityController = TextEditingController();
  final _birthController = TextEditingController();
  final _mortalityController = TextEditingController();
  final _weaningController = TextEditingController();
  final _litresController = TextEditingController();

  final _observationController = TextEditingController();

  bool _isLoading = false;
  bool _gettingLocation = false;

  double? lat;
  double? lng;

  final CompanyRepository _repo = CompanyRepository();

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
    _quarterController.dispose();
    _neighborhoodController.dispose();
    _addressController.dispose();
    _codeAddressController.dispose();
    _coordinatesController.dispose();
    _surfaceController.dispose();
    _fertilityController.dispose();
    _birthController.dispose();
    _mortalityController.dispose();
    _weaningController.dispose();
    _litresController.dispose();
    _observationController.dispose();
    super.dispose();
  }

  /// ---------------- GPS ----------------

  Future<void> _getLocation() async {
    setState(() => _gettingLocation = true);

    final pos = await LocationGpsService.getCurrentLocation();

    if (!mounted) return;

    setState(() => _gettingLocation = false);

    if (pos == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo obtener la ubicación actual')),
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

  /// ---------------- LLENAR FORM ----------------

  void _fillForm(Company c) {
    _codeController.text = c.companyCode;
    _nameController.text = c.companyName;
    _responsibleController.text = c.responsible;
    _dniController.text = c.dni;
    _contactController.text = c.contact;
    _emailController.text = c.email;

    _cityController.text = c.city ?? '';
    _parishController.text = c.parish ?? '';
    _quarterController.text = c.quarter ?? '';
    _neighborhoodController.text = c.neighborhood ?? '';

    _addressController.text = c.address;
    _codeAddressController.text = c.codeAddress ?? '';
    _coordinatesController.text = c.coordinatesString ?? '';

    _surfaceController.text = _formatNumber(c.surface);
    _fertilityController.text = _formatNumber(c.fertilityPercentage);
    _birthController.text = _formatNumber(c.birthRate);
    _mortalityController.text = _formatNumber(c.mortalityRate);
    _weaningController.text = _formatNumber(c.weaningPercentage);
    _litresController.text = _formatNumber(c.litersOfMilk);

    _observationController.text = c.observation ?? '';

    lat = c.lat;
    lng = c.lng;
  }

  /// ---------------- VALIDAR DUPLICADOS ----------------

  Future<String?> _validateDuplicates() async {
    final companies = await _repo.getAll();

    final currentId = widget.company?.id;
    final dni = _dniController.text.trim();
    final contact = _contactController.text.trim();

    final dniExists = companies.any((c) {
      if (currentId != null && c.id == currentId) return false;
      return c.dni.trim() == dni;
    });

    if (dniExists) {
      return 'La cédula ya se encuentra registrada';
    }

    final contactExists = companies.any((c) {
      if (currentId != null && c.id == currentId) return false;
      return c.contact.trim() == contact;
    });

    if (contactExists) {
      return 'El número de teléfono ya se encuentra registrado';
    }

    return null;
  }

  /// ---------------- GUARDAR ----------------

  Future<void> _saveForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final duplicateError = await _validateDuplicates();

      if (!mounted) return;

      if (duplicateError != null) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(duplicateError)));
        return;
      }

      final coordsText = _coordinatesController.text.trim();
      final coords = _parseCoordinates(coordsText);

      final company = Company(
        id: widget.company?.id,
        companyCode: _codeController.text.trim(),
        companyName: _nameController.text.trim(),
        responsible: _responsibleController.text.trim(),
        dni: _dniController.text.trim(),
        contact: _contactController.text.trim(),
        email: _emailController.text.trim(),
        city: _nullIfEmpty(_cityController.text),
        parish: _nullIfEmpty(_parishController.text),
        quarter: _nullIfEmpty(_quarterController.text),
        neighborhood: _nullIfEmpty(_neighborhoodController.text),
        address: _addressController.text.trim(),
        codeAddress: _nullIfEmpty(_codeAddressController.text),
        coordinates: coordsText.isEmpty ? null : coordsText,
        surface: _toDouble(_surfaceController.text),
        fertilityPercentage: _toDouble(_fertilityController.text),
        birthRate: _toDouble(_birthController.text),
        mortalityRate: _toDouble(_mortalityController.text),
        weaningPercentage: _toDouble(_weaningController.text),
        litersOfMilk: _toDouble(_litresController.text),
        lat: coords.$1,
        lng: coords.$2,
        observation: _nullIfEmpty(_observationController.text),
      );

      bool ok = false;

      if (widget.company == null) {
        ok = await _repo.create(company);
      } else {
        ok = await _repo.update(company);
      }

      if (!mounted) return;

      setState(() => _isLoading = false);

      if (!ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo guardar la hacienda. Revisa los datos.'),
          ),
        );
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.company == null
                ? 'Hacienda registrada correctamente'
                : 'Hacienda actualizada correctamente',
          ),
        ),
      );

      widget.onSave();
      Navigator.pop(context);
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ocurrió un error al guardar la hacienda'),
        ),
      );
    }
  }

  /// ---------------- UI ----------------

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
                ),
                _buildField(
                  _nameController,
                  "Nombre Hacienda",
                  Icons.business,
                  required: true,
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
                    return null;
                  },
                ),

                const SizedBox(height: 8),

                _buildField(_cityController, "Ciudad", Icons.location_city),
                _buildField(_parishController, "Parroquia", Icons.map_outlined),
                _buildField(_quarterController, "Sector", Icons.map),
                _buildField(_neighborhoodController, "Barrio", Icons.home),
                _buildField(
                  _addressController,
                  "Dirección",
                  Icons.place,
                  required: true,
                ),

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
                _buildField(
                  _codeAddressController,
                  "Código dirección",
                  Icons.pin_drop,
                ),

                const SizedBox(height: 8),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _gettingLocation ? null : _getLocation,
                    icon:
                        _gettingLocation
                            ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                            : const Icon(Icons.my_location),
                    label: Text(
                      _gettingLocation
                          ? "Obteniendo ubicación..."
                          : "Obtener GPS",
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                _buildNumericField(_surfaceController, "Superficie"),
                _buildNumericField(_fertilityController, "Fertilidad %"),
                _buildNumericField(_birthController, "Nacimiento %"),
                _buildNumericField(_mortalityController, "Mortalidad %"),
                _buildNumericField(_weaningController, "Destete %"),
                _buildNumericField(_litresController, "Producción leche"),

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
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text("Cancelar"),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _saveForm,
          child:
              _isLoading
                  ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                  : const Text("Guardar"),
        ),
      ],
    );
  }

  /// ---------------- INPUTS ----------------

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
          prefixIcon: const Icon(Icons.numbers),
          border: const OutlineInputBorder(),
        ),
        validator: (v) {
          final text = v?.trim() ?? '';
          if (text.isEmpty) return null;
          if (double.tryParse(text) == null) {
            return 'Ingrese un número válido';
          }
          return null;
        },
      ),
    );
  }

  /// ---------------- HELPERS ----------------

  static String? _nullIfEmpty(String? value) {
    if (value == null) return null;
    final clean = value.trim();
    return clean.isEmpty ? null : clean;
  }

  static double _toDouble(String value) {
    return double.tryParse(value.trim()) ?? 0.0;
  }

  static String _formatNumber(double value) {
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

    return (lat, lng);
  }
}
