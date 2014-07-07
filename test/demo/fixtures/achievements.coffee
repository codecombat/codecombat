now = new Date()
oneDayBefore = (new Date now).setDate(now.getDate() - 1)

module.exports.DungeonArenaStarted = DungeonArenaStarted =
  _id: '53ba76249259823746b6b481'
  name: 'Dungeon Arena Started'
  description: 'Started playing Dungeon Arena. '
  icon: '/images/achievements/swords-01.png'
  worth: 3
  collection: 'level.session'
  query: "{\"level.original\":\"dungeon-arena\"}"
  userField: 'creator'

module.exports.Simulated = Simulated =
  _id: '53ba76249259823746b6b482'
  name: 'Simulated'
  description: 'Simulated Games.'
  icon: '/images/achievements/cup-02.png'
  worth: 1
  collection: 'users'
  query: "{\"simulatedBy\":{\"$gt\":0}}"
  userField: '_id'
  proportionalTo: 'simulatedBy'

module.exports.DungeonArenaStartedEarned = DungeonArenaStartedEarned =
  user: ''
  achievement: DungeonArenaStarted._id
  collection: DungeonArenaStarted.collection
  achievementName: DungeonArenaStarted.name
  created: now
  changed: now
  achievedAmount: 1
  earnedPoints: 3
  previouslyAchievedAmount: 0
  notified: true

module.exports.SimulatedEarned = SimulatedEarned =
  user: ''
  achievement: Simulated._id
  collection: Simulated.collection
  achievementName: Simulated.name
  created: now
  changed: now
  achievedAmount: 6
  earnedPoints: 6
  previouslyAchievedAmount: 5
  notified: true


module.exports.achievements = [DungeonArenaStarted, Simulated]
module.exports.earnedAchievements = [DungeonArenaStartedEarned, SimulatedEarned]
