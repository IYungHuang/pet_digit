import os
from PIL import Image
import numpy as np
from scipy.ndimage import binary_dilation, binary_fill_holes, label, binary_erosion

cat_img = Image.open('docs/截圖 2026-09-18 下午2.43.42.png').convert('RGB')
parrot_img = Image.open('docs/截圖 2026-09-18 下午2.44.35.png').convert('RGB')

FRAME_SIZE = 128
GROUND_Y = 114

def extract_perfect(img, crop_box, outline_thresh=85, bg_color=np.array([236, 235, 243])):
    im = img.crop(crop_box)
    arr = np.array(im)
    h, w, _ = arr.shape
    
    # 1. Detect dark outline
    is_outline = np.max(arr, axis=2) < outline_thresh
    
    # 2. Seal gaps with 3x3 dilation
    struct = np.ones((3, 3), dtype=bool)
    dilated = binary_dilation(is_outline, structure=struct, iterations=2)
    filled = binary_fill_holes(dilated)
    
    # 3. Erode back to restore original tight outline
    tight_filled = binary_erosion(filled, structure=struct, iterations=2)
    cat_mask = tight_filled | is_outline
    
    # 4. Filter out any stray emojis or speech bubbles by keeping largest connected component
    lbls, num = label(cat_mask)
    if num > 0:
        counts = np.bincount(lbls.ravel())
        counts[0] = 0
        cat_mask = (lbls == counts.argmax())
        
    # 5. Fill interior (eyes, white belly, etc.)
    cat_mask = binary_fill_holes(cat_mask)
    
    # 6. Remove any border pixels that are close to background color
    color_dist = np.linalg.norm(arr.astype(float) - bg_color, axis=2)
    mask_border = cat_mask & ~binary_erosion(cat_mask, structure=struct, iterations=1)
    cat_mask[mask_border & (color_dist < 35)] = False
    
    res = np.dstack([arr, (cat_mask * 255).astype(np.uint8)])
    out = Image.fromarray(res)
    bbox = out.getbbox()
    return out.crop(bbox) if bbox else out

def place_frame(sprite, target_h=86, offset_x=0, offset_y=0, align_bottom=True):
    w, h = sprite.size
    scale = target_h / float(h)
    new_w = max(1, int(round(w * scale)))
    new_h = max(1, int(round(h * scale)))
    resized = sprite.resize((new_w, new_h), Image.NEAREST)
    
    canvas = Image.new('RGBA', (FRAME_SIZE, FRAME_SIZE), (0, 0, 0, 0))
    x = (FRAME_SIZE - new_w) // 2 + offset_x
    if align_bottom:
        y = GROUND_Y - new_h + offset_y
    else:
        y = (FRAME_SIZE - new_h) // 2 + offset_y
    canvas.paste(resized, (x, y), resized)
    return canvas

# ----------------- 1. CAT SPRITES -----------------
c_stand = extract_perfect(cat_img, (100, 615, 230, 755))
c_run = extract_perfect(cat_img, (170, 940, 330, 1055))
c_crouch = extract_perfect(cat_img, (895, 940, 1055, 1100))
c_obs = extract_perfect(cat_img, (505, 760, 655, 955))

cat_frames = {
    'cat_idle_0.png': place_frame(c_stand, target_h=86),
    'cat_idle_1.png': place_frame(c_stand, target_h=86, offset_y=-1),
    'cat_idle_2.png': place_frame(c_crouch, target_h=82),
    'cat_idle_3.png': place_frame(c_stand, target_h=86),

    'cat_walk_0.png': place_frame(c_stand, target_h=86),
    'cat_walk_1.png': place_frame(c_crouch, target_h=82),
    'cat_walk_2.png': place_frame(c_stand, target_h=86, offset_y=-1),
    'cat_walk_3.png': place_frame(c_crouch, target_h=82),

    'cat_run_0.png': place_frame(c_run, target_h=72),
    'cat_run_1.png': place_frame(c_run, target_h=72, offset_y=-2),

    'cat_jump_0.png': place_frame(c_run, target_h=74, align_bottom=False, offset_y=-6),
    'cat_jump_1.png': place_frame(c_run, target_h=74, align_bottom=False, offset_y=-12),

    'cat_observe_0.png': place_frame(c_obs, target_h=88),
    'cat_observe_1.png': place_frame(c_obs, target_h=88, offset_y=-1),
}

