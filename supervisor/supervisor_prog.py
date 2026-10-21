#!/usr/bin/env python3
import argparse
import os
import sys
import glob
from configparser import ConfigParser
from pathlib import Path

# 固定配置目录
CONF_DIR = "/home/auser/supervisord.d"

def log(message, level="INFO"):
    print(f"[{level}] {message}")

def get_ini_files():
    """获取目录下所有 .ini 文件"""
    pattern = os.path.join(CONF_DIR, "*.ini")
    return [Path(f) for f in glob.glob(pattern)]

def parse_program_name(section: str) -> str:
    """智能解析 section 名称"""
    if not section.startswith("program:"):
        return ""
    return section.split(":", 1)[1].strip()

def build_index():
    """构建内存索引：{ program_name: info }"""
    index = {}
    for filepath in get_ini_files():
        cfg = ConfigParser()
        cfg.optionxform = str  # 保持大小写
        try:
            cfg.read(filepath)
        except Exception:
            continue
            
        for section in cfg.sections():
            prog_name = parse_program_name(section)
            if prog_name:
                index[prog_name] = {
                    'file': filepath,
                    'section': section,
                    'cfg': cfg
                }
    return index

def save_cfg_if_changed(filepath, cfg):
    """保存配置，若为空则删除文件"""
    with open(filepath, "w") as fd:
        cfg.write(fd)
    if not cfg.sections():
        os.remove(filepath)
        log(f"Removed empty file: {filepath.name}", "CLEANUP")

def fmt_ini_file(filepath):
    """格式化单个 ini 文件"""
    cfg = ConfigParser()
    cfg.optionxform = str
    cfg.read(filepath)
    
    if not cfg.sections():
        return False

    lines = []
    sections = cfg.sections()
    
    for i, section in enumerate(sections):
        if i > 0:
            lines.append("")  # Section 之间空一行
        lines.append(f"[{section}]")
        
        for option in cfg.options(section):
            value = cfg.get(section, option)
            lines.append(f"{option} = {value}")
            
    content = "\n".join(lines) + "\n"
    
    with open(filepath, 'r') as f:
        if f.read() != content:
            with open(filepath, 'w') as f:
                f.write(content)
            return True
    return False

def cmd_remove(args):
    index = build_index()
    target = args.name
    if target not in index:
        log(f"Program '{target}' not found.", "ERROR")
        sys.exit(1)
    
    info = index[target]
    info['cfg'].remove_section(info['section'])
    save_cfg_if_changed(info['file'], info['cfg'])
    log(f"Removed '{target}'.")

def cmd_rename(args):
    index = build_index()
    old_name, new_name = args.old, args.new
    
    if old_name not in index:
        log(f"Program '{old_name}' not found.", "ERROR")
        sys.exit(1)
    if new_name in index:
        log(f"Program '{new_name}' already exists.", "ERROR")
        sys.exit(1)
        
    info = index[old_name]
    cfg = info['cfg']
    old_section = info['section']
    new_section = f"program:{new_name}"
    
    cfg.add_section(new_section)
    for option in cfg.options(old_section):
        cfg.set(new_section, option, cfg.get(old_section, option))
    cfg.remove_section(old_section)
    
    save_cfg_if_changed(info['file'], cfg)
    log(f"Renamed '{old_name}' to '{new_name}'.")

def cmd_set(args):
    index = build_index()
    target = args.name
    if target not in index:
        log(f"Program '{target}' not found.", "ERROR")
        sys.exit(1)
        
    info = index[target]
    info['cfg'].set(info['section'], args.key, args.value)
    save_cfg_if_changed(info['file'], info['cfg'])
    log(f"Set [{target}] {args.key} = {args.value}")

def cmd_list(args):
    index = build_index()
    if not index:
        log("No programs found.")
        return
    print(f"{'Name':<25} | File")
    print("-" * 40)
    for name, info in sorted(index.items()):
        print(f"{name:<25} | {info['file'].name}")

def cmd_cleanup(args):
    cleaned = 0
    for filepath in get_ini_files():
        cfg = ConfigParser()
        cfg.read(filepath)
        if not cfg.sections():
            os.remove(filepath)
            log(f"Removed empty: {filepath.name}")
            cleaned += 1
    log(f"Cleaned {cleaned} files." if cleaned else "Nothing to clean.")

def cmd_fmt(args):
    files = get_ini_files()
    count = 0
    for f in files:
        if fmt_ini_file(f):
            log(f"Formatted: {f.name}")
            count += 1
    log(f"Finished. {count} files updated." if count else "All files are clean.")

def main():
    parser = argparse.ArgumentParser(description="Supervisor Config Manager")
    subparsers = parser.add_subparsers(dest="action", required=True)

    p_rm = subparsers.add_parser("remove", help="Remove a program")
    p_rm.add_argument("name")
    
    p_rn = subparsers.add_parser("rename", help="Rename a program")
    p_rn.add_argument("old")
    p_rn.add_argument("new")
    
    p_set = subparsers.add_parser("set", help="Set an option")
    p_set.add_argument("name")
    p_set.add_argument("key")
    p_set.add_argument("value")
    
    p_ls = subparsers.add_parser("list", help="List all programs")
    p_cl = subparsers.add_parser("cleanup", help="Remove empty ini files")
    p_fmt = subparsers.add_parser("fmt", help="Format all ini files")

    args = parser.parse_args()

    if args.action == "remove": cmd_remove(args)
    elif args.action == "rename": cmd_rename(args)
    elif args.action == "set": cmd_set(args)
    elif args.action == "list": cmd_list(args)
    elif args.action == "cleanup": cmd_cleanup(args)
    elif args.action == "fmt": cmd_fmt(args)

if __name__ == "__main__":
    main()
