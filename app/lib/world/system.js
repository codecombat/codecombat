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
// The System will operate on its Thangs of interest in each WorldFrame.
// Systems so far: AI, UI, Collision, Movement, Targeting, Programming, Combat, Vision, Hearing, Inventory, Actions
// Other Systems might be things like Attraction, EdgeBounce, EdgeWrap, and non-physics ones, too, like Rendering, Animation, ...

let System;

export default System = (function() {
  System = class System {
    static initClass() {
      this.className = 'System';
    }
    constructor(world, config) {
      // Unlike with Component, we don't automatically copy all our properties onto the World.
      // Subclasses can copy select properties here if they like.
      this.world = world;
      const object = config != null ? config : {};
      for (var key in object) {
        var value = object[key];
        this[key] = value;
      }
      this.registries = [];
      this.hashes = {};
    }

    // Start is called once the beginning, after all Thangs have been loaded.
    start(thangs) {}

    // Update is called once per frame on all thangs that currently have exist=true in the World.
    // We return a simple numeric hash that will combine to a frame hash help us determine whether this frame has changed later on.
    update(thangs) {
      let hash;
      return hash = 0;
    }

    // Finish is called once at the end, after all frames have been generated.
    finish(thangs) {}

    addRegistry(condition) {
      const registry = [];
      this.registries.push([registry, condition]);
      return registry;
    }

    // Register is called whenever a Thang changes important state (exists, dead, etc), and can be called more specifically by individual Thangs.
    register(thang) {
      for (var [registry, condition] of Array.from(this.registries)) {
        if (condition(thang)) {
          if (!Array.from(registry).includes(thang)) {
            registry.push(thang);
          }
        } else {
          var thangIndex = registry.indexOf(thang);
          if (thangIndex !== -1) {
            registry.splice(thangIndex, 1);
          }
        }
      }
      return null;
    }

    // Override this to determine which registries have which conditions
    checkRegistration(thang, registry) {}

    hashString(s) {
      if (s in this.hashes) { return this.hashes[s]; }
      let hash = 0;
      for (let i = 0, end = Math.min(s.length, 100), asc = 0 <= end; asc ? i < end : i > end; asc ? i++ : i--) {
        hash = (hash * 31) + s.charCodeAt(i);
      }
      hash = (this.hashes[s] = hash % 3.141592653589793);
      return hash;
    }

    toString() {
      return `<System: ${this.constructor.className}`;
    }
  };
  System.initClass();
  return System;
})();
