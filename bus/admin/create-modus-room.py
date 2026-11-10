# Создаёт на шине комнату modus и пять агентов. Запускается один раз внутри контейнера шины:
#   docker exec syst-m-bus-hub-1 python /app/mkroom-modus.py
# Перед изменениями делает резервную копию базы. Токены не печатает: пишет их в /app/modus-tokens/<агент>.token (0600).
import os
import sqlite3
import sys
import time

sys.path[:0] = ["/app", "/app/pylib"]
import hub  # noqa: E402

con = hub.db()
if con.execute("SELECT 1 FROM rooms WHERE id='modus'").fetchone():
    raise SystemExit("room modus already exists")
if con.execute("SELECT 1 FROM agents WHERE name LIKE 'modus-%'").fetchone():
    raise SystemExit("modus-* agents already exist")

bak = "/app/bus.db.bak-modus-%s" % time.strftime("%Y%m%d-%H%M%S")
dst = sqlite3.connect(bak)
con.backup(dst)
dst.close()
os.chmod(bak, 0o600)

AGENTS = [
    ("modus-orch", "orchestrator", "Alexander: оркестратор Модус Трейд"),
    ("modus-review", "review", "Alexander: ревьюер PR"),
    ("modus-flutter", "flutter", "Alexander: Flutter"),
    ("modus-back", "backend", "n1kollo: бэкенд"),
    ("modus-front", "web", "klinduhwtf: фронт"),
]

os.makedirs("/app/modus-tokens", mode=0o700, exist_ok=True)


def save(name, tok):
    fd = os.open("/app/modus-tokens/%s.token" % name, os.O_WRONLY | os.O_CREAT | os.O_TRUNC, 0o600)
    os.write(fd, tok.encode())
    os.close(fd)


owner, lane, human = AGENTS[0]
save(owner, hub.add_agent(con, owner, lane, human, room="modus"))
print(hub.room_create(con, {"is_admin": 1, "name": owner}, "modus", "Модус Трейд",
                      "Хакатон ГК «Модус Трейд»: система обращений сотрудников. Репозиторий Blckk699/modus-trade-feedback",
                      owner=owner))
for name, lane, human in AGENTS[1:]:
    save(name, hub.add_agent(con, name, lane, human, room="modus"))

print([tuple(r) for r in con.execute("SELECT room, agent, role FROM room_members WHERE room='modus' ORDER BY agent")])
print("backup:", os.path.basename(bak), "| tokens:", sorted(os.listdir("/app/modus-tokens")))
con.close()
