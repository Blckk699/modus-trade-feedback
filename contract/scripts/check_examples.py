"""Проверяет, что все примеры в openapi.yaml соответствуют схемам.

Redocly трактует `nullable` рядом с `allOf` по-разному в разных версиях, поэтому примеры
проверяются здесь: схема OpenAPI 3.0 переводится в JSON Schema с учётом `nullable`.

Запуск: uv run --with pyyaml --with jsonschema python scripts/check_examples.py
"""
import copy
import sys
from pathlib import Path

import jsonschema
import yaml

ROOT = Path(__file__).resolve().parent.parent
spec = yaml.safe_load((ROOT / "openapi.yaml").read_text())


def resolve(ref):
    node = spec
    for part in ref.lstrip("#/").split("/"):
        node = node[part.replace("~1", "/").replace("~0", "~")]
    return node


def to_json_schema(s):
    if isinstance(s, list):
        return [to_json_schema(x) for x in s]
    if not isinstance(s, dict):
        return s
    s = {k: to_json_schema(v) for k, v in s.items() if k not in ("example", "examples", "description", "format")}
    if "$ref" in s:
        s["$ref"] = s["$ref"]
    if s.pop("nullable", False):
        return {"anyOf": [{k: v for k, v in s.items()}, {"type": "null"}]}
    return s


defs = {name: to_json_schema(sch) for name, sch in spec["components"]["schemas"].items()}


def validate(value, schema, where):
    js = to_json_schema(schema)
    js = copy.deepcopy(js)
    root = {"components": {"schemas": defs}, **js}
    try:
        jsonschema.validate(value, root, cls=jsonschema.Draft7Validator)
    except jsonschema.ValidationError as e:
        path = "/".join(str(p) for p in e.absolute_path)
        print(f"FAIL {where} at {path or '<root>'}: {e.message[:200]}")
        return False
    return True


def example_values(media):
    if "example" in media:
        yield "example", media["example"]
    for name, ex in (media.get("examples") or {}).items():
        if "$ref" in ex:
            ex = resolve(ex["$ref"])
        yield name, ex["value"]


ok = True
count = 0
for path, item in spec["paths"].items():
    for method, op in item.items():
        if method == "parameters":
            continue
        rb = op.get("requestBody")
        bodies = []
        if rb:
            bodies.append(("request", rb))
        for code, resp in op.get("responses", {}).items():
            if "$ref" in resp:
                resp = resolve(resp["$ref"])
            bodies.append((code, resp))
        for label, body in bodies:
            for ctype, media in (body.get("content") or {}).items():
                if "schema" not in media:
                    continue
                for name, value in example_values(media):
                    count += 1
                    ok &= validate(value, media["schema"], f"{method.upper()} {path} {label} {name}")

print(f"checked {count} examples")
sys.exit(0 if ok else 1)
