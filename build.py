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
            "core/test.strlen.zig"
        ],
        "asm_sources": [
            "core/Backend/String/strlen_simd_allwidths_x86_x64.asm"
        ],
        "cpp_sources": [
            "core/Backend/String/strlen_scalar.cpp"
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

def compile_asm(asm_path: Path) -> Path:
    obj_path = OUT_DIR / (asm_path.stem + ".obj")

    cmd = [
        "nasm",
        "-f", "win64",
        "-D__OS__=WINDOWS",
        asm_path,
        "-o", obj_path
    ]

    print("Assembling:", " ".join(map(str, cmd)))
    subprocess.run(cmd, check=True)

    return obj_path

def compile_cpp_or_c(src_path: Path, cpp: bool = True) -> Path:
    obj_path = OUT_DIR / (src_path.stem + ".o")

    compiler = "g++" if cpp else "gcc"

    cmd = [
        compiler,
        "-c",
        "-O2",             # Release 优化，可根据 MODE 改
        str(src_path),
        "-o",
        str(obj_path)
    ]

    print("Compiling:", " ".join(cmd))
    subprocess.run(cmd, check=True)
    return obj_path

def build_project(proj):
    name = proj["name"]
    typ = proj["type"]
    sources = proj.get("sources", [])
    asm_sources = proj.get("asm_sources", [])
    c_sources = proj.get("c_sources", [])
    cpp_sources = proj.get("cpp_sources", [])
    module_paths = proj.get("module_paths", [])

    out_file = OUT_DIR / (name + (".lib" if typ == "lib" else ".exe"))

    # ========= 编译 asm =========
    obj_files = []
    for asm in asm_sources:
        obj = compile_asm(Path(asm))
        obj_files.append(obj)

    # ========= 编译 C/C++ =========
    for csrc in c_sources:
        obj = compile_cpp_or_c(Path(csrc), cpp=False)
        obj_files.append(obj)
    for cppsrc in cpp_sources:
        obj = compile_cpp_or_c(Path(cppsrc), cpp=True)
        obj_files.append(obj)

    # ========= zig 入口 =========
    cmd = ["zig"]
    if typ == "lib":
        cmd.append("build-lib")
    elif typ == "exe":
        cmd.append("build-exe")
    else:
        raise ValueError(f"Unknown type: {typ}")

    # 默认入口源文件
    if sources:
        cmd.append(sources[0])

    # ========= 链接 obj 文件 =========
    for obj in obj_files:
        cmd.append(str(obj))

    # ========= 模块路径 =========
    for path in module_paths:
        cmd.extend(["-I", path])

    cmd.extend([
        "-target", TARGET,
        "-O", MODE,
        f"-femit-bin={out_file}",
        "-lc",
        "-I", "."
    ])

    if typ == "exe":
        cmd.append("-lShlwapi")
    if typ == "lib":
        cmd.extend(["-luser32", "-lkernel32"])

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
        subprocess.run(exe_cmd, check=True)

# =============================
# 构建所有项目
# =============================
for proj in PROJECTS:
    build_project(proj)

print("\nAll builds finished!")
input("Press Enter to exit...")