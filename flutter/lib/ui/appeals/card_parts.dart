import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:modus_api/api.dart';

import '../../api/app_error.dart';
import '../../app.dart';
import '../../appeals/attachment_files.dart';
import '../../theme/modus_theme.dart';
import '../settings/shared.dart' show assignable, PersonField;

/// Кому бэкенд отдаёт приватную переписку: автор, ответственный, руководитель подразделения, собственник.
/// Остальным (администратор) `GET /messages` отвечает 403 — блок не рисуем и не запрашиваем (#158).
bool canReadMessages(Appeal a) => a.viewerRelations.any((r) => const {
      ViewerRelation.author,
      ViewerRelation.assignee,
      ViewerRelation.departmentHead,
      ViewerRelation.owner,
    }.contains(r));

/// Обращение без ответственного, и зрителю разрешено назначить (история 70, #157):
/// в карточке блок назначения, а «Переназначить» из действий убираем.
bool needsAssignee(Appeal a) => a.assignee == null && a.allowedActions.contains(AppealAction.reassign);

/// Блок карточки на фоне `--card` со скруглением 24, как `.card` в вебе.
class CardBlock extends StatelessWidget {
  const CardBlock({super.key, this.title, required this.children, this.trailing});

  final String? title;
  final Widget? trailing;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Material, а не DecoratedBox: ListTile внутри рисует отклик на своём Material.
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Material(
        color: ModusColors.of(context).card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(WebLook.cardRadius)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        if (title != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(children: [
              Expanded(child: Text(title!, style: theme.textTheme.titleMedium)),
              ?trailing,
            ]),
          ),
        ...children,
          ]),
        ),
      ),
    );
  }
}

/// Тип обращения чипом рядом со статусом (#192).
class TypeChip extends StatelessWidget {
  const TypeChip(this.type, {super.key});

  final AppealType type;

  @override
  Widget build(BuildContext context) {
    final c = ModusColors.of(context);
    final icon = switch (type) {
      AppealType.problem => Icons.report_problem_outlined,
      AppealType.suggestion => Icons.lightbulb_outline,
      _ => Icons.thumb_up_alt_outlined,
    };
    return Container(
      key: const Key('type-chip'),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: c.surface2, borderRadius: BorderRadius.circular(ModusRadius.pill)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 14, color: c.muted),
        const SizedBox(width: 4),
        Text(SessionScope.of(context).typeLabel(type),
            style: Theme.of(context).textTheme.labelMedium?.copyWith(color: c.muted)),
      ]),
    );
  }
}

/// Назначение ответственного прямо в карточке (#157). Причина обязательна и попадает в историю.
class AssignSection extends StatefulWidget {
  const AssignSection({super.key, required this.appeal, required this.onUpdated});

  final Appeal appeal;
  final ValueChanged<Appeal> onUpdated;

  @override
  State<AssignSection> createState() => _AssignSectionState();
}

