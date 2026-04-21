import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/services/ci_service.dart';
import '../../core/services/broadcast_service.dart';
import '../../core/services/device_id_service.dart';
import '../../core/services/graduation_service.dart';
import '../../data/models/graduation_record.dart';
import '../../data/local/hive_service.dart';
import '../../data/local/entities/transaction_entity.dart';
import '../community/community_provider.dart';
import '../input/input_provider.dart';
import '../dashboard/dashboard_provider.dart';

final _historyProvider = Provider<List<TransactionEntity>>((ref) {
  final repo = ref.watch(transactionsRepositoryProvider);
  return repo.getAll();
});

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  Future<void> _publishGraduationToSupabase(
    BuildContext context,
    WidgetRef ref, {
    DashboardData? dashboard,
  }) async {
    try {
      final repo = ref.read(communityRepositoryProvider);
      final deviceId = await DeviceIdService.getOrCreate();
      final alias = GraduationService.nickname ?? '匿名清醒者';
      final title = GraduationService.generatedTitle ?? '新晋脱海者';
      final stamp = GraduationService.stampText ?? '毕业';
      final snap = GraduationService.snapshot;
      final sunkCost = dashboard?.sunkCost ??
          ((snap?['sunkCost'] as num?)?.toDouble() ?? 0.0);
      final exitType = sunkCost > 0 ? 'TRAGIC' : 'SMART';
      final totalInvestment = dashboard?.totalInvestment ??
          ((snap?['totalInvestment'] as num?)?.toDouble() ?? 0.0);
      final finalCi = dashboard?.ciValue ?? ((snap?['ci'] as num?)?.toDouble() ?? 0.0);

      final record = GraduationRecord(
        deviceId: deviceId,
        userAlias: alias,
        userTitle: title,
        exitType: exitType,
        totalInvestment: totalInvestment,
        finalCi: finalCi,
        aiSummary: stamp,
      );

      await repo.publishGraduation(record);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('已同步到脱海大厅'),
          backgroundColor: AppColors.surface,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('同步到脱海大厅失败：$e'),
          backgroundColor: AppColors.surface,
        ),
      );
    }
  }

  Future<void> _confirmGraduate(BuildContext context, WidgetRef ref) async {
    if (GraduationService.isGraduated) {
      final sync =
          await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              backgroundColor: AppColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: AppColors.border,
                  width: 1,
                ),
              ),
              title: const Text(
                '已毕业：同步到脱海大厅？',
                style: TextStyle(color: AppColors.textPrimary),
              ),
              content: const Text(
                '你已封存账单（本地）。如果之前没同步过，可将毕业昵称/头衔同步到 Supabase 脱海大厅。',
                style: TextStyle(color: AppColors.textSecondary),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text(
                    '取消',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text(
                    '同步',
                    style: TextStyle(
                      color: AppColors.income,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ) ??
          false;
      if (!context.mounted) return;
      if (sync == true) {
        await _publishGraduationToSupabase(context, ref);
      }
      return;
    }

    final confirm =
        await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: AppColors.income.withValues(alpha: 0.55),
                width: 1,
              ),
            ),
            title: const Text(
              '封存账单 / 宣布毕业',
              style: TextStyle(color: AppColors.textPrimary),
            ),
            content: const Text(
              '这会冻结当前记账数据快照，并生成带盖章的“最终体检单”。同时会产生一条匿名广播。',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text(
                  '取消',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text(
                  '宣布',
                  style: TextStyle(
                    color: AppColors.income,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ) ??
        false;
    if (!context.mounted) return;

    if (confirm != true) return;

    final nickname = await Navigator.of(context).push<String?>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => const _GraduationSignaturePage(),
      ),
    );
    if (!context.mounted) return;

    final dashboard = ref.read(dashboardNotifierProvider);
    final txs = ref.read(transactionsRepositoryProvider).getAll();
    await GraduationService.graduate(
      dashboard: dashboard,
      transactions: txs,
      nickname: nickname,
    );
    if (!context.mounted) return;
    await _publishGraduationToSupabase(context, ref, dashboard: dashboard);
    if (!context.mounted) return;
    ref.invalidate(dashboardNotifierProvider);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('已生成最终体检单'),
        backgroundColor: AppColors.surface,
      ),
    );
    context.push('/report');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactions = ref.watch(_historyProvider);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: null,
          bottom: const TabBar(
            dividerColor: Colors.transparent,
            tabs: [
              Tab(icon: Icon(Icons.receipt_long_outlined)),
              Tab(text: '脱海大厅'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => ref.invalidate(_historyProvider),
              child: const Text(
                '刷新',
                style: TextStyle(color: AppColors.expense),
              ),
            ),
          ],
        ),
        body: ValueListenableBuilder(
          valueListenable: HiveService.meta.listenable(
            keys: const [
              'graduatedAt',
              'graduationNickname',
              'graduationGeneratedTitle',
              'graduationSnapshot',
            ],
          ),
          builder: (context, box, child) {
            final locked = GraduationService.isGraduated;
            return TabBarView(
              children: [
                _MyLedgerTab(
                  transactions: transactions,
                  locked: locked,
                  onGraduate: () => _confirmGraduate(context, ref),
                ),
                const _HallOfClarityTab(),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _MyLedgerTab extends ConsumerWidget {
  final List<TransactionEntity> transactions;
  final bool locked;
  final VoidCallback onGraduate;

  const _MyLedgerTab({
    required this.transactions,
    required this.locked,
    required this.onGraduate,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Stack(
      children: [
        Column(
          children: [
            ValueListenableBuilder(
              valueListenable: HiveService.broadcasts.listenable(
                keys: const ['items'],
              ),
              builder: (context, box, child) {
                final messages = BroadcastService.getOrSample();
                return _BroadcastMarqueeBar(messages: messages);
              },
            ),
            Expanded(
              child: transactions.isEmpty
                  ? _EmptyHistory()
                  : _HistoryList(transactions: transactions, ref: ref),
            ),
            const SizedBox(height: 84),
          ],
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(
                  top: BorderSide(color: AppColors.border, width: 1),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.surfaceElevated,
                        foregroundColor: AppColors.textPrimary,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () => context.push('/report'),
                      child: Text(
                        '生成体检单',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.income,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        if (locked) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('已毕业：账单已封存'),
                              backgroundColor: AppColors.surface,
                            ),
                          );
                          return;
                        }
                        onGraduate();
                      },
                      child: Text(
                        locked ? '已毕业' : '宣布毕业',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _HallOfClarityTab extends ConsumerStatefulWidget {
  const _HallOfClarityTab();

  @override
  ConsumerState<_HallOfClarityTab> createState() => _HallOfClarityTabState();
}

class _HallOfClarityTabState extends ConsumerState<_HallOfClarityTab> {
  final Map<String, _HallReactions> _reactions = {};
  List<GraduationRecord> _remote = const [];
  bool _loading = true;
  Object? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    List<GraduationRecord>? list;
    Object? error;
    try {
      list = await ref
          .read(communityRepositoryProvider)
          .fetchHallOfClarity()
          .timeout(const Duration(seconds: 10));
    } catch (e) {
      error = e;
    }

    if (!mounted) return;
    setState(() {
      _loading = false;
      _error = error;
      if (list != null) _remote = list;
    });
  }

  _HallEntry _toEntry(GraduationRecord r) {
    return _HallEntry(
      id: r.id,
      nickname: r.userAlias,
      generatedTitle: r.userTitle,
      at: r.createdAt ?? DateTime.now(),
      days: 0,
      stopLoss: 0,
      ci: r.finalCi,
      totalInvestment: r.totalInvestment,
      totalWaitHours: 0,
      cheersCount: r.cheersCount,
      hugCount: r.hugCount,
      warningCount: r.warningCount,
    );
  }

  String _keyOf(_HallEntry entry) =>
      entry.id ??
      '${entry.generatedTitle}|${entry.nickname}|${entry.at.toIso8601String()}';

  Future<void> _interact(_HallEntry entry, String type) async {
    final key = _keyOf(entry);
    setState(() {
      final v = _reactions[key] ?? const _HallReactions();
      _reactions[key] = switch (type) {
        'cheers' => v.copyWith(cheers: v.cheers + 1),
        'hug' => v.copyWith(hug: v.hug + 1),
        'warning' => v.copyWith(warning: v.warning + 1),
        _ => v,
      };
    });

    final id = entry.id;
    if (id == null || id.isEmpty) return;

    try {
      await ref.read(communityRepositoryProvider).interact(id, type);
      final list = await ref.read(communityRepositoryProvider).fetchHallOfClarity();
      if (!mounted) return;
      setState(() {
        _remote = list;
        _reactions.remove(key);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _reactions.remove(key));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('互动失败：$e'),
          backgroundColor: AppColors.surface,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final remoteEntries = _remote.map(_toEntry).toList(growable: false);
    final items = remoteEntries;

    final list = ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: items.isEmpty ? 1 : items.length + (_loading || _error != null ? 1 : 0),
      itemBuilder: (context, index) {
        if (items.isEmpty) {
          final text = _loading
              ? '加载脱海大厅…'
              : _error != null
                  ? '脱海大厅加载失败：${_error ?? ''}'
                  : '脱海大厅暂无记录';
          return Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(
              text,
              style: const TextStyle(fontSize: 12, color: AppColors.textTertiary),
            ),
          );
        }

        if (index == 0 && (_loading || _error != null)) {
          final text = _loading ? '加载脱海大厅…' : '脱海大厅加载失败：${_error ?? ''}';
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(
              text,
              style: const TextStyle(fontSize: 12, color: AppColors.textTertiary),
            ),
          );
        }

        final item = items[index - (_loading || _error != null ? 1 : 0)];
        final key = _keyOf(item);
        final current = _reactions[key] ?? const _HallReactions();
        final hydrated = item.copyWith(
          cheersCount: item.cheersCount + current.cheers,
          hugCount: item.hugCount + current.hug,
          warningCount: item.warningCount + current.warning,
        );
        return _HallCard(
          entry: hydrated,
          onCheers: () => _interact(item, 'cheers'),
          onHug: () => _interact(item, 'hug'),
          onWarning: () => _interact(item, 'warning'),
        );
      },
    );

    return RefreshIndicator(
      onRefresh: _load,
      child: list,
    );
  }
}

enum GraduationType { smart, tragic }

class _HallReactions {
  final int cheers;
  final int hug;
  final int warning;

  const _HallReactions({
    this.cheers = 0,
    this.hug = 0,
    this.warning = 0,
  });

  _HallReactions copyWith({int? cheers, int? hug, int? warning}) {
    return _HallReactions(
      cheers: cheers ?? this.cheers,
      hug: hug ?? this.hug,
      warning: warning ?? this.warning,
    );
  }
}

class _HallEntry {
  final String? id;
  final String nickname;
  final String generatedTitle;
  final DateTime at;
  final int days;
  final double stopLoss;
  final double ci;
  final double totalInvestment;
  final double totalWaitHours;
  int cheersCount;
  int hugCount;
  int warningCount;

  _HallEntry({
    this.id,
    required this.nickname,
    required this.generatedTitle,
    required this.at,
    required this.days,
    required this.stopLoss,
    required this.ci,
    required this.totalInvestment,
    required this.totalWaitHours,
    required this.cheersCount,
    required this.hugCount,
    required this.warningCount,
  });

  GraduationType get graduationType {
    if (totalInvestment > 2000 || totalWaitHours > 50) {
      return GraduationType.tragic;
    }
    return GraduationType.smart;
  }

  _HallEntry copyWith({
    int? cheersCount,
    int? hugCount,
    int? warningCount,
  }) {
    return _HallEntry(
      id: id,
      nickname: nickname,
      generatedTitle: generatedTitle,
      at: at,
      days: days,
      stopLoss: stopLoss,
      ci: ci,
      totalInvestment: totalInvestment,
      totalWaitHours: totalWaitHours,
      cheersCount: cheersCount ?? this.cheersCount,
      hugCount: hugCount ?? this.hugCount,
      warningCount: warningCount ?? this.warningCount,
    );
  }
}

class _HallCard extends StatelessWidget {
  final _HallEntry entry;
  final VoidCallback onCheers;
  final VoidCallback onHug;
  final VoidCallback onWarning;

  const _HallCard({
    required this.entry,
    required this.onCheers,
    required this.onHug,
    required this.onWarning,
  });

  @override
  Widget build(BuildContext context) {
    final atText = DateFormat('M/d HH:mm').format(entry.at);
    final stopLossText = entry.stopLoss <= 0
        ? '总止损: ¥0'
        : '总止损: ¥${entry.stopLoss.toStringAsFixed(0)}';
    final ciText = '离岸 CI: ${entry.ci.toStringAsFixed(2)}';
    final daysText = '耗时: ${entry.days} 天';

    final isTragic = entry.graduationType == GraduationType.tragic;
    final headerTag = isTragic ? '🩸 惨烈脱海' : '🎖️ 及时止损';
    final headerColor = isTragic ? Colors.redAccent : const Color(0xFFBFA46B);
    final gradient = isTragic
        ? const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1A0505), Color(0xFF0E0E11)],
          )
        : LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.greenAccent.withValues(alpha: 0.05),
              const Color(0xFF0E0E11),
            ],
          );
    final borderColor = isTragic
        ? Colors.redAccent.withValues(alpha: 0.3)
        : const Color(0xFFBFA46B).withValues(alpha: 0.28);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: headerColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: headerColor.withValues(alpha: 0.28),
                  ),
                ),
                child: Text(
                  headerTag,
                  style: GoogleFonts.robotoMono(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.1,
                    color: headerColor.withValues(alpha: 0.95),
                  ),
                ),
              ),
              const Spacer(),
              Text(
                atText,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textTertiary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            entry.nickname,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
              height: 1.05,
              letterSpacing: -0.3,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            entry.generatedTitle,
            style: GoogleFonts.robotoMono(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.1,
              color: Colors.white.withValues(alpha: 0.65),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              _MiniPill(text: stopLossText),
              _MiniPill(text: daysText),
              _MiniPill(text: ciText),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _HallActionChip(
                label:
                    '${isTragic ? '🫂 抱抱' : '🥂 沾喜气'} (${isTragic ? entry.hugCount : entry.cheersCount})',
                color: isTragic ? const Color(0xFFFFB26B) : Colors.greenAccent,
                onTap: isTragic ? onHug : onCheers,
              ),
              const SizedBox(width: 10),
              _HallActionChip(
                label: '🤡 引以为戒 (${entry.warningCount})',
                color: Colors.redAccent,
                onTap: onWarning,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HallActionChip extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _HallActionChip({
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      onPressed: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      backgroundColor: color.withValues(alpha: 0.12),
      side: BorderSide(color: color.withValues(alpha: 0.28)),
      label: Text(label),
      labelStyle: TextStyle(
        fontSize: 12,
        color: Colors.white.withValues(alpha: 0.85),
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _MiniPill extends StatelessWidget {
  final String text;
  const _MiniPill({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        text,
        style: GoogleFonts.robotoMono(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppColors.textTertiary,
        ),
      ),
    );
  }
}

class _BroadcastMarqueeBar extends StatelessWidget {
  final List<String> messages;
  const _BroadcastMarqueeBar({required this.messages});

  @override
  Widget build(BuildContext context) {
    if (messages.isEmpty) return const SizedBox.shrink();
    final text = messages.join('   ·   ');
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface.withAlpha(220),
        border: const Border(
          bottom: BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      child: _MarqueeText(
        text: text,
        style: GoogleFonts.robotoMono(
          fontSize: 11,
          color: AppColors.textTertiary,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

class _MarqueeText extends StatefulWidget {
  final String text;
  final TextStyle style;
  const _MarqueeText({required this.text, required this.style});

  @override
  State<_MarqueeText> createState() => _MarqueeTextState();
}

class _MarqueeTextState extends State<_MarqueeText>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
    )..repeat();
  }

  @override
  void didUpdateWidget(covariant _MarqueeText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      _controller
        ..stop()
        ..reset()
        ..repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double _measureTextWidth(BuildContext context) {
    final tp = TextPainter(
      text: TextSpan(text: widget.text, style: widget.style),
      textDirection: Directionality.of(context),
      maxLines: 1,
    )..layout();
    return tp.width;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final textW = _measureTextWidth(context);
        if (textW <= w) {
          return Text(widget.text, style: widget.style, maxLines: 1);
        }

        final travel = textW + w + 24; // add a small gap before repeating
        return ClipRect(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              final dx = w - (_controller.value * travel);
              return Transform.translate(
                offset: Offset(dx, 0),
                child: Text(widget.text, style: widget.style, maxLines: 1),
              );
            },
          ),
        );
      },
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('📋', style: const TextStyle(fontSize: 48)),
          const SizedBox(height: 16),
          Text(
            '暂无记录',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '在「记一笔」记录你的第一笔投入',
            style: const TextStyle(fontSize: 13, color: AppColors.textTertiary),
          ),
        ],
      ),
    );
  }
}

class _HistoryList extends ConsumerWidget {
  final List<TransactionEntity> transactions;
  final WidgetRef ref;

  const _HistoryList({required this.transactions, required this.ref});

  Map<String, Map<String, List<TransactionEntity>>> _groupByMonthAndDay() {
    final result = <String, Map<String, List<TransactionEntity>>>{};
    for (final tx in transactions) {
      final month = DateFormat('yyyy年M月', 'zh_CN').format(tx.timestamp);
      final day = DateFormat('M月d日 E', 'zh_CN').format(tx.timestamp);
      result.putIfAbsent(month, () => {});
      result[month]!.putIfAbsent(day, () => []);
      result[month]![day]!.add(tx);
    }
    return result;
  }

  double _monthTotal(
    Map<String, List<TransactionEntity>> dayMap,
    bool isExpense,
    Map<String, _ReturnDecayState> decayStates,
  ) {
    double total = 0;
    for (final dayTxs in dayMap.values) {
      for (final tx in dayTxs) {
        if (isExpense && tx.type != TransactionType.return_) {
          total += tx.totalValue;
        } else if (!isExpense && tx.type == TransactionType.return_) {
          final decay = decayStates[tx.id];
          final highLeverage =
              tx.returnCategoryV2 == ReturnCategoryV2.intimacy ||
              tx.returnCategoryV2 == ReturnCategoryV2.emotionalValue;
          total += (highLeverage && decay == _ReturnDecayState.decayed)
              ? 0.0
              : tx.totalValue;
        }
      }
    }
    return total;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locked = GraduationService.isGraduated;
    final now = DateTime.now();
    final frictionTimes = transactions
        .where((t) => t.type == TransactionType.timeFriction)
        .map((t) => t.timestamp)
        .toList();

    final decayStates = <String, _ReturnDecayState>{};
    for (final tx in transactions) {
      if (tx.type != TransactionType.return_) continue;
      final highLeverage =
          tx.returnCategoryV2 == ReturnCategoryV2.intimacy ||
          tx.returnCategoryV2 == ReturnCategoryV2.emotionalValue;
      if (!highLeverage) continue;

      final activeUntil = tx.timestamp.add(const Duration(hours: 24));
      final hasFrictionInWindow = frictionTimes.any(
        (t) => t.isAfter(tx.timestamp) && t.isBefore(activeUntil),
      );
      final state = now.isAfter(activeUntil) || hasFrictionInWindow
          ? _ReturnDecayState.decayed
          : _ReturnDecayState.active;
      if (tx.id.isNotEmpty) decayStates[tx.id] = state;
    }

    final grouped = _groupByMonthAndDay();
    final months = grouped.keys.toList();

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      itemCount: months.length,
      itemBuilder: (context, mIdx) {
        final month = months[mIdx];
        final dayMap = grouped[month]!;
        final days = dayMap.keys.toList();
        final totalExpense = _monthTotal(dayMap, true, decayStates);
        final totalIncome = _monthTotal(dayMap, false, decayStates);

        return _MonthSection(
          month: month,
          totalExpense: totalExpense,
          totalIncome: totalIncome,
          days: days,
          dayMap: dayMap,
          decayStates: decayStates,
          onDelete: (tx) {
            if (locked) return;
            // 回滚 CI
            CIService.rollbackTransaction(tx);
            // 删除记录
            ref.read(transactionsRepositoryProvider).delete(tx.id);
            ref.invalidate(_historyProvider);
            ref.invalidate(dashboardNotifierProvider);
          },
          locked: locked,
        );
      },
    );
  }
}

class _MonthSection extends StatefulWidget {
  final String month;
  final double totalExpense;
  final double totalIncome;
  final List<String> days;
  final Map<String, List<TransactionEntity>> dayMap;
  final Map<String, _ReturnDecayState> decayStates;
  final void Function(TransactionEntity) onDelete;
  final bool locked;

  const _MonthSection({
    required this.month,
    required this.totalExpense,
    required this.totalIncome,
    required this.days,
    required this.dayMap,
    required this.decayStates,
    required this.onDelete,
    required this.locked,
  });

  @override
  State<_MonthSection> createState() => _MonthSectionState();
}

class _MonthSectionState extends State<_MonthSection> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Month header
        GestureDetector(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      _expanded
                          ? Icons.keyboard_arrow_down
                          : Icons.keyboard_arrow_right,
                      size: 18,
                      color: AppColors.textTertiary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      widget.month,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Text(
                      '-${formatCurrency(widget.totalExpense)}',
                      style: GoogleFonts.robotoMono(
                        fontSize: 12,
                        color: AppColors.expense,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '+${formatCurrency(widget.totalIncome)}',
                      style: GoogleFonts.robotoMono(
                        fontSize: 12,
                        color: AppColors.income,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        if (_expanded)
          ...widget.days.map((day) {
            final txs = widget.dayMap[day]!;
            return _DaySection(
              day: day,
              transactions: txs,
              decayStates: widget.decayStates,
              onDelete: widget.onDelete,
              locked: widget.locked,
            );
          }),

        const SizedBox(height: 8),
      ],
    );
  }
}

class _DaySection extends StatelessWidget {
  final String day;
  final List<TransactionEntity> transactions;
  final Map<String, _ReturnDecayState> decayStates;
  final void Function(TransactionEntity) onDelete;
  final bool locked;

  const _DaySection({
    required this.day,
    required this.transactions,
    required this.decayStates,
    required this.onDelete,
    required this.locked,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 4, 4, 6),
          child: Text(
            day,
            style: const TextStyle(fontSize: 12, color: AppColors.textTertiary),
          ),
        ),
        ...transactions.map(
          (tx) => _TxRow(
            tx: tx,
            decayState: decayStates[tx.id],
            onDelete: onDelete,
            locked: locked,
          ),
        ),
        const SizedBox(height: 4),
      ],
    );
  }
}

