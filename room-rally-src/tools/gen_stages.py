"""Generate room-rally-src/scripts/stages.gd from the stage designs below."""
import sys

FUR = "res://assets/models/furniture/"
FOOD = "res://assets/models/food/"


class C:  # GDScript Color literal
    def __init__(self, h): self.h = h


def gd(v, ind=0):
    pad = "\t" * ind
    if isinstance(v, C):
        return 'Color("%s")' % v.h
    if isinstance(v, bool):
        return "true" if v else "false"
    if isinstance(v, (int, float)):
        return repr(round(v, 3)) if isinstance(v, float) else str(v)
    if isinstance(v, str):
        return '"%s"' % v
    if isinstance(v, list):
        if all(not isinstance(x, (dict, list)) for x in v):
            return "[" + ", ".join(gd(x) for x in v) + "]"
        return "[\n" + "".join(pad + "\t" + gd(x, ind + 1) + ",\n" for x in v) + pad + "]"
    if isinstance(v, dict):
        inner = ", ".join('"%s": %s' % (k, gd(x, ind + 1)) for k, x in v.items())
        if len(inner) < 150 and not any(isinstance(x, (dict, list)) and x and isinstance(x, list) and isinstance(x[0], dict) for x in v.values()):
            return "{" + inner + "}"
        return "{\n" + "".join(pad + '\t"%s": %s,\n' % (k, gd(x, ind + 1)) for k, x in v.items()) + pad + "}"
    raise TypeError(v)


# Furniture catalogue: model, tier, height, points (bigger = more points).
def fur(name, t, h, s, x, z, rot=0, **kw):
    d = {"p": FUR + name + ".glb", "t": t, "h": h, "s": s, "x": x, "z": z, "rot": rot}
    d.update(kw)
    return d


def kitchen(name, x, z, rot=0, t=4, s=110, **kw):
    h = {"kitchenFridge": 9.2, "kitchenSink": 4.9}.get(name, 4.5)
    if name == "kitchenFridge":
        t, s = 6, 500
    return fur(name, t, h, s, x, z, rot, sc=10, **kw)


# Clutter / on-top item catalogue.
ITEMS = {
    "mug": {"p": FOOD + "mug.glb", "col": C("e8576d"), "t": 0, "h": 0.8, "s": 10},
    "cup": {"p": FOOD + "cup.glb", "col": C("f2b33d"), "t": 0, "h": 0.7, "s": 10},
    "glass": {"p": FOOD + "glass.glb", "col": C("a8d8ea"), "t": 0, "h": 0.9, "s": 10},
    "can": {"p": FOOD + "soda-can.glb", "col": C("d9363e"), "t": 0, "h": 1.0, "s": 15},
    "bottle": {"p": FOOD + "soda-bottle.glb", "col": C("4fb06a"), "t": 1, "h": 2.0, "s": 30},
    "ketchup": {"p": FOOD + "bottle-ketchup.glb", "col": C("d23b3b"), "t": 1, "h": 1.8, "s": 25},
    "carton": {"p": FOOD + "carton.glb", "col": C("6aa8e8"), "t": 1, "h": 1.7, "s": 20},
    "mouse": {"p": FUR + "computerMouse.glb", "t": 0, "h": 0.5, "s": 10},
    "books": {"p": FUR + "books.glb", "t": 1, "h": 1.5, "s": 20},
    "screen": {"p": FUR + "computerScreen.glb", "t": 2, "h": 2.5, "s": 35},
    "plant_s": {"p": FUR + "plantSmall2.glb", "t": 1, "h": 2.0, "s": 25},
    "plant": {"p": FUR + "plantSmall1.glb", "t": 2, "h": 2.4, "s": 40},
    "box_s": {"p": FUR + "cardboardBoxClosed.glb", "t": 3, "h": 3.2, "s": 70},
    "radio": {"p": FUR + "radio.glb", "t": 2, "h": 2.0, "s": 35},
    "microwave": {"p": FUR + "kitchenMicrowave.glb", "t": 3, "h": 3.2, "s": 70},
    "coffee": {"p": FUR + "kitchenCoffeeMachine.glb", "t": 3, "h": 3.4, "s": 70},
    "toaster": {"p": FUR + "toaster.glb", "t": 2, "h": 2.2, "s": 40},
    "blender": {"p": FUR + "kitchenBlender.glb", "t": 2, "h": 2.6, "s": 45},
    "tv": {"p": FUR + "televisionModern.glb", "t": 4, "h": 4.0, "s": 120},
    # procedural toys
    "candy": {"toy": "candy", "t": 0, "h": 0.4, "s": 5},
    "donut": {"toy": "donut", "t": 0, "h": 0.4, "s": 5},
    "apple": {"toy": "apple", "t": 0, "h": 0.8, "s": 10},
    "orange": {"toy": "orange", "t": 0, "h": 0.8, "s": 10},
    "block": {"toy": "block", "t": 0, "h": 0.9, "s": 10},
    "paper": {"toy": "paper", "t": 0, "h": 0.6, "s": 5},
    "slipper": {"toy": "slipper", "t": 0, "h": 0.5, "s": 5},
    "phone": {"toy": "phone", "t": 0, "h": 0.3, "s": 10},
    "remote": {"toy": "remote", "t": 0, "h": 0.4, "s": 10},
    "duck": {"toy": "duck", "t": 1, "h": 1.2, "s": 20},
    "car": {"toy": "car", "t": 1, "h": 1.0, "s": 20},
    "ball": {"toy": "ball", "t": 1, "h": 1.4, "s": 25},
    "cushion": {"toy": "cushion", "t": 1, "h": 1.0, "s": 20},
    "tissue": {"toy": "tissue", "t": 1, "h": 1.0, "s": 15},
    "cactus": {"toy": "cactus", "t": 1, "h": 1.6, "s": 25},
    "piggy": {"toy": "piggy", "t": 1, "h": 1.6, "s": 25},
    "basket": {"toy": "basket", "t": 1, "h": 1.8, "s": 30},
    "teddy": {"toy": "teddy", "t": 2, "h": 2.2, "s": 40},
    "robot": {"toy": "robot", "t": 2, "h": 2.4, "s": 45},
    "drum": {"toy": "drum", "t": 2, "h": 2.2, "s": 40},
    "globe": {"toy": "globe", "t": 2, "h": 2.4, "s": 40},
    "beachball": {"toy": "beachball", "t": 2, "h": 2.4, "s": 45},
    "basketball": {"toy": "basketball", "t": 2, "h": 2.4, "s": 45},
    "suitcase": {"toy": "suitcase", "t": 2, "h": 2.0, "s": 45},
    "fan": {"toy": "fan", "t": 3, "h": 3.0, "s": 60},
    "dollhouse": {"toy": "dollhouse", "t": 3, "h": 3.4, "s": 70},
    # garden
    "flower": {"toy": "flower", "t": 0, "h": 0.9, "s": 5},
    "rock": {"toy": "rock", "t": 0, "h": 0.5, "s": 5},
    "acorn": {"toy": "acorn", "t": 0, "h": 0.5, "s": 5},
    "mushroom": {"toy": "mushroom", "t": 0, "h": 0.7, "s": 10},
    "hose": {"toy": "hose", "t": 1, "h": 0.45, "s": 20},
    "bucket": {"toy": "bucket", "t": 1, "h": 1.2, "s": 20},
    "wateringcan": {"toy": "wateringcan", "t": 1, "h": 1.3, "s": 25},
    "gnome": {"toy": "gnome", "t": 1, "h": 1.8, "s": 30},
    "flamingo": {"toy": "flamingo", "t": 2, "h": 3.0, "s": 40},
    "bush_s": {"toy": "bush", "t": 2, "h": 2.2, "s": 40},
    "rock_l": {"toy": "rock", "t": 2, "h": 1.6, "s": 40},
    "bush": {"toy": "bush", "t": 3, "h": 3.6, "s": 70},
    "hydrant": {"toy": "hydrant", "t": 3, "h": 3.0, "s": 60},
    "coin": {"toy": "coin", "t": 0, "h": 0.15, "s": 5},
    "marble": {"toy": "marble", "t": 0, "h": 0.3, "s": 5},
    "button": {"toy": "button", "t": 0, "h": 0.15, "s": 5},
    "crayon": {"toy": "crayon", "t": 0, "h": 0.3, "s": 5},
    "die": {"toy": "die", "t": 0, "h": 0.4, "s": 5},
    "eraser": {"toy": "eraser", "t": 0, "h": 0.3, "s": 5},
    "pencil": {"toy": "pencil", "t": 0, "h": 0.25, "s": 5},
    "skateboard": {"toy": "skateboard", "t": 1, "h": 0.6, "s": 25},
    # street (sizes for a truck that is already huge)
    "cone_b": {"toy": "trafficcone", "t": 3, "h": 3.0, "s": 60},
    "hydrant_b": {"toy": "hydrant", "t": 4, "h": 4.5, "s": 100},
    "mailbox_b": {"toy": "mailbox", "t": 4, "h": 5.5, "s": 110},
    "bike_b": {"toy": "bicycle", "t": 5, "h": 5.0, "s": 200},
    "bench_b": {"toy": "bench", "t": 5, "h": 4.5, "s": 200},
    "bush_b": {"toy": "bush", "t": 5, "h": 7.0, "s": 220},
}


