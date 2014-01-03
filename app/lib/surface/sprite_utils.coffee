PROG_BAR_WIDTH = 20
PROG_BAR_HEIGHT = 2

module.exports.createProgressBar = createProgressBar = (color, y, width=PROG_BAR_WIDTH, height=PROG_BAR_HEIGHT) ->
  g = new createjs.Graphics()
  g.setStrokeStyle(1)
  g.beginFill(createjs.Graphics.getRGB(color...))
  g.drawRoundRect(0, -1, width, height, height)

  s = new createjs.Shape(g)
  s.x = -width / 2
  s.y = y
  s.z = 100
  s.width = width
  s.height = height
  return s

module.exports.createAvatar = createAvatar = (spriteName, $image) ->
  url = createAvatarURL spriteName
  $image ?= $('<img>')
  $image.attr('src', url)
  $image

module.exports.createAvatarURL = createAvatarURL = (spriteName) ->
  # We destroyed old version of this; this is temp anyway
  spriteName = _.string.slugify(spriteName).replace /-/g, '_'
  spriteName = {
    "anya": "captain_anya"
    "soldier": "ally_small"
    "ogre_munchkin": "enemy_small"
    "ogre": "enemy_medium"
    "ogre_brawler": "enemy_large"
    "ogre_fangrider": "enemy_flying"
    "ogre_shaman": "mage"
    "ogre_thrower": "thrower"
    "health_potion_small": "potion"
    "health_potion_medium": "potion"
    "health_potion_large": "potion"
  }[spriteName] ? spriteName
  "/images/avatars/#{spriteName}.png"
