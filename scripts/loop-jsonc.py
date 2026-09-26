#!/usr/bin/env python3
"""Đọc .cursor/loop.jsonc (hoặc loop.env một project) và ghi file JSONC.

Comment // và /* */ được bỏ khi nằm ngoài chuỗi, nên URL https:// vẫn hợp lệ.
Giữ cột bảng project khớp với Format-ProjectsTable trong scripts/sync-loop.ps1.
"""

from __future__ import annotations

import argparse
import json
import re
import shlex
import sys
from pathlib import Path


def die(message: str) -> None:
    print(f"error: {message}", file=sys.stderr)
    raise SystemExit(1)


def strip_jsonc(text: str) -> str:
    if text.startswith("\ufeff"):
        text = text[1:]
    out: list[str] = []
    i = 0
    n = len(text)
    in_str = False
    escape = False
    while i < n:
        char = text[i]
        if in_str:
            out.append(char)
            if escape:
                escape = False
            elif char == "\\":
                escape = True
            elif char == '"':
                in_str = False
            i += 1
            continue
        if char == '"':
            in_str = True
            out.append(char)
            i += 1
            continue
        if char == "/" and i + 1 < n and text[i + 1] == "/":
            i += 2
            while i < n and text[i] != "\n":
                i += 1
            continue
        if char == "/" and i + 1 < n and text[i + 1] == "*":
            end = text.find("*/", i + 2)
            if end < 0:
                die("comment /* chưa đóng")
            i = end + 2
            continue
        out.append(char)
        i += 1
    if in_str:
        die("chuỗi JSON chưa đóng")
    return "".join(out)


def require_str(value: object, where: str) -> str:
    if not isinstance(value, str) or not value.strip():
        die(f"{where} phải là chuỗi khác rỗng")
    return value.strip()


def table_cell(value: str) -> str:
    return value.replace("\\", "\\\\").replace("|", "\\|").replace("\r", "").replace("\n", " ")


def projects_table(projects: list[dict[str, str]], default_index: int) -> str:
    lines = [
        "| Project | URL | ID | Vai trò |",
        "| --- | --- | --- | --- |",
    ]
    for index, project in enumerate(projects):
        role = "mặc định" if index == default_index else ""
        project_id = project["id"].replace("`", "'")
        lines.append(
            "| {name} | {url} | `{pid}` | {role} |".format(
                name=table_cell(project["name"]),
                url=table_cell(project["url"]),
                pid=table_cell(project_id),
                role=table_cell(role),
            )
        )
    return "\n".join(lines)


def normalize_projects(raw: object) -> tuple[list[dict[str, str]], int]:
    if not isinstance(raw, list) or not raw:
        die("projects phải là mảng có ít nhất một project")
    projects: list[dict[str, str]] = []
    default_indexes: list[int] = []
    seen_ids: set[str] = set()
    for index, item in enumerate(raw):
        if not isinstance(item, dict):
            die(f"projects[{index}] phải là object")
        name = require_str(item.get("name"), f"projects[{index}].name")
        url = require_str(item.get("url"), f"projects[{index}].url")
        project_id = require_str(item.get("id"), f"projects[{index}].id")
        if project_id in seen_ids:
            die(f"trùng project id: {project_id}")
        seen_ids.add(project_id)
        if "default" in item:
            if not isinstance(item["default"], bool):
                die(f'projects[{index}].default phải là boolean')
            if item["default"]:
                default_indexes.append(index)
        projects.append({"name": name, "url": url, "id": project_id})
    if len(default_indexes) > 1:
        die('chỉ được một project có "default": true')
    default_index = default_indexes[0] if default_indexes else 0
    return projects, default_index


def view_from_parts(
    owner: str,
    workspace: str,
    force: bool,
    projects: list[dict[str, str]],
    default_index: int,
) -> dict[str, str]:
    names = ", ".join(project["name"] for project in projects)
    return {
        "OWNER": owner,
        "WORKSPACE": workspace,
        "FORCE_MERGE": "true" if force else "false",
        "DEFAULT_PROJECT_NAME": projects[default_index]["name"],
        "PROJECT_NAMES": names,
        "PROJECTS_TABLE": projects_table(projects, default_index),
    }


def parse_env(text: str) -> dict[str, str]:
    found: dict[str, str] = {}
    for lineno, line in enumerate(text.splitlines(), 1):
        if not line.strip() or line.lstrip().startswith("#"):
            continue
        match = re.match(r"^([A-Za-z_][A-Za-z0-9_]*)=(.*)$", line)
        if not match:
            die(f"dòng không hợp lệ trong loop.env:{lineno}: {line}")
        key, value = match.group(1), match.group(2)
        if len(value) >= 2 and (
            (value[0] == value[-1] == '"') or (value[0] == value[-1] == "'")
        ):
            value = value[1:-1]
        found[key] = value
    return found


def view_from_env(text: str) -> dict[str, str]:
    found = parse_env(text)
    required = (
        "REPLACE_LINEAR_OWNER_DISPLAY_NAME",
        "REPLACE_LINEAR_WORKSPACE",
        "REPLACE_LINEAR_PROJECT_NAME",
        "REPLACE_LINEAR_PROJECT_URL",
        "REPLACE_LINEAR_PROJECT_ID",
    )
    missing = [key for key in required if not found.get(key, "").strip()]
    if missing:
        die("thiếu giá trị trong loop.env: " + ", ".join(missing))
    force_raw = found.get("REPLACE_LOOP_FORCE_MERGE_PR", "true").strip().lower()
    if force_raw not in ("true", "false"):
        die("REPLACE_LOOP_FORCE_MERGE_PR phải là true hoặc false")
    projects = [
        {
            "name": found["REPLACE_LINEAR_PROJECT_NAME"].strip(),
            "url": found["REPLACE_LINEAR_PROJECT_URL"].strip(),
            "id": found["REPLACE_LINEAR_PROJECT_ID"].strip(),
        }
    ]
    return view_from_parts(
        found["REPLACE_LINEAR_OWNER_DISPLAY_NAME"].strip(),
        found["REPLACE_LINEAR_WORKSPACE"].strip(),
        force_raw == "true",
        projects,
        0,
    )


