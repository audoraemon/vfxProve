"""Blockout kit: a tiny z-buffered renderer for massing models at KAK's exact 2:1 isometric angle and 4x scale.

Same projection as make_blockouts.py: one ground unit along x goes (+128, +64) px on screen, along y (-128, +64), one
height unit (1 game px) is 4 px. x runs to the lower right, y to the lower left, so the visible walls face +y (left,
light) and +x (right, dark). Every solid is convex; back faces are culled and a per-pixel depth test sorts everything
else, so parts may overlap freely (a chimney box simply rises through a roof). Outlines come from an id buffer: a
2 px near-black line wherever two faces (or a face and the background) meet. Faces of round things share one id, so a
cylinder shows no facet lines, only its silhouette."""
import math

import numpy as np
from PIL import Image, ImageDraw, ImageFont

S = 4
CX, CY = 32 * S, 16 * S
H = S
G = 32.0                      # height units per ground unit; (1, 1, G) points at the viewer
VIEW = np.array([1.0, 1.0, G])
OUT = (40, 30, 26)

# material: (left/light, right/dark, top)
MATS = {
    "wall": ((196, 190, 178), (128, 122, 112), (206, 200, 188)),
    "stone": ((180, 178, 170), (114, 113, 108), (194, 192, 184)),
    "wood": ((156, 122, 88), (102, 79, 57), (168, 134, 98)),
    "red": ((150, 92, 74), (104, 62, 52), (136, 82, 66)),
    "slate": ((118, 126, 140), (78, 84, 97), (106, 113, 127)),
    "thatch": ((182, 156, 102), (126, 106, 66), (168, 142, 90)),
    "green": ((126, 154, 98), (76, 102, 64), (140, 168, 110)),
    "earth": ((162, 142, 112), (108, 94, 74), (172, 152, 120)),
    "cloth": ((216, 208, 190), (150, 144, 130), (224, 218, 202)),
    "iron": ((96, 96, 100), (64, 64, 68), (108, 108, 112)),
    "water": ((116, 160, 200), (116, 160, 200), (116, 160, 200)),
    "paving": ((178, 174, 164), (178, 174, 164), (178, 174, 164)),
    "dark": ((58, 48, 44), (58, 48, 44), (58, 48, 44)),
}


def newell(pts):
    n = np.zeros(3)
    k = len(pts)
    for i in range(k):
        a, b = pts[i], pts[(i + 1) % k]
        n[0] += (a[1] - b[1]) * (a[2] + b[2])
        n[1] += (a[2] - b[2]) * (a[0] + b[0])
        n[2] += (a[0] - b[0]) * (a[1] + b[1])
    return n


def shade(mat, n):
    light, dark, top = MATS[mat]
    m = np.array([n[0] / G, n[1] / G, n[2]])
    m = m / (np.linalg.norm(m) + 1e-12)
    if m[2] > 0.93:
        return top
    hx, hy = m[0], m[1]
    t = (hy - hx) / (abs(hx) + abs(hy) + 1e-12)
    f = (t + 1) / 2
    return tuple(int(round(dark[i] + (light[i] - dark[i]) * f)) for i in range(3))


