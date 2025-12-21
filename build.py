import subprocess
from pathlib import Path
import sys
import argparse
import shutil

# =============================
# 配置区域
# =============================
PROJECTS = [
    {
        "name": "test",
        "type": "exe",
        "sources": [
            "core/test.logcategory.zig"
        ],
    
        "module_paths": [
            "core" 
        ],
    }
]

OUT_DIR = Path("build")

TARGETS = {
    "gnu": "x86_64-windows-gnu",
    "msvc": "x86_64-windows-msvc",
}

# =============================
# 参数解析
# =============================
parser = argparse.ArgumentParser(description="Build multiple projects")
parser.add_argument("--target", default="gnu", choices=TARGETS.keys(), help="Build target")
parser.add_argument("--debug", action="store_true", help="Build Debug")
parser.add_argument("--run", action="store_true", help="Run exe after build")
parser.add_argument("exe_args", nargs=argparse.REMAINDER, help="Arguments to pass to exe")
args = parser.parse_args()

TARGET = TARGETS[args.target]
MODE = "Debug" if args.debug else "ReleaseFast"

# =============================
# 工具检查
# =============================
if shutil.which("zig") is None:
    print("Error: zig not found in PATH")
    sys.exit(1)

# =============================
# 创建输出目录
# =============================
OUT_DIR.mkdir(parents=True, exist_ok=True)

# =============================
# 构建函数
# =============================
def build_project(proj):
    name = proj["name"]
    typ = proj["type"]
    sources = proj["sources"]
    module_paths = proj.get("module_paths", [])

    out_file = OUT_DIR / (name + (".lib" if typ == "lib" else ".exe"))

    cmd = ["zig"]

    if typ == "lib":
        cmd.append("build-lib")
    elif typ == "exe":
        cmd.append("build-exe")
    else:
        raise ValueError(f"Unknown type: {typ}")

    # 入口文件
    cmd.extend([sources[0]])

    # 模块路径
    for path in module_paths:
        cmd.extend(["-I", path])

    cmd.extend([
        "-target", TARGET,
        "-O", MODE,
        f"-femit-bin={out_file}",
        "-lc",
        "-lShlwapi"
    ])

    if typ == "lib":
        cmd.extend(["-lc", "-luser32", "-lkernel32"])

    print(f"\n=== Building {name} ({typ}) ===")
    print("Running:", " ".join(map(str, cmd)))

    try:
        subprocess.run(cmd, check=True)
    except subprocess.CalledProcessError as e:
        print(f"Build failed for {name}!")
        sys.exit(e.returncode)

    print(f"Build finished: {out_file}")

    if typ == "exe" and args.run:
        exe_cmd = [out_file] + args.exe_args
        print(f"\n=== Running {out_file} ===")
        try:
            subprocess.run(exe_cmd, check=True)
        except subprocess.CalledProcessError as e:
            print(f"Execution failed for {out_file}!")
            sys.exit(e.returncode)

# =============================
# 构建所有项目
# =============================
for proj in PROJECTS:
    build_project(proj)

print("\nAll builds finished!")
input("Press Enter to exit...")