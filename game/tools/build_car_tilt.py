#!/usr/bin/env python3
"""The car's mid-air tilt (T-555; Drifting, Decisions, "The grind overhaul"), free script steps.

The tilt: the car's own front left wheel goes down and its back right wheel goes up, a tilt about the car's
diagonal (the line through its front right and back left wheels), not a turn: the car keeps facing the same way.
3 frames per direction, from a little to the held pose (TILT_STEPS_DEG).

  python game/tools/build_car_tilt.py guides [--dirs 0,8] [--out DIR]
      Pose guides: each frame of the shadowless car (game/art/car/car_iso_noshadow.png) warped in 3D by the
      tilt (every pixel given a height from a simple car-shaped volume, rotated about the diagonal and drawn
      again, nearest pixel, depth-sorted), in the car's own colours. Written to art-archive/T-555/guides/
      as dir<NN>_step<S>.png. They are what PixelLab's /rotate is given as init_image (the pose), with the
      real frame as from_image (the look).
  python game/tools/build_car_tilt.py clean IN.png OUT.png --dir N
      The free clean-up of a generated frame: alpha cut at 128, every colour mapped to the nearest of the car's
      own palette (CIELAB), stray specks removed, and the frame moved by whole pixels so its car sits where
      the guide's car sits (same centre as the normal frame, so the tilt doesn't jump).
  python game/tools/build_car_tilt.py sheet --frames-dir DIR [--out game/art/car/car_iso_tilt]
      Assembles car_iso_tilt.png (32 columns = the car's directions, 3 rows = steps 1 to 3) from
      DIR/dir<NN>_step<S>.png and writes its JSON (car_iso_noshadow.json's layout fields, "rows": 3).
  python game/tools/build_car_tilt.py preview SHEET.png OUT.png [--dirs ...]
      Contact sheet: each direction's normal frame and its 3 tilt frames in a row, enlarged, on dark and light.

Conventions (car_iso.json): frame i shows world heading i * 11.25 degrees, Godot axes (x right, y down, the
heading growing clockwise on screen); world +x is drawn down-right. The car's forward is (cos h, sin h) and its
left (sin h, -cos h).
"""

from __future__ import annotations

import argparse
import json
import math
import sys
from pathlib import Path

import numpy as np
from PIL import Image

REPO = Path(__file__).resolve().parents[2]
CAR_DIR = REPO / "game" / "art" / "car"
NOSHADOW = CAR_DIR / "car_iso_noshadow.png"
NOSHADOW_JSON = CAR_DIR / "car_iso_noshadow.json"
ARCHIVE = REPO / "art-archive" / "T-555"

FRAME = 128
DIRECTIONS = 32
STEP_DEG = 11.25
CENTER = (64.5, 65.5)            # car_iso.json center_px
TILT_STEPS_DEG = (10.0, 20.0, 30.0)   # steps 1, 2, 3 (3 = the held pose); a proposal for the playtest (round 1 used 7, 14, 20: too subtle)

# The camera: orthographic, the game's isometric azimuth, ELEV_DEG above the ground, K screen px per unit.
ELEV_DEG = 45.0
K = 40.0
# The car-shaped volume used to give each pixel a height (local units: u forward, v left, z up from the
# wheels' bottom). The body, then the fastback cabin set a little back.
BODY = (-1.45, 1.45, -0.6, 0.6, 0.0, 0.55)
CABIN = (-0.95, 0.35, -0.48, 0.48, 0.55, 0.9)
PIVOT_Z = 0.45                    # the tilt's axis runs through the car's centre, at this height
WHEEL_U, WHEEL_V = 1.0, 0.5       # wheel centres: the axis runs through front right (u, -v) and back left


def screen_basis(elev_deg: float = ELEV_DEG, k: float = K):
    """Screen vectors (px) of world +x, +y and +z."""
    se, ce = math.sin(math.radians(elev_deg)), math.cos(math.radians(elev_deg))
    r = k / math.sqrt(2.0)
    return np.array([r, r * se]), np.array([-r, r * se]), np.array([0.0, -k * ce])


def local_axes(heading_deg: float):
    h = math.radians(heading_deg)
    return np.array([math.cos(h), math.sin(h)]), np.array([math.sin(h), -math.cos(h)])


def tilt_axes():
    """Unit vectors in local (u, v): along the tilt axis (back left to front right) and the normal pointing to
    the front left wheel's side."""
    d = np.array([WHEEL_U, -WHEEL_V]); d /= np.linalg.norm(d)
    n = np.array([WHEEL_V, WHEEL_U]); n /= np.linalg.norm(n)
    return d, n


AWAY_EASE = 0.45   # how much less the car tilts when the tilt tips its top away from the viewer (see tilt_deg_for)