enum _ReturnDecayState { active, decayed }

class _TxRow extends StatelessWidget {
  final TransactionEntity tx;
  final _ReturnDecayState? decayState;
  final void Function(TransactionEntity) onDelete;
  final bool locked;

  const _TxRow({
    required this.tx,
    required this.decayState,
    required this.onDelete,
    required this.locked,
  });

  bool get _isAiVerdict => tx.type == TransactionType.aiVerdict;
  bool get _isHighLeverageReturn =>
      tx.type == TransactionType.return_ &&
      (tx.returnCategoryV2 == ReturnCategoryV2.intimacy ||
          tx.returnCategoryV2 == ReturnCategoryV2.emotionalValue);

  bool get _isDecayed =>
      _isHighLeverageReturn && decayState == _ReturnDecayState.decayed;
  bool get _isOtherNotePromoted {
    final note = (tx.note ?? '').trim();
    if (note.isEmpty) return false;
    return tx.expenseCategoryV2 == ExpenseCategoryV2.other ||
        tx.returnCategoryV2 == ReturnCategoryV2.other;
  }

  String get _title {
    // v2.9.1: OTHER 分类时，强制提升备注为主标题
    final note = (tx.note ?? '').trim();
    if (note.isNotEmpty &&
        (tx.expenseCategoryV2 == ExpenseCategoryV2.other ||
            tx.returnCategoryV2 == ReturnCategoryV2.other)) {
      return note;
    }

    // 根据类型显示不同标题
    switch (tx.type) {
      case TransactionType.expense:
        return _expenseSubCategoryLabel;
      case TransactionType.labor:
        return _laborSubCategoryLabel;
      case TransactionType.return_:
        if (tx.returnCategoryV2 == ReturnCategoryV2.intimacy) {
          return switch (tx.intimacyAction) {
            IntimacyAction.handHold => '主动牵手',
            IntimacyAction.hug => '主动拥抱',
            IntimacyAction.kiss => '亲吻',
            _ => '亲密接触',
          };
        }
        if (tx.returnCategoryV2 == ReturnCategoryV2.emotionalValue) {
          return switch (tx.emotionalValueAction) {
            EmotionalValueAction.sweetTalk => '说了句好听的',
            EmotionalValueAction.activeCare => '突然关心你',
            EmotionalValueAction.apology => '主动道歉',
            _ => '情绪甜头',
          };
        }
        return _returnCategoryLabel;
      case TransactionType.aiVerdict:
        return '💔 Crush 粉碎机';
      case TransactionType.timeFriction:
        return '时间磨损';
    }
  }

