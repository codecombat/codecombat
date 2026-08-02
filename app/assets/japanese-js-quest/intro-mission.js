(function (root, factory) {
  const mission = factory()
  if (typeof module === 'object' && module.exports) module.exports = mission
  else if (root.JSQuestMissions && !root.JSQuestMissions.some(item => item.id === mission.id)) {
    root.JSQuestMissions.unshift(mission)
    if (typeof document !== 'undefined' && document.readyState === 'loading' && !root.JSQuestProgression) {
      document.write('<script src="progression.js"><\/script>')
    }
  }
})(typeof self !== 'undefined' ? self : this, function () {
  'use strict'

  return {
    id: 0,
    title: 'こんにちは、Yuzu！',
    concept: 'はじめての関数：話す',
    story: 'まずはヒーローに、Yuzuへあいさつしてもらおう。宝石を集めると、魔法使いは経験値をもらって強くなります。',
    instructions: [
      '`hero.say(...)` は、ヒーローに言葉を話してもらう命令です。',
      'コードはもう完成しています。「実行する」を押して、ふきだしを読んだら × で閉じましょう。',
    ],
    api: ['hero.say("Hello Yuzu")'],
    starterCode: 'hero.say(\'Hello Yuzu\');',
    hints: ['このミッションはコードを直さなくてもクリアできます。「実行する」を押しましょう。'],
    solution: 'hero.say(\'Hello Yuzu\');',
    variants: [{
      map: [
        '#########',
        '#.......#',
        '#...H...#',
        '#.......#',
        '#########',
      ],
      sign: null,
    }],
    requirements: {
      state: { sayText: 'Hello Yuzu', maxMoves: 0 },
      syntax: [{ type: 'say', message: 'hero.say(...) を使ってあいさつしましょう。' }],
    },
  }
})
