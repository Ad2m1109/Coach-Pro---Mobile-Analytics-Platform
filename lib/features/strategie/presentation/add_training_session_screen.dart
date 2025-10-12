import 'package:flutter/material.dart';
import 'package:frontend/l10n/app_localizations.dart';
import 'package:frontend/models/training_session.dart';
import 'package:frontend/services/training_session_service.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

class AddTrainingSessionScreen extends StatefulWidget {
  const AddTrainingSessionScreen({super.key});

  @override
  State<AddTrainingSessionScreen> createState() => _AddTrainingSessionScreenState();
}

class _AddTrainingSessionScreenState extends State<AddTrainingSessionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _focusController = TextEditingController();
  final _iconNameController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _focusController.dispose();
    _iconNameController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _saveSession() async {
    final appLocalizations = AppLocalizations.of(context)!;
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      final service = Provider.of<TrainingSessionService>(context, listen: false);
      final newSession = TrainingSession(
        id: '',
        title: _titleController.text,
        date: _selectedDate,
        focus: _focusController.text,
        iconName: _iconNameController.text,
      );

      try {
        await service.createTrainingSession(newSession);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(appLocalizations.trainingSessionCreatedSuccessfully)),
        );
        Navigator.of(context).pop(true);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${appLocalizations.failedToCreateSession(e.toString())}')),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(appLocalizations.addTrainingSession),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(labelText: appLocalizations.title),
                validator: (value) => value!.isEmpty ? appLocalizations.pleaseEnterATitle : null,
              ),
              TextFormField(
                controller: _focusController,
                decoration: InputDecoration(labelText: appLocalizations.focusExample),
                validator: (value) => value!.isEmpty ? appLocalizations.pleaseEnterAFocus : null,
              ),
              TextFormField(
                controller: _iconNameController,
                decoration: InputDecoration(labelText: appLocalizations.iconNameExampleTraining),
                validator: (value) => value!.isEmpty ? appLocalizations.pleaseEnterAnIconName : null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Text("Date: ${DateFormat.yMd().format(_selectedDate)}"),
                  ),
                  TextButton(
                    onPressed: () => _selectDate(context),
                    child: Text(appLocalizations.selectDate),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _saveSession,
                      child: Text(appLocalizations.saveSession),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
