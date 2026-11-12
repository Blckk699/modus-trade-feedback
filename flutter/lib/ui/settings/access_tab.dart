import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:modus_api/api.dart';

import '../../api/app_error.dart';
import '../../app.dart';
import '../../format.dart';
import '../../theme/modus_theme.dart';
import '../sheet_header.dart';

/// Роли, которые можно выдать по заявке или приглашению. Собственника — нельзя (SPEC, «Регистрация и приглашения»).
const assignableRoles = [AssignableRole.employee, AssignableRole.head, AssignableRole.admin];

String inviteStateLabel(InviteState s) => switch (s) {
      InviteState.active => 'Действует',
      InviteState.expired => 'Истекло',
      InviteState.revoked => 'Отозвано',
      _ => 'Использовано',
    };

String _requestStatusLabel(AccessRequestStatus s) => switch (s) {
      AccessRequestStatus.pending => 'Новые',
      AccessRequestStatus.approved => 'Одобрены',
      _ => 'Отклонены',
    };

/// Срок 1–30 дней, использований 1–100 (контракт B-18). Текст ошибки или null.
String? inviteFormError(String days, String uses) {
  final d = int.tryParse(days.trim());
  final u = int.tryParse(uses.trim());
  if (d == null || d < 1 || d > 30) return 'Срок действия: от 1 до 30 дней.';
  if (u == null || u < 1 || u > 100) return 'Число использований: от 1 до 100.';
  return null;
}

/// Вкладка «Доступ»: заявки и приглашения (истории 71–74), как `AccessRequestsTab` и `InvitesTab` в вебе.
class AccessTab extends StatelessWidget {
  const AccessTab({super.key});

  @override
  Widget build(BuildContext context) => DefaultTabController(
        length: 2,
        child: Column(children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: TabBar(
              tabs: [
                Tab(key: Key('access-requests'), text: 'Заявки'),
                Tab(key: Key('access-invites'), text: 'Приглашения'),
              ],
            ),
          ),
          const Expanded(child: TabBarView(children: [_RequestsView(), _InvitesView()])),
        ]),
      );
}

// ───────── заявки ─────────

class _RequestsView extends StatefulWidget {
  const _RequestsView();

  @override
  State<_RequestsView> createState() => _RequestsViewState();
}

class _RequestsViewState extends State<_RequestsView> {
  AccessRequestStatus _status = AccessRequestStatus.pending;
  late Future<(List<AccessRequest>, List<Department>)> _data = _load();

  Future<(List<AccessRequest>, List<Department>)> _load() async {
    final api = SessionScope.read(context).api;
    final page = await api.access.listAccessRequests(status: _status, pageSize: 50);
    final deps = await api.dictionaries.listDepartments().catchError((Object _) => <Department>[]);
    return (page?.items ?? const <AccessRequest>[], deps ?? const <Department>[]);
  }

  void _reload() {
    final next = _load();
    setState(() {
      _data = next;
    });
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async => _reload(),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
        children: [
          SegmentedButton<AccessRequestStatus>(
            key: const Key('request-status'),
            showSelectedIcon: false,
            segments: [
              for (final s in AccessRequestStatus.values) ButtonSegment(value: s, label: Text(_requestStatusLabel(s))),
            ],
            selected: {_status},
            onSelectionChanged: (v) {
              _status = v.first;
              _reload();
            },
          ),
          const SizedBox(height: 12),
          FutureBuilder<(List<AccessRequest>, List<Department>)>(
            future: _data,
            builder: (context, s) {
              if (s.hasError) {
                return Text(AppError.from(s.error!).message, style: TextStyle(color: ModusColors.of(context).danger));
              }
              final data = s.data;
              if (data == null) return const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator()));
              final (items, deps) = data;
              if (items.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    _status == AccessRequestStatus.pending
                        ? 'Новых заявок нет. Бот сообщит, когда кто-то подаст заявку на доступ.'
                        : 'Заявок нет.',
                    textAlign: TextAlign.center,
                  ),
                );
              }
              return Column(children: [
                for (final r in items)
                  _RequestCard(
                    key: Key('request-${r.id}'),
                    request: r,
                    departments: deps,
                    onDecided: (_) => _reload(),
                  ),
              ]);
            },
          ),
        ],
      ),
    );
  }
}

class _RequestCard extends StatefulWidget {
  const _RequestCard({super.key, required this.request, required this.departments, required this.onDecided});

