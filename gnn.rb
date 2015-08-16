# required components

class GeneticNeuron
  attr_accessor :bias
  attr_accessor :recurrent
  attr_reader :activation
  attr_reader :input
  attr_accessor :weights
  def initialize bias, recurrent, weights
    @bias = bias
    @recurrent = recurrent
    @weights = weights.clone
    @activation = 0.0
  end

  def clear_all
    @activation = 0.0
    @input = 0.0
  end

  def clear_input
    @input = 0.0
  end

  def run_cycle
    @input += @activation * @recurrent
    @input += @bias
    @activation = activationFunction(@input)
    clear_input
    return @weights.map{|w| w*@activation}
  end

  def addInput input
    @input += input
  end

  private

  def activationFunction input
    return 1/(1+(Math.exp(-input)))
  end
end

class GeneticNeuralNetwork
  def initialize layers, neurons
    @net = []
    sliceStart = 0
    sliceEnd = 0
    layers.each_index do |i|
      sliceEnd = sliceStart + layers[i]
      @net.push(deepcopyNeurons(neurons[sliceStart...sliceEnd]))
      sliceStart = sliceEnd
    end
  end

  def run_cycle input
    clear_input
    @net[0].each_index do |i|
      @net[0][i].addInput(input[i])
    end

    @net.each_index do |i|
      @net[i].each_index do |j|
        nextInput = @net[i][j].run_cycle
        next if i == @net.length-1
        nextInput.each_index do |k|
          @net[i+1][k].addInput(nextInput[k])
        end
      end
    end

    output = []
    @net[-1].each do |neuron|
      output.push neuron.activation
    end
    return output
  end

  def run_all inputs
    clear_all
    inputs.each do |input|
      run_cycle input
    end
  end

  def loss input, expected
    lossTotal = 0.0
    output  = run_cycle(input)
    output.each_index do |i|
      lossTotal += (expected[i] - output[i])**2
    end
    return lossTotal
  end

  def loss_all inputs, expectations
    totalLoss = 0.0
    inputs.each_index do |i|
      totalLoss += loss(inputs[i],expectations[i])
    end
    return totalLoss
  end

  def clear_all
    @net.each do |layer|
      layer.each do |neuron|
        neuron.clear_all
      end
    end
  end

  def clear_input
   @net.each do |layer|
      layer.each do |neuron|
        neuron.clear_input
      end
    end
  end
end

# Generation and mutation

class Organism
  attr_accessor :neurons
  attr_accessor :fitness
  attr_accessor :assessed

  def initialize neurons
    @fitness = 0.0
    @neurons = neurons
    @assessed = false
  end
end

def randomWeight
  weight = Random.rand()*2.0
  weight -= 1.0
  return weight
end

def randomNeuron toSize
  weights = []
  toSize.times do
    weights.push(randomWeight())
  end
  bias = randomWeight()
  recurrent = randomWeight()
  result = GeneticNeuron.new(bias,recurrent,weights)
  return result
end

def generateNeuronLayer size, toSize
  result = []
  size.times do
    result.push(randomNeuron(toSize))
  end
  return result
end

def mutateNeuron neuron
  neuron.bias += (Random.rand()-0.5)*0.5
  neuron.recurrent += (Random.rand()-0.5)*0.5
  neuron.weights.map!{|w| w += (Random.rand()-0.5)*0.5}
  return neuron
end

def mateNeurons org1, org2
  crosspoint = Random.rand(org1.length)
  child1 = org1[0...crosspoint] + org2[crosspoint...org2.length]
  child2 = org2[0...crosspoint] + org1[crosspoint...org2.length]
  return [child1,child2]
end

def mutateNeurons neurons, chance
  neurons.each do |neuron|
    choice = Random.rand
    neuron = mutateNeuron(neuron) if choice < chance
    neuron = randomNeuron(neuron.weights.length) if choice < (chance*0.1)
  end
end

def initPopulation layers, size
  population = []
  size.times do
    neurons = []
    layers.each_index do |i|
      if i == layers.length()-1
        neurons += generateNeuronLayer(layers[i],0)
      else
        neurons += generateNeuronLayer(layers[i],layers[i+1])
      end
    end
    population.push(deepcopyNeurons(neurons))
  end
  return population.map!{|org| Organism.new(org)}
end

# testing concerns

class TestCase
  attr_accessor :input
  attr_accessor :expectation
  def initialize input, expectation
    @input = input
    @expectation = expectation
  end

  def expectationMatched output
    return false if output.length != @expectation.length
    output.each_index do |i|
      return false if output[i] != @expectation[i]
    end
    return true
  end
end

def decToBin num
  result = []
  while num > 0
    result.push(num%2)
    num = num/2
  end
  while result.length < 8
    result.push(0)
  end
  return result.reverse
end

def binToDec num
  result = 0
  num = num.reverse
  num.each_index do |i|
    result += num[i] * (2**i)
  end
  return result
end

def deepcopyNeuron neuron
  result = GeneticNeuron.new(neuron.bias, neuron.recurrent, neuron.weights.clone)
  return result
end

def deepcopyNeurons neurons
  result = []
  neurons.each do |n|
    result.push(deepcopyNeuron(n))
  end
  return result
end

def randomDeaths size
  deaths = [0,0]
  deaths[0] = Random.rand(size)
  deaths[1] = Random.rand(size)
  while deaths[0] == deaths[1]
    deaths[1] = Random.rand(size)
  end
  return deaths
end

# actual algorithm

def geneticPainterAlgorithm cases
  layers = [24,48,24]
  popSize = 100
  population = initPopulation(layers, popSize)
  best = nil
  bestLoss = nil
  limit = 100000
  poolSize = 30
  mutateChance = 0.01
  generations = 1000
  generation = 0
  totalLoss = 0.0
  inputs = cases.map{|c| c.input}
  expectations = cases.map{|c| c.expectation}
  while (best == nil) or (bestLoss > limit and generation < generations)
    puts "Generation: " + generation.to_s
    generation += 1
    puts "Best Loss: " + bestLoss.to_s
    count = 0
    population.each do |org|
      next if org.assessed
      count += 1
      puts count
      network = GeneticNeuralNetwork.new(layers,org.neurons)
      org.fitness = network.loss_all(inputs, expectations)
      org.assessed = true
    end
    population.sort!{|org1,org2| org1.fitness<=>org2.fitness}
    puts 'Top of Generation: ' + population[0].fitness.to_s
    if best == nil or best.fitness > population[0].fitness
      best = Organism.new(deepcopyNeurons(population[0].neurons))
      best.fitness = population[0].fitness
      bestLoss = best.fitness
    end
    pool = population.shuffle[0...poolSize].sort!{|org1,org2| org2.fitness<=>org1.fitness}
    children = mateNeurons(deepcopyNeurons(pool[0].neurons),deepcopyNeurons(pool[1].neurons))
    children[0] = Organism.new(mutateNeurons(children[0],mutateChance))
    children[1] = Organism.new(mutateNeurons(children[1],mutateChance))
    replace = randomDeaths(popSize)
    population[replace[0]] = children[0]
    population[replace[1]] = children[1]
  end
  return best
end