class Canvas:
    def __init__(self, w=2000, h=1700):
        self.w, self.h = w, h
        self.ox, self.oy = w / 2, h * 0.62
        self.col = np.zeros((h, w, 3), np.uint8)
        self.zb = np.full((h, w), -np.inf)
        self.ids = np.zeros((h, w), np.int32)
        self.next_id = 1
        self.tf = None                       # optional point transform (e.g. a lean)

    # ---- core -------------------------------------------------------------------------------------------------
    def _new_id(self):
        self.next_id += 1
        return self.next_id

    def _xf(self, p):
        p = tuple(float(v) for v in p)
        return self.tf(p) if self.tf else p

    def _scr(self, p):
        x, y, z = p
        return (self.ox + (x - y) * CX, self.oy + (x + y) * CY - z * H)

    def _raster(self, pts, color, gid, bias=0.0):
        n = newell(pts)
        nv = float(n @ VIEW)
        if nv <= 1e-6 * (np.linalg.norm(n) + 1e-12):
            return
        sp = [self._scr(p) for p in pts]
        xs, ys = [q[0] for q in sp], [q[1] for q in sp]
        bx0, by0 = max(int(math.floor(min(xs))) - 1, 0), max(int(math.floor(min(ys))) - 1, 0)
        bx1, by1 = min(int(math.ceil(max(xs))) + 2, self.w), min(int(math.ceil(max(ys))) + 2, self.h)
        if bx1 <= bx0 or by1 <= by0:
            return
        m = Image.new("L", (bx1 - bx0, by1 - by0), 0)
        ImageDraw.Draw(m).polygon([(q[0] - bx0, q[1] - by0) for q in sp], fill=1)
        mask = np.array(m, bool)
        if not mask.any():
            return
        X, Y = np.meshgrid(np.arange(bx0, bx1, dtype=float), np.arange(by0, by1, dtype=float))
        u, v = (X - self.ox) / CX, (Y - self.oy) / CY          # u = x - y, v = x + y on the ground plane
        bx, by = (u + v) / 2, (v - u) / 2
        c = float(n @ np.array(pts[0]))
        t = (c - n[0] * bx - n[1] * by) / nv
        depth = v + 3.0 * t + bias
        zb = self.zb[by0:by1, bx0:bx1]
        upd = mask & (depth > zb + 1e-9)
        zb[upd] = depth[upd]
        self.col[by0:by1, bx0:bx1][upd] = color
        self.ids[by0:by1, bx0:bx1][upd] = gid

    def solid(self, faces, gid=None):
        """faces: list of (points, material, smooth). Convex solid: normals are turned away from the centroid.
        Smooth faces share one id (no lines between them); the others get an id each."""
        faces = [([self._xf(p) for p in pts], mat, sm) for pts, mat, sm in faces]
        allp = np.array([p for f in faces for p in f[0]])
        cen = allp.mean(axis=0)
        sid = gid or self._new_id()
        for pts, mat, sm in faces:
            n = newell(pts)
            if np.linalg.norm(n) < 1e-12:
                continue
            fc = np.mean(np.array(pts), axis=0)
            if n @ (fc - cen) < 0:
                pts = pts[::-1]
                n = -n
            self._raster(pts, shade(mat, n), sid if sm else self._new_id())

    def flat_face(self, pts, mat, bias=0.002):
        """A one-sided polygon (opening, water, paving) turned to face the viewer, drawn just in front of its plane."""
        pts = [self._xf(p) for p in pts]
        n = newell(pts)
        if n @ VIEW < 0:
            pts, n = pts[::-1], -n
        self._raster(pts, shade(mat, n), self._new_id(), bias)

    def image(self):
        ids = self.ids
        edge = np.zeros_like(ids, bool)
        for dy, dx in ((0, 1), (0, -1), (1, 0), (-1, 0)):
            sh = np.zeros_like(ids)
            ys = slice(max(dy, 0), ids.shape[0] + min(dy, 0))
            yd = slice(max(-dy, 0), ids.shape[0] + min(-dy, 0))
            xs = slice(max(dx, 0), ids.shape[1] + min(dx, 0))
            xd = slice(max(-dx, 0), ids.shape[1] + min(-dx, 0))
            sh[yd, xd] = ids[ys, xs]
            edge |= (sh != ids) & ((sh > 0) | (ids > 0))
        rgb = self.col.copy()
        rgb[edge] = OUT
        a = ((ids > 0) | edge).astype(np.uint8) * 255
        im = Image.fromarray(np.dstack([rgb, a]), "RGBA")
        return im.crop(im.getbbox())

    # ---- primitives -------------------------------------------------------------------------------------------
    def prism(self, base, z0, ztop, side="wall", top=None, smooth=False):
        """Vertical prism on a convex base polygon [(x, y)...]; ztop is a number or a function (x, y) -> z."""
        top = top or side
        zt = ztop if callable(ztop) else (lambda x, y, h=ztop: h)
        k = len(base)
        faces = []
        for i in range(k):
            (ax, ay), (bx, by) = base[i], base[(i + 1) % k]
            faces.append(([(ax, ay, z0), (bx, by, z0), (bx, by, zt(bx, by)), (ax, ay, zt(ax, ay))], side, smooth))
        faces.append(([(x, y, zt(x, y)) for x, y in base], top, False))
        faces.append(([(x, y, z0) for x, y in base][::-1], side, False))
        self.solid(faces)

    def box(self, x0, y0, w, d, z0, h, mat="wall", top=None):
        self.prism([(x0, y0), (x0 + w, y0), (x0 + w, y0 + d), (x0, y0 + d)], z0, z0 + h, mat, top)

    def gable(self, x0, y0, w, d, z, rise, mat="red", along_x=True, o=None, end="wall"):
        """Gable roof on a w x d plan at eave height z; ridge along x (or y). o = eave overhang (or (ox, oy))."""
        if o is None:
            o = min(0.08, 0.15 * min(w, d))
        ox, oy = o if isinstance(o, tuple) else (o, o)
        x0, y0, w, d = x0 - ox, y0 - oy, w + 2 * ox, d + 2 * oy
        x1, y1 = x0 + w, y0 + d
        r = z + rise
        if along_x:
            ym = y0 + d / 2
            faces = [([(x0, y1, z), (x1, y1, z), (x1, ym, r), (x0, ym, r)], mat, False),
                     ([(x0, y0, z), (x1, y0, z), (x1, ym, r), (x0, ym, r)], mat, False),
                     ([(x0, y0, z), (x0, y1, z), (x0, ym, r)], end, False),
                     ([(x1, y0, z), (x1, y1, z), (x1, ym, r)], end, False)]
        else:
            xm = x0 + w / 2
            faces = [([(x1, y0, z), (x1, y1, z), (xm, y1, r), (xm, y0, r)], mat, False),
                     ([(x0, y0, z), (x0, y1, z), (xm, y1, r), (xm, y0, r)], mat, False),
                     ([(x0, y0, z), (x1, y0, z), (xm, y0, r)], end, False),
                     ([(x0, y1, z), (x1, y1, z), (xm, y1, r)], end, False)]
        faces.append(([(x0, y0, z), (x1, y0, z), (x1, y1, z), (x0, y1, z)], mat, False))
        self.solid(faces)

    def hip(self, x0, y0, w, d, z, rise, mat="red", o=None):
        if o is None:
            o = min(0.08, 0.15 * min(w, d))
        x0, y0, w, d = x0 - o, y0 - o, w + 2 * o, d + 2 * o
        x1, y1 = x0 + w, y0 + d
        r = z + rise
        if w >= d:
            t = d / 2
            a, b = (x0 + t, y0 + t, r), (x1 - t, y0 + t, r)
            faces = [[(x0, y1, z), (x1, y1, z), b, a], [(x0, y0, z), (x1, y0, z), b, a],
                     [(x0, y0, z), (x0, y1, z), a], [(x1, y0, z), (x1, y1, z), b]]
        else:
            t = w / 2
            a, b = (x0 + t, y0 + t, r), (x0 + t, y1 - t, r)
            faces = [[(x1, y0, z), (x1, y1, z), b, a], [(x0, y0, z), (x0, y1, z), b, a],
                     [(x0, y0, z), (x1, y0, z), a], [(x0, y1, z), (x1, y1, z), b]]
        faces = [(f, mat, False) for f in faces]
        faces.append(([(x0, y0, z), (x1, y0, z), (x1, y1, z), (x0, y1, z)], mat, False))
        self.solid(faces)

    def shed(self, x0, y0, w, d, z_hi, z_lo, low="+y", mat="red", o=0.05, th=1.5):
        """A mono-pitch roof slab; the low edge is on side `low` ('+x', '-x', '+y', '-y')."""
        x0, y0, w, d = x0 - o, y0 - o, w + 2 * o, d + 2 * o

        def zt(x, y):
            f = {"+x": (x - x0) / w, "-x": (x0 + w - x) / w, "+y": (y - y0) / d, "-y": (y0 + d - y) / d}[low]
            return z_hi + (z_lo - z_hi) * f
        base = [(x0, y0), (x0 + w, y0), (x0 + w, y0 + d), (x0, y0 + d)]
        faces = []
        for i in range(4):
            (ax, ay), (bx, by) = base[i], base[(i + 1) % 4]
            faces.append(([(ax, ay, zt(ax, ay) - th), (bx, by, zt(bx, by) - th),
                           (bx, by, zt(bx, by)), (ax, ay, zt(ax, ay))], mat, False))
        faces.append(([(x, y, zt(x, y)) for x, y in base], mat, False))
        faces.append(([(x, y, zt(x, y) - th) for x, y in base][::-1], mat, False))
        self.solid(faces)

    def lean_to(self, x0, y0, w, d, z_hi, z_lo, low="+x", wall="wall", roof="red"):
        def zt(x, y):
            f = {"+x": (x - x0) / w, "-x": (x0 + w - x) / w, "+y": (y - y0) / d, "-y": (y0 + d - y) / d}[low]
            return z_hi + (z_lo - z_hi) * f
        self.prism([(x0, y0), (x0 + w, y0), (x0 + w, y0 + d), (x0, y0 + d)], 0, zt, wall)
        self.shed(x0, y0, w, d, z_hi + 1.5, z_lo + 1.5, low, roof)

    def posts(self, pts, z0, h, t=0.07, mat="wood"):
        for x, y in pts:
            self.box(x - t / 2, y - t / 2, t, t, z0, h, mat)

    def canopy(self, x0, y0, w, d, h, rise, mat="red", along_x=True, nx=2, ny=2, roof="gable", t=0.07,
               low="+y", z0=0):
        """Open roof on posts round the edge: nx posts along x, ny along y."""
        pts = []
        for i in range(nx):
            for j in range(ny):
                if i in (0, nx - 1) or j in (0, ny - 1):
                    pts.append((x0 + t / 2 + (w - t) * i / max(nx - 1, 1), y0 + t / 2 + (d - t) * j / max(ny - 1, 1)))
        self.posts(pts, z0, h - z0, t)
        if roof == "gable":
            self.gable(x0, y0, w, d, h, rise, mat, along_x)
        elif roof == "hip":
            self.hip(x0, y0, w, d, h, rise, mat)
        else:
            self.shed(x0, y0, w, d, h + rise, h, low, mat)

    def porch(self, x0, y0, w, d, h, rise, mat="red", along_x=False):
        self.canopy(x0, y0, w, d, h, rise, mat, along_x)

    def wall(self, x0, y0, x1, y1, h, t=0.09, mat="stone", z0=0):
        if y0 == y1:
            self.box(min(x0, x1), y0 - t / 2, abs(x1 - x0), t, z0, h, mat)
        else:
            self.box(x0 - t / 2, min(y0, y1), t, abs(y1 - y0), z0, h, mat)

    def fence(self, x0, y0, x1, y1, h=8, step=0.22, z0=0, mat="wood"):
        L = math.hypot(x1 - x0, y1 - y0)
        n = max(1, int(round(L / step)))
        self.posts([(x0 + (x1 - x0) * i / n, y0 + (y1 - y0) * i / n) for i in range(n + 1)], z0, h, 0.045, mat)
        for zr in (h * 0.45, h * 0.85):
            self.wall(x0, y0, x1, y1, 1.2, 0.025, mat, z0 + zr)

    def steps(self, x0, y0, w, d, n, h, up="-y", mat="stone"):
        """n steps on a w x d plan rising towards side `up`; the top step is one riser below h."""
        for i in range(n):
            f = (n - i) / n
            zz = h * (i + 1) / (n + 1)
            if up == "-y":
                self.box(x0, y0, w, d * f, 0, zz, mat)
            elif up == "+y":
                self.box(x0, y0 + d * (1 - f), w, d * f, 0, zz, mat)
            elif up == "-x":
                self.box(x0, y0, w * f, d, 0, zz, mat)
            else:
                self.box(x0 + w * (1 - f), y0, w * f, d, 0, zz, mat)

    def frustum(self, cx, cy, r0, r1, z0, h, mat="stone", n=16, ry0=None, ry1=None):
        ry0 = r0 if ry0 is None else ry0
        ry1 = r1 if ry1 is None else ry1
        a = [2 * math.pi * (i + 0.5) / n for i in range(n)]
        lo = [(cx + r0 * math.cos(t), cy + ry0 * math.sin(t), z0) for t in a]
        hi = [(cx + r1 * math.cos(t), cy + ry1 * math.sin(t), z0 + h) for t in a]
        faces = []
        for i in range(n):
            j = (i + 1) % n
            q = [lo[i], lo[j], hi[j], hi[i]] if r1 > 0 else [lo[i], lo[j], hi[i]]
            faces.append((q, mat, True))
        if r1 > 0:
            faces.append((hi, mat, False))
        faces.append((lo[::-1], mat, False))
        self.solid(faces)

    def cylinder(self, cx, cy, r, z0, h, mat="stone", n=16, top=None):
        self.frustum(cx, cy, r, r, z0, h, mat, n)
        if top:
            a = [2 * math.pi * (i + 0.5) / n for i in range(n)]
            self.flat_face([(cx + r * math.cos(t), cy + r * math.sin(t), z0 + h) for t in a], top)

    def cone(self, cx, cy, r, z, rise, mat="slate", n=16):
        self.frustum(cx, cy, r, 0, z, rise, mat, n)

    def ellipsoid(self, cx, cy, cz, rx, ry, rz, mat="green", n=14, rings=7, half=False):
        a = [2 * math.pi * (i + 0.5) / n for i in range(n)]
        lat0 = 0.0 if half else -math.pi / 2
        lats = [lat0 + (math.pi / 2 - lat0) * k / rings for k in range(rings + 1)]
        ring = [[(cx + rx * math.cos(p) * math.cos(t), cy + ry * math.cos(p) * math.sin(t), cz + rz * math.sin(p))
                 for t in a] for p in lats]
        faces = []
        for k in range(rings):
            for i in range(n):
                j = (i + 1) % n
                q = [ring[k][i], ring[k][j], ring[k + 1][j], ring[k + 1][i]]
                if k == rings - 1:
                    q = [ring[k][i], ring[k][j], ring[k + 1][i]]
                elif k == 0 and not half:
                    q = [ring[k][i], ring[k + 1][j], ring[k + 1][i]]
                faces.append((q, mat, True))
        if half:
            faces.append((ring[0][::-1], mat, False))
        self.solid(faces)

    def dome(self, cx, cy, rx, ry, z0, rz, mat="stone", n=16, rings=6):
        self.ellipsoid(cx, cy, z0, rx, ry, rz, mat, n, rings, half=True)

    def hcyl(self, axis, a, b, cz, r, length, mat="wood", rz=None, half=False, n=14):
        """Lying cylinder. axis 'x': starts at x=a, centre y=b; axis 'y': centre x=a, starts at y=b.
        r is in ground units across, rz in height units (default r*G, a round section)."""
        rz = r * G if rz is None else rz
        if half:
            ang = [math.pi * i / n for i in range(n + 1)]
        else:
            ang = [2 * math.pi * (i + 0.5) / n for i in range(n)]

        def pt(t, s):
            if axis == "x":
                return (a + s, b + r * math.cos(t), cz + rz * math.sin(t))
            return (a + r * math.cos(t), b + s, cz + rz * math.sin(t))
        e0 = [pt(t, 0) for t in ang]
        e1 = [pt(t, length) for t in ang]
        k = len(ang)
        faces = []
        for i in range(k if not half else k - 1):
            j = (i + 1) % k
            faces.append(([e0[i], e0[j], e1[j], e1[i]], mat, True))
        if half:
            faces.append(([e0[0], e0[-1], e1[-1], e1[0]], mat, False))
        faces.append((e0, mat, False))
        faces.append((e1[::-1], mat, False))
        self.solid(faces)

    def beam(self, p0, p1, t=0.05, mat="wood"):
        """Square timber between two 3D points (t in ground units)."""
        P0 = np.array([p0[0] * G, p0[1] * G, p0[2]])
        P1 = np.array([p1[0] * G, p1[1] * G, p1[2]])
        dv = P1 - P0
        dv = dv / np.linalg.norm(dv)
        ref = np.array([0.0, 0.0, 1.0]) if abs(dv[2]) < 0.9 else np.array([1.0, 0.0, 0.0])
        u = np.cross(dv, ref)
        u /= np.linalg.norm(u)
        w = np.cross(dv, u)
        hh = t * G / 2
        corners = [(u * sx + w * sy) * hh for sx, sy in ((-1, -1), (1, -1), (1, 1), (-1, 1))]

        def back(P):
            return (P[0] / G, P[1] / G, P[2])
        A = [back(P0 + c) for c in corners]
        B = [back(P1 + c) for c in corners]
        faces = [([A[i], A[(i + 1) % 4], B[(i + 1) % 4], B[i]], mat, False) for i in range(4)]
        faces += [(A, mat, False), (B, mat, False)]
        self.solid(faces)

    def arch_fill(self, x0, x1, y0, d, z_spring, z_top, mat="stone", n=24):
        """The masonry above a round arch spanning x0..x1 in a wall that runs along x (front face at y0 + d):
        one front polygon plus a smooth soffit. Put a deck or wall over z_top to close the top."""
        R = (x1 - x0) / 2
        xc = x0 + R
        k = min(1.0, (z_top - z_spring - 1.5) / (R * G))
        y1 = y0 + d
        xs = [x0 + (x1 - x0) * i / n for i in range(n + 1)]
        zs = [z_spring + math.sqrt(max(R * R - (x - xc) ** 2, 0)) * G * k for x in xs]
        gid = self._new_id()
        for i in range(n):
            q = [self._xf(p) for p in ((xs[i], y0, zs[i]), (xs[i + 1], y0, zs[i + 1]),
                                       (xs[i + 1], y1, zs[i + 1]), (xs[i], y1, zs[i]))]
            nrm = newell(q)
            fc = np.mean(np.array(q), axis=0)
            inward = np.array([xc, fc[1], z_spring]) - fc
            if nrm @ inward < 0:
                q, nrm = q[::-1], -nrm
            self._raster(q, shade(mat, nrm), gid)
        front = [(x0, y1, z_top), (x1, y1, z_top)] + [(xs[i], y1, zs[i]) for i in range(n, -1, -1)]
        self.flat_face(front, mat, 0.0)

    def _box_faces(self, x0, y0, w, d, z0, h, mat):
        x1, y1, z1 = x0 + w, y0 + d, z0 + h
        b = [(x0, y0), (x1, y0), (x1, y1), (x0, y1)]
        f = []
        for i in range(4):
            (ax, ay), (bx, by) = b[i], b[(i + 1) % 4]
            f.append(([(ax, ay, z0), (bx, by, z0), (bx, by, z1), (ax, ay, z1)], mat, False))
        f.append(([(x, y, z1) for x, y in b], mat, False))
        f.append(([(x, y, z0) for x, y in b][::-1], mat, False))
        return f

    # ---- flat details -----------------------------------------------------------------------------------------
    def flat(self, x0, y0, w, d, z=0.0, mat="water"):
        self.flat_face([(x0, y0, z), (x0 + w, y0, z), (x0 + w, y0 + d, z), (x0, y0 + d, z)], mat)

    def water(self, x0, y0, w, d, z=0.0):
        self.flat(x0, y0, w, d, z, "water")

    def door(self, x0, x1, y, z0, z1, mat="dark"):
        """An opening on a wall that faces +y (the light side)."""
        self.flat_face([(x0, y, z0), (x1, y, z0), (x1, y, z1), (x0, y, z1)], mat)

    def door_x(self, y0, y1, x, z0, z1, mat="dark"):
        """An opening on a wall that faces +x (the dark side)."""
        self.flat_face([(x, y0, z0), (x, y1, z0), (x, y1, z1), (x, y0, z1)], mat)

    def arch_door(self, xc, hw, y, z0, zs, mat="dark", n=10):
        pts = [(xc - hw, y, z0), (xc + hw, y, z0)]
        pts += [(xc + hw * math.cos(math.pi * i / n), y, zs + hw * G * 0.7 * math.sin(math.pi * i / n))
                for i in range(n + 1)]
        self.flat_face(pts, mat)

    def tree(self, cx, cy, trunk, r, rz):
        self.cylinder(cx, cy, 0.045, 0, trunk + rz * 0.5, "wood", 8)
        self.ellipsoid(cx, cy, trunk + rz * 0.9, r, r, rz, "green")


