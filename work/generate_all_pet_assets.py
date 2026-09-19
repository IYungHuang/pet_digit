from PIL import Image
import numpy as np
from scipy.ndimage import binary_dilation, binary_fill_holes, label
import os

cat_img = Image.open('docs/截圖 2026-09-18 下午2.43.42.png').convert('RGB')
parrot_img = Image.open('docs/截圖 2026-09-18 下午2.44.35.png').convert('RGB')

FRAME_SIZE = 128
GROUND_Y = 114

def extract_sprite_clean(img, crop_box, outline_thresh=65, min_area=800):
    crop = img.crop(crop_box)
    arr = np.array(crop)
    # Outline is dark
    is_outline = np.max(arr, axis=2) < outline_thresh
    
    # Dilate outline with 3x3 to seal any 8-connected diagonal gaps
    struct = np.ones((3, 3), dtype=bool)
    outline_closed = binary_dilation(is_outline, structure=struct)
    filled = binary_fill_holes(outline_closed)
    
    # Keep only the largest connected component
    lbls, num = label(filled)
    if num > 0:
        counts = np.bincount(lbls.ravel())
        counts[0] = 0
        largest_label = counts.argmax()
        filled = (lbls == largest_label)
        
    out = arr.copy()
    res = np.dstack([out, (filled * 255).astype(np.uint8)])
    im = Image.fromarray(res)
    bbox = im.getbbox()
    return im.crop(bbox) if bbox else im

def extract_dark_bg_sprite(img, crop_box):
    crop = img.crop(crop_box)
    arr = np.array(crop)
    # Dark bg is R,G,B < 45
    fg = (arr[:, :, 0] > 45) | (arr[:, :, 1] > 45) | (arr[:, :, 2] > 45)
    filled = binary_fill_holes(fg)
    res = np.dstack([arr, (filled * 255).astype(np.uint8)])
    im = Image.fromarray(res)
    bbox = im.getbbox()
    return im.crop(bbox) if bbox else im

def place_on_frame(img, align_bottom=True, offset_x=0, offset_y=0, target_h=86):
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

# --- 1. CAT FRAMES ---
c_stand = extract_sprite_clean(cat_img, (95, 615, 230, 755)) # Bubble cat
c_run = extract_sprite_clean(cat_img, (165, 935, 335, 1065))   # Running cat
c_walk = extract_sprite_clean(cat_img, (885, 940, 1055, 1105)) # Walk cat
c_obs = extract_sprite_clean(cat_img, (520, 785, 650, 950))    # Observe cat
c_sit = extract_dark_bg_sprite(cat_img, (40, 120, 175, 260))   # Sit cat

# Build 4 Idle frames (breathing + tail)
cat_idle_0 = place_on_frame(c_stand, offset_y=0)
cat_idle_1 = place_on_frame(c_stand, offset_y=-1)
cat_idle_2 = place_on_frame(c_sit, offset_y=0, target_h=88)
cat_idle_3 = place_on_frame(c_stand, offset_y=0)

# Build 4 Walk frames (alternating prowl)
cat_walk_0 = place_on_frame(c_walk, offset_y=0, target_h=76)
cat_walk_1 = place_on_frame(c_stand, offset_y=-1)
cat_walk_2 = place_on_frame(c_walk.transpose(Image.FLIP_LEFT_RIGHT), offset_y=0, target_h=76).transpose(Image.FLIP_LEFT_RIGHT)
cat_walk_3 = place_on_frame(c_stand, offset_y=0)

# Build 2 Run frames (leaping stride)
cat_run_0 = place_on_frame(c_run, offset_y=0, target_h=62)
cat_run_1 = place_on_frame(c_run, offset_y=-2, target_h=62)

# Build 2 Jump frames
cat_jump_0 = place_on_frame(c_run, align_bottom=False, offset_y=-8, target_h=66)
cat_jump_1 = place_on_frame(c_run, align_bottom=False, offset_y=-16, target_h=66)

# Build 2 Observe frames (looking up at GIF)
cat_obs_0 = place_on_frame(c_obs, offset_y=0, target_h=86)
cat_obs_1 = place_on_frame(c_obs, offset_y=-1, target_h=86)

cat_assets = {
    'cat_idle_0.png': cat_idle_0, 'cat_idle_1.png': cat_idle_1, 'cat_idle_2.png': cat_idle_2, 'cat_idle_3.png': cat_idle_3,
    'cat_walk_0.png': cat_walk_0, 'cat_walk_1.png': cat_walk_1, 'cat_walk_2.png': cat_walk_2, 'cat_walk_3.png': cat_walk_3,
    'cat_run_0.png': cat_run_0, 'cat_run_1.png': cat_run_1,
    'cat_jump_0.png': cat_jump_0, 'cat_jump_1.png': cat_jump_1,
    'cat_observe_0.png': cat_obs_0, 'cat_observe_1.png': cat_obs_1,
}

for name, im in cat_assets.items():
    im.save(os.path.join('assets/pets', name))

