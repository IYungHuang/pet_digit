import numpy as np
from PIL import Image
import scipy.ndimage as ndi

def load_rgba(p):
    return Image.open(p).convert('RGBA')

idle_base = load_rgba('work/screen1_bubble_cut_clean.png')
walk_step_a = load_rgba('work/crop_bottom_clean.png')
walk_step_b = load_rgba('work/screen3_walk_cut_clean.png')
walk_trot = load_rgba('work/screen1_walk_cut_clean.png')
jump_base = load_rgba('work/screen2_jump_cut_clean.png')

# Clean tiny artifact above ear in walk_step_a if any:
arr_a = np.array(walk_step_a)
# Remove anything above y=12 that's disconnected
alpha = arr_a[:, :, 3] > 0
labels, num = ndi.label(alpha)
counts = np.bincount(labels.ravel())
counts[0] = 0
arr_a[labels != counts.argmax()] = 0
walk_step_a = Image.fromarray(arr_a)
walk_step_a = walk_step_a.crop(walk_step_a.getbbox())

FRAME_W = 128
FRAME_H = 128
GROUND_Y = 114

def place_frame(img, offset_x=0, offset_y=0, align_bottom=True):
    canvas = Image.new('RGBA', (FRAME_W, FRAME_H), (0, 0, 0, 0))
    w, h = img.size
    x = (FRAME_W - w) // 2 + offset_x
    if align_bottom:
        y = GROUND_Y - h + offset_y
    else:
        y = (FRAME_H - h) // 2 + offset_y
    canvas.paste(img, (x, y), img)
    return canvas

# --- 1. IDLE FRAMES (4 frames) ---
# Frame 0: Rest pose
idle_0 = place_frame(idle_base, offset_y=0)

# Frame 1: Inhale (chest rises 1px, tail wags slightly)
arr_id = np.array(idle_base)
arr_id_w1 = arr_id.copy()
# Tail region in idle_base: x in [0, 24], y in [42, 65]
# Let's shift the tail pixels slightly up & left by 1px
tail_mask = np.zeros_like(arr_id[:, :, 0], dtype=bool)
tail_mask[42:66, 0:22] = arr_id[42:66, 0:22, 3] > 0
# Fill underneath with coat color [207, 120, 59, 255]
arr_id_w1[tail_mask] = [207, 120, 59, 255]
# Paste shifted tail
tail_pixels = arr_id[42:66, 0:22].copy()
arr_id_w1[40:64, 0:22] = np.where(tail_pixels[:, :, 3:4] > 0, tail_pixels, arr_id_w1[40:64, 0:22])
idle_1 = place_frame(Image.fromarray(arr_id_w1), offset_y=-1)

# Frame 2: Hold inhale (body at -1px, tail wags slightly right)
arr_id_w2 = arr_id.copy()
arr_id_w2[tail_mask] = [207, 120, 59, 255]
arr_id_w2[43:67, 1:23] = np.where(tail_pixels[:, :, 3:4] > 0, tail_pixels, arr_id_w2[43:67, 1:23])
idle_2 = place_frame(Image.fromarray(arr_id_w2), offset_y=-1)

# Frame 3: Exhale (body returns to baseline, tail relaxes)
idle_3 = place_frame(idle_base, offset_y=0)

# --- 2. WALK FRAMES (4 frames) ---
# Frame 0: Step A (paws contact 1)
# Frame 1: Trot / pass (paw lifted, happy)
# Frame 2: Step B (paws contact 2 - alternate step)
# Frame 3: Intermediate passing step (slight bob)
# Scale walk_step_a, walk_step_b, walk_trot so their body heights match nicely
# Let's inspect heights:
print('Heights: step_a:', walk_step_a.size, 'step_b:', walk_step_b.size, 'trot:', walk_trot.size)

# Normalize step sizes to visual consistency
walk_0 = place_frame(walk_step_a, offset_y=0)
walk_1 = place_frame(walk_trot, offset_y=0)
walk_2 = place_frame(walk_step_b, offset_y=0)
walk_3 = place_frame(walk_step_a, offset_y=-2) # passing step with slight foot lift

# --- 3. JUMP / POUNCE FRAMES (2 frames) ---
jump_0 = place_frame(jump_base, align_bottom=False, offset_y=-6)
jump_1 = place_frame(jump_base, align_bottom=False, offset_y=-14)

# --- 4. OBSERVE FRAMES (2 frames) ---
obs_0 = place_frame(walk_step_b, offset_y=0)
obs_1 = place_frame(walk_step_b, offset_y=-1)

# Save frames to work
frames = {
    'idle_0': idle_0, 'idle_1': idle_1, 'idle_2': idle_2, 'idle_3': idle_3,
    'walk_0': walk_0, 'walk_1': walk_1, 'walk_2': walk_2, 'walk_3': walk_3,
    'jump_0': jump_0, 'jump_1': jump_1,
    'obs_0': obs_0, 'obs_1': obs_1,
}

for k, f in frames.items():
    f.save(f'work/{k}.png')

print('All frames saved successfully.')