def items(kind, c, **kw):
    d = dict(ITEMS[kind])
    d["c"] = c
    d.update(kw)
    return d


def on(support, kind, c=1, **kw):
    d = items(kind, c, **kw)
    d = {"on": support, **d}
    return d


def toy(kind, t, h, s, x, z, rot=0, **kw):
    d = {"toy": kind, "t": t, "h": h, "s": s, "x": x, "z": z, "rot": rot}
    d.update(kw)
    return d


def tree(x, z, kind="tree", rot=0):
    if kind == "pine":
        return toy("pine", 5, 10.0, 250, x, z, rot, solid=[0.25, 0.25])
    return toy("tree", 6, 14.0, 450, x, z, rot, solid=[0.15, 0.15])


def rug(name, x, z, w, d, rot=0):
    return {"p": FUR + name + ".glb", "x": x, "z": z, "rot": rot, "w": w, "d": d}


STAGES = []

# ---------------------------------------------------------------- 0 Journey
# One continuous world. The truck starts tiny in a kid's room in the middle of
# a house; growing opens the way out, room by room, then the garden, then the
# street around the block. Zones appear one tier before they can be reached
# (see PropSpawner), and things far smaller than the truck are dropped.
import os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import town  # noqa: E402

YARD = list(town.YARD)
town_layout, town_floors, town_kinds = town.build(toy, C)

