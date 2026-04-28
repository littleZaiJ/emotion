import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/ai_verdict_service.dart';
import '../../core/services/graduation_service.dart';
import '../../core/utils/formatters.dart';
import '../../core/constants/longcat_config.dart';
import '../../data/local/entities/transaction_entity.dart';
import '../settings/settings_provider.dart';
import 'input_provider.dart';

class TransactionInputSheet extends ConsumerStatefulWidget {
  const TransactionInputSheet({super.key});

  @override
  ConsumerState<TransactionInputSheet> createState() =>
      _TransactionInputSheetState();
}

class _TransactionInputSheetState extends ConsumerState<TransactionInputSheet> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  TransactionType? _prevType;

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final form = ref.watch(addTransactionControllerProvider);
    final settingsAsync = ref.watch(settingsNotifierProvider);
    final hourlyRate = settingsAsync.hourlyRate;

    // 切换类型时重置输入框
    if (_prevType != form.type) {
      _amountController.clear();
      _noteController.clear();
      _prevType = form.type;
    }

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.92,
      minChildSize: 0.55,
      maxChildSize: 0.96,
      builder: (context, scrollController) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            decoration: const BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: SafeArea(
              top: false,
              child: SingleChildScrollView(
                controller: scrollController,
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Handle
                    Center(
                      child: Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.border,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const Gap(16),

                    // Title
                    Text(
                      '记一笔',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const Gap(16),

                    // Type selector
                    _TypeSelector(form: form),
                    const Gap(16),

                    // Content based on type
                    switch (form.type) {
                      TransactionType.expense =>
                        form.expenseCategoryV2 == ExpenseCategoryV2.other
                            ? _OtherExpenseForm(
                                form: form,
                                amountController: _amountController,
                                noteController: _noteController,
                              )
                            : _ExpenseForm(
                                form: form,
                                amountController: _amountController,
                                noteController: _noteController,
                                hourlyRate: hourlyRate,
                              ),
                      TransactionType.labor => _LaborForm(
                        form: form,
                        noteController: _noteController,
                        hourlyRate: hourlyRate,
                      ),
                      TransactionType.timeFriction => _FrictionForm(
                        form: form,
                        noteController: _noteController,
                        hourlyRate: hourlyRate,
                      ),
                      TransactionType.return_ =>
                        form.returnCategoryV2 == ReturnCategoryV2.intimacy
                            ? _IntimacyForm(form: form)
                            : (form.returnCategoryV2 ==
                                      ReturnCategoryV2.emotionalValue
                                  ? _EmotionalValueForm(form: form)
                                  : (form.returnCategoryV2 ==
                                            ReturnCategoryV2.other
                                        ? _OtherReturnForm(
                                            form: form,
                                            amountController: _amountController,
                                            noteController: _noteController,
                                          )
                                        : _ReturnForm(
                                            form: form,
                                            amountController: _amountController,
                                            noteController: _noteController,
                                            hourlyRate: hourlyRate,
                                          ))),
                      TransactionType.aiVerdict => _AiVerdictForm(
                        noteController: _noteController,
                        hourlyRate: hourlyRate,
                      ),
                    },
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ─── Type Selector ──────────────────────────────────────────────

class _TypeSelector extends ConsumerStatefulWidget {
  final InputFormState form;
  const _TypeSelector({required this.form});

  @override
  ConsumerState<_TypeSelector> createState() => _TypeSelectorState();
}

class _TypeSelectorState extends ConsumerState<_TypeSelector>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _crack;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
    _crack = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void didUpdateWidget(covariant _TypeSelector old) {
    super.didUpdateWidget(old);
    final wasV = old.form.type == TransactionType.aiVerdict;
    final isV = widget.form.type == TransactionType.aiVerdict;
    if (isV && !wasV) _ctrl.forward();
    if (!isV && wasV) _ctrl.reverse();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = ref.read(addTransactionControllerProvider.notifier);
    final form = widget.form;

    Widget v2Chip({
      required String label,
      required bool selected,
      required Color accent,
      required VoidCallback onTap,
    }) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: selected
                ? accent.withValues(alpha: 0.16)
                : AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: selected ? accent : AppColors.border),
          ),
          child: Text(
            label,
            maxLines: 1,
            softWrap: false,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: selected ? accent : AppColors.textSecondary,
            ),
          ),
        ),
      );
    }

    void switchDirection(TransactionDirection dir) {
      ctrl.setDirectionV2(dir);
      if (dir == TransactionDirection.expense) {
        ctrl.setType(TransactionType.expense);
        ctrl.setExpenseCategoryV2(ExpenseCategoryV2.financial);
      } else {
        ctrl.setType(TransactionType.return_);
        ctrl.setReturnCategoryV2(ReturnCategoryV2.material);
      }
    }

    final isExpense = form.directionV2 == TransactionDirection.expense;
    final isAiVerdict = form.type == TransactionType.aiVerdict;
    final expSel = isExpense && !isAiVerdict;
    final retSel = !isExpense && !isAiVerdict;

    // Heart: 96 × 90   Buttons: 50 tall
    const heartW = 96.0;
    const heartH = 90.0;
    const btnH = 50.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── [投入] [♥ CRUSH] [回血] ─────────────────────────────
        SizedBox(
          height: heartH,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // ── 投入 ──────────────────────────────────────────
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => switchDirection(TransactionDirection.expense),
                  child: Align(
                    alignment: Alignment.center,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      height: btnH,
                      constraints: const BoxConstraints(maxWidth: 110),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1A1A),
                        borderRadius: BorderRadius.circular(8),
                        border: expSel
                            ? Border.all(
                                color: Colors.white.withValues(alpha: 0.6),
                                width: 1.2,
                              )
                            : Border.all(
                                color: Colors.white.withValues(alpha: 0.1),
                                width: 1.0,
                              ),
                      ),
                      child: Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Opacity(
                              opacity: expSel ? 1 : 0.35,
                              child: Text(
                                '👇',
                                //'📉',
                                style: TextStyle(
                                  fontSize: 16,
                                  height: 1,
                                  color: expSel ? Colors.white : Colors.white38,
                                ),
                              ),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              '投入',
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 13,
                                fontWeight: expSel
                                    ? FontWeight.w700
                                    : FontWeight.w400,
                                color: expSel ? Colors.white : Colors.white38,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // ── Heart ─────────────────────────────────────────
              SizedBox(
                width: heartW,
                height: heartH,
                child: GestureDetector(
                  onTap: () => ctrl.setType(TransactionType.aiVerdict),
                  child: AnimatedBuilder(
                    animation: _crack,
                    builder: (ctx, _) => Stack(
                      clipBehavior: Clip.none,
                      children: [
                        // Heart shape with animated crack
                        CustomPaint(
                          size: const Size(heartW, heartH),
                          painter: _HeartCrackPainter(
                            crackProgress: _crack.value,
                          ),
                        ),
                        // Text — left half translates with left piece
                        Transform.translate(
                          offset: Offset(-_crack.value * 8, _crack.value * 2),
                          child: ClipPath(
                            clipper: const _LeftHalfClipper(),
                            child: const SizedBox(
                              width: heartW,
                              height: heartH,
                              child: _HeartLabel(),
                            ),
                          ),
                        ),
                        // Text — right half translates with right piece
                        Transform.translate(
                          offset: Offset(_crack.value * 8, _crack.value * 2),
                          child: ClipPath(
                            clipper: const _RightHalfClipper(),
                            child: const SizedBox(
                              width: heartW,
                              height: heartH,
                              child: _HeartLabel(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // ── 回血 ──────────────────────────────────────────
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => switchDirection(TransactionDirection.return_),
                  child: Align(
                    alignment: Alignment.center,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      height: btnH,
                      constraints: const BoxConstraints(maxWidth: 110),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1A1A),
                        borderRadius: BorderRadius.circular(8),
                        border: retSel
                            ? Border.all(
                                color: Colors.white.withValues(alpha: 0.6),
                                width: 1.2,
                              )
                            : Border.all(
                                color: Colors.white.withValues(alpha: 0.1),
                                width: 1.0,
                              ),
                      ),
                      child: Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '👆',
                              //'📈',
                              style: TextStyle(
                                fontSize: 16,
                                height: 1,
                                color: retSel ? Colors.white : Colors.white38,
                              ),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              '回血',
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 13,
                                fontWeight: retSel
                                    ? FontWeight.w700
                                    : FontWeight.w400,
                                color: retSel ? Colors.white : Colors.white38,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const Gap(12),
        if (form.type != TransactionType.aiVerdict)
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              if (isExpense) ...[
                v2Chip(
                  label: '财务开销',
                  selected:
                      form.expenseCategoryV2 == ExpenseCategoryV2.financial,
                  accent: AppColors.expense,
                  onTap: () {
                    ctrl.setType(TransactionType.expense);
                    ctrl.setExpenseCategoryV2(ExpenseCategoryV2.financial);
                  },
                ),
                v2Chip(
                  label: '行动付出',
                  selected: form.expenseCategoryV2 == ExpenseCategoryV2.effort,
                  accent: AppColors.expense,
                  onTap: () {
                    ctrl.setType(TransactionType.labor);
                    ctrl.setExpenseCategoryV2(ExpenseCategoryV2.effort);
                  },
                ),
                v2Chip(
                  label: '时间磨损',
                  selected:
                      form.expenseCategoryV2 == ExpenseCategoryV2.timeFriction,
                  accent: AppColors.warning,
                  onTap: () {
                    ctrl.setType(TransactionType.timeFriction);
                    ctrl.setExpenseCategoryV2(ExpenseCategoryV2.timeFriction);
                  },
                ),
                v2Chip(
                  label: '情绪消耗',
                  selected:
                      form.expenseCategoryV2 ==
                      ExpenseCategoryV2.emotionalDrain,
                  accent: AppColors.warning,
                  onTap: () {
                    ctrl.setType(TransactionType.timeFriction);
                    ctrl.setExpenseCategoryV2(ExpenseCategoryV2.emotionalDrain);
                  },
                ),
                v2Chip(
                  label: '其他',
                  selected: form.expenseCategoryV2 == ExpenseCategoryV2.other,
                  accent: AppColors.textPrimary,
                  onTap: () {
                    ctrl.setType(TransactionType.expense);
                    ctrl.setExpenseCategoryV2(ExpenseCategoryV2.other);
                  },
                ),
              ] else ...[
                v2Chip(
                  label: '物质回血',
                  selected: form.returnCategoryV2 == ReturnCategoryV2.material,
                  accent: AppColors.income,
                  onTap: () {
                    ctrl.setType(TransactionType.return_);
                    ctrl.setReturnCategoryV2(ReturnCategoryV2.material);
                  },
                ),
                v2Chip(
                  label: '亲密接触',
                  selected: form.returnCategoryV2 == ReturnCategoryV2.intimacy,
                  accent: AppColors.income,
                  onTap: () {
                    ctrl.setType(TransactionType.return_);
                    ctrl.setReturnCategoryV2(ReturnCategoryV2.intimacy);
                  },
                ),
                v2Chip(
                  label: '情绪甜头',
                  selected:
                      form.returnCategoryV2 == ReturnCategoryV2.emotionalValue,
                  accent: AppColors.income,
                  onTap: () {
                    ctrl.setType(TransactionType.return_);
                    ctrl.setReturnCategoryV2(ReturnCategoryV2.emotionalValue);
                  },
                ),
                v2Chip(
                  label: '其他',
                  selected: form.returnCategoryV2 == ReturnCategoryV2.other,
                  accent: AppColors.textPrimary,
                  onTap: () {
                    ctrl.setType(TransactionType.return_);
                    ctrl.setReturnCategoryV2(ReturnCategoryV2.other);
                  },
                ),
              ],
            ],
          ),
      ],
    );
  }
}

// ── Heart label ───────────────────────────────────────────────────

class _HeartLabel extends StatelessWidget {
  const _HeartLabel();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'CRUSH',
          textAlign: TextAlign.center,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 13,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            letterSpacing: 3.0,
            height: 1.0,
          ),
        ),
        const SizedBox(height: 5),
        const Text(
          '粉碎机',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: Colors.white70,
            letterSpacing: 1.5,
            height: 1.0,
          ),
        ),
      ],
    );
  }
}

