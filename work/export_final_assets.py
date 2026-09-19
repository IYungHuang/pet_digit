from PIL import Image
import numpy as np
import os

idle_base = Image.open('work/screen1_bubble_cut_clean.png').convert('RGBA')
walk_step_a = Image.open('work/walk_step_a_perfect.png').convert('RGBA')
walk_step_b = Image.open('work/screen3_walk_cut_clean.png').convert('RGBA')
trot_base = Image.open('work/screen1_walk_cut_clean.png').convert('RGBA')
jump_base = Image.open('work/screen2_jump_cut_clean.png').convert('RGBA')

FRAME_SIZE = 128
GROUND_Y = 114

def make_canvas(img, align_bottom=True, offset_x=0, offset_y=0):
    canvas = Image.new('RGBA', (FRAME_SIZE, FRAME_SIZE), (0, 0, 0, 0))
    w, h = img.size
    x = (FRAME_SIZE - w) // 2 + offset_x
    if align_bottom:
        y = GROUND_Y - h + offset_y
    else:
        y = (FRAME_SIZE - h) // 2 + offset_y
    canvas.paste(img, (x, y), img)
    return canvas

# 1. Build IDLE frames (4 frames: breathing + tail wiggle)
idle_0 = make_canvas(idle_base)

arr_id = np.array(idle_base)
arr_id_1 = arr_id.copy()
tail_mask = np.zeros_like(arr_id[:, :, 0], dtype=bool)
tail_mask[42:66, 0:22] = arr_id[42:66, 0:22, 3] > 0
arr_id_1[tail_mask] = [207, 120, 59, 255] # coat fill
tail_p = arr_id[42:66, 0:22].copy()
arr_id_1[40:64, 0:22] = np.where(tail_p[:, :, 3:4] > 0, tail_p, arr_id_1[40:64, 0:22])
idle_1 = make_canvas(Image.fromarray(arr_id_1), offset_y=-1)

arr_id_2 = arr_id.copy()
arr_id_2[tail_mask] = [207, 120, 59, 255]
arr_id_2[43:67, 1:23] = np.where(tail_p[:, :, 3:4] > 0, tail_p, arr_id_2[43:67, 1:23])
idle_2 = make_canvas(Image.fromarray(arr_id_2), offset_y=-1)

idle_3 = make_canvas(idle_base, offset_y=0)

# 2. Build WALK frames (4 frames: alternating paws)
w0 = make_canvas(walk_step_a)
w1 = make_canvas(walk_step_a, offset_y=-1)
w2 = make_canvas(walk_step_b)
w3 = make_canvas(walk_step_b, offset_y=-1)

# 3. Build RUN frames (2 frames)
r0 = make_canvas(trot_base, offset_y=0)
r1 = make_canvas(trot_base, offset_y=-2)

# 4. Build JUMP / POUNCE frames (2 frames)
j0 = make_canvas(jump_base, align_bottom=False, offset_y=-8)
j1 = make_canvas(jump_base, align_bottom=False, offset_y=-16)

# 5. Build OBSERVE frames (2 frames)
ob0 = make_canvas(walk_step_b, offset_y=0)
ob1 = make_canvas(walk_step_b, offset_y=-1)

out_dir = 'assets/pets'
os.makedirs(out_dir, exist_ok=True)

asset_map = {
    'corgi_idle_0.png': idle_0,
    'corgi_idle_1.png': idle_1,
    'corgi_idle_2.png': idle_2,
    'corgi_idle_3.png': idle_3,
    'corgi_walk_0.png': w0,
    'corgi_walk_1.png': w1,
    'corgi_walk_2.png': w2,
    'corgi_walk_3.png': w3,
    'corgi_run_0.png': r0,
    'corgi_run_1.png': r1,
    'corgi_jump_0.png': j0,
    'corgi_jump_1.png': j1,
    'corgi_observe_0.png': ob0,
    'corgi_observe_1.png': ob1,
}

for filename, img in asset_map.items():
    p = os.path.join(out_dir, filename)
    img.save(p)

# Combined Sprite Sheet (4 cols, 5 rows)
sheet = Image.new('RGBA', (FRAME_SIZE * 4, FRAME_SIZE * 5), (0, 0, 0, 0))

sheet.paste(idle_0, (0 * FRAME_SIZE, 0 * FRAME_SIZE))
sheet.paste(idle_1, (1 * FRAME_SIZE, 0 * FRAME_SIZE))
sheet.paste(idle_2, (2 * FRAME_SIZE, 0 * FRAME_SIZE))
sheet.paste(idle_3, (3 * FRAME_SIZE, 0 * FRAME_SIZE))

sheet.paste(w0, (0 * FRAME_SIZE, 1 * FRAME_SIZE))
sheet.paste(w1, (1 * FRAME_SIZE, 1 * FRAME_SIZE))
sheet.paste(w2, (2 * FRAME_SIZE, 1 * FRAME_SIZE))
sheet.paste(w3, (3 * FRAME_SIZE, 1 * FRAME_SIZE))

sheet.paste(r0, (0 * FRAME_SIZE, 2 * FRAME_SIZE))
sheet.paste(r1, (1 * FRAME_SIZE, 2 * FRAME_SIZE))
sheet.paste(r0, (2 * FRAME_SIZE, 2 * FRAME_SIZE))
sheet.paste(r1, (3 * FRAME_SIZE, 2 * FRAME_SIZE))

sheet.paste(j0, (0 * FRAME_SIZE, 3 * FRAME_SIZE))
sheet.paste(j1, (1 * FRAME_SIZE, 3 * FRAME_SIZE))
sheet.paste(j0, (2 * FRAME_SIZE, 3 * FRAME_SIZE))
sheet.paste(j1, (3 * FRAME_SIZE, 3 * FRAME_SIZE))

sheet.paste(ob0, (0 * FRAME_SIZE, 4 * FRAME_SIZE))
sheet.paste(ob1, (1 * FRAME_SIZE, 4 * FRAME_SIZE))
sheet.paste(ob0, (2 * FRAME_SIZE, 4 * FRAME_SIZE))
sheet.paste(ob1, (3 * FRAME_SIZE, 4 * FRAME_SIZE))

sheet_path = os.path.join(out_dir, 'corgi_sheet.png')
sheet.save(sheet_path)
print('Exported all assets cleanly to assets/pets/.')
