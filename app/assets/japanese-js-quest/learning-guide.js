(function () {
  'use strict'

  const readings = {
    条件分岐: 'じょうけんぶんき',
    優先順位: 'ゆうせんじゅんい',
    文字列: 'もじれつ',
    真偽値: 'しんぎち',
    二重ループ: 'にじゅうるーぷ',
    再読み込み: 'さいよみこみ',
    再起動: 'さいきどう',
    再利用: 'さいりよう',
    初めて: 'はじめて',
    主人公: 'しゅじんこう',
    働きかける: 'はたらきかける',
    保存: 'ほぞん',
    画像: 'がぞう',
    番号: 'ばんごう',
    存在: 'そんざい',
    行動: 'こうどう',
    世界: 'せかい',
    命令: 'めいれい',
    実行: 'じっこう',
    魔法: 'まほう',
    方法: 'ほうほう',
    指定: 'してい',
    情報: 'じょうほう',
    言葉: 'ことば',
    表示: 'ひょうじ',
    表す: 'あらわす',
    値: 'あたい',
    定数: 'ていすう',
    固定: 'こてい',
    代入: 'だいにゅう',
    構造: 'こうぞう',
    戻り値: 'もどりち',
    結果: 'けっか',
    条件: 'じょうけん',
    比較: 'ひかく',
    分岐: 'ぶんき',
    処理: 'しょり',
    繰り返し: 'くりかえし',
    判断: 'はんだん',
    状況: 'じょうきょう',
    複数: 'ふくすう',
    変数: 'へんすう',
    偶数: 'ぐうすう',
    奇数: 'きすう',
    無限: 'むげん',
    総復習: 'そうふくしゅう',
    経験値: 'けいけんち',
    宝石: 'ほうせき',
    看板: 'かんばん',
    方向: 'ほうこう',
    履歴: 'りれき',
    順番: 'じゅんばん',
    画面: 'がめん',
    削除: 'さくじょ',
    左右: 'さゆう',
    正しい: 'ただしい',
    正解: 'せいかい',
    調べる: 'しらべる',
    役割: 'やくわり',
    瞬間: 'しゅんかん',
    外側: 'そとがわ',
    両方: 'りょうほう',
    最初: 'さいしょ',
    最後: 'さいご',
    必要: 'ひつよう',
    選択肢: 'せんたくし',
    回数: 'かいすう',
    利点: 'りてん',
    周回: 'しゅうかい',
    確認: 'かくにん',
    背景色: 'はいけいしょく',
    理由: 'りゆう',
    危険: 'きけん',
    自身: 'じしん',
    追加: 'ついか',
    特別: 'とくべつ',
    自然: 'しぜん',
    反対: 'はんたい',
    距離: 'きょり',
    引用符: 'いんようふ',
    異なる: 'ことなる',
    完成: 'かんせい',
    目的: 'もくてき',
    説明: 'せつめい',
    概念: 'がいねん',
    暗記: 'あんき',
    更新: 'こうしん',
    変身: 'へんしん',
    割り算: 'わりざん',
    余り: 'あまり',
  }
  const readingWords = Object.keys(readings).sort((a, b) => b.length - a.length)

  function displayedMissionId () {
    const match = (document.getElementById('mission-number')?.textContent || '').match(/(\d+)/)
    return match ? Number(match[1]) : 0
  }

  function bindReadingTokens (root) {
    root.querySelectorAll('.reading-token:not([data-reading-bound])').forEach(element => {
      element.dataset.readingBound = 'true'
      element.addEventListener('click', event => {
        event.stopPropagation()
        element.classList.toggle('is-open')
      })
    })
  }

  function bindStoredCardTokens (root) {
    root.querySelectorAll('.glossary-token:not(.reading-token):not([data-concept-card-bound])').forEach(element => {
      element.dataset.conceptCardBound = 'true'
      element.addEventListener('click', event => {
        event.stopPropagation()
        element.classList.toggle('is-open')
      })
    })
  }

  function annotateText (root, gray) {
    if (!root) return
    const walker = document.createTreeWalker(root, NodeFilter.SHOW_TEXT)
    const nodes = []
    while (walker.nextNode()) nodes.push(walker.currentNode)

    for (const node of nodes) {
      const parent = node.parentElement
      if (!parent || !node.nodeValue.trim()) continue
      if (parent.closest('code, script, style, .glossary-token, .function-signature, button, a')) continue
      const pattern = new RegExp('(' + readingWords.join('|') + ')', 'g')
      if (!pattern.test(node.nodeValue)) continue
      pattern.lastIndex = 0

      const fragment = document.createDocumentFragment()
      let cursor = 0
      for (const match of node.nodeValue.matchAll(pattern)) {
        fragment.appendChild(document.createTextNode(node.nodeValue.slice(cursor, match.index)))
        const token = document.createElement('span')
        token.className = 'glossary-token reading-token' + (gray ? ' reading-token-gray' : '')
        token.tabIndex = 0
        token.setAttribute('role', 'button')
        token.dataset.tooltip = match[0] + '（' + readings[match[0]] + '）'
        token.textContent = match[0]
        fragment.appendChild(token)
        cursor = match.index + match[0].length
      }
      fragment.appendChild(document.createTextNode(node.nodeValue.slice(cursor)))
      node.replaceWith(fragment)
    }
    bindReadingTokens(root)
  }

  function annotateCurrentContent () {
    annotateText(document.getElementById('mission-learning-guide'), false)
    annotateText(document.getElementById('mission-title'), false)
    annotateText(document.getElementById('mission-instructions'), false)
    annotateText(document.getElementById('mission-story'), false)
    annotateText(document.getElementById('mission-concept'), false)
    annotateText(document.getElementById('field-mission-heading'), false)
    annotateText(document.getElementById('reference-panel'), true)
  }

  function scheduleAnnotations () {
    window.setTimeout(annotateCurrentContent, 0)
    window.setTimeout(annotateCurrentContent, 80)
  }

  function scheduleQuizAnnotations (event) {
    if (!event.target.closest('.concept-card-quiz-button')) return
    window.setTimeout(() => {
      annotateText(document.getElementById('concept-card-quiz-modal'), false)
    }, 0)
  }

  function renderGuide () {
    const library = window.JSQuestConceptCards
    const guide = library?.getMissionGuide(displayedMissionId())
    const story = document.getElementById('mission-story')
    if (!story || !guide) return

    let section = document.getElementById('mission-learning-guide')
    if (!section) {
      section = document.createElement('section')
      section.id = 'mission-learning-guide'
      section.className = 'mission-learning-guide'
      story.insertAdjacentElement('afterend', section)
    }
    section.innerHTML = [
      '<div class="learning-guide-heading"><span>📚</span><div><strong>新しい考え方</strong><small>このミッションで初めて出てくること</small></div></div>',
      '<h3>' + guide.title + '</h3>',
      '<div class="learning-guide-grid">',
      guide.cards.map(card => [
        '<article data-concept-card-id="' + card.id + '">',
        '<h4>' + card.titleHtml + '</h4>',
        '<p>' + card.bodyHtml + '</p>',
        '</article>',
      ].join('')).join(''),
      '</div>',
    ].join('')
    bindStoredCardTokens(section)
    scheduleAnnotations()
  }

  function init () {
    window.JSQuestReadingHelp = Object.freeze({
      annotate: (root, gray) => annotateText(root, Boolean(gray)),
      schedule: scheduleAnnotations,
      readings: Object.freeze(Object.assign({}, readings)),
    })
    document.addEventListener('jsquest:missionloaded', renderGuide)
    document.addEventListener('click', scheduleQuizAnnotations, true)
    renderGuide()
  }

  if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', init)
  else init()
})()
