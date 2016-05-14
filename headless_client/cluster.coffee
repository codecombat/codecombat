child_process = require 'child_process'
chalk = require 'chalk'
_ = require 'lodash'
Promise = require 'bluebird'
path = require 'path'

cores = 4

list = [
  "dungeons-of-kithgard", "gems-in-the-deep", "shadow-guard", "kounter-kithwise", "crawlways-of-kithgard",
  "enemy-mine", "illusory-interruption", "forgetful-gemsmith", "signs-and-portents", "favorable-odds",
  "true-names", "the-prisoner", "banefire", "the-raised-sword", "kithgard-librarian", "fire-dancing",
  "loop-da-loop", "haunted-kithmaze", "riddling-kithmaze", "descending-further", "the-second-kithmaze",
  "dread-door", "cupboards-of-kithgard", "hack-and-dash", "known-enemy", "master-of-names",
  "lowly-kithmen", "closing-the-distance", "tactical-strike", "the-skeleton", "a-mayhem-of-munchkins",
  "the-final-kithmaze", "the-gauntlet", "radiant-aura", "kithgard-gates", "destroying-angel", "deadly-dungeon-rescue",
  "kithgard-brawl", "cavern-survival", "breakout", "attack-wisely", "kithgard-mastery", "kithgard-apprentice", 
  "robot-ragnarok", "defense-of-plainswood", "peasant-protection", "forest-fire-dancing"
]

c1 = ["dungeons-of-kithgard", "gems-in-the-deep", "shadow-guard", "enemy-mine", "true-names", "fire-dancing", "loop-da-loop", "haunted-kithmaze", "the-second-kithmaze", "dread-door", "cupboards-of-kithgard", "breakout", "known-enemy", "master-of-names", "a-mayhem-of-munchkins", "the-gauntlet", "the-final-kithmaze", "kithgard-gates", "wakka-maul"]
c2 = ["defense-of-plainswood", "course-winding-trail", "patrol-buster", "endangered-burl", "thumb-biter", "gems-or-death", "village-guard", "thornbush-farm", "back-to-back", "ogre-encampment", "woodland-cleaver", "shield-rush", "range-finder", "peasant-protection", "munchkin-swarm", "forest-fire-dancing", "stillness-in-motion", "the-agrippa-defense", "backwoods-bombardier", "coinucopia", "copper-meadows", "drop-the-flag", "mind-the-trap", "signal-corpse", "rich-forager", "cross-bones"]

list = [].concat(c1, c2)
list = c1

list = _.shuffle(list);

lpad = (s, l, color = 'white') ->
  return chalk[color](s.substring(0, l)) if s.length >= l
  return chalk[color](s + new Array(l - s.length).join(' '))


chunks = _.groupBy list, (v,i) -> i%cores
_.forEach chunks, (list, cid) ->
  console.log(list)
  cp = child_process.fork path.join(__dirname, './verifier.js'), list, silent: true
  cp.on 'message', (m) ->
    return if m.state is 'running'
    okay = true
    goals = _.map m.observed.goals, (v,k) ->
      return lpad('No Goals Set', 15, 'yellow') unless m.solution.goals
      lpad(k, 15, if v == m.solution.goals[k] then 'green' else 'red')


    extra = []
    if m.observed.frameCount == m.solution.frameCount
      extra.push lpad('F:' + m.observed.frameCount, 15, 'green')
    else
      extra.push lpad('F:' + m.observed.frameCount  + ' vs ' + m.solution.frameCount , 15, 'red')
      okay = false

    if m.observed.lastHash == m.solution.lastHash
      extra.push lpad('Hash', 5, 'green')
    else
      extra.push lpad('Hash' , 5, 'red')
      okay = false

    col = if okay then 'green' else 'red'
    if m.state is 'error' or m.error 
      console.log lpad(m.level, 30, 'red') + lpad(m.language, 15, 'cyan') + chalk.red(m.error)
    else
      console.log lpad(m.level, 30, col) + lpad(m.language, 15, 'cyan') + ' ' + extra.join(' ') + ' ' + goals.join(' ') 
