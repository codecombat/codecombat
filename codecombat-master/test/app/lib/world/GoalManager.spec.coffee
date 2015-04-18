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