# ---- sheets ---------------------------------------------------------------------------------------------------
def _font(size):
    try:
        return ImageFont.truetype("arial.ttf", size)
    except OSError:
        return ImageFont.load_default(size)


def render(fn):
    c = Canvas()
    fn(c)
    return c.image()


def make_sheet(fns, path, cols=3, pad=110):
    tiles = [render(fn) for fn in fns]
    cw = max(t.width for t in tiles) + pad
    rows = (len(tiles) + cols - 1) // cols
    row_h = []
    for r in range(rows):
        row_h.append(max(t.height for t in tiles[r * cols:(r + 1) * cols]) + pad)
    sheet = Image.new("RGBA", (cw * min(cols, len(tiles)) + pad, sum(row_h) + pad), (255, 255, 255, 255))
    d = ImageDraw.Draw(sheet)
    f = _font(40)
    ytop = pad
    for r in range(rows):
        for k, t in enumerate(tiles[r * cols:(r + 1) * cols]):
            i = r * cols + k
            cx0 = pad + k * cw
            x = cx0 + (cw - pad - t.width) // 2
            y = ytop + (row_h[r] - pad - t.height)
            sheet.alpha_composite(t, (x, y))
            d.text((cx0 - pad // 2 + 6, ytop - pad // 2 - 14), str(i + 1), fill=(192, 192, 192, 255), font=f)
        ytop += row_h[r]
    sheet = sheet.convert("RGB")
    sheet.save(path)
    return sheet


def make_overview(items, path, cols=4, tile_w=900):
    """items: list of (caption, png path)."""
    f = _font(30)
    cells = []
    for cap, p in items:
        im = Image.open(p).convert("RGB")
        s = tile_w / im.width
        im = im.resize((tile_w, max(1, int(round(im.height * s)))), Image.LANCZOS)
        cells.append((cap, im))
    rows = (len(cells) + cols - 1) // cols
    gap, cap_h = 30, 44
    row_h = [max(im.height for _, im in cells[r * cols:(r + 1) * cols]) + cap_h + gap for r in range(rows)]
    out = Image.new("RGB", (cols * (tile_w + gap) + gap, sum(row_h) + gap), (255, 255, 255))
    d = ImageDraw.Draw(out)
    y = gap
    for r in range(rows):
        for k, (cap, im) in enumerate(cells[r * cols:(r + 1) * cols]):
            x = gap + k * (tile_w + gap)
            d.text((x, y), cap, fill=(70, 70, 70), font=f)
            out.paste(im, (x, y + cap_h))
            d.rectangle([x - 1, y + cap_h - 1, x + im.width, y + cap_h + im.height], outline=(210, 210, 210))
        y += row_h[r]
    out.save(path)
