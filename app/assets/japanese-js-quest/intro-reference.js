(function () {
  'use strict'

  function missionId () {
    const match = (document.getElementById('mission-number')?.textContent || '').match(/(\d+)/)
    return match ? Number(match[1]) : 0
  }

  function tooltip (text, meaning) {
    return '<span class="glossary-token" tabindex="0" role="button" data-tooltip="' + meaning + '">' + text + '</span>'
  }

  function bind (root) {
    root.querySelectorAll('.glossary-token').forEach(element => {
      element.addEventListener('click', event => {
        event.stopPropagation()
        element.classList.toggle('is-open')
      })
    })
  }

  function render () {
    const functions = document.getElementById('reference-functions')
    const parameters = document.getElementById('reference-parameters')
    const concepts = document.getElementById('reference-concepts')
    const values = document.getElementById('reference-values')
    if (!functions || !parameters || !concepts || !values) return

    const id = missionId()
    const range = document.getElementById('reference-range')
    if (range) range.textContent = id === 0 ? 'ミッション0で出てきた言葉' : 'ミッション0〜' + id + 'で出てきた言葉'

    if (!document.getElementById('reference-hero-say')) {
      const item = document.createElement('article')
      item.id = 'reference-hero-say'
      item.className = 'reference-item function-reference intro-reference-item'
      item.innerHTML = [
        '<div class="function-signature">',
        tooltip('hero', 'ヒーロー：主人公'), '.',
        tooltip('say', 'セイ：言う・話す'), '(',
        tooltip('message', 'メッセージ：話してほしい言葉'), ')</div>',
        '<p>ヒーローの頭の上に、言葉のふきだしを表示します。</p>',
        '<p class="word-breakdown">hero＝主人公 / say＝言う / message＝言葉</p>',
        '<div class="example-line"><span>例</span><code>hero.say("Hello Yuzu")</code></div>'
      ].join('')
      functions.prepend(item)
      bind(item)
    }

    if (!document.getElementById('reference-message-parameter')) {
      const chip = document.createElement('button')
      chip.id = 'reference-message-parameter'
      chip.className = 'reference-chip glossary-token intro-reference-item'
      chip.type = 'button'
      chip.dataset.tooltip = 'ヒーローに話してほしい言葉です。文字は " " または \' \' で囲みます。'
      chip.innerHTML = '<code>message</code><span>メッセージ：言葉</span>'
      parameters.prepend(chip)
      bind(chip)
    }

    if (id === 0 && !document.getElementById('reference-intro-concept')) {
      const concept = document.createElement('article')
      concept.id = 'reference-intro-concept'
      concept.className = 'reference-item concept-reference intro-reference-item'
      concept.innerHTML = '<div><strong>関数を呼ぶ</strong><code class="concept-code glossary-token" tabindex="0" data-tooltip="名前のあとに ( ) を書くと、その命令を実行します。">hero.say("Hello Yuzu")</code></div><p>say という命令に、話す言葉を渡しています。</p>'
      concepts.prepend(concept)
      bind(concept)
    }

    if (id === 0 && !document.getElementById('reference-intro-hero')) {
      const hero = document.createElement('button')
      hero.id = 'reference-intro-hero'
      hero.className = 'value-card glossary-token intro-reference-item'
      hero.type = 'button'
      hero.dataset.tooltip = '自分がプログラムで動かしたり、話させたりする主人公です。'
      hero.innerHTML = '<span class="value-icon">🧙</span><span><code>hero</code><small>ヒーロー：主人公</small></span>'
      values.prepend(hero)
      bind(hero)
    }
  }

  function scheduleRender () { window.setTimeout(render, 0) }

  function init () {
    const missionNumber = document.getElementById('mission-number')
    if (!missionNumber) return
    new MutationObserver(scheduleRender).observe(missionNumber, { childList: true, characterData: true, subtree: true })
    scheduleRender()
    window.setTimeout(() => {
      document.dispatchEvent(new CustomEvent('jsquest:missionloaded', { detail: { initialCurriculumRefresh: true } }))
    }, 0)
  }

  if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', init)
  else init()
})()
