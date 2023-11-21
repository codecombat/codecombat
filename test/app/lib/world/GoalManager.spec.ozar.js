/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
const factories = require('test/app/factories');

xdescribe('GoalManager', function() {
  const GoalManager = require('lib/world/GoalManager');

  const killGoal = {name: 'Kill Guy', killThangs: ['Guy1', 'Guy2'], id: 'killguy'};
  const saveGoal = {name: 'Save Guy', saveThangs: ['Guy1', 'Guy2'], id: 'saveguy'};
  const getToLocGoal = {name: 'Go there', getToLocation: {target: 'Frying Pan', who: 'Potato'}, id: 'id'};
  const keepFromLocGoal = {name: 'Go there', keepFromLocation: {target: 'Frying Pan', who: 'Potato'}, id: 'id'};
  const leaveMapGoal = {name: 'Go away', leaveOffSide: {who: 'Yall'}, id: 'id'};
  const stayMapGoal =  {name: 'Stay here', keepFromLeavingOffSide: {who: 'Yall'}, id: 'id'};
  const getItemGoal = {name: 'Mine', getItem: {who: 'Grabby', itemID: 'Sandwich'}, id: 'id'};
  const keepItemGoal = {name: 'Not Yours', keepFromGettingItem: {who: 'Grabby', itemID: 'Sandwich'}, id: 'id'};
  const additionalGoals = [{
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
  }];
  let session = null;

  beforeEach(() => session = factories.makeLevelSession({ state: { complete: false, stage: 1 }}));

  it('handles kill goal', function() {
    const gm = new GoalManager();
    gm.setGoals([killGoal]);
    gm.worldGenerationWillBegin();
    gm.submitWorldGenerationEvent('world:thang-died', {thang: {id: 'Guy1'}}, 10);
    gm.worldGenerationEnded();
    let goalStates = gm.getGoalStates();
    expect(goalStates.killguy.status).toBe('incomplete');
    expect(goalStates.killguy.killed.Guy1).toBe(true);
    expect(goalStates.killguy.killed.Guy2).toBe(false);
    expect(goalStates.killguy.keyFrame).toBe(0);

    gm.submitWorldGenerationEvent('world:thang-died', {thang: {id: 'Guy2'}}, 20);
    goalStates = gm.getGoalStates();
    expect(goalStates.killguy.status).toBe('success');
    expect(goalStates.killguy.killed.Guy1).toBe(true);
    expect(goalStates.killguy.killed.Guy2).toBe(true);
    return expect(goalStates.killguy.keyFrame).toBe(20);
  });

  it('handles save goal', function() {
    let gm = new GoalManager();
    gm.setGoals([saveGoal]);
    gm.worldGenerationWillBegin();
    gm.submitWorldGenerationEvent('world:thang-died', {thang: {id: 'Guy1'}}, 10);
    gm.worldGenerationEnded();
    let goalStates = gm.getGoalStates();
    expect(goalStates.saveguy.status).toBe('failure');
    expect(goalStates.saveguy.killed.Guy1).toBe(true);
    expect(goalStates.saveguy.killed.Guy2).toBe(false);
    expect(goalStates.saveguy.keyFrame).toBe(10);

    gm = new GoalManager();
    gm.setGoals([saveGoal]);
    gm.worldGenerationWillBegin();
    gm.worldGenerationEnded();
    goalStates = gm.getGoalStates();
    expect(goalStates.saveguy.status).toBe('success');
    expect(goalStates.saveguy.killed.Guy1).toBe(false);
    expect(goalStates.saveguy.killed.Guy2).toBe(false);
    return expect(goalStates.saveguy.keyFrame).toBe('end');
  });

  it('adds new additional goals without affecting old goals', function() {
    const gm = new GoalManager();
    // Add and complete a regular goal
    gm.setGoals([killGoal]);
    gm.worldGenerationWillBegin();
    gm.submitWorldGenerationEvent('world:thang-died', {thang: {id: 'Guy1'}}, 10);
    gm.submitWorldGenerationEvent('world:thang-died', {thang: {id: 'Guy2'}}, 20);
    gm.worldGenerationEnded();

    expect(gm.getRemainingGoals().length).toBe(0);

    // Progress to the next capstoneStage without affecting goals
    gm.progressCapstoneStage(session, additionalGoals);
    let goalStates = gm.getGoalStates();
    expect(goalStates.killguy.status).toBe('success');
    expect(goalStates.killguy.killed.Guy1).toBe(true);
    expect(goalStates.killguy.killed.Guy2).toBe(true);
    expect(goalStates.killguy.keyFrame).toBe(20);
    expect(session.get('state').capstoneStage).toBe(2);

    // Add additional goals, expecting them to be incomplete while original goals are still complete
    const newGm = new GoalManager(undefined, [killGoal], undefined, { session, additionalGoals });
    newGm.worldGenerationWillBegin();
    newGm.submitWorldGenerationEvent('world:thang-died', {thang: {id: 'Guy1'}}, 10);
    newGm.submitWorldGenerationEvent('world:thang-died', {thang: {id: 'Guy2'}}, 20);
    newGm.worldGenerationEnded();

    goalStates = newGm.getGoalStates();
    expect(goalStates.killguy.status).toBe('success');
    expect(goalStates.killguy.killed.Guy1).toBe(true);
    expect(goalStates.killguy.killed.Guy2).toBe(true);
    expect(goalStates.killguy.keyFrame).toBe(20);
    expect(goalStates.additionalkillguy.status).toBe('incomplete');
    expect(goalStates.additionalkillguy.killed.Guy1).toBe(undefined);
    expect(goalStates.additionalkillguy.killed.Guy2).toBe(undefined);
    expect(goalStates.additionalkillguy.keyFrame).toBe(0);
    return expect(newGm.getRemainingGoals().length).toBe(1);
  });

  it('does not progress past the same stage twice in one goal manager', function() {
    const gm = new GoalManager(null, [saveGoal], {}, {
      session,
      additionalGoals
    });
    gm.worldGenerationWillBegin();
    gm.worldGenerationEnded();

    let stageFinished = gm.finishLevel();
    expect(stageFinished).toBe(true);
    expect(session.get('state').capstoneStage).toBe(2);

    stageFinished = gm.finishLevel();
    return expect(session.get('state').capstoneStage).toBe(2);
  });


  it('adds all additionalGoals for the next stage', function() {
    const gm = new GoalManager();
    gm.setGoals([killGoal]);
    gm.worldGenerationWillBegin();
    gm.submitWorldGenerationEvent('world:thang-died', {thang: {id: 'Guy1'}}, 10);
    gm.submitWorldGenerationEvent('world:thang-died', {thang: {id: 'Guy2'}}, 20);
    gm.worldGenerationEnded();

    let goalStates = gm.getGoalStates();
    expect(goalStates.killguy.status).toBe('success');
    expect(goalStates.killguy.killed.Guy1).toBe(true);
    expect(goalStates.killguy.killed.Guy2).toBe(true);
    expect(goalStates.killguy.keyFrame).toBe(20);
    expect(gm.getRemainingGoals().length).toBe(0);

    gm.progressCapstoneStage(session, additionalGoals);

    expect(session.get('state').capstoneStage).toBe(2);
    const newGm = new GoalManager(null, [killGoal], {}, {
      session,
      additionalGoals
    });

    newGm.worldGenerationWillBegin();
    newGm.submitWorldGenerationEvent('world:thang-died', {thang: {id: 'Guy1'}}, 10);
    newGm.submitWorldGenerationEvent('world:thang-died', {thang: {id: 'Guy2'}}, 20);
    newGm.worldGenerationEnded();

    goalStates = newGm.getGoalStates();
    expect(goalStates.additionalkillguy.status).toBe('incomplete');
    expect(goalStates.additionalkillguy.killed.AdditionalKillGuy1).toBe(false);
    expect(goalStates.additionalkillguy.killed.AdditionalKillGuy1).toBe(false);
    expect(goalStates.additionalkillguy.keyFrame).toBe(0);

    // Complete all goals for the world, as world generation resets goals
    newGm.worldGenerationWillBegin();
    newGm.submitWorldGenerationEvent('world:thang-died', {thang: {id: 'Guy1'}}, 10);
    newGm.submitWorldGenerationEvent('world:thang-died', {thang: {id: 'Guy2'}}, 20);
    newGm.submitWorldGenerationEvent('world:thang-died', {thang: {id: 'AdditionalKillGuy1'}}, 30);
    newGm.submitWorldGenerationEvent('world:thang-died', {thang: {id: 'AdditionalKillGuy2'}}, 40);
    newGm.worldGenerationEnded();
    goalStates = newGm.getGoalStates();

    // Expect all additional goals to be completed
    expect(goalStates.additionalkillguy.status).toBe('success');
    expect(goalStates.additionalkillguy.killed.AdditionalKillGuy1).toBe(true);
    expect(goalStates.additionalkillguy.killed.AdditionalKillGuy2).toBe(true);
    expect(goalStates.additionalkillguy.keyFrame).toBe(40);
    expect(goalStates.additionalsaveguy.status).toBe('success');
    expect(goalStates.additionalsaveguy.killed.AdditionalSaveGuy1).toBe(false);
    expect(goalStates.additionalsaveguy.killed.AdditionalSaveGuy2).toBe(false);
    expect(goalStates.additionalsaveguy.keyFrame).toBe('end');
    return expect(newGm.getRemainingGoals().length).toBe(0);
  });

  it('does not add additionalGoals when they don\'t match the stage', function() {
    const gm = new GoalManager();
    gm.setGoals([killGoal]);
    gm.worldGenerationWillBegin();
    gm.submitWorldGenerationEvent('world:thang-died', {thang: {id: 'Guy1'}}, 10);
    gm.submitWorldGenerationEvent('world:thang-died', {thang: {id: 'Guy2'}}, 20);
    gm.worldGenerationEnded();

    gm.progressCapstoneStage(session, additionalGoals);
    expect(session.get('state').capstoneStage).toBe(2);

    const newGm = new GoalManager(null, [killGoal], {}, {
      session,
      additionalGoals
    });
    newGm.worldGenerationWillBegin();
    newGm.submitWorldGenerationEvent('world:thang-died', {thang: {id: 'Guy1'}}, 10);
    newGm.submitWorldGenerationEvent('world:thang-died', {thang: {id: 'Guy2'}}, 20);
    newGm.worldGenerationEnded();

    // Add additional goals and expect them to be incomplete
    let goalStates = newGm.getGoalStates();
    expect(goalStates.additionalkillguy.status).toBe('incomplete');
    expect(goalStates.additionalkillguy.killed.AdditionalKillGuy1).toBe(false);
    expect(goalStates.additionalkillguy.killed.AdditionalKillGuy1).toBe(false);
    expect(goalStates.additionalkillguy.keyFrame).toBe(0);
    expect(goalStates.additionalsaveguy.status).toBe('success');
    expect(goalStates.additionalsaveguy.keyFrame).toBe('end');

    newGm.worldGenerationWillBegin();
    newGm.submitWorldGenerationEvent('world:thang-died', {thang: {id: 'Guy1'}}, 10);
    newGm.submitWorldGenerationEvent('world:thang-died', {thang: {id: 'Guy2'}}, 20);
    newGm.submitWorldGenerationEvent('world:thang-died', {thang: {id: 'AdditionalKillGuy1'}}, 30);
    newGm.submitWorldGenerationEvent('world:thang-died', {thang: {id: 'AdditionalKillGuy2'}}, 40);
    newGm.worldGenerationEnded();

    goalStates = newGm.getGoalStates();
    expect(goalStates.additionalkillguy2).toBeUndefined(); // The goals for the next stage should not be defined yet
    expect(goalStates.additionalkillguy.killed.AdditionalKillGuy1).toBe(true);
    expect(goalStates.additionalkillguy.killed.AdditionalKillGuy2).toBe(true);
    expect(goalStates.additionalkillguy.keyFrame).toBe(40);
    expect(goalStates.additionalsaveguy.status).toBe('success');
    expect(goalStates.additionalsaveguy.killed.AdditionalSaveGuy1).toBe(false);
    expect(goalStates.additionalsaveguy.killed.AdditionalSaveGuy2).toBe(false);
    expect(goalStates.additionalsaveguy.keyFrame).toBe('end');
    return expect(newGm.getRemainingGoals().length).toBe(0);
  });

  it('reports that all goals are complete when additionalGoals have been completed', function() {
    const gm = new GoalManager();
    gm.setGoals([saveGoal]);
    gm.worldGenerationWillBegin();
    gm.worldGenerationEnded();

    let goalStates = gm.getGoalStates();
    expect(goalStates.saveguy.status).toBe('success');
    expect(goalStates.saveguy.killed.Guy1).toBe(false);
    expect(goalStates.saveguy.killed.Guy2).toBe(false);
    expect(goalStates.saveguy.keyFrame).toBe('end');

    gm.progressCapstoneStage(session, additionalGoals);

    expect(session.get('state').capstoneStage).toBe(2);
    const newGm = new GoalManager(null, [saveGoal], {}, {
      session,
      additionalGoals
    });

    newGm.worldGenerationWillBegin();
    newGm.submitWorldGenerationEvent('world:thang-died', {thang: {id: 'AdditionalKillGuy1'}}, 30);
    newGm.submitWorldGenerationEvent('world:thang-died', {thang: {id: 'AdditionalKillGuy2'}}, 40);
    newGm.worldGenerationEnded();

    // Both original goals (saving saveguy) and additional goals are complete, so the whole world is complete
    goalStates = newGm.getGoalStates();
    expect(goalStates.saveguy.status).toBe('success');
    expect(goalStates.saveguy.killed.Guy1).toBe(false);
    expect(goalStates.saveguy.killed.Guy2).toBe(false);
    expect(goalStates.saveguy.keyFrame).toBe('end');
    expect(goalStates.additionalkillguy.status).toBe('success');
    expect(goalStates.additionalkillguy.killed.AdditionalKillGuy1).toBe(true);
    expect(goalStates.additionalkillguy.killed.AdditionalKillGuy2).toBe(true);
    expect(goalStates.additionalkillguy.keyFrame).toBe(40);
    expect(goalStates.additionalsaveguy.status).toBe('success');
    expect(goalStates.additionalsaveguy.killed.AdditionalSaveGuy1).toBe(false);
    expect(goalStates.additionalsaveguy.killed.AdditionalSaveGuy2).toBe(false);
    expect(goalStates.additionalsaveguy.keyFrame).toBe('end');
    expect(newGm.getRemainingGoals().length).toBe(0);
    return expect(newGm.checkOverallStatus()).toBe('success');
  });

  it('reports that not all goals are complete when not all additionalGoals have been completed', function() {
    const gm = new GoalManager();
    gm.setGoals([saveGoal]);
    gm.worldGenerationWillBegin();
    gm.worldGenerationEnded();

    let goalStates = gm.getGoalStates();
    expect(goalStates.saveguy.status).toBe('success');
    expect(goalStates.saveguy.killed.Guy1).toBe(false);
    expect(goalStates.saveguy.killed.Guy2).toBe(false);
    expect(goalStates.saveguy.keyFrame).toBe('end');
    expect(gm.getRemainingGoals().length).toBe(0);

    gm.progressCapstoneStage(session, additionalGoals);
    expect(session.get('state').capstoneStage).toBe(2);

    const newGm = new GoalManager(null, [saveGoal], {}, {
      session,
      additionalGoals
    });
    // No events mean that the save goal is completed
    newGm.worldGenerationWillBegin();
    newGm.worldGenerationEnded();

    // Only the save goal should be complete
    goalStates = newGm.getGoalStates();
    expect(goalStates.saveguy.status).toBe('success');
    expect(goalStates.saveguy.killed.Guy1).toBe(false);
    expect(goalStates.saveguy.killed.Guy2).toBe(false);
    expect(goalStates.saveguy.keyFrame).toBe('end');
    expect(goalStates.additionalkillguy.status).toBe('incomplete');
    expect(goalStates.additionalsaveguy.status).toBe('success');
    expect(goalStates.additionalsaveguy.killed.AdditionalSaveGuy1).toBe(false);
    expect(goalStates.additionalsaveguy.killed.AdditionalSaveGuy2).toBe(false);
    expect(goalStates.additionalsaveguy.keyFrame).toBe('end');
    expect(newGm.getRemainingGoals().length).toBe(1);
    return expect(newGm.checkOverallStatus()).not.toBe('success');
  });

  it('progresses to the next capstoneStage when completing all goals', function() {
    // Create the goal manager in the more traditional way with a mocked session
    const gm = new GoalManager(null, [saveGoal], {}, {
      session,
      additionalGoals
    });
    gm.worldGenerationWillBegin();
    gm.worldGenerationEnded();

    // Use goalManager.finishLevel() to progress through capstoneStages
    let stageFinished = gm.finishLevel();
    expect(stageFinished).toBe(true);
    expect(session.get('state').capstoneStage).toBe(2);

    // The new goal should not exist yet
    let goalStates = gm.getGoalStates();
    expect(goalStates.additionalkillguy).toBeUndefined();

    const newGm = new GoalManager(null, [saveGoal], {}, {
      session,
      additionalGoals
    });

    newGm.worldGenerationWillBegin();
    newGm.submitWorldGenerationEvent('world:thang-died', {thang: {id: 'AdditionalKillGuy1'}}, 30);
    newGm.submitWorldGenerationEvent('world:thang-died', {thang: {id: 'AdditionalKillGuy2'}}, 40);
    newGm.worldGenerationEnded();

    stageFinished = newGm.finishLevel();
    expect(stageFinished).toBe(true);
    expect(session.get('state').capstoneStage).toBe(3);

    const newGm2 = new GoalManager(null, [saveGoal], {}, {
      session,
      additionalGoals
    });

    // We have to complete all goals as the world resets when worldGenerationWillBegin() runs
    newGm2.worldGenerationWillBegin();
    newGm2.submitWorldGenerationEvent('world:thang-died', {thang: {id: 'AdditionalKillGuy1'}}, 30);
    newGm2.submitWorldGenerationEvent('world:thang-died', {thang: {id: 'AdditionalKillGuy2'}}, 40);
    newGm2.submitWorldGenerationEvent('world:thang-died', {thang: {id: 'AdditionalKillGuy3'}}, 30);
    newGm2.submitWorldGenerationEvent('world:thang-died', {thang: {id: 'AdditionalKillGuy4'}}, 40);
    newGm2.worldGenerationEnded();

    goalStates = newGm2.getGoalStates();

    expect(goalStates.additionalkillguy2.status).toBe('success');
    expect(goalStates.additionalkillguy2.killed.AdditionalKillGuy3).toBe(true);
    expect(goalStates.additionalkillguy2.killed.AdditionalKillGuy4).toBe(true);
    expect(goalStates.additionalkillguy2.keyFrame).toBe(40);

    // The level should now stay complete, with no new goals being added
    stageFinished = newGm2.finishLevel();
    expect(session.get('state').capstoneStage).toBe(4);
    expect(stageFinished).toBe(true);
    expect(newGm2.getRemainingGoals().length).toBe(0);
    return expect(newGm2.checkOverallStatus()).toBe('success');
  });

  xit('handles getToLocation', function() {
    let gm = new GoalManager();
    gm.setGoals([getToLocGoal]);
    gm.worldGenerationWillBegin();
    gm.worldGenerationEnded();
    let goalStates = gm.getGoalStates();
    expect(goalStates.id.status).toBe('incomplete');
    expect(goalStates.id.arrived.Potato).toBe(false);
    expect(goalStates.id.keyFrame).toBe(0);

    gm = new GoalManager();
    gm.setGoals([getToLocGoal]);
    gm.worldGenerationWillBegin();
    gm.submitWorldGenerationEvent('world:thang-touched-goal', {actor: {id: 'Potato'}, touched: {id: 'Frying Pan'}}, 10);
    gm.worldGenerationEnded();
    goalStates = gm.getGoalStates();
    expect(goalStates.id.status).toBe('success');
    expect(goalStates.id.arrived.Potato).toBe(true);
    return expect(goalStates.id.keyFrame).toBe(10);
  });

  xit('handles keepFromLocation', function() {
    let gm = new GoalManager();
    gm.setGoals([keepFromLocGoal]);
    gm.worldGenerationWillBegin();
    gm.submitWorldGenerationEvent('world:thang-touched-goal', {actor: {id: 'Potato'}, touched: {id: 'Frying Pan'}}, 10);
    gm.worldGenerationEnded();
    let goalStates = gm.getGoalStates();
    expect(goalStates.id.status).toBe('failure');
    expect(goalStates.id.arrived.Potato).toBe(true);
    expect(goalStates.id.keyFrame).toBe(10);

    gm = new GoalManager();
    gm.setGoals([keepFromLocGoal]);
    gm.worldGenerationWillBegin();
    gm.worldGenerationEnded();
    goalStates = gm.getGoalStates();
    expect(goalStates.id.status).toBe('success');
    expect(goalStates.id.arrived.Potato).toBe(false);
    return expect(goalStates.id.keyFrame).toBe('end');
  });

  xit('handles leaveOffSide', function() {
    let gm = new GoalManager();
    gm.setGoals([leaveMapGoal]);
    gm.worldGenerationWillBegin();
    gm.worldGenerationEnded();
    let goalStates = gm.getGoalStates();
    expect(goalStates.id.status).toBe('incomplete');
    expect(goalStates.id.left.Yall).toBe(false);
    expect(goalStates.id.keyFrame).toBe(0);

    gm = new GoalManager();
    gm.setGoals([leaveMapGoal]);
    gm.worldGenerationWillBegin();
    gm.submitWorldGenerationEvent('world:thang-left-map', {thang: {id: 'Yall'}}, 10);
    gm.worldGenerationEnded();
    goalStates = gm.getGoalStates();
    expect(goalStates.id.status).toBe('success');
    expect(goalStates.id.left.Yall).toBe(true);
    return expect(goalStates.id.keyFrame).toBe(10);
  });

  xit('handles keepFromLeavingOffSide', function() {
    let gm = new GoalManager();
    gm.setGoals([stayMapGoal]);
    gm.worldGenerationWillBegin();
    gm.submitWorldGenerationEvent('world:thang-left-map', {thang: {id: 'Yall'}}, 10);
    gm.worldGenerationEnded();
    let goalStates = gm.getGoalStates();
    expect(goalStates.id.status).toBe('failure');
    expect(goalStates.id.left.Yall).toBe(true);
    expect(goalStates.id.keyFrame).toBe(10);

    gm = new GoalManager();
    gm.setGoals([stayMapGoal]);
    gm.worldGenerationWillBegin();
    gm.worldGenerationEnded();
    goalStates = gm.getGoalStates();
    expect(goalStates.id.status).toBe('success');
    expect(goalStates.id.left.Yall).toBe(false);
    return expect(goalStates.id.keyFrame).toBe('end');
  });

  xit('handles getItem', function() {
    let gm = new GoalManager();
    gm.setGoals([getItemGoal]);
    gm.worldGenerationWillBegin();
    gm.worldGenerationEnded();
    let goalStates = gm.getGoalStates();
    expect(goalStates.id.status).toBe('incomplete');
    expect(goalStates.id.collected.Grabby).toBe(false);
    expect(goalStates.id.keyFrame).toBe(0);

    gm = new GoalManager();
    gm.setGoals([getItemGoal]);
    gm.worldGenerationWillBegin();
    gm.submitWorldGenerationEvent('world:thang-collected-item', {actor: {id: 'Grabby'}, item: {id: 'Sandwich'}}, 10);
    gm.worldGenerationEnded();
    goalStates = gm.getGoalStates();
    expect(goalStates.id.status).toBe('success');
    expect(goalStates.id.collected.Grabby).toBe(true);
    return expect(goalStates.id.keyFrame).toBe(10);
  });

  return xit('handles keepFromGettingItem', function() {
    let gm = new GoalManager();
    gm.setGoals([keepItemGoal]);
    gm.worldGenerationWillBegin();
    gm.submitWorldGenerationEvent('world:thang-collected-item', {actor: {id: 'Grabby'}, item: {id: 'Sandwich'}}, 10);
    gm.worldGenerationEnded();
    let goalStates = gm.getGoalStates();
    expect(goalStates.id.status).toBe('failure');
    expect(goalStates.id.collected.Grabby).toBe(true);
    expect(goalStates.id.keyFrame).toBe(10);

    gm = new GoalManager();
    gm.setGoals([keepItemGoal]);
    gm.worldGenerationWillBegin();
    gm.worldGenerationEnded();
    goalStates = gm.getGoalStates();
    expect(goalStates.id.status).toBe('success');
    expect(goalStates.id.collected.Grabby).toBe(false);
    return expect(goalStates.id.keyFrame).toBe('end');
});
});
