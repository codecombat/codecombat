# If we ever need a seedable PRNG, we can use this.
# http://coffeescriptcookbook.com/chapters/math/generating-predictable-random-numbers
class Rand
  @className: "Rand"
  # if created without a seed, uses current time as seed
  constructor: (@seed) ->
    # Knuth and Lewis' improvements to Park and Miller's LCPRNG
    @multiplier = 1664525
    @modulo = 4294967296 # 2**32-1
    @offset = 1013904223
    unless @seed? and 0 <= seed < @modulo
      @seed = (new Date().valueOf() * new Date().getMilliseconds()) % @modulo

  # sets new seed value
  seed: (seed) ->
    @seed = seed

  # return a random integer 0 <= n < @modulo
  randn: =>
    # new_seed = (a * seed + c) % m
    @seed = (@multiplier * @seed + @offset) % @modulo

 # return a random float 0 <= f < 1.0
  randf: =>
    @randn() / @modulo

  # return a random int 0 <= f < n
  rand: (n) =>
    Math.floor @randf() * n

  # return a random int min <= f < max
  rand2: (min, max) =>
    min + @rand max - min

  # return an array of randomly shuffled numbers from 0 to n, exclusive
  randArray: (n) =>
    array = ( i for i in [0..(n-1)] )

    for i in [0..(n-1)]
      r = @rand n
      [ array[i], array[r] ] = [ array[r], array[i] ]

    array

module.exports = Rand