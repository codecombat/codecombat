// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS202: Simplify dynamic range loops
 * DS205: Consider reworking code to avoid use of IIFEs
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let WorldFrame;
import ThangState from './thang_state';

export default WorldFrame = (function() {
  WorldFrame = class WorldFrame {
    static initClass() {
      this.className = 'WorldFrame';
    }

    constructor(world, time) {
      this.world = world;
      if (time == null) { time = 0; }
      this.time = time;
      this.thangStateMap = {};
      if (this.world) {
        this.scores = _.omit(this.world.getScores(), 'code-length');
        this.setState();
      }
    }

    getNextFrame() {
      // Optimized. Must be called while thangs are current at this frame.
      const nextTime = this.time + this.world.dt;
      if ((nextTime > this.world.lifespan) && !this.world.indefiniteLength) { return null; }
      this.hash = this.world.rand.seed;
      for (var system of Array.from(this.world.systems)) { this.hash += system.update(); }
      const nextFrame = new WorldFrame(this.world, nextTime);
      return nextFrame;
    }

    setState() {
      if (this.world.synchronous || this.world.headless) { return; }
      return Array.from(this.world.thangs).filter((thang) => !thang.stateless).map((thang) =>
        (this.thangStateMap[thang.id] = thang.getState()));
    }

    restoreState() {
      if (this.world.synchronous || this.world.headless) { return; }
      for (var thangID in this.thangStateMap) { var thangState = this.thangStateMap[thangID]; thangState.restore(); }
      return (() => {
        const result = [];
        for (var thang of Array.from(this.world.thangs)) {
          if (!this.thangStateMap[thang.id] && !thang.stateless) {
            //console.log 'Frame', @time, 'restoring state for', thang.id, 'and saying it don\'t exist'
            result.push(thang.exists = false);
          } else {
            result.push(undefined);
          }
        }
        return result;
      })();
    }

    restorePartialState(ratio) {
      if (this.world.synchronous || this.world.headless) { return; }
      return (() => {
        const result = [];
        for (var thangID in this.thangStateMap) {
          var thangState = this.thangStateMap[thangID];
          result.push(thangState.restorePartial(ratio));
        }
        return result;
      })();
    }

    restoreStateForThang(thang) {
      if (this.world.synchronous || this.world.headless) { return; }
      const thangState = this.thangStateMap[thang.id];
      if (!thangState) {
        if (!thang.stateless) {
          thang.exists = false;
        }
          //console.log 'Frame', @time, 'restoring state for', thang.id, 'in particular and saying it don\'t exist'
        return;
      }
      return thangState.restore();
    }

    clearEvents() { return Array.from(this.world.thangs).map((thang) => (thang.currentEvents = [])); }

    toString() {
      let y, x;
      const map = ((() => {
        let asc, end;
        const result = [];
        for (y = 0, end = this.world.height, asc = 0 <= end; asc ? y <= end : y >= end; asc ? y++ : y--) {
          result.push(((() => {
            let asc1, end1;
            const result1 = [];
            for (x = 0, end1 = this.world.width, asc1 = 0 <= end1; asc1 ? x <= end1 : x >= end1; asc1 ? x++ : x--) {
              result1.push(' ');
            }
            return result1;
          })()));
        }
        return result;
      })());
      const symbols = '.ox@dfga[]/D';
      for (let i = 0; i < this.world.thangs.length; i++) {
        var thang = this.world.thangs[i];
        if (thang.rectangle) {var asc2, end2, start;
        
          var rect = thang.rectangle().axisAlignedBoundingBox();
          for (start = Math.floor(rect.y - (rect.height / 2)), y = start, end2 = Math.ceil(rect.y + (rect.height / 2)), asc2 = start <= end2; asc2 ? y < end2 : y > end2; asc2 ? y++ : y--) {
            var asc3, end3, start1;
            for (start1 = Math.floor(rect.x - (rect.width / 2)), x = start1, end3 = Math.ceil(rect.x + (rect.width / 2)), asc3 = start1 <= end3; asc3 ? x < end3 : x > end3; asc3 ? x++ : x--) {
              if ((0 <= y && y < this.world.height) && (0 <= x && x < this.world.width)) { map[y][x] = symbols[i % symbols.length]; }
            }
          }
        }
      }
      return this.time + '\n' + (Array.from(map).map((xs) => xs.join(' '))).join('\n') + '\n';
    }

    serialize(frameIndex, trackedPropertiesThangIDs, trackedPropertiesPerThangIndices, trackedPropertiesPerThangTypes, trackedPropertiesPerThangValues, specialValuesToKeys, specialKeysToValues, scoresStorage) {
      // Optimize
      for (let thangIndex = 0; thangIndex < trackedPropertiesThangIDs.length; thangIndex++) {
        var thangID = trackedPropertiesThangIDs[thangIndex];
        var thangState = this.thangStateMap[thangID];
        if (thangState) {
          thangState.serialize(frameIndex, trackedPropertiesPerThangIndices[thangIndex], trackedPropertiesPerThangTypes[thangIndex], trackedPropertiesPerThangValues[thangIndex], specialValuesToKeys, specialKeysToValues);
        }
      }
      const scoreValues = _.values(this.scores);
      for (let scoreIndex = 0; scoreIndex < scoreValues.length; scoreIndex++) {
        var score = scoreValues[scoreIndex];
        scoresStorage[(frameIndex * scoreValues.length) + scoreIndex] = score || 0;
      }
      return this.hash;
    }

    static deserialize(world, frameIndex, trackedPropertiesThangIDs, trackedPropertiesThangs, trackedPropertiesPerThangKeys, trackedPropertiesPerThangTypes, trackedPropertiesPerThangValues, specialKeysToValues, scoresStorage, hash, age) {
      // Optimize
      const wf = new WorldFrame(null, age);
      wf.world = world;
      wf.hash = hash;
      wf.scores = {};
      for (let thangIndex = 0; thangIndex < trackedPropertiesThangIDs.length; thangIndex++) {
        var thangID = trackedPropertiesThangIDs[thangIndex];
        wf.thangStateMap[thangID] = ThangState.deserialize(world, frameIndex, trackedPropertiesThangs[thangIndex], trackedPropertiesPerThangKeys[thangIndex], trackedPropertiesPerThangTypes[thangIndex], trackedPropertiesPerThangValues[thangIndex], specialKeysToValues);
      }
      for (let scoreIndex = 0; scoreIndex < world.scoreTypes.length; scoreIndex++) {
        var scoreType = world.scoreTypes[scoreIndex];
        wf.scores[scoreType] = scoresStorage[(frameIndex * world.scoreTypes.length) + scoreIndex];
      }
      return wf;
    }
  };
  WorldFrame.initClass();
  return WorldFrame;
})();
