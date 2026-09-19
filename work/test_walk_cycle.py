from PIL import Image
import numpy as np

w0 = Image.open('work/walk_0.png')
w2 = Image.open('work/walk_2.png')

# Create intermediate passing frames between w0 and w2:
# In w0 and w2, the head and body stay at steady height.
# In passing 1: dog bobs up by 1px
pass1 = Image.new('RGBA', (128, 128), (0, 0, 0, 0))
# Let's shift w0 up by 1px
arr_w0 = np.array(w0)
pass1 = Image.fromarray(arr_w0)
# Shift up by 1
pass1_shifted = Image.new('RGBA', (128, 128), (0, 0, 0, 0))
pass1_shifted.paste(pass1, (0, -1), pass1)

# In passing 2: dog bobs up by 1px from w2
pass2_shifted = Image.new('RGBA', (128, 128), (0, 0, 0, 0))
pass2_shifted.paste(w2, (0, -1), w2)

# Make 4-frame walk cycle: Step A -> Pass A -> Step B -> Pass B
walk_cycle = [w0, pass1_shifted, w2, pass2_shifted]
walk_cycle[0].save('work/preview_walk_smooth.gif', save_all=True, append_images=walk_cycle[1:], duration=150, loop=0)

# Run cycle: trot frames!
run_base = Image.open('work/screen1_walk_cut_clean.png')
# Place run_base on 128x128
r0 = Image.new('RGBA', (128, 128), (0, 0, 0, 0))
r0.paste(run_base, ((128 - run_base.size[0])//2, 114 - run_base.size[1]), run_base)
r1 = Image.new('RGBA', (128, 128), (0, 0, 0, 0))
r1.paste(run_base, ((128 - run_base.size[0])//2, 114 - run_base.size[1] - 2), run_base)
run_cycle = [r0, r1]
run_cycle[0].save('work/preview_run.gif', save_all=True, append_images=run_cycle[1:], duration=120, loop=0)

print('Walk smooth and run gifs generated.')
