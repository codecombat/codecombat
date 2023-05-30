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
let Poll;
import CocoModel from './CocoModel';
import schema from 'schemas/models/poll.schema';

export default Poll = (function() {
  Poll = class Poll extends CocoModel {
    static initClass() {
      this.className = 'Poll';
      this.schema = schema;
      this.prototype.urlRoot = '/db/poll';
    }

    applyDelta(delta) {
      // Hackiest hacks ever, just manually mauling the delta (whose format I don't understand) to not overwrite votes and other languages' nested translations.
      // One still must be careful about patches that accidentally delete keys from the top-level i18n object.
      const i18nDelta = {};
      if (delta.i18n) {
        i18nDelta.i18n = $.extend(true, {}, delta.i18n);
      }
      const object = delta.answers != null ? delta.answers : {};
      for (var answerIndex in object) {
        var answerChanges = object[answerIndex];
        if (i18nDelta.answers == null) { i18nDelta.answers = {}; }
        if (_.isArray(answerChanges)) {
          if (i18nDelta.answers[answerIndex] == null) { i18nDelta.answers[answerIndex] = []; }
          for (var change of Array.from(answerChanges)) {
            var pickedChange;
            if (_.isNumber(change)) {
              pickedChange = change;
            } else {
              pickedChange = $.extend(true, {}, change);
              for (var key in pickedChange) {
                var answerIndexNum = parseInt(answerIndex.replace('_', ''), 10);
                if (!_.isNaN(answerIndexNum)) {
                  var value;
                  var oldValue = this.get('answers')[answerIndexNum][key];
                  var isDeletion = _.string.startsWith(answerIndex, '_');
                  var isI18N = key === 'i18n';
                  if (isI18N && !isDeletion) {
                    // Use the new change, but make sure we're not deleting any other languages' translations.
                    value = pickedChange[key];
                    var object1 = oldValue != null ? oldValue : {};
                    for (var language in object1) {
                      var oldTranslations = object1[language];
                      var object2 = oldTranslations != null ? oldTranslations : {};
                      for (var translationKey in object2) {
                        var translationValue = object2[translationKey];
                        if (value[language] == null) { value[language] = {}; }
                        if (value[language][translationKey] == null) { value[language][translationKey] = translationValue; }
                      }
                    }
                  } else {
                    value = oldValue;
                  }
                  pickedChange[key] = value;
                }
              }
            }
            i18nDelta.answers[answerIndex].push(pickedChange);
          }
        } else {
          i18nDelta.answers[answerIndex] = answerChanges;
          if (answerChanges != null ? answerChanges.votes : undefined) {
            i18nDelta.answers[answerIndex] = _.omit(answerChanges, 'votes');
          }
        }
      }

      //console.log 'got     delta', delta
      //console.log 'got i18nDelta', i18nDelta
      return super.applyDelta(i18nDelta);
    }
  };
  Poll.initClass();
  return Poll;
})();
