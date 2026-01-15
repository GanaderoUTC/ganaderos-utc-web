import 'package:flutter/material.dart';
import '../../models/company_models.dart';
import '../../repositories/company_repository.dart';

class CompanyForm extends StatefulWidget {
  final Company? company;
  final VoidCallback onSave;

  const CompanyForm({super.key, this.company, required this.onSave});

  @override
  State<CompanyForm> createState() => _CompanyFormState();
}

class _CompanyFormState extends State<CompanyForm> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _responsibleController = TextEditingController();
  final TextEditingController _dniController = TextEditingController();
  final TextEditingController _contactController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _parishController = TextEditingController();
  final TextEditingController _quarterController = TextEditingController();
  final TextEditingController _neighborhoodController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _coordinatesController = TextEditingController();
  final TextEditingController _codeAddressController = TextEditingController();
  final TextEditingController _surfaceController = TextEditingController();
  final TextEditingController _fertilityController = TextEditingController();
  final TextEditingController _birthController = TextEditingController();
  final TextEditingController _mortalityController = TextEditingController();
  final TextEditingController _weaningController = TextEditingController();
  final TextEditingController _litresController = TextEditingController();
  final TextEditingController _observationController = TextEditingController();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.company != null) {
      _fillForm(widget.company!);
    }
  }

  void _fillForm(Company company) {
    _codeController.text = company.companyCode;
    _nameController.text = company.companyName;
    _responsibleController.text = company.responsible;
    _dniController.text = company.dni;
    _contactController.text = company.contact;
    _emailController.text = company.email;
    _cityController.text = company.city ?? '';
    _parishController.text = company.parish ?? '';
    _quarterController.text = company.quarter ?? '';
    _neighborhoodController.text = company.neighborhood ?? '';
    _addressController.text = company.address;
    _coordinatesController.text = company.coordinates ?? '';
    _codeAddressController.text = company.codeAddress ?? '';
    _surfaceController.text = company.surface.toString();
    _fertilityController.text = company.fertilityPercentage.toString();
    _birthController.text = company.birthRate.toString();
    _mortalityController.text = company.mortalityRate.toString();
    _weaningController.text = company.weaningPercentage.toString();
    _litresController.text = company.litersOfMilk.toString();
    _observationController.text = company.observation ?? '';
  }

  Future<void> _saveForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final newCompany = Company(
      id: widget.company?.id,
      companyCode: _codeController.text.trim(),
      companyName: _nameController.text.trim(),
      responsible: _responsibleController.text.trim(),
      dni: _dniController.text.trim(),
      contact: _contactController.text.trim(),
      email: _emailController.text.trim(),
      city: _cityController.text.trim(),
      parish: _parishController.text.trim(),
      quarter: _quarterController.text.trim(),
      neighborhood: _neighborhoodController.text.trim(),
      address: _addressController.text.trim(),
      coordinates: _coordinatesController.text.trim(),
      codeAddress: _codeAddressController.text.trim(),
      surface: double.tryParse(_surfaceController.text.trim()) ?? 0,
      fertilityPercentage:
          double.tryParse(_fertilityController.text.trim()) ?? 0,
      birthRate: double.tryParse(_birthController.text.trim()) ?? 0,
      mortalityRate: double.tryParse(_mortalityController.text.trim()) ?? 0,
      weaningPercentage: double.tryParse(_weaningController.text.trim()) ?? 0,
      litersOfMilk: double.tryParse(_litresController.text.trim()) ?? 0,
      observation: _observationController.text.trim(),
    );

    final repo = CompanyRepository();
    bool success = false;

    if (widget.company == null) {
      await repo.create(newCompany);
      success = true;
    } else {
      success = await repo.update(newCompany);
    }

    setState(() => _isLoading = false);

    if (success) {
      widget.onSave();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Empresa guardada exitosamente')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al guardar la empresa')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        widget.company == null ? 'Agregar Empresa' : 'Editar Empresa',
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Color(0xFF2C3E50),
        ),
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildField(_codeController, 'Código', Icons.code, true),
              _buildField(_nameController, 'Nombre', Icons.business, true),
              _buildField(
                _responsibleController,
                'Responsable',
                Icons.person,
                true,
              ),
              _buildField(_dniController, 'DNI', Icons.badge, true),
              _buildField(_contactController, 'Contacto', Icons.phone, true),
              _buildField(_emailController, 'Correo', Icons.email, true),
              _buildField(_cityController, 'Ciudad', Icons.location_city),
              _buildField(_parishController, 'Parroquia', Icons.map),
              _buildField(_quarterController, 'Barrio', Icons.home),
              _buildField(
                _neighborhoodController,
                'Vecindario',
                Icons.apartment,
              ),
              _buildField(
                _addressController,
                'Dirección',
                Icons.location_on,
                true,
              ),
              _buildField(_coordinatesController, 'Coordenadas', Icons.explore),
              _buildField(
                _codeAddressController,
                'Código Dirección',
                Icons.numbers,
              ),
              _buildNumericField(
                _surfaceController,
                'Superficie (ha)',
                Icons.square_foot,
              ),
              _buildNumericField(
                _fertilityController,
                'Fertilidad (%)',
                Icons.eco,
              ),
              _buildNumericField(
                _birthController,
                'Tasa de Nacimiento (%)',
                Icons.child_care,
              ),
              _buildNumericField(
                _mortalityController,
                'Tasa de Mortalidad (%)',
                Icons.warning,
              ),
              _buildNumericField(
                _weaningController,
                'Porcentaje de Destete (%)',
                Icons.pets,
              ),
              _buildNumericField(
                _litresController,
                'Litros de Leche',
                Icons.local_drink,
              ),
              _buildField(_observationController, 'Observaciones', Icons.notes),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton.icon(
          onPressed: _isLoading ? null : _saveForm,
          icon:
              _isLoading
                  ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                  : const Icon(Icons.save),
          label: const Text('Guardar'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF4CAF50),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      ],
    );
  }

  // 🔹 Campos de texto genéricos
  Widget _buildField(
    TextEditingController controller,
    String label,
    IconData icon, [
    bool required = false,
  ]) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: const OutlineInputBorder(),
        ),
        validator: (value) {
          if (required && (value == null || value.isEmpty)) {
            return 'Campo obligatorio';
          }
          return null;
        },
      ),
    );
  }

  // 🔹 Campos numéricos
  Widget _buildNumericField(
    TextEditingController controller,
    String label,
    IconData icon,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: const OutlineInputBorder(),
        ),
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
      ),
    );
  }
}
