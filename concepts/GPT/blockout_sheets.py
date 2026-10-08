"""Blockout sheets 1-12 for the remaining building types, plus their ChatGPT prompts.

Units: x, y in ground units (1 = one 64x32 game cell), z in height units (1 = 1 game px). Each building is a function
of a blockout_kit.Canvas; SHEETS holds what the report and the prompts say about it:
(footprint w x d, wall height, roof rise, first-pass description, detail-pass line)."""
import os

from blockout_kit import make_overview, make_sheet


# ============================================================================================ 1 defence_b
def barbican(c):
    c.box(0.55, 0.2, 1.5, 0.6, 0, 34, "stone")
    for i in range(6):
        c.box(0.62 + i * 0.25, 0.68, 0.12, 0.12, 34, 6, "stone")
        c.box(0.62 + i * 0.25, 0.2, 0.12, 0.12, 34, 6, "stone")
    c.arch_door(1.3, 0.24, 0.8, 0, 14)
    for cx in (0.45, 2.15):
        c.cylinder(cx, 0.5, 0.45, 0, 46, "stone")
        c.cone(cx, 0.5, 0.53, 46, 30, "slate")


def gatehouse(c):
    c.water(-0.45, 1.15, 2.3, 0.55)
    c.box(0, 0, 1.4, 1.0, 0, 32, "stone")
    c.hip(0, 0, 1.4, 1.0, 32, 24, "slate")
    for cx in (0.02, 1.38):
        c.frustum(cx, 0.98, 0.03, 0.14, 12, 6, "stone")
        c.cylinder(cx, 0.98, 0.14, 18, 20, "stone")
        c.cone(cx, 0.98, 0.17, 38, 16, "slate")
    c.arch_door(0.7, 0.2, 1.0, 0, 12)
    c.box(0.5, 1.0, 0.4, 0.78, 0, 2.5, "wood")
    for x in (0.53, 0.87):
        c.beam((x, 1.0, 22), (x, 1.74, 2.5), 0.018, "iron")


def gallows(c):
    c.box(0, 0, 1.2, 1.0, 0, 10, "wood")
    c.steps(0.15, 1.0, 0.36, 0.42, 4, 10, "-y", "wood")
    c.fence(0.04, 0.04, 1.16, 0.04, 8, 0.28, 10)
    c.fence(1.16, 0.04, 1.16, 0.96, 8, 0.3, 10)
    c.flat(0.42, 0.48, 0.32, 0.26, 10, "dark")
    for x in (0.25, 0.86):
        c.box(x, 0.35, 0.09, 0.09, 10, 40, "wood")
    c.box(0.18, 0.35, 0.85, 0.09, 50, 5, "wood")
    c.beam((0.33, 0.395, 38), (0.47, 0.395, 50.5), 0.045)
    c.beam((0.87, 0.395, 38), (0.73, 0.395, 50.5), 0.045)
    c.beam((0.58, 0.395, 50), (0.58, 0.395, 38), 0.014, "iron")


def district_gate(c):
    c.flat(0.42, -0.6, 0.76, 2.1, 0, "paving")
    c.box(0, 0, 0.42, 0.5, 0, 40, "stone")
    c.box(1.18, 0, 0.42, 0.5, 0, 40, "stone")
    c.arch_fill(0.42, 1.18, 0, 0.5, 16, 40)
    c.box(-0.04, -0.04, 1.68, 0.58, 40, 3, "stone")
    c.box(0.1, 0.05, 1.4, 0.4, 43, 8, "wall")
    c.gable(0.1, 0.05, 1.4, 0.4, 51, 16, "red")


# ============================================================================================ 2 faith
def chapel(c):
    c.box(-0.45, 0.15, 0.45, 0.6, 0, 18, "stone")
    c.gable(-0.45, 0.15, 0.45, 0.6, 18, 16, "slate")
    c.box(0, 0, 1.6, 0.9, 0, 22, "stone")
    c.gable(0, 0, 1.6, 0.9, 22, 24, "slate")
    c.box(1.25, 0.33, 0.24, 0.24, 30, 30, "stone")
    c.door(1.31, 1.43, 0.57, 49, 56)
    c.door_x(0.39, 0.51, 1.49, 49, 56)
    c.gable(1.25, 0.33, 0.24, 0.24, 60, 10, "slate", along_x=False)
    c.box(1.36, 0.44, 0.02, 0.02, 69, 6, "iron")
    c.box(0.95, 0.9, 0.42, 0.36, 0, 14, "stone")
    c.gable(0.95, 0.9, 0.42, 0.36, 14, 12, "slate", along_x=False)
    c.arch_door(1.16, 0.09, 1.26, 0, 7)
    for x in (0.2, 0.55):
        c.door(x, x + 0.1, 0.9, 7, 17)


def monastery(c):
    c.flat(0.6, 0.6, 1.2, 1.4, 0, "paving")
    c.box(0, 0, 2.4, 0.6, 0, 26, "stone")
    c.gable(0, 0, 2.4, 0.6, 26, 22, "red")
    c.box(0.15, 0.05, 0.36, 0.36, 0, 46, "stone")
    c.hip(0.15, 0.05, 0.36, 0.36, 46, 18, "slate")
    c.box(0, 0.3, 0.6, 1.7, 0, 22, "stone")
    c.gable(0, 0.3, 0.6, 1.7, 22, 20, "red", along_x=False)
    c.box(1.8, 0.3, 0.6, 1.7, 0, 22, "stone")
    c.gable(1.8, 0.3, 0.6, 1.7, 22, 20, "red", along_x=False)
    c.box(1.3, 0.12, 0.15, 0.15, 26, 30, "stone")
    c.posts([(0.62 + i * 0.232, 0.84) for i in range(6)], 0, 9, 0.045)
    c.shed(0.6, 0.6, 1.2, 0.26, 13, 9, "+y", "red")
    c.posts([(0.84, 0.86 + i * 0.27) for i in range(1, 5)], 0, 9, 0.045)
    c.shed(0.6, 0.86, 0.26, 1.14, 13, 9, "+x", "red")
    c.posts([(1.56, 0.86 + i * 0.27) for i in range(1, 5)], 0, 9, 0.045)
    c.shed(1.54, 0.86, 0.26, 1.14, 13, 9, "-x", "red")
    c.flat(0.98, 1.1, 0.44, 0.5, 0.01, "green")
    c.cylinder(1.2, 1.35, 0.09, 0, 4, "stone", top="dark")


def graveyard(c):
    c.wall(0, 0, 2.0, 0, 6)
    c.wall(0, 0, 0, 1.4, 6)
    c.wall(2.0, 0, 2.0, 1.4, 6)
    c.wall(0, 1.4, 0.8, 1.4, 6)
    c.wall(1.2, 1.4, 2.0, 1.4, 6)
    c.box(0.72, 1.33, 0.12, 0.14, 0, 10, "stone")
    c.box(1.16, 1.33, 0.12, 0.14, 0, 10, "stone")
    c.box(1.35, 0.1, 0.5, 0.42, 0, 14, "stone")
    c.gable(1.35, 0.1, 0.5, 0.42, 14, 14, "slate", along_x=False)
    c.arch_door(1.6, 0.08, 0.52, 0, 6)
    c.tree(0.28, 0.3, 8, 0.2, 13)
    for r in range(3):
        for k in range(6):
            x, y = 0.22 + k * 0.26, 0.62 + r * 0.25
            if r == 0 and x > 1.2:
                continue
            tall = (r * 6 + k) % 4 == 1
            c.box(x, y, 0.09, 0.035, 0, 8 if tall else 5, "stone")
            if tall:
                c.box(x - 0.03, y, 0.15, 0.035, 5, 1.5, "stone")


def hospital(c):
    c.box(0, 0, 2.8, 1.0, 0, 30, "wall")
    c.gable(0, 0, 2.8, 1.0, 30, 30, "red")
    for x in (0.55, 2.1):
        c.box(x, 0.3, 0.16, 0.16, 30, 38, "stone")
    for x in (0.4, 1.25, 2.1):
        c.box(x, 0.6, 0.3, 0.36, 30, 15, "wall")
        c.gable(x, 0.6, 0.3, 0.36, 45, 9, "red", along_x=False)
    c.porch(1.2, 1.0, 0.4, 0.34, 14, 10, "red")
    c.door(1.32, 1.48, 1.0, 0, 10)
    c.steps(1.25, 1.34, 0.3, 0.15, 1, 3, "-y")


def leper_house(c):
    c.fence(0, 0, 1.85, 0)
    c.fence(0, 0, 0, 1.35)
    c.fence(1.85, 0, 1.85, 1.35)
    c.fence(0, 1.35, 0.7, 1.35)
    c.fence(1.05, 1.35, 1.85, 1.35)
    c.box(0.3, 0.25, 0.9, 0.7, 0, 16, "wall")
    c.gable(0.3, 0.25, 0.9, 0.7, 16, 18, "red")
    c.box(0.95, 0.42, 0.13, 0.13, 16, 24, "stone")
    c.lean_to(1.2, 0.35, 0.35, 0.55, 12, 8, "+x", "wood", "slate")
    c.door(0.55, 0.7, 0.95, 0, 10)
    c.cylinder(0.25, 1.1, 0.08, 0, 5, "wood", top="water")
    c.posts([(1.45, 1.15)], 0, 12, 0.04)
    c.beam((1.45, 1.15, 12), (1.6, 1.15, 12), 0.03)


def bathhouse(c):
    c.box(0, 0, 1.6, 1.1, 0, 20, "stone")
    c.gable(0, 0, 1.6, 1.1, 20, 22, "red")
    for x in (0.3, 0.95):
        c.box(x, 0.45, 0.24, 0.2, 34, 13, "wood")
        c.gable(x, 0.45, 0.24, 0.2, 47, 6, "red")
    c.lean_to(1.6, 0.2, 0.5, 0.7, 14, 10, "+x", "stone", "slate")
    c.box(1.72, 0.35, 0.2, 0.2, 0, 54, "stone")
    c.door(0.5, 0.7, 1.1, 0, 11)
    c.steps(0.45, 1.1, 0.3, 0.14, 1, 3, "-y")