def view_from_jsonc(text: str) -> dict[str, str]:
    try:
        data = json.loads(strip_jsonc(text))
    except json.JSONDecodeError as exc:
        die(f"loop.jsonc không hợp lệ: {exc}")
    if not isinstance(data, dict):
        die("loop.jsonc phải là object")
    owner = require_str(data.get("ownerDisplayName"), "ownerDisplayName")
    workspace = require_str(data.get("workspace"), "workspace")
    if "forceMergePr" not in data:
        force = True
    elif isinstance(data["forceMergePr"], bool):
        force = data["forceMergePr"]
    else:
        die("forceMergePr phải là boolean true/false, không phải chuỗi")
    projects, default_index = normalize_projects(data.get("projects"))
    return view_from_parts(owner, workspace, force, projects, default_index)


def emit(path: Path) -> None:
    text = path.read_text(encoding="utf-8")
    if path.name == "loop.env":
        view = view_from_env(text)
        source_kind = "env"
    else:
        view = view_from_jsonc(text)
        source_kind = "jsonc"
    exported = {
        "LOOP_OWNER": view["OWNER"],
        "LOOP_WORKSPACE": view["WORKSPACE"],
        "LOOP_FORCE_MERGE": view["FORCE_MERGE"],
        "LOOP_DEFAULT_PROJECT_NAME": view["DEFAULT_PROJECT_NAME"],
        "LOOP_PROJECT_NAMES": view["PROJECT_NAMES"],
        "LOOP_PROJECTS_TABLE": view["PROJECTS_TABLE"],
        "LOOP_SOURCE_KIND": source_kind,
    }
    for key, value in exported.items():
        print(f"{key}={shlex.quote(value)}")


def parse_bool_arg(value: str) -> bool:
    lowered = value.lower()
    if lowered == "true":
        return True
    if lowered == "false":
        return False
    die("--force-merge phải là true hoặc false")


def render_jsonc(owner: str, workspace: str, force: bool, projects: list[dict[str, str]]) -> str:
    blocks: list[str] = []
    last = len(projects) - 1
    for index, project in enumerate(projects):
        lines = [
            "    {",
            f'      "name": {json.dumps(project["name"], ensure_ascii=False)},',
            f'      "url": {json.dumps(project["url"], ensure_ascii=False)},',
        ]
        if index == 0:
            lines.append(f'      "id": {json.dumps(project["id"], ensure_ascii=False)},')
            lines.append('      "default": true')
        else:
            lines.append(f'      "id": {json.dumps(project["id"], ensure_ascii=False)}')
        lines.append("    }" + ("," if index != last else ""))
        blocks.append("\n".join(lines))
    force_literal = "true" if force else "false"
    return (
        "{\n"
        "  // Tên hiển thị owner trên Linear — dùng trong comment.\n"
        f'  "ownerDisplayName": {json.dumps(owner, ensure_ascii=False)},\n'
        "\n"
        "  // Slug workspace Linear.\n"
        f'  "workspace": {json.dumps(workspace, ensure_ascii=False)},\n'
        "\n"
        "  // true: agent auto-merge PR sau ce-plan / ce-work / ce-compound.\n"
        "  // false: chỉ tạo PR và gắn URL Linear, chờ owner merge tay.\n"
        f'  "forceMergePr": {force_literal},\n'
        "\n"
        "  // Mọi Linear project quản lý issue của repo này.\n"
        '  // "default": true trên đúng một project — nơi tạo issue mới khi chưa\n'
        "  // xác định được project. Nếu không project nào đánh dấu, project đầu tiên là mặc định.\n"
        '  "projects": [\n'
        + "\n".join(blocks)
        + "\n  ]\n}\n"
    )


def write_config(args: argparse.Namespace) -> None:
    if not args.project:
        die("thiếu --project NAME URL ID")
    raw = []
    for index, (name, url, project_id) in enumerate(args.project):
        item: dict[str, object] = {"name": name, "url": url, "id": project_id}
        if index == 0:
            item["default"] = True
        raw.append(item)
    projects, _default_index = normalize_projects(raw)
    owner = require_str(args.owner, "ownerDisplayName")
    workspace = require_str(args.workspace, "workspace")
    force = parse_bool_arg(args.force_merge)
    text = render_jsonc(owner, workspace, force, projects)
    Path(args.dest).write_text(text, encoding="utf-8")


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="Đọc hoặc ghi loop.jsonc")
    sub = parser.add_subparsers(dest="command", required=True)

    emit_parser = sub.add_parser("emit", help="in biến shell từ loop.jsonc hoặc loop.env")
    emit_parser.add_argument("file")

    write_parser = sub.add_parser("write", help="ghi loop.jsonc từ flag --setup")
    write_parser.add_argument("--dest", required=True)
    write_parser.add_argument("--owner", required=True)
    write_parser.add_argument("--workspace", required=True)
    write_parser.add_argument("--force-merge", default="true")
    write_parser.add_argument(
        "--project",
        nargs=3,
        action="append",
        metavar=("NAME", "URL", "ID"),
    )
    return parser


def main() -> None:
    parser = build_parser()
    args = parser.parse_args()
    if args.command == "emit":
        emit(Path(args.file))
        return
    if args.command == "write":
        write_config(args)
        return
    die(f"lệnh không rõ: {args.command}")


if __name__ == "__main__":
    main()
