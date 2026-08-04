(function () {
  'use strict'

  const oldMissionZeroCode = '// Yuzu にあいさつしよう\nhero.say(\'Hello Yuzu\');'
  const newMissionZeroCode = 'hero.say(\'Hello Yuzu\');'
  const missionZeroStorageKey = 'japanese-js-quest-code-v1-0'

  try {
    if (localStorage.getItem(missionZeroStorageKey) === oldMissionZeroCode) {
      localStorage.setItem(missionZeroStorageKey, newMissionZeroCode)
    }
  } catch (_) {}

  const terms = [
    { japanese: 'オブジェクト', english: 'Object', katakana: 'オブジェクト', missions: [0] },
    { japanese: 'メソッド', english: 'Method', katakana: 'メソッド', missions: [0, 1, 3, 5, 8] },
    { japanese: 'パラメーター', english: 'Parameter', katakana: 'パラメーター', missions: [0, 1, 3] },
    { japanese: '文字列', english: 'String', katakana: 'ストリング', missions: [0], preferredText: 'これは文字列という値です。' },
    { japanese: '文字列', english: 'String', katakana: 'ストリング', missions: [5] },
    { japanese: 'リテラル', english: 'Literal', katakana: 'リテラル', missions: [0] },
    { japanese: 'コメント', english: 'Comment', katakana: 'コメント', missions: [1] },
    { japanese: '定数', english: 'Constant', katakana: 'コンスタント', missions: [3, 11, 14, 20] },
    { japanese: '条件分岐', english: 'Conditional branch', katakana: 'コンディショナル・ブランチ', missions: [3, 20] },
    { japanese: '分岐', english: 'Branch', katakana: 'ブランチ', missions: [4, 9, 17, 19] },
    { japanese: '代入', english: 'Assignment', katakana: 'アサインメント', missions: [3, 18] },
    { japanese: '戻り値', english: 'Return value', katakana: 'リターン・バリュー', missions: [3, 5, 20] },
    { japanese: '比較', english: 'Comparison', katakana: 'コンパリズン', missions: [3, 5, 6, 14] },
    { japanese: '演算子', english: 'Operator', katakana: 'オペレーター', missions: [6, 7, 18] },
    { japanese: '真偽値', english: 'Boolean', katakana: 'ブーリアン', missions: [8, 13, 20] },
    { japanese: '変数', english: 'Variable', katakana: 'ヴァリアブル', missions: [18] },
    { japanese: '二重ループ', english: 'Nested loop', katakana: 'ネステッド・ループ', missions: [15, 18, 20] },
    { japanese: 'ループ', english: 'Loop', katakana: 'ループ', missions: [10, 12, 13, 14, 16, 17, 19] },
  ]

  const terminologyNotes = {
    6: 'プログラムで計算や判断をする記号を演算子と呼びます。`&&` は論理演算子、`!==` は比較演算子です。',
    7: '`||` も演算子の一つで、二つの条件を「または」でつなぐ論理演算子です。',
    18: '`%` は、割り算の余りを求める演算子です。',
  }

  function displayedMissionId () {
    const match = (document.getElementById('mission-number')?.textContent || '').match(/(\d+)/)
    return match ? Number(match[1]) : 0
  }

  function currentMissionId () {
    const finalId = displayedMissionId()
    const curriculum = window.JSQuestCurriculumV3
    return curriculum && typeof curriculum.legacyIdForFinalId === 'function'
      ? curriculum.legacyIdForFinalId(finalId)
      : finalId
  }

  function createEnglishTerm (term) {
    const span = document.createElement('span')
    span.className = 'glossary-token tech-term'
    span.tabIndex = 0
    span.setAttribute('role', 'button')
    span.dataset.tooltip = term.english + '（' + term.katakana + '）'
    span.textContent = term.english
    span.addEventListener('click', event => {
      event.stopPropagation()
      span.classList.toggle('is-open')
    })
    return span
  }

  function addEnglishName (root, term) {
    const walker = document.createTreeWalker(root, NodeFilter.SHOW_TEXT)
    const nodes = []
    while (walker.nextNode()) nodes.push(walker.currentNode)

    for (const node of nodes) {
      const parent = node.parentElement
      if (!parent || parent.closest('code, .glossary-token, script, style')) continue
      if (term.preferredText && !node.nodeValue.includes(term.preferredText)) continue
      const index = node.nodeValue.indexOf(term.japanese)
      if (index < 0) continue

      const fragment = document.createDocumentFragment()
      fragment.appendChild(document.createTextNode(node.nodeValue.slice(0, index + term.japanese.length) + '（'))
      fragment.appendChild(createEnglishTerm(term))
      fragment.appendChild(document.createTextNode('）' + node.nodeValue.slice(index + term.japanese.length)))
      node.replaceWith(fragment)
      return
    }
  }

  function addTerminologyNote (section, missionId) {
    const text = terminologyNotes[missionId]
    if (!text || section.querySelector('.technical-terminology-note')) return
    const article = section.querySelector('.learning-guide-grid article')
    if (!article) return

    const paragraph = document.createElement('p')
    paragraph.className = 'technical-terminology-note'
    paragraph.innerHTML = text.replace(/`([^`]+)`/g, '<code>$1</code>')
    article.appendChild(paragraph)
  }

  function enhanceGuide () {
    const section = document.getElementById('mission-learning-guide')
    if (!section || section.dataset.technicalTermsEnhanced === 'true') return
    section.dataset.technicalTermsEnhanced = 'true'

    const missionId = currentMissionId()
    addTerminologyNote(section, missionId)

    for (const term of terms) {
      if (term.missions.includes(missionId)) addEnglishName(section, term)
    }
  }

  function init () {
    document.addEventListener('jsquest:missionloaded', enhanceGuide)
    window.setTimeout(enhanceGuide, 0)
  }

  if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', init)
  else init()
})()
