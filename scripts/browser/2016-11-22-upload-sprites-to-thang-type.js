// Hacky SpriteSheet Uploading Script

// SETUP:
// Put the images somewhere in /app/assets
// Run locally on prod db
// Create the thang type in the thang type editor, set type to 'singular'.
// Be on the ThangEditView that you are editing

// STEP 1: Load images. Modify the range numbers and the file naming

// TODO Webpack: Reconcile createJS not being globally available
images = _.map(_.range(1,110), (i) => new createjs.Bitmap(`/images/kr/dark-knight/darkKnight_${_.string.pad(i, 4, '0')}.png`))

// STEP 2: Take ranges, match them with the correct default animation.
// Filenames are 1-indexed, frames or 0-indexed, and range is not inclusive,
// so... first number is -1 and second number is equal to those given.
// Make sure STEP 1 is done separately from STEP 2 or createjs will complain
// about unloaded images not having bounds.

builder = new createjs.SpriteSheetBuilder()
_.forEach(images, (i) => builder.addFrame(i))
builder.addAnimation('move_side', _.range(0,22))
builder.addAnimation('move_back', _.range(22,44))
builder.addAnimation('move_fore', _.range(44,66))
builder.addAnimation('idle', [66])
builder.addAnimation('attack', _.range(67,78))
builder.addAnimation('die', _.range(101,109))


// DIFFERENT VERSIONS OF STEPS 1 & 2

// ORC ARMORED

images = _.map(_.range(1,116), (i) => new createjs.Bitmap(`/images/kr/orc_armored/orc_armored_${_.string.pad(i, 4, '0')}.png`))

builder = new createjs.SpriteSheetBuilder()
_.forEach(images, (i) => builder.addFrame(i))
builder.addAnimation('move_side', _.range(0,22))
builder.addAnimation('move_back', _.range(22,44))
builder.addAnimation('move_fore', _.range(44,66))
builder.addAnimation('idle', [66])
builder.addAnimation('attack', _.range(67,77))
builder.addAnimation('thorned', _.range(77,100))
builder.addAnimation('die', _.range(100,115))


// SKELETON WARRIOR

images = _.map(_.range(1,147), (i) => new createjs.Bitmap(`/images/kr/skeleton_warrior/skeleton_warrior_${_.string.pad(i, 4, '0')}.png`))

builder = new createjs.SpriteSheetBuilder()
_.forEach(images, (i) => builder.addFrame(i))
builder.addAnimation('move_side', _.range(0,16))
builder.addAnimation('move_back', _.range(17,32))
builder.addAnimation('move_fore', _.range(32,47))
builder.addAnimation('idle', [47])
builder.addAnimation('attack', _.range(48,69))
builder.addAnimation('thorned', _.range(69,92))
builder.addAnimation('die', _.range(92,113))
builder.addAnimation('spawn', _.range(113,146))

// SPIDER

images = _.map(_.range(1,85), (i) => new createjs.Bitmap(`/images/kr/spiderMedium/spider_medium_${_.string.pad(i, 4, '0')}.png`))

builder = new createjs.SpriteSheetBuilder()
_.forEach(images, (i) => builder.addFrame(i))
builder.addAnimation('move_side', _.range(0,9))
builder.addAnimation('move_back', _.range(9,18))
builder.addAnimation('move_fore', _.range(18,27))
builder.addAnimation('idle', [27])
builder.addAnimation('attack', _.range(28,46))
builder.addAnimation('thorned', _.range(46,69))
builder.addAnimation('die', _.range(69,84))

// HERO MALIK
// IS TOO LARGE TO FIT INTO ONE SPRITE SHEET!

images = _.map(_.range(1,140), (i) => new createjs.Bitmap(`/images/kr/heroMalik/hero_reinforce_${_.string.pad(i, 4, '0')}.png`))

builder = new createjs.SpriteSheetBuilder()
_.forEach(images, (i) => builder.addFrame(i))
builder.addAnimation('idle', [0])
builder.addAnimation('move_side', _.range(1,6))
builder.addAnimation('attack', _.range(6,24))
builder.addAnimation('attack2', _.range(24,41))
builder.addAnimation('special', _.range(41,78))
builder.addAnimation('special2', _.range(78,105))
builder.addAnimation('levelUp', _.range(105,129))
builder.addAnimation('die', _.range(129,139))

// HERO MALIK TRIMMED

images = _.map(_.flatten([_.range(1,24), _.range(131,140)]), (i) => new createjs.Bitmap(`/images/kr/heroMalik/hero_reinforce_${_.string.pad(i, 4, '0')}.png`))

builder = new createjs.SpriteSheetBuilder()
_.forEach(images, (i) => builder.addFrame(i))
builder.addAnimation('idle', [0])
builder.addAnimation('move_side', _.range(1,6))
builder.addAnimation('attack', _.range(6,23))
builder.addAnimation('die', _.range(23,32))


// HERO LIGHTSEEKER
images = _.map(_.range(1,141), (i) => new createjs.Bitmap(`/images/kr/heroLightseeker/hero_barracks_${_.string.pad(i, 4, '0')}.png`))

builder = new createjs.SpriteSheetBuilder()
_.forEach(images, (i) => builder.addFrame(i))
builder.addAnimation('idle', [0])
builder.addAnimation('move_side', _.range(1,6))
builder.addAnimation('attack', _.range(6,17))
builder.addAnimation('attack2', _.range(17,28))
builder.addAnimation('levelUP', _.range(28,55))
builder.addAnimation('shield', _.range(55,79))
builder.addAnimation('buff', _.range(79,132))
builder.addAnimation('die', _.range(132,140))


// STEP 3: BUILD, UPLOAD SPRITE SHEET

sheet = builder.build()
sprite = new createjs.Sprite(sheet)
currentView.stage.addChild(sprite) // DEBUG STEP: Sprite should appear in Thang editor canvas

$('body').empty().append(sheet._images[0]) // DEBUG STEP: Should see whole sprite sheet


// Upload sprite sheet
src = sheet._images[0].toDataURL()
src = src.replace('data:image/png;base64,', '').replace(/\ /g, '+')
filename = 'spritesheet-'+_.string.slugify(moment().format())+'.png'
thangType = currentView.thangType
body = {
  filename,
  mimetype: 'image/png',
  path: `db/thang.type/${thangType.get('original')}`,
  b64png: src
}
$.ajax('/file', {type: 'POST', data: body})


// Save sprite sheet reference to thang type
frames = _.map(sheet._frames, (f) => {
    return [
      f.rect.x,
      f.rect.y,
      f.rect.width,
      f.rect.height,
      0,
      f.regX,
      f.regY
    ]
  })
spriteSheetData = {
  actionNames: sheet._animations,
  animations: sheet._data,
  frames,
  image: `db/thang.type/${thangType.get('original')}/`+filename,
  resolutionFactor: 3,
  spriteType: 'singular'
}
spriteSheets = []
spriteSheets.push(spriteSheetData)
thangType.set('prerenderedSpriteSheetData', spriteSheets)
thangType.save()

// STEP 4: UNIT SETUP

// You should now be able to point to animations in the actions. Add 'attack': { animation: 'attack' }
// for example. Setup unit as normal now!
