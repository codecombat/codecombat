(function () {
  'use strict'

  let bubbleOpen = false
  let currentForm = 'hero'
  let activeBubble = null
  let activeBubbleResolve = null
  let removePositionListeners = null

  function loadAddonAssets () {
    if (!document.querySelector('link[href="progression-ui.css"]')) {
      const link = document.createElement('link')
      link.rel = 'stylesheet'
      link.href = 'progression-ui.css'
      document.head.appendChild(link)
    }
    for (const src of ['progression-reference.js', 'progression-ui.js']) {
      if (document.querySelector('script[src="' + src + '"]')) continue
      const script = document.createElement('script')
      script.src = src
      document.body.appendChild(script)
    }
  }

  function applyFormToGrid () {
    document.querySelectorAll('#game-grid .tile.hero').forEach(tile => {
      tile.classList.toggle('form-frog', currentForm === 'frog')
      tile.classList.toggle('form-wizard', currentForm !== 'frog')
    })
  }

  function setForm (form) {
    currentForm = form === 'frog' ? 'frog' : 'hero'
    applyFormToGrid()
  }

  function clearActiveBubble (resolvePending) {
    if (removePositionListeners) removePositionListeners()
    removePositionListeners = null
    if (activeBubble) activeBubble.remove()
    activeBubble = null
    bubbleOpen = false

    if (resolvePending && activeBubbleResolve) activeBubbleResolve()
    activeBubbleResolve = null
  }

  function resetForRun () {
    clearActiveBubble(true)
    document.querySelectorAll('.level-up-overlay').forEach(element => element.remove())
    currentForm = 'hero'
    applyFormToGrid()
  }

  function positionBubble (bubble, heroTile) {
    if (!bubble.isConnected || !heroTile.isConnected) return
    const heroRect = heroTile.getBoundingClientRect()
    bubble.classList.remove('speech-clamped-top')
    bubble.style.left = (heroRect.left + heroRect.width / 2) + 'px'
    bubble.style.top = (heroRect.top - 13) + 'px'

    window.requestAnimationFrame(() => {
      if (!bubble.isConnected) return
      const bubbleRect = bubble.getBoundingClientRect()
      if (bubbleRect.top < 8) {
        bubble.classList.add('speech-clamped-top')
        bubble.style.top = '8px'
      }
    })
  }

  function watchBubblePosition (bubble, heroTile) {
    const update = () => positionBubble(bubble, heroTile)
    window.addEventListener('resize', update)
    window.addEventListener('scroll', update, true)
    update()

    return () => {
      window.removeEventListener('resize', update)
      window.removeEventListener('scroll', update, true)
    }
  }

  function showSpeechBubble (message) {
    return new Promise(resolve => {
      const heroTile = document.querySelector('#game-grid .tile.hero')
      if (!heroTile) {
        resolve()
        return
      }

      clearActiveBubble(true)
      bubbleOpen = true
      activeBubbleResolve = resolve

      const bubble = document.createElement('div')
      bubble.className = 'hero-speech-bubble'
      bubble.setAttribute('role', 'dialog')
      bubble.setAttribute('aria-modal', 'true')
      bubble.setAttribute('aria-label', 'ヒーローのふきだし')
      bubble.innerHTML = [
        '<button class="speech-close" type="button" aria-label="ふきだしを閉じる">×</button>',
        '<p></p>',
      ].join('')
      bubble.querySelector('p').textContent = String(message)
      document.body.appendChild(bubble)
      activeBubble = bubble
      removePositionListeners = watchBubblePosition(bubble, heroTile)

      const close = () => {
        if (!bubbleOpen || activeBubble !== bubble) return
        const finish = activeBubbleResolve
        clearActiveBubble(false)
        if (finish) finish()
      }
      bubble.querySelector('.speech-close').addEventListener('click', close, { once: true })
      bubble.querySelector('.speech-close').focus()
    })
  }

  function showLevelUpModal (html) {
    return new Promise(resolve => {
      const overlay = document.createElement('div')
      overlay.className = 'level-up-overlay'
      overlay.setAttribute('role', 'dialog')
      overlay.setAttribute('aria-modal', 'true')
      overlay.setAttribute('aria-label', 'レベルアップ')
      overlay.innerHTML = '<div class="level-up-modal">' + html + '<button class="button primary level-up-close" type="button">つづける</button></div>'
      document.body.appendChild(overlay)
      const close = () => {
        overlay.remove()
        resolve()
      }
      overlay.querySelector('.level-up-close').addEventListener('click', close, { once: true })
      overlay.querySelector('.level-up-close').focus()
    })
  }

  function init () {
    loadAddonAssets()
    applyFormToGrid()
  }

  window.JSQuestSpeechUI = {
    showSpeechBubble,
    showLevelUpModal,
    setForm,
    resetForRun,
  }

  if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', init)
  else init()
})()
