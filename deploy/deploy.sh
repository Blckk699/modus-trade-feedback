#!/bin/sh
# Выкладка main на сервер systm одной командой (из корня репозитория на машине оркестратора):
#   sh deploy/deploy.sh            код из origin/main
#   sh deploy/deploy.sh <ref>      другая ветка или коммит
# Нужен ssh-доступ `systm`. Ключи на сервере лежат в /opt/modus/secrets.env и сюда не передаются.
set -e
REF=${1:-origin/main}
HOST=${DEPLOY_HOST:-systm}
DIR=/opt/modus

git fetch -q origin
SHA=$(git rev-parse --short "$REF")
echo "Выкладываю $REF ($SHA) на $HOST:$DIR"

git archive --format=tar "$REF" | ssh "$HOST" "set -e; umask 022; mkdir -p $DIR/seed $DIR/web-dist; rm -rf $DIR/src.new; mkdir $DIR/src.new; tar -x -C $DIR/src.new; rm -rf $DIR/src; mv $DIR/src.new $DIR/src; echo $SHA > $DIR/src/REVISION"

ssh "$HOST" "set -e; cd $DIR
  umask 077
  [ -f .env ] || echo POSTGRES_PASSWORD=\$(head -c 24 /dev/urandom | od -An -tx1 | tr -d ' \n') > .env
  [ -f secrets.env ] || { echo 'Нет /opt/modus/secrets.env с ключами'; exit 1; }
  umask 022
  # Веб собирается в контейнере node: адрес API — тот же домен, dev-вход выключен.
  docker run --rm -v $DIR/src/web:/w -w /w \
    -e VITE_API_BASE_URL=https://modus.systm.kz -e VITE_DEV_LOGIN=false -e VITE_TELEGRAM_BOT_USERNAME=modus_fb_bot -e VITE_TELEGRAM_BOT_ID=9253046478 \
    node:24-alpine sh -c 'npm ci --no-audit --no-fund >/dev/null && npm run build >/dev/null'
  # Обновляем содержимое на месте: nginx смонтировал саму папку web-dist, подмена папки оставила бы его на удалённой.
  mkdir -p web-dist && find web-dist -mindepth 1 -delete && cp -R src/web/dist/. web-dist/
  docker compose -f src/deploy/compose.yml --project-directory $DIR --env-file .env --env-file secrets.env up -d --build --remove-orphans
  # API после пересборки поднимается секунд 20 (миграции, сид): ждём здоровья до минуты.
  i=0; until curl -sf -m 5 http://127.0.0.1:18000/api/v1/health >/dev/null || [ \$i -ge 30 ]; do i=\$((i+1)); sleep 2; done
  docker compose -f src/deploy/compose.yml --project-directory $DIR ps --format '{{.Service}}: {{.Status}}'
  printf 'API: '; curl -s -m 10 http://127.0.0.1:18000/api/v1/health; echo
  printf 'Веб: '; curl -s -m 10 -o /dev/null -w '%{http_code}\n' http://127.0.0.1:18080/"
echo "Выложено: $SHA"