STAGES.append({
    "name": "Journey",
    "journey": True,
    "hx": 300.0, "hz": 260.0,
    "time": 75.0,
    "outdoor": True,
    "fence": C("f4ead8"),
    "inner_wall": C("f1e4cf"), "wall": C("f1e4cf"), "stripe": C("e6d6bc"),
    "tier_thresholds": [40, 200, 500, 1100, 2200, 4000, 9000, 20000, 40000],
    "tier_time": [10, 10, 15, 15, 20, 20, 20, 20, 15],
    "star_scores": [6000, 25000, 60000],
    "floors": [
        # the town is paved; grass only in gardens, the park and plots
        {"layer": 0, "rect": [-300, -260, 300, 260], "color": C("8f8b80")},
        {"layer": 1, "rect": YARD, "kind": "lawn"},
        {"layer": 2, "rect": [-50, -40, 50, 40], "kind": "planks"},
        {"layer": 3, "rect": [-50, -40, -18, 40], "color": C("aab6b2")},                 # kitchen tiles
        {"layer": 3, "rect": [-18, -14, 18, 14], "color": C("8e7ab8")},                  # kid's room carpet
        {"layer": 2, "rect": [-26, 40, 28, 56], "kind": "planks", "a": C("b98a5e"), "b": C("a07550")},  # deck
        {"layer": 2, "rect": [-6, -65, 6, -40], "color": C("b0a690")},                   # front path
        {"layer": 2, "rect": [20, -65, 44, -40], "color": C("9a9890")},                  # driveway
        {"layer": 2, "rect": [60, 10, 90, 34], "color": C("d9b46a")},                    # sand pit
        {"layer": 2, "rect": [-40, 92, -6, 104], "color": C("8a6a4a")},                  # flower bed
        {"layer": 2, "rect": [60, -35, 100, -25], "color": C("8a6a4a")},                 # vegetable bed
    ] + town_floors,
    "walls": [
        # kid's room (doors west and east, blocked by toy boxes until tier 2)
        {"from": [-18, -14], "to": [-18, 14], "doors": [[14.0, 6.0]], "break_tier": 5},
        {"from": [18, -14], "to": [18, 14], "doors": [[14.0, 6.0]], "break_tier": 5},
        {"from": [-18, 14], "to": [18, 14], "doors": [], "break_tier": 5},
        {"from": [-18, -14], "to": [18, -14], "doors": [], "break_tier": 5},
        # house shell (patio door north, front door south, moving boxes until tier 4)
        # 22 wide: the biggest truck the house can grow (tier 7) still fits through
        {"from": [-50, 40], "to": [50, 40], "doors": [[50.0, 22.0]], "break_tier": 8},
        {"from": [-50, -40], "to": [50, -40], "doors": [[50.0, 22.0]], "break_tier": 8},
        {"from": [-50, -40], "to": [-50, 40], "doors": [], "break_tier": 8},
        {"from": [50, -40], "to": [50, 40], "doors": [], "break_tier": 8},
        # block wall around the lot: gates at the front and the side (tier 6)
        {"from": [-70, -65], "to": [110, -65], "doors": [[70.0, 18.0]], "fence": True, "style": "block", "h": 5.0, "break_tier": 7},
        {"from": [110, -65], "to": [110, 115], "doors": [[85.0, 18.0]], "fence": True, "style": "block", "h": 5.0, "break_tier": 7},
        {"from": [-70, 115], "to": [110, 115], "doors": [], "fence": True, "style": "block", "h": 5.0, "break_tier": 7},
        {"from": [-70, -65], "to": [-70, 115], "doors": [], "fence": True, "style": "block", "h": 5.0, "break_tier": 7},
    ],
    "platforms": [], "ramps": [],
    "rugs": [], "layout": [], "on_top": [], "clutter": [],
    "zones": [
        {   # ---- the kid's room (start)
            "name": "Kid's Room", "rect": [-18, -14, 18, 14], "spawn_tier": 0,
            "rugs": [rug("rugSquare", 0, 0, 12, 12)],
            "layout": [
                fur("bedSingle", 4, 4.0, 110, -16, -4, 0, id="kbed"),
                fur("desk", 4, 3.6, 110, 12, 10, 180, id="kdesk"),
                fur("chairDesk", 3, 3.4, 70, 10, 5, 0),
                fur("bookcaseClosed", 4, 6.0, 120, 16.4, -6, -90),
                toy("dollhouse", 3, 3.0, 70, 6, -10, 20),
                # toy boxes in both doorways (gone at tier 2)
                # (model origins are at a corner: these centre on z -2, 0, 2)
                fur("cardboardBoxClosed", 2, 2.4, 40, -18.9, -1.1, 0),
                fur("cardboardBoxClosed", 2, 2.4, 40, -18.9, 0.9, 0),
                fur("cardboardBoxClosed", 2, 2.4, 40, -18.9, 2.9, 0),
                fur("cardboardBoxClosed", 2, 2.4, 40, 17.1, -1.1, 0),
                fur("cardboardBoxClosed", 2, 2.4, 40, 17.1, 0.9, 0),
                fur("cardboardBoxClosed", 2, 2.4, 40, 17.1, 2.9, 0),
            ],
            "on_top": [on("kbed", "teddy", 1), on("kbed", "cushion", 1), on("kdesk", "crayon", 3), on("kdesk", "pencil", 2),
                       on("kdesk", "eraser", 1), on("kdesk", "globe", 1)],
            "clutter": [
                items("candy", 8, rect=[-16, -12, 16, 12], sep=1.0), items("coin", 6, rect=[-16, -12, 16, 12], sep=1.0),
                items("marble", 6, rect=[-16, -12, 16, 12], sep=1.0), items("button", 5, rect=[-16, -12, 16, 12], sep=1.0),
                items("crayon", 6, rect=[-16, -12, 16, 12], sep=1.0), items("die", 5, rect=[-16, -12, 16, 12], sep=1.0),
                items("eraser", 3, rect=[-16, -12, 16, 12], sep=1.0), items("block", 10, rect=[-16, -12, 16, 12], sep=1.0),
                items("paper", 4, rect=[-16, -12, 16, 12], sep=1.0), items("slipper", 2, rect=[-16, -12, 16, 12]),
                items("duck", 4, rect=[-16, -12, 16, 12]), items("car", 5, rect=[-16, -12, 16, 12]),
                items("ball", 3, rect=[-16, -12, 16, 12]), items("skateboard", 2, rect=[-16, -12, 16, 12]),
                items("cushion", 2, rect=[-16, -12, 16, 12]), items("piggy", 1, rect=[-16, -12, 16, 12]),
                items("robot", 1, rect=[-16, -12, 16, 12]), items("drum", 1, rect=[-16, -12, 16, 12]),
                items("beachball", 1, rect=[-16, -12, 16, 12]),
            ],
        },
        {   # ---- the rest of the house
            "name": "The House", "sub": "Kitchen and living room", "rect": [-50, -40, 50, 40], "spawn_tier": 1,
            "rugs": [rug("rugRectangle", 34, 0, 18, 12), rug("rugRectangle", 0, -27, 14, 8)],
            "layout": [
                # kitchen (west)
                kitchen("kitchenFridge", -47.5, 34, 90),
                kitchen("kitchenCabinet", -47.5, 27, 90, id="c1"),
                kitchen("kitchenStove", -47.5, 22, 90, id="c2"),
                kitchen("kitchenSink", -47.5, 17, 90, id="c3"),
                kitchen("kitchenCabinet", -47.5, 12, 90, id="c4"),
                fur("table", 5, 5.0, 230, -40, -20, id="table"),
                fur("chair", 5, 7.0, 220, -32, -14, 180),
                fur("stoolBar", 4, 4.5, 110, -30, 28), fur("stoolBar", 4, 4.5, 110, -30, 22),
                fur("trashcan", 3, 3.6, 60, -24, 36),
                # living room (east)
                fur("loungeSofaLong", 5, 6.0, 250, 46, -8, -90),
                fur("tableCoffee", 3, 2.5, 65, 32, -4, 90, id="coffee"),
                fur("cabinetTelevision", 4, 3.0, 120, 26, -20, 90, id="tv"),
                fur("loungeChair", 5, 6.0, 200, 34, 22, 180),
                fur("loungeChair", 5, 6.0, 200, 34, -26, 0),
                fur("bookcaseClosed", 6, 10.0, 500, 48.4, 28, -90),
                fur("lampRoundFloor", 3, 6.0, 60, 46, -34),
                fur("pottedPlant", 4, 5.0, 100, 22, 36),
                fur("speaker", 3, 3.8, 65, 26, -30), fur("speaker", 3, 3.8, 65, 26, -12),
                # hall (north) and entrance (south)
                fur("coatRack", 3, 6.0, 70, -14, 36),
                fur("bookcaseClosed", 6, 10.0, 500, 36, 38.4, 180),
                fur("sideTableDrawers", 3, 3.4, 70, 12, -37, 0, id="side"),
                fur("pottedPlant", 4, 5.0, 100, -14, -36),
                # moving boxes in the patio and front doors (gone at tier 4)
                # (6 boxes across each 22-wide doorway; origins are at a corner)
                fur("cardboardBoxClosed", 4, 4.5, 90, -10.9, 41.7, 0),
                fur("cardboardBoxClosed", 4, 4.5, 90, -7.2, 41.7, 0),
                fur("cardboardBoxClosed", 4, 4.5, 90, -3.5, 41.7, 0),
                fur("cardboardBoxClosed", 4, 4.5, 90, 0.2, 41.7, 0),
                fur("cardboardBoxClosed", 4, 4.5, 90, 3.9, 41.7, 0),
                fur("cardboardBoxClosed", 4, 4.5, 90, 7.6, 41.7, 0),
                fur("cardboardBoxClosed", 4, 4.5, 90, -10.9, -38.3, 0),
                fur("cardboardBoxClosed", 4, 4.5, 90, -7.2, -38.3, 0),
                fur("cardboardBoxClosed", 4, 4.5, 90, -3.5, -38.3, 0),
                fur("cardboardBoxClosed", 4, 4.5, 90, 0.2, -38.3, 0),
                fur("cardboardBoxClosed", 4, 4.5, 90, 3.9, -38.3, 0),
                fur("cardboardBoxClosed", 4, 4.5, 90, 7.6, -38.3, 0),
            ],
            "on_top": [
                on("c1", "microwave", 1), on("c2", "mug", 2), on("c3", "glass", 2), on("c4", "toaster", 1),
                on("c1", "cup", 1), on("c4", "coffee", 1), on("table", "apple", 2), on("table", "donut", 2),
                on("table", "ketchup", 1), on("coffee", "remote", 1), on("coffee", "mug", 1), on("tv", "tv", 1),
                on("side", "phone", 1), on("side", "plant_s", 1),
            ],
            "clutter": [
                items("apple", 5, rect=[-46, -36, -20, 36]), items("orange", 4, rect=[-46, -36, -20, 36]),
                items("can", 5, rect=[-46, -36, -20, 36]), items("bottle", 3, rect=[-46, -36, -20, 36]),
                items("carton", 3, rect=[-46, -36, -20, 36]), items("mug", 3, rect=[-46, -36, -20, 36]),
                items("ketchup", 2, rect=[-46, -36, -20, 36]), items("basket", 2, rect=[-46, -36, -20, 36]),
                items("cushion", 4, rect=[20, -36, 46, 36]), items("remote", 2, rect=[20, -36, 46, 36]),
                items("books", 5, rect=[20, -36, 46, 36]), items("phone", 2, rect=[20, -36, 46, 36]),
                items("basketball", 1, rect=[20, -36, 46, 36]), items("suitcase", 2, rect=[-16, -38, 16, -16]),
                items("slipper", 4, rect=[-16, -38, 16, -16]), items("tissue", 2, rect=[20, -36, 46, 36]),
                items("box_s", 2, rect=[-16, 16, 16, 38]), items("fan", 1, rect=[20, -36, 46, 36]),
                items("radio", 1, rect=[20, -36, 46, 36]), items("plant", 2, rect=[-16, 16, 16, 38]),
                items("candy", 6, rect=[-46, -38, 46, 38]), items("paper", 6, rect=[-46, -38, 46, 38]),
            ],
        },
        {   # ---- the garden (the house's own lot)
            "name": "The Garden", "sub": "Out into the open air!", "rect": YARD, "spawn_tier": 3,
            "layout": [
                fur("table", 5, 5.0, 230, 12, 53, id="picnic"),
                toy("grill", 3, 3.6, 70, -12, 50), toy("parasol", 4, 6.0, 110, -20, 46, solid=[0.12, 0.12]),
                toy("pool", 4, 1.3, 100, 40, 72), toy("doghouse", 4, 4.5, 120, 80, -12, -60),
                toy("shed", 6, 11.0, 500, -48, 100, 180), toy("bench", 4, 3.0, 110, 92, 96, 200),
                toy("bench", 4, 3.0, 110, -60, 60, 90),
                toy("lamppost", 5, 9.0, 200, -12, -54, solid=[0.3, 0.3]), toy("lamppost", 5, 9.0, 200, 12, -54, solid=[0.3, 0.3]),
                toy("sedan", 6, 5.0, 300, 32, -53, 90),
                tree(-58, -52), tree(30, 104), tree(96, 78), tree(96, -48), tree(-12, 106, "pine"),
                tree(70, 46, "pine"), tree(-60, 20, "pine"), tree(62, 100), tree(-60, 82),
                # gates in the block wall (gone at tier 6)
                toy("gate", 6, 5.0, 300, 0, -65, 0), toy("gate", 6, 5.0, 300, 110, 20, 90),
            ],
            "on_top": [on("picnic", "can", 2), on("picnic", "apple", 2), on("picnic", "cup", 2), on("picnic", "bottle", 1)],
            "clutter": [
                items("flower", 12, rect=[-39, 93, -7, 103], sep=1.6), items("flower", 6, rect=[-68, -60, -54, -44], sep=1.6),
                items("gnome", 3, rect=[-39, 93, -7, 103], sep=2.4), items("wateringcan", 1, rect=[61, -34, 99, -26], sep=2.4),
                items("orange", 5, rect=[61, -34, 99, -26], sep=1.4), items("apple", 4, rect=[61, -34, 99, -26], sep=1.4),
                items("bucket", 3, rect=[61, 11, 89, 33], sep=2.0), items("block", 4, rect=[61, 11, 89, 33], sep=1.4),
                items("car", 2, rect=[61, 11, 89, 33], sep=1.8), items("beachball", 1, rect=[61, 11, 89, 33], sep=3.0),
                items("flamingo", 4, rect=[-68, 58, 108, 112]), items("bush", 8, rect=[-68, -63, 108, 113], sep=5.0),
                items("bush_s", 8, rect=[-68, -63, 108, 113], sep=3.5), items("rock_l", 4, rect=[-68, 58, 108, 113]),
                items("hose", 2, rect=[-40, 58, 40, 80]), items("ball", 3, rect=[-68, 58, 108, 113]),
                items("basketball", 1, rect=[52, -63, 108, 40]), items("skateboard", 2, rect=[-68, -63, 48, -42]),
                items("acorn", 6, rect=[-68, -63, -52, 113]), items("mushroom", 5, rect=[-68, -63, -52, 113]),
                items("rock", 6, rect=[-68, -63, 108, 113]), items("flower", 6, rect=[52, -63, 108, 113]),
                items("gnome", 2, rect=[-68, -63, 48, -42]),
            ],
        },
        {   # ---- the town around the house
            "name": "The Neighborhood", "sub": "Cars, houses... everything!", "rect": [-300, -260, 300, 260], "spawn_tier": 5,
            "layout": town_layout,
            "clutter": [
                items("cone_b", 6, rect=[-120, -100, 120, -60], sep=6.0),
                items("hydrant_b", 6, rect=[-290, -250, 290, 250], sep=10.0),
                items("mailbox_b", 8, rect=[-290, -250, 290, 250], sep=10.0),
                items("bike_b", 5, rect=[-290, -250, 290, 250], sep=10.0),
            ],
        },
    ],
})

