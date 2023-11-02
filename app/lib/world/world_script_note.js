/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let WorldScriptNote;
const {clone} = require('./world_utils');
const {scriptMatchesEventPrereqs} = require('./script_event_prereqs');

module.exports = (WorldScriptNote = (function() {
  WorldScriptNote = class WorldScriptNote {
    static initClass() {
      this.className = 'WorldScriptNote';
    }
    constructor(script, event, world) {
      this.event = event;
      if (script == null) { return; }
      this.invalid = true;
      if (!scriptMatchesEventPrereqs(script, this.event)) { return; }
      // Could add the scriptPrereqsSatisfied or seen/repeats stuff if needed
      this.invalid = false;
      this.channel = script.channel;
      if (this.event == null) { this.event = {}; }
      if (script.noteChain) { this.event.replacedNoteChain = script.noteChain; }
    }

    serialize() {
      const o = {channel: this.channel, event: {}};
      for (var key in this.event) {
        var value = this.event[key];
        if (value != null ? value.isThang : undefined) {
          value = {isThang: true, id: value.id};
        } else if (_.isArray(value)) {
          for (var i = 0; i < value.length; i++) {
            var subval = value[i];
            if (subval != null ? subval.isThang : undefined) {
              value[i] = {isThang: true, id: subval.id};
            }
          }
        }
        o.event[key] = value;
      }
      return o;
    }

    static deserialize(o, world, classMap) {
      const scriptNote = new WorldScriptNote;
      scriptNote.channel = o.channel;
      scriptNote.event = {};
      for (var key in o.event) {
        var value = o.event[key];
        if ((value != null) && (typeof value === 'object') && value.isThang) {
          value = world.getThangByID(value.id);
        } else if (_.isArray(value)) {
          for (var i = 0; i < value.length; i++) {
            var subval = value[i];
            if ((subval != null) && (typeof subval === 'object') && subval.isThang) {
              value[i] = world.getThangByID(subval.id);
            }
          }
        } else if ((value != null) && (typeof value === 'object') && value.CN) {
          value = classMap[value.CN].deserialize(value, world, classMap);
        }
        scriptNote.event[key] = value;
      }
      return scriptNote;
    }
  };
  WorldScriptNote.initClass();
  return WorldScriptNote;
})());
