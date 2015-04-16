describe('ScriptManager', ->
  ScriptManager = require 'lib/scripts/ScriptManager'
  xit('broadcasts note with event upon hearing from channel', ->
    note = {channel: 'cnn', event: {1: 1}}
    noteGroup = {duration: 0, notes: [note]}
    script = {channel: 'pbs', noteChain: [noteGroup]}

    sm = new ScriptManager({scripts: [script]})
    sm.paused = false

    gotEvent = {}
    f = (event) ->
      gotEvent = event
    Backbone.Mediator.subscribe('cnn', f, @)
    Backbone.Mediator.publish('pbs')
    expect(gotEvent[1]).toBe(note.event[1])
    sm.destroy()
    Backbone.Mediator.unsubscribe('cnn', f, @)
  )

  xit('is silent when script event do not match', ->
    note = {channel: 'cnn', event: {1: 1}}
    noteGroup = {duration: 0, notes: [note]}
    script =
      channel: 'pbs'
      eventPrereqs: [
        eventProps: 'foo'
        equalTo: 'bar'
      ]

      noteChain: [noteGroup]

    sm = new ScriptManager([script])
    sm.paused = false

    gotEvent = null
    f = (event) -> gotEvent = event
    Backbone.Mediator.subscribe('cnn', f, @)

    # bunch of mismatches
    Backbone.Mediator.publish('pbs', {foo: 'rad'})
    expect(gotEvent).toBeNull()
    Backbone.Mediator.publish('pbs', 'bar')
    Backbone.Mediator.publish('pbs')
    Backbone.Mediator.publish('pbs', {foo: 'bar'})
    expect(gotEvent[1]).toBe(note.event[1])
    sm.destroy()
    Backbone.Mediator.unsubscribe('cnn', f, @)
  )

  xit('makes no subscriptions when something is invalid', ->
    note = {event: {1: 1}} # channel is required
    noteGroup = {notes: [note]}
    script = {channel: 'pbs', noteChain: [noteGroup]}
    sm = new ScriptManager([script])
    expect(sm.subscriptions['pbs']).toBe(undefined)
    sm.destroy()
  )

  xit('fills out lots of notes based on note group properties', ->
    note = {channel: 'cnn', event: {1: 1}}

    noteGroup =
      duration: 0
      botPos: [1, 2]
      botMessage: 'testers'
      domHighlight: '#code-area'
      surfaceHighlights: ['Guy0', 'Guy1']
      scrubToTime: 20
      notes: [note]

    script = {channel: 'pbs', noteChain: [noteGroup]}

    sm = new ScriptManager([script])
    sm.paused = false

    Backbone.Mediator.publish('pbs')
    expect(sm.lastNoteGroup.notes.length).toBe(7)
    channels = (note.channel for note in sm.lastNoteGroup.notes)
    expect(channels).toContain('cnn')
    expect(channels).toContain('level-bot-move')
    expect(channels).toContain('level-bot-say')
    expect(channels).toContain('level-highlight-dom')
    expect(channels).toContain('level-highlight-sprites')
    expect(channels).toContain('level-set-time')
    expect(channels).toContain('level-disable-controls')
    sm.destroy()
  )

  xit('releases notes based on user confirmation', ->
    note1 = {channel: 'cnn', event: {1: 1}}
    note2 = {channel: 'cbs', event: {2: 2}}
    noteGroup1 = {duration: 0, notes: [note1]}
    noteGroup2 = {duration: 0, notes: [note2]}
    script = {channel: 'pbs', noteChain: [noteGroup1, noteGroup2]}
    sm = new ScriptManager({scripts: [script]})
    sm.paused = false

    gotCnnEvent = null
    f1 = (event) -> gotCnnEvent = event
    Backbone.Mediator.subscribe('cnn', f1, @)

    gotCbsEvent = null
    f2 = (event) -> gotCbsEvent = event
    Backbone.Mediator.subscribe('cbs', f2, @)

    Backbone.Mediator.publish('pbs')
    expect(gotCnnEvent[1]).toBe(1)
    expect(gotCbsEvent).toBeNull()
    expect(sm.scriptInProgress).toBe(true)
    runs(-> Backbone.Mediator.publish('script:end-current-script'))
    f = -> gotCbsEvent?
    waitsFor(f, 'The next event should have been published', 20)
    f = ->
      expect(gotCnnEvent[1]).toBe(1)
      expect(gotCbsEvent[2]).toBe(2)
      expect(sm.scriptInProgress).toBe(true)
      Backbone.Mediator.publish('end-current-script')
      expect(sm.scriptInProgress).toBe(false)
      sm.destroy()
      Backbone.Mediator.unsubscribe('cnn', f1, @)
      Backbone.Mediator.unsubscribe('cbs', f2, @)
    runs(f)
  )

  xit('ignores triggers for scripts waiting for other scripts to fire', ->
    # channel2 won't fire the cbs notification until channel1 does its thing
    note1 = {channel: 'cnn', event: {1: 1}}
    note2 = {channel: 'cbs', event: {2: 2}}
    noteGroup1 = {duration: 0, notes: [note1]}
    noteGroup2 = {duration: 0, notes: [note2]}
    script1 = {channel: 'channel1', id: 'channel1Script', noteChain: [noteGroup1]}
    script2 = {channel: 'channel2', scriptPrereqs: ['channel1Script'], noteChain: [noteGroup2]}

    sm = new ScriptManager([script1, script2])
    sm.paused = false
    gotCbsEvent = null
    f = (event) -> gotCbsEvent = event
    Backbone.Mediator.subscribe('cbs', f, @)

    Backbone.Mediator.publish('channel2')
    expect(gotCbsEvent).toBeNull() # channel1 hasn't done its thing yet
    Backbone.Mediator.publish('channel1')
    expect(gotCbsEvent).toBeNull() # channel2 needs to be triggered again
    Backbone.Mediator.publish('channel2')
    expect(gotCbsEvent).toBeNull() # channel1 is still waiting for user confirmation
    Backbone.Mediator.publish('script:end-current-script')
    expect(gotCbsEvent[1]).toBe(2) # and finally the second script is fired
    sm.destroy()
    Backbone.Mediator.unsubscribe('cnn', f, @)
  )
)
