/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
const LevelSession = require('app/models/LevelSession');

describe('LevelSession', () => describe('@getTopScores({level, session})', function() {
  it('takes a JSON session and returns its scores, normalized', function() {
    const session = {
      state: {
        topScores: [
          { type: 'time', score: -1 },
          { type: 'gold', score: 50 }
        ]
      }
    };
    const topScores = LevelSession.getTopScores({session});
    return expect(topScores).toEqual([
      { type: 'time', score: 1 },
      { type: 'gold', score: 50 }
    ]);
  });

  return it('optionally takes a level object and extends the scores with thresholds reached', function() {
    const session = {
      state: {
        topScores: [
          { type: 'time', score: -20 },
          { type: 'gold', score: 60 },
          { type: 'damage-dealt', score: 30 }
        ]
      }
    };
    const level = {
      scoreTypes: [
        { type: 'time', thresholds: {bronze: 50, silver: 30, gold: 10} },
        { type: 'gold', thresholds: {bronze: 50, silver: 30, gold: 10} },
        'damage-dealt'
      ]
    };
    const topScores = LevelSession.getTopScores({session, level});
    return expect(topScores).toEqual([
      { type: 'time', score: 20, thresholdAchieved: 'silver' },
      { type: 'gold', score: 60, thresholdAchieved: 'gold' },
      { type: 'damage-dealt', score: 30 }
    ]);
  });
}));