// ── Heart crack CustomPainter ─────────────────────────────────────

class _HeartCrackPainter extends CustomPainter {
  final double crackProgress;
  const _HeartCrackPainter({required this.crackProgress});

  Path _heartPath(Size s) {
    final w = s.width;
    final h = s.height;
    return Path()
      ..moveTo(w * .50, h * .88)
      ..cubicTo(w * .02, h * .55, w * .02, h * .18, w * .26, h * .18)
      ..cubicTo(w * .38, h * .18, w * .50, h * .32, w * .50, h * .32)
      ..cubicTo(w * .50, h * .32, w * .62, h * .18, w * .74, h * .18)
      ..cubicTo(w * .98, h * .18, w * .98, h * .55, w * .50, h * .88)
      ..close();
  }

  List<Offset> _crackPoints(Size s) => [
    Offset(s.width * .50, s.height * .18),
    Offset(s.width * .55, s.height * .30),
    Offset(s.width * .45, s.height * .43),
    Offset(s.width * .57, s.height * .56),
    Offset(s.width * .43, s.height * .70),
    Offset(s.width * .50, s.height * .88),
  ];

  Path _leftClip(Size s, List<Offset> pts) {
    final p = Path()
      ..moveTo(0, 0)
      ..lineTo(pts.first.dx, pts.first.dy);
    for (final pt in pts.skip(1)) {
      p.lineTo(pt.dx, pt.dy);
    }
    return p
      ..lineTo(0, s.height)
      ..close();
  }