# ============================================================================================ 3 trade
def coaching_inn(c):
    c.box(-1.1, 0.25, 1.1, 0.65, 0, 16, "wall")
    c.gable(-1.1, 0.25, 1.1, 0.65, 16, 16, "slate")
    for x in (-1.0, -0.65, -0.3):
        c.door(x, x + 0.24, 0.9, 0, 11)
    c.box(0, 0, 2.2, 0.9, 0, 30, "wall")
    c.gable(0, 0, 2.2, 0.9, 30, 28, "red")
    c.box(1.4, 0.45, 0.8, 1.55, 0, 30, "wall")
    c.gable(1.4, 0.45, 0.8, 1.55, 30, 26, "red", along_x=False)
    for x in (0.3, 0.85):
        c.box(x, 0.5, 0.3, 0.38, 30, 13, "wall")
        c.gable(x, 0.5, 0.3, 0.38, 43, 8, "red", along_x=False)
    c.box(0.15, 0.2, 0.16, 0.16, 30, 38, "stone")
    c.box(1.7, 1.2, 0.16, 0.16, 30, 34, "stone")
    c.door(0.6, 0.8, 0.9, 0, 11)
    c.door(1.7, 1.9, 2.0, 0, 11)
    c.posts([(0.3, 1.45)], 0, 30, 0.05)
    c.beam((0.3, 1.45, 28), (0.55, 1.45, 28), 0.035)
    c.box(0.43, 1.43, 0.14, 0.03, 17, 9, "wood")
    c.box(-0.8, 1.05, 0.4, 0.12, 0, 4, "wood", top="water")


def shop_house(c):
    c.box(0, 0, 0.75, 1.2, 0, 14, "wall")
    c.box(-0.04, 0, 0.83, 1.3, 14, 16, "wall")
    c.gable(-0.04, 0, 0.83, 1.3, 30, 30, "slate", along_x=False)
    c.box(0.3, 0.15, 0.14, 0.14, 30, 36, "stone")
    c.door(0.06, 0.69, 1.2, 1, 12)
    c.box(0.08, 1.2, 0.59, 0.12, 0, 6, "wood")
    c.shed(0.0, 1.3, 0.75, 0.32, 13.5, 10.5, "+y", "red")
    c.posts([(0.03, 1.6), (0.72, 1.6)], 0, 10.5, 0.04)
    c.box(-0.25, 1.0, 0.18, 0.18, 0, 5, "wood")
    c.cylinder(-0.14, 1.35, 0.07, 0, 6, "wood")


def guild_hall(c):
    c.box(0, 0, 1.4, 1.6, 0, 30, "stone")
    c.gable(0, 0, 1.4, 1.6, 30, 34, "red", along_x=False)
    c.box(0, 1.6, 1.4, 0.12, 0, 38, "stone")
    for k in range(1, 5):
        half = 0.7 - k * 0.14
        c.box(0.7 - half, 1.6, 2 * half, 0.12, 30 + k * 8, 8, "stone")
    c.box(0.66, 1.62, 0.08, 0.08, 70, 6, "stone")
    c.box(0.9, 0.35, 0.45, 0.32, 30, 15, "wall")
    c.gable(0.9, 0.35, 0.45, 0.32, 45, 8, "red")
    c.box(0.15, 0.3, 0.16, 0.16, 30, 40, "stone")
    c.arch_door(0.7, 0.12, 1.72, 4, 10)
    for x in (0.2, 1.05):
        c.door(x, x + 0.15, 1.72, 16, 27)
    c.steps(0.45, 1.72, 0.5, 0.28, 2, 6, "-y")


def market_hall(c):
    c.box(0, 0, 2.4, 1.4, 0, 3, "stone")
    pts = [(0.05 + i * 0.575, 0.05) for i in range(5)] + [(0.05 + i * 0.575, 1.35) for i in range(5)]
    pts += [(0.05, 0.7), (2.35, 0.7)]
    c.posts(pts, 3, 17, 0.1)
    c.box(0.35, 0.45, 0.55, 0.28, 3, 6, "wood")
    c.box(1.4, 0.45, 0.55, 0.28, 3, 6, "wood")
    c.box(0.9, 0.95, 0.55, 0.25, 3, 6, "wood")
    c.hip(0, 0, 2.4, 1.4, 20, 30, "red", o=0.12)
    c.box(1.0, 0.6, 0.4, 0.2, 40, 13, "wood")
    c.hip(1.0, 0.6, 0.4, 0.2, 53, 8, "red")


def weigh_house(c):
    c.box(0, 0, 1.2, 1.0, 0, 24, "stone")
    c.gable(0, 0, 1.2, 1.0, 24, 22, "slate")
    c.box(0.85, 0.3, 0.15, 0.15, 24, 30, "stone")
    c.door(0.15, 0.35, 1.0, 0, 11)
    c.shed(0.05, 1.0, 1.1, 0.5, 16, 12, "+y", "slate")
    c.posts([(0.08, 1.46), (1.12, 1.46)], 0, 12, 0.05)
    c.box(1.62, 0.6, 0.06, 0.06, 0, 22, "wood")
    c.beam((1.62, 0.63, 0), (1.5, 0.63, 8), 0.04)
    c.beam((1.68, 0.63, 0), (1.8, 0.63, 8), 0.04)
    c.box(1.3, 0.6, 0.66, 0.06, 20, 2, "wood")
    for x in (1.34, 1.92):
        c.beam((x, 0.63, 20), (x, 0.63, 9), 0.012, "iron")
        c.box(x - 0.09, 0.54, 0.18, 0.18, 8, 1.2, "iron")
    c.box(1.3, 1.1, 0.12, 0.1, 0, 3, "iron")
    c.box(1.48, 1.12, 0.08, 0.08, 0, 2, "iron")


def fish_market(c):
    c.box(0.15, 0.35, 0.6, 0.3, 0, 6, "wood")
    c.box(1.05, 0.35, 0.6, 0.3, 0, 6, "wood")
    c.canopy(0, 0, 1.8, 1.0, 14, 14, "slate", nx=3, ny=2, t=0.08)
    c.box(0.2, 1.15, 0.55, 0.26, 0, 6, "wood")
    c.cylinder(1.3, 1.3, 0.13, 0, 4, "wood", top="water")
    c.cylinder(1.62, 1.22, 0.08, 0, 6, "wood")
    c.box(0.95, 1.2, 0.16, 0.14, 0, 3, "wood")


# ============================================================================================ 4 crafts_a
def bakery(c):
    c.box(0, 0, 1.2, 0.9, 0, 18, "wall")
    c.gable(0, 0, 1.2, 0.9, 18, 20, "red")
    c.box(0.25, 0.3, 0.15, 0.15, 18, 26, "stone")
    c.box(1.2, 0.15, 0.45, 0.6, 0, 5, "stone")
    c.dome(1.42, 0.45, 0.24, 0.28, 5, 12, "stone")
    c.box(1.37, 0.3, 0.1, 0.1, 10, 16, "stone")
    c.door(0.75, 0.95, 0.9, 0, 11)
    c.box(0.15, 1.02, 0.5, 0.15, 0, 6, "wood")
    c.dome(0.3, 1.1, 0.06, 0.05, 6, 3, "cloth")
    c.dome(0.48, 1.1, 0.06, 0.05, 6, 3, "cloth")


def butcher(c):
    c.box(0, 0, 1.0, 1.0, 0, 26, "wall")
    c.gable(0, 0, 1.0, 1.0, 26, 24, "red", along_x=False)
    c.box(0.15, 0.25, 0.15, 0.15, 26, 30, "stone")
    c.lean_to(1.0, 0.2, 0.4, 0.6, 14, 10, "+x", "wood", "slate")
    c.door(0.08, 0.92, 1.0, 1, 11)
    c.box(0.08, 1.0, 0.84, 0.14, 0, 6, "wood")
    c.shed(0.0, 1.0, 1.0, 0.28, 14.5, 12, "+y", "red")
    c.box(0.1, 1.12, 0.8, 0.02, 11, 0.8, "iron")
    c.cylinder(-0.2, 1.1, 0.1, 0, 5, "wood")


def brewery(c):
    c.box(0, 0, 1.8, 1.1, 0, 24, "wall")
    c.gable(0, 0, 1.8, 1.1, 24, 24, "red")
    c.box(0.45, 0.42, 0.28, 0.28, 40, 16, "wood")
    c.hip(0.45, 0.42, 0.28, 0.28, 56, 12, "red")
    c.box(1.15, 0.45, 0.22, 0.2, 40, 10, "wood")
    c.gable(1.15, 0.45, 0.22, 0.2, 50, 6, "red")
    c.box(1.5, 0.3, 0.15, 0.15, 24, 32, "stone")
    c.door(0.2, 0.42, 1.1, 0, 12)
    for cy in (0.3, 0.85):
        c.cylinder(2.1, cy, 0.22, 0, 16, "wood")
    for i, x in enumerate((0.7, 0.95, 1.2)):
        c.hcyl("y", x, 1.25, 3.5, 0.11, 0.26, "wood")
    for x in (0.825, 1.075):
        c.hcyl("y", x, 1.25, 9.4, 0.11, 0.26, "wood")


def tannery(c):
    c.box(0, 0, 1.2, 0.8, 0, 16, "wall")
    c.gable(0, 0, 1.2, 0.8, 16, 18, "slate")
    c.canopy(1.2, 0.05, 0.5, 0.7, 10, 3, "slate", nx=2, ny=2, roof="shed", t=0.05, low="+x")
    c.door(0.2, 0.38, 0.8, 0, 10)
    for x0 in (0.1, 0.75):
        c.box(x0, 1.15, 0.05, 0.05, 0, 18, "wood")
        c.box(x0 + 0.5, 1.15, 0.05, 0.05, 0, 18, "wood")
        c.box(x0, 1.15, 0.55, 0.05, 16, 2, "wood")
        c.box(x0, 1.15, 0.55, 0.05, 2, 1.5, "wood")
        c.box(x0 + 0.08, 1.165, 0.39, 0.02, 4.5, 10.5, "cloth")
    for cx, cy in ((1.55, 1.1), (1.85, 1.0), (1.75, 1.4)):
        c.cylinder(cx, cy, 0.13, 0, 5, "wood", top="earth")


def dyers(c):
    c.box(0, 0, 1.4, 0.9, 0, 20, "wall")
    c.gable(0, 0, 1.4, 0.9, 20, 20, "red")
    c.box(1.05, 0.28, 0.15, 0.15, 20, 28, "stone")
    c.door(0.3, 0.5, 0.9, 0, 11)
    for x in (1.75, 2.15):
        for y in (0.0, 0.6, 1.2):
            c.box(x, y, 0.05, 0.05, 0, 30, "wood")
        c.box(x, 0.0, 0.05, 1.25, 28, 2, "wood")
        c.box(x + 0.01, 0.08, 0.03, 0.45, 9, 19, "cloth")
        c.box(x + 0.01, 0.68, 0.03, 0.45, 9, 19, "cloth")
    for cx in (0.4, 0.8):
        c.cylinder(cx, 1.15, 0.14, 0, 7, "wood", top="water")


