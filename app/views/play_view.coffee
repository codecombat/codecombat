View = require 'views/kinds/RootView'
template = require 'templates/play'
LevelSession = require 'models/LevelSession'
CocoCollection = require 'collections/CocoCollection'

class LevelSessionsCollection extends CocoCollection
  url: ''
  model: LevelSession

  constructor: (model) ->
    super()
    @url = "/db/user/#{me.id}/level.sessions?project=state.complete,levelID"

module.exports = class PlayView extends View
  id: "play-view"
  template: template

  constructor: (options) ->
    super options
    @levelStatusMap = {}
    @sessions = new LevelSessionsCollection()
    @sessions.fetch()
    @listenToOnce @sessions, 'sync', @onSessionsLoaded

  onSessionsLoaded: (e) ->
    for session in @sessions.models
      @levelStatusMap[session.get('levelID')] = if session.get('state')?.complete then 'complete' else 'started'
    @render()

  getRenderData: (context={}) ->
    context = super(context)
    context.home = true
    context.notFound = @getQueryVariable 'not_found'
    tutorials = [
      {
        name: 'Rescue Mission'
        difficulty: 1
        id: 'rescue-mission'
        image: '/file/db/level/52740644904ac0411700067c/rescue_mission_icon.png'
        description: "Tharin has been captured!"
      }
      {
        name: 'Grab the Mushroom'
        difficulty: 1
        id: 'grab-the-mushroom'
        image: '/file/db/level/529662dfe0df8f0000000007/grab_the_mushroom_icon.png'
        description: "Grab a powerup and smash a big ogre."
      }
      {
        name: 'Drink Me'
        difficulty: 1
        id: 'drink-me'
        image: '/file/db/level/525dc5589a0765e496000006/drink_me_icon.png'
        description: "Drink up and slay two munchkins."
      }
      {
        name: 'Taunt the Guards'
        difficulty: 1
        id: 'taunt-the-guards'
        image: '/file/db/level/5276c9bdcf83207a2801ff8f/taunt_icon.png'
        description: "Tharin, if clever, can escape with Phoebe."
      }
      {
        name: "It's a Trap"
        difficulty: 1
        id: 'its-a-trap'
        image: '/file/db/level/528aea2d7f37fc4e0700016b/its_a_trap_icon.png'
        description: "Organize a dungeon ambush with archers."
      }
      {
        name: 'Break the Prison'
        difficulty: 1
        id: 'break-the-prison'
        image: '/file/db/level/5275272c69abdcb12401216e/break_the_prison_icon.png'
        description: "More comrades are imprisoned!"
      }
      {
        name: 'Taunt'
        difficulty: 1
        id: 'taunt'
        image: '/file/db/level/525f150306e1ab0962000018/taunt_icon.png'
        description: "Taunt the ogre to claim victory."
      }
      {
        name: 'Cowardly Taunt'
        difficulty: 1
        id: 'cowardly-taunt'
        image: '/file/db/level/525abfd9b12777d78e000009/cowardly_taunt_icon.png'
        description: "Lure infuriated ogres to their doom."
      }
      {
        name: 'Commanding Followers'
        difficulty: 1
        id: 'commanding-followers'
        image: '/file/db/level/525ef8ef06e1ab0962000003/commanding_followers_icon.png'
        description: "Lead allied soldiers into battle."
      }
      {
        name: 'Mobile Artillery'
        difficulty: 1
        id: 'mobile-artillery'
        image: '/file/db/level/525085419851b83f4b000001/mobile_artillery_icon.png'
        description: "Blow ogres up!"
      }
    ]

    experienced = [
      {
        name: 'Hunter Triplets'
        difficulty: 2
        id: 'hunter-triplets'
        image: '/file/db/level/526711d9add4f8965f000002/hunter_triplets_icon.png'
        description: "Three soldiers go ogre hunting."
      }
      {
        name: 'Emphasis on Aim'
        difficulty: 2
        id: 'emphasis-on-aim'
        image: '/file/db/level/525f384d96cd77000000000f/munchkin_masher_icon.png'
        description: "Chose your targets carefully."
      }
      {
        name: 'Zone of Danger'
        difficulty: 3
        id: 'zone-of-danger'
        image: '/file/db/level/526ae95c1e5cd30000000008/zone_of_danger_icon.png'
        description: "Target the ogres swarming into arrow range."
      }
      {
        name: 'Molotov Medic'
        difficulty: 2
        id: 'molotov-medic'
        image: '/file/db/level/52602ecb026e8481e7000001/generic_1.png'
        description: "Tharin must play support in this dungeon battle."
      }
      {
        name: 'Gridmancer'
        difficulty: 5
        id: 'gridmancer'
        image: '/file/db/level/52ae2460ef42c52f13000008/gridmancer_icon.png'
        description: "Super algorithm challenge level!"
      }
    ]

    arenas = [
      {
        name: 'Greed'
        difficulty: 4
        id: 'greed'
        image: '/file/db/level/526fd3043c637ece50001bb2/the_herd_icon.png'
        description: "Liked Dungeon Arena and Gold Rush? Put them together in this economic arena!"
        levelPath: 'ladder'
      }
      {
        name: 'Dungeon Arena'
        difficulty: 3
        id: 'dungeon-arena'
        image: '/file/db/level/526ae95c1e5cd30000000008/zone_of_danger_icon.png'
        description: "Play head-to-head against fellow Wizards in a dungeon melee!"
        levelPath: 'ladder'
      }
      {
        name: 'Gold Rush'
        difficulty: 3
        id: 'gold-rush'
        image: '/file/db/level/52602ecb026e8481e7000001/generic_1.png'
        description: "Prove you are better at collecting gold than your opponent!"
        levelPath: 'ladder'
      }
      {
        name: 'Brawlwood'
        difficulty: 4
        id: 'brawlwood'
        image: '/file/db/level/525ef8ef06e1ab0962000003/commanding_followers_icon.png'
        description: "Combat the armies of other Wizards in a strategic forest arena! (Fast computer required.)"
        levelPath: 'ladder'
      }
    ]

    playerCreated = [
      {
        name: 'Extra Extrapolation'
        difficulty: 2
        id: 'extra-extrapolation'
        image: '/file/db/level/526bda3fe79aefde2a003e36/mobile_artillery_icon.png'
        description: "Predict your target's position for deadly aim. - by Sootn"
      }
      {
        name: 'The Right Route'
        difficulty: 1
        id: 'the-right-route'
        image: '/file/db/level/526fd3043c637ece50001bb2/the_herd_icon.png'
        description: "Strike at the weak point in an array of enemies. - by Aftermath"
      }
      {
        name: 'Sword Loop'
        difficulty: 2
        id: 'sword-loop'
        image: '/file/db/level/525dc5589a0765e496000006/drink_me_icon.png'
        description: 'Kill the ogres and save the peasants with for-loops. - by Prabh Simran Singh Baweja'
      }
      {
        name: 'Coin Mania'
        difficulty: 2
        id: 'coin-mania'
        image: '/file/db/level/529662dfe0df8f0000000007/grab_the_mushroom_icon.png'
        description: 'Learn while-loops to grab coins and potions. - by Prabh Simran Singh Baweja'
      }
      {
        name: 'Bubble Sort Bootcamp Battle'
        difficulty: 3
        id: 'bubble-sort-bootcamp-battle'
        image: '/file/db/level/525ef8ef06e1ab0962000003/commanding_followers_icon.png'
        description: "Write a bubble sort to organize your soldiers. - by Alexandru Caciulescu"
      }
      {
        name: 'Ogres of Hanoi'
        difficulty: 3
        id: 'ogres-of-hanoi'
        image: '/file/db/level/526fd3043c637ece50001bb2/the_herd_icon.png'
        description: "Transfer a stack of ogres while preserving their honor. - by Alexandru Caciulescu"
      }
      {
        name: 'Danger! Minefield'
        difficulty: 3
        id: 'danger-minefield'
        image: '/file/db/level/526bda3fe79aefde2a003e36/mobile_artillery_icon.png'
        description: "Learn how to find prime numbers while defusing mines! - by Alexandru Caciulescu"
      }
      {
        name: 'Find the Spy'
        difficulty: 2
        id: 'find-the-spy'
        image: '/file/db/level/526ae95c1e5cd30000000008/zone_of_danger_icon.png'
        description: "Identify the spies hidden among your soldiers - by Nathan Gossett"
      }
      {
        name: 'Harvest Time'
        difficulty: 2
        id: 'harvest-time'
        image: '/file/db/level/529662dfe0df8f0000000007/grab_the_mushroom_icon.png'
        description: "Collect a hundred mushrooms in just five lines of code - by Nathan Gossett"
      }
    ]

    context.campaigns = [
      {id: "beginner", name: "Beginner Campaign", description: "... in which you learn the wizardry of programming.", levels: tutorials}
      {id: "multiplayer", name: "Multiplayer Arenas", description: "... in which you code head-to-head against other players.", levels: arenas}
      {id: "dev", name: "Random Harder Levels", description: "... in which you learn the interface while doing something a little harder.", levels: experienced}
      {id: "player_created", name: "Player-Created", description: "... in which you battle against the creativity of your fellow <a href=\"/contribute#artisan\">Artisan Wizards</a>.", levels: playerCreated}
    ]
    context.levelStatusMap = @levelStatusMap
    context

  afterRender: ->
    super()
    @$el.find('.modal').on 'shown.bs.modal', ->
      $('input:visible:first', @).focus()