  Path _rightClip(Size s, List<Offset> pts) {
    final p = Path()
      ..moveTo(s.width, 0)
      ..lineTo(pts.first.dx, pts.first.dy);
    for (final pt in pts.skip(1)) {
      p.lineTo(pt.dx, pt.dy);
    }
    return p
      ..lineTo(s.width, s.height)
      ..close();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final heart = _heartPath(size);
    final pts = _crackPoints(size);
    final lClip = _leftClip(size, pts);
    final rClip = _rightClip(size, pts);
    final sep = crackProgress * 8.0;
    final drop = crackProgress * 3.0;

    final col = Color.lerp(
      const Color(0xFFCC2200),
      const Color(0xFF8B0000),
      crackProgress,
    )!;

    // Outer glow when cracking
    if (crackProgress > 0.15) {
      canvas.drawPath(
        heart,
        Paint()
          ..color = const Color(
            0xFFCC2200,
          ).withValues(alpha: crackProgress * 0.35)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16),
      );
    }

    // Left half
    canvas.save();
    canvas.clipPath(lClip);
    canvas.translate(-sep, drop);
    canvas.drawPath(heart, Paint()..color = col);
    canvas.restore();

    // Right half
    canvas.save();
    canvas.clipPath(rClip);
    canvas.translate(sep, drop);
    canvas.drawPath(heart, Paint()..color = col);
    canvas.restore();

    // Dark crack gap
    if (crackProgress > 0.05) {
      final crackPath = Path()..moveTo(pts.first.dx, pts.first.dy);
      for (final pt in pts.skip(1)) {
        crackPath.lineTo(pt.dx, pt.dy);
      }
      canvas.drawPath(
        crackPath,
        Paint()
          ..color = Colors.black.withValues(alpha: crackProgress * 0.9)
          ..strokeWidth = crackProgress * 4.0
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _HeartCrackPainter old) =>
      old.crackProgress != crackProgress;
}

// ── Half-clip helpers ─────────────────────────────────────────────

class _LeftHalfClipper extends CustomClipper<Path> {
  const _LeftHalfClipper();
  @override
  Path getClip(Size s) =>
      Path()..addRect(Rect.fromLTWH(0, 0, s.width / 2, s.height));
  @override
  bool shouldReclip(_) => false;
}

class _RightHalfClipper extends CustomClipper<Path> {
  const _RightHalfClipper();
  @override
  Path getClip(Size s) =>
      Path()..addRect(Rect.fromLTWH(s.width / 2, 0, s.width / 2, s.height));
  @override
  bool shouldReclip(_) => false;
}

// ─── AI Verdict Form ───────────────────────────────────────────

class _AiVerdictForm extends ConsumerStatefulWidget {
  final TextEditingController noteController;
  final double hourlyRate;

  const _AiVerdictForm({
    required this.noteController,
    required this.hourlyRate,
  });

  @override
  ConsumerState<_AiVerdictForm> createState() => _AiVerdictFormState();
}

class _AiVerdictFormState extends ConsumerState<_AiVerdictForm> {
  static const _maxShots = 9;

  bool _analyzing = false;
  bool _hasResult = false;

  List<PlatformFile> _shots = const [];
  double _score = 0;
  String _label = '';
  String _diagnosis = '';
  double _ciDelta = 0;
  double _delusion = 0;
  double _perfunctory = 0;
  double _shatter = 0;

  Future<void> _pick() async {
    HapticFeedback.selectionClick();
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: true,
      withData: true,
    );
    if (result == null) return;
    final next = <PlatformFile>[
      ..._shots,
      ...result.files,
    ].take(_maxShots).toList();
    setState(() {
      _shots = next;
      _hasResult = false;
    });
  }

  void _removeAt(int index) {
    final next = _shots.toList()..removeAt(index);
    setState(() {
      _shots = next;
      _hasResult = false;
    });
  }

  Future<void> _analyze() async {
    if (_shots.isEmpty) return;
    setState(() {
      _analyzing = true;
      _hasResult = false;
    });

    final images = <Uint8List>[];
    for (final f in _shots) {
      final bytes = f.bytes;
      if (bytes == null || bytes.isEmpty) continue;
      images.add(bytes);
      if (images.length >= 4) break; // 避免一次传太多图导致超时/过大
    }

    final llm = await AiVerdictService.analyzeCrush(
      apiKey: kLongcatApiKey,
      images: images,
      note: widget.noteController.text,
    );

    final result = llm ?? _fallbackAnalyze(_shots.length);

    setState(() {
      _score = result.perfunctory;
      _label = result.label;
      _diagnosis = result.diagnosis;
      _ciDelta = result.ciDelta;
      _delusion = result.delusion;
      _perfunctory = result.perfunctory;
      _shatter = result.shatter;
      _hasResult = true;
      _analyzing = false;
    });
  }

  AiVerdictResult _fallbackAnalyze(int n) {
    // 兜底：规则引擎（按截图数量给出可用的结构化结果）
    final perfunctory = n >= 6 ? 92.0 : (n >= 3 ? 78.0 : 56.0);
    final delusion = (100 - perfunctory).clamp(0, 100).toDouble();
    final shatter = (perfunctory * 0.9 + n * 2).clamp(0, 100).toDouble();
    final label = perfunctory >= 85
        ? '滤镜粉碎'
        : (perfunctory >= 70 ? '开始裂痕' : '可疑上头');
    final diagnosis = switch (label) {
      '滤镜粉碎' => 'Ta 不是忙，你只是不在优先列表里。把他降级成 Crush，就不会疼了。',
      '开始裂痕' => '你在自证，他在装死。别再把沉默翻译成深情。',
      _ => '这段关系的含糖量很高，但营养成分几乎为 0。',
    };
    final ciDelta = perfunctory >= 85
        ? -0.10
        : (perfunctory >= 70 ? -0.05 : 0.0);

    return AiVerdictResult(
      perfunctory: perfunctory,
      delusion: delusion,
      shatter: shatter,
      label: label,
      diagnosis: diagnosis,
      ciDelta: ciDelta,
    );
  }

