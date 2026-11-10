import type { AuthMethod } from '../types';
import { devLoginMethod } from './devLogin';
import { telegramWidgetMethod } from './telegramWidget';

/**
 * Способы входа по порядку. Сначала пробуются autoLogin, затем экран входа показывает LoginButton.
 * Вход Mini App (T-06) добавляется сюда первым элементом: файл methods/miniApp.ts с autoLogin
 * по Telegram.WebApp.initData → POST /api/v1/auth/telegram/mini-app. Экраны править не нужно.
 */
export const authMethods: AuthMethod[] = [telegramWidgetMethod, devLoginMethod];
