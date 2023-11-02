/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS205: Consider reworking code to avoid use of IIFEs
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
describe('ScriptManager', function() {
  const ScriptManager = require('lib/scripts/ScriptManager');
  xit('broadcasts note with event upon hearing from channel', function() {
    const note = {channel: 'cnn', event: {1: 1}};
    const noteGroup = {duration: 0, notes: [note]};
    const script = {channel: 'pbs', noteChain: [noteGroup]};

    const sm = new ScriptManager({scripts: [script]});
    sm.paused = false;

    let gotEvent = {};
    const f = event => gotEvent = event;
    Backbone.Mediator.subscribe('cnn', f, this);
    Backbone.Mediator.publish('pbs');
    expect(gotEvent[1]).toBe(note.event[1]);
    sm.destroy();
    return Backbone.Mediator.unsubscribe('cnn', f, this);
  });

  xit('is silent when script event do not match', function() {
    const note = {channel: 'cnn', event: {1: 1}};
    const noteGroup = {duration: 0, notes: [note]};
    const script = {
      channel: 'pbs',
      eventPrereqs: [{
        eventProps: 'foo',
        equalTo: 'bar'
      }
      ],

      noteChain: [noteGroup]
    };

    const sm = new ScriptManager([script]);
    sm.paused = false;

    let gotEvent = null;
    const f = event => gotEvent = event;
    Backbone.Mediator.subscribe('cnn', f, this);

    // bunch of mismatches
    Backbone.Mediator.publish('pbs', {foo: 'rad'});
    expect(gotEvent).toBeNull();
    Backbone.Mediator.publish('pbs', 'bar');
    Backbone.Mediator.publish('pbs');
    Backbone.Mediator.publish('pbs', {foo: 'bar'});
    expect(gotEvent[1]).toBe(note.event[1]);
    sm.destroy();
    return Backbone.Mediator.unsubscribe('cnn', f, this);
  });

  xit('makes no subscriptions when something is invalid', function() {
    const note = {event: {1: 1}}; // channel is required
    const noteGroup = {notes: [note]};
    const script = {channel: 'pbs', noteChain: [noteGroup]};
    const sm = new ScriptManager([script]);
    expect(sm.subscriptions['pbs']).toBe(undefined);
    return sm.destroy();
  });

  xit('fills out lots of notes based on note group properties', function() {
    let note;
    note = {channel: 'cnn', event: {1: 1}};

    const noteGroup = {
      duration: 0,
      botPos: [1, 2],
      botMessage: 'testers',
      domHighlight: '#code-area',
      surfaceHighlights: ['Guy0', 'Guy1'],
      scrubToTime: 20,
      notes: [note]
    };

    const script = {channel: 'pbs', noteChain: [noteGroup]};

    const sm = new ScriptManager([script]);
    sm.paused = false;

    Backbone.Mediator.publish('pbs');
    expect(sm.lastNoteGroup.notes.length).toBe(7);
    const channels = ((() => {
      const result = [];
      for (note of Array.from(sm.lastNoteGroup.notes)) {         result.push(note.channel);
      }
      return result;
    })());
    expect(channels).toContain('cnn');
    expect(channels).toContain('level-bot-move');
    expect(channels).toContain('level-bot-say');
    expect(channels).toContain('level-highlight-dom');
    expect(channels).toContain('level-highlight-sprites');
    expect(channels).toContain('level-set-time');
    expect(channels).toContain('level-disable-controls');
    return sm.destroy();
  });

  xit('releases notes based on user confirmation', function() {
    const note1 = {channel: 'cnn', event: {1: 1}};
    const note2 = {channel: 'cbs', event: {2: 2}};
    const noteGroup1 = {duration: 0, notes: [note1]};
    const noteGroup2 = {duration: 0, notes: [note2]};
    const script = {channel: 'pbs', noteChain: [noteGroup1, noteGroup2]};
    const sm = new ScriptManager({scripts: [script]});
    sm.paused = false;

    let gotCnnEvent = null;
    const f1 = event => gotCnnEvent = event;
    Backbone.Mediator.subscribe('cnn', f1, this);

    let gotCbsEvent = null;
    const f2 = event => gotCbsEvent = event;
    Backbone.Mediator.subscribe('cbs', f2, this);

    Backbone.Mediator.publish('pbs');
    expect(gotCnnEvent[1]).toBe(1);
    expect(gotCbsEvent).toBeNull();
    expect(sm.scriptInProgress).toBe(true);
    runs(() => Backbone.Mediator.publish('script:end-current-script'));
    let f = () => gotCbsEvent != null;
    waitsFor(f, 'The next event should have been published', 20);
    f = function() {
      expect(gotCnnEvent[1]).toBe(1);
      expect(gotCbsEvent[2]).toBe(2);
      expect(sm.scriptInProgress).toBe(true);
      Backbone.Mediator.publish('end-current-script');
      expect(sm.scriptInProgress).toBe(false);
      sm.destroy();
      Backbone.Mediator.unsubscribe('cnn', f1, this);
      return Backbone.Mediator.unsubscribe('cbs', f2, this);
    };
    return runs(f);
  });

  return xit('ignores triggers for scripts waiting for other scripts to fire', function() {
    // channel2 won't fire the cbs notification until channel1 does its thing
    const note1 = {channel: 'cnn', event: {1: 1}};
    const note2 = {channel: 'cbs', event: {2: 2}};
    const noteGroup1 = {duration: 0, notes: [note1]};
    const noteGroup2 = {duration: 0, notes: [note2]};
    const script1 = {channel: 'channel1', id: 'channel1Script', noteChain: [noteGroup1]};
    const script2 = {channel: 'channel2', scriptPrereqs: ['channel1Script'], noteChain: [noteGroup2]};

    const sm = new ScriptManager([script1, script2]);
    sm.paused = false;
    let gotCbsEvent = null;
    const f = event => gotCbsEvent = event;
    Backbone.Mediator.subscribe('cbs', f, this);

    Backbone.Mediator.publish('channel2');
    expect(gotCbsEvent).toBeNull(); // channel1 hasn't done its thing yet
    Backbone.Mediator.publish('channel1');
    expect(gotCbsEvent).toBeNull(); // channel2 needs to be triggered again
    Backbone.Mediator.publish('channel2');
    expect(gotCbsEvent).toBeNull(); // channel1 is still waiting for user confirmation
    Backbone.Mediator.publish('script:end-current-script');
    expect(gotCbsEvent[1]).toBe(2); // and finally the second script is fired
    sm.destroy();
    return Backbone.Mediator.unsubscribe('cnn', f, this);
  });
});