  final AccessRequest request;
  final List<Department> departments;
  final ValueChanged<AccessRequest> onDecided;

  @override
  State<_RequestCard> createState() => _RequestCardState();
}

class _RequestCardState extends State<_RequestCard> {
  AssignableRole _role = AssignableRole.employee;
  late int? _departmentId = widget.request.department?.id;
  bool _rejecting = false;
  final _reason = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  Future<void> _run(Future<AccessRequest?> Function() call) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final r = await call();
      if (r != null) widget.onDecided(r);
    } catch (e) {
      if (mounted) setState(() => _error = AppError.from(e).message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.request;
    final theme = Theme.of(context);
    final c = ModusColors.of(context);
    final session = SessionScope.of(context);
    final api = session.api.access;
    final pending = r.status == AccessRequestStatus.pending;
    final deps = [...widget.departments]..sort((a, b) => a.name.compareTo(b.name));
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: c.card, borderRadius: BorderRadius.circular(WebLook.tileRadius)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(r.fullName, style: theme.textTheme.titleSmall),
        const SizedBox(height: 2),
        Text(
          [
            if (r.email != null) r.email!,
            if (r.telegramUsername != null) '@${r.telegramUsername}',
            r.department?.name ?? 'подразделение не указано',
            formatDateTime(r.updatedAt),
          ].join(' · '),
          style: theme.textTheme.bodySmall,
        ),
        if (r.comment != null) ...[const SizedBox(height: 6), Text(r.comment!)],
        if (r.status == AccessRequestStatus.approved)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              'Одобрена: ${r.assignedRole != null ? session.roleLabel(Role.fromJson(r.assignedRole!.toJson())!) : '—'}'
              '${r.assignedDepartment != null ? ', ${r.assignedDepartment!.name}' : ''}'
              ' · ${r.decidedBy?.fullName ?? ''}',
              style: theme.textTheme.bodySmall,
            ),
          ),
        if (r.status == AccessRequestStatus.rejected)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              'Отклонена${r.rejectReason != null ? ': ${r.rejectReason}' : ''} · ${r.decidedBy?.fullName ?? ''}',
              style: theme.textTheme.bodySmall,
            ),
          ),
        if (pending) ...[
          const SizedBox(height: 12),
          DropdownButtonFormField<AssignableRole>(
            key: Key('request-role-${r.id}'),
            initialValue: _role,
            decoration: const InputDecoration(labelText: 'Роль'),
            items: [
              for (final role in assignableRoles)
                DropdownMenuItem(value: role, child: Text(session.roleLabel(Role.fromJson(role.toJson())!))),
            ],
            onChanged: _busy ? null : (v) => setState(() => _role = v ?? _role),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<int?>(
            key: Key('request-department-${r.id}-${deps.length}'),
            initialValue: deps.any((d) => d.id == _departmentId) ? _departmentId : null,
            decoration: const InputDecoration(labelText: 'Подразделение'),
            items: [
              const DropdownMenuItem<int?>(value: null, child: Text('Без подразделения')),
              for (final d in deps) DropdownMenuItem<int?>(value: d.id, child: Text(d.name)),
            ],
            onChanged: _busy ? null : (v) => setState(() => _departmentId = v),
          ),
          if (_rejecting) ...[
            const SizedBox(height: 8),
            TextField(
              key: Key('request-reason-${r.id}'),
              controller: _reason,
              enabled: !_busy,
              decoration: const InputDecoration(
                labelText: 'Причина отказа',
                helperText: 'Необязательно, придёт заявителю',
              ),
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: TextStyle(color: c.danger)),
          ],
          const SizedBox(height: 12),
          Wrap(spacing: 8, runSpacing: 8, children: [
            if (!_rejecting) ...[
              FilledButton(
                key: Key('request-approve-${r.id}'),
                onPressed: _busy
                    ? null
                    : () => _run(() => api.approveAccessRequest(
                          r.id,
                          AccessRequestApprove(role: _role, departmentId: _departmentId),
                        )),
                child: Text(_busy ? 'Сохраняем…' : 'Одобрить'),
              ),
              OutlinedButton(
                key: Key('request-reject-${r.id}'),
                style: dangerButtonStyle(context),
                onPressed: _busy ? null : () => setState(() => _rejecting = true),
                child: const Text('Отклонить'),
              ),
            ] else ...[
              OutlinedButton(
                key: Key('request-reject-confirm-${r.id}'),
                style: dangerButtonStyle(context),
                onPressed: _busy
                    ? null
                    : () => _run(() => api.rejectAccessRequest(
                          r.id,
                          AccessRequestReject(reason: _reason.text.trim().isEmpty ? null : _reason.text.trim()),
                        )),
                child: const Text('Отклонить заявку'),
              ),
              TextButton(
                onPressed: _busy ? null : () => setState(() => _rejecting = false),
                child: const Text('Отмена'),
              ),
            ],
          ]),
        ],
      ]),
    );
  }
}