  void _save() {
    if (!_hasResult) return;
    ref
        .read(addTransactionControllerProvider.notifier)
        .saveAiVerdict(
          verdictScore: _score,
          delusion: _delusion,
          perfunctory: _perfunctory,
          shatter: _shatter,
          diagnosisText: _diagnosis,
          ciDelta: _ciDelta,
          note: widget.noteController.text,
        );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final canPickMore = _shots.length < _maxShots;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FieldLabel('聊天截图（1~9 张）'),
        const Gap(8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _shots.isEmpty
                          ? '上传截图，粉碎 Crush'
                          : '已选择 ${_shots.length} 张截图',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: canPickMore ? _pick : null,
                    child: Text(
                      canPickMore ? '选择图片' : '已满 9 张',
                      style: TextStyle(
                        color: canPickMore
                            ? AppColors.expense
                            : AppColors.textTertiary,
                      ),
                    ),
                  ),
                ],
              ),
              if (_shots.isNotEmpty) ...[
                const Gap(10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (var i = 0; i < _shots.length; i++)
                      _ShotChip(file: _shots[i], onRemove: () => _removeAt(i)),
                  ],
                ),
              ],
            ],
          ),
        ),
        const Gap(16),
        _FieldLabel('备注（可选）'),
        const Gap(8),
        TextField(
          controller: widget.noteController,
          maxLength: 20,
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
          decoration: const InputDecoration(
            counterText: '',
            hintText: '比如：对方失联/已读不回…',
            hintStyle: TextStyle(color: AppColors.textTertiary, fontSize: 13),
          ),
        ),
        const Gap(16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _shots.isEmpty
                  ? AppColors.border
                  : AppColors.warning,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: _shots.isEmpty || _analyzing ? null : _analyze,
            child: Text(
              _analyzing ? '分析中…' : '开始分析',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
        if (_hasResult) ...[
          const Gap(14),
          _AiVerdictResultCard(
            score: _score,
            label: _label,
            diagnosis: _diagnosis,
            ciDelta: _ciDelta,
            delusion: _delusion,
            perfunctory: _perfunctory,
            shatter: _shatter,
          ),
          const Gap(12),
          SizedBox(
            width: double.infinity,
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
              onPressed: _save,
              child: Text(
                '确认入账',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _ShotChip extends StatelessWidget {
  final PlatformFile file;
  final VoidCallback onRemove;
  const _ShotChip({required this.file, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final name = (file.name).trim().isEmpty ? '截图' : file.name;
    return InkWell(
      onTap: onRemove,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.image_outlined,
              size: 16,
              color: AppColors.textTertiary,
            ),
            const Gap(6),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 160),
              child: Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            const Gap(6),
            const Icon(Icons.close, size: 16, color: AppColors.textTertiary),
          ],
        ),
      ),
    );
  }
}

class _AiVerdictResultCard extends StatelessWidget {
  final double score;
  final String label;
  final String diagnosis;
  final double ciDelta;
  final double delusion;
  final double perfunctory;
  final double shatter;

  const _AiVerdictResultCard({
    required this.score,
    required this.label,
    required this.diagnosis,
    required this.ciDelta,
    required this.delusion,
    required this.perfunctory,
    required this.shatter,
  });

  @override
  Widget build(BuildContext context) {
    final impact = ciDelta == 0
        ? 'CI ±0.0'
        : (ciDelta > 0
              ? 'CI +${ciDelta.toStringAsFixed(2)}'
              : 'CI ${ciDelta.toStringAsFixed(2)}');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF120708),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.redAccent.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  'CRUSH 粉碎机报告',
                  style: GoogleFonts.robotoMono(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ),
              const Spacer(),
              Text(
                '${perfunctory.toStringAsFixed(0)}%',
                style: GoogleFonts.robotoMono(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: Colors.redAccent,
                ),
              ),
            ],
          ),
          const Gap(10),
          Text(
            '判定: $label',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: Colors.redAccent.withValues(alpha: 0.95),
            ),
          ),
          const Gap(8),
          Row(
            children: [
              Expanded(
                child: _CrushMetric(
                  label: '脑补浓度',
                  value: delusion,
                  color: Colors.white.withValues(alpha: 0.85),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _CrushMetric(
                  label: '敷衍指数',
                  value: perfunctory,
                  color: Colors.redAccent,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _CrushMetric(
                  label: '滤镜破碎',
                  value: shatter,
                  color: Colors.orangeAccent.withValues(alpha: 0.95),
                ),
              ),
            ],
          ),
          const Gap(8),
          Text(
            diagnosis,
            style: const TextStyle(
              fontSize: 13,
              height: 1.4,
              color: Colors.white70,
            ),
          ),
          const Gap(10),
          Text(
            '📉 清醒指数（CI）影响：$impact',
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}

class _CrushMetric extends StatelessWidget {
  final String label;
  final double value;
  final Color color;

  const _CrushMetric({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10,
              color: Colors.white.withValues(alpha: 0.65),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${value.toStringAsFixed(0)}%',
            style: GoogleFonts.robotoMono(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Expense Form ─────────────────────────────────────────────

class _ExpenseForm extends ConsumerWidget {
  final InputFormState form;
  final TextEditingController amountController;
  final TextEditingController noteController;
  final double hourlyRate;

  const _ExpenseForm({
    required this.form,
    required this.amountController,
    required this.noteController,
    required this.hourlyRate,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(addTransactionControllerProvider.notifier);
    final otherSelected =
        form.expenseCategory == ExpenseCategory.other ||
        form.expenseSubCategory == ExpenseSubCategory.other;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FieldLabel('一级分类'),
        const Gap(8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _CategoryChip(
              label: '🎁 礼物',
              selected: form.expenseCategory == ExpenseCategory.gift,
              onTap: () => controller.setExpenseCategory(ExpenseCategory.gift),
            ),
            _CategoryChip(
              label: '🍿 约会',
              selected: form.expenseCategory == ExpenseCategory.date,
              onTap: () => controller.setExpenseCategory(ExpenseCategory.date),
            ),
            _CategoryChip(
              label: '💸 转账',
              selected: form.expenseCategory == ExpenseCategory.transfer,
              onTap: () =>
                  controller.setExpenseCategory(ExpenseCategory.transfer),
            ),
            _CategoryChip(
              label: '📦 其他',
              selected: form.expenseCategory == ExpenseCategory.other,
              onTap: () => controller.setExpenseCategory(ExpenseCategory.other),
            ),
          ],
        ),
        const Gap(16),

        if (form.expenseCategory != null &&
            form.expenseCategory != ExpenseCategory.other) ...[
          _FieldLabel('二级分类'),
          const Gap(8),
          _ExpenseSubCategorySelector(
            category: form.expenseCategory!,
            selected: form.expenseSubCategory,
          ),
          const Gap(16),
        ],

        _FieldLabel('金额'),
        const Gap(8),
        _AmountInput(
          controller: amountController,
          color: AppColors.expense,
          onChanged: (v) =>
              controller.setMonetaryAmount(double.tryParse(v) ?? 0),
        ),
        const Gap(16),

        _FieldLabel(otherSelected ? '备注（必填）' : '备注（可选）'),
        const Gap(8),
        TextField(
          controller: noteController,
          maxLength: 20,
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
          decoration: const InputDecoration(
            counterText: '',
            hintText: '比如：生日/纪念日…',
            hintStyle: TextStyle(color: AppColors.textTertiary, fontSize: 13),
          ),
          onChanged: (v) => controller.setNote(v),
        ),
        const Gap(16),

        _SaveButton(
          canSave: form.canSave,
          label: '记下这笔支出',
          color: AppColors.expense,
          hourlyRate: hourlyRate,
        ),
      ],
    );
  }
}

class _ExpenseSubCategorySelector extends ConsumerWidget {
  final ExpenseCategory category;
  final ExpenseSubCategory? selected;

  const _ExpenseSubCategorySelector({
    required this.category,
    required this.selected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(addTransactionControllerProvider.notifier);
    final options = _getOptions();

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((opt) {
        return _CategoryChip(
          label: opt.label,
          selected: selected == opt.value,
          onTap: () => controller.setExpenseSubCategory(opt.value),
        );
      }).toList(),
    );
  }

  List<_SubOption> _getOptions() {
    switch (category) {
      case ExpenseCategory.gift:
        return [
          _SubOption('首饰包包', ExpenseSubCategory.jewelryBags),
          _SubOption('数码外设', ExpenseSubCategory.digitalGear),
          _SubOption('鲜花手工', ExpenseSubCategory.flowersHandmade),
          _SubOption('其他', ExpenseSubCategory.other),
        ];
      case ExpenseCategory.date:
        return [
          _SubOption('高档餐饮', ExpenseSubCategory.fineDining),
          _SubOption('电影演出', ExpenseSubCategory.movieShow),
          _SubOption('密室桌游', ExpenseSubCategory.escapeBoard),
          _SubOption('其他', ExpenseSubCategory.other),
        ];
      case ExpenseCategory.transfer:
        return [
          _SubOption('清空购物车', ExpenseSubCategory.clearCart),
          _SubOption('节日红包', ExpenseSubCategory.holidayRedPacket),
          _SubOption('帮还账单', ExpenseSubCategory.payBills),
          _SubOption('其他', ExpenseSubCategory.other),
        ];
      case ExpenseCategory.other:
        return [_SubOption('其他', ExpenseSubCategory.other)];
    }
  }
}

// ─── Labor Form ───────────────────────────────────────────────

class _LaborForm extends ConsumerWidget {
  final InputFormState form;
  final TextEditingController noteController;
  final double hourlyRate;

  const _LaborForm({
    required this.form,
    required this.noteController,
    required this.hourlyRate,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(addTransactionControllerProvider.notifier);
    final otherSelected =
        form.laborCategory == LaborCategory.other ||
        form.laborSubCategory == LaborSubCategory.other;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FieldLabel('分类（含权重）'),
        const Gap(8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _CategoryChip(
              label: '💝 情绪价值 (1.5x)',
              selected: form.laborCategory == LaborCategory.emotional,
              onTap: () => controller.setLaborCategory(LaborCategory.emotional),
            ),
            _CategoryChip(
              label: '💪 体力劳动 (1.0x)',
              selected: form.laborCategory == LaborCategory.physical,
              onTap: () => controller.setLaborCategory(LaborCategory.physical),
            ),
            _CategoryChip(
              label: '⏰ 时间沉没 (0.8x)',
              selected: form.laborCategory == LaborCategory.timeSunk,
              onTap: () => controller.setLaborCategory(LaborCategory.timeSunk),
            ),
            _CategoryChip(
              label: '📦 其他 (1.0x)',
              selected: form.laborCategory == LaborCategory.other,
              onTap: () => controller.setLaborCategory(LaborCategory.other),
            ),
          ],
        ),
        const Gap(16),

        if (form.laborCategory != null &&
            form.laborCategory != LaborCategory.other) ...[
          _FieldLabel('具体内容'),
          const Gap(8),
          _LaborSubCategorySelector(
            category: form.laborCategory!,
            selected: form.laborSubCategory,
          ),
          const Gap(16),
        ],

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _FieldLabel('耗时'),
            Text(
              '时薪 ${formatCurrency(hourlyRate)}/h × ${form.weight}x',
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textTertiary,
              ),
            ),
          ],
        ),
        const Gap(10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              form.laborHours.toStringAsFixed(1),
              style: GoogleFonts.robotoMono(
                fontSize: 44,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                height: 1,
              ),
            ),
            const Gap(6),
            const Text(
              '小时',
              style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
            ),
          ],
        ),
        Slider(
          value: form.laborHours,
          min: 0,
          max: 24,
          divisions: 48,
          label: '${form.laborHours.toStringAsFixed(1)}h',
          onChanged: (v) {
            final rounded = (v * 2).round() / 2.0;
            controller.setLaborHours(rounded);
          },
        ),

        // 实时计算
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.expense.withAlpha(10),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.expense.withAlpha(50)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '折算金额',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const Gap(4),
                  Text(
                    formatCurrency(form.laborHours * hourlyRate * form.weight),
                    style: GoogleFonts.robotoMono(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: AppColors.expense,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${form.laborHours.toStringAsFixed(1)}h',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textTertiary,
                    ),
                  ),
                  Text(
                    '× ${formatCurrency(hourlyRate)}/h',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textTertiary,
                    ),
                  ),
                  Text(
                    '× ${form.weight}x',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const Gap(16),

        _FieldLabel(otherSelected ? '备注（必填）' : '备注（可选）'),
        const Gap(8),
        TextField(
          controller: noteController,
          maxLength: 20,
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
          decoration: const InputDecoration(
            counterText: '',
            hintText: '补充说明…',
            hintStyle: TextStyle(color: AppColors.textTertiary, fontSize: 13),
          ),
          onChanged: (v) => controller.setNote(v),
        ),
        const Gap(16),

        _SaveButton(
          canSave: form.canSave,
          label: '记下这笔支出',
          color: AppColors.expense,
          hourlyRate: hourlyRate,
        ),
      ],
    );
  }
}

