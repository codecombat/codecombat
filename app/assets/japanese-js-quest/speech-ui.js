(function () {
  'use strict'

  let bypassNextRun = false
  let bubbleOpen = false

  function currentMissionId () {
    const text = document.getElementById('mission-number')?.textContent || ''
    const match = text.match(/(\d+)/)
    return match ? Number(match[1]) : null
  }

  function editorCode () {
    if (window.ace) {
      try { return window.ace.edit('editor').getValue() } catch (_) {}
    }
    return document.getElementById('editor-fallback')?.value || ''
  }

  function firstSayMessage (code) {
    const match = code.match(/hero\.say\s*\(\s*(['"`])([\s\S]*?)\1\s*\)/)
    return match ? match[2] : null
  }

  function showSpeechBubble (message, onClose) {
    if (bubbleOpen) return
    const heroTile = document.querySelector('#game-grid .tile.hero')
    if (!heroTile) {
      onClose()
      return
    }

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
      onClose()
    }
    bubble.querySelector('.speech-close').addEventListener('click', close, { once: true })
    bubble.querySelector('.speech-close').focus()
  }

  function pauseIntroExecution (event) {
    if (bypassNextRun) {
      bypassNextRun = false
      return
    }
    if (currentMissionId() !== 0 || bubbleOpen) return

    const message = firstSayMessage(editorCode())
    if (message == null) return

    event.preventDefault()
    event.stopImmediatePropagation()
    showSpeechBubble(message, () => {
      bypassNextRun = true
      document.getElementById('run-code')?.click()
    })
  }

  function init () {
    const run = document.getElementById('run-code')
    if (!run) return
    run.addEventListener('click', pauseIntroExecution, true)
    document.addEventListener('keydown', event => {
      if (!(event.ctrlKey || event.metaKey) || event.key !== 'Enter') return
      pauseIntroExecution(event)
    }, true)
  }

  if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', init)
  else init()
})()