  String get _expenseSubCategoryLabel {
    switch (tx.expenseSubCategory) {
      case ExpenseSubCategory.jewelryBags:
        return '首饰包包';
      case ExpenseSubCategory.digitalGear:
        return '数码外设';
      case ExpenseSubCategory.flowersHandmade:
        return '鲜花手工';
      case ExpenseSubCategory.fineDining:
        return '高档餐饮';
      case ExpenseSubCategory.movieShow:
        return '电影演出';
      case ExpenseSubCategory.escapeBoard:
        return '密室桌游';
      case ExpenseSubCategory.clearCart:
        return '清空购物车';
      case ExpenseSubCategory.holidayRedPacket:
        return '节日红包';
      case ExpenseSubCategory.payBills:
        return '帮还账单';
      default:
        return '花钱';
    }
  }

  String get _laborSubCategoryLabel {
    switch (tx.laborSubCategory) {
      case LaborSubCategory.lateNightComfort:
        return '深夜树洞安慰';
      case LaborSubCategory.breakIce:
        return '吵架主动破冰';
      case LaborSubCategory.prepareSurprise:
        return '精心准备惊喜';
      case LaborSubCategory.errandsPickup:
        return '跑腿接送';
      case LaborSubCategory.movingCleaning:
        return '搬家打扫';
      case LaborSubCategory.queueBuying:
        return '排队代买';
      case LaborSubCategory.longWaiting:
        return '单方面漫长等待';
      case LaborSubCategory.boringActivity:
        return '陪做不感兴趣的事';
      default:
        return '出力';
    }
  }