def tilt_deg_for(i: int, deg: float) -> float:
    """The tilt drawn for direction frame i (T-555 round 2): the full angle when lowering the front left side tips
    the car's top towards the viewer; up to AWAY_EASE less when it tips it away (the rear views), where the full
    angle turns the roof edge-on and the sprite collapses into a sliver it has no pixels for."""
    f, l = local_axes(i * STEP_DEG)
    _, n = tilt_axes()
    world_n = n[0] * f + n[1] * l                        # the front left side's direction on the ground
    towards_viewer = float(world_n @ np.array([1.0, 1.0]) / math.sqrt(2.0))
    return deg * (1.0 - AWAY_EASE * max(0.0, -towards_viewer))


def tilt_local(u, v, z, deg: float):
    """Rotates local points by the tilt: the front left side goes down, the top leans towards it."""
    d, n = tilt_axes()
    a = u * n[0] + v * n[1]             # towards the front left
    t = u * d[0] + v * d[1]             # along the axis
    b = z - PIVOT_Z
    c, s = math.cos(math.radians(deg)), math.sin(math.radians(deg))
    a2, b2 = a * c + b * s, -a * s + b * c
    return t * d[0] + a2 * n[0], t * d[1] + a2 * n[1], b2 + PIVOT_Z


def _inside(u, v, z):
    out = np.zeros(u.shape, bool)
    for (u0, u1, v0, v1, z0, z1) in (BODY, CABIN):
        out |= (u >= u0) & (u <= u1) & (v >= v0) & (v <= v1) & (z >= z0) & (z <= z1)
    return out


def volume_bbox(heading_deg: float):
    """The car-shaped volume's bounding box on screen (model px, relative to CENTER): (x0, y0, x1, y1)."""
    pts = []
    for (u0, u1, v0, v1, z0, z1) in (BODY, CABIN):
        for u in (u0, u1):
            for v in (v0, v1):
                for z in (z0, z1):
                    sx, sy, _ = project(np.array(u), np.array(v), np.array(z), heading_deg)
                    pts.append((float(sx) - CENTER[0], float(sy) - CENTER[1]))
    p = np.array(pts)
    return p[:, 0].min(), p[:, 1].min(), p[:, 0].max(), p[:, 1].max()


def frame_fit(alpha: np.ndarray, heading_deg: float):
    """Fits the volume to the frame's own silhouette (T-555 round 2): the scale (fx, fy) and the centres that
    put the volume's screen bounding box on the sprite's. Returns (sprite_centre, volume_centre, scale), with a
    sprite pixel p at model point volume_centre + (p - sprite_centre) / scale."""
    ys, xs = np.nonzero(alpha)
    sx0, sx1, sy0, sy1 = xs.min(), xs.max() + 1, ys.min(), ys.max() + 1
    x0, y0, x1, y1 = volume_bbox(heading_deg)
    scale = np.array([(sx1 - sx0) / (x1 - x0), (sy1 - sy0) / (y1 - y0)])
    return np.array([(sx0 + sx1) / 2.0, (sy0 + sy1) / 2.0]), np.array([(x0 + x1) / 2.0, (y0 + y1) / 2.0]), scale


def pixel_heights(alpha: np.ndarray, heading_deg: float, fit=None):
    """For each opaque pixel of a frame: its local (u, v, z) on the car-shaped volume, found by walking down its
    view ray from above and taking the first point inside the volume; a ray that misses it gets the point where
    it is closest to the volume's middle height. With `fit` (frame_fit), the volume is fitted to the frame's
    silhouette first. Returns arrays (ys, xs, u, v, z)."""
    ex, ey, ez = screen_basis()
    f, l = local_axes(heading_deg)
    ys, xs = np.nonzero(alpha)
    px = xs + 0.5 - CENTER[0]
    py = ys + 0.5 - CENTER[1]
    if fit is not None:
        cs, cp, sc = fit
        px = cp[0] + (xs + 0.5 - cs[0]) / sc[0]
        py = cp[1] + (ys + 0.5 - cs[1]) / sc[1]
    zs = np.linspace(1.4, -0.3, 86)
    m = np.array([[ex[0], ey[0]], [ex[1], ey[1]]])
    minv = np.linalg.inv(m)
    hit_z = np.full(px.shape, np.nan)
    hit_u = np.zeros(px.shape)
    hit_v = np.zeros(px.shape)
    for z in zs:
        # Screen = x*ex + y*ey + (z - PIVOT_Z)*ez, the car's centre at (0, 0, PIVOT_Z) on CENTER.
        rx = px - (z - PIVOT_Z) * ez[0]
        ry = py - (z - PIVOT_Z) * ez[1]
        wx = minv[0, 0] * rx + minv[0, 1] * ry
        wy = minv[1, 0] * rx + minv[1, 1] * ry
        u = wx * f[0] + wy * f[1]
        v = wx * l[0] + wy * l[1]
        new = np.isnan(hit_z) & _inside(u, v, np.full(u.shape, z))
        hit_z[new], hit_u[new], hit_v[new] = z, u[new], v[new]
    miss = np.isnan(hit_z)
    if miss.any():
        z = 0.3
        rx = px[miss] - (z - PIVOT_Z) * ez[0]
        ry = py[miss] - (z - PIVOT_Z) * ez[1]
        wx = minv[0, 0] * rx + minv[0, 1] * ry
        wy = minv[1, 0] * rx + minv[1, 1] * ry
        hit_u[miss] = wx * f[0] + wy * f[1]
        hit_v[miss] = wx * l[0] + wy * l[1]
        hit_z[miss] = z
    return ys, xs, hit_u, hit_v, hit_z


