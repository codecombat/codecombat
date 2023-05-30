// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS206: Consider reworking classes to avoid initClass
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let FlagLank;
import IndieLank from 'lib/surface/IndieLank';
import { me } from 'core/auth';

export default FlagLank = (function() {
  FlagLank = class FlagLank extends IndieLank {
    static initClass() {
      this.prototype.subscriptions =
        {'surface:mouse-moved': 'onMouseMoved'};
    }

    //shortcuts:

    defaultPos() { return {x: 20, y: 20, z: 1}; }

    constructor(thangType, options) {
      super(thangType, options);
      this.toggleCursor(options.isCursor);
    }

    makeIndieThang(thangType, options) {
      const thang = super.makeIndieThang(thangType, options);
      thang.width = (thang.height = (thang.depth = 2));
      thang.pos.z = 1;
      thang.isSelectable = false;
      thang.color = options.color;
      thang.team = options.team;
      return thang;
    }

    onMouseMoved(e) {
      if (!this.options.isCursor) { return; }
      const wop = this.options.camera.screenToWorld({x: e.x, y: e.y});
      this.thang.pos.x = wop.x;
      return this.thang.pos.y = wop.y;
    }

    toggleCursor(to) {
      this.options.isCursor = to;
      this.thang.alpha = to ? 0.33 : 0.67;  // 1.0 is for flags that have been placed
      //@thang.action = if to then 'idle' else 'appear'  # TODO: why doesn't this work? Does it not render the action or something?
      this.thang.action = 'appear';
      return this.updateAlpha();
    }
  };
  FlagLank.initClass();
  return FlagLank;
})();