  String get _returnCategoryLabel {
    switch (tx.returnCategory) {
      case ReturnCategory.material:
        return _returnSubCategoryLabel;
      case ReturnCategory.emotional:
        return _returnSubCategoryLabel;
      case ReturnCategory.action:
        return _returnSubCategoryLabel;
      default:
        return '回馈';
    }
  }

  String get _returnSubCategoryLabel {
    switch (tx.returnSubCategory) {
      case ReturnSubCategory.receivedGift:
        return '收到礼物';
      case ReturnSubCategory.treatMeal:
        return '对方买单';
      case ReturnSubCategory.moneyTransfer:
        return '资金转账';
      case ReturnSubCategory.deepTalk:
        return '走心沟通';
      case ReturnSubCategory.emotionalSupport:
        return '情绪支持';
      case ReturnSubCategory.surprise:
        return '制造惊喜';
      case ReturnSubCategory.shareTask:
        return '分担任务';
      case ReturnSubCategory.dedicatedTime:
        return '专属陪伴';
      default:
        return '回馈';
    }
  }

  IconData get _typeIcon {
    switch (tx.type) {
      case TransactionType.expense:
        return Icons.payments_outlined;
      case TransactionType.labor:
        return Icons.access_time_outlined;
      case TransactionType.return_:
        return Icons.card_giftcard_outlined;
      case TransactionType.aiVerdict:
        return Icons.gavel_rounded;
      case TransactionType.timeFriction:
        return Icons.hourglass_bottom_rounded;
    }
  }

