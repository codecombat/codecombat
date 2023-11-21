/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
xdescribe('GoalManager', function() {
  const GoalManager = require('lib/world/GoalManager');

  const liveState = {
    stateMap: {
      '1': {health: 10},
      '2': {health: 5}
    }
  };

  const halfLiveState = {
    stateMap: {
      '1': {health: 0},
      '2': {health: 5}
    }
  };

  const deadState = {
    stateMap: {
      '1': {health: 0},
      '2': {health: -5}
    }
  };


  it('can tell when everyone is dead', function() {
    const gm = new GoalManager(1);
    const world =
      {frames: [liveState, liveState, liveState]};
    gm.setWorld(world);

    const goal = {id: 'die', name: 'Kill Everyone', killGuy: ['1', '2']};
    gm.addGoal(goal);

    expect(gm.goalStates['die'].complete).toBe(false);

    world.frames.push(deadState);
    world.frames.push(deadState);
    gm.setWorld(world);
    expect(gm.goalStates['die'].complete).toBe(true);
    return expect(gm.goalStates['die'].frameCompleted).toBe(3);
  });

  return it('can tell when someone is saved', function() {
    const gm = new GoalManager(1);
    let world =
      {frames: [liveState, liveState, liveState, deadState, deadState]};
    gm.setWorld(world);

    const goal = {id: 'live', name: 'Save guy 2', saveGuy: '2'};
    gm.addGoal(goal);

    expect(gm.goalStates['live'].complete).toBe(false);
    world =
      {frames: [liveState, liveState, liveState, liveState, liveState]};
    gm.setWorld(world);
    return expect(gm.goalStates['live'].complete).toBe(true);
  });
});

//    world.frames.push(deadState)
//    world.frames.push(deadState)
//    gm.setWorld(world)
//    expect(gm.goalStates['live'].complete).toBe(true)
//    expect(gm.goalStates['live'].frameCompleted).toBe(3)
