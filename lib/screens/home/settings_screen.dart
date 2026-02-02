import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gains/providers/auth_provider.dart';
import 'package:gains/providers/user_provider.dart';
import 'package:gains/services/notification_service.dart';
import 'package:gains/models/user_models.dart';

import 'package:gains/utils/app_colors.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gains/screens/analytics/body_fat_calculator_dialog.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  // Bildirim ayarlarını tutma
  bool _notificationsExpanded = false;
  bool _notificationsEnabled = false;
  TimeOfDay _reminderTime = const TimeOfDay(hour: 18, minute: 0);

  // Kilo takibi hatırlatıcısı için gerekli değişkenler
  bool _weightReminderEnabled = false;
  int _weightReminderWeekday = 1; // Monday
  TimeOfDay _weightReminderTime = const TimeOfDay(hour: 9, minute: 0);

  // Profil düzenleme ekranı ve form alanları
  bool _editProfileExpanded = false;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadNotificationSettings();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loadNotificationSettings() async {
    // Kayıtlı bildirim tercihlerini cihazdan yükleme
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationsEnabled = prefs.getBool('notifications_enabled') ?? false;
      final hour = prefs.getInt('reminder_hour') ?? 18;
      final minute = prefs.getInt('reminder_minute') ?? 0;
      _reminderTime = TimeOfDay(hour: hour, minute: minute);

      _weightReminderEnabled =
          prefs.getBool('weight_reminder_enabled') ?? false;
      _weightReminderWeekday = prefs.getInt('weight_reminder_weekday') ?? 1;
      final wHour = prefs.getInt('weight_reminder_hour') ?? 9;
      final wMinute = prefs.getInt('weight_reminder_minute') ?? 0;
      _weightReminderTime = TimeOfDay(hour: wHour, minute: wMinute);
    });
  }

  Future<void> _saveNotificationSettings({
    bool? enabled,
    TimeOfDay? time,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    if (enabled != null) {
      await prefs.setBool('notifications_enabled', enabled);
      setState(() => _notificationsEnabled = enabled);
    }
    if (time != null) {
      await prefs.setInt('reminder_hour', time.hour);
      await prefs.setInt('reminder_minute', time.minute);
      setState(() => _reminderTime = time);
    }

    final service = NotificationService();
    if (_notificationsEnabled) {
      await service.requestPermissions();
      await service.scheduleDailyNotification(
        id: 0,
        title: 'Time to Workout! 💪',
        body: 'Consistency is key. Lets crush it today!',
        time: _reminderTime,
      );
    } else {
      await service.cancelAllNotifications();
    }
  }

  Future<void> _saveWeightReminderSettings({
    bool? enabled,
    int? weekday,
    TimeOfDay? time,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    // Tercihleri kaydedip durumu güncelleme
    if (enabled != null) {
      await prefs.setBool('weight_reminder_enabled', enabled);
      setState(() => _weightReminderEnabled = enabled);
    }
    if (weekday != null) {
      await prefs.setInt('weight_reminder_weekday', weekday);
      setState(() => _weightReminderWeekday = weekday);
    }
    if (time != null) {
      await prefs.setInt('weight_reminder_hour', time.hour);
      await prefs.setInt('weight_reminder_minute', time.minute);
      setState(() => _weightReminderTime = time);
    }

    // Hatırlatıcıyı kurma ya da iptal etme
    final service = ref.read(notificationServiceProvider);
    if (_weightReminderEnabled) {
      await service.scheduleWeeklyNotification(
        id: 100,
        title: '⚖️ Kilo Takibi Zamanı!',
        body: 'Haftalık kilonu güncelleyerek gelişimini takip et.',
        weekday: _weightReminderWeekday,
        time: _weightReminderTime,
      );
    } else {
      await service.cancelNotification(100);
    }
  }

  String _formatTimeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inDays > 7) {
      return '${date.day}/${date.month}/${date.year}';
    } else if (diff.inDays > 0) {
      return '${diff.inDays} days ago';
    } else if (diff.inHours > 0) {
      return '${diff.inHours} hours ago';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes} minutes ago';
    } else {
      return 'Just now';
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProfileAsync = ref.watch(userProfileProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundDarkBlue,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Profile',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: userProfileAsync.when(
        data: (profile) {
          // Eğer isim girilmemişse kullanıcı adını göster
          final displayName = (profile.name == 'User' || profile.name.isEmpty)
              ? profile.username
              : profile.name;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Profil resmi ve isim
                Center(
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.primaryBlue,
                            width: 2,
                          ),
                        ),
                        child: CircleAvatar(
                          radius: 50,
                          backgroundColor: AppColors.surfaceDark,
                          backgroundImage: profile.profileImageUrl != null
                              ? NetworkImage(profile.profileImageUrl!)
                              : null,
                          child: profile.profileImageUrl == null
                              ? Text(
                                  displayName.isNotEmpty
                                      ? displayName[0].toUpperCase()
                                      : '?',
                                  style: const TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                )
                              : null,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        displayName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // İstatistik Kartları
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _StatCard(
                      label: 'WEIGHT',
                      value: profile.weight != null
                          ? '${profile.weight!.toStringAsFixed(1)}kg'
                          : '--kg',
                      unit: 'kg',
                      icon: Icons.monitor_weight_outlined,
                      color: Colors.blue,
                      onTap: () => _showEditStatDialog(
                        'Weight',
                        'kg',
                        profile.weight,
                        (val) async {
                          final db = ref.read(databaseServiceProvider);
                          await db.updateUserProfileFields(weight: val);
                          // Save to history
                          await db.addBodyMeasurement(val, profile.bodyFat);
                          ref.invalidate(userProfileProvider);
                          ref.invalidate(bodyMeasurementsProvider);
                        },
                      ),
                    ),

                    const SizedBox(width: 12),
                    _StatCard(
                      label: 'BODY FAT',
                      value: profile.bodyFat != null
                          ? '${profile.bodyFat!.toStringAsFixed(1)}%'
                          : '--%',
                      unit: '%',
                      icon: Icons.accessibility_new,
                      color: Colors.orange,
                      onTap: () => _showBodyFatCalculator(
                        profile.height,
                        'male',
                        profile.weight,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // Hesap Ayarları Başlığı
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'ACCOUNT SETTINGS',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Profil Düzenleme Alanı
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E2746),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      _SettingsTile(
                        icon: Icons.person,
                        title: 'Edit Profile',
                        withContainer: false,
                        onTap: () {
                          setState(() {
                            _editProfileExpanded = !_editProfileExpanded;
                            if (_editProfileExpanded) {
                              _nameController.text = profile.name;
                              _usernameController.text = profile.username;
                            }
                          });
                        },
                        trailingIcon: _editProfileExpanded
                            ? Icons.keyboard_arrow_down
                            : Icons.keyboard_arrow_right,
                      ),
                      if (_editProfileExpanded) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Divider(
                                color: Colors.white.withValues(alpha: 0.1),
                              ),
                              const SizedBox(height: 16),
                              TextField(
                                controller: _nameController,
                                style: const TextStyle(color: Colors.white),
                                decoration: const InputDecoration(
                                  labelText: 'Full Name',
                                  labelStyle: TextStyle(
                                    color: AppColors.textSecondary,
                                  ),
                                  enabledBorder: UnderlineInputBorder(
                                    borderSide: BorderSide(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  focusedBorder: UnderlineInputBorder(
                                    borderSide: BorderSide(
                                      color: AppColors.primaryBlue,
                                    ),
                                  ),
                                  prefixIcon: Icon(
                                    Icons.badge,
                                    color: AppColors.textSecondary,
                                    size: 20,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              TextField(
                                controller: _usernameController,
                                style: const TextStyle(color: Colors.white),
                                decoration: const InputDecoration(
                                  labelText: 'Username',
                                  labelStyle: TextStyle(
                                    color: AppColors.textSecondary,
                                  ),
                                  enabledBorder: UnderlineInputBorder(
                                    borderSide: BorderSide(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  focusedBorder: UnderlineInputBorder(
                                    borderSide: BorderSide(
                                      color: AppColors.primaryBlue,
                                    ),
                                  ),
                                  prefixIcon: Icon(
                                    Icons.alternate_email,
                                    color: AppColors.textSecondary,
                                    size: 20,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              TextField(
                                controller: _passwordController,
                                obscureText: true,
                                style: const TextStyle(color: Colors.white),
                                decoration: const InputDecoration(
                                  labelText: 'New Password (Optional)',
                                  labelStyle: TextStyle(
                                    color: AppColors.textSecondary,
                                  ),
                                  enabledBorder: UnderlineInputBorder(
                                    borderSide: BorderSide(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  focusedBorder: UnderlineInputBorder(
                                    borderSide: BorderSide(
                                      color: AppColors.primaryBlue,
                                    ),
                                  ),
                                  prefixIcon: Icon(
                                    Icons.lock,
                                    color: AppColors.textSecondary,
                                    size: 20,
                                  ),
                                  helperText:
                                      'Leave empty to keep current password',
                                  helperStyle: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),
                              ElevatedButton(
                                onPressed: () async {
                                  await _saveProfileChanges(profile);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primaryBlue
                                      .withValues(alpha: 0.2),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text(
                                  'Update Profile',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // Bildirim Ayarları
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E2746),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      _SettingsTile(
                        icon: Icons.notifications,
                        title: 'Notifications',
                        withContainer: false,
                        onTap: () {
                          setState(() {
                            _notificationsExpanded = !_notificationsExpanded;
                          });
                        },
                        trailingIcon: _notificationsExpanded
                            ? Icons.keyboard_arrow_down
                            : Icons.keyboard_arrow_right,
                      ),
                      if (_notificationsExpanded) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Divider(
                                color: Colors.white.withValues(alpha: 0.1),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'DAILY WORKOUT',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SwitchListTile(
                                title: const Text(
                                  'Enable Reminder',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                  ),
                                ),
                                value: _notificationsEnabled,
                                activeTrackColor: AppColors.primaryBlue,
                                onChanged: (val) =>
                                    _saveNotificationSettings(enabled: val),
                              ),
                              if (_notificationsEnabled)
                                ListTile(
                                  title: const Text(
                                    'Time',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                    ),
                                  ),
                                  trailing: Text(
                                    _reminderTime.format(context),
                                    style: const TextStyle(
                                      color: AppColors.primaryBlue,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  onTap: () async {
                                    final picked = await showTimePicker(
                                      context: context,
                                      initialTime: _reminderTime,
                                      builder: (context, child) {
                                        return Theme(
                                          data: ThemeData.dark().copyWith(
                                            colorScheme: const ColorScheme.dark(
                                              primary: AppColors.primaryBlue,
                                              onPrimary: Colors.white,
                                              surface: AppColors.surfaceDark,
                                              onSurface: Colors.white,
                                            ),
                                          ),
                                          child: child!,
                                        );
                                      },
                                    );
                                    if (picked != null) {
                                      _saveNotificationSettings(time: picked);
                                    }
                                  },
                                ),
                              const SizedBox(height: 16),
                              const Text(
                                'WEEKLY WEIGHT',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SwitchListTile(
                                title: const Text(
                                  'Weekly Reminder',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                  ),
                                ),
                                value: _weightReminderEnabled,
                                activeTrackColor: AppColors.primaryBlue,
                                onChanged: (val) =>
                                    _saveWeightReminderSettings(enabled: val),
                              ),
                              if (_weightReminderEnabled) ...[
                                ListTile(
                                  title: const Text(
                                    'Day',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                    ),
                                  ),
                                  trailing: DropdownButton<int>(
                                    value: _weightReminderWeekday,
                                    dropdownColor: AppColors.surfaceDark,
                                    underline: const SizedBox(),
                                    style: const TextStyle(
                                      color: AppColors.primaryBlue,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    items: const [
                                      DropdownMenuItem(
                                        value: 1,
                                        child: Text("Mon"),
                                      ),
                                      DropdownMenuItem(
                                        value: 2,
                                        child: Text("Tue"),
                                      ),
                                      DropdownMenuItem(
                                        value: 3,
                                        child: Text("Wed"),
                                      ),
                                      DropdownMenuItem(
                                        value: 4,
                                        child: Text("Thu"),
                                      ),
                                      DropdownMenuItem(
                                        value: 5,
                                        child: Text("Fri"),
                                      ),
                                      DropdownMenuItem(
                                        value: 6,
                                        child: Text("Sat"),
                                      ),
                                      DropdownMenuItem(
                                        value: 7,
                                        child: Text("Sun"),
                                      ),
                                    ],
                                    onChanged: (val) {
                                      if (val != null) {
                                        _saveWeightReminderSettings(
                                          weekday: val,
                                        );
                                      }
                                    },
                                  ),
                                ),
                                ListTile(
                                  title: const Text(
                                    'Time',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                    ),
                                  ),
                                  trailing: Text(
                                    _weightReminderTime.format(context),
                                    style: const TextStyle(
                                      color: AppColors.primaryBlue,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  onTap: () async {
                                    final picked = await showTimePicker(
                                      context: context,
                                      initialTime: _weightReminderTime,
                                      builder: (context, child) {
                                        return Theme(
                                          data: ThemeData.dark().copyWith(
                                            colorScheme: const ColorScheme.dark(
                                              primary: AppColors.primaryBlue,
                                              onPrimary: Colors.white,
                                              surface: AppColors.surfaceDark,
                                              onSurface: Colors.white,
                                            ),
                                          ),
                                          child: child!,
                                        );
                                      },
                                    );
                                    if (picked != null) {
                                      _saveWeightReminderSettings(time: picked);
                                    }
                                  },
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                _SettingsTile(
                  icon: Icons.help,
                  title: 'Help & Support',
                  onTap: () {},
                ),

                const SizedBox(height: 32),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'YOUR TRANSFORMATION',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  height: 180,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceDark,
                    borderRadius: BorderRadius.circular(24),
                    image: const DecorationImage(
                      image: NetworkImage(
                        'https://images.unsplash.com/photo-1549476464-37392f717541?q=80&w=3087&auto=format&fit=crop',
                      ),
                      fit: BoxFit.cover,
                      opacity: 0.4,
                    ),
                  ),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      const Text(
                        'Current Progress',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Last update: ${_formatTimeAgo(profile.updatedAt)}',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                _SettingsTile(
                  icon: Icons.logout,
                  title: 'Log Out',
                  iconColor: AppColors.error,
                  textColor: AppColors.error,
                  onTap: () async {
                    await ref.read(authStateProvider.notifier).logout();
                    if (context.mounted) {
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        '/welcome',
                        (route) => false,
                      );
                    }
                  },
                ),
                const SizedBox(height: 32),
              ],
            ),
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primaryBlue),
        ),
        error: (err, stack) => Center(
          child: Text(
            'Error: $err',
            style: const TextStyle(color: Colors.white),
          ),
        ),
      ),
    );
  }

  Future<void> _showEditStatDialog(
    String title,
    String suffix,
    double? currentValue,
    Function(double) onSave,
  ) async {
    String value = currentValue?.toString() ?? '';
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        title: Text(
          'Update $title',
          style: const TextStyle(color: Colors.white),
        ),
        content: TextField(
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            suffixText: suffix,
            suffixStyle: const TextStyle(color: AppColors.textSecondary),
            enabledBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.textSecondary),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.primaryBlue),
            ),
          ),
          onChanged: (val) => value = val,
          controller: TextEditingController(text: value),
        ),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: const Text(
              'Save',
              style: TextStyle(color: AppColors.primaryBlue),
            ),
            onPressed: () {
              final doubleVal = double.tryParse(value);
              if (doubleVal != null) {
                onSave(doubleVal);
                Navigator.pop(context);
              }
            },
          ),
        ],
      ),
    );
  }

  Future<void> _saveProfileChanges(UserProfile profile) async {
    try {
      // İsim ve Kullanıcı Adı değişikliklerini kontrol edip kaydetme
      bool profileUpdated = false;
      String? newName;
      String? newUsername;

      if (_nameController.text.trim() != profile.name) {
        newName = _nameController.text.trim();
        profileUpdated = true;
      }
      if (_usernameController.text.trim() != profile.username) {
        newUsername = _usernameController.text.trim();
        profileUpdated = true;
      }

      if (profileUpdated) {
        await ref
            .read(databaseServiceProvider)
            .updateUserProfileFields(name: newName, username: newUsername);
      }

      // Eğer şifre alanına bir şey yazıldıysa şifreyi de güncelleme
      if (_passwordController.text.isNotEmpty) {
        await ref
            .read(authServiceProvider)
            .updatePassword(_passwordController.text);
      }

      // Kullanıcıya işlemin başarılı olduğunu bildirme
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: AppColors.primaryBlue,
          ),
        );
        setState(() {
          _editProfileExpanded = false;
          _passwordController.clear();
        });
        ref.invalidate(userProfileProvider);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating profile: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _showBodyFatCalculator(
    double? height,
    String gender,
    double? currentWeight,
  ) async {
    final result = await showDialog<double>(
      context: context,
      builder: (context) =>
          BodyFatCalculatorDialog(initialHeight: height, initialGender: gender),
    );

    if (result != null) {
      // Hesaplanan sonucu doğrudan veritabanına ve geçmişe kaydetme
      final db = ref.read(databaseServiceProvider);
      await db.updateUserProfileFields(bodyFat: result);

      if (currentWeight != null) {
        await db.addBodyMeasurement(currentWeight, result);
        ref.invalidate(bodyMeasurementsProvider);
      }

      ref.invalidate(userProfileProvider);
    }
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _StatCard({
    required this.label,
    required this.value,
    this.unit = '',
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surfaceDark,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: color, size: 20),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.edit_outlined,
                    color: AppColors.textSecondary.withValues(alpha: 0.5),
                    size: 16,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Flexible(
                    child: Text(
                      value.replaceAll(RegExp(r'[a-zA-Z%]'), ''),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 2),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 3),
                    child: Text(
                      unit.isNotEmpty
                          ? unit
                          : (value.contains('%')
                                ? '%'
                                : value.replaceAll(RegExp(r'[0-9.]'), '')),
                      style: TextStyle(
                        color: AppColors.textSecondary.withValues(alpha: 0.7),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Color? iconColor;
  final Color? textColor;
  final bool withContainer;
  final IconData? trailingIcon;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.iconColor,
    this.textColor,
    this.withContainer = true,
    this.trailingIcon,
  });

  @override
  Widget build(BuildContext context) {
    final child = Theme(
      data: Theme.of(context).copyWith(
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        hoverColor: Colors.transparent,
        splashFactory: NoSplash.splashFactory,
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        splashColor: Colors.transparent,
        hoverColor: Colors.transparent,
        focusColor: Colors.transparent,
        tileColor: Colors.transparent,
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: (iconColor ?? AppColors.primaryBlue).withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: iconColor ?? AppColors.primaryBlue,
            size: 20,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: textColor ?? Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
        trailing: Icon(
          trailingIcon ?? Icons.chevron_right,
          color: AppColors.textSecondary.withValues(alpha: 0.5),
        ),
      ),
    );

    if (withContainer) {
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF1E2746),
          borderRadius: BorderRadius.circular(20),
        ),
        child: child,
      );
    }

    return child;
  }
}
