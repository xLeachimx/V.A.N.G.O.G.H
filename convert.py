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

def toPiFile(image):
  image = deepcopy(image)
  width = image.width
  height = image.height
  image = image.load()
  result = ''
  result += str(width) + "\n"
  result += str(height) + "\n"
  for x in xrange(width):
    for y in xrange(height):
      result += str(image[x,y][0]) + ','
      result += str(image[x,y][1]) + ','
      result += str(image[x,y][2])
      result += "\n"
  return result

source = Image.open(sys.argv[1])
fout = open(sys.argv[2], 'w')
fout.write(toPiFile(source))