  Color get _color {
    switch (tx.type) {
      case TransactionType.expense:
      case TransactionType.labor:
        return AppColors.expense;
      case TransactionType.return_:
        return AppColors.income;
      case TransactionType.aiVerdict:
        return Colors.redAccent;
      case TransactionType.timeFriction:
        return AppColors.warning;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isAiVerdict) {
      final perfunctory = (tx.crushPerfunctory ?? tx.verdictScore ?? 0.0).clamp(
        0.0,
        100.0,
      );
      final delusion = (tx.crushDelusion ?? (100.0 - perfunctory)).clamp(
        0.0,
        100.0,
      );
      final shatter = (tx.crushShatter ?? (perfunctory * 0.9)).clamp(
        0.0,
        100.0,
      );
      final label = perfunctory >= 85
          ? '滤镜粉碎'
          : (perfunctory >= 70 ? '开始裂痕' : '可疑上头');
      final diagnosis = (tx.diagnosisText ?? '（无诊断正文）').trim();
      final impact =
          tx.actionTaken ??
          (tx.ciDelta == null
              ? 'CI ±0.0'
              : (tx.ciDelta! == 0
                    ? 'CI ±0.0'
                    : (tx.ciDelta! > 0
                          ? 'CI +${tx.ciDelta!.toStringAsFixed(2)}'
                          : 'CI ${tx.ciDelta!.toStringAsFixed(2)}')));

      final content = Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1A0505), Color(0xFF120708)],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.redAccent.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.heart_broken_rounded,
                        size: 14,
                        color: Colors.redAccent,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'CRUSH 粉碎机报告',
                        style: GoogleFonts.robotoMono(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                          color: Colors.white.withValues(alpha: 0.92),
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Text(
                  DateFormat('HH:mm').format(tx.timestamp),
                  style: const TextStyle(fontSize: 11, color: Colors.white70),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              '判定: $label',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: Colors.redAccent.withValues(alpha: 0.95),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _AiVerdictMetricChip(label: '脑补浓度', value: delusion),
                const SizedBox(width: 8),
                _AiVerdictMetricChip(
                  label: '敷衍指数',
                  value: perfunctory,
                  accent: Colors.redAccent,
                ),
                const SizedBox(width: 8),
                _AiVerdictMetricChip(
                  label: '滤镜破碎',
                  value: shatter,
                  accent: Colors.orangeAccent.withValues(alpha: 0.95),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              diagnosis,
              style: const TextStyle(
                fontSize: 13,
                height: 1.4,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '📉 清醒指数（CI）影响：$impact',
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withValues(alpha: 0.7),
              ),
            ),
            if ((tx.note ?? '').trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                tx.note!.trim(),
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.white.withValues(alpha: 0.55),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      );

      if (locked) return content;
      return Dismissible(
        key: Key('tx_${tx.id}'),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          decoration: BoxDecoration(
            color: AppColors.income.withAlpha(30),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.delete_outline,
            color: AppColors.income,
            size: 22,
          ),
        ),
        confirmDismiss: (dir) async {
          return await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: AppColors.surface,
                  title: const Text(
                    '删除记录',
                    style: TextStyle(color: AppColors.textPrimary),
                  ),
                  content: const Text(
                    '确定删除这条记录？',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text(
                        '取消',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text(
                        '删除',
                        style: TextStyle(color: AppColors.income),
                      ),
                    ),
                  ],
                ),
              ) ??
              false;
        },
        onDismissed: (_) => onDelete(tx),
        child: content,
      );
    }

    final content = Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _isDecayed ? AppColors.surfaceVariant : AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _isHighLeverageReturn
              ? (_isDecayed
                    ? AppColors.border
                    : AppColors.income.withValues(alpha: 0.35))
              : AppColors.border,
        ),
        boxShadow: _isHighLeverageReturn && !_isDecayed
            ? [
                BoxShadow(
                  color: AppColors.income.withValues(alpha: 0.25),
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                ),
              ]
            : null,
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _color.withAlpha(15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(_typeIcon, size: 18, color: _color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (_isDecayed)
                  const Text(
                    '药效已过，滤镜破碎，账本赤字已回滚',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textTertiary,
                      decoration: TextDecoration.lineThrough,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                if (!_isOtherNotePromoted && (tx.note ?? '').trim().isNotEmpty)
                  Text(
                    tx.note!.trim(),
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textTertiary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                if (tx.type == TransactionType.labor &&
                    tx.laborDurationHours > 0)
                  Text(
                    '${tx.laborDurationHours.toStringAsFixed(1)}h × ${formatCurrency(tx.hourlyRateSnapshot)}/h × ${tx.weight}x',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textTertiary,
                    ),
                  ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${tx.type == TransactionType.return_ ? '+' : '-'}${formatCurrency(_isDecayed ? 0.0 : tx.totalValue)}',
                style: GoogleFonts.robotoMono(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: _isDecayed ? AppColors.textTertiary : _color,
                ),
              ),
              Text(
                DateFormat('HH:mm').format(tx.timestamp),
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textTertiary,
                ),
              ),
            ],
          ),
        ],
      ),
    );

    if (locked) return content;

    return Dismissible(
      key: Key('tx_${tx.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.income.withAlpha(30),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(
          Icons.delete_outline,
          color: AppColors.income,
          size: 22,
        ),
      ),
      confirmDismiss: (dir) async {
        return await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                backgroundColor: AppColors.surface,
                title: const Text(
                  '删除记录',
                  style: TextStyle(color: AppColors.textPrimary),
                ),
                content: const Text(
                  '确定删除这条记录？',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text(
                      '取消',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text(
                      '删除',
                      style: TextStyle(color: AppColors.income),
                    ),
                  ),
                ],
              ),
            ) ??
            false;
      },
      onDismissed: (_) => onDelete(tx),
      child: content,
    );
  }
}

