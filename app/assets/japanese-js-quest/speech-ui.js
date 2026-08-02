(function () {
  'use strict'

  let bubbleOpen = false
  let currentForm = 'hero'

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

  function resetForRun () {
    document.querySelectorAll('.hero-speech-bubble').forEach(element => element.remove())
    document.querySelectorAll('.level-up-overlay').forEach(element => element.remove())
    bubbleOpen = false
    currentForm = 'hero'
    applyFormToGrid()
  }

  function showSpeechBubble (message) {
    return new Promise(resolve => {
      const heroTile = document.querySelector('#game-grid .tile.hero')
      if (!heroTile) {
        resolve()
        return
      }

      document.querySelectorAll('.hero-speech-bubble').forEach(element => element.remove())
      bubbleOpen = true
      const bubble = document.createElement('div')
      bubble.className = 'hero-speech-bubble'
      bubble.setAttribute('role', 'dialog')
      bubble.setAttribute('aria-label', 'ヒーローのふきだし')
      bubble.innerHTML = [
        '<button class="speech-close" type="button" aria-label="ふきだしを閉じる">×</button>',
        '<p></p>',
      ].join('')
      bubble.querySelector('p').textContent = String(message)
      heroTile.appendChild(bubble)

      const close = () => {
        if (!bubbleOpen) return
        bubbleOpen = false
        bubble.remove()
        resolve()
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
