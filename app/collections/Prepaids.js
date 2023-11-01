// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let Prepaids;
const CocoCollection = require('collections/CocoCollection');
const Prepaid = require('models/Prepaid');

const sum = numbers => _.reduce(numbers, (a, b) => a + b);

module.exports = (Prepaids = (function() {
  Prepaids = class Prepaids extends CocoCollection {
    static initClass() {
      this.prototype.model = Prepaid;
  
      this.prototype.url = "/db/prepaid";
    }

    initialize() {
      return super.initialize(...arguments);
    }

    comparator(prepaid) {
      return [
        prepaid.get('type') === 'course' ? 'C' : 'S',
        prepaid.get('endDate')
      ].toString();
    }

    totalMaxRedeemers() {
      return sum((Array.from(this.models).map((prepaid) => prepaid.get('maxRedeemers')))) || 0;
    }

    totalRedeemers() {
      return sum((Array.from(this.models).map((prepaid) => _.size(prepaid.get('redeemers'))))) || 0;
    }

    totalAvailable() { return Math.max(this.totalMaxRedeemers() - this.totalRedeemers(), 0); }

    fetchByCreator(creatorID, opts) {
      if (opts == null) { opts = {}; }
      if (opts.data == null) { opts.data = {}; }
      opts.data.creator = creatorID;
      return this.fetch(opts);
    }

    fetchMineAndShared() {
      return this.fetchByCreator(me.id, { data: {includeShared: true} });
    }

    fetchForClassroom(classroom) {
      if (classroom.isOwner()) {
        return this.fetchMineAndShared();
      } else if (classroom.hasReadPermission()) {
        const options = {
          data: {
            includeShared: true,
            sharedClassroomId: classroom.id
          }
        };
        return this.fetchByCreator(classroom.get('ownerID'), options);
      } else {
        return this.fetchMineAndShared();
      }
    }
  };
  Prepaids.initClass();
  return Prepaids;
})());
