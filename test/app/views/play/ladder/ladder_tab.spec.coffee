LadderTabView = require 'views/play/ladder/ladder_tab'
Level = require 'models/Level'
fixtures = require 'test/app/fixtures/levels'

describe 'LeaderboardData', ->
  it 'triggers "sync" when its request is finished', ->
    level = new Level(fixtures.LadderLevel)
    leaderboard = new LadderTabView.LeaderboardData(level, 'humans', null, 4)
    leaderboard.fetch()
    
    # no session passed in, so only one request
    expect(jasmine.Ajax.requests.count()).toBe(1)
    
    request = jasmine.Ajax.requests.mostRecent()
    triggered = false
    leaderboard.once 'sync', -> triggered = true
    request.response({status: 200, responseText: '{}'})
    expect(triggered).toBe(true)