// ───────── приглашения ─────────

class _InvitesView extends StatefulWidget {
  const _InvitesView();

  @override
  State<_InvitesView> createState() => _InvitesViewState();
}

class _InvitesViewState extends State<_InvitesView> {
  late Future<List<Invite>> _data = _load();

  Future<List<Invite>> _load() async =>
      await SessionScope.read(context).api.access.listInvites(includeInactive: true) ?? const <Invite>[];

  void _reload() {
    final next = _load();
    setState(() {
      _data = next;
    });
  }

  Future<void> _create() async {
    final api = SessionScope.read(context).api;
    final deps = await api.dictionaries.listDepartments().catchError((Object _) => <Department>[]) ?? const <Department>[];
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      // Ссылки показываются один раз — лист не закрывается случайным тапом мимо.
      isDismissible: false,
      enableDrag: false,
      builder: (_) => _CreateInviteSheet(departments: deps),
    );
    _reload();
  }

  Future<void> _revoke(Invite inv) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await SessionScope.read(context).api.access.revokeInvite(inv.id);
      _reload();
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(AppError.from(e).message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = ModusColors.of(context);
    final session = SessionScope.of(context);
    return RefreshIndicator(
      onRefresh: () async => _reload(),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
        children: [
          Text(
            'По ссылке человек сразу получает доступ с заданной ролью и подразделением, без заявки.',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton.icon(
              key: const Key('invite-create'),
              onPressed: _create,
              icon: const Icon(Icons.link_rounded),
              label: const Text('Создать приглашение'),
            ),
          ),
          const SizedBox(height: 12),
          FutureBuilder<List<Invite>>(
            future: _data,
            builder: (context, s) {
              if (s.hasError) return Text(AppError.from(s.error!).message, style: TextStyle(color: c.danger));
              final items = s.data;
              if (items == null) return const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator()));
              if (items.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('Приглашений пока нет. Создайте первое и отправьте ссылку человеку.', textAlign: TextAlign.center),
                );
              }
              return Column(children: [
                for (final inv in items)
                  Container(
                    key: Key('invite-${inv.id}'),
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: c.card, borderRadius: BorderRadius.circular(WebLook.tileRadius)),
                    child: Row(children: [
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(
                            [
                              session.roleLabel(Role.fromJson(inv.role.toJson())!),
                              if (inv.department != null) inv.department!.name,
                              if (inv.fullName != null) inv.fullName!,
                            ].join(' · '),
                            style: theme.textTheme.titleSmall,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'до ${formatDateTime(inv.expiresAt)} · использовано ${inv.usedCount} из ${inv.maxUses} · ${inv.createdBy.fullName}',
                            style: theme.textTheme.bodySmall,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            inviteStateLabel(inv.state),
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: inv.state == InviteState.active ? c.success : c.muted,
                            ),
                          ),
                        ]),
                      ),
                      if (inv.state == InviteState.active)
                        TextButton(
                          key: Key('invite-revoke-${inv.id}'),
                          style: TextButton.styleFrom(foregroundColor: c.danger),
                          onPressed: () => _revoke(inv),
                          child: const Text('Отозвать'),
                        ),
                    ]),
                  ),
              ]);
            },
          ),
        ],
      ),
    );
  }
}

class _CreateInviteSheet extends StatefulWidget {
  const _CreateInviteSheet({required this.departments});

  final List<Department> departments;

  @override
  State<_CreateInviteSheet> createState() => _CreateInviteSheetState();
}

class _CreateInviteSheetState extends State<_CreateInviteSheet> {
  AssignableRole _role = AssignableRole.employee;
  int? _departmentId;
  final _name = TextEditingController();
  final _days = TextEditingController(text: '7');
  final _uses = TextEditingController(text: '1');
  bool _busy = false;
  String? _error;
  InviteCreated? _created;