def weavers(c):
    c.box(0, 0, 2.2, 1.1, 0, 30, "wall")
    c.gable(0, 0, 2.2, 1.1, 30, 28, "slate")
    c.door(0.12, 2.08, 1.1, 18, 25)
    c.door_x(0.1, 1.0, 2.2, 18, 25)
    for i in range(1, 12):
        x = 0.12 + i * (1.96 / 12)
        c.flat_face([(x - 0.012, 1.1, 18), (x + 0.012, 1.1, 18), (x + 0.012, 1.1, 25), (x - 0.012, 1.1, 25)],
                    "wall", 0.004)
    for x in (0.35, 1.45):
        c.box(x, 0.55, 0.32, 0.4, 30, 14, "wall")
        c.gable(x, 0.55, 0.32, 0.4, 44, 9, "slate", along_x=False)
    c.box(1.0, 0.25, 0.16, 0.16, 30, 36, "stone")
    c.door(0.95, 1.15, 1.1, 0, 11)
    c.steps(0.9, 1.1, 0.3, 0.14, 1, 3, "-y")


# ============================================================================================ 5 crafts_b
def potter(c):
    c.box(0, 0, 1.0, 0.8, 0, 16, "wall")
    c.gable(0, 0, 1.0, 0.8, 16, 18, "red")
    c.box(0.2, 0.25, 0.14, 0.14, 16, 22, "stone")
    c.door(0.55, 0.72, 0.8, 0, 10)
    c.cylinder(1.45, 0.45, 0.32, 0, 14, "stone")
    c.dome(1.45, 0.45, 0.32, 0.32, 14, 10, "stone")
    c.cylinder(1.45, 0.45, 0.08, 20, 12, "stone")
    c.box(1.38, 0.72, 0.14, 0.1, 0, 6, "stone")
    c.door(1.41, 1.49, 0.82, 0, 4)
    c.box(0.12, 0.95, 0.65, 0.16, 0, 5, "wood")
    for x in (0.2, 0.36, 0.52, 0.68):
        c.cylinder(x, 1.03, 0.045, 5, 4, "earth", 10)


def cooper(c):
    c.box(0, 0, 0.8, 0.6, 0, 14, "wood")
    c.gable(0, 0, 0.8, 0.6, 14, 14, "slate")
    c.door(0.08, 0.72, 0.6, 0, 10)
    c.box(0.6, 0.12, 0.1, 0.1, 14, 16, "stone")
    for y0 in (0.15, 0.75):
        for x in (0.98, 1.2, 1.42):
            c.hcyl("y", x, y0, 3.3, 0.105, 0.24, "wood")
        for x in (1.09, 1.31):
            c.hcyl("y", x, y0, 9.0, 0.105, 0.24, "wood")
        c.hcyl("y", 1.2, y0, 14.7, 0.105, 0.24, "wood")
    c.cylinder(0.25, 0.9, 0.1, 0, 7, "wood")
    c.cylinder(0.5, 1.02, 0.1, 0, 7, "wood")
    c.box(0.2, 1.2, 0.45, 0.14, 0, 2, "wood")


def masons_yard(c):
    c.box(0, 0, 0.9, 0.06, 0, 16, "wood")
    c.canopy(0, 0, 0.9, 0.5, 12, 4, "red", nx=3, ny=2, roof="shed", t=0.05, low="+y")
    c.box(0.15, 0.15, 0.3, 0.2, 0, 7, "stone")
    c.box(1.1, 0.1, 0.5, 0.35, 0, 8, "stone")
    c.box(1.15, 0.15, 0.32, 0.24, 8, 6, "stone")
    c.box(0.15, 0.75, 0.42, 0.3, 0, 6, "stone")
    c.box(0.2, 0.8, 0.3, 0.22, 6, 6, "stone")
    c.box(0.7, 1.05, 0.18, 0.14, 0, 5, "stone")
    c.box(1.4, 0.85, 0.08, 0.08, 0, 46, "wood")
    c.beam((1.2, 0.89, 0), (1.42, 0.89, 14), 0.04)
    c.beam((1.44, 1.12, 0), (1.44, 0.92, 14), 0.04)
    c.beam((1.46, 0.89, 28), (2.08, 0.89, 46), 0.05)
    c.beam((1.44, 0.89, 46), (2.06, 0.89, 46), 0.03)
    c.beam((2.04, 0.89, 45), (2.04, 0.89, 12), 0.012, "iron")
    c.box(1.97, 0.82, 0.14, 0.14, 7, 5, "stone")
    c.hcyl("x", 1.5, 1.05, 4, 0.05, 0.22, "wood")


def lumber_yard(c):
    c.flat(0.2, 0.18, 0.6, 0.24, 0.02, "dark")
    c.canopy(0, 0, 1.0, 0.6, 16, 16, "slate", nx=2, ny=2, t=0.07)
    for x in (0.12, 0.85):
        c.box(x, 0.24, 0.05, 0.12, 0, 5, "wood")
    c.hcyl("x", 0.05, 0.3, 6.5, 0.06, 0.9, "wood")
    for x0, y0, n in ((1.2, 0.8, 4), (0.15, 1.0, 3)):
        for row in range(n):
            for k in range(n - row):
                c.hcyl("x", x0, y0 + (row * 0.5 + k) * 0.15, 2.4 + row * 4.1, 0.075, 0.85, "wood", n=12)
    c.box(1.25, 0.15, 0.8, 0.35, 0, 3, "wood")
    c.box(1.3, 0.2, 0.7, 0.25, 3, 2, "wood")


def charcoal_kiln(c):
    c.dome(0.6, 0.6, 0.55, 0.55, 0, 18, "earth")
    c.cylinder(0.6, 0.6, 0.07, 16, 2.5, "earth", top="dark")
    c.box(1.35, 0.1, 0.55, 0.6, 0, 2, "wood")
    c.gable(1.35, 0.1, 0.55, 0.6, 2, 22, "thatch", along_x=False, end="wood")
    c.door(1.55, 1.7, 0.78, 0, 9)
    c.box(0.1, 1.25, 0.55, 0.16, 0, 5, "wood")


def glassworks(c):
    c.box(0, 0, 1.5, 1.0, 0, 22, "stone")
    c.gable(0, 0, 1.5, 1.0, 22, 20, "slate")
    c.frustum(2.0, 0.5, 0.48, 0.18, 0, 64, "stone")
    c.cylinder(2.0, 0.5, 0.21, 64, 3, "stone", top="dark")
    c.box(1.85, 0.9, 0.3, 0.16, 0, 10, "stone")
    c.door(1.92, 2.08, 1.06, 0, 6)
    c.door(0.5, 0.7, 1.0, 0, 11)
    c.box(0.95, 1.12, 0.2, 0.16, 0, 4, "wood")
    c.box(1.2, 1.12, 0.2, 0.16, 0, 4, "wood")


# ============================================================================================ 6 food
def granary(c):
    for x in (0.1, 0.6, 1.1):
        for y in (0.1, 0.7):
            c.cylinder(x, y, 0.05, 0, 6, "stone", 10)
            c.cylinder(x, y, 0.11, 6, 2, "stone", 12)
    c.box(0, 0, 1.2, 0.8, 8, 18, "wood")
    c.gable(0, 0, 1.2, 0.8, 26, 20, "red")
    c.door(0.5, 0.7, 0.8, 9, 21)
    c.steps(0.45, 0.88, 0.3, 0.3, 3, 9, "-y", "stone")


def dock_warehouse(c):
    c.water(-0.25, 1.6, 1.9, 0.45)
    c.box(-0.25, 1.0, 1.9, 0.6, 0, 2, "stone")
    c.box(0, 0, 1.4, 1.0, 0, 40, "wall")
    c.gable(0, 0, 1.4, 1.0, 40, 32, "slate", along_x=False)
    c.box(0.15, 0.2, 0.16, 0.16, 40, 30, "stone")
    c.door(0.55, 0.85, 1.0, 2, 13)
    for z0, z1 in ((16, 25), (29, 37), (44, 52)):
        c.door(0.58, 0.82, 1.0, z0, z1)
    c.box(0.66, 1.0, 0.08, 0.45, 56, 4, "wood")
    c.beam((0.7, 1.4, 56), (0.7, 1.4, 22), 0.012, "iron")
    c.box(0.62, 1.32, 0.16, 0.16, 15, 7, "wood")
    c.box(-0.15, 1.15, 0.2, 0.2, 2, 5, "wood")
    c.cylinder(1.3, 1.3, 0.08, 2, 6, "wood")


def orchard(c):
    for cx, cy in ((0.4, 0.4), (1.2, 0.4), (0.4, 1.2), (1.2, 1.2)):
        c.tree(cx, cy, 10, 0.32, 15)
    c.beam((0.95, 1.38, 0), (1.08, 1.27, 22), 0.03)
    c.beam((1.03, 1.46, 0), (1.15, 1.34, 22), 0.03)
    c.cylinder(0.8, 1.55, 0.07, 0, 4, "wood")


def vineyard(c):
    for r in range(4):
        y = 0.1 + r * 0.32
        c.box(0.02, y - 0.045, 1.8, 0.12, 4, 8, "green")
        for i in range(7):
            c.box(i * 0.3, y, 0.035, 0.035, 0, 14, "wood")
        c.box(0, y + 0.005, 1.84, 0.025, 12.5, 0.8, "wood")


def beehives(c):
    c.box(0, 0, 1.6, 0.14, 0, 18, "stone")
    c.gable(0, 0, 1.6, 0.14, 18, 4, "slate")
    for x in (0.1, 0.78, 1.45):
        c.box(x, 0.2, 0.05, 0.18, 0, 5, "wood")
    c.box(0.05, 0.18, 1.5, 0.22, 5, 1.5, "wood")
    for x in (0.2, 0.5, 0.8, 1.1, 1.4):
        c.dome(x, 0.29, 0.1, 0.1, 6.5, 9, "thatch")
        c.door(x - 0.02, x + 0.02, 0.385, 6.5, 8.5)


def dovecote(c):
    c.cylinder(0.45, 0.45, 0.45, 0, 30, "stone")
    c.cylinder(0.45, 0.45, 0.48, 18, 1.5, "stone")
    c.cone(0.45, 0.45, 0.53, 30, 26, "red")
    c.cylinder(0.45, 0.45, 0.1, 48, 9, "wood", 10)
    c.cone(0.45, 0.45, 0.14, 57, 9, "red", 10)
    c.box(0.37, 0.82, 0.16, 0.1, 0, 10, "stone")
    c.door(0.41, 0.49, 0.92, 0, 8)


# ============================================================================================ 7 water
def water_tower(c):
    c.box(0, 0, 0.8, 0.8, 0, 30, "stone")
    c.cylinder(0.4, 0.4, 0.46, 30, 14, "wood")
    c.cone(0.4, 0.4, 0.52, 44, 14, "slate")
    c.box(0.8, 0.58, 0.05, 0.05, 6, 26, "iron")
    c.box(0.82, 0.45, 0.25, 0.32, 0, 4, "stone", top="water")
    c.door(0.3, 0.5, 0.8, 0, 11)