class _LaborSubCategorySelector extends ConsumerWidget {
  final LaborCategory category;
  final LaborSubCategory? selected;

  const _LaborSubCategorySelector({
    required this.category,
    required this.selected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(addTransactionControllerProvider.notifier);
    final options = _getOptions();

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((opt) {
        return _CategoryChip(
          label: opt.label,
          selected: selected == opt.value,
          onTap: () => controller.setLaborSubCategory(opt.value),
        );
      }).toList(),
    );
  }

  List<_LaborSubOption> _getOptions() {
    switch (category) {
      case LaborCategory.emotional:
        return [
          _LaborSubOption('深夜树洞安慰', LaborSubCategory.lateNightComfort),
          _LaborSubOption('吵架主动破冰', LaborSubCategory.breakIce),
          _LaborSubOption('精心准备惊喜', LaborSubCategory.prepareSurprise),
          _LaborSubOption('其他', LaborSubCategory.other),
        ];
      case LaborCategory.physical:
        return [
          _LaborSubOption('跑腿接送', LaborSubCategory.errandsPickup),
          _LaborSubOption('搬家打扫', LaborSubCategory.movingCleaning),
          _LaborSubOption('排队代买', LaborSubCategory.queueBuying),
          _LaborSubOption('其他', LaborSubCategory.other),
        ];
      case LaborCategory.timeSunk:
        return [
          _LaborSubOption('陪做不感兴趣的事', LaborSubCategory.boringActivity),
          _LaborSubOption('其他', LaborSubCategory.other),
        ];
      case LaborCategory.other:
        return [_LaborSubOption('其他', LaborSubCategory.other)];
    }
  }
}

