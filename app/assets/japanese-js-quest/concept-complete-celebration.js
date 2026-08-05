(function () {
  'use strict'

  let activeOverlay = null
  let waitingForQuizToClose = false

  function showCelebration () {
    if (activeOverlay || !window.JSQuestConceptMemory?.isMissionReady()) return

    const quizModal = document.getElementById('concept-card-quiz-modal')
    if (quizModal && !quizModal.hidden) {
      if (!waitingForQuizToClose) {
        waitingForQuizToClose = true
        window.setTimeout(() => {
          waitingForQuizToClose = false
          showCelebration()
        }, 500)
      }
      return
    }

    const overlay = document.createElement('div')
    overlay.className = 'level-up-overlay concept-complete-overlay'
    overlay.setAttribute('role', 'dialog')
    overlay.setAttribute('aria-modal', 'true')
    overlay.setAttribute('aria-label', 'カード確認完了')
    overlay.innerHTML = [
      '<div class="level-up-modal concept-complete-modal">',
      '  <div class="concept-complete-icon" aria-hidden="true"><span>🎉</span><strong>✓</strong><span>🎉</span></div>',
      '  <h2>おめでとう！</h2>',
      '  <p class="concept-complete-unlocked">ミッションがひらいたよ。</p>',
      '  <p class="concept-complete-next">説明を最後まで読んで、下へスクロールしよう。</p>',
      '  <button class="button success concept-complete-close" type="button">つづける</button>',
      '</div>'
    ].join('')
    document.body.appendChild(overlay)
    activeOverlay = overlay

    const close = () => {
      overlay.remove()
      activeOverlay = null
    }
    overlay.querySelector('.concept-complete-close').addEventListener('click', close, { once: true })
    overlay.querySelector('.concept-complete-close').focus()
  }

  document.addEventListener('jsquest:conceptcardschanged', event => {
    if (!event.detail?.validated) return
    window.setTimeout(showCelebration, 0)
  })
})()
