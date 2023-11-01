LevelSession = require 'app/models/LevelSession'

describe 'LevelSession', ->
  describe '@getTopScores({level, session})', ->
    it 'takes a JSON session and returns its scores, normalized', ->
      session = {
        state: {
          topScores: [
            { type: 'time', score: -1 },
            { type: 'gold', score: 50 }
          ]
        }
      }
      topScores = LevelSession.getTopScores({session})
      expect(topScores).toEqual([
        { type: 'time', score: 1 },
        { type: 'gold', score: 50 }
      ])

    it 'optionally takes a level object and extends the scores with thresholds reached', ->
      session = {
        state: {
          topScores: [
            { type: 'time', score: -20 },
            { type: 'gold', score: 60 }
            { type: 'damage-dealt', score: 30 }
          ]
        }
      }
      level = {
        scoreTypes: [
          { type: 'time', thresholds: {bronze: 50, silver: 30, gold: 10} },
          { type: 'gold', thresholds: {bronze: 50, silver: 30, gold: 10} },
          'damage-dealt'
        ]
      }
      topScores = LevelSession.getTopScores({session, level})
      expect(topScores).toEqual([
        { type: 'time', score: 20, thresholdAchieved: 'silver' },
        { type: 'gold', score: 60, thresholdAchieved: 'gold' }
        { type: 'damage-dealt', score: 30 }
      ])