def project(u, v, z, heading_deg: float):
    ex, ey, ez = screen_basis()
    f, l = local_axes(heading_deg)
    wx = u * f[0] + v * l[0]
    wy = u * f[1] + v * l[1]
    sx = wx * ex[0] + wy * ey[0] + (z - PIVOT_Z) * ez[0] + CENTER[0]
    sy = wx * ex[1] + wy * ey[1] + (z - PIVOT_Z) * ez[1] + CENTER[1]
    se, ce = math.sin(math.radians(ELEV_DEG)), math.cos(math.radians(ELEV_DEG))
    depth = (wx + wy) / math.sqrt(2.0) * ce + z * se     # larger = nearer the viewer
    return sx, sy, depth


def _blur(a: np.ndarray, sigma: float) -> np.ndarray:
    """Separable Gaussian blur (edges clamped), numpy only."""
    r = max(1, int(3 * sigma))
    k = np.exp(-0.5 * (np.arange(-r, r + 1) / sigma) ** 2)
    k /= k.sum()
    p = np.pad(a, r, mode="edge")
    p = sum(k[i] * p[i:i + a.shape[0], :] for i in range(2 * r + 1))
    return sum(k[i] * p[:, i:i + a.shape[1]] for i in range(2 * r + 1))


HEIGHT_SMOOTH = 4.0   # px: the height map is smoothed so the warp bends the car instead of tearing it


def height_map(alpha: np.ndarray, heading_deg: float, fit=None) -> np.ndarray:
    """A smooth height (z, local units) for every pixel of the frame: the opaque pixels' heights on the
    car-shaped volume, spread to the rest of the frame and smoothed."""
    ys, xs, _, _, z = pixel_heights(alpha, heading_deg, fit)
    zmap = np.zeros(alpha.shape)
    mask = np.zeros(alpha.shape)
    zmap[ys, xs] = z
    mask[ys, xs] = 1.0
    num, den = _blur(zmap, 12.0), _blur(mask, 12.0)
    filled = np.where(mask > 0, zmap, num / np.maximum(den, 1e-6))
    return _blur(filled, HEIGHT_SMOOTH)


def displacement(alpha: np.ndarray, heading_deg: float, tilt_deg: float, fitted: bool = False,
                 with_depth: bool = False):
    """Screen displacement (dx, dy) of every pixel of the frame under the tilt, from the smooth height map.
    `fitted`: the volume is fitted to the frame's silhouette (frame_fit), and the displacement scaled back to the
    sprite's pixels. `with_depth` also returns each pixel's depth after the tilt (larger = nearer the viewer)."""
    ex, ey, ez = screen_basis()
    f, l = local_axes(heading_deg)
    fit = frame_fit(alpha, heading_deg) if fitted else None
    z = height_map(alpha, heading_deg, fit)
    yy, xx = np.mgrid[0:FRAME, 0:FRAME]
    px = xx + 0.5 - CENTER[0]
    py = yy + 0.5 - CENTER[1]
    sc = np.ones(2)
    if fit is not None:
        cs, cp, sc = fit
        px = cp[0] + (xx + 0.5 - cs[0]) / sc[0]
        py = cp[1] + (yy + 0.5 - cs[1]) / sc[1]
    minv = np.linalg.inv(np.array([[ex[0], ey[0]], [ex[1], ey[1]]]))
    rx = px - (z - PIVOT_Z) * ez[0]
    ry = py - (z - PIVOT_Z) * ez[1]
    wx = minv[0, 0] * rx + minv[0, 1] * ry
    wy = minv[1, 0] * rx + minv[1, 1] * ry
    u = wx * f[0] + wy * f[1]
    v = wx * l[0] + wy * l[1]
    u2, v2, z2 = tilt_local(u, v, z, tilt_deg)
    sx0, sy0, _ = project(u, v, z, heading_deg)
    sx1, sy1, depth = project(u2, v2, z2, heading_deg)
    dx, dy = (sx1 - sx0) * sc[0], (sy1 - sy0) * sc[1]
    return (dx, dy, depth) if with_depth else (dx, dy)


def _bilinear(field: np.ndarray, x: np.ndarray, y: np.ndarray) -> np.ndarray:
    x = np.clip(x - 0.5, 0, FRAME - 1.001)
    y = np.clip(y - 0.5, 0, FRAME - 1.001)
    x0, y0 = np.floor(x).astype(int), np.floor(y).astype(int)
    tx, ty = x - x0, y - y0
    return (field[y0, x0] * (1 - tx) * (1 - ty) + field[y0, x0 + 1] * tx * (1 - ty)
            + field[y0 + 1, x0] * (1 - tx) * ty + field[y0 + 1, x0 + 1] * tx * ty)


