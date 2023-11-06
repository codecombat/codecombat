// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS002: Fix invalid constructor
 * DS102: Remove unnecessary code created because of implicit returns
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let IndieLank;
const Thang = require('lib/world/thang');
const Lank = require('lib/surface/Lank');

module.exports = (IndieLank = (IndieLank = (function() {
  IndieLank = class IndieLank extends Lank {
    static initClass() {
      this.prototype.notOfThisWorld = true;
      this.prototype.subscriptions = {
        'script:note-group-started': 'onNoteGroupStarted',
        'script:note-group-ended': 'onNoteGroupEnded'
      };
    }

    constructor(thangType, options) {
      super(thangType, options);
      this.onNoteGroupStarted = this.onNoteGroupStarted.bind(this);
      this.onNoteGroupEnded = this.onNoteGroupEnded.bind(this);
      options.thang = this.makeIndieThang(thangType, options);
      this.shadow = this.thang;
    }

    makeIndieThang(thangType, options) {
      let thang;
      this.thang = (thang = new Thang(null, thangType.get('name'), options.thangID));
      // Build needed results of what used to be Exists, Physical, Acts, and Selectable Components
      thang.exists = true;
      thang.width = (thang.height = (thang.depth = 4));
      thang.pos = options.pos != null ? options.pos : this.defaultPos();
      thang.pos.z = thang.depth / 2;
      thang.shape = 'ellipsoid';
      thang.rotation = 0;
      thang.action = 'idle';
      thang.setAction = action => thang.action = action;
      thang.getActionName = () => thang.action;
      thang.acts = true;
      thang.isSelectable = true;
      thang.team = options.team;
      thang.teamColors = options.teamColors;
      return thang;
    }

    onNoteGroupStarted() { return this.scriptRunning = true; }
    onNoteGroupEnded() { return this.scriptRunning = false; }
    onMouseEvent(e, ourEventName) { if (!this.scriptRunning) { return super.onMouseEvent(e, ourEventName); } }
    defaultPos() { return {x: -20, y: 20, z: this.thang.depth / 2}; }
  };
  IndieLank.initClass();
  return IndieLank;
})()));
