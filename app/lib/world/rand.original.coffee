# http://coffeescriptcookbook.com/chapters/math/generating-predictable-random-numbers
class Rand
  @className: 'Rand'
  # If created without a seed, uses current time as seed.
  constructor: (@seed) ->
    # Knuth and Lewis' improvements to Park and Miller's LCPRNG
    @multiplier = 1664525
    @modulo = 4294967296 # 2**32-1
    @offset = 1013904223
    unless @seed? and 0 <= @seed < @modulo
      @seed = (new Date().valueOf() * new Date().getMilliseconds()) % @modulo

  # sets new seed value, even handling negative numbers
  setSeed: (seed) ->
    @seed = ((seed % @modulo) + @modulo) % @modulo

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

  # return a random float min <= f < max
  randf2: (min, max) =>
    min + @randf() * (max - min)

  # return a random float within range around x
  randfRange: (x, range) =>
    x + (-0.5 + @randf()) * range

  # shuffle array in place, and also return it
  shuffle: (arr) =>
    return arr unless arr.length > 2
    for i in [arr.length-1 .. 1]
      j = Math.floor @randf() * (i + 1)
      t = arr[j]
      arr[j] = arr[i]
      arr[i] = t
    arr

  # shuffle in exactly the same way lo-dash did to migrate same random sequences
  # returns a new array but does not modify existing array
  shuffleCompat: (arr) =>
    index = -1
    length = arr.length or 0
    result = new Array length
    for item in arr
      r = @rand ++index + 1
      result[index] = result[r]
      result[r] = item
    result

  choice: (arr) =>
    return arr[@rand arr.length]


module.exports = Rand
