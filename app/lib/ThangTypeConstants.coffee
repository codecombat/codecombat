ThangTypeConstants =
  heroes:
    captain: '529ec584c423d4e83b000014'
    knight: '529ffbf1cf1818f2be000001'
    samurai: '53e12be0d042f23505c3023b'
    raider: '55527eb0b8abf4ba1fe9a107'
    goliath: '55e1a6e876cb0948c96af9f8'
    guardian: '566a058620de41290036a745'
    ninja: '52fc0ed77e01835453bd8f6c'
    'forest-archer': '5466d4f2417c8b48a9811e87'
    trapper: '5466d449417c8b48a9811e83'
    pixie: '579a619382f2401f001cd5b4'
    assassin: '566a2202e132c81f00f38c81'
    librarian: '52fbf74b7e01835453bd8d8e'
    'potion-master': '52e9adf7427172ae56002172'
    sorcerer: '52fd1524c7e6cf99160e7bc9'
    necromancer: '55652fb3b9effa46a1f775fd'
    'master-wizard': '5f75db6b7e9d990022cf49f4'
    duelist: '57588f09046caf2e0012ed41'
    champion: '575848b522179b2800efbfbf'
    'code-ninja': '58192d484954d56144a7062f'
    stalwart: '5a576ec52db68a00269b7a08'
    'armando-hoyos': '6037ed81ad0ac000f5e9f0b5'
    'ned-fulmer': '6136fe7e9f1147002c1316b4'
    'wolf-pup-hero': '663cedaa5a5f9b8a296f9383'
    'cougar-hero': '663ced3e5a5f9b8a296f92c8'
    'polar-bear-cub-hero': '663ced2d5a5f9b8a296f92b9'
    'frog-hero': '663ced675a5f9b8a296f92ff'
    'turtle-hero': '663cedc65a5f9b8a296f93a5'
    'blue-fox-hero': '663ced805a5f9b8a296f931d'
    'panther-cub-hero': '663ced735a5f9b8a296f930e'
    'brown-rat-hero': '663ced225a5f9b8a296f92aa'
    'duck-hero': '663ced9f5a5f9b8a296f9374'
    'tiger-cub-hero': '663ced955a5f9b8a296f9365'
    'pugicorn-hero': '663ced085a5f9b8a296f928b'
    'raven-hero': '663ced8a5a5f9b8a296f932c'
    'baby-griffin-hero': '663ced185a5f9b8a296f929b'
    'yetibab-hero': '663ced485a5f9b8a296f92d4'
    'mimic-hero': '663cedcf5a5f9b8a296f93b2'
    'phoenix-hero': '663ced555a5f9b8a296f92e4'
    'dragonling-hero': '663ced5e5a5f9b8a296f92f3'
    'kindling-elemental-hero': '663cedbb5a5f9b8a296f9396'
  ozariaHeroes:
    'hero-a': '5d1630bf14281c002af1ee51'  # Male, thin
    'hero-b': '5d164dfedf16b90034a2ce89'  # Female, thin
    'hero-c': '60f8f30a5b55bb0029710795'  # Female, curvy
    'hero-d': '60ff9b255b55bb002971b998'  # Male, stocky
    'hero-e': '60ff9b6b28067a00236ea9f0'  # Female, androgynous
    'hero-f': '60ff9b7a5b55bb002971b9e5'  # Male, wheelchair
  ozariaCinematicHeroes:
    'hero-a': '5d03e18887ed53004682e340'  # Male, thin
    'hero-b': '5d03e60dab809900234a0037'  # Female, thin
    'hero-c': '60fe44d128067a00236e6cc5'  # Female, curvy
    'hero-d': '60ff9b9d28067a00236eaa21'  # Male, stocky
    'hero-e': '60ff9bc75b55bb002971ba41'  # Female, androgynous
    'hero-f': '60ff9bd728067a00236eaa57'  # Male, wheelchair
  heroClasses:
    Warrior: ['champion', 'duelist', 'captain', 'knight', 'samurai', 'raider', 'goliath', 'guardian', 'code-ninja', 'stalwart', 'armando-hoyos', 'ned-fulmer', 'wolf-pup-hero', 'cougar-hero', 'polar-bear-cub-hero', 'frog-hero', 'turtle-hero', 'blue-fox-hero', 'panther-cub-hero', 'brown-rat-hero', 'duck-hero', 'tiger-cub-hero', 'pugicorn-hero', 'raven-hero', 'baby-griffin-hero', 'yetibab-hero', 'mimic-hero', 'phoenix-hero', 'dragonling-hero', 'kindling-elemental-hero']
    Ranger: ['ninja', 'forest-archer', 'trapper', 'pixie', 'assassin']
    Wizard: ['librarian', 'potion-master', 'sorcerer', 'necromancer', 'master-wizard']
  items:
    'simple-boots': '53e237bf53457600003e3f05'
  # Junior pet heroes shown in the pet hero choice modal, in display order.
  # This is the roster source of truth: membership, ordering, and access tier
  # (free / subscriber / premium) all come from here, replacing the old
  # gems-as-sort-key hack. ObjectIDs live in the heroes map above.
  juniorHeroesConfig: [
    { slug: 'wolf-pup-hero', access: 'free' }
    { slug: 'cougar-hero', access: 'free' }
    { slug: 'polar-bear-cub-hero', access: 'free' }
    { slug: 'frog-hero', access: 'free' }
    { slug: 'turtle-hero', access: 'free' }
    { slug: 'blue-fox-hero', access: 'free' }
    { slug: 'panther-cub-hero', access: 'free' }
    { slug: 'brown-rat-hero', access: 'free' }
    { slug: 'duck-hero', access: 'free' }
    { slug: 'tiger-cub-hero', access: 'free' }
    { slug: 'pugicorn-hero', access: 'subscriber' }
    { slug: 'raven-hero', access: 'subscriber' }
    { slug: 'baby-griffin-hero', access: 'subscriber' }
    { slug: 'yetibab-hero', access: 'premium' }
    { slug: 'mimic-hero', access: 'premium' }
    { slug: 'phoenix-hero', access: 'premium' }
    { slug: 'dragonling-hero', access: 'premium' }
    { slug: 'kindling-elemental-hero', access: 'premium' }
  ]
  # junior-pet-access experiment (GD-875), beta arm only. Control keeps using
  # juniorHeroesConfig above. Same shape as that roster, plus per-pet:
  #   access: free (anyone) | signup (selectable, Save routes to signup while
  #           anonymous) | premium (subscribers) | module (unlocks when
  #           unlockLevel is completed)
  #   unlockLevel: level.original whose completion unlocks the pet (module
  #                tier only). These are the odyssey modules' levelToUnlock
  #                gates - each lives in the PREVIOUS module and unlocks the
  #                next one. Completion read from level sessions.
  #   hint: player-facing locked-pet copy shown in the modal
  #   position: modal grid placement, row/column
  # Assignment is provisional - PM adjusts by editing this array.
  # Layout: row 0 = free pets then the 11 module-unlockable pets;
  #         row 1 = signup pets then premium pets.
  juniorPetAccessConfig: [
    { slug: 'wolf-pup-hero', access: 'free', position: { row: 0, column: 0 } }
    { slug: 'cougar-hero', access: 'free', position: { row: 0, column: 1 } }
    { slug: 'turtle-hero', access: 'module', unlockLevel: '66072b276bfa8984388f2e65', hint: 'Complete Sun Shores to unlock', position: { row: 0, column: 2 } } # gate level in Sun Shores; completing it unlocks Amber Keys
    { slug: 'brown-rat-hero', access: 'module', unlockLevel: '65ce52333ca6ed67e1be5447', hint: 'Complete Amber Keys to unlock', position: { row: 0, column: 3 } } # gate level in Amber Keys; completing it unlocks Crimson Sands
    { slug: 'raven-hero', access: 'module', unlockLevel: '65ce63c53ca6ed67e1be6f75', hint: 'Complete Crimson Sands to unlock', position: { row: 0, column: 4 } } # gate level in Crimson Sands; completing it unlocks Blaze Coast
    { slug: 'dragonling-hero', access: 'module', unlockLevel: '66072bfc6bfa8984388f3377', hint: 'Complete Blaze Coast to unlock', position: { row: 0, column: 5 } } # gate level in Blaze Coast; completing it unlocks Wild Growth
    { slug: 'panther-cub-hero', access: 'module', unlockLevel: '66072c2b6bfa8984388f35ec', hint: 'Complete Wild Growth to unlock', position: { row: 0, column: 6 } } # gate level in Wild Growth; completing it unlocks Redrock Reach
    { slug: 'kindling-elemental-hero', access: 'module', unlockLevel: '660f19ffddeab4a188453963', hint: 'Complete Redrock Reach to unlock', position: { row: 0, column: 7 } } # gate level in Redrock Reach; completing it unlocks Coldrock Pass
    { slug: 'yetibab-hero', access: 'module', unlockLevel: '67180617c15a4d2ab0a38aef', hint: 'Complete Coldrock Pass to unlock', position: { row: 0, column: 8 } } # gate level in Coldrock Pass; completing it unlocks Cool Waters
    { slug: 'mimic-hero', access: 'module', unlockLevel: '671a6929e431af0c7e6f1c9d', hint: 'Complete Cool Waters to unlock', position: { row: 0, column: 9 } } # gate level in Cool Waters; completing it unlocks Snow Isles
    { slug: 'polar-bear-cub-hero', access: 'module', unlockLevel: '671a698ee431af0c7e6f210f', hint: 'Complete Snow Isles to unlock', position: { row: 0, column: 10 } } # gate level in Snow Isles; completing it unlocks Tundra Break
    { slug: 'blue-fox-hero', access: 'module', unlockLevel: '67215459e389d6253f508cdc', hint: 'Complete Tundra Break to unlock', position: { row: 0, column: 11 } } # gate level in Tundra Break; completing it unlocks Greenrise Atoll
    { slug: 'tiger-cub-hero', access: 'module', unlockLevel: '6723fed6e389d6253f518552', hint: 'Complete Greenrise Atoll to unlock', position: { row: 0, column: 12 } } # gate level in Greenrise Atoll; completing it unlocks Emerald Crown
    { slug: 'duck-hero', access: 'signup', position: { row: 1, column: 0 } }
    { slug: 'frog-hero', access: 'signup', position: { row: 1, column: 1 } }
    { slug: 'pugicorn-hero', access: 'premium', position: { row: 1, column: 2 } }
    { slug: 'phoenix-hero', access: 'premium', position: { row: 1, column: 3 } }
    { slug: 'baby-griffin-hero', access: 'premium', position: { row: 1, column: 4 } }
  ]
  juniorHeroReplacements:
    captain: 'wolf-pup-hero'
    knight: 'cougar-hero'
    samurai: 'polar-bear-cub-hero'
    raider: 'frog-hero'
    goliath: 'turtle-hero'
    guardian: 'blue-fox-hero'
    duelist: 'panther-cub-hero'
    champion: 'tiger-cub-hero'
    stalwart: 'duck-hero'
    'armando-hoyos': 'brown-rat-hero'
    'ned-fulmer': 'brown-rat-hero'

module.exports = ThangTypeConstants
