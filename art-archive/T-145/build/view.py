import sys
from PIL import Image
im=Image.open(sys.argv[1]).convert('RGBA')
b=Image.new('RGBA',im.size,(220,220,226,255)); b.alpha_composite(im); b.resize((im.width*4,im.height*4),Image.NEAREST).save(sys.argv[2])
