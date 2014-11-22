module.exports = LevelOptions =
  'dungeons-of-kithgard':
    disableSpaces: true
    hidesSubmitUntilRun: true
    hidesPlayButton: true
    hidesRunShortcut: true
    hidesHUD: true
    hidesSay: true
    hidesCodeToolbar: true
    hidesRealTimePlayback: true
    requiredGear: {feet: 'simple-boots'}
    restrictedGear: {feet: 'leather-boots'}
    requiredCode: ['moveRight']
  'gems-in-the-deep':
    disableSpaces: true
    hidesSubmitUntilRun: true
    hidesPlayButton: true
    hidesRunShortcut: true
    hidesHUD: true
    hidesSay: true
    hidesCodeToolbar: true
    hidesRealTimePlayback: true
    requiredGear: {feet: 'simple-boots'}
    restrictedGear: {feet: 'leather-boots'}
  'shadow-guard':
    disableSpaces: true
    hidesSubmitUntilRun: true
    hidesPlayButton: true
    hidesRunShortcut: true
    hidesHUD: true
    hidesSay: true
    hidesCodeToolbar: true
    hidesRealTimePlayback: true
    requiredGear: {feet: 'simple-boots'}
    restrictedGear: {feet: 'leather-boots', 'right-hand': 'simple-sword'}
  'kounter-kithwise':
    disableSpaces: true
    hidesPlayButton: true
    hidesRunShortcut: true
    hidesHUD: true
    hidesSay: true
    hidesCodeToolbar: true
    hidesRealTimePlayback: true
    requiredGear: {feet: 'simple-boots'}
    restrictedGear: {feet: 'leather-boots', 'right-hand': 'simple-sword', 'programming-book': 'programmaticon-i'}
  'crawlways-of-kithgard':
    hidesPlayButton: true
    hidesRunShortcut: true
    hidesHUD: true
    hidesSay: true
    hidesCodeToolbar: true
    hidesRealTimePlayback: true
    requiredGear: {feet: 'simple-boots'}
    restrictedGear: {feet: 'leather-boots', 'right-hand': 'simple-sword', 'programming-book': 'programmaticon-i'}
  'forgetful-gemsmith':
    disableSpaces: true
    hidesPlayButton: true
    hidesRunShortcut: true
    hidesHUD: true
    hidesSay: true
    hidesCodeToolbar: true
    hidesRealTimePlayback: true
    requiredGear: {feet: 'simple-boots'}
    restrictedGear: {feet: 'leather-boots', 'programming-book': 'programmaticon-i'}
  'true-names':
    disableSpaces: true
    hidesPlayButton: true
    hidesRunShortcut: true
    hidesHUD: true
    hidesSay: true
    hidesCodeToolbar: true
    hidesRealTimePlayback: true
    requiredGear: {feet: 'simple-boots', 'right-hand': 'simple-sword', waist: 'leather-belt'}
    restrictedGear: {feet: 'leather-boots'}
    requiredCode: ['Brak']
  'favorable-odds':
    disableSpaces: true
    hidesPlayButton: true
    hidesRunShortcut: true
    hidesHUD: true
    hidesSay: true
    hidesCodeToolbar: true
    hidesRealTimePlayback: true
    requiredGear: {feet: 'simple-boots', 'right-hand': 'simple-sword'}
    restrictedGear: {feet: 'leather-boots'}
  'the-raised-sword':
    disableSpaces: true
    hidesPlayButton: true
    hidesRunShortcut: true
    hidesHUD: true
    hidesSay: true
    hidesCodeToolbar: true
    hidesRealTimePlayback: true
    requiredGear: {feet: 'simple-boots', 'right-hand': 'simple-sword', torso: 'tarnished-bronze-breastplate'}
    restrictedGear: {feet: 'leather-boots'}
  'the-first-kithmaze':
    hidesRunShortcut: true
    hidesHUD: true
    hidesSay: true
    hidesCodeToolbar: true
    hidesRealTimePlayback: true
    requiredGear: {feet: 'simple-boots', 'programming-book': 'programmaticon-i'}
    restrictedGear: {feet: 'leather-boots'}
    requiredCode: ['loop']
  'haunted-kithmaze':
    hidesRunShortcut: true
    hidesHUD: true
    hidesSay: true
    hidesCodeToolbar: true
    hidesRealTimePlayback: true
    moveRightLoopSnippet: true
    requiredGear: {feet: 'simple-boots', 'programming-book': 'programmaticon-i'}
    restrictedGear: {feet: 'leather-boots'}
    requiredCode: ['loop']
  'descending-further':
    hidesHUD: true
    hidesSay: true
    hidesCodeToolbar: true
    hidesRealTimePlayback: true
    requiredGear: {feet: 'simple-boots', 'programming-book': 'programmaticon-i'}
    restrictedGear: {feet: 'leather-boots'}
  'the-second-kithmaze':
    hidesHUD: true
    hidesSay: true
    hidesCodeToolbar: true
    hidesRealTimePlayback: true
    moveRightLoopSnippet: true
    requiredGear: {feet: 'simple-boots', 'programming-book': 'programmaticon-i'}
    restrictedGear: {feet: 'leather-boots'}
  'dread-door':
    hidesHUD: true
    hidesSay: true
    hidesCodeToolbar: true
    hidesRealTimePlayback: true
    requiredGear: {'right-hand': 'simple-sword', 'programming-book': 'programmaticon-i'}
    restrictedGear: {feet: 'leather-boots'}
  'known-enemy':
    hidesHUD: true
    hidesSay: true
    hidesCodeToolbar: true
    hidesRealTimePlayback: true
    requiredGear: {'right-hand': 'simple-sword', 'programming-book': 'programmaticon-i', torso: 'tarnished-bronze-breastplate'}
    restrictedGear: {feet: 'leather-boots'}
  'master-of-names':
    hidesHUD: true
    hidesSay: true
    hidesCodeToolbar: true
    hidesRealTimePlayback: true
    requiredGear: {feet: 'simple-boots', 'right-hand': 'simple-sword', 'programming-book': 'programmaticon-i', eyes: 'crude-glasses', torso: 'tarnished-bronze-breastplate'}
    restrictedGear: {feet: 'leather-boots'}
    requiredCode: ['findNearestEnemy']
    suspectCode: [{name: 'lone-find-nearest-enemy', pattern: /^[ ]*(self|this|@)?[:.]?findNearestEnemy()/m}]
  'lowly-kithmen':
    hidesHUD: true
    hidesSay: true
    hidesCodeToolbar: true
    hidesRealTimePlayback: true
    requiredGear: {feet: 'simple-boots', 'right-hand': 'simple-sword', 'programming-book': 'programmaticon-i', eyes: 'crude-glasses', torso: 'tarnished-bronze-breastplate'}
    restrictedGear: {feet: 'leather-boots'}
    requiredCode: ['findNearestEnemy']
    suspectCode: [{name: 'lone-find-nearest-enemy', pattern: /^[ ]*(self|this|@)?[:.]?findNearestEnemy()/m}]
  'closing-the-distance':
    hidesHUD: true
    hidesSay: true
    hidesCodeToolbar: true
    hidesRealTimePlayback: true
    requiredGear: {feet: 'simple-boots', 'right-hand': 'simple-sword', torso: 'tarnished-bronze-breastplate', eyes: 'crude-glasses'}
    restrictedGear: {feet: 'leather-boots'}
    suspectCode: [{name: 'lone-find-nearest-enemy', pattern: /^[ ]*(self|this|@)?[:.]?findNearestEnemy()/m}]
  'tactical-strike':
    hidesHUD: true
    hidesSay: true
    hidesCodeToolbar: true
    hidesRealTimePlayback: true
    requiredGear: {feet: 'simple-boots', 'right-hand': 'simple-sword', torso: 'tarnished-bronze-breastplate', eyes: 'crude-glasses'}
    restrictedGear: {feet: 'leather-boots'}
    suspectCode: [{name: 'lone-find-nearest-enemy', pattern: /^[ ]*(self|this|@)?[:.]?findNearestEnemy()/m}]
  'the-final-kithmaze':
    hidesHUD: true
    hidesSay: true
    hidesCodeToolbar: true
    hidesRealTimePlayback: true
    requiredGear: {feet: 'simple-boots', 'right-hand': 'simple-sword', torso: 'tarnished-bronze-breastplate', 'programming-book': 'programmaticon-i', eyes: 'crude-glasses'}
    suspectCode: [{name: 'lone-find-nearest-enemy', pattern: /^[ ]*(self|this|@)?[:.]?findNearestEnemy()/m}]
  'the-gauntlet':
    hidesHUD: true
    hidesSay: true
    hidesCodeToolbar: true
    hidesRealTimePlayback: true
    requiredGear: {feet: 'simple-boots', 'right-hand': 'simple-sword', torso: 'tarnished-bronze-breastplate', 'programming-book': 'programmaticon-i', eyes: 'crude-glasses'}
    restrictedGear: {feet: 'leather-boots'}
    suspectCode: [{name: 'lone-find-nearest-enemy', pattern: /^[ ]*(self|this|@)?[:.]?findNearestEnemy()/m}]
  'kithgard-gates':
    hidesSay: true
    hidesCodeToolbar: true
    hidesRealTimePlayback: true
    requiredGear: {feet: 'simple-boots', 'right-hand': 'crude-builders-hammer', torso: 'tarnished-bronze-breastplate'}
    restrictedGear: {'right-hand': 'simple-sword'}
  'defense-of-plainswood':
    hidesRealTimePlayback: true
    hidesCodeToolbar: true
    requiredGear: {feet: 'simple-boots', 'right-hand': 'crude-builders-hammer'}
    restrictedGear: {'right-hand': 'simple-sword'}
  'winding-trail':
    hidesRealTimePlayback: true
    hidesCodeToolbar: true
    requiredGear: {feet: 'leather-boots', 'right-hand': 'crude-builders-hammer'}
    restrictedGear: {feet: 'simple-boots', 'right-hand': 'simple-sword'}
  'endangered-burl':
    hidesRealTimePlayback: true
    hidesCodeToolbar: true
    requiredGear: {feet: 'leather-boots', 'right-hand': 'simple-sword', 'programming-book': 'programmaticon-ii', eyes: 'crude-glasses'}
    restrictedGear: {feet: 'simple-boots', 'right-hand': 'crude-builders-hammer'}
  'village-guard':
    hidesCodeToolbar: true
    requiredGear: {feet: 'leather-boots', 'right-hand': 'simple-sword', 'programming-book': 'programmaticon-ii', eyes: 'crude-glasses'}
    restrictedGear: {feet: 'simple-boots', 'right-hand': 'crude-builders-hammer'}
  'thornbush-farm':
    hidesCodeToolbar: true
    requiredGear: {feet: 'leather-boots', 'right-hand': 'crude-builders-hammer', 'programming-book': 'programmaticon-ii', eyes: 'crude-glasses'}
    restrictedGear: {feet: 'simple-boots', 'right-hand': 'simple-sword'}
    requiredCode: ['topEnemy']
  'back-to-back':
    hidesCodeToolbar: true
    requiredGear: {feet: 'leather-boots', torso: 'tarnished-bronze-breastplate', waist: 'leather-belt', 'programming-book': 'programmaticon-ii', eyes: 'crude-glasses', 'right-hand': 'simple-sword', 'left-hand': 'wooden-shield'}
    restrictedGear: {feet: 'simple-boots', 'right-hand': 'crude-builders-hammer'}
  'ogre-encampment':
    requiredGear: {torso: 'tarnished-bronze-breastplate', waist: 'leather-belt', 'programming-book': 'programmaticon-ii', eyes: 'crude-glasses', 'right-hand': 'simple-sword', 'left-hand': 'wooden-shield'}
    restrictedGear: {feet: 'simple-boots', 'right-hand': 'crude-builders-hammer'}
  'woodland-cleaver':
    requiredGear: {torso: 'tarnished-bronze-breastplate', waist: 'leather-belt', 'programming-book': 'programmaticon-ii', eyes: 'crude-glasses', 'right-hand': 'long-sword', 'left-hand': 'wooden-shield', wrists: 'sundial-wristwatch', feet: 'leather-boots'}
    restrictedGear: {feet: 'simple-boots', 'right-hand': 'simple-sword'}
  'shield-rush':
    requiredGear: {torso: 'tarnished-bronze-breastplate', waist: 'leather-belt', 'programming-book': 'programmaticon-ii', eyes: 'crude-glasses', 'right-hand': 'long-sword', 'left-hand': 'bronze-shield', wrists: 'sundial-wristwatch'}
    restrictedGear: {'left-hand': 'wooden-shield'}

  # Warrior branch
  'peasant-protection':
    requiredGear: {torso: 'tarnished-bronze-breastplate', waist: 'leather-belt', 'programming-book': 'programmaticon-ii', eyes: 'wooden-glasses', 'right-hand': 'long-sword', 'left-hand': 'bronze-shield', wrists: 'sundial-wristwatch'}
    restrictedGear: {eyes: 'crude-glasses'}
  'munchkin-swarm':
    requiredGear: {torso: 'tarnished-bronze-breastplate', waist: 'leather-belt', 'programming-book': 'programmaticon-ii', eyes: 'wooden-glasses', 'right-hand': 'long-sword', 'left-hand': 'bronze-shield', wrists: 'sundial-wristwatch'}
    restrictedGear: {}

  # Ranger branch
  'munchkin-harvest':
    requiredGear: {torso: 'tarnished-bronze-breastplate', waist: 'leather-belt', 'programming-book': 'programmaticon-ii', eyes: 'wooden-glasses', 'right-hand': 'long-sword', 'left-hand': 'bronze-shield', wrists: 'sundial-wristwatch'}
    restrictedGear: {}
  'swift-dagger':
    requiredGear: {waist: 'leather-belt', 'programming-book': 'programmaticon-ii', eyes: 'wooden-glasses', 'right-hand': 'crude-crossbow', 'left-hand': 'crude-dagger', wrists: 'sundial-wristwatch'}
    restrictedGear: {eyes: 'crude-glasses'}
  'shrapnel':
    requiredGear: {waist: 'leather-belt', 'programming-book': 'programmaticon-ii', eyes: 'wooden-glasses', 'right-hand': 'crude-crossbow', 'left-hand': 'weak-charge', wrists: 'sundial-wristwatch'}
    restrictedGear: {eyes: 'crude-glasses', 'left-hand': 'crude-dagger'}

  # Wizard branch
  'arcane-ally':
    requiredGear: {torso: 'tarnished-bronze-breastplate', waist: 'leather-belt', 'programming-book': 'programmaticon-ii', eyes: 'wooden-glasses', 'right-hand': 'long-sword', 'left-hand': 'bronze-shield', wrists: 'sundial-wristwatch'}
    restrictedGear: {eyes: 'crude-glasses'}
  'touch-of-death':
    requiredGear: {waist: 'leather-belt', 'programming-book': 'programmaticon-ii', eyes: 'wooden-glasses', 'right-hand': 'enchanted-stick', 'left-hand': 'unholy-tome-i', wrists: 'sundial-wristwatch'}
    restrictedGear: {}
  'bonemender':
    requiredGear: {waist: 'leather-belt', 'programming-book': 'programmaticon-ii', eyes: 'wooden-glasses', 'right-hand': 'enchanted-stick', 'left-hand': 'book-of-life-i', wrists: 'sundial-wristwatch'}
    restrictedGear: {'left-hand': 'unholy-tome-i'}

  'coinucopia':
    requiredGear: {'programming-book': 'programmaticon-i', feet: 'leather-boots', 'programming-book': 'programmaticon-ii', flag: 'basic-flags'}
    restrictedGear: {}
  'copper-meadows':
    requiredGear: {'programming-book': 'programmaticon-i', feet: 'leather-boots', 'programming-book': 'programmaticon-ii', flag: 'basic-flags', eyes: 'wooden-glasses'}
    restrictedGear: {}
  'drop-the-flag':
    requiredGear: {'programming-book': 'programmaticon-i', feet: 'leather-boots', 'programming-book': 'programmaticon-ii', flag: 'basic-flags', eyes: 'wooden-glasses', 'right-hand': 'crude-builders-hammer'}
    restrictedGear: {'right-hand': 'long-sword'}
  'deadly-pursuit':
    requiredGear: {'programming-book': 'programmaticon-i', feet: 'leather-boots', 'programming-book': 'programmaticon-ii', flag: 'basic-flags', eyes: 'wooden-glasses', 'right-hand': 'crude-builders-hammer'}
    restrictedGear: {'right-hand': 'long-sword'}
  'rich-forager':
    requiredGear: {'programming-book': 'programmaticon-i', feet: 'leather-boots', 'programming-book': 'programmaticon-ii', flag: 'basic-flags', eyes: 'wooden-glasses', torso: 'tarnished-bronze-breastplate', 'right-hand': 'long-sword', 'left-hand': 'bronze-shield'}
    restrictedGear: {'right-hand': 'crude-builders-hammer'}
  'multiplayer-treasure-grove':
    requiredGear: {'programming-book': 'programmaticon-i', feet: 'leather-boots', 'programming-book': 'programmaticon-ii', flag: 'basic-flags', eyes: 'wooden-glasses', torso: 'tarnished-bronze-breastplate'}
    restrictedGear: {}
  'siege-of-stonehold':
    requiredGear: {}
    restrictedGear: {}
