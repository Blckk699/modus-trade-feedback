import type { AuthMethod } from '../types';
import { devLoginMethod } from './devLogin';
import { miniAppMethod } from './miniApp';
import { telegramWidgetMethod } from './telegramWidget';

/**
 * Способы входа по порядку. Сначала пробуются autoLogin, затем экран входа показывает LoginButton.
 * Вход Mini App (T-06) первым: внутри Telegram пользователь входит по initData без экрана входа.
 */
export const authMethods: AuthMethod[] = [miniAppMethod, telegramWidgetMethod, devLoginMethod];
