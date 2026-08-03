(function () {
  'use strict'

  function currentMissionId () {
    const match = (document.getElementById('mission-number')?.textContent || '').match(/(\d+)/)
    return match ? Number(match[1]) : 0
  }

  function tooltip (text, reading, extraClass) {
    return '<span class="glossary-token ' + (extraClass || '') + '" tabindex="0" role="button" data-tooltip="' +
      text + '（' + reading + '）">' + text + '</span>'
  }

  function bindCustomTokens (root) {
    root.querySelectorAll('.glossary-token:not([data-curriculum-bound])').forEach(token => {
      token.dataset.curriculumBound = 'true'
      token.addEventListener('click', event => {
        event.stopPropagation()
        token.classList.toggle('is-open')
      })
    })
  }

  function guideShell (title, cards) {
    return [
      '<div class="learning-guide-heading"><span>📚</span><div><strong>新しい考え方</strong><small>このミッションで初めて出てくること</small></div></div>',
      '<h3>' + title + '</h3>',
      '<div class="learning-guide-grid">',
      cards.map(card => '<article><h4>' + card[0] + '</h4><p>' + card[1] + '</p></article>').join(''),
      '</div>',
    ].join('')
  }

  function renderBooleanGuide () {
    const section = document.getElementById('mission-learning-guide')
    if (!section) return
    section.innerHTML = guideShell('true と false を名前に保存しよう', [
      [
        tooltip('ブール値', 'ぶーるち') + '（' + tooltip('Boolean', 'ブーリアン', 'tech-term') + '）',
        'ブール値は <code>true</code> と <code>false</code> の二つだけを持つ値です。<code>true</code> は「正しい」、<code>false</code> は「正しくない」を表します。',
      ],
      [
        '<code>const</code> は ' + tooltip('定数', 'ていすう') + '（' + tooltip('Constant', 'コンスタント', 'tech-term') + '）',
        '<code>const</code> は、プレイヤーが値に名前をつけて固定する魔法です。固定した値は、あとで同じ名前を使って何度でも再利用できます。',
      ],
      [
        '<code>=</code> は ' + tooltip('代入', 'だいにゅう') + '（' + tooltip('Assignment', 'アサインメント', 'tech-term') + '）',
        '<code>const alwaysTrue = true;</code> では、右側の <code>true</code> を左側の <code>alwaysTrue</code> という名前へ入れます。<code>=</code> は「同じか調べる」記号ではありません。',
      ],
      [
        '<code>always</code> は「いつも」',
        '<code>alwaysTrue</code> は「いつも true」、<code>alwaysFalse</code> は「いつも false」という意味です。名前を読むと、保存した値の意味を思い出せます。',
      ],
      [
        '<code>hero.isTrue(boolean)</code>',
        '<code>isTrue</code> はブール値だけを受け取ります。<code>true</code> なら「正しいです。」、<code>false</code> なら「違いますよ。」とヒーローが言います。',
      ],
    ])
    bindCustomTokens(section)
  }

  function renderInfiniteGuide () {
    const section = document.getElementById('mission-learning-guide')
    if (!section) return
    section.innerHTML = guideShell('止まらない条件ループを体験しよう', [
      [
        tooltip('条件ループ', 'じょうけんるーぷ') + '（' + tooltip('Conditional loop', 'コンディショナル・ループ', 'tech-term') + '）',
        '<code>while (条件) { ... }</code> は、条件が <code>true</code> の間、波かっこの中を何度も繰り返します。毎回、次の周回へ進む前に条件を確かめます。',
      ],
      [
        '<code>while (true)</code> は ' + tooltip('無限ループ', 'むげんるーぷ') + '（' + tooltip('Infinite loop', 'インフィニット・ループ', 'tech-term') + '）',
        '条件そのものがずっと <code>true</code> なので、ループを終えるきっかけがありません。次の命令へ進めず、コンピューターの力を使い続ける危険があります。',
      ],
      [
        tooltip('世界全体', 'せかいぜんたい') + 'を再起動する',
        'プログラム自身が止まれないときは、外側からシステムを再起動する必要があります。このゲームでは、ブラウザーの丸い矢印を押すか <code>Ctrl+F5</code> でページを再読み込みします。',
      ],
      [
        'クリア記録を先に保存する',
        'この特別なミッションでは、「実行する」を押した瞬間にクリア記録を保存してから無限ループを始めます。ページを再読み込みすると、次のミッションへ進めます。',
      ],
    ])
    bindCustomTokens(section)
  }

  function addBooleanReference (finalId) {
    if (finalId < 3) return
    const functions = document.getElementById('reference-functions')
    const parameters = document.getElementById('reference-parameters')
    const concepts = document.getElementById('reference-concepts')
    if (!functions || !parameters || !concepts) return

    if (!functions.querySelector('[data-curriculum-reference="isTrue"]')) {
      functions.insertAdjacentHTML('beforeend', [
        '<article class="reference-item function-reference" data-curriculum-reference="isTrue">',
        '<div class="function-signature" aria-label="hero.isTrue(boolean)">',
        tooltip('hero', 'ヒーロー：主人公'), '.', tooltip('is', 'イズ：〜である'), tooltip('True', 'トゥルー：正しい'), '(', tooltip('boolean', 'ブーリアン：true または false'), ')',
        '</div>',
        '<p>true か false を受け取り、結果を日本語で話します。</p>',
        '<p class="word-breakdown">is＝〜である / true＝正しい / boolean＝真偽値</p>',
        '<div class="example-line"><span>例</span><code>hero.isTrue(alwaysTrue)</code></div>',
        '</article>',
      ].join(''))
    }

    const parameterItems = [
      ['boolean', 'ブーリアン', 'true または false のどちらか一つだけを表す値です。'],
      ['true', 'トゥルー', '正しい・はいを表すブール値です。'],
      ['false', 'フォルス', '正しくない・いいえを表すブール値です。'],
      ['always', 'オールウェイズ', '「いつも」という意味です。alwaysTrue は「いつも true」です。'],
      ['alwaysTrue / alwaysFalse', 'オールウェイズ・トゥルー／フォルス', 'このミッションでブール値につけた定数名です。'],
    ]
    for (const item of parameterItems) {
      if (parameters.querySelector('[data-curriculum-code="' + item[0] + '"]')) continue
      parameters.insertAdjacentHTML('beforeend', '<button class="reference-chip glossary-token" type="button" data-curriculum-code="' + item[0] + '" data-tooltip="' + item[2] + '"><code>' + item[0] + '</code><span>' + item[1] + '</span></button>')
    }

    concepts.querySelectorAll('.concept-reference:not([data-curriculum-concept])').forEach(article => {
      const code = article.querySelector('.concept-code')?.textContent.trim()
      if (code === 'true / false' || code === '=') article.remove()
    })

    const conceptItems = [
      ['boolean', 'ブール値', 'true / false', 'true と false の二つだけを持つ値です。'],
      ['constant', '定数', 'const alwaysTrue = true', 'const で値に名前をつけて固定し、あとで再利用します。'],
      ['assignment', '代入', '=', '右側の値を左側の名前へ入れます。=== とは意味が違います。'],
    ]
    for (const item of conceptItems) {
      if (concepts.querySelector('[data-curriculum-concept="' + item[0] + '"]')) continue
      concepts.insertAdjacentHTML('beforeend', '<article class="reference-item concept-reference" data-curriculum-concept="' + item[0] + '"><div><strong>' + item[1] + '</strong><code class="concept-code glossary-token" tabindex="0" data-tooltip="' + item[3] + '">' + item[2] + '</code></div><p>' + item[3] + '</p></article>')
    }

    bindCustomTokens(document.getElementById('reference-panel'))
  }

  function addInfiniteReference (finalId) {
    if (finalId < 14) return
    const concepts = document.getElementById('reference-concepts')
    if (!concepts || concepts.querySelector('[data-curriculum-concept="infinite-loop"]')) return
    concepts.insertAdjacentHTML('beforeend', '<article class="reference-item concept-reference" data-curriculum-concept="infinite-loop"><div><strong>無限ループ</strong><code class="concept-code glossary-token" tabindex="0" data-tooltip="条件が永遠に true なので、自分では終われないループです。">while (true) { ... }</code></div><p>止める条件がないため、外側からシステムやページを再起動する必要があります。</p></article>')
    bindCustomTokens(document.getElementById('reference-panel'))
  }

  function adaptCurriculumUi () {
    const finalId = currentMissionId()

    if (finalId === 3) renderBooleanGuide()
    else if (finalId === 14) renderInfiniteGuide()

    addBooleanReference(finalId)
    addInfiniteReference(finalId)
    const range = document.getElementById('reference-range')
    if (range) range.textContent = 'MISSION ' + String(finalId).padStart(2, '0') + ' までに出てきた英語と記号'
  }

  function init () {
    document.addEventListener('jsquest:missionloaded', adaptCurriculumUi)
    adaptCurriculumUi()
  }

  if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', init)
  else init()
})()