SUBSAMPLES = 3   # each source pixel is moved as 3 x 3 samples, so a stretched part leaves no holes


def splat_frame(frame: np.ndarray, heading_deg: float, tilt_deg: float) -> np.ndarray:
    """The frame tilted (T-555 round 2 guide): the volume fitted to the frame's silhouette, every source pixel
    moved forward as SUBSAMPLES x SUBSAMPLES samples along the smooth displacement field, the sample nearest the
    viewer kept per output pixel (so a raised part covers what is behind it instead of tearing), the few holes
    left filled from their neighbours, specks dropped. Only the frame's own pixels are used."""
    alpha = frame[:, :, 3] > 0
    if not alpha.any() or tilt_deg == 0:
        return frame.copy()
    dx, dy, depth = displacement(alpha, heading_deg, tilt_deg, fitted=True, with_depth=True)
    ys, xs = np.nonzero(alpha)
    k = SUBSAMPLES
    offs = (np.arange(k) + 0.5) / k
    oy, ox = np.meshgrid(offs, offs, indexing="ij")
    sx = (xs[:, None] + ox.ravel()[None, :]).ravel()
    sy = (ys[:, None] + oy.ravel()[None, :]).ravel()
    src = np.repeat(np.arange(len(xs)), k * k)
    tx = np.floor(sx + _bilinear(dx, sx, sy)).astype(int)
    ty = np.floor(sy + _bilinear(dy, sx, sy)).astype(int)
    dep = _bilinear(depth, sx, sy)
    ok = (tx >= 0) & (tx < FRAME) & (ty >= 0) & (ty < FRAME)
    tx, ty, dep, src = tx[ok], ty[ok], dep[ok], src[ok]
    order = np.argsort(dep, kind="stable")          # far first; the nearest is written last and stays
    out = np.zeros_like(frame)
    out[ty[order], tx[order]] = frame[ys[src[order]], xs[src[order]]]
    return remove_specks(fill_holes(out))


def warp_frame(frame: np.ndarray, heading_deg: float, tilt_deg: float) -> np.ndarray:
    """The frame tilted: a smooth warp (every output pixel takes the source pixel that moves onto it, found by
    fixed-point iteration on the displacement field), nearest pixel, so only the car's own pixels are used."""
    alpha = frame[:, :, 3] > 0
    dx, dy = displacement(alpha, heading_deg, tilt_deg)
    yy, xx = np.mgrid[0:FRAME, 0:FRAME].astype(float)
    sx, sy = xx.copy(), yy.copy()
    for _ in range(12):
        ix = np.clip(np.floor(sx + 0.5).astype(int), 0, FRAME - 1)
        iy = np.clip(np.floor(sy + 0.5).astype(int), 0, FRAME - 1)
        sx, sy = xx - dx[iy, ix], yy - dy[iy, ix]
    ix = np.floor(sx + 0.5).astype(int)
    iy = np.floor(sy + 0.5).astype(int)
    ok = (ix >= 0) & (ix < FRAME) & (iy >= 0) & (iy < FRAME)
    out = np.zeros_like(frame)
    out[ok] = frame[iy[ok], ix[ok]]
    return out


def fill_holes(img: np.ndarray, passes: int = 2) -> np.ndarray:
    """A transparent pixel with at least 5 of its 8 neighbours opaque takes their most common colour."""
    img = img.copy()
    for _ in range(passes):
        a = img[:, :, 3] > 0
        pad = np.pad(a, 1)
        count = sum(pad[1 + dy:FRAME + 1 + dy, 1 + dx:FRAME + 1 + dx]
                    for dy in (-1, 0, 1) for dx in (-1, 0, 1) if (dx, dy) != (0, 0))
        todo = np.argwhere((~a) & (count >= 5))
        if not len(todo):
            break
        src = img.copy()
        for y, x in todo:
            cols = {}
            for dy in (-1, 0, 1):
                for dx in (-1, 0, 1):
                    yy, xx = y + dy, x + dx
                    if (dx or dy) and 0 <= yy < FRAME and 0 <= xx < FRAME and src[yy, xx, 3] > 0:
                        key = tuple(src[yy, xx])
                        cols[key] = cols.get(key, 0) + 1
            img[y, x] = max(cols, key=cols.get)
    return img


# --- palette and clean-up ---

def _srgb_to_lab(rgb: np.ndarray) -> np.ndarray:
    c = rgb.astype(float) / 255.0
    c = np.where(c > 0.04045, ((c + 0.055) / 1.055) ** 2.4, c / 12.92)
    m = np.array([[0.4124, 0.3576, 0.1805], [0.2126, 0.7152, 0.0722], [0.0193, 0.1192, 0.9505]])
    xyz = c @ m.T / np.array([0.95047, 1.0, 1.08883])
    f = np.where(xyz > 0.008856, np.cbrt(xyz), 7.787 * xyz + 16 / 116)
    return np.stack([116 * f[..., 1] - 16, 500 * (f[..., 0] - f[..., 1]), 200 * (f[..., 1] - f[..., 2])], -1)