def aqueduct(c):
    c.box(0, 0, 0.13, 0.35, 0, 36, "stone")
    c.box(1.07, 0, 0.13, 0.35, 0, 36, "stone")
    c.box(-0.02, -0.01, 0.17, 0.37, 13, 1.5, "stone")
    c.box(1.05, -0.01, 0.17, 0.37, 13, 1.5, "stone")
    c.arch_fill(0.13, 1.07, 0, 0.35, 14, 36)
    c.box(0, 0, 1.2, 0.35, 36, 8, "stone")
    c.box(0, 0, 1.2, 0.06, 44, 3, "stone")
    c.box(0, 0.29, 1.2, 0.06, 44, 3, "stone")
    c.water(0, 0.06, 1.2, 0.23, 44.5)


def wash_house(c):
    c.water(-0.25, 1.0, 2.1, 0.55)
    c.box(0, 0, 1.6, 1.0, 0, 4, "stone")
    c.box(0.5, 1.0, 0.6, 0.2, 0, 2, "stone")
    c.box(0, 0, 1.6, 0.08, 4, 14, "wood")
    c.canopy(0, 0, 1.6, 0.95, 20, 18, "red", nx=3, ny=2, t=0.07, z0=4)
    c.box(0.15, 0.7, 0.55, 0.14, 4, 3, "stone")
    c.cylinder(1.25, 0.7, 0.1, 4, 4, "wood", top="water")


def latrine(c):
    c.lean_to(0, 0, 0.45, 0.45, 19, 15, "+y", "wood", "red")
    c.door(0.13, 0.32, 0.45, 1, 14)
    c.box(0.1, 0.45, 0.25, 0.1, 0, 1.5, "stone")
    c.box(0.36, 0.08, 0.05, 0.05, 18, 8, "wood")


def sluice(c):
    c.water(0.45, -0.1, 0.5, 1.8)
    c.box(0.3, -0.1, 0.15, 1.8, 0, 5, "stone")
    c.box(0.95, -0.1, 0.15, 1.8, 0, 5, "stone")
    c.box(0.3, 0.7, 0.15, 0.18, 5, 20, "stone")
    c.box(0.95, 0.7, 0.15, 0.18, 5, 20, "stone")
    c.box(0.45, 0.76, 0.5, 0.06, 0, 14, "wood")
    c.box(0.6, 0.77, 0.04, 0.04, 14, 11, "wood")
    c.box(0.8, 0.77, 0.04, 0.04, 14, 11, "wood")
    c.box(0.26, 0.74, 0.88, 0.1, 25, 3, "wood")
    c.hcyl("x", 0.62, 0.79, 31, 0.06, 0.2, "wood")


def footbridge(c):
    c.water(0.4, -0.35, 0.8, 1.5)
    c.prism([(0, 0.25), (0.42, 0.25), (0.42, 0.47), (0, 0.47)], 0, lambda x, y: 3 + 7 * x / 0.42, "stone")
    c.prism([(1.18, 0.25), (1.6, 0.25), (1.6, 0.47), (1.18, 0.47)], 0,
            lambda x, y: 3 + 7 * (1.6 - x) / 0.42, "stone")
    c.posts([(0.8, 0.28), (0.8, 0.44)], 0, 8, 0.05)
    c.box(0.4, 0.25, 0.8, 0.22, 8, 2, "wood")
    for y in (0.27, 0.45):
        c.posts([(0.42 + i * 0.19, y) for i in range(5)], 10, 8, 0.03)
        c.box(0.4, y - 0.015, 0.8, 0.03, 17, 1.2, "wood")


# ============================================================================================ 8 housing
def manor(c):
    c.wall(-1.3, 0.3, -0.05, 0.3, 10)
    c.wall(-1.3, 0.3, -1.3, 1.8, 10)
    c.wall(-1.3, 1.8, -0.85, 1.8, 10)
    c.wall(-0.5, 1.8, -0.05, 1.8, 10)
    c.wall(-0.05, 1.2, -0.05, 1.8, 10)
    c.box(-0.9, 1.74, 0.08, 0.12, 0, 14, "stone")
    c.box(-0.53, 1.74, 0.08, 0.12, 0, 14, "stone")
    c.tree(-0.95, 0.75, 8, 0.24, 12)
    c.box(-1.05, 1.25, 0.6, 0.1, 0, 4, "green")
    c.box(-1.05, 1.45, 0.6, 0.1, 0, 4, "green")
    c.box(0, 0, 2.0, 1.2, 0, 42, "stone")
    c.gable(0, 0, 2.0, 1.2, 42, 34, "slate")
    for x in (0.3, 0.85, 1.4):
        c.box(x, 0.7, 0.3, 0.42, 42, 18, "wall")
        c.gable(x, 0.7, 0.3, 0.42, 60, 10, "slate", along_x=False)
    for x in (0.12, 1.68):
        c.box(x, 0.5, 0.2, 0.2, 42, 48, "stone")
    c.cylinder(2.0, 1.2, 0.2, 0, 58, "stone")
    c.cone(2.0, 1.2, 0.24, 58, 22, "slate")
    c.porch(0.8, 1.2, 0.4, 0.3, 16, 10, "slate")
    c.door(0.9, 1.1, 1.2, 4, 14)
    c.steps(0.75, 1.5, 0.5, 0.25, 3, 6, "-y")


def patrician(c):
    c.box(0, 0, 0.8, 1.0, 0, 14, "stone")
    c.box(-0.03, 0, 0.86, 1.1, 14, 14, "wall")
    c.box(-0.06, 0, 0.92, 1.2, 28, 13, "wall")
    c.gable(-0.06, 0, 0.92, 1.2, 41, 32, "red", along_x=False)
    c.box(0.45, 0.35, 0.4, 0.3, 41, 14, "wall")
    c.gable(0.45, 0.35, 0.4, 0.3, 55, 8, "red")
    c.box(0.08, 0.2, 0.16, 0.16, 41, 38, "stone")
    c.door(0.5, 0.68, 1.0, 0, 11)
    c.door(0.1, 0.38, 1.0, 3, 10)


def terrace(c):
    for i, (h, roof) in enumerate(((26, "red"), (28, "slate"), (26, "red"))):
        x0 = i * 0.8
        c.box(x0, 0, 0.8, 1.0, 0, h, "wall")
        c.gable(x0, 0, 0.8, 1.0, h, 24, roof, o=(0.0, 0.08))
        c.door(x0 + 0.1, x0 + 0.27, 1.0, 1, 11)
        c.steps(x0 + 0.06, 1.0, 0.25, 0.12, 1, 2, "-y")
    for x in (0.72, 1.52):
        c.box(x, 0.35, 0.16, 0.3, 26, 36, "stone")
    c.box(0.95, 0.6, 0.3, 0.38, 28, 13, "wall")
    c.gable(0.95, 0.6, 0.3, 0.38, 41, 8, "slate", along_x=False)


def slum_tenement(c):
    c.tf = lambda p: (p[0] + 0.0032 * p[2], p[1] + 0.0008 * p[2], p[2])
    c.box(0, 0, 0.9, 0.9, 0, 16, "wall")
    c.box(-0.03, 0, 0.96, 0.98, 16, 14, "wall")
    c.box(-0.06, 0, 1.02, 1.06, 30, 12, "wall")
    c.gable(-0.06, 0, 1.02, 1.06, 42, 26, "slate", along_x=False)
    c.box(0.15, 0.2, 0.15, 0.15, 42, 32, "stone")
    c.door(0.55, 0.72, 0.9, 0, 11)
    c.tf = None
    for y in (0.3, 0.75):
        c.beam((1.5, y, 0), (1.05, y, 30), 0.05)
    c.lean_to(0.05, 0.9, 0.42, 0.35, 12, 8, "+y", "wood", "red")


def slum_shacks(c):
    c.lean_to(0, 0, 0.6, 0.5, 13.5, 9.5, "+y", "wood", "red")
    c.box(0.2, 0.15, 0.05, 0.05, 12, 10, "iron")
    c.door(0.35, 0.5, 0.5, 0, 8)
    c.canopy(0.6, 0.0, 0.25, 0.45, 8, 2, "slate", nx=1, ny=2, roof="shed", t=0.04, low="+y")
    c.lean_to(0.85, 0.2, 0.55, 0.55, 12.5, 8.5, "+x", "wood", "slate")
    c.door(0.95, 1.1, 0.75, 0, 8)
    c.box(0.1, 0.62, 0.18, 0.16, 0, 5, "wood")
    c.cylinder(0.65, 0.7, 0.07, 0, 6, "wood")
    c.fence(1.45, 0.25, 1.45, 0.9, 7)


def hut(c):
    c.box(0, 0, 0.8, 0.6, 0, 11, "wall")
    c.gable(0, 0, 0.8, 0.6, 11, 22, "thatch", o=0.11)
    c.box(0.55, 0.22, 0.1, 0.1, 18, 18, "stone")
    c.door(0.15, 0.3, 0.6, 0, 9)
    c.box(0.92, 0.1, 0.15, 0.4, 0, 6, "wood")
    c.fence(-0.1, 0.85, 0.9, 0.85, 6, 0.2)


# ============================================================================================ 9 public
def monument(c):
    c.box(0, 0, 0.9, 0.9, 0, 3, "stone")
    c.box(0.1, 0.1, 0.7, 0.7, 3, 3, "stone")
    c.box(0.25, 0.25, 0.4, 0.4, 6, 16, "stone")
    c.box(0.22, 0.22, 0.46, 0.46, 22, 2, "stone")
    c.box(0.32, 0.36, 0.26, 0.18, 24, 4, "stone")
    c.box(0.36, 0.39, 0.18, 0.12, 28, 18, "stone")
    c.box(0.41, 0.41, 0.08, 0.08, 46, 6, "stone")


def notice_board(c):
    c.box(0, 0.1, 0.06, 0.06, 0, 26, "wood")
    c.box(0.66, 0.1, 0.06, 0.06, 0, 26, "wood")
    c.box(0.02, 0.11, 0.68, 0.04, 8, 14, "wood")
    c.gable(0.0, 0.08, 0.72, 0.1, 26, 8, "red", o=0.04)
    for x0, z0 in ((0.08, 11), (0.24, 14), (0.42, 10), (0.55, 15)):
        c.door(x0, x0 + 0.12, 0.15, z0, z0 + 5, "cloth")


def crier_platform(c):
    c.box(0, 0, 0.8, 0.8, 0, 12, "wood")
    c.fence(0.03, 0.03, 0.77, 0.03, 8, 0.25, 12)
    c.fence(0.03, 0.03, 0.03, 0.77, 8, 0.25, 12)
    c.fence(0.77, 0.03, 0.77, 0.77, 8, 0.25, 12)
    c.steps(0.25, 0.8, 0.3, 0.42, 3, 12, "-y", "wood")
    c.box(0.66, 0.08, 0.04, 0.04, 12, 40, "wood")
    c.box(0.7, 0.09, 0.2, 0.012, 44, 7, "cloth")


