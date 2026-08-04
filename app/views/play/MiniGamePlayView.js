require('app/styles/play/minigame-play.sass')
const RootView = require('views/core/RootView')
const template = require('app/templates/play/minigame-play')
const MiniGame = require('models/MiniGame')

/**
 * Plays a mini-game entirely from its DB document: fetches the doc by slug, lazy-loads
 * Phaser into its own chunk, executes the doc's code bundle from /file/, builds the
 * asset map, and drives the createGame/destroy contract documented in the
 * codecombat-mini-games repo. Admin-only until the GD-880 cutover.
 */
class MiniGamePlayView extends RootView {
  id = 'minigame-play-view'
  template = template

  constructor (options = {}, slug) {
    super(options)
    this.slug = slug
    this.gameHandle = null
  }

  afterInsert () {
    super.afterInsert()
    this.launch().catch(err => {
      console.error('[minigame] launch failed', err)
      this.showError(err?.message || 'Failed to launch mini-game.')
    })
  }

  async launch () {
    if (!me.isAdmin()) {
      this.showError('Admin only for now.')
      return
    }

    const miniGame = new MiniGame({ _id: this.slug })
    try {
      await new Promise((resolve, reject) => miniGame.fetch({ success: resolve, error: (m, res) => reject(res) }))
    } catch (res) {
      this.showError(res?.status === 404 ? `No mini-game found for slug "${this.slug}".` : 'Could not load the mini-game document.')
      return
    }
    if (this.destroyed) { return }

    const code = miniGame.get('code')
    if (!code) {
      this.showError('This mini-game has no code bundle uploaded yet.')
      return
    }

    // The bundle expects window.Phaser before it executes (IIFE, phaser external).
    const PhaserModule = await import(/* webpackChunkName: "phaser" */ 'phaser')
    if (this.destroyed) { return }
    window.Phaser = PhaserModule.default ?? PhaserModule

    // Re-entering the page must not re-execute an already-registered bundle.
    if (!window.CocoMiniGames?.[this.slug]) {
      await this.loadScript(this.fileUrl(code))
    }
    if (this.destroyed) { return }

    const gameModule = window.CocoMiniGames?.[this.slug]
    if (!gameModule?.createGame) {
      this.showError(`The code bundle did not register window.CocoMiniGames['${this.slug}'].`)
      return
    }

    this.gameHandle = gameModule.createGame({
      parent: this.$el.find('#minigame-host')[0],
      assets: this.buildAssetMap(miniGame),
      onExit: () => application.router.navigate('/editor/minigame', { trigger: true }),
      // Deliberately no analytics here: admin test sessions would pollute the event
      // stream. The GD-880 host attaches gameName and forwards real events.
      onEvent: (event, payload) => console.log('[minigame]', this.slug, event, payload),
    })
  }

  /** Stored values are bare /file paths; absolute (/ or http) URLs pass through. */
  fileUrl (path) {
    if (/^(https?:)?\//.test(path)) { return path }
    return `/file/${encodeURI(path)}`
  }

  buildAssetMap (miniGame) {
    const assets = { images: {}, atlases: {}, sounds: {} }
    for (const { key, image } of miniGame.get('images') || []) {
      assets.images[key] = this.fileUrl(image)
    }
    for (const { key, image, data } of miniGame.get('atlases') || []) {
      assets.atlases[key] = { image: this.fileUrl(image), data: this.fileUrl(data) }
    }
    for (const { key, mp3, ogg } of miniGame.get('sounds') || []) {
      assets.sounds[key] = [mp3, ogg].filter(Boolean).map(url => this.fileUrl(url))
    }
    return assets
  }

  loadScript (url) {
    return new Promise((resolve, reject) => {
      const script = document.createElement('script')
      script.src = url
      script.addEventListener('load', resolve, false)
      script.addEventListener('error', () => reject(new Error(`Could not load the game bundle from ${url}.`)), false)
      document.head.appendChild(script)
    })
  }

  showError (message) {
    this.$el.find('.minigame-error').text(message).show()
  }

  destroy () {
    // Tear the game down before super.destroy() wipes instance properties.
    try {
      this.gameHandle?.destroy()
    } catch (e) {
      console.error('[minigame] teardown error', e)
    }
    this.gameHandle = null
    return super.destroy()
  }
}

module.exports = MiniGamePlayView
