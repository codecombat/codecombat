LadderTabView = require 'views/ladder/LadderTabView'
Level = require 'models/Level'
factories = require 'test/app/factories'

describe 'LeaderboardData', ->
  it 'triggers "sync" when its request is finished', ->
    level = factories.makeLevel()
    leaderboard = new LadderTabView.LeaderboardData(level, 'humans', null, 4)
    leaderboard.fetch()

    # no session passed in, so only one request
    expect(jasmine.Ajax.requests.count()).toBe(1)

    request = jasmine.Ajax.requests.mostRecent()
    triggered = false
    leaderboard.once 'sync', -> triggered = true
    request.respondWith({status: 200, responseText: '{}'})
    expect(triggered).toBe(true)