# Cat Sprite Sheet (512x640)
cat_sheet = Image.new('RGBA', (512, 640), (0, 0, 0, 0))
cat_sheet.paste(cat_idle_0, (0, 0)); cat_sheet.paste(cat_idle_1, (128, 0))
cat_sheet.paste(cat_idle_2, (256, 0)); cat_sheet.paste(cat_idle_3, (384, 0))
cat_sheet.paste(cat_walk_0, (0, 128)); cat_sheet.paste(cat_walk_1, (128, 128))
cat_sheet.paste(cat_walk_2, (256, 128)); cat_sheet.paste(cat_walk_3, (384, 128))
cat_sheet.paste(cat_run_0, (0, 256)); cat_sheet.paste(cat_run_1, (256, 256))
cat_sheet.paste(cat_jump_0, (0, 384)); cat_sheet.paste(cat_jump_1, (256, 384))
cat_sheet.paste(cat_obs_0, (0, 512)); cat_sheet.paste(cat_obs_1, (256, 512))
cat_sheet.save('assets/pets/cat_sheet.png')

# Cat Paw (16x16)
c_paw_crop = extract_dark_bg_sprite(cat_img, (40, 280, 85, 325))
c_paw_16 = Image.new('RGBA', (16, 16), (0, 0, 0, 0))
cp_resized = c_paw_crop.resize((12, 12), Image.NEAREST)
c_paw_16.paste(cp_resized, (2, 2), cp_resized)
c_paw_16.save('assets/pets/cat_paw.png')

# --- 2. PARROT FRAMES ---
p_stand = extract_sprite_clean(parrot_img, (120, 645, 220, 765))  # Bubble parrot
p_chase = extract_sprite_clean(parrot_img, (205, 955, 335, 1065)) # Chase/strut parrot
p_fly = extract_sprite_clean(parrot_img, (525, 810, 660, 925))    # Hover/dance parrot
p_perch = extract_sprite_clean(parrot_img, (885, 945, 1005, 1065))# Perch parrot
p_logo = extract_dark_bg_sprite(parrot_img, (25, 75, 150, 200))   # Logo parrot

parrot_idle_0 = place_on_frame(p_stand, offset_y=0, target_h=86)
parrot_idle_1 = place_on_frame(p_logo, offset_y=0, target_h=86)
parrot_idle_2 = place_on_frame(p_perch, offset_y=0, target_h=86)
parrot_idle_3 = place_on_frame(p_stand, offset_y=0, target_h=86)

parrot_walk_0 = place_on_frame(p_chase, offset_y=0, target_h=84)
parrot_walk_1 = place_on_frame(p_stand, offset_y=-1, target_h=86)
parrot_walk_2 = place_on_frame(p_chase, offset_y=-2, target_h=84)
parrot_walk_3 = place_on_frame(p_stand, offset_y=0, target_h=86)

parrot_run_0 = place_on_frame(p_chase, offset_y=0, target_h=84)
parrot_run_1 = place_on_frame(p_fly, offset_y=-3, target_h=88)

parrot_jump_0 = place_on_frame(p_fly, align_bottom=False, offset_y=-8, target_h=88)
parrot_jump_1 = place_on_frame(p_fly, align_bottom=False, offset_y=-16, target_h=88)

parrot_obs_0 = place_on_frame(p_fly, offset_y=0, target_h=88)
parrot_obs_1 = place_on_frame(p_perch, offset_y=-1, target_h=86)

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
parrot_sheet = Image.new('RGBA', (512, 640), (0, 0, 0, 0))
parrot_sheet.paste(parrot_idle_0, (0, 0)); parrot_sheet.paste(parrot_idle_1, (128, 0))
parrot_sheet.paste(parrot_idle_2, (256, 0)); parrot_sheet.paste(parrot_idle_3, (384, 0))
parrot_sheet.paste(parrot_walk_0, (0, 128)); parrot_sheet.paste(parrot_walk_1, (128, 128))
parrot_sheet.paste(parrot_walk_2, (256, 128)); parrot_sheet.paste(parrot_walk_3, (384, 128))
parrot_sheet.paste(parrot_run_0, (0, 256)); parrot_sheet.paste(parrot_run_1, (256, 256))
parrot_sheet.paste(parrot_jump_0, (0, 384)); parrot_sheet.paste(parrot_jump_1, (256, 384))
parrot_sheet.paste(parrot_obs_0, (0, 512)); parrot_sheet.paste(parrot_obs_1, (256, 512))
parrot_sheet.save('assets/pets/parrot_sheet.png')

# Parrot Feather (16x16)
p_feather_crop = extract_dark_bg_sprite(parrot_img, (55, 260, 110, 320))
p_feather_16 = Image.new('RGBA', (16, 16), (0, 0, 0, 0))
pf_resized = p_feather_crop.resize((14, 14), Image.NEAREST)
p_feather_16.paste(pf_resized, (1, 1), pf_resized)
p_feather_16.save('assets/pets/parrot_feather.png')

print('All Cat and Parrot assets generated cleanly and saved to assets/pets!')
