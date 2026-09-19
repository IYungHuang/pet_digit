import numpy as np
from PIL import Image

def load_rgba(path):
    return Image.open(path).convert('RGBA')

idle_base = load_rgba('work/screen1_bubble_cut_clean.png')
walk_stride1 = load_rgba('work/screen3_walk_cut_clean.png')
walk_stride2 = load_rgba('work/screen1_walk_cut_clean.png')
jump_base = load_rgba('work/screen2_jump_cut_clean.png')

FRAME_SIZE = 128
BASELINE_Y = 112  # Ground baseline for feet

def place_on_frame(img, align_bottom=True, offset_x=0, offset_y=0):
    canvas = Image.new('RGBA', (FRAME_SIZE, FRAME_SIZE), (0, 0, 0, 0))
    w, h = img.size
    x = (FRAME_SIZE - w) // 2 + offset_x
    if align_bottom:
        y = BASELINE_Y - h + offset_y
    else:
        y = (FRAME_SIZE - h) // 2 + offset_y
    canvas.paste(img, (x, y), img)
    return canvas

# Let's inspect idle frames
# Idle base
idle_f0 = place_on_frame(idle_base, offset_y=0)

# Idle f1: breathing up by 1px, tail shift
# We can shift the top half (head/ears/chest) up by 1-2 pixels
arr_idle = np.array(idle_base)
arr_f1 = arr_idle.copy()
# Shift head & ears (upper 60%) up by 2 pixels
split_y = int(arr_idle.shape[0] * 0.65)
arr_f1[:split_y] = np.roll(arr_f1[:split_y], -2, axis=0)
# Also wiggle tail (leftmost x, mid-height y)
# In idle_base, tail is on the left: x < 25, y between 40 and 70
tail_mask = np.zeros_like(arr_idle[:, :, 0], dtype=bool)
tail_mask[40:70, :25] = arr_idle[40:70, :25, 3] > 0
arr_f1[tail_mask] = np.roll(arr_f1[tail_mask], 1, axis=0)
idle_f1_img = Image.fromarray(arr_f1)
idle_f1 = place_on_frame(idle_f1_img, offset_y=0)

# Idle f2: return to base with slight tail flick
arr_f2 = arr_idle.copy()
arr_f2[tail_mask] = np.roll(arr_f2[tail_mask], -1, axis=0)
idle_f2 = place_on_frame(Image.fromarray(arr_f2), offset_y=0)

# Idle f3: subtle breath drop
idle_f3 = place_on_frame(idle_base, offset_y=1)

# Walk frames
# We want 4 frames of walk:
# walk_0: walk_stride1 (contact 1)
# walk_1: walk_stride2 (passing/trot 1)
# walk_2: walk_stride1 with legs shifted / passing
# walk_3: walk_stride2 with legs inverted for opposite step

# Let's place walk_stride1 and walk_stride2
walk_f0 = place_on_frame(walk_stride1, offset_y=0)
walk_f1 = place_on_frame(walk_stride2, offset_y=0)

# Invert/flip legs for walk_f2 and walk_f3:
# For walk_f2: walk_stride1 with feet shifted
arr_w1 = np.array(walk_stride1)
arr_w2 = arr_w1.copy()
# feet area: lower 25% of height
feet_y = int(arr_w1.shape[0] * 0.75)
arr_w2[feet_y:] = np.roll(arr_w2[feet_y:], 4, axis=1) # shift feet
walk_f2 = place_on_frame(Image.fromarray(arr_w2), offset_y=0)

# For walk_f3: walk_stride2 with alternate feet motion and slightly lowered body
arr_w3 = np.array(walk_stride2)
arr_w3_mod = arr_w3.copy()
# Legs area in stride 2:
feet_y_s2 = int(arr_w3.shape[0] * 0.70)
# swap left and right paws
paws_slice = arr_w3_mod[feet_y_s2:, :]
arr_w3_mod[feet_y_s2:, :] = np.roll(paws_slice, -6, axis=1)
walk_f3 = place_on_frame(Image.fromarray(arr_w3_mod), offset_y=0)

# Jump / pounce frames:
# f0: crouch/anticipation
# f1: leaping high (jump_base)
# f2: apex
# f3: landing
jump_f0 = place_on_frame(walk_stride1, offset_y=4) # crouch slightly
jump_f1 = place_on_frame(jump_base, align_bottom=False, offset_y=-10) # mid-air leap
jump_f2 = place_on_frame(jump_base, align_bottom=False, offset_y=-20) # apex
jump_f3 = place_on_frame(walk_stride2, offset_y=0) # touchdown

# Observe frames:
# Head looking up attentively
arr_obs = np.array(walk_stride1)
# Tilt head / perk ears
arr_obs[:int(arr_obs.shape[0]*0.55)] = np.roll(arr_obs[:int(arr_obs.shape[0]*0.55)], -2, axis=0)
obs_f0 = place_on_frame(Image.fromarray(arr_obs), offset_y=0)
obs_f1 = place_on_frame(Image.fromarray(arr_obs), offset_y=-1)

idle_f0.save('work/frame_idle_0.png')
idle_f1.save('work/frame_idle_1.png')
idle_f2.save('work/frame_idle_2.png')
idle_f3.save('work/frame_idle_3.png')

walk_f0.save('work/frame_walk_0.png')
walk_f1.save('work/frame_walk_1.png')
walk_f2.save('work/frame_walk_2.png')
walk_f3.save('work/frame_walk_3.png')

jump_f1.save('work/frame_jump_1.png')
obs_f0.save('work/frame_obs_0.png')
print('Frames generated successfully.')
