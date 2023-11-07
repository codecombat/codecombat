var Vector;

Vector = (function() {
  var fn, fn1, i, j, len, len1, name, ref, ref1;

  Vector.className = 'Vector';

  ref = ['add', 'subtract', 'multiply', 'divide', 'limit', 'normalize', 'rotate'];
  fn = function(name) {
    return Vector[name] = function(a, b, useZ) {
      return a.copy()[name](b, useZ);
    };
  };
  for (i = 0, len = ref.length; i < len; i++) {
    name = ref[i];
    fn(name);
  }

  ref1 = ['magnitude', 'heading', 'distance', 'dot', 'equals', 'copy', 'distanceSquared'];
  fn1 = function(name) {
    return Vector[name] = function(a, b, useZ) {
      return a[name](b, useZ);
    };
  };
  for (j = 0, len1 = ref1.length; j < len1; j++) {
    name = ref1[j];
    fn1(name);
  }

  Vector.prototype.isVector = true;

  Vector.prototype.apiProperties = ['x', 'y', 'z', 'magnitude', 'heading', 'distance', 'dot', 'equals', 'copy', 'distanceSquared', 'add', 'subtract', 'multiply', 'divide', 'limit', 'normalize', 'rotate'];

  function Vector(x, y, z) {
    var ref2;
    if (x == null) {
      x = 0;
    }
    if (y == null) {
      y = 0;
    }
    if (z == null) {
      z = 0;
    }
    if (!(this instanceof Vector)) {
      return new Vector(x, y, z);
    }
    ref2 = [x, y, z], this.x = ref2[0], this.y = ref2[1], this.z = ref2[2];
  }

  Vector.prototype.copy = function() {
    return new Vector(this.x, this.y, this.z);
  };

  Vector.prototype.normalize = function(useZ) {
    var m;
    m = this.magnitude(useZ);
    if (m > 0) {
      this.divide(m, useZ);
    }
    return this;
  };

  Vector.prototype.esper_normalize = function(useZ) {
    return this.copy().normalize(useZ);
  };

  Vector.prototype.limit = function(max) {
    if (this.magnitude() > max) {
      this.normalize();
      return this.multiply(max);
    } else {
      return this;
    }
  };

  Vector.prototype.esper_limit = function(max) {
    return this.copy().limit(max);
  };

  Vector.prototype.subtract = function(other, useZ) {
    this.x -= other.x;
    this.y -= other.y;
    if (useZ) {
      this.z -= other.z;
    }
    return this;
  };

  Vector.prototype.esper_subtract = function(other, useZ) {
    return this.copy().subtract(other, useZ);
  };

  Vector.prototype.add = function(other, useZ) {
    this.x += other.x;
    this.y += other.y;
    if (useZ) {
      this.z += other.z;
    }
    return this;
  };

  Vector.prototype.esper_add = function(other, useZ) {
    return this.copy().add(other, useZ);
  };

  Vector.prototype.divide = function(n, useZ) {
    var ref2;
    ref2 = [this.x / n, this.y / n], this.x = ref2[0], this.y = ref2[1];
    if (useZ) {
      this.z = this.z / n;
    }
    return this;
  };

  Vector.prototype.esper_divide = function(n, useZ) {
    return this.copy().divide(n, useZ);
  };

  Vector.prototype.multiply = function(n, useZ) {
    var ref2;
    ref2 = [this.x * n, this.y * n], this.x = ref2[0], this.y = ref2[1];
    if (useZ) {
      this.z = this.z * n;
    }
    return this;
  };

  Vector.prototype.esper_multiply = function(n, useZ) {
    return this.copy().multiply(n, useZ);
  };

  Vector.prototype.rotate = function(theta) {
    var ref2;
    if (!theta) {
      return this;
    }
    ref2 = [Math.cos(theta) * this.x - Math.sin(theta) * this.y, Math.sin(theta) * this.x + Math.cos(theta) * this.y], this.x = ref2[0], this.y = ref2[1];
    return this;
  };

  Vector.prototype.esper_rotate = function(theta) {
    return this.copy().rotate(theta);
  };

  Vector.prototype.magnitude = function(useZ) {
    var sum;
    sum = this.x * this.x + this.y * this.y;
    if (useZ) {
      sum += this.z * this.z;
    }
    return Math.sqrt(sum);
  };

  Vector.prototype.magnitudeSquared = function(useZ) {
    var sum;
    sum = this.x * this.x + this.y * this.y;
    if (useZ) {
      sum += this.z * this.z;
    }
    return sum;
  };

  Vector.prototype.heading = function() {
    return -1 * Math.atan2(-1 * this.y, this.x);
  };

  Vector.prototype.distance = function(other, useZ) {
    var dx, dy, dz, sum;
    dx = this.x - other.x;
    dy = this.y - other.y;
    sum = dx * dx + dy * dy;
    if (useZ) {
      dz = this.z - other.z;
      sum += dz * dz;
    }
    return Math.sqrt(sum);
  };

  Vector.prototype.distanceSquared = function(other, useZ) {
    var dx, dy, dz, sum;
    dx = this.x - other.x;
    dy = this.y - other.y;
    sum = dx * dx + dy * dy;
    if (useZ) {
      dz = this.z - other.z;
      sum += dz * dz;
    }
    return sum;
  };

  Vector.prototype.dot = function(other, useZ) {
    var sum;
    sum = this.x * other.x + this.y * other.y;
    if (useZ) {
      sum += this.z * other.z;
    }
    return sum;
  };

  Vector.prototype.projectOnto = function(other, useZ) {
    return other.copy().multiply(this.dot(other, useZ), useZ);
  };

  Vector.prototype.isZero = function(useZ) {
    var result;
    result = this.x === 0 && this.y === 0;
    if (useZ) {
      result = result && this.z === 0;
    }
    return result;
  };

  Vector.prototype.equals = function(other, useZ) {
    var result;
    result = other && this.x === other.x && this.y === other.y;
    if (useZ) {
      result = result && this.z === other.z;
    }
    return result;
  };

  Vector.prototype.invalid = function() {
    return (this.x === Infinity) || isNaN(this.x) || this.y === Infinity || isNaN(this.y) || this.z === Infinity || isNaN(this.z);
  };

  Vector.prototype.toString = function(precision) {
    if (precision == null) {
      precision = 2;
    }
    return "{x: " + (this.x.toFixed(precision)) + ", y: " + (this.y.toFixed(precision)) + ", z: " + (this.z.toFixed(precision)) + "}";
  };

  Vector.prototype.serialize = function() {
    return {
      CN: this.constructor.className,
      x: this.x,
      y: this.y,
      z: this.z
    };
  };

  Vector.deserialize = function(o, world, classMap) {
    return new Vector(o.x, o.y, o.z);
  };

  Vector.prototype.serializeForAether = function() {
    return this.serialize();
  };

  Vector.deserializeFromAether = function(o) {
    return this.deserialize(o);
  };

  return Vector;

})();

module.exports = Vector;

// ---
// generated by coffee-script 1.9.2