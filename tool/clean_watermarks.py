#!/usr/bin/env python3
"""
清理 readings.json 中的版权水印标记。
用法: python3 tool/clean_watermarks.py
预计运行时间: 5-10秒
"""

import json
import re
import sys
import time

INPUT_FILE = "assets/data/readings.json"

# 所有需要清除的版权水印（按长度降序排列，先替换长字符串）
WATERMARKS = [
    "http://www.ks5u.com/",
    "http://wx.jtyjy.com/.Com",
    "http://wx.jtyjy.com/",
    "www.ks5u.com",
    "www.zxxk.com",
    "www.szzx100.com",
    "ks5u",
    "zxxk",
    "szzx100",
]

# 清理后可能残留的碎片
RESIDUAL = [
    "[: ]",
    "[:  ]",
    "[:",
]


def clean_string(s: str) -> str:
    """清除单个字符串中的所有水印标记"""
    for wm in WATERMARKS:
        s = s.replace(wm, "")
    for r in RESIDUAL:
        s = s.replace(r, "")
    return s.strip()


def clean_obj(obj):
    """递归清理 JSON 对象中的所有字符串"""
    if isinstance(obj, str):
        return clean_string(obj)
    elif isinstance(obj, list):
        return [clean_obj(item) for item in obj]
    elif isinstance(obj, dict):
        return {k: clean_obj(v) for k, v in obj.items()}
    else:
        return obj


def main():
    t0 = time.time()

    print(f"[1/5] 读取文件: {INPUT_FILE}")
    with open(INPUT_FILE, "r", encoding="utf-8") as f:
        data = json.load(f)
    print(f"      共 {len(data)} 篇文章")

    print("[2/5] 扫描水印出现次数...")
    raw = json.dumps(data, ensure_ascii=False)
    for wm in WATERMARKS:
        count = raw.count(wm)
        if count > 0:
            print(f"      {wm}: {count} 处")
    print(f"      扫描完成，耗时 {time.time()-t0:.1f}s")

    print("[3/5] 开始清理水印...")
    t1 = time.time()
    cleaned = clean_obj(data)
    print(f"      清理完成，耗时 {time.time()-t1:.1f}s")

    print("[4/5] 验证清理结果...")
    raw_cleaned = json.dumps(cleaned, ensure_ascii=False)
    all_clean = True
    for wm in WATERMARKS:
        count = raw_cleaned.count(wm)
        status = "OK" if count == 0 else f"还有 {count} 处!"
        print(f"      {wm}: {status}")
        if count > 0:
            all_clean = False

    if not all_clean:
        print("ERROR: 仍有水印残留，请检查!")
        sys.exit(1)

    print("[5/5] 写回文件...")
    t2 = time.time()
    with open(INPUT_FILE, "w", encoding="utf-8") as f:
        json.dump(cleaned, f, ensure_ascii=False)
    print(f"      写入完成，耗时 {time.time()-t2:.1f}s")

    total = time.time() - t0
    print(f"\n全部完成! 总耗时 {total:.1f}s")
    print("Android 和 iOS 重新打包即可生效。")


if __name__ == "__main__":
    main()