class _AiVerdictMetricChip extends StatelessWidget {
  final String label;
  final double value;
  final Color? accent;

  const _AiVerdictMetricChip({
    required this.label,
    required this.value,
    this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final color = accent ?? Colors.white.withValues(alpha: 0.85);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Colors.white.withValues(alpha: 0.7),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '${value.toStringAsFixed(0)}%',
            style: GoogleFonts.robotoMono(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _GraduationSignaturePage extends StatefulWidget {
  const _GraduationSignaturePage();

  @override
  State<_GraduationSignaturePage> createState() =>
      _GraduationSignaturePageState();
}

class _GraduationSignaturePageState extends State<_GraduationSignaturePage> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _finish({required bool skip}) {
    final value = _controller.text.trim();
    if (skip || value.isEmpty) {
      Navigator.pop(context, null);
      return;
    }
    Navigator.pop(context, value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: Center(
                child: Text(
                  'CLARITY',
                  style: GoogleFonts.robotoMono(
                    fontSize: 64,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 8,
                    color: AppColors.textPrimary.withAlpha(10),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => _finish(skip: true),
                        icon: const Icon(
                          Icons.close,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () => _finish(skip: true),
                        child: const Text(
                          '跳过',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Text(
                    '恭喜脱海',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.6,
                      height: 1.05,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '请签署你的重生代号，它将出现在你的终极体检单上。',
                    style: const TextStyle(
                      fontSize: 13,
                      height: 1.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      maxLength: 8,
                      textInputAction: TextInputAction.done,
                      style: GoogleFonts.robotoMono(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                      decoration: const InputDecoration(
                        counterText: '',
                        border: InputBorder.none,
                        hintText: '匿名清醒者',
                        hintStyle: TextStyle(
                          color: AppColors.textQuaternary,
                          fontSize: 18,
                        ),
                      ),
                      onSubmitted: (_) => _finish(skip: false),
                    ),
                  ),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.income,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () => _finish(skip: false),
                      child: Text(
                        '签署并生成体检单',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    '跳过不填将默认显示为「匿名清醒者」。',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
