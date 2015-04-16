xdescribe 'GoalManager', ->
  GoalManager = require 'lib/world/GoalManager'

  liveState =
    stateMap:
      '1': {health: 10}
      '2': {health: 5}

  halfLiveState =
    stateMap:
      '1': {health: 0}
      '2': {health: 5}

  deadState =
    stateMap:
      '1': {health: 0}
      '2': {health: -5}


  it 'can tell when everyone is dead', ->
    gm = new GoalManager(1)
    world =
      frames: [liveState, liveState, liveState]
    gm.setWorld(world)

    goal = {id: 'die', name: 'Kill Everyone', killGuy: ['1', '2']}
    gm.addGoal goal

    expect(gm.goalStates['die'].complete).toBe(false)

    world.frames.push(deadState)
    world.frames.push(deadState)
    gm.setWorld(world)
    expect(gm.goalStates['die'].complete).toBe(true)
    expect(gm.goalStates['die'].frameCompleted).toBe(3)

  it 'can tell when someone is saved', ->
    gm = new GoalManager(1)
    world =
      frames: [liveState, liveState, liveState, deadState, deadState]
    gm.setWorld(world)

    goal = {id: 'live', name: 'Save guy 2', saveGuy: '2'}
    gm.addGoal goal

    expect(gm.goalStates['live'].complete).toBe(false)
    world =
      frames: [liveState, liveState, liveState, liveState, liveState]
    gm.setWorld(world)
    expect(gm.goalStates['live'].complete).toBe(true)

#    world.frames.push(deadState)
#    world.frames.push(deadState)
#    gm.setWorld(world)
#    expect(gm.goalStates['live'].complete).toBe(true)
#    expect(gm.goalStates['live'].frameCompleted).toBe(3)
