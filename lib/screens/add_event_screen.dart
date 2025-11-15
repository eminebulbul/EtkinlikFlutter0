import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/api_service.dart';

class AddEventScreen extends StatefulWidget {
  const AddEventScreen({super.key});

  @override
  State<AddEventScreen> createState() => _AddEventScreenState();
}

class _AddEventScreenState extends State<AddEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _peopleCtrl = TextEditingController();
  final _imageCtrl = TextEditingController();

  DateTime? _selectedDateTime;
  bool _isSubmitting = false;
  String? _error;

  final ApiService _api = ApiService();

  @override
  void dispose() {
    _titleCtrl.dispose();
    _locationCtrl.dispose();
    _peopleCtrl.dispose();
    _imageCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final now = DateTime.now();

    final date = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: DateTime(now.year + 2),
    );

    if (!mounted) return;
    if (date == null) return;

    final time = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 19, minute: 0),
    );

    if (!mounted) return;
    if (time == null) return;

    setState(() {
      _selectedDateTime = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedDateTime == null) {
      setState(() {
        _error = "Lütfen etkinlik için bir tarih/saat seç.";
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final userIdStr = prefs.getString('auth_token');
      final userName = prefs.getString('user_name') ?? 'Flutter Kullanıcısı';

      if (userIdStr == null || userIdStr.trim().isEmpty) {
        setState(() {
          _error = "İlan açmak için önce giriş yapmalısın.";
        });
        return;
      }

      final organizerUserId = int.tryParse(userIdStr) ?? 0;
      if (organizerUserId == 0) {
        setState(() {
          _error = "Kullanıcı bilgisi okunamadı.";
        });
        return;
      }

      final title = _titleCtrl.text.trim();
      final location = _locationCtrl.text.trim();
      final peopleNeeded = _peopleCtrl.text.trim();
      final imageUrl = _imageCtrl.text.trim().isEmpty
          ? "https://via.placeholder.com/300x150.png?text=Etkinlik"
          : _imageCtrl.text.trim();

      await _api.createEvent(
        title: title,
        imageUrl: imageUrl,
        peopleNeeded: peopleNeeded,
        hostName: userName,
        hostImageUrl: "https://i.pravatar.cc/150?img=11",
        date: _selectedDateTime!,
        location: location,
        organizerUserId: organizerUserId,
      );

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Yeni Etkinlik Oluştur"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                "Yeni etkinlik ilanı ekle ✨",
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _titleCtrl,
                decoration: const InputDecoration(
                  labelText: "Etkinlik başlığı",
                  border: OutlineInputBorder(),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return "Başlık zorunlu";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _locationCtrl,
                decoration: const InputDecoration(
                  labelText: "Konum",
                  border: OutlineInputBorder(),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return "Konum zorunlu";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _peopleCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Kaç kişi aranıyor?",
                  border: OutlineInputBorder(),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return "Bu alan zorunlu";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _imageCtrl,
                decoration: const InputDecoration(
                  labelText: "Görsel URL (opsiyonel)",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: Text(
                      _selectedDateTime == null
                          ? "Tarih & saat seçilmedi"
                          : "Seçilen: "
                            "${_selectedDateTime!.day.toString().padLeft(2, '0')}."
                            "${_selectedDateTime!.month.toString().padLeft(2, '0')}."
                            "${_selectedDateTime!.year} "
                            "${_selectedDateTime!.hour.toString().padLeft(2, '0')}:"
                            "${_selectedDateTime!.minute.toString().padLeft(2, '0')}",
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: _pickDateTime,
                    icon: const Icon(Icons.calendar_month),
                    label: const Text("Tarih & saat seç"),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              if (_error != null) ...[
                Text(
                  _error!,
                  style: const TextStyle(color: Colors.red, fontSize: 13),
                ),
                const SizedBox(height: 8),
              ],

              SizedBox(
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _isSubmitting ? null : _submit,
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.check),
                  label: Text(
                    _isSubmitting ? "Kaydediliyor..." : "Etkinliği oluştur",
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
