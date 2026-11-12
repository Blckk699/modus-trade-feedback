"""Уменьшенные копии картинок-вложений.

Копия делается при первом запросе и кладётся рядом с файлом (`<файл>.preview.jpg`), дальше отдаётся готовая.
"""

from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageOps

PREVIEW_TYPES = frozenset({"image/jpeg", "image/png", "image/webp", "image/gif"})
PREVIEW_SIZE = (480, 480)
PREVIEW_SUFFIX = ".preview.jpg"
# Защита от «бомб»: картинку больше 100 Мп не разбираем, клиент покажет значок файла.
MAX_PIXELS = 100_000_000


def has_preview(content_type: str) -> bool:
    return content_type.split(";")[0].strip().lower() in PREVIEW_TYPES


def preview_path(source: Path) -> Path:
    return source.with_name(source.name + PREVIEW_SUFFIX)


def build_preview(source: Path) -> Path | None:
    """Путь к уменьшенной копии или None, если файл не читается как картинка. Блокирующая функция."""
    target = preview_path(source)
    if target.is_file():
        return target
    try:
        with Image.open(source) as image:
            if image.width * image.height > MAX_PIXELS:
                return None
            image.draft("RGB", PREVIEW_SIZE)  # JPEG сразу читается уменьшенным
            image.seek(0)  # у анимации — первый кадр
            frame = ImageOps.exif_transpose(image)
            frame.thumbnail(PREVIEW_SIZE)
            if frame.mode in ("RGBA", "LA", "P"):
                frame = frame.convert("RGBA")
                canvas = Image.new("RGB", frame.size, "white")
                canvas.paste(frame, mask=frame.getchannel("A"))
                frame = canvas
            else:
                frame = frame.convert("RGB")
            temporary = target.with_name(target.name + ".tmp")
            frame.save(temporary, "JPEG", quality=80, optimize=True)
            temporary.replace(target)
    except Exception:  # noqa: BLE001 — битый или не тот файл: превью нет, это не ошибка сервера
        return None
    return target


def remove_files(source: Path) -> None:
    """Удаляет файл вложения и его уменьшенную копию. Отсутствие файла — не ошибка."""
    source.unlink(missing_ok=True)
    preview_path(source).unlink(missing_ok=True)