def grandstand(c):
    for i, h in enumerate((24, 18, 12, 6)):
        c.box(0, 0.25 * i, 2.4, 0.25, 0, h, "wood")
    c.box(0, 0, 2.4, 0.06, 24, 22, "wood")
    c.posts([(0.04, 0.52), (0.82, 0.52), (1.6, 0.52), (2.36, 0.52)], 12, 34, 0.06)
    c.shed(0, 0, 2.4, 0.55, 50, 46, "+y", "red")
    for x in (0.0, 2.4):
        c.box(x - 0.02, 0.02, 0.03, 0.03, 50, 16, "wood")
        c.box(x, 0.025, 0.16, 0.012, 60, 6, "cloth")


def tilt_barrier(c):
    for x in (0.0, 0.6):
        c.box(x, 0, 0.06, 0.08, 0, 14, "wood")
    c.box(0, 0.01, 1.2, 0.06, 12, 2, "wood")
    c.box(0, 0.02, 1.2, 0.04, 3, 9, "wood")


def stage(c):
    c.box(0, 0.05, 1.6, 0.12, 0, 49, "wood")
    c.box(0, 0.15, 1.6, 1.0, 0, 10, "wood")
    c.box(0, 0.17, 0.12, 0.4, 10, 30, "wood")
    c.box(1.48, 0.17, 0.12, 0.4, 10, 30, "wood")
    c.door(0.3, 1.3, 0.17, 10, 34, "cloth")
    c.posts([(0.05, 1.1), (1.55, 1.1)], 10, 28, 0.06)
    c.shed(0, 0.05, 1.6, 1.1, 50, 40, "+y", "red")
    c.steps(1.1, 1.15, 0.36, 0.3, 3, 10, "-y", "wood")


# ============================================================================================ 10 civic_b
def school(c):
    c.box(0, 0, 1.4, 0.9, 0, 20, "wall")
    c.gable(0, 0, 1.4, 0.9, 20, 22, "red")
    c.box(1.05, 0.36, 0.18, 0.18, 30, 22, "wood")
    c.door(1.09, 1.19, 0.54, 44, 50)
    c.gable(1.05, 0.36, 0.18, 0.18, 52, 8, "red", along_x=False)
    c.box(0.2, 0.3, 0.14, 0.14, 20, 26, "stone")
    c.porch(0.25, 0.9, 0.4, 0.3, 13, 10, "red")
    c.door(0.37, 0.53, 0.9, 0, 10)
    c.steps(0.3, 1.2, 0.3, 0.12, 1, 3, "-y")


def library(c):
    c.box(0, 0, 1.8, 1.1, 0, 34, "stone")
    c.gable(0, 0, 1.8, 1.1, 34, 30, "slate")
    for x in (0.02, 0.58, 1.14, 1.7):
        c.box(x, 1.1, 0.08, 0.12, 0, 26, "stone")
    for x in (0.22, 0.78, 1.34):
        c.door(x, x + 0.18, 1.1, 8, 28)
    for y in (0.25, 0.6):
        c.door_x(y, y + 0.18, 1.8, 8, 28)
    c.cylinder(1.85, 0.15, 0.19, 0, 48, "stone")
    c.cone(1.85, 0.15, 0.23, 48, 18, "slate")
    c.door(0.42, 0.56, 1.1, 0, 0.1)
    c.arch_door(0.95, 0.08, 1.22, 0, 6)
    c.box(0.8, 1.1, 0.3, 0.12, 0, 0.1, "stone")
    c.steps(0.82, 1.22, 0.26, 0.14, 1, 3, "-y")


def pavilion(c):
    import math as _m
    c.cylinder(0.5, 0.5, 0.5, 0, 3, "stone", 8)
    c.posts([(0.5 + 0.42 * _m.cos(_m.pi / 8 + k * _m.pi / 4), 0.5 + 0.42 * _m.sin(_m.pi / 8 + k * _m.pi / 4))
             for k in range(8)], 3, 15, 0.06)
    c.cylinder(0.5, 0.5, 0.47, 18, 2, "wood", 8)
    c.cone(0.5, 0.5, 0.58, 20, 22, "red", 8)
    c.box(0.48, 0.48, 0.04, 0.04, 42, 6, "iron")


def farmhouse(c):
    c.box(0, 0, 1.6, 0.9, 0, 16, "wall")
    c.gable(0, 0, 1.6, 0.9, 16, 26, "thatch", o=0.12)
    c.box(0.7, 0.35, 0.16, 0.16, 16, 30, "stone")
    c.lean_to(1.6, 0.1, 0.55, 0.7, 14, 9, "+x", "wood", "slate")
    c.door(0.35, 0.52, 0.9, 0, 10)
    c.cylinder(0.15, 1.05, 0.08, 0, 5, "wood", top="water")
    c.fence(0.8, 1.15, 2.1, 1.15, 7)


def fishpond(c):
    c.water(0.05, 0.05, 1.3, 0.9, 2)
    c.wall(0, 0, 1.4, 0, 4, 0.1)
    c.wall(0, 0, 0, 1.0, 4, 0.1)
    c.wall(1.4, 0, 1.4, 1.0, 4, 0.1)
    c.wall(0, 1.0, 1.4, 1.0, 4, 0.1)
    c.box(1.0, 0.1, 0.12, 0.08, 0, 7, "green")
    c.box(0.15, 0.75, 0.1, 0.1, 0, 7, "green")
    c.box(0.55, 1.05, 0.3, 0.12, 0, 2, "stone")


def ice_house(c):
    c.dome(0.6, 0.5, 0.55, 0.5, 0, 22, "earth")
    c.cylinder(0.6, 0.45, 0.05, 18, 8, "stone", 10)
    c.box(0.45, 0.7, 0.3, 0.45, 0, 14, "stone")
    c.gable(0.45, 0.7, 0.3, 0.45, 14, 8, "slate", along_x=False)
    c.arch_door(0.6, 0.08, 1.15, 0, 6)


# ============================================================================================ 11 transport
def stables(c):
    c.box(0, 0, 2.2, 0.9, 0, 16, "wall")
    c.gable(0, 0, 2.2, 0.9, 16, 20, "red")
    for k in range(4):
        c.door(0.08 + k * 0.55, 0.47 + k * 0.55, 0.9, 0, 11)
    for x in (0.55, 1.1, 1.65):
        c.box(x - 0.015, 0.9, 0.03, 0.48, 0, 8, "wood")
    c.posts([(0.04, 1.4), (0.57, 1.4), (1.1, 1.4), (1.63, 1.4), (2.16, 1.4)], 0, 10, 0.06)
    c.shed(0, 0.9, 2.2, 0.55, 13.5, 10, "+y", "red")
    c.box(1.0, 0.45, 0.32, 0.4, 16, 14, "wood")
    c.gable(1.0, 0.45, 0.32, 0.4, 30, 9, "red", along_x=False)
    c.door(1.08, 1.24, 0.85, 19, 28)


def wagon(c):
    for x in (0.25, 0.85):
        c.hcyl("y", x, 0.0, 3.9, 0.12, 0.035, "wood", rz=3.9)
    c.box(0.1, 0.05, 0.9, 0.4, 4, 4, "wood")
    c.hcyl("x", 0.15, 0.25, 8, 0.21, 0.8, "cloth", rz=11, half=True)
    for x in (0.25, 0.85):
        c.hcyl("y", x, 0.45, 3.9, 0.12, 0.035, "wood", rz=3.9)
    for y in (0.13, 0.37):
        c.beam((1.0, y, 6), (1.45, y, 5), 0.03)


def hand_cart(c):
    c.hcyl("y", 0.25, -0.03, 4.2, 0.13, 0.03, "wood", rz=4.2)
    c.box(0, 0.02, 0.5, 0.32, 4, 2, "wood")
    c.box(0, 0.02, 0.5, 0.03, 6, 3, "wood")
    c.box(0, 0.02, 0.03, 0.32, 6, 3, "wood")
    c.box(0, 0.31, 0.5, 0.03, 6, 3, "wood")
    c.dome(0.22, 0.17, 0.1, 0.09, 6, 5, "cloth")
    c.hcyl("y", 0.25, 0.34, 4.2, 0.13, 0.03, "wood", rz=4.2)
    for y in (0.06, 0.3):
        c.beam((0.48, y, 5), (0.9, y, 2), 0.03)
    c.box(0.03, 0.05, 0.03, 0.03, 0, 4, "wood")


def harbour_crane(c):
    c.water(-0.25, 0.9, 1.95, 0.6)
    c.box(-0.25, 0, 1.95, 0.9, 0, 3, "stone")
    c.box(0, 0.1, 0.7, 0.6, 3, 22, "wood")
    c.gable(0, 0.1, 0.7, 0.6, 25, 16, "slate")
    c.hcyl("y", 0.35, 0.72, 16, 0.4, 0.08, "wood", rz=12.8, n=20)
    c.hcyl("y", 0.35, 0.8, 16, 0.3, 0.012, "dark", rz=9.6, n=20)
    c.box(0.55, 0.35, 0.1, 0.1, 25, 24, "wood")
    c.beam((0.62, 0.45, 32), (1.05, 1.25, 46), 0.05)
    c.beam((0.6, 0.4, 49), (1.05, 1.25, 46), 0.03)
    c.beam((1.05, 1.25, 45), (1.05, 1.25, 12), 0.012, "iron")
    c.box(0.97, 1.17, 0.16, 0.16, 6, 6, "wood")
    c.cylinder(1.5, 0.75, 0.05, 3, 4, "wood")


def ferry_landing(c):
    c.water(-0.25, 0.5, 2.1, 1.3)
    c.box(-0.25, 0, 2.1, 0.5, 0, 3, "stone")
    c.box(1.2, 0.02, 0.4, 0.35, 3, 12, "wood")
    c.gable(1.2, 0.02, 0.4, 0.35, 15, 10, "red")
    c.posts([(0.32, 0.8), (0.66, 0.8), (0.32, 1.45), (0.66, 1.45)], 0, 6, 0.05)
    c.box(0.3, 0.4, 0.4, 1.1, 4, 1.5, "wood")
    c.posts([(0.72, 1.4)], 0, 8, 0.05)
    c.box(0.85, 0.75, 0.8, 0.55, 0, 3, "wood")
    c.box(0.85, 0.75, 0.8, 0.03, 3, 3, "wood")
    c.box(0.85, 1.27, 0.8, 0.03, 3, 3, "wood")
    c.beam((1.5, 1.0, 3), (1.75, 1.05, 26), 0.025)


def livestock_pens(c):
    c.box(0.05, 0.05, 0.85, 0.05, 0, 13, "wood")
    c.canopy(0.05, 0.05, 0.85, 0.42, 11, 3, "slate", nx=2, ny=2, roof="shed", t=0.05, low="+y")
    c.fence(0, 0, 2.0, 0)
    c.fence(0, 0, 0, 1.2)
    c.fence(2.0, 0, 2.0, 1.2)
    c.fence(1.0, 0, 1.0, 1.2)
    c.fence(0, 1.2, 0.6, 1.2)
    c.fence(0.9, 1.2, 2.0, 1.2)
    c.box(1.3, 0.6, 0.4, 0.12, 0, 3.5, "wood", top="water")
    c.dome(0.5, 0.75, 0.16, 0.14, 0, 7, "thatch")


