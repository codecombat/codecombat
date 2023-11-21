/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
const LadderTabView = require('views/ladder/LadderTabView');
const Level = require('models/Level');
const factories = require('test/app/factories');

describe('LeaderboardData', () => it('triggers "sync" when its request is finished', function() {
  const level = factories.makeLevel();
  const leaderboard = new LadderTabView.LeaderboardData(level, 'humans', null, 4);
  leaderboard.fetch();

  // no session passed in, so only one request
  expect(jasmine.Ajax.requests.count()).toBe(1);

  const request = jasmine.Ajax.requests.mostRecent();
  let triggered = false;
  leaderboard.once('sync', () => triggered = true);
  request.respondWith({status: 200, responseText: '{}'});
  return expect(triggered).toBe(true);
}));
