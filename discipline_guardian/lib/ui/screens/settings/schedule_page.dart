import 'package:flutter/material.dart';
import '../../../data/models/schedule_settings_model.dart';
import '../../../services/local_backend_service.dart';
import '../../widgets/anime_card.dart';
import '../../widgets/anime_button.dart';

/// 监控时段页面
class SchedulePage extends StatefulWidget {
  const SchedulePage({super.key});

  @override
  State<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage> {
  final LocalBackendService _backendService = LocalBackendService();
  late bool _isEnabled;
  late TimeOfDay _workdayStart;
  late TimeOfDay _workdayEnd;
  late TimeOfDay _weekendStart;
  late TimeOfDay _weekendEnd;
  bool _isLoading = true;
  String _scheduleId = 'default';

  @override
  void initState() {
    super.initState();
    _isEnabled = false;
    _workdayStart = const TimeOfDay(hour: 9, minute: 0);
    _workdayEnd = const TimeOfDay(hour: 22, minute: 0);
    _weekendStart = const TimeOfDay(hour: 8, minute: 0);
    _weekendEnd = const TimeOfDay(hour: 23, minute: 0);
    _loadSchedule();
  }

  Future<void> _loadSchedule() async {
    final schedule = await _backendService.getSchedule();
    if (!mounted) {
      return;
    }

    setState(() {
      _scheduleId = schedule.id;
      _isEnabled = schedule.isEnabled;
      _workdayStart = _parseTime(schedule.workdayStart);
      _workdayEnd = _parseTime(schedule.workdayEnd);
      _weekendStart = _parseTime(schedule.weekendStart);
      _weekendEnd = _parseTime(schedule.weekendEnd);
      _isLoading = false;
    });
  }

  String _formatTime(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  TimeOfDay _parseTime(String value) {
    final parts = value.split(':');
    if (parts.length != 2) {
      return const TimeOfDay(hour: 9, minute: 0);
    }

    final hour = int.tryParse(parts[0]) ?? 9;
    final minute = int.tryParse(parts[1]) ?? 0;
    return TimeOfDay(hour: hour, minute: minute);
  }

  Future<void> _saveSchedule() async {
    final model = ScheduleSettingsModel(
      id: _scheduleId,
      isEnabled: _isEnabled,
      workdayStart: _formatTime(_workdayStart),
      workdayEnd: _formatTime(_workdayEnd),
      weekendStart: _formatTime(_weekendStart),
      weekendEnd: _formatTime(_weekendEnd),
      updatedAt: DateTime.now(),
    );
    await _backendService.saveSchedule(model);
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('设置已保存')),
    );
    Navigator.pop(context);
  }

  Future<void> _selectTime(BuildContext context, TimeOfDay initialTime, Function(TimeOfDay) onSelected) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) {
        return Localizations.override(
          context: context,
          locale: const Locale('zh', 'CN'),
          child: MediaQuery(
            data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
            child: child ?? const SizedBox.shrink(),
          ),
        );
      },
    );
    if (picked != null) {
      onSelected(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF333333)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          '监控时段',
          style: TextStyle(
            color: Color(0xFF333333),
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 开关
              AnimeCard(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '启用时段限制',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF333333),
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          '仅在设定时间段内启用监控',
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF666666),
                          ),
                        ),
                      ],
                    ),
                    Switch(
                      value: _isEnabled,
                      onChanged: (value) {
                        setState(() {
                          _isEnabled = value;
                        });
                      },
                      activeThumbColor: const Color(0xFFFF6B9D),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // 工作日设置
              if (_isEnabled) ...[
                _buildSectionTitle('工作日'),
                const SizedBox(height: 12),
                _buildTimeSelector(
                  '开始时间',
                  _formatTime(_workdayStart),
                  () => _selectTime(context, _workdayStart, (time) {
                    setState(() {
                      _workdayStart = time;
                    });
                  }),
                ),
                const SizedBox(height: 12),
                _buildTimeSelector(
                  '结束时间',
                  _formatTime(_workdayEnd),
                  () => _selectTime(context, _workdayEnd, (time) {
                    setState(() {
                      _workdayEnd = time;
                    });
                  }),
                ),
                const SizedBox(height: 24),
                // 周末设置
                _buildSectionTitle('周末'),
                const SizedBox(height: 12),
                _buildTimeSelector(
                  '开始时间',
                  _formatTime(_weekendStart),
                  () => _selectTime(context, _weekendStart, (time) {
                    setState(() {
                      _weekendStart = time;
                    });
                  }),
                ),
                const SizedBox(height: 12),
                _buildTimeSelector(
                  '结束时间',
                  _formatTime(_weekendEnd),
                  () => _selectTime(context, _weekendEnd, (time) {
                    setState(() {
                      _weekendEnd = time;
                    });
                  }),
                ),
                const SizedBox(height: 32),
                // 保存按钮
                SizedBox(
                  width: double.infinity,
                  child: AnimeButton(
                    text: '保存设置',
                    onPressed: _saveSchedule,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Color(0xFF333333),
        ),
      ),
    );
  }

  Widget _buildTimeSelector(String label, String time, VoidCallback onTap) {
    return AnimeCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              color: Color(0xFF333333),
            ),
          ),
          Row(
            children: [
              Text(
                time,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFFF6B9D),
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.chevron_right,
                color: Color(0xFF999999),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