// ─── Friction Form ────────────────────────────────────────────

class _FrictionForm extends ConsumerWidget {
  final InputFormState form;
  final TextEditingController noteController;
  final double hourlyRate;

  const _FrictionForm({
    required this.form,
    required this.noteController,
    required this.hourlyRate,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(addTransactionControllerProvider.notifier);
    final isEmotionalDrain =
        form.expenseCategoryV2 == ExpenseCategoryV2.emotionalDrain;
    final title = isEmotionalDrain ? '情绪消耗时长' : '磨损时长';
    final accent = AppColors.warning;
    final hint = isEmotionalDrain ? '比如：吵到心累/被冷处理…' : '比如：等到睡着/等到破防…';
    final saveLabel = isEmotionalDrain ? '记下这笔情绪消耗' : '记下这笔磨损';
    final hours = form.laborHours.clamp(0.0, 24.0);
    final amount = hours * hourlyRate * form.weight;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FieldLabel(title),
        const Gap(10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  hours.toStringAsFixed(1),
                  style: GoogleFonts.robotoMono(
                    fontSize: 44,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    height: 1,
                  ),
                ),
                const Gap(6),
                const Text(
                  '小时',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            Text(
              '⏳ ${formatCurrency(hourlyRate)}/h × ${form.weight}x',
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textTertiary,
              ),
            ),
          ],
        ),
        Slider(
          value: hours,
          min: 0,
          max: 12,
          divisions: 24,
          label: '${hours.toStringAsFixed(1)}h',
          onChanged: (v) {
            final rounded = (v * 2).round() / 2.0;
            controller.setLaborHours(rounded);
          },
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: accent.withAlpha(10),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: accent.withAlpha(50)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '折算成本（TI）',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const Gap(4),
                  Text(
                    formatCurrency(amount),
                    style: GoogleFonts.robotoMono(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: accent,
                    ),
                  ),
                ],
              ),
              const Icon(
                Icons.hourglass_bottom_rounded,
                color: AppColors.warning,
              ),
            ],
          ),
        ),
        const Gap(16),
        _FieldLabel('备注（可选）'),
        const Gap(8),
        TextField(
          controller: noteController,
          maxLength: 20,
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
          decoration: InputDecoration(
            counterText: '',
            hintText: hint,
            hintStyle: const TextStyle(
              color: AppColors.textTertiary,
              fontSize: 13,
            ),
          ),
          onChanged: (v) => controller.setNote(v),
        ),
        const Gap(16),
        _SaveButton(
          canSave: form.canSave,
          label: saveLabel,
          color: accent,
          hourlyRate: hourlyRate,
        ),
      ],
    );
  }
}

class _OtherExpenseForm extends ConsumerWidget {
  final InputFormState form;
  final TextEditingController amountController;
  final TextEditingController noteController;

  const _OtherExpenseForm({
    required this.form,
    required this.amountController,
    required this.noteController,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(addTransactionControllerProvider.notifier);
    final hourlyRate = ref.watch(settingsNotifierProvider).hourlyRate;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FieldLabel('金额'),
        const Gap(8),
        _AmountInput(
          controller: amountController,
          color: AppColors.expense,
          onChanged: (v) =>
              controller.setMonetaryAmount(double.tryParse(v) ?? 0),
        ),
        const Gap(16),
        _FieldLabel('一句话描述（必填）'),
        const Gap(8),
        TextField(
          controller: noteController,
          maxLength: 20,
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
          decoration: const InputDecoration(
            counterText: '',
            hintText: '一句话描述你干了啥/花了啥',
            hintStyle: TextStyle(color: AppColors.textTertiary, fontSize: 13),
          ),
          onChanged: (v) => controller.setNote(v),
        ),
        const Gap(16),
        _SaveButton(
          canSave: form.canSave,
          label: '记下这笔投入',
          color: AppColors.expense,
          hourlyRate: hourlyRate,
        ),
      ],
    );
  }
}

class _OtherReturnForm extends ConsumerWidget {
  final InputFormState form;
  final TextEditingController amountController;
  final TextEditingController noteController;

  const _OtherReturnForm({
    required this.form,
    required this.amountController,
    required this.noteController,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(addTransactionControllerProvider.notifier);
    final hourlyRate = ref.watch(settingsNotifierProvider).hourlyRate;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FieldLabel('等效回血（金额）'),
        const Gap(8),
        _AmountInput(
          controller: amountController,
          color: AppColors.income,
          onChanged: (v) =>
              controller.setMonetaryAmount(double.tryParse(v) ?? 0),
        ),
        const Gap(16),
        _FieldLabel('一句话描述（必填）'),
        const Gap(8),
        TextField(
          controller: noteController,
          maxLength: 20,
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
          decoration: const InputDecoration(
            counterText: '',
            hintText: '一句话描述你得到了啥',
            hintStyle: TextStyle(color: AppColors.textTertiary, fontSize: 13),
          ),
          onChanged: (v) => controller.setNote(v),
        ),
        const Gap(16),
        _SaveButton(
          canSave: form.canSave,
          label: '记下这笔回血',
          color: AppColors.income,
          hourlyRate: hourlyRate,
        ),
      ],
    );
  }
}

class _IntimacyForm extends ConsumerWidget {
  final InputFormState form;
  const _IntimacyForm({required this.form});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(addTransactionControllerProvider.notifier);

