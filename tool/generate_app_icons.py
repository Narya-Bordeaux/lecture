"""Produit l'icone de l'application et l'ecran de chargement d'apres le logo.

Source unique : assets/accueil.jpg, le logo de l'accueil du jeu. Relancer ce
script apres avoir change le logo, puis verifier par `flutter test`
(test/infrastructure/app_icon_test.dart).

    pip install pillow
    python3 tool/generate_app_icons.py

Ce qui est produit :
- Android, saveur jeu (src/main/res) : icone adaptative (calque avant et
  couleur de fond), icone de repli pour Android 7, ovale de l'ecran de
  chargement pour Android 7 a 11 ;
- Android, saveur auteur (src/auteur/res) : les memes icones marquees d'un
  crayon, pour ne pas confondre les deux applications sur le telephone ;
- web : favicon, icones ordinaires et icones « maskable ».

Les fichiers XML (styles, couleurs, adaptive-icon) sont ecrits a la main et
ne sont pas produits ici.
"""

import os

from PIL import Image, ImageDraw

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SOURCE = os.path.join(ROOT, 'assets', 'accueil.jpg')
MAIN_RES = os.path.join(ROOT, 'android', 'app', 'src', 'main', 'res')
AUTHOR_RES = os.path.join(ROOT, 'android', 'app', 'src', 'auteur', 'res')
WEB = os.path.join(ROOT, 'web')

# Les densites Android et leur facteur par rapport au dp.
DENSITIES = {'mdpi': 1, 'hdpi': 1.5, 'xhdpi': 2, 'xxhdpi': 3, 'xxxhdpi': 4}

# Le cadrage A1, choisi par l'auteur : l'image presque entiere, en carre.
# Il remplit le calque de 108 dp ; le telephone n'en montre que le centre de
# 72 dp, dans la forme qu'il a choisie.
CROP_CENTER = (500, 470)
CROP_SIZE = 940

# Le calque adaptatif fait 108 dp, dont 72 visibles.
LAYER_DP = 108
VISIBLE_DP = 72

# L'ovale du logo, comme sur l'accueil, pour l'ecran de chargement ancien.
SPLASH_OVAL_DP = (180, 220)
SPLASH_BORDER_DP = 4

# Rendu des masques en plus grand, pour des bords lisses.
SUPERSAMPLING = 4


def load_layer():
    source = Image.open(SOURCE).convert('RGB')
    x, y = CROP_CENTER
    half = CROP_SIZE // 2
    return source.crop((x - half, y - half, x + half, y + half)), source


def with_pencil(layer):
    """Pose un crayon dans une pastille blanche, en bas a droite.

    La pastille reste dans le cercle sur de 66 dp : aucune forme d'icone ne
    peut la couper.
    """
    size = layer.width
    scale = size / LAYER_DP
    badge = Image.new('RGBA', (size * SUPERSAMPLING, size * SUPERSAMPLING))
    draw = ImageDraw.Draw(badge)
    s = scale * SUPERSAMPLING

    # Centre a 20 dp du centre du calque, rayon 12 : le bord de la pastille
    # reste a moins de 33 dp, dans le cercle que toute forme conserve.
    centre = (68 * s, 68 * s)
    radius = 12 * s
    draw.ellipse(
        (centre[0] - radius, centre[1] - radius,
         centre[0] + radius, centre[1] + radius),
        fill=(255, 255, 255, 255), outline=(31, 75, 122, 255),
        width=int(1.6 * s))

    # Le crayon, incline a 45 degres : un corps jaune, une gomme rose, une
    # pointe de bois et sa mine.
    def along(t, offset):
        # t le long du crayon (de la gomme a la mine), offset en travers.
        ux, uy = 0.7071, 0.7071   # direction : vers le bas a droite
        vx, vy = -0.7071, 0.7071  # travers
        start = (centre[0] - 8.5 * s * ux, centre[1] - 8.5 * s * uy)
        return (start[0] + t * s * ux + offset * s * vx,
                start[1] + t * s * uy + offset * s * vy)

    width = 3
    outline = (40, 40, 40, 255)
    draw.polygon([along(0, -width), along(3.2, -width),
                  along(3.2, width), along(0, width)],
                 fill=(240, 128, 150, 255), outline=outline)
    draw.polygon([along(3.2, -width), along(12, -width),
                  along(12, width), along(3.2, width)],
                 fill=(255, 196, 40, 255), outline=outline)
    draw.polygon([along(12, -width), along(17, 0), along(12, width)],
                 fill=(236, 200, 150, 255), outline=outline)
    draw.polygon([along(15.3, -1), along(17, 0), along(15.3, 1)],
                 fill=outline)

    badge = badge.resize((size, size), Image.LANCZOS)
    marked = layer.convert('RGBA')
    marked.alpha_composite(badge)
    return marked.convert('RGB')