def car_palette() -> np.ndarray:
    data = json.loads((CAR_DIR / "car_iso.json").read_text(encoding="utf-8"))
    return np.array([[int(h[i:i + 2], 16) for i in (1, 3, 5)] for h in data["palette"]], np.uint8)


def map_to_palette(img: np.ndarray, palette: np.ndarray) -> np.ndarray:
    out = img.copy()
    a = out[:, :, 3] >= 128
    out[:, :, 3] = np.where(a, 255, 0)
    out[~a] = 0
    if a.any():
        lab = _srgb_to_lab(out[a][:, :3])
        plab = _srgb_to_lab(palette)
        idx = np.argmin(((lab[:, None, :] - plab[None, :, :]) ** 2).sum(-1), axis=1)
        rgb = out[a]
        rgb[:, :3] = palette[idx]
        out[a] = rgb
    return out


def remove_specks(img: np.ndarray, min_size: int = 6) -> np.ndarray:
    """Opaque islands smaller than min_size pixels (8-connected), apart from the car, are made transparent."""
    a = img[:, :, 3] > 0
    seen = np.zeros_like(a)
    out = img.copy()
    for y0, x0 in np.argwhere(a):
        if seen[y0, x0]:
            continue
        stack, comp = [(y0, x0)], []
        seen[y0, x0] = True
        while stack:
            y, x = stack.pop()
            comp.append((y, x))
            for dy in (-1, 0, 1):
                for dx in (-1, 0, 1):
                    yy, xx = y + dy, x + dx
                    if 0 <= yy < FRAME and 0 <= xx < FRAME and a[yy, xx] and not seen[yy, xx]:
                        seen[yy, xx] = True
                        stack.append((yy, xx))
        if len(comp) < min_size:
            for y, x in comp:
                out[y, x] = 0
    return out


def bbox_center(img: np.ndarray):
    ys, xs = np.nonzero(img[:, :, 3] > 0)
    return (xs.min() + xs.max() + 1) / 2.0, (ys.min() + ys.max() + 1) / 2.0


def shift(img: np.ndarray, dx: int, dy: int) -> np.ndarray:
    out = np.zeros_like(img)
    h, w = img.shape[:2]
    ys, xs = slice(max(0, dy), min(h, h + dy)), slice(max(0, dx), min(w, w + dx))
    ys0, xs0 = slice(max(0, -dy), min(h, h - dy)), slice(max(0, -dx), min(w, w - dx))
    out[ys, xs] = img[ys0, xs0]
    return out


SHEAR_RADIUS_PX = 17.0   # screen distance (px) of the lowered/raised corners from the tilt axis; a proposal


def shear_offsets(width: int, cx: float, half_w: float, corner_dy: int) -> np.ndarray:
    """Whole-pixel vertical offset per column: +corner_dy (down) at the left edge of the car, -corner_dy (up) at
    the right edge, 0 at the centre, linear between and clamped outside."""
    x = (np.arange(width) + 0.5 - cx) / max(half_w, 1.0)
    return np.rint(-np.clip(x, -1.0, 1.0) * corner_dy).astype(int)


def shear_frame(frame: np.ndarray, tilt_deg: float, radius: float = SHEAR_RADIUS_PX) -> np.ndarray:
    """The tilt as a column shear of the real frame (T-555 v4): every column moves up or down by whole pixels,
    so no pixel is resampled, the facing never changes, the palette and stripes stay exact. Left side (the
    lowered front left corner in direction 8) goes down, right side (raised back right) goes up."""
    corner_dy = int(round(radius * np.sin(np.radians(tilt_deg))))
    ys, xs = np.nonzero(frame[:, :, 3] > 0)
    if len(xs) == 0 or corner_dy == 0:
        return frame.copy()
    cx = (xs.min() + xs.max() + 1) / 2.0
    half_w = (xs.max() + 1 - xs.min()) / 2.0
    offs = shear_offsets(frame.shape[1], cx, half_w, corner_dy)
    out = np.zeros_like(frame)
    h = frame.shape[0]
    for x, dy in enumerate(offs):
        col = frame[:, x]
        if dy >= 0:
            out[dy:, x] = col[:h - dy]
        else:
            out[:h + dy, x] = col[-dy:]
    return out


def clean(img: np.ndarray, reference: np.ndarray, palette: np.ndarray | None = None) -> np.ndarray:
    """Alpha cut, the car's palette, no specks, and the car's bounding-box centre moved (whole pixels) onto the
    reference's (the guide for the same direction and step)."""
    palette = car_palette() if palette is None else palette
    out = remove_specks(map_to_palette(img, palette))
    cx, cy = bbox_center(out)
    rx, ry = bbox_center(reference)
    return shift(out, int(round(rx - cx)), int(round(ry - cy)))


