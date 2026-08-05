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
    const doc = await this.resolveDoc()
    if (!doc || this.destroyed) { return }

    const code = doc.code
    if (!code) {
      this.showError('This mini-game has no code bundle uploaded yet.')
      return
    }

    // The bundle expects window.Phaser before it executes (IIFE, phaser external).
    const PhaserModule = await import(/* webpackChunkName: "phaser" */ 'phaser')
    if (this.destroyed) { return }
    window.Phaser = PhaserModule.default ?? PhaserModule

    // The bundle is executable: pin it to same-origin /file/ (URL-normalized, so ../
    // can't escape). Assets stay pass-through — they're media, never executed.
    const bundleUrl = new URL(this.fileUrl(code), window.location.origin)
    if (bundleUrl.origin !== window.location.origin || !bundleUrl.pathname.startsWith('/file/')) {
      this.showError('The code bundle must be a same-origin /file/ path.')
      return
    }

    // Always (re)load the bundle: a re-upload writes the SAME /file/ path, and the global
    // registry survives SPA navigation — so both the registry entry and the browser cache
    // can be stale. Cache-bust with the doc's save timestamp (dev tests always bust);
    // re-executing the IIFE just overwrites its registry entry.
    bundleUrl.searchParams.set('v', this.devMode ? String(Date.now()) : String(doc.updated || Date.now()))
    await this.loadScript(bundleUrl.href)
    if (this.destroyed) { return }

    const gameModule = window.CocoMiniGames?.[this.slug]
    if (!gameModule?.createGame) {
      this.showError(`The code bundle did not register window.CocoMiniGames['${this.slug}'].`)
      return
    }

    this.gameHandle = gameModule.createGame({
      parent: this.$el.find('#minigame-host')[0],
      assets: this.buildAssetMap(doc),
      onExit: () => this.onGameExit(),
      // This page fires no analytics itself: when framed, the hackstack host receives the
      // event via postMessage, attaches gameName, and tracks with its own base props.
      onEvent: (event, payload) => this.postToHost(event, payload),
    })
  }

  isFramed () {
    return window.parent !== window
  }

  /** Envelope contract documented in the codecombat-mini-games README. Same-origin only. */
  postToHost (event, payload) {
    if (!this.isFramed()) { return }
    window.parent.postMessage({ type: 'coco-minigame', slug: this.slug, event, payload }, window.location.origin)
  }

  onGameExit () {
    if (this.isFramed()) {
      this.postToHost('exit', {})
    } else if (me.isAdmin()) {
      application.router.navigate('/editor/minigame', { trigger: true })
    } else {
      window.location.href = '/ai/starlab'
    }
  }

  /**
   * Returns the doc's plain attributes. With ?dev=true, the editor's current UNSAVED
   * Treema state (handed over via localStorage by the Test button) wins over the DB doc.
   */
  async resolveDoc () {
    // Dev mode (unsaved editor state) is an authoring tool — admins only.
    this.devMode = new URLSearchParams(window.location.search).get('dev') === 'true' && me.isAdmin()
    if (this.devMode) {
      try {
        const stashed = JSON.parse(window.localStorage.getItem(`minigame-dev-doc:${this.slug}`) || 'null')
        if (stashed?.data) { return stashed.data }
      } catch (e) {
        console.warn('[minigame] could not parse dev doc, falling back to DB', e)
      }
      this.showError('No unsaved editor state found — use the Test button in the editor.')
      return null
    }

    const miniGame = new MiniGame({ _id: this.slug })
    try {
      await new Promise((resolve, reject) => miniGame.fetch({ success: resolve, error: (m, res) => reject(res) }))
    } catch (res) {
      this.showError(res?.status === 404 ? `No mini-game found for slug "${this.slug}".` : 'Could not load the mini-game document.')
      return null
    }
    return miniGame.attributes
  }

  /** Stored values are bare /file paths; absolute (/ or http) URLs pass through. */
  fileUrl (path) {
    if (/^(https?:)?\//.test(path)) { return path }
    return `/file/${encodeURI(path)}`
  }

  buildAssetMap (doc) {
    const assets = { images: {}, atlases: {}, sounds: {} }
    for (const { key, image } of doc.images || []) {
      assets.images[key] = this.fileUrl(image)
    }
    for (const { key, image, data } of doc.atlases || []) {
      assets.atlases[key] = { image: this.fileUrl(image), data: this.fileUrl(data) }
    }
    for (const { key, mp3, ogg } of doc.sounds || []) {
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