# ----------------- 2. PARROT SPRITES -----------------
p_stand = extract_perfect(parrot_img, (100, 615, 230, 755))
p_run = extract_perfect(parrot_img, (170, 940, 330, 1055))
p_fly = extract_perfect(parrot_img, (510, 760, 660, 955))
p_perch_raw = extract_perfect(parrot_img, (880, 930, 1040, 1090))
# Trim perch branch off
p_perch = p_perch_raw.crop((0, 0, p_perch_raw.width, max(1, p_perch_raw.height - 18)))

parrot_frames = {
    'parrot_idle_0.png': place_frame(p_stand, target_h=84),
    'parrot_idle_1.png': place_frame(p_stand, target_h=84, offset_y=-1),
    'parrot_idle_2.png': place_frame(p_perch, target_h=80),
    'parrot_idle_3.png': place_frame(p_stand, target_h=84),

    'parrot_walk_0.png': place_frame(p_stand, target_h=84),
    'parrot_walk_1.png': place_frame(p_run, target_h=80),
    'parrot_walk_2.png': place_frame(p_stand, target_h=84, offset_y=-1),
    'parrot_walk_3.png': place_frame(p_run, target_h=80),

    'parrot_run_0.png': place_frame(p_run, target_h=80),
    'parrot_run_1.png': place_frame(p_fly, target_h=84, offset_y=-2),

    'parrot_jump_0.png': place_frame(p_fly, target_h=86, align_bottom=False, offset_y=-6),
    'parrot_jump_1.png': place_frame(p_fly, target_h=86, align_bottom=False, offset_y=-14),

    'parrot_observe_0.png': place_frame(p_perch, target_h=82),
    'parrot_observe_1.png': place_frame(p_perch, target_h=82, offset_y=-1),
}

# ----------------- 3. BUILD SPRITE SHEETS -----------------
def build_sheet(frames_dict, prefix):
    sheet = Image.new('RGBA', (FRAME_SIZE * 4, FRAME_SIZE * 5), (0, 0, 0, 0))
    # Row 0: idle 0, 1, 2, 3
    for col in range(4):
        sheet.paste(frames_dict[f'{prefix}_idle_{col}.png'], (col * FRAME_SIZE, 0))
    # Row 1: walk 0, 1, 2, 3
    for col in range(4):
        sheet.paste(frames_dict[f'{prefix}_walk_{col}.png'], (col * FRAME_SIZE, FRAME_SIZE))
    # Row 2: run 0, 1, run 0, 1
    sheet.paste(frames_dict[f'{prefix}_run_0.png'], (0, FRAME_SIZE * 2))
    sheet.paste(frames_dict[f'{prefix}_run_1.png'], (FRAME_SIZE * 2, FRAME_SIZE * 2))
    # Row 3: jump 0, 1, jump 0, 1
    sheet.paste(frames_dict[f'{prefix}_jump_0.png'], (0, FRAME_SIZE * 3))
    sheet.paste(frames_dict[f'{prefix}_jump_1.png'], (FRAME_SIZE * 2, FRAME_SIZE * 3))
    # Row 4: observe 0, 1, observe 0, 1
    sheet.paste(frames_dict[f'{prefix}_observe_0.png'], (0, FRAME_SIZE * 4))
    sheet.paste(frames_dict[f'{prefix}_observe_1.png'], (FRAME_SIZE * 2, FRAME_SIZE * 4))
    return sheet

cat_sheet = build_sheet(cat_frames, 'cat')
parrot_sheet = build_sheet(parrot_frames, 'parrot')

# Save to assets/pets/
out_dir = 'assets/pets'
for k, v in cat_frames.items():
    v.save(os.path.join(out_dir, k))
cat_sheet.save(os.path.join(out_dir, 'cat_sheet.png'))

for k, v in parrot_frames.items():
    v.save(os.path.join(out_dir, k))
parrot_sheet.save(os.path.join(out_dir, 'parrot_sheet.png'))

print('Successfully generated all clean Cat & Parrot assets in assets/pets/!')
