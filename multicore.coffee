cluster = require 'cluster'
numCPUs = require('os').cpus().length
numCPUs = parseInt(process.env.COCO_CORES) if process.env.COCO_CORES

deaths = [
  'Killed by a soldier ant.'
  'Ascended.'
  'Killed by an invisible gnome lord.'
  'Died of starvation.'
  'Petrified by a cockatrice corpse.'
  'Poisoned by a rotted kobold corpse.'
  'Fell into a pit.'
  'Killed by brainlessness.'
  'Slipped while mounting a saddled pony called Rainbow Dash.'
  'Killed by a scroll of genocide.'
  'Choked on a tin of spinach.'
  'Killed by the wrath of Anhur.'
  'Killed by a jackal, while fainted from lack of food.'
  'Drowned in a pool of water by an electric eel.'
  'Killed by falling downstairs.'
  'Killed by an ape, while helpless.'
  'Burned by a tower of flame.'
  'Killed by Ms. Sipaliwini, the shopkeeper.'
  'Fell onto a sink.'
  'Killed by a killer bee, while praying.'
  'Crushed to death by a collapsing drawbridge.'
  'Crunched in the head by an iron ball.'
  'Killed by exhaustion.'
  'Caught itself in its own magical blast.'
  'Shot itself with a death ray.'
  'Killed by genocidal confusion.'
  'Killed by touching Excalibur.'
  'Killed by a hallucinogen-distorted dwarf.'
  'Dissolved in molten lava.'
  'Turned to slime by a green slime.'
  'Killed by sipping boiling water.'
  'A trickery.'
  'Escaped (in celestial disgrace)'
  'Killed by kicking a sink.'
  'Killed by a kitten called Steve, while sleeping.'
  'Went to heaven prematurely.'
  'Teleported out of the dungeon and fell to its death.'
  'Panic.'
  'Killed by a minotaur, while dressing up.'
  'Petrified by trying to help a cockatrice out of a pit.'
  'Killed by a luckstone.'
  'Killed by a panther, while taking off clothes.'
  'Killed by a watch captain called The Nymphmaster.'
  'Killed by a black pudding, while jumping around.'
  'Killed by a hallucinogen-distorted white unicorn, while praying.'
  'Choked on a slice of birthday cake.'
  'Killed by a long worm, while reading a book.'
  'Killed by a giant beetle, while vomiting.'
  'Killed by an invisible master mind flayer, while unconscious from rotten food.'
  'Burned by burning.'
  'Killed by an air elemental, while hiding from thunderstorm (with the Amulet).'
  'Killed by wedging into a narrow crevice.'
  'Killed by a carnivorous bag.'
  'Killed by axing a hard object.'
  'Killed by an iron ball collision.'
  'Killed by an alchemic blast.'
  'Killed by dangerous winds.'
  'Killed by psychic blast.'
  'Committed suicide.'
  'Squished under a boulder.'
  'Killed by colliding with the ceiling.'
  'Killed by sitting on an iron spike.'
  "Quit while already on Charon's boat."
  'Fell into a chasm.'
  'Turned to slime by a cockatrice egg.'
]


if process.env.COCO_DEBUG_PORT?
  require('./debugger').init()

if cluster.isMaster
  for i in [0...numCPUs]
    cluster.fork()
  cluster.on 'exit', (worker, code, signal) ->
    message = "Worker #{worker.id} died!"
    console.log message
    try
      slack = require './server/slack'
      slack.sendSlackMessage(message, ['eng'], {papertrail: true})
    catch error
      console.log "Couldn't send Slack message on server death:", error
    cluster.fork()

else
  require('coffee-script')
  require('coffee-script/register')
  server = require('./server')
  {app, httpServer} = server.startServer()
  cluster.worker.app = app
  cluster.worker.httpServer = httpServer

