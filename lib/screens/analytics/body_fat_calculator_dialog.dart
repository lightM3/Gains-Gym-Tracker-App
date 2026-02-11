import 'dart:math';
import 'package:flutter/material.dart';
import 'package:gains/utils/app_colors.dart';

// Vücut yağ oranı hesaplayıcı dialogu
class BodyFatCalculatorDialog extends StatefulWidget {
  final double? initialHeight;
  final String? initialGender;

  const BodyFatCalculatorDialog({
    super.key,
    this.initialHeight,
    this.initialGender,
  });

  @override
  State<BodyFatCalculatorDialog> createState() =>
      _BodyFatCalculatorDialogState();
}

class _BodyFatCalculatorDialogState extends State<BodyFatCalculatorDialog> {
  final _formKey = GlobalKey<FormState>();
  late String _gender;
  late TextEditingController _heightController;
  final _neckController = TextEditingController();
  final _waistController = TextEditingController();
  final _hipController = TextEditingController();

  double? _calculatedBodyFat;

  @override
  void initState() {
    super.initState();
    _gender = widget.initialGender == 'female' ? 'female' : 'male';
    _heightController = TextEditingController(
      text: widget.initialHeight?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _heightController.dispose();
    _neckController.dispose();
    _waistController.dispose();
    _hipController.dispose();
    super.dispose();
  }

  void _calculateBodyFat() {
    if (_formKey.currentState!.validate()) {
      final height = double.parse(_heightController.text);
      final neck = double.parse(_neckController.text);
      final waist = double.parse(_waistController.text);
      final hip = _gender == 'female'
          ? double.tryParse(_hipController.text) ?? 0
          : 0.0;

      double bodyFat;

      // ABD Donanması metoduna göre yağ oranı hesaplama
      if (_gender == 'male') {
        bodyFat =
            495 /
                (1.0324 -
                    0.19077 * (log(waist - neck) / ln10) +
                    0.15456 * (log(height) / ln10)) -
            450;
      } else {
        bodyFat =
            495 /
                (1.29579 -
                    0.35004 * (log(waist + hip - neck) / ln10) +
                    0.22100 * (log(height) / ln10)) -
            450;
      }

      setState(() {
        _calculatedBodyFat = double.parse(bodyFat.toStringAsFixed(1));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surfaceDarkBlue,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Body Fat Calculator',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.close,
                      color: AppColors.textSecondary,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'US Navy Method',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 24),

              // Gender Selection
              Row(
                children: [
                  Expanded(child: _buildGenderButton('Male', 'male')),
                  const SizedBox(width: 16),
                  Expanded(child: _buildGenderButton('Female', 'female')),
                ],
              ),
              const SizedBox(height: 24),

              _buildInputField(
                controller: _heightController,
                label: 'Height (cm)',
                icon: Icons.height,
              ),
              const SizedBox(height: 16),
              _buildInputField(
                controller: _neckController,
                label: 'Neck (cm)',
                icon: Icons.person_outline,
              ),
              const SizedBox(height: 16),
              _buildInputField(
                controller: _waistController,
                label: 'Waist (cm)',
                icon: Icons.accessibility_new,
              ),
              if (_gender == 'female') ...[
                const SizedBox(height: 16),
                _buildInputField(
                  controller: _hipController,
                  label: 'Hip (cm)',
                  icon: Icons.accessibility,
                ),
              ],

              const SizedBox(height: 32),

              if (_calculatedBodyFat != null) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceDark,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.primaryBlue.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Estimated Body Fat',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$_calculatedBodyFat%',
                        style: const TextStyle(
                          color: AppColors.primaryBlue,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context, _calculatedBodyFat);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Save to Profile',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ] else
                ElevatedButton(
                  onPressed: _calculateBodyFat,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondaryBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Calculate',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGenderButton(String label, String value) {
    final isSelected = _gender == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _gender = value;
          _calculatedBodyFat = null;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryBlue.withValues(alpha: 0.2)
              : AppColors.surfaceDark,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primaryBlue : Colors.transparent,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected
                  ? AppColors.primaryBlue
                  : AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.textSecondary),
        prefixIcon: Icon(icon, color: AppColors.textSecondary),
        filled: true,
        fillColor: AppColors.surfaceDark,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primaryBlue),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Required';
        }
        if (double.tryParse(value) == null) {
          return 'Invalid number';
        }
        return null;
      },
    );
  }
}