# ---------------------------------------------------------------- 1 Playroom
STAGES.append({
    "name": "Playroom",
    "hx": 24.0, "hz": 20.0,
    "time": 60.0,
    "wall": C("eaf1fb"), "stripe": C("d6e4f6"), "inner_wall": C("e3ecf8"),
    "rugs": [rug("rugSquare", 0, 0, 14, 14), rug("rugRectangle", 2, -11, 14, 8)],
    "platforms": [
        {"box": [-12, 10, 16, 9, 2.5], "color": C("7fb2e5")},   # toy stage
    ],
    "ramps": [
        {"from": [4, 10, 0.0], "to": [-4, 10, 2.5], "w": 4.0, "color": C("f2b33d")},
    ],
    "layout": [
        fur("bedSingle", 5, 3.5, 300, 16, 7, id="bed"),
        fur("bookcaseClosed", 5, 8.0, 260, -21, -2, 90),
        fur("bookcaseClosed", 5, 8.0, 260, -21, -10, 90),
        fur("cardboardBoxClosed", 3, 3.5, 70, 18, -14, 15),
        fur("cardboardBoxClosed", 3, 3.5, 70, 12, -16, -10),
        fur("loungeChair", 4, 4.5, 110, -14, -13, 30),
        fur("sideTable", 3, 3.2, 60, 20, -4, -90, id="side"),
        fur("tableCoffee", 3, 2.5, 65, 2, -11, id="kidtable"),
        fur("chair", 3, 3.5, 50, -4, -11, 90),
        fur("chair", 3, 3.5, 50, 8, -11, -90),
        fur("pottedPlant", 4, 5.0, 100, 21, 17),
        fur("lampRoundFloor", 3, 6.0, 60, 6, 17),
    ],
    "on_top": [
        on("bed", "cushion", 2), on("bed", "teddy", 1), on("bed", "books", 1), on("bed", "duck", 1),
        on("side", "plant_s", 1), on("side", "books", 1),
        on("kidtable", "block", 3), on("kidtable", "apple", 1),
    ],
    "clutter": [
        # on the toy stage
        items("block", 6, y=2.5, rect=[-19, 6.5, -5, 13.5], sep=1.6),
        items("duck", 2, y=2.5, rect=[-19, 6.5, -5, 13.5], sep=1.6),
        items("car", 2, y=2.5, rect=[-19, 6.5, -5, 13.5], sep=1.6),
        items("robot", 1, y=2.5, rect=[-19, 6.5, -5, 13.5], sep=2.5),
        items("drum", 1, y=2.5, rect=[-19, 6.5, -5, 13.5], sep=2.5),
        # floor
        items("block", 10), items("candy", 8), items("duck", 3), items("car", 4),
        items("ball", 3), items("books", 3), items("basket", 2), items("beachball", 1, sep=3.0),
        items("dollhouse", 1, sep=4.0), items("teddy", 1, sep=3.0),
    ],
})

# ---------------------------------------------------------------- 2 Kitchen
counter_z = 21.5
counter = [kitchen("kitchenFridge", -26.0, counter_z, id="fridge"),
           kitchen("kitchenStove", -21.7, counter_z, id="stove"),
           kitchen("kitchenSink", -17.4, counter_z, id="sink")]
for i, x in enumerate([-13.1, -8.8, -4.5, -0.2, 4.1]):
    counter.append(kitchen("kitchenCabinet", x, counter_z, id="c%d" % (i + 1)))
