"""Procedural Japanese-style suburb for the Journey's last zone.

Not a grid: a few crooked streets (T-junctions, dead ends, one wider main
road), lots of different sizes strung along them, and a mix of what a real
neighbourhood has (houses of four kinds, small apartment blocks, corner
shops, parking, an empty plot), plus utility poles, vending machines, a
park and a shrine. Deterministic (fixed seed).
"""
import math
import random

HX, HZ = 300.0, 260.0
YARD = (-70, -65, 110, 115)          # the player's own lot (x0, z0, x1, z1)

# Streets: polylines with a width. The first is the street in front of home.
ROADS = [
    {"pts": [(-300, -84), (-115, -80), (60, -78), (300, -86)], "w": 22},          # front street
    {"pts": [(178, -260), (186, -80), (198, 60), (212, 260)], "w": 36, "main": True},
    {"pts": [(-118, -260), (-112, -80), (-118, 80), (-110, 260)], "w": 20},       # west street
    {"pts": [(-300, 176), (-114, 170), (60, 162), (200, 152)], "w": 20},          # north street
    {"pts": [(-112, 40), (-300, 54)], "w": 14},                                    # alley (west)
    {"pts": [(-30, -82), (-24, -150), (-34, -205)], "w": 14},                      # lane south
    {"pts": [(-300, -206), (-116, -200), (40, -210), (180, -204)], "w": 18},      # south street
    {"pts": [(190, -10), (300, -2)], "w": 14},                                     # lane east of main
    {"pts": [(60, 162), (66, 260)], "w": 14},                                      # lane north
]

PARK = (-235, -66, -150, 26)
SHRINE = (-285, 188, -205, 255)
RESERVED = [PARK, SHRINE]


def segs(road):
    p = road["pts"]
    return [(p[i], p[i + 1]) for i in range(len(p) - 1)]


def rot_pt(x, z, r):
    return (x * math.cos(r) + z * math.sin(r), -x * math.sin(r) + z * math.cos(r))


def obb(cx, cz, w, d, r):
    """Corners of a w x d rectangle centred at (cx, cz), turned by r (radians, Godot yaw)."""
    out = []
    for sx, sz in ((-1, -1), (1, -1), (1, 1), (-1, 1)):
        dx, dz = rot_pt(sx * w / 2, sz * d / 2, r)
        out.append((cx + dx, cz + dz))
    return out


def sat(a, b):
    for poly in (a, b):
        for i in range(len(poly)):
            x0, z0 = poly[i]
            x1, z1 = poly[(i + 1) % len(poly)]
            nx, nz = z1 - z0, x0 - x1
            pa = [nx * x + nz * z for x, z in a]
            pb = [nx * x + nz * z for x, z in b]
            if max(pa) < min(pb) or max(pb) < min(pa):
                return False
    return True


def rect_poly(r, grow=0.0):
    x0, z0, x1, z1 = r
    return [(x0 - grow, z0 - grow), (x1 + grow, z0 - grow), (x1 + grow, z1 + grow), (x0 - grow, z1 + grow)]


def seg_dist(px, pz, a, b):
    ax, az = a
    bx, bz = b
    dx, dz = bx - ax, bz - az
    t = max(0.0, min(1.0, ((px - ax) * dx + (pz - az) * dz) / (dx * dx + dz * dz)))
    return math.hypot(px - ax - t * dx, pz - az - t * dz)


def road_clear(poly, margin):
    """True if no street comes within `margin` of the polygon (sampled)."""
    cx = sum(p[0] for p in poly) / 4
    cz = sum(p[1] for p in poly) / 4
    pts = poly + [(cx, cz)] + [((poly[i][0] + poly[(i + 1) % 4][0]) / 2, (poly[i][1] + poly[(i + 1) % 4][1]) / 2) for i in range(4)]
    for road in ROADS:
        for a, b in segs(road):
            for px, pz in pts:
                if seg_dist(px, pz, a, b) < road["w"] / 2 + margin:
                    return False
            # the road may cross the middle of a big lot
            n = int(math.hypot(b[0] - a[0], b[1] - a[1]) / 4) + 1
            for k in range(n + 1):
                t = k / n
                x, z = a[0] + (b[0] - a[0]) * t, a[1] + (b[1] - a[1]) * t
                if point_in(poly, x, z):
                    return False
    return True


def point_in(poly, x, z):
    sign = 0
    for i in range(4):
        x0, z0 = poly[i]
        x1, z1 = poly[(i + 1) % 4]
        c = (x1 - x0) * (z - z0) - (z1 - z0) * (x - x0)
        s = 1 if c > 0 else -1
        if sign == 0:
            sign = s
        elif s != sign:
            return False
    return True


def inside_map(poly, m=6):
    return all(abs(x) < HX - m and abs(z) < HZ - m for x, z in poly)


