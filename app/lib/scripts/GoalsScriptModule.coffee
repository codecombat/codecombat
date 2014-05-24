ScriptModule = require './ScriptModule'

module.exports = class GoalsScriptModule extends ScriptModule
  @neededFor: (noteGroup) ->
    return noteGroup.goals?

  startNotes: ->
    notes = []
    notes.push(@addNote()) if @noteGroup.goals.add?
    notes.push(@removeNote()) if @noteGroup.goals.remove?
    return notes

  endNotes: ->
    return []

  skipNotes: ->
    return @startNotes()

  addNote: ->
    note =
      channel: 'level-add-goals'
      event:
        goals: @noteGroup.goals.add
    return note

  removeNote: ->
    note =
      channel: 'level-remove-goals'
      event:
        goals: @noteGroup.goals.remove
    return note