STAGES.append({
    "name": "Kitchen",
    "hx": 30.0, "hz": 24.0,
    "time": 100.0,
    "wall": C("eef3e2"), "stripe": C("dde8cc"), "inner_wall": C("e6ecd6"),
    "rugs": [rug("rugRectangle", 12, 2, 18, 12)],
    "walls": [
        {"from": [12, -24], "to": [12, -10], "doors": []},
        {"from": [12, -10], "to": [30, -10], "doors": [[9.0, 12.0]]},
    ],
    "platforms": [
        {"box": [-10, 6, 14, 6, 4.5], "color": C("b9875a")},    # kitchen island
    ],
    "ramps": [
        # cutting-board ramp up onto the counter run from the east
        {"from": [17.5, counter_z, 0.0], "to": [6.2, counter_z, 4.5], "w": 3.4, "color": C("d9a865")},
    ],
    "layout": counter + [
        fur("stoolBar", 4, 4.5, 110, -14, -0.5),
        fur("stoolBar", 4, 4.5, 110, -10, -0.5),
        fur("stoolBar", 4, 4.5, 110, -6, -0.5),
        fur("table", 5, 5.0, 230, 12, 2, id="dining"),
        fur("chair", 5, 7.0, 220, 12, -3.5, 0),
        fur("chair", 5, 7.0, 220, 12, 7.5, 180),
        fur("chair", 5, 7.0, 220, 4.0, 2, 90),
        fur("chair", 5, 7.0, 220, 20.0, 2, -90),
        fur("trashcan", 3, 3.6, 60, 24, 20),
        fur("pottedPlant", 4, 5.0, 100, -27, -21),
        fur("plantSmall1", 2, 2.4, 40, 8, -21),
        # pantry
        fur("cardboardBoxClosed", 5, 5.0, 180, 27, -21, 10),
        fur("cardboardBoxClosed", 5, 5.0, 180, 27, -14, -15),
        fur("cardboardBoxClosed", 4, 3.5, 90, 16, -21, 30),
    ],
    "on_top": [
        on("c1", "microwave", 1), on("c3", "coffee", 1), on("c5", "toaster", 1), on("c4", "blender", 1),
        on("c1", "cup", 1), on("c2", "mug", 2), on("c2", "apple", 2), on("c3", "glass", 1),
        on("c4", "orange", 2), on("c5", "donut", 2), on("sink", "glass", 1), on("stove", "ketchup", 1),
        on("fridge", "carton", 1), on("fridge", "bottle", 1),
        on("dining", "mug", 2), on("dining", "cup", 2), on("dining", "apple", 2), on("dining", "donut", 2),
        on("dining", "ketchup", 1),
    ],
    "clutter": [
        # on the island
        items("apple", 3, y=4.5, rect=[-16, 3.6, -4, 8.4], sep=1.4),
        items("orange", 3, y=4.5, rect=[-16, 3.6, -4, 8.4], sep=1.4),
        items("cup", 2, y=4.5, rect=[-16, 3.6, -4, 8.4], sep=1.4),
        items("bottle", 1, y=4.5, rect=[-16, 3.6, -4, 8.4], sep=2.0),
        # pantry
        items("carton", 4, rect=[14, -23, 29, -11], sep=1.8),
        items("bottle", 4, rect=[14, -23, 29, -11], sep=1.8),
        items("can", 6, rect=[14, -23, 29, -11], sep=1.5),
        items("ketchup", 3, rect=[14, -23, 29, -11], sep=1.8),
        # kitchen floor
        items("mug", 4, rect=[-28, -22, 10, 18]), items("cup", 4, rect=[-28, -22, 10, 18]),
        items("glass", 3, rect=[-28, -22, 10, 18]), items("can", 4, rect=[-28, -22, 10, 18]),
        items("apple", 5), items("orange", 4), items("candy", 6), items("donut", 4),
        items("basket", 2, rect=[-28, -22, 10, 18]),
    ],
})

# ---------------------------------------------------------------- 3 House
STAGES.append({
    "name": "House",
    "hx": 40.0, "hz": 30.0,
    "time": 120.0,
    "wall": C("f6ead6"), "stripe": C("ecd9bb"), "inner_wall": C("efe2cc"),
    "rugs": [rug("rugRectangle", -20, -4, 20, 14), rug("rugSquare", 24, 14, 12, 12),
             rug("rugRectangle", 24, -14, 14, 9)],
    "walls": [
        # living | right wing, with two wide doorways
        {"from": [8, -30], "to": [8, 30], "doors": [[14.0, 13.0], [46.0, 13.0]]},
        # bedroom (north) | study (south)
        {"from": [8, 0], "to": [40, 0], "doors": [[16.0, 13.0]]},
    ],
    "platforms": [
        {"box": [-21, 25.5, 34, 9, 6.0], "color": C("9c6b45")},   # living-room loft (to the wall)
    ],
    "ramps": [
        # runs north from the middle of the living room up onto the loft
        {"from": [-7, 6, 0.0], "to": [-7, 20.9, 6.0], "w": 4.0, "color": C("d9a865")},
    ],
    "layout": [
        # living room
        fur("loungeSofaLong", 5, 6.0, 250, -33, -4, 90),
        fur("tableCoffee", 3, 2.5, 65, -22, -4, 90, id="coffee"),
        fur("cabinetTelevision", 4, 3.0, 120, -10, -4, -90, id="tvstand"),
        fur("loungeChair", 5, 6.0, 200, -22, -18, 0),
        fur("loungeChair", 5, 6.0, 200, -22, 10, 180),
        fur("lampRoundFloor", 3, 6.0, 60, -38, -27),
        fur("pottedPlant", 4, 5.0, 100, -38, 15),
        fur("speaker", 3, 3.8, 65, -10, -12),
        fur("speaker", 3, 3.8, 65, -12, 4),
        # loft (on the platform)
        # (small things only: up here the truck is still small, it came by the ramp)
        fur("cardboardBoxClosed", 3, 3.2, 70, -34, 27.5, 10, y=6.0),
        fur("cardboardBoxClosed", 3, 3.2, 70, -29, 28.0, -15, y=6.0),
        fur("pottedPlant", 3, 4.0, 70, -16, 27.5, 0, y=6.0),
        # bedroom
        fur("bedDouble", 6, 4.8, 450, 24, 21, 0, id="bed"),
        fur("sideTableDrawers", 4, 4.0, 120, 13, 26, 0, id="night"),
        fur("bookcaseClosed", 6, 10.0, 500, 38.4, 24, -90),
        fur("loungeSofa", 5, 5.5, 220, 37, 11, -90),
        # study
        fur("desk", 5, 4.5, 230, 25, -24, 0, id="desk"),
        fur("chairDesk", 4, 4.5, 110, 25, -17, 180),
        fur("bookcaseClosed", 6, 10.0, 500, 38.4, -12, -90),
        fur("bookcaseClosed", 6, 10.0, 500, 38.4, -22, -90),
        fur("cardboardBoxClosed", 5, 5.0, 180, 12, -26, 15),
        fur("cardboardBoxClosed", 4, 3.5, 90, 16.5, -27, -10),
        fur("trashcan", 3, 3.6, 60, 34, -4),
        fur("plantSmall1", 2, 2.4, 40, 12, -4),
    ],
    "on_top": [
        on("coffee", "remote", 1), on("coffee", "mug", 1), on("coffee", "books", 1), on("coffee", "candy", 2),
        on("tvstand", "tv", 1),
        on("bed", "cushion", 2), on("bed", "teddy", 1), on("bed", "books", 1), on("bed", "phone", 1),
        on("night", "glass", 1), on("night", "books", 1),
        on("desk", "screen", 1), on("desk", "mouse", 1), on("desk", "mug", 1), on("desk", "cactus", 1),
    ],
    "clutter": [
        # loft
        items("books", 4, y=6.0, rect=[-36, 22, -10, 27], sep=1.8),
        items("teddy", 1, y=6.0, rect=[-36, 22, -10, 27], sep=2.6),
        items("robot", 1, y=6.0, rect=[-36, 22, -10, 27], sep=2.6),
        items("globe", 1, y=6.0, rect=[-36, 22, -10, 27], sep=2.6),
        items("block", 5, y=6.0, rect=[-36, 22, -10, 27], sep=1.4),
        items("ball", 2, y=6.0, rect=[-36, 22, -10, 27], sep=1.8),
        # living room floor
        items("block", 6, rect=[-38, -28, 6, 20]), items("car", 4, rect=[-38, -28, 6, 20]),
        items("duck", 3, rect=[-38, -28, 6, 20]), items("ball", 2, rect=[-38, -28, 6, 20]),
        items("cushion", 3, rect=[-38, -28, 6, 20], sep=3.0), items("paper", 6, rect=[-38, -28, 6, 20]),
        items("books", 3, rect=[-38, -28, 6, 20]), items("remote", 2, rect=[-38, -28, 6, 20]),
        # bedroom
        items("slipper", 4, rect=[10, 2, 38, 28]), items("cushion", 2, rect=[10, 2, 38, 28], sep=3.0),
        items("ball", 2, rect=[10, 2, 38, 28]), items("basketball", 1, rect=[10, 2, 38, 28], sep=3.0),
        items("piggy", 1, rect=[10, 2, 38, 28]), items("books", 3, rect=[10, 2, 38, 28]),
        items("tissue", 1, rect=[10, 2, 38, 28]), items("suitcase", 1, rect=[10, 2, 38, 28], sep=3.0),
        # study
        items("paper", 8, rect=[10, -28, 36, -2]), items("books", 4, rect=[10, -28, 36, -2]),
        items("mouse", 2, rect=[10, -28, 36, -2]), items("mug", 2, rect=[10, -28, 36, -2]),
        items("can", 2, rect=[10, -28, 36, -2]), items("tissue", 2, rect=[10, -28, 36, -2]),
        items("globe", 1, rect=[10, -28, 36, -2], sep=3.0), items("basket", 1, rect=[10, -28, 36, -2]),
    ],
})

