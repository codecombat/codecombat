{clone} = require './world_utils'
{scriptMatchesEventPrereqs} = require './script_event_prereqs'

module.exports = class WorldScriptNote
  @className: 'WorldScriptNote'
  constructor: (script, @event, world) ->
    return unless script?
    @invalid = true
    return unless scriptMatchesEventPrereqs(script, @event)
    # Could add the scriptPrereqsSatisfied or seen/repeats stuff if needed
    @invalid = false
    @channel = script.channel
    @event ?= {}
    @event.replacedNoteChain = script.noteChain if script.noteChain

  serialize: ->
    o = {channel: @channel, event: {}}
    for key, value of @event
      if value?.isThang
        value = {isThang: true, id: value.id}
      else if _.isArray value
        for subval, i in value
          if subval?.isThang
            value[i] = {isThang: true, id: subval.id}
      o.event[key] = value
    o

  @deserialize: (o, world, classMap) ->
    scriptNote = new WorldScriptNote
    scriptNote.channel = o.channel
    scriptNote.event = {}
    for key, value of o.event
      if value? and typeof value is 'object' and value.isThang
        value = world.getThangByID value.id
      else if _.isArray value
        for subval, i in value
          if subval? and typeof subval is 'object' and subval.isThang
            value[i] = world.getThangByID subval.id
      else if value? and typeof value is 'object' and value.CN
        value = classMap[value.CN].deserialize value, world, classMap
      scriptNote.event[key] = value
    scriptNote