def build(toy, C):
    rng = random.Random(20261013)
    layout, floors, clutter_pts = [], [], []
    taken = [rect_poly(YARD, 6)] + [rect_poly(r, 2) for r in RESERVED]

    def free(poly):
        return inside_map(poly) and not any(sat(poly, t) for t in taken)

    # --- road surfaces: asphalt, white edge lines, a centre line on the main road
    for road in ROADS:
        for a, b in segs(road):
            # extend a little so joints and corners have no gaps
            dx, dz = b[0] - a[0], b[1] - a[1]
            L = math.hypot(dx, dz)
            ux, uz = dx / L, dz / L
            e = road["w"] / 2
            a2 = (a[0] - ux * e, a[1] - uz * e)
            b2 = (b[0] + ux * e, b[1] + uz * e)
            floors.append({"layer": 2, "seg": [a2[0], a2[1], b2[0], b2[1]], "w": road["w"], "color": C("5d5f68")})
    for road in ROADS:
        for a, b in segs(road):
            dx, dz = b[0] - a[0], b[1] - a[1]
            L = math.hypot(dx, dz)
            nx, nz = -dz / L, dx / L
            off = road["w"] / 2 - 1.2
            for s in (-1, 1):
                floors.append({"seg": [a[0] + nx * off * s, a[1] + nz * off * s, b[0] + nx * off * s, b[1] + nz * off * s],
                               "w": 0.5, "color": C("e8e6e0"), "layer": 3})
            if road.get("main"):
                floors.append({"layer": 3, "seg": [a[0], a[1], b[0], b[1]], "w": 0.6, "color": C("f2c94c")})
    # a zebra crossing in front of home, and one on the main road
    for i in range(6):
        x = -6 + i * 2.4
        floors.append({"layer": 3, "rect": [x, -90, x + 1.2, -70], "color": C("eeeeea")})
    for i in range(8):
        z = -20 + i * 2.6
        floors.append({"layer": 3, "seg": [176, z, 208, z + 2.8], "w": 1.3, "color": C("eeeeea")})

    # --- lots along the streets
    kinds = []
    for road in ROADS:
        for a, b in segs(road):
            dx, dz = b[0] - a[0], b[1] - a[1]
            L = math.hypot(dx, dz)
            ux, uz = dx / L, dz / L
            for side in (-1, 1):
                nx, nz = -uz * side, ux * side          # from the road towards the lot
                t = rng.uniform(4, 16)
                while t < L - 10:
                    main = road.get("main", False)
                    roll = rng.random()
                    if main and roll < 0.30:
                        kind, w, d = "apartment", rng.uniform(62, 72), rng.uniform(40, 48)
                    elif main and roll < 0.55:
                        kind, w, d = "shop", rng.uniform(56, 64), rng.uniform(46, 54)
                    elif roll < 0.10:
                        kind, w, d = "apartment", rng.uniform(62, 70), rng.uniform(40, 46)
                    elif roll < 0.17:
                        kind, w, d = "parking", rng.uniform(40, 56), rng.uniform(36, 50)
                    elif roll < 0.22:
                        kind, w, d = "field", rng.uniform(34, 50), rng.uniform(30, 46)
                    else:
                        kind, w, d = "house", rng.uniform(40, 52), rng.uniform(44, 56)
                    setback = road["w"] / 2 + rng.uniform(2.5, 6.0)
                    cxr = a[0] + ux * (t + w / 2) + nx * (setback + d / 2)
                    czr = a[1] + uz * (t + w / 2) + nz * (setback + d / 2)
                    # the lot faces the road: local +z points back at it
                    r = math.atan2(-nx, -nz) + rng.uniform(-0.04, 0.04)
                    poly = obb(cxr, czr, w, d, r)
                    if free(poly) and road_clear(poly, 1.5):
                        taken.append(poly)
                        kinds.append(kind)
                        _fill_lot(kind, cxr, czr, w, d, r, rng, toy, C, layout, floors)
                        t += w + rng.uniform(1, 6)
                    else:
                        t += rng.uniform(6, 14)

    # --- infill: back-row lots in the blocks (flag lots), facing the nearest street
    tries = 0
    while len(kinds) < 90 and tries < 10000:
        tries += 1
        x, z = rng.uniform(-HX + 20, HX - 20), rng.uniform(-HZ + 20, HZ - 20)
        best = None
        for road in ROADS:
            for a, b in segs(road):
                dist = seg_dist(x, z, a, b)
                if best is None or dist < best[0]:
                    best = (dist, a, b)
        _, a, b = best
        dx, dz = b[0] - a[0], b[1] - a[1]
        L = math.hypot(dx, dz)
        ux, uz = dx / L, dz / L
        t = (x - a[0]) * ux + (z - a[1]) * uz
        fx, fz = a[0] + ux * t, a[1] + uz * t          # foot on the road line
        nx, nz = x - fx, z - fz                        # road -> lot
        nl = math.hypot(nx, nz) or 1.0
        r = math.atan2(-nx / nl, -nz / nl) + rng.uniform(-0.06, 0.06)
        roll = rng.random()
        if roll < 0.12:
            kind, w, d = "apartment", rng.uniform(62, 70), rng.uniform(40, 46)
        elif roll < 0.2:
            kind, w, d = "field", rng.uniform(30, 46), rng.uniform(28, 40)
        elif roll < 0.26:
            kind, w, d = "parking", rng.uniform(40, 52), rng.uniform(34, 44)
        else:
            kind, w, d = "house", rng.uniform(24, 40), rng.uniform(26, 42)
        poly = obb(x, z, w, d, r)
        if free(poly) and road_clear(poly, 2.0):
            taken.append(poly)
            kinds.append(kind)
            _fill_lot(kind, x, z, w, d, r, rng, toy, C, layout, floors)

    # --- poles along the streets (one side), a few cars parked on the street
    for k, road in enumerate(ROADS):
        for a, b in segs(road):
            dx, dz = b[0] - a[0], b[1] - a[1]
            L = math.hypot(dx, dz)
            ux, uz = dx / L, dz / L
            side = 1 if k % 2 else -1
            nx, nz = -uz * side, ux * side
            t = rng.uniform(10, 30)
            while t < L - 8:
                x = a[0] + ux * t + nx * (road["w"] / 2 + 1.0)
                z = a[1] + uz * t + nz * (road["w"] / 2 + 1.0)
                if abs(x) < HX - 4 and abs(z) < HZ - 4 and not point_in(rect_poly(YARD, 2), x, z):
                    layout.append(toy("utilitypole", 6, 16.0, 300, round(x, 1), round(z, 1),
                                      round(math.degrees(math.atan2(ux, uz)), 1), solid=[0.25, 0.25]))
                t += rng.uniform(62, 80)
            if rng.random() < 0.6 and L > 60:
                t = rng.uniform(20, L - 20)
                off = road["w"] / 2 - 3.2
                x = a[0] + ux * t - nx * off
                z = a[1] + uz * t - nz * off
                kind = rng.choice(["sedan", "sedan", "van"])
                layout.append(toy(kind, 7, 6.5 if kind == "sedan" else 8.0, 400 if kind == "sedan" else 450,
                                  round(x, 1), round(z, 1), round(math.degrees(math.atan2(ux, uz)) - 90, 1)))
    # buses on the main road
    layout.append(toy("bus", 8, 11.0, 700, 190, -150, -87))
    layout.append(toy("bus", 8, 11.0, 700, 205, 150, -86))

    # --- park: trees, playground, benches, a fountain
    px0, pz0, px1, pz1 = PARK
    floors.append({"layer": 1, "rect": [px0, pz0, px1, pz1], "kind": "lawn"})
    floors.append({"layer": 2, "rect": [px0 + 30, pz0 + 30, px0 + 60, pz0 + 52], "color": C("d9b46a")})
    layout += [
        toy("fountain", 8, 12.0, 700, -192, -10),
        toy("slide", 6, 9.0, 300, -200, -26, 30), toy("swing", 6, 9.0, 300, -185, -40, 0),
        toy("bench", 5, 4.5, 200, -168, 0, -90),
        toy("bench", 5, 4.5, 200, -168, -30, -90),
        toy("tree", 8, 24.0, 650, -225, 14, solid=[0.15, 0.15]), toy("tree", 8, 24.0, 650, -160, 16, solid=[0.15, 0.15]),
        toy("pine", 8, 26.0, 650, -226, -56, solid=[0.25, 0.25]), toy("tree", 8, 24.0, 650, -158, -58, solid=[0.15, 0.15]),
        toy("bikerack", 5, 3.5, 200, -175, 20, 0),
    ]
    # --- shrine in a grove
    sx0, sz0, sx1, sz1 = SHRINE
    floors.append({"layer": 1, "rect": [sx0, sz0, sx1, sz1], "color": C("b9b09a")})
    floors.append({"layer": 2, "rect": [-250, 188, -240, 228], "color": C("d8cfb8")})
    layout += [
        toy("torii", 8, 18.0, 700, -245, 192, 180, solid=[0.9, 0.1]),
        toy("shrine", 9, 26.0, 1000, -245, 238, 180),
        toy("pine", 8, 28.0, 650, -275, 205, solid=[0.25, 0.25]), toy("pine", 8, 28.0, 650, -212, 210, solid=[0.25, 0.25]),
        toy("tree", 8, 24.0, 650, -278, 245, solid=[0.15, 0.15]), toy("tree", 8, 24.0, 650, -212, 248, solid=[0.15, 0.15]),
    ]
    return layout, floors, kinds


