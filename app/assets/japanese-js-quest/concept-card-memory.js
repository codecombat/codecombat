(function (root, factory) {
  const api = factory(root)
  if (typeof module === 'object' && module.exports) module.exports = api
  else {
    root.JSQuestConceptMemory = api
    root.JSQuestExecutionGate = api.executionGate
    api.install()
  }
})(typeof self !== 'undefined' ? self : this, function (root) {
  'use strict'

  const STORAGE_KEY = 'japanese-js-quest-concept-memory-v1'
  let validatedCards = new Set()
  let previewCardId = null
  let activeModalCardId = null

  function storage () {
    return root && root.localStorage ? root.localStorage : null
  }

  function load () {
    try {
      const saved = JSON.parse(storage()?.getItem(STORAGE_KEY) || '{}')
      validatedCards = new Set(Array.isArray(saved.validatedCardIds) ? saved.validatedCardIds : [])
    } catch (_) {
      validatedCards = new Set()
    }
    return validatedCards
  }

  function save () {
    storage()?.setItem(STORAGE_KEY, JSON.stringify({
      validatedCardIds: Array.from(validatedCards).sort()
    }))
  }

  function currentMissionId () {
    if (typeof document === 'undefined') return 0
    const match = (document.getElementById('mission-number')?.textContent || '').match(/(\d+)/)
    return match ? Number(match[1]) : 0
  }

  function missionCardIds () {
    const guide = root.JSQuestConceptCards?.getMissionGuide(currentMissionId())
    return guide ? guide.cardIds.slice() : []
  }

  function isValidated (cardId) {
    return validatedCards.has(cardId)
  }

  function validateCard (cardId) {
    validatedCards.add(cardId)
    previewCardId = null
    save()
    if (typeof document !== 'undefined') {
      document.dispatchEvent(new CustomEvent('jsquest:conceptcardschanged', {
        detail: { cardId, validated: true }
      }))
    }
  }

  function isMissionReady () {
    const cardIds = missionCardIds()
    return cardIds.length > 0 && cardIds.every(isValidated)
  }

  function explainBlockedExecution () {
    if (typeof document === 'undefined') return
    const feedback = document.getElementById('feedback')
    if (feedback) {
      feedback.className = 'feedback neutral'
      feedback.textContent = '先に「新しい考え方」のカードを全部めくって、ミニクイズに正解しよう。'
    }
    document.getElementById('mission-learning-guide')?.scrollIntoView({ behavior: 'smooth', block: 'center' })
  }

  const executionGate = Object.freeze({
    canRun: isMissionReady,
    explainBlockedExecution
  })

  function shuffle (values) {
    const result = values.slice()
    for (let index = result.length - 1; index > 0; index--) {
      const target = Math.floor(Math.random() * (index + 1))
      const temporary = result[index]
      result[index] = result[target]
      result[target] = temporary
    }
    return result
  }

  function closePreview () {
    if (!previewCardId) return
    previewCardId = null
    refreshCards()
  }

  function ensureModal () {
    let modal = document.getElementById('concept-card-quiz-modal')
    if (modal) return modal

    modal = document.createElement('div')
    modal.id = 'concept-card-quiz-modal'
    modal.className = 'concept-card-quiz-modal'
    modal.hidden = true
    modal.innerHTML = [
      '<div class="concept-card-quiz-dialog" role="dialog" aria-modal="true" aria-labelledby="concept-card-quiz-title">',
      '  <button class="concept-card-quiz-close" type="button" aria-label="クイズを閉じる">×</button>',
      '  <p class="concept-card-quiz-eyebrow">カードを読んだか確認しよう</p>',
      '  <h3 id="concept-card-quiz-title">ミニクイズ</h3>',
      '  <form id="concept-card-quiz-form"></form>',
      '  <p id="concept-card-quiz-feedback" class="concept-card-quiz-feedback" aria-live="polite"></p>',
      '</div>'
    ].join('')
    document.body.appendChild(modal)

    const close = () => {
      modal.hidden = true
      activeModalCardId = null
      closePreview()
    }
    modal.querySelector('.concept-card-quiz-close').addEventListener('click', close)
    modal.addEventListener('click', event => {
      if (event.target === modal) close()
    })
    document.addEventListener('keydown', event => {
      if (!modal.hidden && event.key === 'Escape') close()
    })
    return modal
  }

  function openQuiz (cardId) {
    const quiz = root.JSQuestConceptCardQuizzes?.getQuiz(cardId)
    const card = root.JSQuestConceptCards?.getCard(cardId)
    if (!quiz || !card) return

    activeModalCardId = cardId
    const modal = ensureModal()
    const form = modal.querySelector('#concept-card-quiz-form')
    const feedback = modal.querySelector('#concept-card-quiz-feedback')
    modal.querySelector('#concept-card-quiz-title').textContent = 'ミニクイズ：' + cardId.replace('concept-card-', 'CARD ')
    feedback.textContent = ''
    feedback.className = 'concept-card-quiz-feedback'
    form.innerHTML = ''

    quiz.forEach((item, questionIndex) => {
      const fieldset = document.createElement('fieldset')
      fieldset.className = 'concept-card-quiz-question'
      const legend = document.createElement('legend')
      legend.textContent = (questionIndex + 1) + '. ' + item.prompt
      fieldset.appendChild(legend)

      shuffle(item.choices).forEach((choice, choiceIndex) => {
        const label = document.createElement('label')
        label.className = 'concept-card-quiz-choice'
        const input = document.createElement('input')
        input.type = 'radio'
        input.name = 'question-' + questionIndex
        input.value = choice
        input.id = 'quiz-' + questionIndex + '-' + choiceIndex
        const text = document.createElement('span')
        text.textContent = choice
        label.append(input, text)
        fieldset.appendChild(label)
      })
      form.appendChild(fieldset)
    })

    const submit = document.createElement('button')
    submit.type = 'submit'
    submit.className = 'button success concept-card-quiz-submit'
    submit.textContent = '答えを確認する'
    form.appendChild(submit)

    form.onsubmit = event => {
      event.preventDefault()
      const correct = quiz.every((item, questionIndex) => {
        const selected = form.querySelector('input[name="question-' + questionIndex + '"]:checked')
        return selected && selected.value === item.answer
      })

      if (!correct) {
        feedback.textContent = 'どこかにまちがいがあります。カードをもう一度読んで、やり直そう。'
        feedback.className = 'concept-card-quiz-feedback error'
        form.querySelectorAll('input[type="radio"]').forEach(input => { input.checked = false })
        return
      }

      validateCard(cardId)
      feedback.textContent = '正解！ このカードを確認できました。'
      feedback.className = 'concept-card-quiz-feedback success'
      window.setTimeout(() => {
        modal.hidden = true
        activeModalCardId = null
        refreshCards()
      }, 450)
    }

    modal.hidden = false
    modal.querySelector('.concept-card-quiz-close').focus()
  }

  function decorateCard (article) {
    const cardId = article.dataset.conceptCardId
    if (!cardId) return

    if (!article.dataset.masteryPrepared) {
      article.dataset.masteryPrepared = 'true'
      article.classList.add('concept-memory-card')

      const front = document.createElement('div')
      front.className = 'concept-card-front'
      while (article.firstChild) front.appendChild(article.firstChild)

      const cover = document.createElement('button')
      cover.type = 'button'
      cover.className = 'concept-card-cover'
      cover.innerHTML = '<span aria-hidden="true">📘</span><strong>新しいカード</strong><small>クリックしてめくる</small>'
      cover.addEventListener('click', event => {
        event.stopPropagation()
        previewCardId = cardId
        refreshCards()
      })

      const quizButton = document.createElement('button')
      quizButton.type = 'button'
      quizButton.className = 'concept-card-quiz-button'
      quizButton.innerHTML = '<span aria-hidden="true">🧠</span> ミニクイズ'
      quizButton.addEventListener('click', event => {
        event.stopPropagation()
        openQuiz(cardId)
      })

      const success = document.createElement('span')
      success.className = 'concept-card-success'
      success.setAttribute('aria-label', '確認済み')
      success.textContent = '✓'

      front.appendChild(quizButton)
      article.append(cover, front, success)
    }

    const validated = isValidated(cardId)
    const previewed = !validated && previewCardId === cardId
    article.classList.toggle('is-validated', validated)
    article.classList.toggle('is-preview', previewed)
    article.classList.toggle('is-covered', !validated && !previewed)
  }

  function renderProgress () {
    const guide = document.getElementById('mission-learning-guide')
    const heading = guide?.querySelector('.learning-guide-heading')
    if (!guide || !heading) return

    let progress = guide.querySelector('.concept-card-memory-progress')
    if (!progress) {
      progress = document.createElement('div')
      progress.className = 'concept-card-memory-progress'
      heading.appendChild(progress)
    }

    const cardIds = missionCardIds()
    const completed = cardIds.filter(isValidated).length
    progress.textContent = 'カード ' + completed + ' / ' + cardIds.length
    progress.classList.toggle('complete', completed === cardIds.length)
  }

  function updateExecutionGate () {
    const ready = isMissionReady()
    const run = document.getElementById('run-code')
    const codePanel = document.querySelector('.code-panel')
    const guide = document.getElementById('mission-learning-guide')
    if (run) {
      run.disabled = !ready
      run.setAttribute('aria-disabled', String(!ready))
      run.title = ready ? '' : '先にすべてのカードのミニクイズに正解しよう。'
    }
    codePanel?.classList.toggle('concept-cards-pending', !ready)
    guide?.classList.toggle('all-concept-cards-validated', ready)
  }

  function refreshCards () {
    if (typeof document === 'undefined') return
    document.querySelectorAll('#mission-learning-guide [data-concept-card-id]').forEach(decorateCard)
    renderProgress()
    updateExecutionGate()
  }

  function installGuards () {
    const run = document.getElementById('run-code')
    run?.addEventListener('click', event => {
      if (isMissionReady()) return
      event.preventDefault()
      event.stopImmediatePropagation()
      explainBlockedExecution()
    }, true)

    document.addEventListener('keydown', event => {
      if (!(event.ctrlKey || event.metaKey) || event.key !== 'Enter' || isMissionReady()) return
      event.preventDefault()
      event.stopImmediatePropagation()
      explainBlockedExecution()
    }, true)
  }

  function install () {
    if (typeof document === 'undefined') return
    const init = () => {
      load()
      ensureModal()
      installGuards()
      refreshCards()
      document.addEventListener('jsquest:missionloaded', () => {
        previewCardId = null
        activeModalCardId = null
        window.setTimeout(refreshCards, 0)
      })
      document.addEventListener('click', event => {
        if (!previewCardId || activeModalCardId) return
        if (event.target.closest('[data-concept-card-id]')) return
        closePreview()
      })
    }

    if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', init)
    else init()
  }

  return Object.freeze({
    STORAGE_KEY,
    load,
    save,
    isValidated,
    validateCard,
    isMissionReady,
    executionGate,
    install
  })
})