  @override
  void dispose() {
    for (final c in [_name, _days, _uses]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    final invalid = inviteFormError(_days.text, _uses.text);
    if (invalid != null) return setState(() => _error = invalid);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final created = await SessionScope.read(context).api.access.createInvite(InviteCreate(
            role: _role,
            departmentId: _departmentId,
            fullName: _name.text.trim().isEmpty ? null : _name.text.trim(),
            expiresInDays: int.parse(_days.text.trim()),
            maxUses: int.parse(_uses.text.trim()),
          ));
      if (mounted) setState(() => _created = created);
    } catch (e) {
      if (mounted) setState(() => _error = AppError.from(e).message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = SessionScope.of(context);
    final deps = [...widget.departments]..sort((a, b) => a.name.compareTo(b.name));
    final created = _created;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: created != null
                ? [
                    const SheetHeader('Приглашение создано'),
                    Text(
                      'Скопируйте или отправьте ссылку сейчас. Позже её посмотреть нельзя.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 12),
                    _LinkRow(key: const Key('invite-bot-link'), label: 'Через бота в Telegram', value: created.botLink),
                    _LinkRow(key: const Key('invite-web-link'), label: 'Через браузер', value: created.webLink),
                    const SizedBox(height: 8),
                    FilledButton(
                      key: const Key('invite-done'),
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Готово'),
                    ),
                  ]
                : [
                    SheetHeader('Новое приглашение', enabled: !_busy),
                    DropdownButtonFormField<AssignableRole>(
                      key: const Key('invite-role'),
                      initialValue: _role,
                      decoration: const InputDecoration(labelText: 'Роль'),
                      items: [
                        for (final role in assignableRoles)
                          DropdownMenuItem(value: role, child: Text(session.roleLabel(Role.fromJson(role.toJson())!))),
                      ],
                      onChanged: _busy ? null : (v) => setState(() => _role = v ?? _role),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<int?>(
                      key: const Key('invite-department'),
                      initialValue: _departmentId,
                      decoration: const InputDecoration(labelText: 'Подразделение'),
                      items: [
                        const DropdownMenuItem<int?>(value: null, child: Text('Без подразделения')),
                        for (final d in deps) DropdownMenuItem<int?>(value: d.id, child: Text(d.name)),
                      ],
                      onChanged: _busy ? null : (v) => setState(() => _departmentId = v),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      key: const Key('invite-name'),
                      controller: _name,
                      enabled: !_busy,
                      decoration: const InputDecoration(labelText: 'Имя', helperText: 'Необязательно'),
                    ),
                    const SizedBox(height: 10),
                    Row(children: [
                      Expanded(
                        child: TextField(
                          key: const Key('invite-days'),
                          controller: _days,
                          enabled: !_busy,
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          decoration: const InputDecoration(labelText: 'Действует, дней'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          key: const Key('invite-uses'),
                          controller: _uses,
                          enabled: !_busy,
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          decoration: const InputDecoration(labelText: 'Использований'),
                        ),
                      ),
                    ]),
                    if (_error != null) ...[
                      const SizedBox(height: 8),
                      Text(_error!, key: const Key('invite-error'), style: TextStyle(color: ModusColors.of(context).danger)),
                    ],
                    const SizedBox(height: 14),
                    FilledButton(
                      key: const Key('invite-submit'),
                      onPressed: _busy ? null : _submit,
                      child: Text(_busy ? 'Создаём…' : 'Создать ссылку'),
                    ),
                  ],
          ),
        ),
      ),
    );
  }
}

/// Ссылка приглашения: копировать в буфер или отправить системным меню «Поделиться».
class _LinkRow extends StatelessWidget {
  const _LinkRow({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = ModusColors.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(14, 10, 6, 10),
      decoration: BoxDecoration(color: c.surface2, borderRadius: BorderRadius.circular(WebLook.controlRadius)),
      child: Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: theme.textTheme.labelSmall),
            SelectableText(value, maxLines: 2, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface)),
          ]),
        ),
        IconButton(
          tooltip: 'Копировать',
          icon: const Icon(Icons.copy_rounded),
          onPressed: () async {
            await Clipboard.setData(ClipboardData(text: value));
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ссылка скопирована')));
            }
          },
        ),
      ]),
    );
  }
}
