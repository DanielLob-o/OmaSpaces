"""Shared helpers for the lint checks. Standard library only, so CI needs no installs."""
from pathlib import Path
import json
import sys

ROOT = Path(__file__).resolve().parents[2]
SKIP_DIRS = {".git", "test", "node_modules", "docs"}


def runtime_files(*suffixes, root=ROOT):
    """The files the plugin ships, not its tests or documentation."""
    out = []
    for path in sorted(root.rglob("*")):
        rel = path.relative_to(root)
        hidden = any(part.startswith(".") for part in rel.parts[:-1])
        if path.is_file() and path.suffix in suffixes and not hidden and not SKIP_DIRS.intersection(rel.parts):
            out.append(path)
    return out


def manifest(root=ROOT):
    return json.loads((root / "manifest.json").read_text())


def code_only(source, keep_strings=True):
    """Blank out comments, and string contents when keep_strings is False.

    Line numbers stay the same because newlines are kept. Regex literals are
    not parsed; keep quotes out of them.
    """
    out = []
    i, n = 0, len(source)
    while i < n:
        c = source[i]
        if source.startswith("//", i):
            end = source.find("\n", i)
            end = n if end == -1 else end
            out.append(" " * (end - i))
            i = end
        elif source.startswith("/*", i):
            end = source.find("*/", i + 2)
            end = n if end == -1 else end + 2
            out.append("".join(ch if ch == "\n" else " " for ch in source[i:end]))
            i = end
        elif c in "\"'`":
            j = i + 1
            while j < n and source[j] != c:
                j += 2 if source[j] == "\\" else 1
            literal = source[i:j + 1]
            out.append(literal if keep_strings else c + " " * max(0, len(literal) - 2) + c)
            i = j + 1
        else:
            out.append(c)
            i += 1
    return "".join(out)


def block_at(source, open_index):
    """The text from the brace at open_index to its matching close brace."""
    depth = 0
    bare = code_only(source, keep_strings=False)
    for j in range(open_index, len(bare)):
        if bare[j] == "{":
            depth += 1
        elif bare[j] == "}":
            depth -= 1
            if depth == 0:
                return source[open_index:j + 1]
    return source[open_index:]


def line_of(source, index):
    return source.count("\n", 0, index) + 1


class Report:
    """Collects failures and prints them as path:line: message."""

    def __init__(self, name):
        self.name = name
        self.failures = []

    def fail(self, path, line, message):
        rel = path.relative_to(ROOT) if isinstance(path, Path) and path.is_absolute() else path
        self.failures.append(f"{rel}:{line}: {message}" if line else f"{rel}: {message}")

    def finish(self):
        for failure in self.failures:
            print(failure)
        if self.failures:
            print(f"{self.name}: {len(self.failures)} problem(s)")
            sys.exit(1)
        print(f"{self.name}: ok")
