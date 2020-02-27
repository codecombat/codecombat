ScriptModule = require './ScriptModule'
{me} = require 'core/auth'
utils = require 'core/utils'

module.exports = class SpritesScriptModule extends ScriptModule
  @neededFor: (noteGroup) ->
    return noteGroup.sprites?.length

  startNotes: ->
    notes = []
    @moveSums = {}
    @speakingSprites = {}
    for sprite in @noteGroup.sprites or []
      notes.push(@spriteMoveNote sprite) if sprite.move?
    for sprite in @noteGroup.sprites or []
      notes.push(@spriteSayNote(sprite, @noteGroup.script)) if sprite.say?
      notes.push(@spriteSelectNote sprite) if sprite.select?
    return (n for n in notes when n)

  spriteMoveNote: (sprite, instant=false) ->
    duration = if instant then 0 else sprite.move.duration
    note =
      channel: 'sprite:move'
      event:
        pos: sprite.move.target
        duration: duration
        spriteID: sprite.id
    if duration
      @moveSums[sprite.id] ?= 0
      note.delay = @scrubbingTime + @moveSums[sprite.id]
      @moveSums[sprite.id] += sprite.move.duration
    return note

  spriteSayNote: (sprite, script) ->
    return if @speakingSprites[sprite.id]
    responses = sprite.say.responses
    responses = [] unless script.skippable or responses
    for response in responses ? []
      response.text = utils.i18n response, 'text'
    text = utils.i18n sprite.say, 'text'
    blurb = utils.i18n sprite.say, 'blurb'
    sound = utils.i18n sprite.say, 'sound'
    note =
      channel: 'level:sprite-dialogue'
      event:
        message: text
        blurb: blurb
        mood: sprite.say.mood or 'explain'
        responses: responses
        spriteID: sprite.id
        sound: sound
    @maybeApplyDelayToNote note
    return note

  spriteSelectNote: (sprite) ->
    note =
      channel: 'level:select-sprite'
      event:
        thangID: if sprite.select then sprite.id else null
    return note

  endNotes: ->
    notes = {}
    for sprite in @noteGroup.sprites or []
      notes[sprite.id] ?= {}
      notes[sprite.id]['move'] = (@spriteMoveNote sprite, true) if sprite.move?
      notes[sprite.id]['say'] = { channel: 'level:sprite-clear-dialogue' } if sprite.say?
    noteArray = []
    for spriteID of notes
      for type of notes[spriteID]
        noteArray.push(notes[spriteID][type])
    noteArray