# ============================================================================================ 12 small
def milestone(c):
    c.box(0, 0, 0.3, 0.24, 0, 2, "stone")
    c.box(0.07, 0.06, 0.16, 0.12, 2, 9, "stone")
    c.hcyl("y", 0.15, 0.06, 11, 0.08, 0.12, "stone", rz=4, half=True)


def wayside_cross(c):
    c.box(0, 0, 0.4, 0.4, 0, 3, "stone")
    c.box(0.08, 0.08, 0.24, 0.24, 3, 3, "stone")
    c.box(0.17, 0.17, 0.06, 0.06, 6, 28, "wood")
    c.box(0.07, 0.17, 0.26, 0.06, 26, 3, "wood")
    c.gable(0.05, 0.13, 0.3, 0.14, 34, 6, "red")


def alley_steps(c):
    c.steps(0.15, 0, 0.6, 1.0, 6, 21, "-y")
    c.box(0.15, 0, 0.6, 0.15, 0, 18, "stone")
    c.box(0, 0, 0.15, 1.0, 0, 30, "stone")
    c.box(-0.01, -0.01, 0.17, 1.02, 30, 2, "stone")
    c.box(0.75, 0, 0.15, 1.0, 0, 30, "stone")
    c.box(0.74, -0.01, 0.17, 1.02, 30, 2, "stone")


