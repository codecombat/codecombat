// Creates a sprite for thangTypes using raster atlas animation data (i.e. spriteType = rasterAtlas)
// Creates an interface that can be used by the attached lanks to play an action.

module.exports = class RasterAtlasSprite extends createjs.Container {
  constructor (thangType) {
    super()
    this.thangType = thangType
    this.movieClips = new Map() // acts like a cache of movieclip objects for different actions on the same sprite
  }

  configureSettings (action) {
    this.scaleX = this.scaleY = action.scale || this.thangType.get('scale') || 1
    if (action.flipX) {
      this.scaleX *= -1
    }
    if (action.flipY) {
      this.scaleY *= -1
    }
    this.baseScaleX = this.scaleX
    this.baseScaleY = this.scaleY

    const reg = (action.positions || {}).registration || (this.thangType.get('positions') || {}).registration || { x: 0, y: 0 }
    this.regX = -reg.x
    this.regY = -reg.y
  }

  gotoAndPlay (actionName) {
    this.removeAllChildren()

    const action = this.thangType.getActions()[actionName]
    this.notifyActionNeedsRender(action)
    this.configureSettings(action)

    const spriteData = this.thangType.getRasterAtlasSpriteData(actionName)

    // Play the movieClip if it exists and if its spritesheet(ss) is not empty
    if ((spriteData || {}).movieClip && !_.isEmpty((spriteData || {}).ss)) {
      const mc = this.movieClips.get(actionName) || new spriteData.movieClip()
      this.movieClips.set(actionName, mc)
      mc.framerate = (action.framerate || 20) * (action.speed || 1)
      this.addChild(mc)
      mc.play()
    } else {
      console.warn(`Sprite data for action ${actionName} not completely loaded/built yet.`, spriteData)
    }
  }

  // needed to render any action that is not inculded in the list of defaultActions in models/ThangType
  notifyActionNeedsRender (action) {
    if (this.lank) {
      this.lank.trigger('action-needs-render', this.lank, action)
    }
  }
}