class _AssignSectionState extends State<AssignSection> {
  late final Future<List<User>> _users;
  final _reason = TextEditingController();
  int? _assigneeId;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _users = SessionScope.read(context).api.dictionaries.listUsers().then((u) => assignable(u ?? const []));
  }

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final local = _assigneeId == null
        ? 'Выберите ответственного.'
        : _reason.text.trim().isEmpty
            ? 'Напишите причину: она попадёт в историю обращения.'
            : null;
    if (local != null) return setState(() => _error = local);
    setState(() {
      _busy = true;
      _error = null;
    });
    final messenger = ScaffoldMessenger.of(context);
    try {
      final next = await SessionScope.read(context).api.appealActions.reassignAppeal(
            widget.appeal.id,
            ReassignAppealRequest(assigneeId: _assigneeId!, reason: _reason.text.trim()),
          );
      if (next == null) throw const AppError(code: 'internal_error', message: 'Пустой ответ сервера.');
      messenger.showSnackBar(
        SnackBar(content: Text('${next.number}: ответственный — ${next.assignee?.fullName ?? 'назначен'}')),
      );
      widget.onUpdated(next);
    } catch (e) {
      if (mounted) setState(() => _error = AppError.from(e).message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.appeal;
    final c = ModusColors.of(context);
    return Container(
      key: const Key('assign-section'),
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: c.warnBg, borderRadius: BorderRadius.circular(WebLook.cardRadius)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          Icon(Icons.person_add_alt_1_outlined, color: c.warn),
          const SizedBox(width: 8),
          Text('Нет ответственного',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(color: c.warn, fontWeight: FontWeight.w700)),
        ]),
        const SizedBox(height: 4),
        Text(
          '${a.category != null ? 'В категории «${a.category!.name}» ответственный не задан.' : 'Категория не указана.'} '
          'Назначьте, кто ответит автору.',
          style: TextStyle(color: c.warn),
        ),
        const SizedBox(height: 12),
        FutureBuilder<List<User>>(
          future: _users,
          builder: (context, s) => PersonField(
            key: Key('assign-user-${s.hasData}'),
            label: 'Ответственный',
            users: s.data ?? const [],
            value: s.hasData ? _assigneeId : null,
            noneLabel: s.hasData ? 'Выберите сотрудника' : 'Загружаем сотрудников…',
            onChanged: (v) => setState(() {
              _assigneeId = v;
              _error = null;
            }),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          key: const Key('assign-reason'),
          controller: _reason,
          enabled: !_busy,
          decoration: const InputDecoration(labelText: 'Причина — попадёт в историю'),
          onChanged: (_) => setState(() => _error = null),
        ),
        if (_error != null) ...[
          const SizedBox(height: 8),
          Text(_error!, key: const Key('assign-error'), style: TextStyle(color: c.danger)),
        ],
        const SizedBox(height: 12),
        FilledButton(
          key: const Key('assign-submit'),
          onPressed: _busy ? null : _submit,
          child: Text(_busy ? 'Назначаем…' : 'Назначить'),
        ),
      ]),
    );
  }
}

/// Превью картинки-вложения: качаем с токеном и показываем из памяти.
class AttachmentThumb extends StatefulWidget {
  const AttachmentThumb({super.key, required this.attachment, required this.onTap});

  final Attachment attachment;
  final VoidCallback onTap;

  @override
  State<AttachmentThumb> createState() => _AttachmentThumbState();
}

class _AttachmentThumbState extends State<AttachmentThumb> {
  late final Future<List<int>> _bytes;

  @override
  void initState() {
    super.initState();
    _bytes = downloadAttachmentBytes(SessionScope.read(context).api, widget.attachment);
  }

  @override
  Widget build(BuildContext context) {
    final c = ModusColors.of(context);
    return InkWell(
      onTap: widget.onTap,
      borderRadius: BorderRadius.circular(WebLook.tileRadius),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(WebLook.tileRadius),
        child: Container(
          color: c.surface2,
          child: FutureBuilder<List<int>>(
            future: _bytes,
            builder: (context, s) {
              final data = s.data;
              if (data == null) {
                return Center(
                  child: s.hasError
                      ? Icon(Icons.broken_image_outlined, color: c.muted)
                      : const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2)),
                );
              }
              return Image.memory(
                Uint8List.fromList(data),
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Center(child: Icon(Icons.broken_image_outlined, color: c.muted)),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Каркас карточки при загрузке (#188): серые плашки на месте заголовка, бейджей и блоков.
class CardSkeleton extends StatelessWidget {
  const CardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final c = ModusColors.of(context);
    Widget bar(double w, double h, {double r = 8}) => Container(
          width: w,
          height: h,
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(color: c.extra.surface3, borderRadius: BorderRadius.circular(r)),
        );
    return ListView(
      key: const Key('card-skeleton'),
      padding: const EdgeInsets.all(16),
      physics: const NeverScrollableScrollPhysics(),
      children: [
        bar(280, 22),
        bar(200, 22),
        Row(children: [bar(90, 24, r: 99), const SizedBox(width: 8), bar(110, 24, r: 99)]),
        const SizedBox(height: 8),
        bar(double.infinity, 120, r: WebLook.cardRadius),
        bar(double.infinity, 180, r: WebLook.cardRadius),
      ],
    );
  }
}