# ============================================================================================ metadata
R, SL, TH = "red tile", "slate", "thatch"
SHEETS = [
    ("1_defence_b", [
        (barbican, "barbican", "2.6 x 0.9", "34 (towers 46)", "30 (cone roofs)",
         "BARBICAN: a gate block of warm grey stone between two round stone towers; slate cone roofs; a dark arched "
         "gate passage with a wooden gate and portcullis; crenellations along the top; arrow slits in the towers.",
         "a portcullis grid half raised in the arch, a coat-of-arms shield over the gate, arrow slits, a banner pole on one cone"),
        (gatehouse, "gatehouse", "1.4 x 1.0 (+bridge 0.78)", "32 (corner turrets 18-38)", "24 (hip)",
         "GATEHOUSE: a square warm grey stone gatehouse with a slate hip roof; two small corbelled corner turrets with "
         "slate cones; the arched gate opens onto a lowered wooden drawbridge with iron chains over a short moat of water.",
         "planks and iron bands on the drawbridge, chain pulleys over the gate, a small window in each turret, ripples on the moat"),
        (gallows, "gallows", "1.2 x 1.0 (+steps 0.42)", "platform 10, uprights 40", "-",
         "GALLOWS: a raised wooden scaffold platform with wooden steps at the front and a plain rail at the back; two "
         "heavy wooden uprights with a crossbeam and braces; a dark trapdoor; one rope hanging from the beam.",
         "plank lines and nails on the platform, iron bolts on the beam, a coiled rope, a bucket under the steps"),
        (district_gate, "district gate arch", "1.6 x 0.5", "piers 40, gate room 43-51", "16",
         "DISTRICT GATE: a freestanding stone gateway over a paved street; two square stone piers with a round arch; "
         "a small plastered guard room with timber framing on top under a red tile roof.",
         "a hanging lantern under the arch, a district sign board over the arch, worn paving stones, a small shuttered window in the guard room"),
    ]),
    ("2_faith", [
        (chapel, "parish chapel", "1.6 x 0.9 nave (+chancel 0.45, porch)", "22 (chancel 18, porch 14)", "24",
         "PARISH CHAPEL: a warm grey stone nave with a slate roof, a lower stone chancel at the back, a small stone "
         "porch at the front; a stone bell cote on the ridge with one bell in its opening and a tiny iron cross.",
         "a bronze bell in the cote, a wooden door with iron hinges in the porch, two small rectangular windows with amber glow, a few gravestones beside it"),
        (monastery, "monastery", "2.4 x 2.0", "26 (wings 22, tower 46)", "22 (wings 20, tower 18)",
         "MONASTERY: a U-shaped range of warm grey stone buildings with red tile roofs round a paved cloister court; "
         "a square stone tower with a slate pyramid roof; a covered walk on wooden posts with a red tile lean-to roof "
         "along the three inner sides; a small garden and a well in the court.",
         "monks' cell windows in a row, a herb bed in the court, a bell in the tower, a chimney stack with smoke stains"),
        (graveyard, "graveyard", "2.0 x 1.4", "wall 6 (ossuary 14)", "14 (ossuary)",
         "GRAVEYARD: a low warm grey stone wall round a rectangle with a gap and two gate piers at the front; rows of "
         "small grey headstones and a few stone crosses; a tiny stone ossuary chapel with a slate roof; one dark yew tree.",
         "moss on the wall top, a few wildflowers, a wrought-iron gate between the piers, a skull carving over the ossuary door"),
        (hospital, "hospital / almshouse", "2.8 x 1.0", "30 (two storeys)", "30",
         "HOSPITAL / ALMSHOUSE: a long two-storey ward hall of cream plaster with dark brown timber framing; a big red "
         "tile roof with three dormers and two stone chimneys; a small open timber porch over the door.",
         "two rows of small windows with amber glow, a hanging sign with a cross, a bench by the porch, laundry on a line"),
        (leper_house, "leper house", "0.9 x 0.7 (yard 1.85 x 1.35)", "16", "18",
         "LEPER HOUSE: a small cream plaster cottage with timber framing and a red tile roof, a stone chimney and a "
         "plank lean-to with a slate roof; a wooden fence round its yard with a gap for the gate; a water barrel and "
         "a post with a hanging bell.",
         "a warning clapper bell on the post, patched plaster, a shuttered window, a wicket gate in the fence gap"),
        (bathhouse, "bathhouse", "1.6 x 1.1 (+furnace 0.5)", "20", "22",
         "BATHHOUSE: a warm grey stone hall with a red tile roof and two wooden louvred roof vents on the ridge; a "
         "lower stone furnace room on the right with a slate lean-to roof and a tall stone chimney.",
         "steam drifting from the vents, a firewood stack by the furnace, a towel rail and buckets by the door, a hanging bath sign"),
    ]),
    ("3_trade", [
        (coaching_inn, "coaching inn", "3.3 x 2.0 (L plan)", "30 (stable wing 16)", "28 (wing 26, stable 16)",
         "COACHING INN: an L-shaped two-storey inn of cream plaster and dark timber framing with red tile roofs, two "
         "dormers and two chimneys; a long low stable wing on the left with a slate roof and three open dark stable "
         "doors; a tall post with a hanging inn sign; a water trough.",
         "a painted sign board on the post, flower boxes under the windows, a lantern by the door, hay spilling from the stable doors"),
        (shop_house, "merchant shop-house", "0.83 x 1.3 (+awning 0.32)", "30 (jettied upper floor at 14)", "30",
         "MERCHANT SHOP-HOUSE: a narrow two-storey house with its gable to the street, cream plaster and timber framing, "
         "jettied upper floor, slate roof and a chimney; the ground floor is an open shop front with a wooden counter "
         "under a red tile awning on two posts; a crate and a barrel outside.",
         "goods on the counter (cloth bolts, jars), a hanging shop sign, shutters folded open, a small window with amber glow upstairs"),
        (guild_hall, "guild hall", "1.4 x 1.6 (+steps)", "30", "34 (stepped gable to 70)",
         "GUILD HALL: a warm grey stone hall with a tall stepped stone gable facing the street, a red tile roof, a "
         "dormer and a chimney; an arched door at the top of stone steps; two windows above the door.",
         "a guild coat-of-arms on the gable, a banner over the door, carved step tops, iron lanterns either side of the door"),
        (market_hall, "covered market hall", "2.4 x 1.4", "posts 17 on a 3 plinth", "30 (hip) + roof lantern",
         "COVERED MARKET HALL: a big red tile hip roof on stout wooden posts over a low stone floor, open on all sides, "
         "with a small louvred wooden lantern on the ridge; wooden market stall tables under the roof.",
         "baskets and produce on the tables, cloth hangings between some posts, sacks and crates, a hanging market bell"),
        (weigh_house, "weigh house", "1.2 x 1.0 (+awning 0.5, scale frame 0.7)", "24", "22",
         "WEIGH HOUSE: a warm grey stone house with a slate roof and a chimney; a slate awning on two wooden posts in "
         "front; beside it in the open a tall wooden beam-scale frame with a crossbeam and two hanging iron pans; iron weights on the ground.",
         "sacks on one scale pan, a clerk's desk and ledger, a town seal over the door, stacked iron weights"),
        (fish_market, "fish market", "1.8 x 1.0 (+front table)", "posts 14", "14",
         "FISH MARKET: an open slate roof on six wooden posts over wooden fish tables; another table in front, a "
         "water tub, a barrel and a crate.",
         "silver fish on the tables, ice and wet planks, baskets of fish, a hanging fish sign, gulls on the ridge"),
    ]),
    ("4_crafts_a", [
        (bakery, "bakery", "1.2 x 0.9 (+oven 0.45)", "18", "20",
         "BAKERY: a cream plaster cottage with timber framing, red tile roof and a chimney; a round domed stone bread "
         "oven built onto its right side with its own small chimney; a bread bench out front.",
         "loaves on the bench, a bread peel leaning by the oven, firewood stack, a pretzel-shaped hanging sign"),
        (butcher, "butcher", "1.0 x 1.0 (+lean-to 0.4)", "26 (two storeys)", "24",
         "BUTCHER: a two-storey cream plaster house with timber framing, its gable to the street, red tile roof and a "
         "chimney; the ground floor is an open shop front with a counter under a small red tile hood; a plank cold "
         "store lean-to with a slate roof on the right; a chopping block.",
         "hams and sausages hanging from the iron rail, a cleaver on the block, a pig sign, sawdust on the floor"),
        (brewery, "brewery", "1.8 x 1.1 (+vats)", "24", "24 (malt kiln cowl to 68)",
         "BREWERY: a large cream plaster building with timber framing and a red tile roof; a tall square wooden malt "
         "kiln cowl with a pointed red tile cap and a smaller louvred vent on the ridge; a chimney; two big upright "
         "wooden vats on the right and a stack of lying barrels in front.",
         "iron hoops on vats and barrels, a hop garland over the door, steam from the cowl, sacks of malt"),
        (tannery, "tannery", "1.2 x 0.8 (+open shed 0.5, yard)", "16", "18",
         "TANNERY: a cream plaster workshop with timber framing and a slate roof; an open work shed on posts with a "
         "slate lean-to roof on the right; two wooden frames with stretched hides in front; three wooden tanning vats.",
         "brown liquid in the vats, scraping tools, hides drying on the frames, a stack of bark"),
        (dyers, "dyers' works", "1.4 x 0.9 (+racks to 2.2)", "20", "20",
         "DYERS' WORKS: a cream plaster workshop with timber framing, red tile roof and a chimney; two tall wooden "
         "drying racks on the right hung with long dyed cloths; two dye vats in front.",
         "cloths in deep red, blue and yellow on the racks, coloured liquid in the vats, stirring poles, stained ground"),
        (weavers, "weavers' hall", "2.2 x 1.1", "30 (two storeys)", "28",
         "WEAVERS' HALL: a long two-storey hall of cream plaster with timber framing and a slate roof with two dormers "
         "and a chimney; a wide band of many small windows across the upper floor on both visible sides.",
         "warm amber light in the window band, a loom visible through a window, a cloth bale on a hoist, a guild sign"),
    ]),
    ("5_crafts_b", [
        (potter, "potter", "1.0 x 0.8 (+kiln 0.64)", "16 (kiln 14 + dome)", "18",
         "POTTER: a cream plaster cottage with timber framing, a red tile roof and a chimney; a round brick-and-stone "
         "kiln with a domed top and a short flue on the right, with a small stoke hole; a plank shelf of pots in front.",
         "terracotta pots and jugs on the shelf, a potter's wheel, a stack of firewood by the stoke hole, broken shards"),
        (cooper, "cooper's yard", "0.8 x 0.6 shed (yard 1.6 x 1.3)", "14", "14",
         "COOPER'S YARD: a small open-fronted plank workshop with a slate roof and a chimney; two pyramids of lying "
         "wooden barrels, two upright barrels and a pile of staves.",
         "iron hoops on every barrel, a hoop stack on the wall, a shaving horse, wood shavings"),
        (masons_yard, "mason's yard", "2.1 x 1.2", "shed 12-16, crane mast 46", "4 (lean-to)",
         "MASON'S YARD: an open lean-to shed with a red tile roof on posts against a plank back wall; stacks of cut "
         "pale stone blocks; a wooden jib crane with braces, a rope and a stone block hanging from it, and a windlass drum.",
         "chisels and mallets on a block, a half-carved statue, stone dust, a ladder"),
        (lumber_yard, "lumber yard", "2.1 x 1.4", "sawpit shed posts 16", "16",
         "LUMBER YARD: an open sawpit shed: a slate roof on four posts over a dark pit with a log on trestles; two "
         "pyramids of lying logs; a stack of sawn planks.",
         "a long two-man saw in the log, bark and sawdust piles, an axe in a chopping block, rope-tied plank bundles"),
        (charcoal_kiln, "charcoal kiln", "1.1 dia mound (+hut 0.55 x 0.6)", "mound 18", "22 (A-frame hut)",
         "CHARCOAL KILN: a round earth-and-turf mound with a smoke hole on top; a small "
         "A-frame thatch hut for the burner with a dark door; a short pile of split wood.",
         "thin smoke from the top hole, turf patches on the mound, a rake and shovel, a log seat by the hut"),
        (glassworks, "glassworks", "1.5 x 1.0 (+cone 0.96 dia)", "22", "20 (cone chimney 64)",
         "GLASSWORKS: a warm grey stone workshop with a slate roof; a tall tapering cone furnace chimney of brick and "
         "stone on the right with a small arched furnace mouth at its foot; crates of glass in front.",
         "an orange glow in the furnace mouth, glass bottles in the crates, smoke from the cone top, a firewood heap"),
    ]),
    ("6_food", [
        (granary, "granary", "1.2 x 0.8", "18 (floor raised to 8)", "20",
         "GRANARY: a wooden plank granary raised on six mushroom-shaped staddle stones, with a red tile roof and a "
         "door; loose stone steps that stop short of the door.",
         "vertical plank lines, grain sacks by the steps, a cat on the steps, iron hinges on the door"),
        (dock_warehouse, "dock warehouse", "1.4 x 1.0 (+quay 0.6, water)", "40 (three storeys)", "32",
         "DOCK WAREHOUSE: a tall three-storey warehouse of cream plaster and dark timber framing with a slate roof, "
         "its gable to the quay; a stack of loading doors up the front; a hoist beam under the gable with a rope and a "
         "hanging crate; a stone quay edge and water in front; a crate and a bollard.",
         "a pulley wheel on the hoist beam, open loading doors with sacks inside, mooring rings on the quay, rope coils"),
        (orchard, "orchard", "1.6 x 1.6", "trunks 10", "crowns 15",
         "ORCHARD: four round fruit trees in a square block; a wooden ladder leaning against one tree; a basket.",
         "red and yellow fruit in the crowns, fallen fruit in the basket, a few windfalls on the ground"),
        (vineyard, "vineyard", "1.85 x 1.1", "stakes 14", "-",
         "VINEYARD: four rows of wooden stakes with a wire along the top and green vines trained along each row.",
         "dark purple grape bunches under the leaves, a wicker basket at one row end, curled tendrils"),
        (beehives, "beehives", "1.6 x 0.4", "back wall 18", "4 (coping)",
         "BEEHIVES: five straw bee skeps in a row on a wooden bench, in front of a low stone bee wall with a slate "
         "coping.",
         "coiled straw texture on the skeps, tiny entrance holes, a few bees, flowers at the bench foot"),
        (dovecote, "dovecote", "0.9 dia", "30", "26 (+lantern to 66)",
         "DOVECOTE: a round warm grey stone dovecote with a string course, a red tile cone roof and a small wooden "
         "lantern on top with its own red cone; a small door at the base.",
         "rows of small flight holes under the eaves, doves on the roof and lantern, a weather vane"),
    ]),
    ("7_water", [
        (water_tower, "cistern / water tower", "0.8 x 0.8 (+trough)", "30 (tank 30-44)", "14",
         "CISTERN TOWER: a square warm grey stone tower carrying a round wooden water tank with a slate cone roof; an "
         "iron pipe down the right side into a stone trough.",
         "iron hoops on the tank, water dribbling into the trough, a ladder up the tower, a small door"),
        (aqueduct, "aqueduct segment", "1.2 x 0.35 (tiles along x)", "piers 36, top 47", "-",
         "AQUEDUCT SEGMENT: one stone arch with a half pier at each end and a water channel along the top; it must "
         "tile end to end along its length, so keep both ends cut straight and identical.",
         "stone courses, moss and water stains under the channel, water visible in the channel; keep both ends identical"),
        (wash_house, "wash house", "1.6 x 1.0 (+water)", "posts 4-20 on a 4 platform", "18",
         "WASH HOUSE: a red tile roof on wooden posts over a low stone platform at the water's edge, with a plank "
         "back wall; stone steps down into the water; a stone washing trough and a wash tub.",
         "washing boards, linen drying on a line, buckets, soap suds in the water by the steps"),
        (latrine, "latrine shed", "0.45 x 0.45", "15-19", "4 (mono-pitch)",
         "LATRINE SHED: a small plank shed with a red tile mono-pitch roof, a dark door and a stone step; a vent pipe.",
         "a crescent cut in the door, plank grain, a bucket beside it"),
        (sluice, "sluice gate", "0.8 x 1.8 (channel)", "piers 25", "-",
         "SLUICE GATE: a stone-lined water channel with two stone piers; a wooden gate board across the channel "
         "raised by two rack posts under a wooden lifting beam with a winch drum.",
         "water pouring under the gate, an iron winch handle, iron bands on the gate, moss on the piers"),
        (footbridge, "footbridge", "1.6 x 0.22", "deck 8-10, rails to 18", "-",
         "FOOTBRIDGE: a narrow wooden plank footbridge on two stone abutments and a central pair of posts over a "
         "stream, with simple wooden handrails.",
         "plank gaps, a rope tied to a rail, ripples round the posts, reeds at the banks"),
    ]),
    ("8_housing", [
        (manor, "noble manor", "2.0 x 1.2 (+walled garden 1.25 x 1.5)", "42 (three storeys)", "34",
         "NOBLE MANOR: a three-storey warm grey stone manor with a big slate roof, three dormers, two tall chimneys "
         "and a round stair tower with a slate cone at the front corner; an open porch and front steps; a walled "
         "garden on the left with a gateway, a tree and two hedges.",
         "a coat of arms over the porch, flower beds in the garden, a gravel path, banners on the stair tower"),
        (patrician, "patrician townhouse", "0.92 x 1.2", "41 (three storeys, two jetties)", "32",
         "PATRICIAN TOWNHOUSE: a tall narrow townhouse with a stone ground floor and two jettied upper floors of "
         "cream plaster and dark timber framing; red tile roof with its gable to the street, a side dormer and a "
         "chimney; a door and a shop window.",
         "carved jetty brackets, flower boxes, a hanging lantern, decorative timber patterns on the gable"),
        (terrace, "terraced row of 3", "2.4 x 1.0 (3 x 0.8)", "26 / 28 / 26", "24",
         "TERRACED ROW: three attached cream plaster and timber-framed houses in a row, alternating red and slate "
         "roofs, chimney stacks on the party walls, a dormer on the middle house; each has a door and a step. The "
         "left and right ends are plain party walls so the row can touch its neighbours.",
         "different colours of window shutters per house, a hanging sign on one, a bench, keep both end walls plain"),
        (slum_tenement, "slum tenement", "1.0 x 1.0 (leaning)", "42 (three storeys)", "26",
         "SLUM TENEMENT: a tall leaning three-storey tenement of patched plaster and crooked timbers with a slate roof "
         "and a chimney, propped up by two wooden beams on the right; a plank lean-to with a red tile roof at the front.",
         "patched plaster and boards, washing lines between windows, missing roof slates, rubbish in the corner"),
        (slum_shacks, "two slum shacks", "1.45 x 0.75", "9.5-13.5 / 8.5-12.5", "4 (mono-pitch)",
         "SLUM SHACKS: two small plank shacks with mono-pitch roofs (one red tile, one slate), a stove pipe, a "
         "plank awning between them, a crate, a barrel and a short fence.",
         "mismatched boards, sacking over a window, a cooking pot, patched roof"),
        (hut, "suburb hut", "0.8 x 0.6", "11", "22 (thatch)",
         "SUBURB HUT: a small cream plaster hut with low walls under a big steep thatch roof and a small stone "
         "chimney; a woodpile and a low wattle fence.",
         "thick straw texture on the thatch, a chicken, a water butt, smoke from the chimney"),
    ]),
    ("9_public", [
        (monument, "plaza monument", "0.9 x 0.9", "pedestal to 24, statue to 52", "-",
         "PLAZA MONUMENT: a stepped warm grey stone plinth with a tall pedestal and cornice, carrying a stone statue "
         "of a standing hero.",
         "a bronze plaque on the pedestal, a laurel wreath, pigeons, worn steps"),
        (notice_board, "notice board", "0.72 x 0.1", "posts 26", "8",
         "NOTICE BOARD: a wooden board on two posts with a small red tile roof; a few paper notices pinned on it.",
         "pinned papers and a wanted poster, iron nails, a small lantern hook"),
        (crier_platform, "town crier's platform", "0.8 x 0.8 (+steps)", "12", "-",
         "TOWN CRIER'S PLATFORM: a raised wooden platform with steps at the front, a rail on three sides and a tall "
         "pole with a pennant.",
         "a hand bell hanging on the pole, plank lines, a town banner colour on the pennant"),
        (grandstand, "tournament grandstand", "2.4 x 1.0", "tiers 6-24, back wall 46", "4 (canopy 46-50 over the back tiers)",
         "TOURNAMENT GRANDSTAND: four tiers of wooden benches rising to a plank back wall, under a red tile canopy on "
         "posts; two banner poles with pennants.",
         "striped cloth hangings on the front edge, heraldic shields on the posts, cushions on the top tier"),
        (tilt_barrier, "tilt barrier segment", "1.2 x 0.08 (tiles along x)", "14", "-",
         "TILT BARRIER: one segment of a wooden jousting barrier: posts, a top rail and a board panel. It must tile end "
         "to end along its length, so keep both ends cut straight and identical.",
         "a painted cloth drape over the panel in two colours, keep both ends identical"),
        (stage, "play stage", "1.6 x 1.0 (+steps)", "platform 10, back wall 49", "10 (mono-pitch)",
         "PLAY STAGE: a raised wooden stage with a tall plank back wall and two side wings, a cloth backdrop, a red "
         "tile canopy on two front posts and steps at the side.",
         "a painted backdrop, props on the stage (a crown, a chest), a curtain rope, lanterns along the front edge"),
    ]),
    ("10_civic_b", [
        (school, "school house", "1.4 x 0.9 (+porch)", "20", "22",
         "SCHOOL HOUSE: a cream plaster schoolhouse with timber framing and a red tile roof; a small wooden bell cote "
         "on the ridge; a chimney; an open porch over the door with a step.",
         "a small bell, a slate board by the door, children's satchels on a bench"),
        (library, "library / scriptorium", "1.8 x 1.1", "34", "30 (stair turret 48 + 18)",
         "LIBRARY / SCRIPTORIUM: a tall warm grey stone hall with a slate roof, stone buttresses and tall narrow "
         "rectangular windows; a round stone stair turret with a slate cone at the back corner; a small door with a step.",
         "amber glow in the tall windows, a carved book emblem over the door, iron lanterns"),
        (pavilion, "garden pavilion", "1.0 dia (octagon)", "posts 15 on a 3 base", "22",
         "GARDEN PAVILION: an open octagonal pavilion of wooden posts on a low stone base under a red tile pointed roof "
         "with a finial.",
         "a bench inside, climbing roses on two posts, a carved ring beam"),
        (farmhouse, "thatched farmhouse", "1.6 x 0.9 (+lean-to 0.55)", "16", "26 (thatch)",
         "THATCHED FARMHOUSE: a long low cream plaster farmhouse with timber framing under a big steep thatch roof with "
         "a stone chimney; a plank lean-to with a slate roof on the right; a water butt and a fence.",
         "thick straw thatch with a ridge pattern, a pitchfork, a hay bale, chickens"),
        (fishpond, "fishpond", "1.4 x 1.0", "rim 4", "-",
         "FISHPOND: a rectangular pond with a low warm grey stone rim, reeds at two corners and a stone step.",
         "lily pads and a few orange fish in the water, reeds, a small fishing net"),
        (ice_house, "ice house", "1.1 x 1.0 mound (+entrance)", "mound 22, entrance 14", "8",
         "ICE HOUSE: a round grass-and-earth mound with a vent on top and a small stone entrance with a slate roof "
         "and a dark arched door at the front.",
         "turf on the mound, an iron-banded door, straw bales by the entrance"),
    ]),
    ("11_transport", [
        (stables, "stables / livery", "2.2 x 0.9 (+stall lean-to 0.55)", "16", "20",
         "STABLES / LIVERY: a long cream plaster and timber stable with a red tile roof and a hayloft dormer; an open "
         "row of four stalls under a red tile lean-to on posts at the front with wooden stall partitions.",
         "horse heads looking out of two stalls, hay in the loft door, saddles on a rail, a water bucket"),
        (wagon, "covered wagon", "1.45 x 0.5", "bed 4-8, cover to 19", "-",
         "COVERED WAGON: a wooden wagon with four spoked wheels, a cream canvas cover on hoops and two shafts at the "
         "front. (Mirroring gives the other facing, so no lettering.)",
         "spokes and iron tyres on the wheels, rope ties on the canvas, a lantern and a bucket hanging at the back"),
        (hand_cart, "hand cart", "0.9 x 0.4", "bed 4-9", "-",
         "HAND CART: a small two-wheeled wooden hand cart with low sides, two handles and a sack in it.",
         "spoked wheels, a second sack, a shovel"),
        (harbour_crane, "harbour treadwheel crane", "1.5 x 1.2 (+water)", "house 25", "16",
         "HARBOUR CRANE: a timber crane house with a slate roof on a stone quay, a big wooden treadwheel on its front, "
         "a mast and a long jib reaching over the water with a rope and a hanging crate; a bollard.",
         "spokes and treads on the wheel, a rope drum, pulley at the jib tip, water ripples"),
        (ferry_landing, "ferry landing", "1.8 x 1.5 (+water)", "jetty 5.5, hut 15", "10 (hut)",
         "FERRY LANDING: a wooden jetty on piles from a stone bank into the water, a flat wooden ferry raft with low "
         "rails and a punt pole, and a small ferryman's hut with a red tile roof on the bank.",
         "a rope from the raft to the mooring post, a fare box on the hut, a lantern on the jetty"),
        (livestock_pens, "livestock pens", "2.0 x 1.2", "fence 8, shelter 11-14", "3 (lean-to)",
         "LIVESTOCK PENS: two pens of wooden post-and-rail fencing with a gate gap; a slate lean-to shelter on posts "
         "with a plank back wall; a water trough and a hay heap.",
         "two sheep and a pig, straw on the ground, a gate latch, a feed bucket"),
    ]),
    ("12_small", [
        (milestone, "milestone", "0.3 x 0.24", "13", "-",
         "MILESTONE: a small warm grey stone milestone with a rounded top on a low stone base.",
         "a carved distance number and arrow (keep them unreadable), moss at the base"),
        (wayside_cross, "wayside cross", "0.4 x 0.4", "34", "6",
         "WAYSIDE CROSS: a wooden cross on a stepped stone base with a small red tile roof over the top.",
         "a small carved figure under the roof, flowers on the base, weathered wood"),
        (alley_steps, "alley steps", "0.9 x 1.0", "walls 32, top step 18", "-",
         "ALLEY STEPS: a short flight of stone steps between two warm grey stone wall stubs with coping, rising to a "
         "landing at the back.",
         "worn step edges, a lamp bracket on one wall, moss in the joints"),
    ]),
]

