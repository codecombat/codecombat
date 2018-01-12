_ = require 'lodash'

module.exports = simpleCache = 
  # We use mongoose-cache to aggressively cache requests for ladder score distributions for the histograms.
  # We'd like access to those results outside of that same query for ladder simulations and leaderboard rank indexing.
  # This simple cache is another place to put the latest score distributions for those purposes.
  ladderScores: {}

  getLadderScores: (levelSlug, team) ->
    simpleCache.ladderScores[levelSlug]?[team]

  setLadderScores: (levelSlug, team, scores) ->
    simpleCache.ladderScores[levelSlug] ?= {}
    simpleCache.ladderScores[levelSlug][team] = scores

  getLadderRank: (levelSlug, team, totalScore) ->
    scores = simpleCache.getLadderScores levelSlug, team
    return null unless scores
    sessionIndex = _.sortedIndex scores, totalScore, (index) -> -index  # Descending order
    sessionIndex + 1