# ---------------------------------------------------------------- 4 Office
desks, desk_tops = [], []
n = 0
for x in (-16, 0, 16):
    for z, chair_z, rot in ((8, 14, 180), (-8, -14, 0)):
        n += 1
        desks.append(fur("desk", 5, 4.5, 230, x, z, 0, id="d%d" % n))
        desks.append(fur("chairDesk", 4, 4.5, 110, x, chair_z, rot))
        desk_tops += [on("d%d" % n, "screen", 1), on("d%d" % n, "mouse", 1),
                      on("d%d" % n, ("mug", "cup", "can")[n % 3], 1), on("d%d" % n, "books", 1)]
STAGES.append({
    "name": "Office",
    "hx": 50.0, "hz": 36.0,
    "time": 170.0,
    "wall": C("e3ebf3"), "stripe": C("cfdbe8"), "inner_wall": C("dbe5ef"),
    "rugs": [rug("rugRectangle", -38, -4, 18, 14, 90), rug("rugRectangle", 36, 24, 20, 12)],
    "walls": [
        # meeting room (NE)
        {"from": [22, 12], "to": [22, 36], "doors": [[10.0, 13.0]]},
        {"from": [22, 12], "to": [50, 12], "doors": [[16.0, 13.0]]},
        # break room (NW)
        {"from": [-24, 12], "to": [-24, 36], "doors": [[10.0, 13.0]]},
        {"from": [-50, 12], "to": [-24, 12], "doors": [[13.0, 13.0]]},
        # storage (SE)
        {"from": [26, -16], "to": [50, -16], "doors": [[12.0, 13.0]]},
        {"from": [26, -36], "to": [26, -16], "doors": [[10.0, 13.0]]},
    ],
    "platforms": [
        {"box": [-30, -30.5, 36, 11, 6.0], "color": C("8a95a3")},   # mezzanine (to the wall)
    ],
    "ramps": [
        {"from": [4, -30, 0.0], "to": [-12.1, -30, 6.0], "w": 4.0, "color": C("b8c2cc")},
    ],
    "layout": desks + [
        # break room
        kitchen("kitchenFridge", -48.4, 26, 90),
        kitchen("kitchenCabinet", -44, 33.6, 0, id="b1"),
        kitchen("kitchenCabinet", -39.7, 33.6, 0, id="b2"),
        kitchen("kitchenSink", -35.4, 33.6, 0),
        fur("table", 5, 5.0, 230, -37, 21, 0, id="breaktable"),
        fur("chair", 5, 7.0, 220, -41, 15, 0), fur("chair", 5, 7.0, 220, -33, 15, 0),
        # meeting room
        fur("table", 5, 5.0, 230, 36, 24, 0, id="meeting"),
        fur("chair", 5, 7.0, 220, 31, 18.5, 0), fur("chair", 5, 7.0, 220, 36, 18.5, 0),
        fur("chair", 5, 7.0, 220, 41, 18.5, 0), fur("chair", 5, 7.0, 220, 31, 29.5, 180),
        fur("chair", 5, 7.0, 220, 36, 29.5, 180), fur("chair", 5, 7.0, 220, 41, 29.5, 180),
        fur("cabinetTelevision", 4, 3.0, 120, 48.6, 24, -90, id="meettv"),
        fur("pottedPlant", 4, 5.0, 100, 47, 34),
        # lounge (W)
        fur("loungeSofaLong", 5, 6.0, 250, -44, -4, 90),
        fur("tableCoffee", 3, 2.5, 65, -34, -4, 90, id="lounge"),
        fur("loungeChair", 5, 6.0, 200, -32, 6, 180),
        fur("pottedPlant", 4, 5.0, 100, -48, 9),
        # storage (SE)
        fur("cardboardBoxClosed", 5, 5.0, 180, 31, -32, 10), fur("cardboardBoxClosed", 5, 5.0, 180, 37, -32, -5),
        fur("cardboardBoxClosed", 5, 5.0, 180, 43, -32, 20), fur("cardboardBoxClosed", 5, 5.0, 180, 46, -24, -15),
        fur("trashcan", 3, 3.6, 60, 30, -20), fur("speaker", 3, 3.8, 65, 47, -19),
        # mezzanine
        fur("cardboardBoxClosed", 3, 3.2, 70, -44, -32, 10, y=6.0),
        fur("cardboardBoxClosed", 3, 3.2, 70, -39, -32.5, -20, y=6.0),
        fur("cardboardBoxClosed", 3, 3.2, 70, -24, -33, 25, y=6.0),
        # open area dressing
        fur("pottedPlant", 4, 5.0, 100, -20, 20), fur("pottedPlant", 4, 5.0, 100, 18, -22),
        fur("coatRack", 3, 8.0, 60, 4, -34),
        fur("trashcan", 3, 3.6, 60, 8, 20),
    ],
    "on_top": desk_tops + [
        on("b1", "coffee", 1), on("b2", "microwave", 1),
        on("breaktable", "mug", 2), on("breaktable", "donut", 2), on("breaktable", "cup", 1),
        on("meeting", "cup", 3), on("meeting", "mug", 2), on("meeting", "books", 2), on("meeting", "phone", 1),
        on("meettv", "tv", 1),
        on("lounge", "books", 1), on("lounge", "cup", 1),
    ],
    "clutter": [
        # mezzanine
        items("books", 4, y=6.0, rect=[-46, -34, -14, -26], sep=1.8),
        items("plant", 2, y=6.0, rect=[-46, -34, -14, -26], sep=2.4),
        items("basket", 2, y=6.0, rect=[-46, -34, -14, -26], sep=2.4),
        items("globe", 1, y=6.0, rect=[-46, -34, -14, -26], sep=2.6),
        items("fan", 1, y=6.0, rect=[-46, -34, -14, -26], sep=3.0),
        # storage
        items("box_s", 3, rect=[28, -34, 48, -18], sep=4.0), items("radio", 1, rect=[28, -34, 48, -18], sep=3.0),
        items("suitcase", 2, rect=[28, -34, 48, -18], sep=3.0), items("carton", 3, rect=[28, -34, 48, -18]),
        # break room
        items("can", 4, rect=[-48, 14, -26, 34]), items("cup", 3, rect=[-48, 14, -26, 34]),
        items("apple", 3, rect=[-48, 14, -26, 34]),
        # open area
        items("paper", 14, rect=[-22, -22, 22, 22]), items("mug", 4, rect=[-22, -22, 22, 22]),
        items("cup", 4, rect=[-22, -22, 22, 22]), items("can", 4, rect=[-22, -22, 22, 22]),
        items("books", 4, rect=[-22, -22, 22, 22]), items("tissue", 3, rect=[-22, -22, 22, 22]),
        items("mouse", 3, rect=[-22, -22, 22, 22]), items("cactus", 3, rect=[-22, -22, 22, 22]),
        items("basket", 2, rect=[-22, -22, 22, 22]), items("phone", 2, rect=[-22, -22, 22, 22]),
    ],
})