    Widget chip(IntimacyAction value, String label) {
      final selected = form.intimacyAction == value;
      return InkWell(
        onTap: () => controller.setIntimacyAction(value),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.income.withValues(alpha: 0.16)
                : AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? AppColors.income : AppColors.border,
            ),
          ),
          child: Text(
            label,
            maxLines: 1,
            softWrap: false,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: selected ? AppColors.income : AppColors.textSecondary,
            ),
          ),
        ),
      );
    }

    Future<void> interceptAndSave() async {
      HapticFeedback.heavyImpact();
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: Colors.black,
          title: const Text(
            '⚠️ 账本预警',
            style: TextStyle(color: Colors.redAccent),
          ),
          content: const Text(
            '检测到 1 次零成本肢体接触。\n系统已为您强行冲销 ¥1000 沉没成本。\n\n看，只要一点甜头，你的底线就能无限退让。\n已强制入账。',
            style: TextStyle(
              color: Colors.redAccent,
              height: 1.6,
              fontSize: 13,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('知道了', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
      if (!context.mounted) return;
      controller.save(ref.read(settingsNotifierProvider).hourlyRate);
      Navigator.pop(context);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FieldLabel('亲密接触（高杠杆）'),
        const Gap(8),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            chip(IntimacyAction.handHold, '🤝 主动牵手'),
            chip(IntimacyAction.hug, '🫂 主动拥抱'),
            chip(IntimacyAction.kiss, '💋 亲吻'),
          ],
        ),
        const Gap(16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.income.withAlpha(10),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.income.withAlpha(50)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '冲销基值',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const Gap(4),
                  Text(
                    formatCurrency(1000),
                    style: GoogleFonts.robotoMono(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: AppColors.income,
                    ),
                  ),
                ],
              ),
              const Icon(Icons.favorite, color: AppColors.income),
            ],
          ),
        ),
        const Gap(16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.income,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: form.canSave ? interceptAndSave : null,
            child: Text(
              '强制入账',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _EmotionalValueForm extends ConsumerWidget {
  final InputFormState form;
  const _EmotionalValueForm({required this.form});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(addTransactionControllerProvider.notifier);

    Widget chip(EmotionalValueAction value, String label) {
      final selected = form.emotionalValueAction == value;
      return InkWell(
        onTap: () => controller.setEmotionalValueAction(value),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.income.withValues(alpha: 0.16)
                : AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? AppColors.income : AppColors.border,
            ),
          ),
          child: Text(
            label,
            maxLines: 1,
            softWrap: false,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: selected ? AppColors.income : AppColors.textSecondary,
            ),
          ),
        ),
      );
    }

    void saveAndClose() {
      controller.save(ref.read(settingsNotifierProvider).hourlyRate);
      Navigator.pop(context);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FieldLabel('情绪甜头（中高杠杆）'),
        const Gap(8),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            chip(EmotionalValueAction.sweetTalk, '🍬 说了句好听的'),
            chip(EmotionalValueAction.activeCare, '🌿 主动关心'),
            chip(EmotionalValueAction.apology, '🧯 主动道歉'),
          ],
        ),
        const Gap(16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.income.withAlpha(10),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.income.withAlpha(50)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '冲销基值',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const Gap(4),
                  Text(
                    formatCurrency(300),
                    style: GoogleFonts.robotoMono(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: AppColors.income,
                    ),
                  ),
                ],
              ),
              const Icon(Icons.auto_awesome, color: AppColors.income),
            ],
          ),
        ),
        const Gap(16),
        _SaveButton(
          canSave: form.canSave,
          label: '记下这笔回血',
          color: AppColors.income,
          hourlyRate: 0,
          onTapOverride: saveAndClose,
        ),
      ],
    );
  }
}

// ─── Return Form ──────────────────────────────────────────────

class _ReturnForm extends ConsumerWidget {
  final InputFormState form;
  final TextEditingController amountController;
  final TextEditingController noteController;
  final double hourlyRate;

  const _ReturnForm({
    required this.form,
    required this.amountController,
    required this.noteController,
    required this.hourlyRate,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(addTransactionControllerProvider.notifier);
    final otherSelected =
        form.returnCategory == ReturnCategory.other ||
        form.returnSubCategory == ReturnSubCategory.other;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FieldLabel('回报类型'),
        const Gap(8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _CategoryChip(
              label: '💰 物质回馈 (1.0x)',
              selected: form.returnCategory == ReturnCategory.material,
              onTap: () =>
                  controller.setReturnCategory(ReturnCategory.material),
            ),
            _CategoryChip(
              label: '💝 情绪回馈 (1.2x)',
              selected: form.returnCategory == ReturnCategory.emotional,
              onTap: () =>
                  controller.setReturnCategory(ReturnCategory.emotional),
            ),
            _CategoryChip(
              label: '🤝 行动回馈 (1.0x)',
              selected: form.returnCategory == ReturnCategory.action,
              onTap: () => controller.setReturnCategory(ReturnCategory.action),
            ),
            _CategoryChip(
              label: '📦 其他 (1.0x)',
              selected: form.returnCategory == ReturnCategory.other,
              onTap: () => controller.setReturnCategory(ReturnCategory.other),
            ),
          ],
        ),
        const Gap(16),

        if (form.returnCategory != null &&
            form.returnCategory != ReturnCategory.other) ...[
          _FieldLabel('具体内容'),
          const Gap(8),
          _ReturnSubCategorySelector(
            category: form.returnCategory!,
            selected: form.returnSubCategory,
          ),
          const Gap(16),
        ],

        // 物质回馈：金额输入
        if (form.returnCategory == ReturnCategory.material ||
            form.returnCategory == ReturnCategory.other) ...[
          _FieldLabel('回馈金额'),
          const Gap(8),
          _AmountInput(
            controller: amountController,
            color: AppColors.income,
            onChanged: (v) =>
                controller.setMonetaryAmount(double.tryParse(v) ?? 0),
          ),
          const Gap(16),
        ],

        // 非物质回馈：时长滑动条
        if (form.isNonMaterialReturn) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _FieldLabel('时长'),
              Text(
                '时薪 ${formatCurrency(hourlyRate)}/h × ${form.weight}x',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textTertiary,
                ),
              ),
            ],
          ),
          const Gap(10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                form.laborHours.toStringAsFixed(1),
                style: GoogleFonts.robotoMono(
                  fontSize: 44,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  height: 1,
                ),
              ),
              const Gap(6),
              const Text(
                '小时',
                style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
              ),
            ],
          ),
          Slider(
            value: form.laborHours,
            min: 0,
            max: 24,
            divisions: 48,
            label: '${form.laborHours.toStringAsFixed(1)}h',
            onChanged: (v) {
              final rounded = (v * 2).round() / 2.0;
              controller.setLaborHours(rounded);
            },
          ),

          // 实时计算
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.income.withAlpha(10),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.income.withAlpha(50)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '折算金额',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const Gap(4),
                    Text(
                      formatCurrency(
                        form.laborHours * hourlyRate * form.weight,
                      ),
                      style: GoogleFonts.robotoMono(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: AppColors.income,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${form.laborHours.toStringAsFixed(1)}h',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textTertiary,
                      ),
                    ),
                    Text(
                      '× ${formatCurrency(hourlyRate)}/h',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textTertiary,
                      ),
                    ),
                    Text(
                      '× ${form.weight}x',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Gap(16),
        ],

        _FieldLabel('Ta 的态度'),
        const Gap(8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _CategoryChip(
              label: '🧊 冷暴力 (-10)',
              selected: form.attitude == Attitude.cold,
              onTap: () => controller.setAttitude(Attitude.cold),
            ),
            _CategoryChip(
              label: '😐 敷衍 (-5)',
              selected: form.attitude == Attitude.dismissive,
              onTap: () => controller.setAttitude(Attitude.dismissive),
            ),
            _CategoryChip(
              label: '🙂 正常 (0)',
              selected: form.attitude == Attitude.normal,
              onTap: () => controller.setAttitude(Attitude.normal),
            ),
            _CategoryChip(
              label: '😊 主动 (+5)',
              selected: form.attitude == Attitude.proactive,
              onTap: () => controller.setAttitude(Attitude.proactive),
            ),
          ],
        ),
        const Gap(16),

        _FieldLabel('回复媒介'),
        const Gap(8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _CategoryChip(
              label: '💬 文字 (+1)',
              selected: form.medium == Medium.text,
              onTap: () => controller.setMedium(Medium.text),
            ),
            _CategoryChip(
              label: '🎤 语音 (+2)',
              selected: form.medium == Medium.voice,
              onTap: () => controller.setMedium(Medium.voice),
            ),
            _CategoryChip(
              label: '📷 图片/视频 (+3)',
              selected: form.medium == Medium.media,
              onTap: () => controller.setMedium(Medium.media),
            ),
          ],
        ),
        const Gap(16),

        // IQS 预览
        if (form.attitude != null && form.medium != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.income.withAlpha(10),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.income.withAlpha(50)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '互动质量分 (IQS)',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const Gap(4),
                    Text(
                      '${TransactionEntity.getAttitudeScore(form.attitude) + TransactionEntity.getMediumScore(form.medium)}',
                      style: GoogleFonts.robotoMono(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color:
                            (TransactionEntity.getAttitudeScore(form.attitude) +
                                    TransactionEntity.getMediumScore(
                                      form.medium,
                                    )) >=
                                0
                            ? AppColors.income
                            : AppColors.expense,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '态度 ${TransactionEntity.getAttitudeScore(form.attitude)}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textTertiary,
                      ),
                    ),
                    Text(
                      '+ 媒介 ${TransactionEntity.getMediumScore(form.medium)}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        const Gap(16),

        _FieldLabel(otherSelected ? '备注（必填）' : '备注（可选）'),
        const Gap(8),
        TextField(
          controller: noteController,
          maxLength: 20,
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
          decoration: const InputDecoration(
            counterText: '',
            hintText: '比如：生日礼物…',
            hintStyle: TextStyle(color: AppColors.textTertiary, fontSize: 13),
          ),
          onChanged: (v) => controller.setNote(v),
        ),
        const Gap(16),

        _SaveButton(
          canSave: form.canSave,
          label: '记下这笔回报',
          color: AppColors.income,
          hourlyRate: hourlyRate,
        ),
      ],
    );
  }
}

