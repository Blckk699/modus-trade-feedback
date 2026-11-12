//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

library openapi.api;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:http/http.dart';
import 'package:intl/intl.dart';
import 'package:meta/meta.dart';

part 'api_client.dart';
part 'api_helper.dart';
part 'api_exception.dart';
part 'auth/authentication.dart';
part 'auth/api_key_auth.dart';
part 'auth/oauth.dart';
part 'auth/http_basic_auth.dart';
part 'auth/http_bearer_auth.dart';

part 'api/access_api.dart';
part 'api/admin_api.dart';
part 'api/analytics_api.dart';
part 'api/appeal_actions_api.dart';
part 'api/appeals_api.dart';
part 'api/attachments_api.dart';
part 'api/auth_api.dart';
part 'api/bitrix_api.dart';
part 'api/bot_api.dart';
part 'api/dictionaries_api.dart';
part 'api/discussions_api.dart';
part 'api/drafts_api.dart';
part 'api/duplicates_api.dart';
part 'api/feed_api.dart';
part 'api/me_api.dart';
part 'api/meetings_api.dart';
part 'api/messages_api.dart';
part 'api/notifications_api.dart';
part 'api/system_api.dart';

part 'model/accept_feedback_request.dart';
part 'model/access_request.dart';
part 'model/access_request_approve.dart';
part 'model/access_request_page.dart';
part 'model/access_request_reject.dart';
part 'model/access_request_status.dart';
part 'model/access_request_submit.dart';
part 'model/access_status.dart';
part 'model/ack_notification_request.dart';
part 'model/admin_update_settings_request.dart';
part 'model/analytics_summary.dart';
part 'model/appeal.dart';
part 'model/appeal_action.dart';
part 'model/appeal_create.dart';
part 'model/appeal_draft.dart';
part 'model/appeal_list_item.dart';
part 'model/appeal_page.dart';
part 'model/appeal_ref.dart';
part 'model/appeal_scope.dart';
part 'model/appeal_source.dart';
part 'model/appeal_status.dart';
part 'model/appeal_type.dart';
part 'model/assignable_role.dart';
part 'model/assignee_load.dart';
part 'model/attachment.dart';
part 'model/auth_methods.dart';
part 'model/bitrix_task.dart';
part 'model/bot_notification.dart';
part 'model/bot_notification_all_of_recipient.dart';
part 'model/category.dart';
part 'model/category_ref.dart';
part 'model/category_update.dart';
part 'model/category_write.dart';
part 'model/close_discussion_request.dart';
part 'model/closed_reason.dart';
part 'model/code_login_request.dart';
part 'model/count_by_category.dart';
part 'model/count_by_status.dart';
part 'model/count_by_type.dart';
part 'model/credentials_update.dart';
part 'model/deadline_rule.dart';
part 'model/department.dart';
part 'model/department_ref.dart';
part 'model/department_update.dart';
part 'model/department_write.dart';
part 'model/dev_login_request.dart';
part 'model/dictionaries.dart';
part 'model/dictionaries_actions_inner.dart';
part 'model/dictionaries_statuses_inner.dart';
part 'model/digest.dart';
part 'model/discussion.dart';
part 'model/discussion_appeal.dart';
part 'model/discussion_comment.dart';
part 'model/discussion_create.dart';
part 'model/discussion_page.dart';
part 'model/discussion_ref.dart';
part 'model/discussion_status.dart';
part 'model/due_filter.dart';
part 'model/due_state.dart';
part 'model/duplicate_suggestion.dart';
part 'model/email_login.dart';
part 'model/email_register.dart';
part 'model/error.dart';
part 'model/error_code.dart';
part 'model/error_error.dart';
part 'model/exchange_bitrix_login_request.dart';
part 'model/fail_notification_request.dart';
part 'model/feed_item.dart';
part 'model/feed_page.dart';
part 'model/get_health200_response.dart';
part 'model/history_event.dart';
part 'model/implement_appeal_request.dart';
part 'model/invite.dart';
part 'model/invite_accept.dart';
part 'model/invite_accepted.dart';
part 'model/invite_create.dart';
part 'model/invite_created.dart';
part 'model/invite_preview.dart';
part 'model/invite_state.dart';
part 'model/labeled_code.dart';
part 'model/login_code.dart';
part 'model/mark_read_request.dart';
part 'model/me.dart';
part 'model/meeting.dart';
part 'model/meeting_brief.dart';
part 'model/meeting_draft.dart';
part 'model/meeting_draft_status.dart';
part 'model/meeting_draft_update.dart';
part 'model/meeting_status.dart';
part 'model/merge_appeal_request.dart';
part 'model/message.dart';
part 'model/mini_app_login_request.dart';
part 'model/name_consent.dart';
part 'model/notification.dart';
part 'model/notification_button.dart';
part 'model/notification_button_type.dart';
part 'model/notification_kind.dart';
part 'model/notification_page.dart';
part 'model/permissions.dart';
part 'model/post_message_request.dart';
part 'model/priority.dart';
part 'model/reassign_appeal_request.dart';
part 'model/register_result.dart';
part 'model/reject_appeal_request.dart';
part 'model/repeated_topic.dart';
part 'model/request_info_request.dart';
part 'model/role.dart';
part 'model/session.dart';
part 'model/session_token.dart';
part 'model/set_name_consent_request.dart';
part 'model/start_work_request.dart';
part 'model/stuck_appeal.dart';
part 'model/switch_account_request.dart';
part 'model/system_settings.dart';
part 'model/take_appeal_request.dart';
part 'model/telegram_identity.dart';
part 'model/telegram_widget_login_request.dart';
part 'model/temporary_password.dart';
part 'model/text_draft_request.dart';
part 'model/unread_count.dart';
part 'model/user.dart';
part 'model/user_brief.dart';
part 'model/user_create.dart';
part 'model/user_update.dart';
part 'model/viewer_relation.dart';
part 'model/vote_request.dart';
part 'model/vote_value.dart';


/// An [ApiClient] instance that uses the default values obtained from
/// the OpenAPI specification file.
var defaultApiClient = ApiClient();

const _delimiters = {'csv': ',', 'ssv': ' ', 'tsv': '\t', 'pipes': '|'};
const _dateEpochMarker = 'epoch';
const _deepEquality = DeepCollectionEquality();
final _dateFormatter = DateFormat('yyyy-MM-dd');
final _regList = RegExp(r'^List<(.*)>$');
final _regSet = RegExp(r'^Set<(.*)>$');
final _regMap = RegExp(r'^Map<String,(.*)>$');

bool _isEpochMarker(String? pattern) => pattern == _dateEpochMarker || pattern == '/$_dateEpochMarker/';
