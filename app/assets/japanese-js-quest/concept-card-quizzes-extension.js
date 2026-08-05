(function (root, factory) {
  const base = typeof module === 'object' && module.exports
    ? require('./concept-card-quizzes.js')
    : root.JSQuestConceptCardQuizzes
  const api = factory(base)
  if (typeof module === 'object' && module.exports) module.exports = api
  else root.JSQuestConceptCardQuizzes = api
})(typeof self !== 'undefined' ? self : this, function (base) {
  'use strict'

  if (!base) throw new Error('JSQuestConceptCardQuizzes must be loaded before its extension')

  function question (prompt, answer, wrongChoices) {
    return Object.freeze({
      prompt,
      answer,
      choices: Object.freeze([answer, ...wrongChoices])
    })
  }

  const replacementQuizzes = Object.freeze({
    'concept-card-005': Object.freeze([
      question('hero.move(direction) は何をしますか？', '主人公を指定した方向へ動かす', ['主人公に話させる', 'ページを再読み込みする']),
      question('hero.move(...) を1回呼ぶと何マス進みますか？', '1マス', ['3マス', 'ゴールまで全部']),
      question('何マスも進みたいときはどうしますか？', '進む回数だけ hero.move(...) を呼ぶ', ['一度だけ呼ぶ', 'コメントに書くだけ'])
    ])
  })

  const additionalQuizzes = Object.freeze({
    'concept-card-037': Object.freeze([
      question(
        'JavaScript は何のためのことばですか？',
        'コンピューターにしてほしいことを伝えるため',
        ['宝石の色を決めるため', 'ブラウザーを閉じるため']
      ),
      question(
        'この冒険では JavaScript で何をしますか？',
        'ヒーローに命令する',
        ['カードを印刷する', '画面の明るさを変える']
      )
    ]),
    'concept-card-038': Object.freeze([
      question(
        'Editor は何をする場所ですか？',
        'コードを読んだり書いたり直したりする場所',
        ['宝石を置くだけの場所', 'ミッションを消す場所']
      ),
      question(
        'Editor に書いたコードを動かすにはどうしますか？',
        '実行するを押す',
        ['Editor を閉じる', 'コメントだけを書く']
      )
    ])
  })

  function getQuiz (cardId) {
    return replacementQuizzes[cardId] || additionalQuizzes[cardId] || base.getQuiz(cardId)
  }

  function allQuizzes () {
    return Object.freeze(Object.assign({}, base.allQuizzes(), replacementQuizzes, additionalQuizzes))
  }

  return Object.freeze({
    getQuiz,
    allQuizzes
  })
})
