from PIL import Image, ImageMath
from random import randint
import sys
from copy import deepcopy
from math import *
def negative(image):
  neg = deepcopy(image)
  negPixels = neg.load()
  for x in xrange(neg.width):
    for y in xrange(neg.height):
      negPixels[x,y] = pixelDiff((255,255,255),negPixels[x,y])
  return neg

def fromPiFile(filename):
  fin = open(filename,'r')
  width = int(fin.readline())
  height = int(fin.readline())
  image = Image.new('RGB',(width,height))
  imagePix = image.load()
  for x in xrange(width):
    for y in xrange(height):
      pixel = fin.readline()
      pixel = pixel.split(',')
      pixel[0] = int(pixel[0])
      pixel[1] = int(pixel[1])
      pixel[2] = int(pixel[2])
      imagePix[x,y] = (pixel[0],pixel[1],pixel[2])
  fin.close()
  return image



fromPiFile(sys.argv[1]).save(sys.argv[2])
