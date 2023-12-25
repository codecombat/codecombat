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
let Poll
const CocoModel = require('./CocoModel')
const schema = require('schemas/models/poll.schema')

module.exports = (Poll = (function () {
  Poll = class Poll extends CocoModel {
    static initClass () {
      this.className = 'Poll'
      this.schema = schema
      this.prototype.urlRoot = '/db/poll'
    }

    applyDelta (delta) {
      // Hackiest hacks ever, just manually mauling the delta (whose format I don't understand) to not overwrite votes and other languages' nested translations.
      // One still must be careful about patches that accidentally delete keys from the top-level i18n object.
      const i18nDelta = {}
      if (delta.i18n) {
        i18nDelta.i18n = $.extend(true, {}, delta.i18n)
      }
      const object = delta.answers != null ? delta.answers : {}
      for (const answerIndex in object) {
        const answerChanges = object[answerIndex]
        if (i18nDelta.answers == null) { i18nDelta.answers = {} }
        if (_.isArray(answerChanges)) {
          if (i18nDelta.answers[answerIndex] == null) { i18nDelta.answers[answerIndex] = [] }
          for (const change of Array.from(answerChanges)) {
            let pickedChange
            if (_.isNumber(change)) {
              pickedChange = change
            } else {
              pickedChange = $.extend(true, {}, change)
              for (const key in pickedChange) {
                const answerIndexNum = parseInt(answerIndex.replace('_', ''), 10)
                if (!_.isNaN(answerIndexNum)) {
                  let value
                  const oldValue = this.get('answers')[answerIndexNum][key]
                  const isDeletion = _.string.startsWith(answerIndex, '_')
                  const isI18N = key === 'i18n'
                  if (isI18N && !isDeletion) {
                    // Use the new change, but make sure we're not deleting any other languages' translations.
                    value = pickedChange[key]
                    const object1 = oldValue != null ? oldValue : {}
                    for (const language in object1) {
                      const oldTranslations = object1[language]
                      const object2 = oldTranslations != null ? oldTranslations : {}
                      for (const translationKey in object2) {
                        const translationValue = object2[translationKey]
                        if (value[language] == null) { value[language] = {} }
                        if (value[language][translationKey] == null) { value[language][translationKey] = translationValue }
                      }
                    }
                  } else {
                    value = oldValue
                  }
                  pickedChange[key] = value
                }
              }
            }
            i18nDelta.answers[answerIndex].push(pickedChange)
          }
        } else {
          i18nDelta.answers[answerIndex] = answerChanges
          if (answerChanges != null ? answerChanges.votes : undefined) {
            i18nDelta.answers[answerIndex] = _.omit(answerChanges, 'votes')
          }
        }
      }

      // console.log 'got     delta', delta
      // console.log 'got i18nDelta', i18nDelta
      return super.applyDelta(i18nDelta)
    }
  }
  Poll.initClass()
  return Poll
})())