# --- files ---

def load_rgba(path: Path) -> np.ndarray:
    return np.array(Image.open(path).convert("RGBA"))


def save_rgba(arr: np.ndarray, path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    Image.fromarray(arr.astype(np.uint8), "RGBA").save(path)


def normal_frame(i: int, sheet: np.ndarray | None = None) -> np.ndarray:
    sheet = load_rgba(NOSHADOW) if sheet is None else sheet
    return sheet[:, i * FRAME:(i + 1) * FRAME].copy()


def frame_name(i: int, step: int) -> str:
    return f"dir{i:02d}_step{step}.png"


def build_guides(dirs, out_dir: Path) -> list[Path]:
    sheet = load_rgba(NOSHADOW)
    made = []
    for i in dirs:
        frame = normal_frame(i, sheet)
        for s, deg in enumerate(TILT_STEPS_DEG, start=1):
            p = out_dir / frame_name(i, s)
            save_rgba(splat_frame(frame, i * STEP_DEG, tilt_deg_for(i, deg)), p)
            made.append(p)
    return made


PIXELLAB_DIRS = ("south-east", "south", "south-west", "west", "north-west", "north", "north-east", "east")


def pixellab_direction(i: int) -> str:
    """PixelLab's name for the nearest of its 8 directions to car frame i (frame 0 = south-east, 8 = south-west)."""
    return PIXELLAB_DIRS[int(math.floor(i / 4.0 + 0.5)) % 8]


def _b64_png(arr: np.ndarray) -> str:
    import base64
    import io
    buf = io.BytesIO()
    Image.fromarray(arr.astype(np.uint8), "RGBA").save(buf, format="PNG")
    return base64.b64encode(buf.getvalue()).decode("ascii")


def rotate_request(i: int, step: int, strength: int, seed: int, guides_dir: Path,
                   guidance: float = 4.0) -> dict:
    """The /rotate body (T-157's method): from_image and color_image = the car's own shadowless frame i (the
    look), init_image = the tilt guide for frame i and the step (the pose), no turn and no view change."""
    frame = normal_frame(i)
    guide = load_rgba(guides_dir / frame_name(i, step))
    d = pixellab_direction(i)
    return {
        "image_size": {"width": FRAME, "height": FRAME},
        "from_image": {"type": "base64", "base64": _b64_png(frame)},
        "init_image": {"type": "base64", "base64": _b64_png(guide)},
        "init_image_strength": int(strength),
        "color_image": {"type": "base64", "base64": _b64_png(frame)},
        "image_guidance_scale": float(guidance),
        "from_view": "high top-down", "to_view": "high top-down",
        "from_direction": d, "to_direction": d,
        "isometric": True,
        "seed": int(seed),
    }


CALLS_LOG = ARCHIVE / "pixellab-calls.md"


def generate_set(dirs, steps, strength: int, seed0: int, guides_dir: Path, raw_dir: Path, frames_dir: Path,
                 tag: str, max_calls: int, run=None) -> list[str]:
    """The paid part of the full set, in one command: for each direction and step, the /rotate request
    (rotate_request), one `pixellab_client.py generate` call (only inside a live style loop run, which its
    environment carries), then the free clean into frames_dir. A frame whose raw file already exists is not paid
    for again (only cleaned), so a stopped run carries on. Stops before going over max_calls. Every call is a
    line in art-archive/T-555/pixellab-calls.md. Returns the names called."""
    import subprocess
    run = run or (lambda cmd: subprocess.run(cmd, cwd=REPO).returncode)
    called = []
    for i in dirs:
        for s in steps:
            name = f"d{i:02d}_s{s}_st{strength}_{tag}"
            raw = raw_dir / f"{name}.png"
            if not raw.is_file():
                if len(called) >= max_calls:
                    print(f"stopped: {max_calls} calls reached before {name}")
                    return called
                req = ARCHIVE / "requests" / f"{name}.json"
                req.parent.mkdir(parents=True, exist_ok=True)
                seed = seed0 + i * 10 + s
                req.write_text(json.dumps(rotate_request(i, s, strength, seed, guides_dir)) + "\n", encoding="utf-8")
                with CALLS_LOG.open("a", encoding="utf-8") as fh:
                    fh.write(f"| {name} | dir {i} | step {s} | strength {strength} | {seed} | {tag} | full set |")
                code = run([sys.executable, "game/tools/pixellab_client.py", "generate", "--endpoint", "rotate",
                            "--params-file", str(req), "--out-dir", str(raw_dir), "--name", name,
                            "--consulted", "docs/visual-style.md", "--consulted", "docs/extended-narrative.md",
                            "--consulted", "docs/drifting.md", "--consulted", guides_dir.as_posix(),
                            "--task", "T-555"])
                called.append(name)
                with CALLS_LOG.open("a", encoding="utf-8") as fh:
                    fh.write(" saved |\n" if code == 0 else f" failed (exit {code}) |\n")
                if code != 0:
                    print(f"stopped: {name} failed (exit {code})")
                    return called
            guide = load_rgba(guides_dir / frame_name(i, s))
            save_rgba(clean(load_rgba(raw), guide), frames_dir / frame_name(i, s))
    return called


def strip(frames, out: Path) -> None:
    """A one-row sheet of 128 x 128 frames (the style loop's version of a sample direction)."""
    save_rgba(np.concatenate(list(frames), axis=1), out)


def assemble_sheet(frames_dir: Path, out_base: Path) -> dict:
    """car_iso_tilt.png and .json from frames_dir/dir<NN>_step<S>.png (all 96 must exist)."""
    sheet = np.zeros((3 * FRAME, DIRECTIONS * FRAME, 4), np.uint8)
    missing = [frame_name(i, s) for s in (1, 2, 3) for i in range(DIRECTIONS)
               if not (frames_dir / frame_name(i, s)).is_file()]
    if missing:
        raise SystemExit(f"missing frames in {frames_dir}: {', '.join(missing[:6])}{' ...' if len(missing) > 6 else ''}")
    colours = set()
    for s in (1, 2, 3):
        for i in range(DIRECTIONS):
            f = load_rgba(frames_dir / frame_name(i, s))
            if f.shape != (FRAME, FRAME, 4):
                raise SystemExit(f"{frame_name(i, s)} is {f.shape[1]}x{f.shape[0]}, not {FRAME}x{FRAME}")
            sheet[(s - 1) * FRAME:s * FRAME, i * FRAME:(i + 1) * FRAME] = f
            colours |= {tuple(c) for c in f[f[:, :, 3] > 0][:, :3]}
    save_rgba(sheet, out_base.with_suffix(".png"))
    base = json.loads(NOSHADOW_JSON.read_text(encoding="utf-8"))
    layout = {k: base[k] for k in ("car_size_note", "car_size_px", "car_size_units", "center_note", "center_px",
                                   "frame0_faces", "frame0_heading_deg", "frame_from_rotation", "frame_height",
                                   "frame_width", "order", "projection", "px_per_unit", "step_deg", "view")
              if k in base}
    layout.update({
        "file": out_base.with_suffix(".png").name,
        "columns": DIRECTIONS, "frame_count": DIRECTIONS, "rows": 3,
        "rows_note": "row 0 = tilt step 1, row 1 = step 2, row 2 = step 3 (the held pose); column = the car's "
                     "direction frame, as in car_iso.png (T-551's hook, car_sprite.gd tilt_frame_index)",
        "tilt": "the car's front left wheel down and its back right wheel up, about the diagonal through its front "
                "right and back left wheels; it keeps facing the same way (Drifting, Decisions, \"The grind overhaul\")",
        "tilt_steps_deg": list(TILT_STEPS_DEG),
        "drop_shadow": False,
        "palette": sorted("#%02x%02x%02x" % c for c in colours),
        "placeholder": False,
        "record": {"task": "T-555", "command": "python game/tools/build_car_tilt.py sheet --frames-dir "
                   + frames_dir.relative_to(REPO).as_posix() if frames_dir.is_relative_to(REPO) else str(frames_dir),
                   "frames_dir": frames_dir.relative_to(REPO).as_posix() if frames_dir.is_relative_to(REPO)
                   else str(frames_dir)},
    })
    out_base.with_suffix(".json").write_text(json.dumps(layout, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    return layout


def contact_sheet(tilt_sheet: np.ndarray, dirs, scale: int = 2) -> Image.Image:
    """Per direction: the normal (shadowless) frame and steps 1 to 3, on dark then light, enlarged."""
    normal = load_rgba(NOSHADOW)
    rows = []
    for i in dirs:
        tiles = [normal_frame(i, normal)] + [tilt_sheet[(s - 1) * FRAME:s * FRAME, i * FRAME:(i + 1) * FRAME]
                                             for s in (1, 2, 3)]
        rows.append(np.concatenate(tiles, axis=1))
    strip = Image.fromarray(np.concatenate(rows, axis=0), "RGBA")
    w, h = strip.size
    out = Image.new("RGBA", (w * 2 + 8, h), (128, 128, 128, 255))
    for k, bg in enumerate(((20, 20, 28, 255), (235, 235, 230, 255))):
        tile = Image.new("RGBA", (w, h), bg)
        tile.alpha_composite(strip)
        out.paste(tile, (k * (w + 8), 0))
    return out.resize((out.width * scale, out.height * scale), Image.NEAREST)


def _dirs(text: str | None):
    return list(range(DIRECTIONS)) if not text or text == "all" else [int(x) for x in text.split(",")]


def main(argv=None) -> int:
    ap = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    sub = ap.add_subparsers(dest="cmd", required=True)
    g = sub.add_parser("guides")
    g.add_argument("--dirs")
    g.add_argument("--out", default=str(ARCHIVE / "guides3"))
    c = sub.add_parser("clean")
    c.add_argument("inp")
    c.add_argument("out")
    c.add_argument("--dir", type=int, required=True)
    c.add_argument("--step", type=int, default=3)
    c.add_argument("--guides", default=str(ARCHIVE / "guides3"))
    s = sub.add_parser("sheet")
    s.add_argument("--frames-dir", required=True)
    s.add_argument("--out", default=str(CAR_DIR / "car_iso_tilt"))
    r = sub.add_parser("request")
    r.add_argument("--dir", type=int, required=True)
    r.add_argument("--step", type=int, default=3)
    r.add_argument("--strength", type=int, default=450)
    r.add_argument("--seed", type=int, required=True)
    r.add_argument("--guidance", type=float, default=4.0)
    r.add_argument("--guides", default=str(ARCHIVE / "guides3"))
    r.add_argument("--out", required=True)
    t = sub.add_parser("strip")
    t.add_argument("--dir", required=True, help="a direction frame, or all (a 96-frame row, direction by direction)")
    t.add_argument("--frames-dir", required=True)
    t.add_argument("--out", required=True)
    gs = sub.add_parser("generate-set")
    gs.add_argument("--dirs", required=True)
    gs.add_argument("--steps", default="1,2,3")
    gs.add_argument("--strength", type=int, required=True)
    gs.add_argument("--seed0", type=int, default=556000)
    gs.add_argument("--guides", default=str(ARCHIVE / "guides3"))
    gs.add_argument("--raw-dir", default=str(ARCHIVE / "raw"))
    gs.add_argument("--frames-dir", required=True)
    gs.add_argument("--tag", required=True)
    gs.add_argument("--max-calls", type=int, required=True)
    cp = sub.add_parser("copy-guides")
    cp.add_argument("--dirs", required=True)
    cp.add_argument("--steps", default="1")
    cp.add_argument("--guides", default=str(ARCHIVE / "guides3"))
    cp.add_argument("--frames-dir", required=True)
    h = sub.add_parser("shear")
    h.add_argument("--dir", type=int, required=True)
    h.add_argument("--out-dir", required=True)
    h.add_argument("--radius", type=float, default=SHEAR_RADIUS_PX)
    p = sub.add_parser("preview")
    p.add_argument("sheet")
    p.add_argument("out")
    p.add_argument("--dirs")
    p.add_argument("--scale", type=int, default=2)
    a = ap.parse_args(argv)
    if a.cmd == "guides":
        for path in build_guides(_dirs(a.dirs), Path(a.out)):
            print(path)
    elif a.cmd == "clean":
        ref_path = Path(a.guides) / frame_name(a.dir, a.step)
        reference = load_rgba(ref_path) if ref_path.is_file() else splat_frame(
            normal_frame(a.dir), a.dir * STEP_DEG, tilt_deg_for(a.dir, TILT_STEPS_DEG[a.step - 1]))
        save_rgba(clean(load_rgba(Path(a.inp)), reference), Path(a.out))
        print(a.out)
    elif a.cmd == "sheet":
        layout = assemble_sheet(Path(a.frames_dir).resolve(), Path(a.out))
        print(f"{layout['file']}: {layout['columns']} x {layout['rows']}, {len(layout['palette'])} colours")
    elif a.cmd == "request":
        body = rotate_request(a.dir, a.step, a.strength, a.seed, Path(a.guides), a.guidance)
        Path(a.out).parent.mkdir(parents=True, exist_ok=True)
        Path(a.out).write_text(json.dumps(body) + "\n", encoding="utf-8")
        print(a.out)
    elif a.cmd == "strip":
        fd = Path(a.frames_dir)
        strip([load_rgba(fd / frame_name(i, s)) for i in _dirs(a.dir) for s in (1, 2, 3)], Path(a.out))
        print(a.out)
    elif a.cmd == "generate-set":
        called = generate_set(_dirs(a.dirs), [int(x) for x in a.steps.split(",")], a.strength, a.seed0,
                              Path(a.guides), Path(a.raw_dir), Path(a.frames_dir), a.tag, a.max_calls)
        print(f"{len(called)} PixelLab calls: {', '.join(called) or 'none'}")
    elif a.cmd == "copy-guides":
        for i in _dirs(a.dirs):
            for s in [int(x) for x in a.steps.split(",")]:
                save_rgba(load_rgba(Path(a.guides) / frame_name(i, s)), Path(a.frames_dir) / frame_name(i, s))
        print(f"copied to {a.frames_dir}")
    elif a.cmd == "shear":
        src = normal_frame(a.dir)
        for s, deg in enumerate(TILT_STEPS_DEG, start=1):
            out = Path(a.out_dir) / frame_name(a.dir, s)
            save_rgba(shear_frame(src, deg, a.radius), out)
            print(out)
    elif a.cmd == "preview":
        img = contact_sheet(load_rgba(Path(a.sheet)), _dirs(a.dirs), a.scale)
        img.save(a.out)
        print(a.out)
    return 0


if __name__ == "__main__":
    sys.exit(main())
