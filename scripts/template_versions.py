"""Theme versions for templates.

Each templates/<name>/main.typ starts with marker comments and a placeholder import:

    // template: theme-academic 0.2.1+
    // template: just new 會把 <version> 換成選定的版本，並自動刪除這兩行
    #import "@local/theme-academic:<version>": *

The first marker names the package and the oldest version the template works with; any newer
version of the same major.minor series qualifies (0.2.1+ means 0.2.1, 0.2.2, ...). The newest
qualifying folder under packages/local/<package>/ is the default, so releasing a new version only
needs the new folder; templates and docs keep the placeholder.

Usage:
    template_versions.py list                                # every template: series, default, choices
    template_versions.py render <template> <out> [version]   # write main.typ with the version filled in,
                                                             # print "<package>:<version>"
"""

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
MARKER = re.compile(r"^// template: (\S+) (\d+)\.(\d+)\.(\d+)\+\s*$", re.M)
PLACEHOLDER = "<version>"


def fail(msg):
    sys.stderr.write(f"✗ {msg}\n")
    sys.exit(1)


def spec(template):
    main = ROOT / "templates" / template / "main.typ"
    if not main.exists():
        names = " ".join(sorted(p.name for p in (ROOT / "templates").iterdir() if p.is_dir()))
        fail(f"找不到模板 templates/{template}（可用：{names}）")
    text = main.read_text()
    m = MARKER.search(text)
    if not m:
        fail(f"templates/{template}/main.typ 缺少 `// template: <package> <x.y.z>+` 標記")
    return text, m.group(1), tuple(int(x) for x in m.group(2, 3, 4))


def versions(package, minimum):
    def key(v):
        return tuple(int(x) for x in v.split("."))

    found = [
        p.name for p in (ROOT / "packages/local" / package).iterdir()
        if p.is_dir() and re.fullmatch(r"\d+\.\d+\.\d+", p.name)
        and key(p.name)[:2] == minimum[:2] and key(p.name) >= minimum
    ]
    if not found:
        fail(f"packages/local/{package}/ 沒有 {fmt(minimum)} 以上的 {minimum[0]}.{minimum[1]}.x 版本")
    return sorted(found, key=key)


def fmt(v):
    return ".".join(map(str, v))


def kit_of(package, version):
    lib = (ROOT / "packages/local" / package / version / "lib.typ").read_text()
    m = re.search(r'"@local/(slide-kit:[\d.]+)"', lib)
    return m.group(1) if m else "（不依賴 slide-kit）"


def choose(template, package, choices, requested):
    latest = choices[-1]
    if requested:
        if requested not in choices:
            fail(f"{template} 模板不支援 {package} {requested}（可用：{' '.join(choices)}）")
        return requested
    if not sys.stdin.isatty():
        return latest
    sys.stderr.write(f"{template} 模板可用的 {package} 版本：{' '.join(choices)}\n")
    while True:
        sys.stderr.write(f"選擇版本 [{latest}]: ")
        sys.stderr.flush()
        answer = sys.stdin.readline().strip() or latest
        if answer in choices:
            return answer
        sys.stderr.write(f"沒有 {answer}，請從上面的版本中選擇\n")


def cmd_list():
    for main in sorted((ROOT / "templates").glob("*/main.typ")):
        template = main.parent.name
        _, package, minimum = spec(template)
        choices = versions(package, minimum)
        latest = choices[-1]
        print(f"{template:<8} {package} {fmt(minimum)}+  預設 {latest} -> {kit_of(package, latest)}  可選：{' '.join(choices)}")


def cmd_render(template, out, requested):
    text, package, minimum = spec(template)
    version = choose(template, package, versions(package, minimum), requested)
    lines = [l for l in text.splitlines(keepends=True) if not l.startswith("// template:")]
    Path(out).write_text("".join(lines).replace(PLACEHOLDER, version))
    print(f"{package}:{version}")


if __name__ == "__main__":
    args = sys.argv[1:]
    if args[:1] == ["list"]:
        cmd_list()
    elif args[:1] == ["render"] and len(args) in (3, 4):
        cmd_render(args[1], args[2], args[3] if len(args) == 4 else "")
    else:
        fail("usage: template_versions.py list | render <template> <out> [version]")
