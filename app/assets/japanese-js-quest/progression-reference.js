(function () {
  'use strict'

  function currentMissionId () {
    const match = (document.getElementById('mission-number')?.textContent || '').match(/(\d+)/)
    return match ? Number(match[1]) : 0
  }

  function tooltip (text, meaning) {
    return '<span class="glossary-token" tabindex="0" role="button" data-tooltip="' + meaning + '">' + text + '</span>'
  }

  function bind (root) {
    root.querySelectorAll('.glossary-token').forEach(element => {
      if (element.dataset.progressionBound) return
      element.dataset.progressionBound = 'true'
      element.addEventListener('click', event => {
        event.stopPropagation()
        element.classList.toggle('is-open')
      })
    })
  }

  function updateGemHelp () {
    document.querySelectorAll('#reference-values .value-card').forEach(card => {
      if (card.querySelector('code')?.textContent !== 'gem' || card.dataset.progressionGemHelp) return
      card.dataset.progressionGemHelp = 'true'
      card.dataset.tooltip = 'ジェム：宝石。集めると経験値が増え、魔法使いのレベルが上がって、新しい力が使えるようになります。'
      const reading = card.querySelector('small')
      if (reading) reading.textContent = 'ジェム：宝石・経験値'
    })
  }

  function renderTransformHelp () {
    if (currentMissionId() < 2) return
    const functions = document.getElementById('reference-functions')
    const parameters = document.getElementById('reference-parameters')
    const values = document.getElementById('reference-values')
    if (!functions || !parameters || !values) return

    if (!document.getElementById('reference-transform')) {
      const item = document.createElement('article')
      item.id = 'reference-transform'
      item.className = 'reference-item function-reference progression-reference-item'
      item.innerHTML = [
        '<div class="function-signature">',
        tooltip('hero', 'ヒーロー：主人公'), '.',
        tooltip('trans', 'トランス：変える・別の状態へ'),
        tooltip('form', 'フォーム：姿・形'), '(',
        tooltip('form', 'フォーム：変身したい姿'), ')</div>',
        '<p>魔法使いの見た目を、指定した姿へ変えます。</p>',
        '<p class="word-breakdown">transform＝姿を変える / form＝姿・形</p>',
        '<div class="example-line"><span>例</span><code>hero.transform("frog")</code></div>'
      ].join('')
      functions.appendChild(item)
      bind(item)
    }

    if (!document.getElementById('reference-form-parameter')) {
      const chip = document.createElement('button')
      chip.id = 'reference-form-parameter'
      chip.className = 'reference-chip glossary-token progression-reference-item'
      chip.type = 'button'
      chip.dataset.tooltip = 'フォーム：変身したい姿を入れます。今は "frog" または "hero" を使えます。'
      chip.innerHTML = '<code>form</code><span>フォーム：姿・形</span>'
      parameters.appendChild(chip)
      bind(chip)
    }

    if (!document.getElementById('reference-frog-value')) {
      const frog = document.createElement('button')
      frog.id = 'reference-frog-value'
      frog.className = 'value-card glossary-token progression-reference-item'
      frog.type = 'button'
      frog.dataset.tooltip = 'フロッグ：カエル。hero.transform("frog") でカエルの姿になります。'
      frog.innerHTML = '<span class="value-icon frog-reference-icon"><img src="frog-sprite.svg" alt=""></span><span><code>frog</code><small>フロッグ：カエル</small></span>'
      values.appendChild(frog)
      bind(frog)
    }
  }

  function render () {
    window.setTimeout(() => {
      updateGemHelp()
      renderTransformHelp()
    }, 0)
  }

  function init () {
    const number = document.getElementById('mission-number')
    if (number) new MutationObserver(render).observe(number, { childList: true, subtree: true, characterData: true })
    const values = document.getElementById('reference-values')
    if (values) new MutationObserver(render).observe(values, { childList: true })
    render()
  }

  if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', init)
  else init()
})()
