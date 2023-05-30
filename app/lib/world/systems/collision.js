// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
// http://codingowl.com/readblog.php?blogid=124
let CollisionCategory;
module.exports.CollisionCategory = (CollisionCategory = (function() {
  CollisionCategory = class CollisionCategory {
    static initClass() {
      this.className = 'CollisionCategory';
    }
    constructor(name, superteamIndex=null, collisionSystem) {
      // @superteamIndex is null for 'none', 'obstacles', and 'dead'.
      // It's 0 for 'ground', 'air', and 'ground_and_air' units with no superteams.
      // It's 1, 2, or 3 for the superteams it gets after that. We can only have 16 collision categories.
      this.superteamIndex = superteamIndex;
      this.collisionSystem = collisionSystem;
      this.ground = name.search('ground') !== -1;
      this.air = name.search('air') !== -1;
      this.name = CollisionCategory.nameFor(name, this.superteamIndex);
      if (this.ground || this.air) { if (this.superteamIndex == null) { this.superteamIndex = 0; } }
      this.number = 1 << this.collisionSystem.totalCategories++;
      if (this.collisionSystem.totalCategories > 16) { console.log('There should only be 16 collision categories!'); }
      this.mask = 0;
      this.collisionSystem.allCategories[this.name] = this;
      for (var otherCatName in this.collisionSystem.allCategories) {
        var otherCat = this.collisionSystem.allCategories[otherCatName];
        if (this.collidesWith(otherCat)) {
          this.mask = this.mask | otherCat.number;
          otherCat.mask = otherCat.mask | this.number;
        }
      }
    }

    collidesWith(cat) {
      // 'none' collides with nothing
      if ((this.name === 'none') || (cat.name === 'none')) { return false; }

      // 'obstacles' collides with everything; could also try letting air units (but not ground_and_air) fly over these
      if ((cat.name === 'obstacles') || (this.name === 'obstacles')) { return true; }

      // 'dead' collides only with obstacles
      if (this.name === 'dead') { return cat.name === 'obstacles'; }
      if (cat.name === 'dead') { return this.name === 'obstacles'; }

      // 'ground_and_air_<team>' units don't hit ground or air units on their team (so missiles don't hit same team)
      const sameTeam = this.superteamIndex && (cat.superteamIndex === this.superteamIndex);
      if (sameTeam && this.ground && this.air) { return false; }

      // actually, 'ground_and_air<team>' units don't hit any ground_and_air units (temp missile collision fix)
      if (this.ground && this.air && cat.ground && cat.air) { return false; }

      // 'ground' collides with 'ground'
      if (cat.ground && this.ground) { return true; }

      // 'air' collides with 'air'
      if (cat.air && this.air) { return true; }

      // doesn't collide (probably 'ground' and 'air')
      return false;
    }

    static nameFor(name, superteamIndex=null) {
      if (!name.match('ground') && !name.match('air')) { return name; }
      return name + '_' + (superteamIndex || 0);
    }
  };
  CollisionCategory.initClass();
  return CollisionCategory;
})());
