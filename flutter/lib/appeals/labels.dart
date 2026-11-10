import 'package:modus_api/api.dart';

/// Подписи статусов, типов, приоритетов и ролей приходят из `GET /dictionaries`
/// (`SessionController.statusLabel` и др.). Здесь — то, чего в справочнике нет;
/// тексты совпадают с `web/src/appeals/labels.ts`.

String dueStateLabel(DueState state) => switch (state) {
      DueState.onTime => 'В срок',
      DueState.dueSoon => 'Срок скоро',
      DueState.overdue => 'Просрочено',
      DueState.answered => 'Ответ дан',
      DueState.noDeadline => 'Без срока',
    };

String historyKindLabel(HistoryEventKindEnum kind) => switch (kind) {
      HistoryEventKindEnum.created => 'Обращение подано',
      HistoryEventKindEnum.assigned => 'Назначен ответственный',
      HistoryEventKindEnum.reassigned => 'Ответственный переназначен',
      HistoryEventKindEnum.statusChanged => 'Статус изменён',
      HistoryEventKindEnum.deadlineSet => 'Назначен срок',
      HistoryEventKindEnum.clarificationRequested => 'Задан уточняющий вопрос',
      HistoryEventKindEnum.clarificationAnswered => 'Получен ответ на вопрос',
      HistoryEventKindEnum.escalated => 'Эскалация',
      HistoryEventKindEnum.merged => 'Склеено с другим обращением',
      HistoryEventKindEnum.participantAdded => 'Добавлен участник',
      HistoryEventKindEnum.attachmentAdded => 'Добавлено вложение',
      HistoryEventKindEnum.discussionPublished => 'Вынесено на обсуждение',
      HistoryEventKindEnum.discussionClosed => 'Обсуждение завершено',
      HistoryEventKindEnum.bitrixTaskCreated => 'Создана задача в Битрикс24',
      HistoryEventKindEnum.fieldChanged => 'Изменено поле',
    };

String closedReasonLabel(ClosedReason reason) => switch (reason) {
      ClosedReason.feedbackAccepted => 'Отзыв принят',
      ClosedReason.merged => 'Присоединено к другому обращению',
    };
