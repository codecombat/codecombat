// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS202: Simplify dynamic range loops
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
// http://coffeescriptcookbook.com/chapters/math/generating-predictable-random-numbers
class Rand {
  static initClass() {
    this.className = 'Rand';
  }
  // If created without a seed, uses current time as seed.
  constructor(seed) {
    // Knuth and Lewis' improvements to Park and Miller's LCPRNG
    this.randn = this.randn.bind(this);
    this.randf = this.randf.bind(this);
    this.rand = this.rand.bind(this);
    this.rand2 = this.rand2.bind(this);
    this.randf2 = this.randf2.bind(this);
    this.randfRange = this.randfRange.bind(this);
    this.shuffle = this.shuffle.bind(this);
    this.shuffleCompat = this.shuffleCompat.bind(this);
    this.choice = this.choice.bind(this);
    this.seed = seed;
    this.multiplier = 1664525;
    this.modulo = 4294967296; // 2**32-1
    this.offset = 1013904223;
    if ((this.seed == null) || !(0 <= this.seed && this.seed < this.modulo)) {
      this.seed = (new Date().valueOf() * new Date().getMilliseconds()) % this.modulo;
    }
  }

  // sets new seed value, even handling negative numbers
  setSeed(seed) {
    return this.seed = ((seed % this.modulo) + this.modulo) % this.modulo;
  }

  // return a random integer 0 <= n < @modulo
  randn() {
    // new_seed = (a * seed + c) % m
    return this.seed = ((this.multiplier * this.seed) + this.offset) % this.modulo;
  }

 // return a random float 0 <= f < 1.0
  randf() {
    return this.randn() / this.modulo;
  }

  // return a random int 0 <= f < n
  rand(n) {
    return Math.floor(this.randf() * n);
  }

  // return a random int min <= f < max
  rand2(min, max) {
    return min + this.rand(max - min);
  }

  // return a random float min <= f < max
  randf2(min, max) {
    return min + (this.randf() * (max - min));
  }

  // return a random float within range around x
  randfRange(x, range) {
    return x + ((-0.5 + this.randf()) * range);
  }

  // shuffle array in place, and also return it
  shuffle(arr) {
    if (!(arr.length > 2)) { return arr; }
    for (let start = arr.length-1, i = start, asc = start <= 1; asc ? i <= 1 : i >= 1; asc ? i++ : i--) {
      var j = Math.floor(this.randf() * (i + 1));
      var t = arr[j];
      arr[j] = arr[i];
      arr[i] = t;
    }
    return arr;
  }

  // shuffle in exactly the same way lo-dash did to migrate same random sequences
  // returns a new array but does not modify existing array
  shuffleCompat(arr) {
    let index = -1;
    const length = arr.length || 0;
    const result = new Array(length);
    for (var item of Array.from(arr)) {
      var r = this.rand(++index + 1);
      result[index] = result[r];
      result[r] = item;
    }
    return result;
  }

  choice(arr) {
    return arr[this.rand(arr.length)];
  }
}
Rand.initClass();


export default Rand;
