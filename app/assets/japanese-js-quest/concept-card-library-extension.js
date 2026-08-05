(function (root, factory) {
  const base = typeof module === 'object' && module.exports
    ? require('./concept-card-library.js')
    : root.JSQuestConceptCards
  const api = factory(base)
  if (typeof module === 'object' && module.exports) module.exports = api
  else root.JSQuestConceptCards = api
})(typeof self !== 'undefined' ? self : this, function (base) {
  'use strict'

  if (!base) throw new Error('JSQuestConceptCards must be loaded before its extension')

  function tooltip (text, reading, extraClass) {
    return '<span class="glossary-token ' + (extraClass || '') + '" tabindex="0" role="button" data-tooltip="' +
      text + '（' + reading + '）">' + text + '</span>'
  }

  function card (id, missionId, titleHtml, bodyHtml) {
    return Object.freeze({ id, missionId, titleHtml, bodyHtml })
  }

  const replacementCards = Object.freeze([
    card(
      'concept-card-005',
      1,
      '<code>hero.move(direction)</code>',
      '<code>move</code> は動くメソッドです。パラメーター <code>direction</code> に <code>"left"</code> や <code>"right"</code> を渡して、動く方向を指定します。' +
        '<br><br>1回呼ぶと、ヒーローはその方向へ1マスだけ進みます。何マスも進みたいときは、進む回数だけこのメソッドを呼びます。'
    )
  ])

  const additionalCards = Object.freeze([
    card(
      'concept-card-037',
      1,
      tooltip('JavaScript', 'ジャバスクリプト', 'tech-term') + ' は' +
        tooltip('プログラミング言語', 'ぷろぐらみんぐげんご'),
      tooltip('JavaScript', 'ジャバスクリプト', 'tech-term') + ' は、コンピューターにしてほしいことを、決められた言葉と書き方で伝える ' +
        tooltip('プログラミング言語', 'ぷろぐらみんぐげんご') + ' です。この冒険では、JavaScript でヒーローに命令します。'
    ),
    card(
      'concept-card-038',
      1,
      tooltip('Editor', 'エディター', 'tech-term') + ' はコードを書く場所',
      tooltip('Editor', 'エディター', 'tech-term') + ' は、プログラムのコードを読んだり、書いたり、直したりする場所です。ここに JavaScript を書き、<code>実行する</code> で動かします。'
    )
  ])

  const replacementById = Object.freeze(Object.fromEntries(
    replacementCards.map(item => [item.id, item])
  ))
  const additionalById = Object.freeze(Object.fromEntries(
    additionalCards.map(item => [item.id, item])
  ))
  const cardsById = Object.freeze(Object.assign({}, base.cardsById, replacementById, additionalById))
  const missionOneGuide = Object.freeze({
    title: 'JavaScript editor とコメント、新しいメソッド：動く',
    cardIds: Object.freeze([
      'concept-card-037',
      'concept-card-038',
      'concept-card-036',
      'concept-card-005'
    ])
  })
  const missionGuides = Object.freeze(Object.assign({}, base.missionGuides, { 1: missionOneGuide }))

  function getCard (id) {
    return cardsById[id] || null
  }

  function getMissionGuide (missionId) {
    const guide = missionGuides[missionId]
    if (!guide) return null
    return {
      title: guide.title,
      cardIds: guide.cardIds.slice(),
      cards: guide.cardIds.map(getCard)
    }
  }

  function allCards () {
    return base.allCards()
      .map(item => replacementById[item.id] || item)
      .concat(additionalCards)
  }

  return Object.freeze({
    cardsById,
    missionGuides,
    getCard,
    getMissionGuide,
    allCards
  })
})
