import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import '../models/transaction_model.dart';
import '../services/notification_service.dart';
import '../utils/streak_helper.dart';

/// Kartu streak pencatatan harian + pengingat "belum catat hari ini".
/// Muncul penuh hanya bila hari ini belum ada pencatatan;
/// kalau sudah catat, tampil ringkas (streak + dots minggu).
class StreakCard extends StatefulWidget {
  final List<TransactionModel> transactions;

  const StreakCard({super.key, required this.transactions});

  @override
  State<StreakCard> createState() => _StreakCardState();
}

class _StreakCardState extends State<StreakCard> {
  bool _dismissed = false;

  Future<void> _toggleReminder(bool enabled) async {
    await NotificationService.setDailyReminder(enabled: enabled);
    if (mounted) setState(() {});
  }

  Future<void> _pickTime(TimeOfDay current) async {
    final picked = await showTimePicker(context: context, initialTime: current);
    if (picked == null) return;
    await NotificationService.setDailyReminder(
      enabled: true,
      hour: picked.hour,
      minute: picked.minute,
    );
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final streak = computeStreak(widget.transactions);

    return ValueListenableBuilder(
      valueListenable: Hive.box('settings').listenable(),
      builder: (context, Box settings, _) {
        final enabled =
            settings.get('dailyReminderEnabled', defaultValue: true) as bool? ??
            true;
        final hour =
            settings.get('dailyReminderHour', defaultValue: 20) as int? ?? 20;
        final minute =
            settings.get('dailyReminderMinute', defaultValue: 0) as int? ?? 0;
        final time = TimeOfDay(hour: hour, minute: minute);

        // Mode ringkas: sudah catat hari ini -> tampil Mini saja.
        if (streak.loggedToday || _dismissed) {
          return _compact(context, streak, textTheme);
        }

        return Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 16,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      Icons.local_fire_department_rounded,
                      size: 24,
                      color: Colors.orange.shade700,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          streak.currentStreak > 0
                              ? '${streak.currentStreak} hari beruntun!'
                              : 'Mulai streak hari ini!',
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1E293B),
                          ),
                        ),
                        Text(
                          'Kamu belum catat hari ini. Catat sekarang biar streak tidak putus.',
                          style: textTheme.bodySmall?.copyWith(
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => setState(() => _dismissed = true),
                    icon: Icon(
                      Icons.close_rounded,
                      size: 18,
                      color: Colors.grey.shade400,
                    ),
                    tooltip: 'Sembunyikan hari ini',
                    constraints: const BoxConstraints(),
                    style: IconButton.styleFrom(
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _weekDots(streak, textTheme),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pickTime(time),
                      icon: const Icon(Icons.schedule_rounded, size: 18),
                      label: Text(
                        enabled
                            ? 'Ingatkan ${time.format(context)}'
                            : 'Atur pengingat',
                        overflow: TextOverflow.ellipsis,
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: colorScheme.primary,
                        side: BorderSide(
                          color: colorScheme.primary.withOpacity(0.4),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 8,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Switch.adaptive(
                    value: enabled,
                    onChanged: _toggleReminder,
                    activeThumbColor: colorScheme.primary,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  /// Versi ringkas saat sudah catat hari ini.
  Widget _compact(
    BuildContext context,
    StreakInfo streak,
    TextTheme textTheme,
  ) {
    if (streak.currentStreak == 0 && streak.weekLogged.every((e) => !e)) {
      return const SizedBox.shrink();
    }
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.2), width: 1.5),
      ),
      child: Row(
        children: [
          Icon(
            Icons.local_fire_department_rounded,
            size: 22,
            color: Colors.orange.shade200,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${streak.currentStreak} hari beruntun',
              style: textTheme.bodyMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ...List.generate(7, (i) {
            final logged = streak.weekLogged[i];
            final isToday = i == 6;
            return Container(
              margin: const EdgeInsets.only(left: 4),
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: logged
                    ? Colors.greenAccent
                    : Colors.white.withOpacity(0.35),
                border: isToday
                    ? Border.all(color: Colors.white, width: 1.5)
                    : null,
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _weekDots(StreakInfo streak, TextTheme textTheme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(7, (i) {
        final date = streak.last7Dates[i];
        final logged = streak.weekLogged[i];
        final isToday = i == 6;
        return Expanded(
          child: Column(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: logged ? Colors.green.shade500 : Colors.grey.shade100,
                  border: isToday && !logged
                      ? Border.all(color: Colors.orange.shade400, width: 2)
                      : null,
                ),
                child: Icon(
                  logged ? Icons.check_rounded : Icons.circle_outlined,
                  size: 18,
                  color: logged ? Colors.white : Colors.grey.shade400,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                isToday ? 'Hari ini' : DateFormat('EEE', 'id_ID').format(date),
                style: textTheme.labelSmall?.copyWith(
                  color: isToday
                      ? Colors.orange.shade700
                      : Colors.grey.shade500,
                  fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                  fontSize: 10,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );
      }),
    );
  }
}