# ---------------------------------------------------------------- 5 Backyard
# Starts inside a house in the middle of the yard. Ways out:
#  - a pet flap in the kitchen (only while the truck is tiny),
#  - the patio door, blocked by moving boxes (tier 3),
#  - the front door, blocked by bigger boxes (tier 4).
# Outside: patio with a picnic table, flower beds, a sand pit, a play fort
# with a slide, an orchard, the front yard with a parked truck.
HW = [-26, -22, 26, 22]   # house rectangle
STAGES.append({
    "name": "Backyard",
    "hx": 72.0, "hz": 58.0,
    "time": 180.0,
    "outdoor": True,
    "fence": C("f4ead8"),
    "inner_wall": C("f1e4cf"), "wall": C("f1e4cf"), "stripe": C("e6d6bc"),
    "tier_fractions": [0.06, 0.15, 0.22, 0.45, 0.55, 0.55],
    "floors": [
        {"rect": HW, "kind": "planks"},
        {"rect": [-26, -22, -6, 22], "color": C("cfd6d2")},              # kitchen tiles
        {"rect": [0, 22, 26, 34], "kind": "planks", "a": C("b98a5e"), "b": C("a07550")},  # patio deck
        {"rect": [6, -58, 18, -22], "color": C("a89c86")},              # front path
        {"rect": [34, -58, 50, -14], "color": C("7f7c78")},             # driveway
        {"rect": [38, 2, 58, 18], "color": C("d9b46a")},                # sand pit
        {"rect": [-60, 30, -34, 40], "color": C("8a6a4a")},             # flower bed
        {"rect": [-20, 44, 0, 52], "color": C("8a6a4a")},               # flower bed
        {"rect": [40, -6, 66, -2], "color": C("8a6a4a")},               # veggie bed
    ],
    "rugs": [rug("rugRectangle", 10, 2, 16, 10)],
    "walls": [
        # house shell (fades like any interior wall when it hides the truck)
        {"from": [-26, 22], "to": [26, 22], "doors": [[12.0, 3.2, 1.9], [36.0, 12.0]]},
        {"from": [-26, -22], "to": [26, -22], "doors": [[38.0, 12.0]]},
        {"from": [-26, -22], "to": [-26, 22], "doors": []},
        {"from": [26, -22], "to": [26, 22], "doors": []},
        # kitchen | living room
        {"from": [-6, -22], "to": [-6, 22], "doors": [[22.0, 13.0]]},
    ],
    "platforms": [
        {"box": [54, 44, 16, 10, 4.5], "color": C("c98a4b")},          # play fort
    ],
    "ramps": [
        # the slide, down the fort's south side
        {"from": [54, 26.5, 0.0], "to": [54, 39.1, 4.5], "w": 4.0, "color": C("e8576d")},
    ],
    "layout": [
        # living room (start)
        fur("loungeSofa", 5, 5.5, 220, 18, -14, 0),
        fur("tableCoffee", 3, 2.5, 65, 14, -4, 0, id="coffee"),
        fur("cabinetTelevision", 4, 3.0, 120, -3, -12, 90, id="tvstand"),
        fur("loungeChair", 5, 6.0, 200, 22, 4, -90),
        fur("bookcaseClosed", 6, 10.0, 500, 24.4, -6, -90),
        fur("lampRoundFloor", 3, 6.0, 60, 23, 18),
        fur("pottedPlant", 4, 5.0, 100, -2, -19),
        fur("speaker", 3, 3.8, 65, 4, -19),
        # kitchen
        kitchen("kitchenFridge", -23.5, 18, 90),
        kitchen("kitchenCabinet", -23.5, 12, 90, id="k1"),
        kitchen("kitchenStove", -23.5, 7.5, 90, id="k2"),
        kitchen("kitchenSink", -23.5, 3, 90, id="k3"),
        kitchen("kitchenCabinet", -23.5, -1.5, 90, id="k4"),
        fur("table", 5, 5.0, 230, -20, -16, id="ktable"),
        fur("chair", 5, 7.0, 220, -12, -10, 180),
        fur("trashcan", 3, 3.6, 60, -9, 19),
        # patio door: moving boxes (gone at tier 3)
        fur("cardboardBoxClosed", 3, 3.2, 70, 5.4, 22, 5),
        fur("cardboardBoxClosed", 3, 3.2, 70, 8.4, 22, -8),
        fur("cardboardBoxClosed", 3, 3.2, 70, 11.4, 22, 4),
        fur("cardboardBoxClosed", 3, 3.2, 70, 14.4, 22, -6),
        # front door: bigger boxes (gone at tier 4)
        fur("cardboardBoxClosed", 4, 4.5, 90, 7.6, -22, 6),
        fur("cardboardBoxClosed", 4, 4.5, 90, 12.0, -22, -5),
        fur("cardboardBoxClosed", 4, 4.5, 90, 16.4, -22, 3),
        # patio
        fur("table", 5, 5.0, 230, 8, 28, id="picnic"),
        toy("grill", 3, 3.6, 70, 3, 31),
        toy("parasol", 4, 6.0, 110, 22, 30, solid=[0.12, 0.12]),
        toy("pool", 4, 1.3, 100, -10, 34),
        # back yard
        toy("shed", 6, 11.0, 500, -62, 50, 180),
        toy("doghouse", 4, 4.5, 120, 30, 46, -30),
        toy("bench", 4, 3.0, 110, -30, 48, 180),
        tree(-46, 50), tree(-8, 50, "pine"), tree(26, 52), tree(66, 30, "pine"),
        tree(36, 34), tree(-40, 26, "pine"),
        # side yards
        tree(-56, 8), tree(-62, -14), tree(-44, -6, "pine"), tree(-58, -36),
        tree(64, -30, "pine"), tree(62, 10),
        toy("lamppost", 5, 9.0, 200, -36, -28, solid=[0.3, 0.3]),
        toy("lamppost", 5, 9.0, 200, 30, -52, solid=[0.3, 0.3]),
        toy("bench", 4, 3.0, 110, -48, -46),
        # front yard
        fur("trashcan", 3, 3.6, 60, 30, -24), fur("trashcan", 3, 3.6, 60, 30, -20),
        toy("mailbox", 3, 4.0, 70, 22, -54),
        toy("hydrant", 3, 3.0, 60, 0, -54),
        {"p": "res://models/vehicle-truck-yellow.glb", "col": C("3fa7c9"), "t": 6, "h": 6.5,
         "s": 500, "x": 42, "z": -40, "rot": 0},
    ],
    "on_top": [
        on("coffee", "remote", 1), on("coffee", "mug", 1), on("tvstand", "tv", 1),
        on("k1", "toaster", 1), on("k2", "mug", 2), on("k3", "glass", 1), on("k4", "blender", 1),
        on("k1", "cup", 1), on("ktable", "apple", 2), on("ktable", "donut", 2), on("ktable", "ketchup", 1),
        on("picnic", "can", 2), on("picnic", "apple", 2), on("picnic", "cup", 2), on("picnic", "bottle", 1),
    ],
    "clutter": [
        # inside: plenty for the first tiers
        items("candy", 6, rect=[-24, -20, 24, 20]), items("donut", 4, rect=[-24, -20, -8, 20]),
        items("paper", 6, rect=[-24, -20, 24, 20]), items("slipper", 4, rect=[-4, -20, 24, 20]),
        items("block", 6, rect=[-4, -20, 24, 20]), items("phone", 2, rect=[-4, -20, 24, 20]),
        items("mug", 3, rect=[-24, -20, -8, 20]), items("cup", 3, rect=[-24, -20, -8, 20]),
        items("apple", 4, rect=[-24, -20, -8, 20]), items("can", 3, rect=[-24, -20, -8, 20]),
        items("duck", 2, rect=[-4, -20, 24, 20]), items("car", 3, rect=[-4, -20, 24, 20]),
        items("cushion", 3, rect=[-4, -20, 24, 20]), items("ball", 2, rect=[-4, -20, 24, 20]),
        items("books", 3, rect=[-4, -20, 24, 20]), items("bottle", 2, rect=[-24, -20, -8, 20]),
        items("teddy", 2, rect=[-4, -20, 24, 20]), items("robot", 1, rect=[-4, -20, 24, 20]),
        items("basket", 2, rect=[-24, -20, 24, 20]), items("box_s", 1, rect=[-24, -20, -8, 20]),
        # on the play fort
        items("ball", 2, y=4.5, rect=[47, 40, 61, 48], sep=2.0), items("block", 4, y=4.5, rect=[47, 40, 61, 48], sep=1.4),
        items("teddy", 1, y=4.5, rect=[47, 40, 61, 48], sep=2.6), items("beachball", 1, y=4.5, rect=[47, 40, 61, 48], sep=3.0),
        # flower beds and veggie bed
        items("flower", 9, rect=[-59, 31, -35, 39], sep=1.6), items("flower", 6, rect=[-19, 45, -1, 51], sep=1.6),
        items("gnome", 2, rect=[-59, 31, -35, 39], sep=2.4), items("wateringcan", 1, rect=[-19, 45, -1, 51], sep=2.4),
        items("orange", 5, rect=[41, -5, 65, -3], sep=1.4), items("apple", 4, rect=[41, -5, 65, -3], sep=1.4),
        # sand pit
        items("bucket", 3, rect=[39, 3, 57, 17], sep=2.0), items("block", 3, rect=[39, 3, 57, 17], sep=1.4),
        items("car", 2, rect=[39, 3, 57, 17], sep=1.8), items("duck", 2, rect=[39, 3, 57, 17], sep=1.8),
        items("beachball", 1, rect=[39, 3, 57, 17], sep=3.0),
        # lawns
        items("flamingo", 4, rect=[-60, 24, 60, 56]), items("bush", 6, rect=[-68, -54, 68, 54], sep=5.0),
        items("bush_s", 6, rect=[-68, -54, 68, 54], sep=3.5), items("rock_l", 4, rect=[-68, -54, 68, 54]),
        items("hose", 2, rect=[-40, 24, 40, 40]), items("ball", 3, rect=[-60, 24, 60, 56]),
        items("basketball", 1, rect=[-60, 24, 60, 56]), items("hydrant", 1, rect=[-68, -54, -30, -24]),
        items("acorn", 8, rect=[-68, -40, -30, 20]), items("mushroom", 5, rect=[-68, -40, -30, 20]),
        items("rock", 6, rect=[-68, -54, 68, 54]), items("flower", 5, rect=[-68, -54, 68, 54]),
        items("can", 3, rect=[-68, -54, 68, 54]), items("paper", 3, rect=[-68, -54, 68, 54]),
        items("gnome", 3, rect=[-30, -54, 30, -26]), items("flower", 5, rect=[-30, -54, 30, -26]),
    ],
})

