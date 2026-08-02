(function () {
  'use strict'

  let bypassNextRun = false
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

  function currentMission () {
    const text = document.getElementById('mission-number')?.textContent || ''
    const match = text.match(/(\d+)/)
    const id = match ? Number(match[1]) : null
    return (window.JSQuestMissions || []).find(mission => mission.id === id)
  }

  function editorCode () {
    if (window.ace) {
      try { return window.ace.edit('editor').getValue() } catch (_) {}
    }
    return document.getElementById('editor-fallback')?.value || ''
  }

  function literalSayMessages (code) {
    return [...code.matchAll(/hero\.say\s*\(\s*(['"`])([\s\S]*?)\1\s*\)/g)].map(match => match[2])
  }

  function literalTransforms (code) {
    return [...code.matchAll(/hero\.transform\s*\(\s*(['"`])([^'"`]+)\1\s*\)/g)].map(match => match[2])
  }

  function applyFormToGrid () {
    document.querySelectorAll('#game-grid .tile.hero').forEach(tile => {
      tile.classList.toggle('form-frog', currentForm === 'frog')
      tile.classList.toggle('form-wizard', currentForm !== 'frog')
      const currentLabel = tile.getAttribute('aria-label') || ''
      const tileLabel = currentLabel.includes('、') ? currentLabel.slice(currentLabel.indexOf('、') + 1) : currentLabel
      tile.setAttribute('aria-label', (currentForm === 'frog' ? 'カエルの姿のヒーロー、' : 'ヒーロー、') + tileLabel)
    })
  }

  function setForm (form) {
    currentForm = form === 'frog' ? 'frog' : 'hero'
    applyFormToGrid()
  }

  function showSpeechBubble (message) {
    return new Promise(resolve => {
      if (bubbleOpen) return resolve()
      const heroTile = document.querySelector('#game-grid .tile.hero')
      if (!heroTile) return resolve()

      bubbleOpen = true
      const bubble = document.createElement('div')
      bubble.className = 'hero-speech-bubble'
      bubble.setAttribute('role', 'dialog')
      bubble.setAttribute('aria-label', 'ヒーローのふきだし')
      bubble.innerHTML = [
        '<button class="speech-close" type="button" aria-label="ふきだしを閉じる">×</button>',
        '<p></p>'
      ].join('')
      bubble.querySelector('p').textContent = message
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

  async function pauseBeforeRun (event) {
    if (bypassNextRun) {
      bypassNextRun = false
      return
    }
    if (bubbleOpen) {
      event.preventDefault()
      event.stopImmediatePropagation()
      return
    }

    const mission = currentMission()
    const code = editorCode()
    const says = literalSayMessages(code)
    const transforms = literalTransforms(code)
    const lockedTransform = transforms.length > 0 && (mission?.wizardLevel || 0) < 1

    if (!says.length && !lockedTransform) {
      const validForms = transforms.filter(form => form === 'frog' || form === 'hero')
      const lastForm = validForms[validForms.length - 1]
      if (lastForm) setForm(lastForm)
      return
    }

    event.preventDefault()
    event.stopImmediatePropagation()

    for (const message of says) await showSpeechBubble(message)
    if (lockedTransform) await showSpeechBubble(window.JSQuestEngine?.LOCKED_POWER_MESSAGE || 'まだできないざわだよ。')

    const validForms = transforms.filter(form => form === 'frog' || form === 'hero')
    const lastForm = !lockedTransform ? validForms[validForms.length - 1] : null
    if (lastForm) setForm(lastForm)
    bypassNextRun = true
    document.getElementById('run-code')?.click()
  }

  function init () {
    loadAddonAssets()
    const run = document.getElementById('run-code')
    const grid = document.getElementById('game-grid')
    if (!run) return
    run.addEventListener('click', pauseBeforeRun, true)
    document.addEventListener('keydown', event => {
      if (!(event.ctrlKey || event.metaKey) || event.key !== 'Enter') return
      pauseBeforeRun(event)
    }, true)
    if (grid) new MutationObserver(applyFormToGrid).observe(grid, { childList: true, subtree: true })
    applyFormToGrid()
  }

  window.JSQuestSpeechUI = { showSpeechBubble, showLevelUpModal, setForm }

  if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', init)
  else init()
})()