def rounded_mask(size, radius_ratio):
    big = size * SUPERSAMPLING
    mask = Image.new('L', (big, big), 0)
    ImageDraw.Draw(mask).rounded_rectangle(
        (0, 0, big - 1, big - 1), radius=int(big * radius_ratio), fill=255)
    return mask.resize((size, size), Image.LANCZOS)


def visible_part(layer):
    """Le centre de 72 dp, celui que montre le telephone."""
    margin = layer.width * (LAYER_DP - VISIBLE_DP) // (2 * LAYER_DP)
    return layer.crop((margin, margin, layer.width - margin,
                       layer.height - margin))


def rounded_icon(layer, size):
    """L'icone deja decoupee : Android 7, et les icones ordinaires du web."""
    icon = visible_part(layer).resize((size, size), Image.LANCZOS)
    shaped = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    shaped.paste(icon, (0, 0), rounded_mask(size, 0.22))
    return shaped


def splash_oval(source, factor):
    width = round(SPLASH_OVAL_DP[0] * factor)
    height = round(SPLASH_OVAL_DP[1] * factor)
    border = round(SPLASH_BORDER_DP * factor)
    # Le logo en entier, recadre sur la hauteur de l'ovale, comme l'accueil.
    picture = source.resize((height, height), Image.LANCZOS)
    left = (height - width) // 2
    picture = picture.crop((left, 0, left + width, height))

    total = (width + 2 * border, height + 2 * border)
    big = (total[0] * SUPERSAMPLING, total[1] * SUPERSAMPLING)
    outer = Image.new('L', big, 0)
    ImageDraw.Draw(outer).ellipse((0, 0, big[0] - 1, big[1] - 1), fill=255)
    inner = Image.new('L', big, 0)
    b = border * SUPERSAMPLING
    ImageDraw.Draw(inner).ellipse((b, b, big[0] - 1 - b, big[1] - 1 - b),
                                  fill=255)
    outer = outer.resize(total, Image.LANCZOS)
    inner = inner.resize(total, Image.LANCZOS)

    oval = Image.new('RGBA', total, (255, 255, 255, 0))
    oval.paste((255, 255, 255, 255), (0, 0), outer)
    framed = Image.new('RGB', total)
    framed.paste(picture, (border, border))
    oval.paste(framed, (0, 0), inner)
    return oval


def save(image, *parts):
    path = os.path.join(*parts)
    os.makedirs(os.path.dirname(path), exist_ok=True)
    image.save(path, optimize=True)
    print(os.path.relpath(path, ROOT))


def main():
    layer, source = load_layer()
    author_layer = with_pencil(layer)

    for density, factor in DENSITIES.items():
        layer_px = round(LAYER_DP * factor)
        legacy_px = round(48 * factor)
        for res, picture in ((MAIN_RES, layer), (AUTHOR_RES, author_layer)):
            save(picture.resize((layer_px, layer_px), Image.LANCZOS),
                 res, f'mipmap-{density}', 'ic_launcher_foreground.png')
            save(rounded_icon(picture, legacy_px),
                 res, f'mipmap-{density}', 'ic_launcher.png')
        save(splash_oval(source, factor),
             MAIN_RES, f'drawable-{density}', 'splash_logo.png')

    # Le web sert l'outil d'auteur comme le jeu, depuis le meme dossier : une
    # seule icone, celle du jeu.
    save(rounded_icon(layer, 32), WEB, 'favicon.png')
    for size in (192, 512):
        save(rounded_icon(layer, size), WEB, 'icons', f'Icon-{size}.png')
        save(layer.resize((size, size), Image.LANCZOS),
             WEB, 'icons', f'Icon-maskable-{size}.png')


if __name__ == '__main__':
    main()
