from PIL import Image
import numpy as np
from collections import deque
import os

parrot_img = Image.open('docs/截圖 2026-09-18 下午2.44.35.png').convert('RGB')
FRAME_SIZE = 128
GROUND_Y = 114

def extract_parrot(crop_box, clean_bottom_shadow=True):
    crop = parrot_img.crop(crop_box)
    arr = np.array(crop)
    h, w, _ = arr.shape
    
    visited = np.zeros((h, w), dtype=bool)
    is_bg = np.zeros((h, w), dtype=bool)
    
    q = deque()
    for x in range(w):
        q.append((0, x)); q.append((h-1, x))
    for y in range(h):
        q.append((y, 0)); q.append((y, w-1))
        
    while q:
        y, x = q.popleft()
        if visited[y, x]: continue
        visited[y, x] = True
        
        r, g, b = arr[y, x]
        is_outline = (max(r, g, b) < 65)
        is_red = (r > 120 and g < 100)
        is_yellow = (r > 150 and g > 130 and b < 100)
        is_blue = (b > 130 and r < 100)
        is_pet = is_outline or is_red or is_yellow or is_blue
        
        # Don't treat bottom contact shadow as pet outline if it's below the feet
        if clean_bottom_shadow and y >= h - 10 and max(r, g, b) < 65:
            is_pet = False
            
        if not is_pet:
            is_bg[y, x] = True
            for ny, nx in [(y-1, x), (y+1, x), (y, x-1), (y, x+1)]:
                if 0 <= ny < h and 0 <= nx < w and not visited[ny, nx]:
                    q.append((ny, nx))
                    
    # Also clean enclosed background between legs if any (neutral gray/white)
    # Anything not visited, but neutral white/gray with R>200, G>200, B>200 and low saturation
    for y in range(h):
        for x in range(w):
            if not is_bg[y, x]:
                r, g, b = arr[y, x]
                sat = int(max(r, g, b)) - int(min(r, g, b))
                if r > 195 and g > 190 and b > 195 and sat < 20 and y > h // 2:
                    is_bg[y, x] = True

    out = arr.copy()
    res = np.dstack([out, (~is_bg * 255).astype(np.uint8)])
    im = Image.fromarray(res)
    bbox = im.getbbox()
    return im.crop(bbox) if bbox else im

def place_frame(img, align_bottom=True, offset_x=0, offset_y=0, target_h=86):
    w, h = img.size
    scale = target_h / float(h)
    new_w = max(1, int(round(w * scale)))
    new_h = max(1, int(round(h * scale)))
    resized = img.resize((new_w, new_h), Image.NEAREST)
    
    canvas = Image.new('RGBA', (FRAME_SIZE, FRAME_SIZE), (0, 0, 0, 0))
    x = (FRAME_SIZE - new_w) // 2 + offset_x
    if align_bottom:
        y = GROUND_Y - new_h + offset_y
    else:
        y = (FRAME_SIZE - new_h) // 2 + offset_y
    canvas.paste(resized, (x, y), resized)
    return canvas

p_stand = extract_parrot((120, 645, 220, 765))
p_chase = extract_parrot((205, 955, 335, 1065))
p_fly = extract_parrot((525, 810, 660, 925))
p_perch = extract_parrot((885, 945, 1005, 1065))

parrot_idle_0 = place_frame(p_stand, offset_y=0, target_h=86)
parrot_idle_1 = place_frame(p_stand, offset_y=-1, target_h=86)
parrot_idle_2 = place_frame(p_perch, offset_y=0, target_h=86)
parrot_idle_3 = place_frame(p_stand, offset_y=0, target_h=86)

parrot_walk_0 = place_frame(p_chase, offset_y=0, target_h=84)
parrot_walk_1 = place_frame(p_stand, offset_y=-1, target_h=86)
parrot_walk_2 = place_frame(p_chase, offset_y=-2, target_h=84)
parrot_walk_3 = place_frame(p_stand, offset_y=0, target_h=86)

parrot_run_0 = place_frame(p_chase, offset_y=0, target_h=84)
parrot_run_1 = place_frame(p_fly, offset_y=-3, target_h=88)

parrot_jump_0 = place_frame(p_fly, align_bottom=False, offset_y=-8, target_h=88)
parrot_jump_1 = place_frame(p_fly, align_bottom=False, offset_y=-16, target_h=88)

parrot_obs_0 = place_frame(p_fly, offset_y=0, target_h=88)
parrot_obs_1 = place_frame(p_perch, offset_y=-1, target_h=86)

parrot_assets = {
    'parrot_idle_0.png': parrot_idle_0, 'parrot_idle_1.png': parrot_idle_1, 'parrot_idle_2.png': parrot_idle_2, 'parrot_idle_3.png': parrot_idle_3,
    'parrot_walk_0.png': parrot_walk_0, 'parrot_walk_1.png': parrot_walk_1, 'parrot_walk_2.png': parrot_walk_2, 'parrot_walk_3.png': parrot_walk_3,
    'parrot_run_0.png': parrot_run_0, 'parrot_run_1.png': parrot_run_1,
    'parrot_jump_0.png': parrot_jump_0, 'parrot_jump_1.png': parrot_jump_1,
    'parrot_observe_0.png': parrot_obs_0, 'parrot_observe_1.png': parrot_obs_1,
}

for name, im in parrot_assets.items():
    im.save(os.path.join('assets/pets', name))

# Parrot Sprite Sheet (512x640)
sheet = Image.new('RGBA', (512, 640), (0, 0, 0, 0))
sheet.paste(parrot_idle_0, (0, 0)); sheet.paste(parrot_idle_1, (128, 0))
sheet.paste(parrot_idle_2, (256, 0)); sheet.paste(parrot_idle_3, (384, 0))
sheet.paste(parrot_walk_0, (0, 128)); sheet.paste(parrot_walk_1, (128, 128))
sheet.paste(parrot_walk_2, (256, 128)); sheet.paste(parrot_walk_3, (384, 128))
sheet.paste(parrot_run_0, (0, 256)); sheet.paste(parrot_run_1, (256, 256))
sheet.paste(parrot_jump_0, (0, 384)); sheet.paste(parrot_jump_1, (256, 384))
sheet.paste(parrot_obs_0, (0, 512)); sheet.paste(parrot_obs_1, (256, 512))
sheet.save('assets/pets/parrot_sheet.png')

print('Parrot assets generated perfectly!')
