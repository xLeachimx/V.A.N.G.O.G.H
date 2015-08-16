require_relative 'gnn'

class Image
  attr_accessor :width
  attr_accessor :height
  attr_accessor :pixels
  def initialize filename
    fin = File.open(filename)
    contents = fin.read
    fin.close
    contents = contents.split("\n")
    contents.map!{|line| line.strip}
    contents.delete_if{|line| line == ''}
    contents.delete_if{|line| line[0] == '#'}
    size = contents[0...2]
    contents = contents[2...contents.length]
    @width = size[0].to_i
    @height = size[1].to_i
    @pixels = []
    tempList = []
    contents.each do |line|
      line = line.split(",")
      line.map!{|num| num.strip.to_i}
      @pixels.push(line)
    end
  end
end

def buildTestCases image
  cases = []
  image.pixels.each_index do |i|
    next if i == image.pixels.length-1
    input = decToBin(image.pixels[i][0]) + decToBin(image.pixels[i][1]) + decToBin(image.pixels[i][2])
    output = decToBin(image.pixels[i+1][0]) + decToBin(image.pixels[i+1][1]) + decToBin(image.pixels[i+1][2])
    cases.push(TestCase.new(input,output))
  end
  return cases
end

image = Image.new(ARGV[0])
cases = buildTestCases(image)
geneticPainterAlgorithm(cases)
