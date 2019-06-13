factories = require 'test/app/factories'

describe('GoalManager', ->
  GoalManager = require 'lib/world/GoalManager'

  killGoal = {name: 'Kill Guy', killThangs: ['Guy1', 'Guy2'], id: 'killguy'}
  saveGoal = {name: 'Save Guy', saveThangs: ['Guy1', 'Guy2'], id: 'saveguy'}
  getToLocGoal = {name: 'Go there', getToLocation: {target: 'Frying Pan', who: 'Potato'}, id: 'id'}
  keepFromLocGoal = {name: 'Go there', keepFromLocation: {target: 'Frying Pan', who: 'Potato'}, id: 'id'}
  leaveMapGoal = {name: 'Go away', leaveOffSide: {who: 'Yall'}, id: 'id'}
  stayMapGoal =  {name: 'Stay here', keepFromLeavingOffSide: {who: 'Yall'}, id: 'id'}
  getItemGoal = {name: 'Mine', getItem: {who: 'Grabby', itemID: 'Sandwich'}, id: 'id'}
  keepItemGoal = {name: 'Not Yours', keepFromGettingItem: {who: 'Grabby', itemID: 'Sandwich'}, id: 'id'}
  additionalGoals = [{
    stage: 2,
    goals: [
      {name: 'Additional Kill Guy', killThangs: ['AdditionalKillGuy1', 'AdditionalKillGuy2'], id: 'additionalkillguy'},
      {name: 'Additional Save Guy', saveThangs: ['AdditionalSaveGuy1', 'AdditionalSaveGuy2'], id: 'additionalsaveguy'}
    ]
  }, {
    stage: 3,
    goals: [
      {name: 'Additional Kill Guy 2', killThangs: ['AdditionalKillGuy3', 'AdditionalKillGuy4'], id: 'additionalkillguy2'},
    ]
  }, {
    stage: -1,
    goals: [killGoal]
  }]
  session = null

  beforeEach ->
    session = factories.makeLevelSession({ state: { complete: false }})

  it('handles kill goal', ->
    gm = new GoalManager()
    gm.setGoals([killGoal])
    gm.worldGenerationWillBegin()
    gm.submitWorldGenerationEvent('world:thang-died', {thang: {id: 'Guy1'}}, 10)
    gm.worldGenerationEnded()
    goalStates = gm.getGoalStates()
    expect(goalStates.killguy.status).toBe('incomplete')
    expect(goalStates.killguy.killed.Guy1).toBe(true)
    expect(goalStates.killguy.killed.Guy2).toBe(false)
    expect(goalStates.killguy.keyFrame).toBe(0)

    gm.submitWorldGenerationEvent('world:thang-died', {thang: {id: 'Guy2'}}, 20)
    goalStates = gm.getGoalStates()
    expect(goalStates.killguy.status).toBe('success')
    expect(goalStates.killguy.killed.Guy1).toBe(true)
    expect(goalStates.killguy.killed.Guy2).toBe(true)
    expect(goalStates.killguy.keyFrame).toBe(20)
  )

  it('handles save goal', ->
    gm = new GoalManager()
    gm.setGoals([saveGoal])
    gm.worldGenerationWillBegin()
    gm.submitWorldGenerationEvent('world:thang-died', {thang: {id: 'Guy1'}}, 10)
    gm.worldGenerationEnded()
    goalStates = gm.getGoalStates()
    expect(goalStates.saveguy.status).toBe('failure')
    expect(goalStates.saveguy.killed.Guy1).toBe(true)
    expect(goalStates.saveguy.killed.Guy2).toBe(false)
    expect(goalStates.saveguy.keyFrame).toBe(10)

    gm = new GoalManager()
    gm.setGoals([saveGoal])
    gm.worldGenerationWillBegin()
    gm.worldGenerationEnded()
    goalStates = gm.getGoalStates()
    expect(goalStates.saveguy.status).toBe('success')
    expect(goalStates.saveguy.killed.Guy1).toBe(false)
    expect(goalStates.saveguy.killed.Guy2).toBe(false)
    expect(goalStates.saveguy.keyFrame).toBe('end')
  )

  it 'adds new additional goals without affecting old goals', ->
    gm = new GoalManager()
    # Add and complete a regular goal
    gm.setGoals([killGoal])
    gm.worldGenerationWillBegin()
    gm.submitWorldGenerationEvent('world:thang-died', {thang: {id: 'Guy1'}}, 10)
    gm.submitWorldGenerationEvent('world:thang-died', {thang: {id: 'Guy2'}}, 20)
    gm.worldGenerationEnded()

    expect(gm.getRemainingGoals().length).toBe(0)

    # Add additional goals, expecting them to be incomplete while original goals are still complete
    gm.addAdditionalGoals(session, additionalGoals)
    goalStates = gm.getGoalStates()

    expect(goalStates.killguy.status).toBe('success')
    expect(goalStates.killguy.killed.Guy1).toBe(true)
    expect(goalStates.killguy.killed.Guy2).toBe(true)
    expect(goalStates.killguy.keyFrame).toBe(20)
    expect(goalStates.additionalkillguy.status).toBe('incomplete')
    expect(goalStates.additionalkillguy.killed).toBeUndefined()
    expect(goalStates.additionalkillguy.keyFrame).toBe(0)
    expect(gm.getRemainingGoals().length).toBe(2)

  it 'adds all additionalGoals for the next stage', ->
    gm = new GoalManager()
    gm.setGoals([killGoal])
    gm.worldGenerationWillBegin()
    gm.submitWorldGenerationEvent('world:thang-died', {thang: {id: 'Guy1'}}, 10)
    gm.submitWorldGenerationEvent('world:thang-died', {thang: {id: 'Guy2'}}, 20)
    gm.worldGenerationEnded()

    goalStates = gm.getGoalStates()
    expect(goalStates.killguy.status).toBe('success')
    expect(goalStates.killguy.killed.Guy1).toBe(true)
    expect(goalStates.killguy.killed.Guy2).toBe(true)
    expect(goalStates.killguy.keyFrame).toBe(20)
    expect(gm.getRemainingGoals().length).toBe(0)

    gm.addAdditionalGoals(session, additionalGoals)
    goalStates = gm.getGoalStates()

    expect(goalStates.additionalkillguy.status).toBe('incomplete')
    expect(goalStates.additionalkillguy.killed).toBeUndefined()
    expect(goalStates.additionalkillguy.keyFrame).toBe(0)

    # Complete all goals for the world, as world generation resets goals
    gm.worldGenerationWillBegin()
    gm.submitWorldGenerationEvent('world:thang-died', {thang: {id: 'Guy1'}}, 10)
    gm.submitWorldGenerationEvent('world:thang-died', {thang: {id: 'Guy2'}}, 20)
    gm.submitWorldGenerationEvent('world:thang-died', {thang: {id: 'AdditionalKillGuy1'}}, 30)
    gm.submitWorldGenerationEvent('world:thang-died', {thang: {id: 'AdditionalKillGuy2'}}, 40)
    gm.worldGenerationEnded()
    goalStates = gm.getGoalStates()

    # Expect all additional goals to be completed
    expect(goalStates.additionalkillguy.status).toBe('success')
    expect(goalStates.additionalkillguy.killed.AdditionalKillGuy1).toBe(true)
    expect(goalStates.additionalkillguy.killed.AdditionalKillGuy2).toBe(true)
    expect(goalStates.additionalkillguy.keyFrame).toBe(40)
    expect(goalStates.additionalsaveguy.status).toBe('success')
    expect(goalStates.additionalsaveguy.killed.AdditionalSaveGuy1).toBe(false)
    expect(goalStates.additionalsaveguy.killed.AdditionalSaveGuy2).toBe(false)
    expect(goalStates.additionalsaveguy.keyFrame).toBe('end')
    expect(gm.getRemainingGoals().length).toBe(0)

  it 'does not add additionalGoals when they don\'t match the stage', ->
    gm = new GoalManager()
    gm.setGoals([killGoal])
    gm.worldGenerationWillBegin()
    gm.submitWorldGenerationEvent('world:thang-died', {thang: {id: 'Guy1'}}, 10)
    gm.submitWorldGenerationEvent('world:thang-died', {thang: {id: 'Guy2'}}, 20)
    gm.worldGenerationEnded()

    # Add additional goals and expect them to be incomplete
    gm.addAdditionalGoals(session, additionalGoals)
    goalStates = gm.getGoalStates()
    expect(goalStates.additionalkillguy.status).toBe('incomplete')
    expect(goalStates.additionalkillguy.killed).toBeUndefined()
    expect(goalStates.additionalkillguy.keyFrame).toBe(0)
    expect(goalStates.additionalsaveguy.status).toBe('incomplete')
    expect(goalStates.additionalsaveguy.keyFrame).toBe(0)

    gm.worldGenerationWillBegin()
    gm.submitWorldGenerationEvent('world:thang-died', {thang: {id: 'Guy1'}}, 10)
    gm.submitWorldGenerationEvent('world:thang-died', {thang: {id: 'Guy2'}}, 20)
    gm.submitWorldGenerationEvent('world:thang-died', {thang: {id: 'AdditionalKillGuy1'}}, 30)
    gm.submitWorldGenerationEvent('world:thang-died', {thang: {id: 'AdditionalKillGuy2'}}, 40)
    gm.worldGenerationEnded()

    goalStates = gm.getGoalStates()
    expect(goalStates.additionalkillguy2).toBeUndefined() # The goals for the next stage should not be defined yet
    expect(goalStates.additionalkillguy.killed.AdditionalKillGuy1).toBe(true)
    expect(goalStates.additionalkillguy.killed.AdditionalKillGuy2).toBe(true)
    expect(goalStates.additionalkillguy.keyFrame).toBe(40)
    expect(goalStates.additionalsaveguy.status).toBe('success')
    expect(goalStates.additionalsaveguy.killed.AdditionalSaveGuy1).toBe(false)
    expect(goalStates.additionalsaveguy.killed.AdditionalSaveGuy2).toBe(false)
    expect(goalStates.additionalsaveguy.keyFrame).toBe('end')
    expect(gm.getRemainingGoals().length).toBe(0)

  it 'reports that all goals are complete when additionalGoals have been completed', ->
    gm = new GoalManager()
    gm.setGoals([saveGoal])
    gm.worldGenerationWillBegin()
    gm.worldGenerationEnded()

    goalStates = gm.getGoalStates()
    expect(goalStates.saveguy.status).toBe('success')
    expect(goalStates.saveguy.killed.Guy1).toBe(false)
    expect(goalStates.saveguy.killed.Guy2).toBe(false)
    expect(goalStates.saveguy.keyFrame).toBe('end')

    gm.addAdditionalGoals(session, additionalGoals)

    gm.worldGenerationWillBegin()
    gm.submitWorldGenerationEvent('world:thang-died', {thang: {id: 'AdditionalKillGuy1'}}, 30)
    gm.submitWorldGenerationEvent('world:thang-died', {thang: {id: 'AdditionalKillGuy2'}}, 40)
    gm.worldGenerationEnded()

    # Both original goals (saving saveguy) and additional goals are complete, so the whole world is complete
    goalStates = gm.getGoalStates()
    expect(goalStates.saveguy.status).toBe('success')
    expect(goalStates.saveguy.killed.Guy1).toBe(false)
    expect(goalStates.saveguy.killed.Guy2).toBe(false)
    expect(goalStates.saveguy.keyFrame).toBe('end')
    expect(goalStates.additionalkillguy.status).toBe('success')
    expect(goalStates.additionalkillguy.killed.AdditionalKillGuy1).toBe(true)
    expect(goalStates.additionalkillguy.killed.AdditionalKillGuy2).toBe(true)
    expect(goalStates.additionalkillguy.keyFrame).toBe(40)
    expect(goalStates.additionalsaveguy.status).toBe('success')
    expect(goalStates.additionalsaveguy.killed.AdditionalSaveGuy1).toBe(false)
    expect(goalStates.additionalsaveguy.killed.AdditionalSaveGuy2).toBe(false)
    expect(goalStates.additionalsaveguy.keyFrame).toBe('end')
    expect(gm.getRemainingGoals().length).toBe(0)
    expect(gm.checkOverallStatus()).toBe('success')


  it 'reports that not all goals are complete when not all additionalGoals have been completed', ->
    gm = new GoalManager()
    gm.setGoals([saveGoal])
    gm.worldGenerationWillBegin()
    gm.worldGenerationEnded()

    goalStates = gm.getGoalStates()
    expect(goalStates.saveguy.status).toBe('success')
    expect(goalStates.saveguy.killed.Guy1).toBe(false)
    expect(goalStates.saveguy.killed.Guy2).toBe(false)
    expect(goalStates.saveguy.keyFrame).toBe('end')
    expect(gm.getRemainingGoals().length).toBe(0)

    gm.addAdditionalGoals(session, additionalGoals)

    # No events mean that the save goal is completed
    gm.worldGenerationWillBegin()
    gm.worldGenerationEnded()

    # Only the save goal should be complete
    goalStates = gm.getGoalStates()
    expect(goalStates.saveguy.status).toBe('success')
    expect(goalStates.saveguy.killed.Guy1).toBe(false)
    expect(goalStates.saveguy.killed.Guy2).toBe(false)
    expect(goalStates.saveguy.keyFrame).toBe('end')
    expect(goalStates.additionalkillguy.status).toBe('incomplete')
    expect(goalStates.additionalsaveguy.status).toBe('success')
    expect(goalStates.additionalsaveguy.killed.AdditionalSaveGuy1).toBe(false)
    expect(goalStates.additionalsaveguy.killed.AdditionalSaveGuy2).toBe(false)
    expect(goalStates.additionalsaveguy.keyFrame).toBe('end')
    expect(gm.getRemainingGoals().length).toBe(1)

    expect(gm.checkOverallStatus()).not.toBe('success')

  it 'progresses to the next additional goal when completing them all', ->
    # Create the goal manager in the more traditional way with a mocked session
    gm = new GoalManager(null, [saveGoal], {}, {
      session
      additionalGoals
    })
    gm.worldGenerationWillBegin()
    gm.worldGenerationEnded()

    # Use goalManager.finishLevel() to automatically progress through additionalGoals
    stageFinished = gm.finishLevel()
    expect(stageFinished).toBe(true)

    # The new goal should not be done yet
    goalStates = gm.getGoalStates()
    expect(goalStates.additionalkillguy.status).toBe('incomplete')

    gm.worldGenerationWillBegin()
    gm.submitWorldGenerationEvent('world:thang-died', {thang: {id: 'AdditionalKillGuy1'}}, 30)
    gm.submitWorldGenerationEvent('world:thang-died', {thang: {id: 'AdditionalKillGuy2'}}, 40)
    gm.worldGenerationEnded()

    stageFinished = gm.finishLevel()
    expect(stageFinished).toBe(true)

    # The new goal should not be done yet
    goalStates = gm.getGoalStates()
    expect(goalStates.additionalkillguy2.status).toBe('incomplete')

    # We have to complete all goals as the world resets when worldGenerationWillBegin() runs
    gm.worldGenerationWillBegin()
    gm.submitWorldGenerationEvent('world:thang-died', {thang: {id: 'AdditionalKillGuy1'}}, 30)
    gm.submitWorldGenerationEvent('world:thang-died', {thang: {id: 'AdditionalKillGuy2'}}, 40)
    gm.submitWorldGenerationEvent('world:thang-died', {thang: {id: 'AdditionalKillGuy3'}}, 30)
    gm.submitWorldGenerationEvent('world:thang-died', {thang: {id: 'AdditionalKillGuy4'}}, 40)
    gm.worldGenerationEnded()

    goalStates = gm.getGoalStates()

    expect(goalStates.additionalkillguy2.status).toBe('success')
    expect(goalStates.additionalkillguy2.killed.AdditionalKillGuy3).toBe(true)
    expect(goalStates.additionalkillguy2.killed.AdditionalKillGuy4).toBe(true)
    expect(goalStates.additionalkillguy2.keyFrame).toBe(40)

    # The level should now stay complete, with no new goals being added
    stageFinished = gm.finishLevel()
    expect(stageFinished).toBe(true)
    expect(gm.getRemainingGoals().length).toBe(0)
    expect(gm.checkOverallStatus()).toBe('success')

  it 'does not add goals twice for the same stage', ->
    gm = new GoalManager(null, [saveGoal], {}, {
      session
      additionalGoals
    })
    gm.worldGenerationWillBegin()
    gm.worldGenerationEnded()

    stageFinished = gm.finishLevel()
    expect(stageFinished).toBe(true)
    expect(session.get('state').capstoneStage).toBe(2)

    stageFinished = gm.finishLevel()
    expect(stageFinished).toBe(false)
    expect(session.get('state').capstoneStage).toBe(2)

  xit 'handles getToLocation', ->
    gm = new GoalManager()
    gm.setGoals([getToLocGoal])
    gm.worldGenerationWillBegin()
    gm.worldGenerationEnded()
    goalStates = gm.getGoalStates()
    expect(goalStates.id.status).toBe('incomplete')
    expect(goalStates.id.arrived.Potato).toBe(false)
    expect(goalStates.id.keyFrame).toBe(0)

    gm = new GoalManager()
    gm.setGoals([getToLocGoal])
    gm.worldGenerationWillBegin()
    gm.submitWorldGenerationEvent('world:thang-touched-goal', {actor: {id: 'Potato'}, touched: {id: 'Frying Pan'}}, 10)
    gm.worldGenerationEnded()
    goalStates = gm.getGoalStates()
    expect(goalStates.id.status).toBe('success')
    expect(goalStates.id.arrived.Potato).toBe(true)
    expect(goalStates.id.keyFrame).toBe(10)

  xit 'handles keepFromLocation', ->
    gm = new GoalManager()
    gm.setGoals([keepFromLocGoal])
    gm.worldGenerationWillBegin()
    gm.submitWorldGenerationEvent('world:thang-touched-goal', {actor: {id: 'Potato'}, touched: {id: 'Frying Pan'}}, 10)
    gm.worldGenerationEnded()
    goalStates = gm.getGoalStates()
    expect(goalStates.id.status).toBe('failure')
    expect(goalStates.id.arrived.Potato).toBe(true)
    expect(goalStates.id.keyFrame).toBe(10)

    gm = new GoalManager()
    gm.setGoals([keepFromLocGoal])
    gm.worldGenerationWillBegin()
    gm.worldGenerationEnded()
    goalStates = gm.getGoalStates()
    expect(goalStates.id.status).toBe('success')
    expect(goalStates.id.arrived.Potato).toBe(false)
    expect(goalStates.id.keyFrame).toBe('end')

  xit 'handles leaveOffSide', ->
    gm = new GoalManager()
    gm.setGoals([leaveMapGoal])
    gm.worldGenerationWillBegin()
    gm.worldGenerationEnded()
    goalStates = gm.getGoalStates()
    expect(goalStates.id.status).toBe('incomplete')
    expect(goalStates.id.left.Yall).toBe(false)
    expect(goalStates.id.keyFrame).toBe(0)

    gm = new GoalManager()
    gm.setGoals([leaveMapGoal])
    gm.worldGenerationWillBegin()
    gm.submitWorldGenerationEvent('world:thang-left-map', {thang: {id: 'Yall'}}, 10)
    gm.worldGenerationEnded()
    goalStates = gm.getGoalStates()
    expect(goalStates.id.status).toBe('success')
    expect(goalStates.id.left.Yall).toBe(true)
    expect(goalStates.id.keyFrame).toBe(10)

  xit 'handles keepFromLeavingOffSide', ->
    gm = new GoalManager()
    gm.setGoals([stayMapGoal])
    gm.worldGenerationWillBegin()
    gm.submitWorldGenerationEvent('world:thang-left-map', {thang: {id: 'Yall'}}, 10)
    gm.worldGenerationEnded()
    goalStates = gm.getGoalStates()
    expect(goalStates.id.status).toBe('failure')
    expect(goalStates.id.left.Yall).toBe(true)
    expect(goalStates.id.keyFrame).toBe(10)

    gm = new GoalManager()
    gm.setGoals([stayMapGoal])
    gm.worldGenerationWillBegin()
    gm.worldGenerationEnded()
    goalStates = gm.getGoalStates()
    expect(goalStates.id.status).toBe('success')
    expect(goalStates.id.left.Yall).toBe(false)
    expect(goalStates.id.keyFrame).toBe('end')

  xit 'handles getItem', ->
    gm = new GoalManager()
    gm.setGoals([getItemGoal])
    gm.worldGenerationWillBegin()
    gm.worldGenerationEnded()
    goalStates = gm.getGoalStates()
    expect(goalStates.id.status).toBe('incomplete')
    expect(goalStates.id.collected.Grabby).toBe(false)
    expect(goalStates.id.keyFrame).toBe(0)

    gm = new GoalManager()
    gm.setGoals([getItemGoal])
    gm.worldGenerationWillBegin()
    gm.submitWorldGenerationEvent('world:thang-collected-item', {actor: {id: 'Grabby'}, item: {id: 'Sandwich'}}, 10)
    gm.worldGenerationEnded()
    goalStates = gm.getGoalStates()
    expect(goalStates.id.status).toBe('success')
    expect(goalStates.id.collected.Grabby).toBe(true)
    expect(goalStates.id.keyFrame).toBe(10)

  xit 'handles keepFromGettingItem', ->
    gm = new GoalManager()
    gm.setGoals([keepItemGoal])
    gm.worldGenerationWillBegin()
    gm.submitWorldGenerationEvent('world:thang-collected-item', {actor: {id: 'Grabby'}, item: {id: 'Sandwich'}}, 10)
    gm.worldGenerationEnded()
    goalStates = gm.getGoalStates()
    expect(goalStates.id.status).toBe('failure')
    expect(goalStates.id.collected.Grabby).toBe(true)
    expect(goalStates.id.keyFrame).toBe(10)

    gm = new GoalManager()
    gm.setGoals([keepItemGoal])
    gm.worldGenerationWillBegin()
    gm.worldGenerationEnded()
    goalStates = gm.getGoalStates()
    expect(goalStates.id.status).toBe('success')
    expect(goalStates.id.collected.Grabby).toBe(false)
    expect(goalStates.id.keyFrame).toBe('end'))