class _ReturnSubCategorySelector extends ConsumerWidget {
  final ReturnCategory category;
  final ReturnSubCategory? selected;

  const _ReturnSubCategorySelector({
    required this.category,
    required this.selected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(addTransactionControllerProvider.notifier);
    final options = _getOptions();

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((opt) {
        return _CategoryChip(
          label: opt.label,
          selected: selected == opt.value,
          onTap: () => controller.setReturnSubCategory(opt.value),
        );
      }).toList(),
    );
  }

  List<_ReturnSubOption> _getOptions() {
    switch (category) {
      case ReturnCategory.material:
        return [
          _ReturnSubOption('收到礼物', ReturnSubCategory.receivedGift),
          _ReturnSubOption('对方买单', ReturnSubCategory.treatMeal),
          _ReturnSubOption('资金转账', ReturnSubCategory.moneyTransfer),
          _ReturnSubOption('其他', ReturnSubCategory.other),
        ];
      case ReturnCategory.emotional:
        return [
          _ReturnSubOption('走心沟通', ReturnSubCategory.deepTalk),
          _ReturnSubOption('情绪支持', ReturnSubCategory.emotionalSupport),
          _ReturnSubOption('制造惊喜', ReturnSubCategory.surprise),
          _ReturnSubOption('其他', ReturnSubCategory.other),
        ];
      case ReturnCategory.action:
        return [
          _ReturnSubOption('分担任务', ReturnSubCategory.shareTask),
          _ReturnSubOption('专属陪伴', ReturnSubCategory.dedicatedTime),
          _ReturnSubOption('其他', ReturnSubCategory.other),
        ];
      case ReturnCategory.other:
        return [_ReturnSubOption('其他', ReturnSubCategory.other)];
    }
  }
}

class _ReturnSubOption {
  final String label;
  final ReturnSubCategory value;
  _ReturnSubOption(this.label, this.value);
}

// ─── Shared Widgets ───────────────────────────────────────────

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 12,
        color: AppColors.textSecondary,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}

class _AmountInput extends StatelessWidget {
  final TextEditingController controller;
  final Color color;
  final ValueChanged<String> onChanged;

  const _AmountInput({
    required this.controller,
    required this.color,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
      ],
      style: GoogleFonts.robotoMono(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
      decoration: InputDecoration(
        prefixText: '¥ ',
        prefixStyle: GoogleFonts.robotoMono(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: color,
        ),
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        hintText: '0.00',
        hintStyle: GoogleFonts.robotoMono(
          fontSize: 28,
          color: AppColors.textQuaternary,
        ),
      ),
      onChanged: onChanged,
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.expense.withAlpha(15)
              : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.expense : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: selected ? AppColors.expense : AppColors.textSecondary,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

class _SaveButton extends ConsumerWidget {
  final bool canSave;
  final String label;
  final Color color;
  final double hourlyRate;
  final VoidCallback? onTapOverride;

  const _SaveButton({
    required this.canSave,
    required this.label,
    required this.color,
    required this.hourlyRate,
    this.onTapOverride,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locked = GraduationService.isGraduated;
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.surfaceVariant,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        onPressed: (!canSave || locked)
            ? null
            : () {
                HapticFeedback.mediumImpact();
                if (onTapOverride != null) {
                  onTapOverride!();
                  return;
                }
                ref
                    .read(addTransactionControllerProvider.notifier)
                    .save(hourlyRate);
                Navigator.pop(context);
              },
        child: Text(
          locked ? '账单已封存' : label,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

// ─── Helper Classes ───────────────────────────────────────────

class _SubOption {
  final String label;
  final ExpenseSubCategory value;
  _SubOption(this.label, this.value);
}

class _LaborSubOption {
  final String label;
  final LaborSubCategory value;
  _LaborSubOption(this.label, this.value);
}
