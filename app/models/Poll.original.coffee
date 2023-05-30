CocoModel = require './CocoModel'
schema = require 'schemas/models/poll.schema'

module.exports = class Poll extends CocoModel
  @className: 'Poll'
  @schema: schema
  urlRoot: '/db/poll'

  applyDelta: (delta) ->
    # Hackiest hacks ever, just manually mauling the delta (whose format I don't understand) to not overwrite votes and other languages' nested translations.
    # One still must be careful about patches that accidentally delete keys from the top-level i18n object.
    i18nDelta = {}
    if delta.i18n
      i18nDelta.i18n = $.extend true, {}, delta.i18n
    for answerIndex, answerChanges of delta.answers ? {}
      i18nDelta.answers ?= {}
      if _.isArray answerChanges
        i18nDelta.answers[answerIndex] ?= []
        for change in answerChanges
          if _.isNumber change
            pickedChange = change
          else
            pickedChange = $.extend true, {}, change
            for key of pickedChange
              answerIndexNum = parseInt(answerIndex.replace('_', ''), 10)
              unless _.isNaN answerIndexNum
                oldValue = @get('answers')[answerIndexNum][key]
                isDeletion = _.string.startsWith answerIndex, '_'
                isI18N = key is 'i18n'
                if isI18N and not isDeletion
                  # Use the new change, but make sure we're not deleting any other languages' translations.
                  value = pickedChange[key]
                  for language, oldTranslations of oldValue ? {}
                    for translationKey, translationValue of oldTranslations ? {}
                      value[language] ?= {}
                      value[language][translationKey] ?= translationValue
                else
                  value = oldValue
                pickedChange[key] = value
          i18nDelta.answers[answerIndex].push pickedChange
      else
        i18nDelta.answers[answerIndex] = answerChanges
        if answerChanges?.votes
          i18nDelta.answers[answerIndex] = _.omit answerChanges, 'votes'

    #console.log 'got     delta', delta
    #console.log 'got i18nDelta', i18nDelta
    super i18nDelta