def _fill_lot(kind, cx, cz, w, d, r, rng, toy, C, layout, floors):
    deg = round(math.degrees(r), 1)

    def at(lx, lz):
        dx, dz = rot_pt(lx, lz, r)
        return round(cx + dx, 1), round(cz + dz, 1)

    ground = {"house": rng.choice([C("b3ab98"), C("a69f8b"), "lawn"]), "apartment": C("aca89e"),
              "shop": C("7a7c80"), "parking": C("5d5f68"), "field": rng.choice([C("8a6a4a"), "lawn"])}[kind]
    patch = {"layer": 1, "rect": [cx - w / 2, cz - d / 2, cx + w / 2, cz + d / 2], "rot": deg}
    if ground == "lawn":
        patch["kind"] = "lawn"
    else:
        patch["color"] = ground
    floors.append(patch)
    if kind == "house":
        # Small lots get small houses: the house fills the back of the lot.
        h = round(max(20.0, min(38.0, w * 0.78, (d - 8) * 1.0, rng.uniform(26, 38))), 1)
        t, s = (9, 900) if h >= 33 else ((8, 650) if h >= 25 else (7, 480))
        bx, bz = at(rng.uniform(-2, 2), -d / 2 + 0.47 * h + 1)
        layout.append(toy("house", t, h, s, bx, bz, deg, solid=[0.9, 0.9]))
        roll = rng.random()
        if roll < 0.5:
            x, z = at(w / 2 - 9 if rng.random() < 0.5 else -w / 2 + 9, d / 2 - 7)
            layout.append(toy("sedan", 7, 6.5, 400, x, z, deg + 90))
        elif roll < 0.75:
            x, z = at(w / 2 - 6, d / 2 - 5)
            layout.append(toy("bicycle", 5, 5.0, 200, x, z, deg + 90))
        if rng.random() < 0.6:
            x, z = at(-w / 2 + 5, d / 2 - 4)
            layout.append(toy("bush", 5, 7.0, 220, x, z, 0))
        if rng.random() < 0.5:
            x, z = at(w / 2 - 5, -d / 2 + 6)
            layout.append(toy("tree", 7, 18.0, 450, x, z, 0, solid=[0.15, 0.15]))
        if rng.random() < 0.5:
            x, z = at(-w / 2 + 3, -d / 2 + 30)
            layout.append(toy("ac", 4, 4.0, 110, x, z, deg - 90))
    elif kind == "apartment":
        h = round(rng.uniform(38, 46), 1)
        bx, bz = at(0, -d / 2 + 20)
        layout.append(toy("apartment", 9, h, 1100, bx, bz, deg, solid=[0.95, 0.95]))
        x, z = at(-w / 2 + 6, d / 2 - 5)
        layout.append(toy("bikerack", 5, 3.5, 200, x, z, deg))
        x, z = at(w / 2 - 8, d / 2 - 6)
        layout.append(toy("vending", 6, 9.0, 300, x, z, deg))
    elif kind == "shop":
        bx, bz = at(0, -d / 2 + 16)
        layout.append(toy("shop", 8, 17.0, 700, bx, bz, deg, solid=[0.95, 0.95]))
        for k in range(2):
            x, z = at(-w / 2 + 10 + k * 16, d / 2 - 8)
            layout.append(toy("sedan", 7, 6.5, 400, x, z, deg + rng.uniform(-8, 8)))
        x, z = at(w / 2 - 5, d / 2 - 14)
        layout.append(toy("vending", 6, 9.0, 300, x, z, deg))
        x, z = at(w / 2 - 9, d / 2 - 14)
        layout.append(toy("vending", 6, 9.0, 300, x, z, deg))
    elif kind == "parking":
        n = int(w // 14)
        for k in range(n):
            if rng.random() < 0.7:
                x, z = at(-w / 2 + 7 + k * 14, rng.uniform(-6, 6))
                kind_c = "van" if rng.random() < 0.3 else "sedan"
                layout.append(toy(kind_c, 7, 8.0 if kind_c == "van" else 6.5, 450 if kind_c == "van" else 400,
                                  x, z, deg + 90 + rng.uniform(-6, 6)))
        x, z = at(w / 2 - 4, d / 2 - 4)
        layout.append(toy("vending", 6, 9.0, 300, x, z, deg))
    else:  # field / empty plot
        for k in range(rng.randint(2, 4)):
            x, z = at(rng.uniform(-w / 2 + 6, w / 2 - 6), rng.uniform(-d / 2 + 6, d / 2 - 6))
            layout.append(toy("bush", 5, 7.0, 220, x, z, rng.uniform(0, 360)))