HEADER = '''class_name Stages extends RefCounted

## Stage definitions, generated by tools/gen_stages.py (edit that, not this).
## Every stage uses the same rules
## (smash props of an unlocked tier, each tier makes the truck bigger);
## stages differ in room size and walls, raised platforms and ramps,
## furniture, items on top of furniture, clutter and time limit.
##
## hx / hz:   half size of the room
## walls:     interior walls {from, to, doors: [[distance along wall, width]]}
## platforms: raised surfaces {box: [x, z, width, depth, height]}
## ramps:     {from: [x, z, y], to: [x, z, y], w}
## layout:    furniture {p, t (tier), h (height), s (points), x, z, rot, y?, id?, sc?}
## on_top:    items on a layout id's top surface {on, p|toy, t, h, s, c}
## clutter:   scattered {p|toy, t, h, s, c, rect?, y?, sep?, col?}
## outdoor:   lawn and fence instead of the room shell; "floors" are patches
##            {rect: [x0, z0, x1, z1], kind: "planks" | color}
## solid:     [fx, fz] footprint fraction that collides (tree trunks)
## A door may have a third value: the height of a low opening (pet flap).
## journey:   one continuous run; "zones" ({name, sub, rect, spawn_tier, rugs,
##            layout, on_top, clutter}) appear as the truck grows, and
##            "tier_thresholds", "tier_time" (seconds added per tier) and
##            "star_scores" are set by hand. Walls with "fence": true are
##            picket fences "h" tall. A wall with "break_tier" crumbles
##            once the truck reaches that tier.
## Tier thresholds are derived from each stage's points (see GameManager).

## Star goals as a fraction of the stage's total prop points; 1.0 = smash
## everything (which also ends the run early with a time bonus).
const STAR_FRACTIONS: = [0.25, 0.6, 1.0]
## Tier k unlocks at this fraction of the points available below tier k
## (a stage may override it with "tier_fractions").
const TIER_FRACTIONS: = [0.15, 0.3, 0.45, 0.55, 0.55, 0.55]

## Selected stage (survives scene reloads).
static var current: int = 0

static func get_stage(i: int = -1) -> Dictionary:
	return STAGES[current if i < 0 else i]

static func count() -> int:
	return STAGES.size()

'''

if __name__ == "__main__":
    out = HEADER + "const STAGES: = " + gd(STAGES) + "\n"
    open(sys.argv[1], "w").write(out)
    print("stages:", [s["name"] for s in STAGES])
