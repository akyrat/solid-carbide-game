import sys
from PIL import Image
# usage: strip.py out.png dir prefix [n]
out,d,pre=sys.argv[1:4]; n=int(sys.argv[4]) if len(sys.argv)>4 else 8
k=6
im=Image.new('RGBA',(n*48*k,48*k),(14,14,26,255))
for i in range(n): im.alpha_composite(Image.open(f'{d}/{pre}_{i}.png').convert('RGBA').resize((48*k,48*k),Image.NEAREST),(i*48*k,0))
im.save(out)