FIRST_PASS = """Image 1 = BLOCKOUT GUIDE. Image 2 = my game's existing buildings (enlarged 4x). Image 3 = the game view.

TASK: Paint each blockout in image 1 as a finished building in the exact art style of image 2. Keep image 1's silhouettes, wall heights, roof shapes, roof pitch, footprint, size and isometric angle EXACTLY — trace over them. Do not make walls taller, roofs smaller, or change the angle. The small grey numbers are labels only — do not draw them. Add surface detail, materials and small props.

STYLE = image 2 exactly: same chunky pixel size, same muted palette (terracotta-red or greyish slate-blue tiles, cream plaster with dark brown timber framing, warm grey stone), dark warm outlines, light from the upper LEFT (left walls lighter, right walls darker), warm amber window glow, small rectangular windows with wooden frames, no arched windows, no stone frames around windows or doors. Doors about one person tall, small like in image 2.

BUILDINGS (by label number):
{buildings}

OUTPUT: same layout as image 1, white or transparent background, no ground, no grass, no shadows, no text or numbers.
"""

DETAIL_PASS = """DETAIL PASS on the image you just made (same chat). Keep every building exactly where and how it is: same silhouettes, wall heights, roof shapes and pitch, footprints, sizes, colours, outlines and isometric angle. Do not redraw from scratch, do not move or resize anything, do not change the layout. The grey label numbers must not appear.

Add finer surface detail only, in the same chunky pixel style and muted palette as image 2: individual roof tiles or slates in courses with a few chipped or mossy ones; timber grain and joints; stone courses with a few cracks; plaster patches; window frames and shutters with warm amber glow; plank doors with iron hinges; small props where they fit. Keep the light from the upper LEFT (left walls lighter, right walls darker).

OUTPUT: same layout, white or transparent background, no ground, no grass, no shadows, no text or numbers.

Extra detail per building — use only the block for the sheet you are working on:
"""

POS = ["top left", "top middle", "top right", "bottom left", "bottom middle", "bottom right"]


def pos_name(i, n):
    if n <= 3:
        return ["left", "middle", "right"][i]
    return POS[i]


def write_prompts(prompt_dir):
    os.makedirs(prompt_dir, exist_ok=True)
    detail = [DETAIL_PASS]
    for name, items in SHEETS:
        lines = [f"{i + 1} ({pos_name(i, len(items))}) {it[5]}" for i, it in enumerate(items)]
        with open(os.path.join(prompt_dir, f"{name}.txt"), "w", encoding="utf-8", newline="\n") as f:
            f.write(FIRST_PASS.format(buildings="\n".join(lines)))
        detail.append(f"\n[{name}]")
        detail += [f"{i + 1}: {it[6]}." for i, it in enumerate(items)]
    with open(os.path.join(prompt_dir, "detail_pass.txt"), "w", encoding="utf-8", newline="\n") as f:
        f.write("\n".join(detail) + "\n")


def report_table():
    out = []
    for name, items in SHEETS:
        out.append(f"\n### {name}\n\n| # | building | footprint (ground units) | wall height | roof rise |\n|---|---|---|---|---|")
        out += [f"| {i + 1} | {it[1]} | {it[2]} | {it[3]} | {it[4]} |" for i, it in enumerate(items)]
    return "\n".join(out)


def build_all(here, defence_png=None):
    bdir = os.path.join(here, "blockouts")
    os.makedirs(bdir, exist_ok=True)
    made = []
    for name, items in SHEETS:
        p = os.path.join(bdir, f"{name}.png")
        make_sheet([it[0] for it in items], p)
        made.append((name, p))
        print(name)
    write_prompts(os.path.join(here, "prompts"))
    ov = ([("0_defence", defence_png)] if defence_png else []) + made
    make_overview(ov, os.path.join(bdir, "overview.png"))
    return made
