"""生成「搞个机吧」应用图标。

设计：青蓝→青绿对角渐变底 + 白色描边手机轮廓 + 一圈顺时针循环箭头。
所有图形先在 4 倍画布上绘制再缩小，避免 PIL 圆弧锯齿。

用法：
    python tools/gen_icon.py
产物：
    app/assets/icon/app_icon.png                  1024 完整图（含底）
    app/assets/icon/app_icon_foreground.png       1024 透明前景（Android adaptive）
    app/windows/runner/resources/app_icon.ico     多尺寸 Windows 图标
    app/android/app/src/main/res/mipmap-*/...     Android 各密度
"""

from __future__ import annotations

import math
import os

import numpy as np
from PIL import Image, ImageDraw

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
APP = os.path.join(ROOT, "app")

SIZE = 1024
SS = 4  # supersampling
C1 = (0x2C, 0x6E, 0x8F)  # 深青蓝
C2 = (0x5E, 0xEA, 0xD4)  # 青绿
WHITE = (255, 255, 255, 255)


def gradient(size: int) -> Image.Image:
    """对角线性渐变，从左上 C1 到右下 C2。"""
    t = (np.arange(size)[None, :] + np.arange(size)[:, None]) / (2 * size - 2)
    c1 = np.array(C1, dtype=np.float64)
    c2 = np.array(C2, dtype=np.float64)
    rgb = c1[None, None, :] * (1 - t[..., None]) + c2[None, None, :] * t[..., None]
    alpha = np.full((size, size, 1), 255.0)
    return Image.fromarray(
        np.concatenate([rgb, alpha], axis=2).astype(np.uint8), "RGBA"
    )


def arrow_head(draw: ImageDraw.ImageDraw, cx, cy, r, angle_deg, span_deg, width, color):
    """在半径 r、角度 angle_deg 处画一个沿切线方向的实心箭头尖。"""
    a = math.radians(angle_deg)
    # 切线方向（顺时针）
    tx, ty = -math.sin(a), math.cos(a)
    px, py = cx + r * math.cos(a), cy + r * math.sin(a)
    half = width * 0.62
    # 尖端沿切线方向拉长，底边沿径向展开：三角比弧宽高出一截才像箭头，
    # 否则在 48px 上会缩成一个疙瘩。
    tip = (px + tx * half * 3.4, py + ty * half * 3.4)
    base_c = (px, py)
    left = (base_c[0] - math.cos(a) * half * 1.15, base_c[1] - math.sin(a) * half * 1.15)
    right = (base_c[0] + math.cos(a) * half * 1.15, base_c[1] + math.sin(a) * half * 1.15)
    draw.polygon([tip, left, right], fill=color)


def draw_mark(draw: ImageDraw.ImageDraw, scale: int) -> None:
    """在 scale 倍坐标系里画手机 + 循环箭头（图标主体，白色）。"""
    s = scale
    cx = cy = 512 * s
    stroke = int(40 * s)

    # 手机轮廓：圆角矩形描边
    pad = int(118 * s)
    draw.rounded_rectangle(
        [cx - pad, cy - int(246 * s), cx + pad, cy + int(246 * s)],
        radius=int(74 * s),
        outline=WHITE,
        width=stroke,
    )
    # 听筒
    draw.rounded_rectangle(
        [cx - int(52 * s), cy - int(190 * s), cx + int(52 * s), cy - int(164 * s)],
        radius=int(13 * s),
        fill=WHITE,
    )
    # 底部主页条
    draw.rounded_rectangle(
        [cx - int(60 * s), cy + int(186 * s), cx + int(60 * s), cy + int(208 * s)],
        radius=int(11 * s),
        fill=WHITE,
    )

    # 循环箭头：两段弧 + 两个箭头尖
    r = int(372 * s)
    aw = int(34 * s)
    box = [cx - r, cy - r, cx + r, cy + r]
    # PIL 的 angle 从 3 点方向开始、顺时针递增
    draw.arc(box, start=190, end=318, fill=WHITE, width=aw)
    draw.arc(box, start=10, end=138, fill=WHITE, width=aw)
    arrow_head(draw, cx, cy, r, 138, 0, aw, WHITE)
    arrow_head(draw, cx, cy, r, 318, 0, aw, WHITE)


def build_icon(with_background: bool, shrink: float = 1.0) -> Image.Image:
    big = SIZE * SS
    layer = Image.new("RGBA", (big, big), (0, 0, 0, 0))
    draw = ImageDraw.Draw(layer)
    if shrink != 1.0:
        # 缩小主体：先画满，再整体缩放后居中贴回
        inner = Image.new("RGBA", (big, big), (0, 0, 0, 0))
        draw_mark(ImageDraw.Draw(inner), SS)
        scaled = inner.resize((int(big * shrink), int(big * shrink)), Image.LANCZOS)
        off = (big - scaled.width) // 2
        layer.alpha_composite(scaled, (off, off))
    else:
        draw_mark(draw, SS)
    layer = layer.resize((SIZE, SIZE), Image.LANCZOS)

    if not with_background:
        return layer

    base = gradient(SIZE)
    base.alpha_composite(layer)
    return base


def save_png(img: Image.Image, path: str, size: int | None = None) -> None:
    os.makedirs(os.path.dirname(path), exist_ok=True)
    out = img if size is None else img.resize((size, size), Image.LANCZOS)
    out.save(path, "PNG")
    print(f"  {os.path.relpath(path, ROOT)}  {out.width}x{out.height}")


def save_ico(img: Image.Image, path: str) -> None:
    os.makedirs(os.path.dirname(path), exist_ok=True)
    sizes = [(16, 16), (24, 24), (32, 32), (48, 48), (64, 64), (128, 128), (256, 256)]
    img.save(path, format="ICO", sizes=sizes)
    print(f"  {os.path.relpath(path, ROOT)}  {len(sizes)} sizes")


def save_round(img: Image.Image, path: str, size: int) -> None:
    """圆形裁切版（Android roundIcon）。"""
    big = img.resize((size * SS, size * SS), Image.LANCZOS)
    mask = Image.new("L", (size * SS, size * SS), 0)
    ImageDraw.Draw(mask).ellipse([0, 0, size * SS - 1, size * SS - 1], fill=255)
    out = Image.new("RGBA", (size * SS, size * SS), (0, 0, 0, 0))
    out.paste(big, (0, 0), mask)
    save_png(out.resize((size, size), Image.LANCZOS), path)


def main() -> None:
    print("生成图标：")
    full = build_icon(with_background=True)
    save_png(full, os.path.join(APP, "assets", "icon", "app_icon.png"))

    # adaptive 前景：主体缩到 66%，给系统裁切留余量
    fg = build_icon(with_background=False, shrink=0.66)
    save_png(fg, os.path.join(APP, "assets", "icon", "app_icon_foreground.png"))

    save_ico(full, os.path.join(APP, "windows", "runner", "resources", "app_icon.ico"))

    res = os.path.join(APP, "android", "app", "src", "main", "res")
    for folder, px in [
        ("mipmap-mdpi", 48),
        ("mipmap-hdpi", 72),
        ("mipmap-xhdpi", 96),
        ("mipmap-xxhdpi", 144),
        ("mipmap-xxxhdpi", 192),
    ]:
        save_png(full, os.path.join(res, folder, "ic_launcher.png"), px)
        save_round(full, os.path.join(res, folder, "ic_launcher_round.png"), px)


if __name__ == "__main__":
    main()
