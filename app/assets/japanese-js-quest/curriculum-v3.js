(function (root, factory) {
  const api = factory()
  if (typeof module === 'object' && module.exports) module.exports = api
  else {
    root.JSQuestCurriculumV3 = api
    if (root.JSQuestMissions) api.apply(root.JSQuestMissions)
  }
})(typeof self !== 'undefined' ? self : this, function () {
  'use strict'

  const STORAGE_KEY = 'japanese-js-quest-progress-v1'
  const CODE_KEY_PREFIX = 'japanese-js-quest-code-v1-'
  const MIGRATION_KEY = 'japanese-js-quest-curriculum-v3-migrated'
  const INFINITE_MESSAGE = 'ぼくは無限ループの中にいるよ。世界全体を動かす魔法だけが、ここから出してくれるんだ！'

  function finalIdForLegacyId (legacyId) {
    if (legacyId >= 13) return legacyId + 2
    if (legacyId >= 3) return legacyId + 1
    return legacyId
  }

  function legacyIdForFinalId (finalId) {
    if (finalId <= 2) return finalId
    if (finalId === 3) return 2
    if (finalId <= 13) return finalId - 1
    if (finalId === 14) return 12
    return finalId - 2
  }

  function booleanMission () {
    const originalStarterCode = [
      'const alwaysTrue = true;',
      'hero.isTrue(alwaysTrue);',
      '',
      'const alwaysFalse = false;',
      'hero.isTrue(alwaysFalse);',
      '',
      'hero.move("right");',
    ].join('\n')
    const starterCode = [
      '// true という値に alwaysTrue という名前をつける',
      'const alwaysTrue = true;',
      'hero.isTrue(alwaysTrue);',
      '',
      '// false という値に alwaysFalse という名前をつける',
      'const alwaysFalse = false;',
      'hero.isTrue(alwaysFalse);',
      '',
      '// 宝石を取って、旗まで進む',
      'hero.move("right");',
      'hero.move("right");',
    ].join('\n')

    return {
      id: 3,
      title: 'true と false',
      concept: 'ブール値（Boolean）と定数',
      story: '魔法には「正しい」と「正しくない」だけを表す特別な値があります。完成したコードをそのまま実行して、二つの値を確かめ、最後に旗まで進もう。',
      instructions: [
        '`true` と `false` は、二つしかないブール値です。',
        '`const` は値に名前をつけて固定し、あとで同じ値を使えるようにします。',
        '定数の名前は、空白を入れないローマ字で自由につけられます。意味が伝わりやすい英語の名前がよく使われます。',
        '`hero.isTrue(boolean)` は、受け取った値が true か false かを言葉で教えます。',
        'コードは完成しています。変更せずに「実行する」を押しましょう。',
      ],
      api: ['hero.isTrue(boolean)', 'hero.move(direction)'],
      originalStarterCode,
      starterCode,
      hints: ['コードは直さなくて大丈夫です。二つのふきだしを順番に閉じて、宝石を取ったあと旗まで進みましょう。'],
      solution: starterCode,
      variants: [{
        map: ['#####', '#H*G#', '#####'],
        sign: null,
      }],
      requirements: {
        booleanDemo: true,
        state: { goal: true, minGems: 1, maxMoves: 2, sayText: '違いますよ。' },
        syntax: [{ type: 'variable', message: 'const で true と false に名前をつけましょう。' }],
      },
    }
  }

  function infiniteLoopMission () {
    const starterCode = [
      'hero.move("right");',
      '',
      'while (true) {',
      '  hero.say(' + JSON.stringify(INFINITE_MESSAGE) + ');',
      '}',
    ].join('\n')

    return {
      id: 14,
      title: '終わらない while',
      concept: 'while (true) と無限ループ',
      story: 'while は、条件が true の間ずっと同じ処理を繰り返します。条件がいつまでも true なら、プログラムは自分では止まれません。',
      instructions: [
        '`while (true)` は条件が永遠に true なので、無限ループになります。',
        '無限ループは、次の命令へ進めず、コンピューターの力を使い続けるので危険です。',
        'このミッションは「実行する」を押した瞬間に先にクリア記録を保存します。',
        '実行後は、ブラウザーの丸い矢印を押すか `Ctrl+F5` でページ全体を再読み込みしてください。',
      ],
      api: ['while (true) { ... }', 'hero.say(message)', 'hero.move("right")'],
      starterCode,
      hints: ['実行するとヒーローは止まれません。ふきだしを確認したら、丸い矢印か Ctrl+F5 でページを再読み込みしましょう。'],
      solution: starterCode,
      infiniteLoopDemo: true,
      infiniteLoopMessage: INFINITE_MESSAGE,
      variants: [{
        map: ['#####', '#H*G#', '#####'],
        sign: null,
      }],
      requirements: {
        state: { minGems: 1, maxMoves: 1 },
        syntax: [
          { type: 'whileLoop', message: 'while (true) を実行して、無限ループを体験しましょう。' },
          { type: 'say', message: 'ループの中で hero.say(...) を使いましょう。' },
        ],
      },
    }
  }

  function migrateBrowserStorage () {
    if (typeof localStorage === 'undefined' || localStorage.getItem(MIGRATION_KEY) === 'done') return

    try {
      const savedCodes = new Map()
      for (let legacyId = 3; legacyId <= 20; legacyId++) {
        const value = localStorage.getItem(CODE_KEY_PREFIX + legacyId)
        if (value != null) savedCodes.set(legacyId, value)
      }
      for (let legacyId = 3; legacyId <= 20; legacyId++) {
        localStorage.removeItem(CODE_KEY_PREFIX + legacyId)
      }
      for (const [legacyId, value] of savedCodes) {
        localStorage.setItem(CODE_KEY_PREFIX + finalIdForLegacyId(legacyId), value)
      }

      const savedProgress = JSON.parse(localStorage.getItem(STORAGE_KEY) || '{}')
      if (Array.isArray(savedProgress.completed)) {
        savedProgress.completed = savedProgress.completed.map(finalIdForLegacyId)
      }
      if (savedProgress.unlocked != null) {
        const oldUnlocked = Math.max(1, Number(savedProgress.unlocked) || 1)
        savedProgress.unlocked = oldUnlocked + (oldUnlocked >= 4 ? 1 : 0) + (oldUnlocked >= 14 ? 1 : 0)
      }
      localStorage.setItem(STORAGE_KEY, JSON.stringify(savedProgress))
      localStorage.setItem(MIGRATION_KEY, 'done')
    } catch (_) {
      // Keep the game usable even when browser storage is unavailable or malformed.
    }
  }

  function apply (missions) {
    if (!Array.isArray(missions) || missions.__curriculumV3Applied) return missions

    for (const mission of missions) {
      const legacyId = Number(mission.id)
      mission.legacyId = legacyId
      mission.id = finalIdForLegacyId(legacyId)
    }

    missions.push(booleanMission(), infiniteLoopMission())
    missions.sort((left, right) => left.id - right.id)
    Object.defineProperty(missions, '__curriculumV3Applied', { value: true })

    if (typeof window !== 'undefined') migrateBrowserStorage()
    return missions
  }

  return {
    apply,
    finalIdForLegacyId,
    legacyIdForFinalId,
    INFINITE_MESSAGE,
  }
})