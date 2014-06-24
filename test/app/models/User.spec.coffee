User = require 'models/User'

describe 'UserModel', ->
  it 'experience functions are correct', ->
    expect(User.expForLevel(User.levelFromExp 0)).toBe 0
    expect(User.expForLevel(User.levelFromExp 50)).toBe 50
    expect(User.expForLevel 1).toBe 0
    expect(User.expForLevel 2).toBeGreaterThan User.expForLevel 1

  it 'level is calculated correctly', ->
    me.set 'points', 0
    expect(me.level()).toBe 1

    me.set 'points', 50
    expect(me.level()).toBe User.levelFromExp 50

