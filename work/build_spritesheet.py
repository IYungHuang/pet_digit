import numpy as np
from PIL import Image

def load_rgba(p):
    return Image.open(p).convert('RGBA')

idle_base = load_rgba('work/screen1_bubble_cut_clean.png')
walk_base1 = load_rgba('work/screen3_walk_cut_clean.png')
walk_base2 = load_rgba('work/screen1_walk_cut_clean.png')
jump_base = load_rgba('work/screen2_jump_cut_clean.png')

# Let's inspect the bounding box and exact pixels of the tail in idle_base
# In idle_base: size is 89x93
# Tail is on the left side:
# Let's find tail bounds
arr_idle = np.array(idle_base)
# The tail is roughly x in [0, 24], y in [42, 68]
# Let's inspect non-transparent pixels in that region
print('idle_base shape:', arr_idle.shape)

FRAME_SIZE = 120
BASELINE_Y = 108

def make_frame(img, offset_x=0, offset_y=0, align_bottom=True):
    canvas = Image.new('RGBA', (FRAME_SIZE, FRAME_SIZE), (0, 0, 0, 0))
    w, h = img.size
    x = (FRAME_SIZE - w) // 2 + offset_x
    if align_bottom:
        y = BASELINE_Y - h + offset_y
    else:
        y = (FRAME_SIZE - h) // 2 + offset_y
    canvas.paste(img, (x, y), img)
    return canvas

# 1. IDLE FRAMES (4 frames: breathing + tail wag)
# Frame 0: Base pose
idle_0 = make_frame(idle_base)

# Frame 1: Breath rise (body goes up 1px), tail flicks up 1px
# To move tail, we can copy the tail region and shift it up by 1px
arr_f1 = arr_idle.copy()
# Tail region: x in [0, 26], y in [40, 72]
tail_patch = arr_f1[40:72, 0:26].copy()
arr_f1[40:72, 0:26] = 0
# paste shifted up by 2px, right by 1px
arr_f1[38:70, 1:27] = tail_patch
idle_1 = make_frame(Image.fromarray(arr_f1), offset_y=-1)

# Frame 2: Deep breath (body at -1px), tail flicks further or tilts
arr_f2 = arr_idle.copy()
tail_patch2 = arr_f2[40:72, 0:26].copy()
arr_f2[40:72, 0:26] = 0
arr_f2[39:71, 2:28] = tail_patch2
idle_2 = make_frame(Image.fromarray(arr_f2), offset_y=-1)

# Frame 3: Exhale (body returns to baseline, tail relaxes back)
arr_f3 = arr_idle.copy()
tail_patch3 = arr_f3[40:72, 0:26].copy()
arr_f3[40:72, 0:26] = 0
arr_f3[41:73, 0:26] = tail_patch3
idle_3 = make_frame(Image.fromarray(arr_f3), offset_y=0)

# 2. WALK FRAMES (4 frames: alternating four legs)
# In walk_base1 (85x85) & walk_base2 (112x68)
# walk_base1 has legs standing/contact.
# walk_base2 has paws extended.
# Let's align them on the ground baseline!
walk_0 = make_frame(walk_base1, offset_y=0)
walk_1 = make_frame(walk_base2, offset_y=0)

# For alternating steps 2 and 3:
# For walk_2: alternate leg posture from walk_base1
# In walk_base1, legs are at the bottom: y > 58
arr_wb1 = np.array(walk_base1)
arr_wb1_alt = arr_wb1.copy()
# swap the two front legs and two back legs
# Back legs are around x in [10, 45], front legs around x in [45, 78]
# For back legs, rear-most leg moves forward; front-most front leg moves back
legs_h = arr_wb1.shape[0]
legs_split = int(legs_h * 0.72)
# Slightly shift front and back legs in opposite directions
front_legs = arr_wb1_alt[legs_split:, 45:80].copy()
rear_legs = arr_wb1_alt[legs_split:, 10:45].copy()
arr_wb1_alt[legs_split:, 45:80] = 0
arr_wb1_alt[legs_split:, 10:45] = 0
# paste with swapped offsets
arr_wb1_alt[legs_split:, 41:76] = front_legs
arr_wb1_alt[legs_split:, 14:49] = rear_legs
walk_2 = make_frame(Image.fromarray(arr_wb1_alt), offset_y=0)

# For walk_3: alternate passing pose of walk_base2
arr_wb2 = np.array(walk_base2)
arr_wb2_alt = arr_wb2.copy()
legs_split2 = int(arr_wb2.shape[0] * 0.65)
# In walk_base2: front paw is stretched forward (x in [75, 110]), rear paw stretched back (x in [10, 40])
# We flip the extension:
front_paw = arr_wb2_alt[legs_split2:, 70:110].copy()
rear_paw = arr_wb2_alt[legs_split2:, 10:50].copy()
arr_wb2_alt[legs_split2:, 70:110] = 0
arr_wb2_alt[legs_split2:, 10:50] = 0
# place front paw lower/further back, rear paw further forward
arr_wb2_alt[legs_split2:, 60:100] = front_paw
arr_wb2_alt[legs_split2:, 20:60] = rear_paw
walk_3 = make_frame(Image.fromarray(arr_wb2_alt), offset_y=-1)

# 3. JUMP / POUNCE (2 frames)
jump_0 = make_frame(jump_base, align_bottom=False, offset_y=-8)
jump_1 = make_frame(jump_base, align_bottom=False, offset_y=-16)

# 4. OBSERVE (2 frames: looking up attentive)
# In walk_base1, corgi head is tilted, ears up.
obs_0 = make_frame(walk_base1, offset_y=0)
obs_1 = make_frame(walk_base1, offset_y=-2)

# Save individual frames to test
idle_0.save('work/test_idle_0.png')
idle_1.save('work/test_idle_1.png')
idle_2.save('work/test_idle_2.png')
idle_3.save('work/test_idle_3.png')
walk_0.save('work/test_walk_0.png')
walk_1.save('work/test_walk_1.png')
walk_2.save('work/test_walk_2.png')
walk_3.save('work/test_walk_3.png')
jump_0.save('work/test_jump_0.png')
jump_1.save('work/test_jump_1.png')
obs_0.save('work/test_obs_0.png')
obs_1.save('work/test_obs_1.png')

print('Test frames built.')
