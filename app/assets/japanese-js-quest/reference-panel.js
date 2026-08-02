(function () {
  'use strict'

  const functionEntries = [
    {
      from: 1,
      signature: [
        token('hero', 'ヒーロー（主人公）'), plain('.'),
        token('move', 'ムーブ：動く・移動する'), plain('('),
        token('direction', 'ディレクション：進む方向'), plain(')')
      ],
      example: 'hero.move("right")',
      description: 'ヒーローを、指定した方向へ1マス動かします。',
      words: 'hero＝主人公 / move＝動く / direction＝方向'
    },
    {
      from: 3,
      signature: [
        token('hero', 'ヒーロー（主人公）'), plain('.'),
        token('read', 'リード：読む'), token('Sign', 'サイン：看板・しるし'), plain('()')
      ],
      example: 'hero.readSign()',
      description: 'フィールドの看板に書かれた文字や数を読みます。',
      words: 'read＝読む / sign＝看板・しるし'
    },
    {
      from: 5,
      signature: [
        token('hero', 'ヒーロー（主人公）'), plain('.'),
        token('look', 'ルック：見る・調べる'), plain('('),
        token('direction', 'ディレクション：見る方向'), plain(')')
      ],
      example: 'hero.look("right")',
      description: '指定した方向の、となりのマスを調べます。gem、trap、enemy などの文字を返します。',
      words: 'look＝見る・調べる / direction＝方向'
    },
    {
      from: 6,
      signature: [
        token('hero', 'ヒーロー（主人公）'), plain('.'),
        token('can', 'キャン：〜できる・可能である'),
        token('Move', 'ムーブ：動く・移動する'), plain('('),
        token('direction', 'ディレクション：進みたい方向'), plain(')')
      ],
      example: 'hero.canMove("right")',
      description: 'その方向へ進めるなら true、進めないなら false を返します。',
      words: 'can＝できる / move＝動く / direction＝方向'
    },
    {
      from: 8,
      signature: [
        token('hero', 'ヒーロー（主人公）'), plain('.'),
        token('has', 'ハズ：持っている'),
        token('Key', 'キー：カギ'), plain('()')
      ],
      example: 'hero.hasKey()',
      description: 'ヒーローがカギを持っているなら true を返します。',
      words: 'has＝持っている / key＝カギ'
    },
    {
      from: 13,
      signature: [
        token('hero', 'ヒーロー（主人公）'), plain('.'),
        token('is', 'イズ：〜である'),
        token('At', 'アット：〜にいる'),
        token('Goal', 'ゴール：目的地'), plain('()')
      ],
      example: 'hero.isAtGoal()',
      description: 'ヒーローがゴールに着いているなら true を返します。',
      words: 'is＝〜である / at＝〜に / goal＝ゴール'
    }
  ]

  const parameterEntries = [
    word(1, 'direction', 'ディレクション', '方向を入れるための名前です。right、left、up、down などを渡します。'),
    word(1, 'right', 'ライト', '右。hero.move("right") で右へ進みます。'),
    word(1, 'left', 'レフト', '左。hero.move("left") で左へ進みます。'),
    word(2, 'up', 'アップ', '上。hero.move("up") で上へ進みます。'),
    word(2, 'down', 'ダウン', '下。hero.move("down") で下へ進みます。'),
    word(7, 'east', 'イースト', '東。今回のゲームでは right（右）と同じ意味の看板の言葉です。'),
    word(7, 'west', 'ウェスト', '西。今回のゲームでは left（左）と同じ意味の看板の言葉です。'),
    word(10, 'i / step / row', 'カウンターの名前', 'ループが今何回目かを覚えるための変数名です。名前は自分で決められます。'),
    word(14, 'distance / steps', '距離・歩数', '何マス進むか、何回くり返すかを保存する変数名です。')
  ]

  const conceptEntries = [
    concept(1, '関数の呼び出し', 'hero.move("right")', '名前のあとに ( ) を書いて、用意された動きを実行します。'),
    concept(1, '文字列', '"right"', 'ダブルクォーテーション " " で囲んだ文字です。方向やマスの種類を表します。'),
    concept(3, '変数を作る', 'const direction = ...', '値に名前をつけて覚えます。const で作った名前には、あとから別の値を入れません。'),
    concept(3, '条件', 'if (条件) { ... }', 'もし条件が正しいなら { } の中を実行します。if は「もし」です。'),
    concept(3, '同じか比較', '===', '左と右の値が同じかを調べます。例：direction === "right"'),
    concept(4, 'それ以外', 'else { ... }', 'if の条件が正しくなかったときに実行します。else は「それ以外」です。'),
    concept(5, '戻り値', 'const tile = hero.look("right")', '関数が調べた結果として返す値です。look は gem などの文字を返します。'),
    concept(6, '同じではない', '!==', '左と右の値がちがうかを調べます。例：tile !== "trap"'),
    concept(6, 'そして・両方', '&&', '左の条件と右の条件が、両方とも正しいときだけ true になります。'),
    concept(7, 'または・どちらか', '||', '左か右のどちらか一方でも正しければ true になります。'),
    concept(8, '真と偽', 'true / false', 'true は「正しい・はい」、false は「正しくない・いいえ」です。'),
    concept(9, '別の条件', 'else if (条件)', '最初の if がちがったとき、次の条件を調べます。選択肢が3つ以上あるときに使います。'),
    concept(10, '回数ループ', 'for (let i = 0; i < 6; i++)', '決めた回数だけ { } の中をくり返します。for は「回数を数えてくり返す」です。'),
    concept(10, '変えられる変数', 'let i = 0', 'あとから値を変えられる変数を作ります。ループの回数を数えるときによく使います。'),
    concept(10, 'より小さい', '<', '左の数が右の数より小さいかを調べます。i < 6 は「i が6より小さい」です。'),
    concept(10, '1増やす', 'i++', 'i の値を1だけ増やします。i = i + 1 とほぼ同じ意味です。'),
    concept(12, '条件ループ', 'while (条件) { ... }', '条件が正しい間、何度も { } の中をくり返します。'),
    concept(13, '反対にする', '!条件', 'true と false を反対にします。!hero.isAtGoal() は「まだゴールではない」です。'),
    concept(14, 'より大きい', '>', '左の数が右の数より大きいかを調べます。distance > 0 などに使います。'),
    concept(15, '二重ループ', 'for (...) { for (...) { ... } }', 'ループの中に、もう一つループを入れます。段と、その段の歩数を別々に数えられます。'),
    concept(15, '二つから選ぶ', '条件 ? A : B', '条件が正しければ A、ちがえば B を選びます。短い if / else のような書き方です。'),
    concept(18, '余り', '%', '割り算の余りを求めます。row % 2 が0なら偶数、1なら奇数です。'),
    concept(18, '値を入れる', '=', '右側の値を、左側の変数に入れます。===（同じか調べる）とは意味が違います。')
  ]

  const valueEntries = [
    value(1, '🧙', 'hero', 'ヒーロー', '自分がプログラムで動かす主人公です。'),
    value(1, '💎', 'gem', 'ジェム：宝石', 'hero.look(direction) が、となりに宝石があるとき返す文字です。'),
    value(1, '🏁', 'goal', 'ゴール', 'ミッションの目的地です。'),
    value(3, '🪧', 'sign', 'サイン：看板', 'hero.readSign() で看板の文字や数を読みます。'),
    value(5, '🧱', 'wall', 'ウォール：壁', '進めないマスです。look で調べると wall になります。'),
    value(5, '▫️', 'floor', 'フロア：床', '何もない、歩けるマスです。'),
    value(6, '⚠️', 'trap', 'トラップ：ワナ', '踏むと失敗になる危険なマスです。look で調べて避けます。'),
    value(8, '🔑', 'key', 'キー：カギ', '取るとドアを通れるようになります。'),
    value(8, '🚪', 'door', 'ドア：扉', 'カギを持っていると通れるマスです。'),
    value(13, '👹', 'enemy', 'エネミー：敵', '進路をふさぐ敵です。look で見つけて別の道から避けます。')
  ]

  function token (text, tooltip) {
    return { text, tooltip }
  }

  function plain (text) {
    return { text }
  }

  function word (from, code, reading, description) {
    return { from, code, reading, description }
  }

  function concept (from, name, code, description) {
    return { from, name, code, description }
  }

  function value (from, icon, code, reading, description) {
    return { from, icon, code, reading, description }
  }

  function escapeHtml (value) {
    return String(value)
      .replace(/&/g, '&amp;')
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;')
      .replace(/"/g, '&quot;')
      .replace(/'/g, '&#039;')
  }

  function tooltipToken (part) {
    if (!part.tooltip) return escapeHtml(part.text)
    return '<span class="glossary-token" tabindex="0" role="button" aria-label="' +
      escapeHtml(part.text + '：' + part.tooltip) + '" data-tooltip="' + escapeHtml(part.tooltip) + '">' +
      escapeHtml(part.text) + '</span>'
  }

  function renderFunctions (missionId) {
    return functionEntries
      .filter(item => item.from <= missionId)
      .map(item => [
        '<article class="reference-item function-reference">',
        '<div class="function-signature" aria-label="' + escapeHtml(item.example) + '">',
        item.signature.map(tooltipToken).join(''),
        '</div>',
        '<p>' + escapeHtml(item.description) + '</p>',
        '<p class="word-breakdown">' + escapeHtml(item.words) + '</p>',
        '<div class="example-line"><span>例</span><code>' + escapeHtml(item.example) + '</code></div>',
        '</article>'
      ].join(''))
      .join('')
  }

  function renderParameters (missionId) {
    return parameterEntries
      .filter(item => item.from <= missionId)
      .map(item => [
        '<button class="reference-chip glossary-token" type="button" data-tooltip="' + escapeHtml(item.description) + '">',
        '<code>' + escapeHtml(item.code) + '</code>',
        '<span>' + escapeHtml(item.reading) + '</span>',
        '</button>'
      ].join(''))
      .join('')
  }

  function renderConcepts (missionId) {
    return conceptEntries
      .filter(item => item.from <= missionId)
      .map(item => [
        '<article class="reference-item concept-reference">',
        '<div><strong>' + escapeHtml(item.name) + '</strong><code class="concept-code glossary-token" tabindex="0" data-tooltip="' + escapeHtml(item.description) + '">' + escapeHtml(item.code) + '</code></div>',
        '<p>' + escapeHtml(item.description) + '</p>',
        '</article>'
      ].join(''))
      .join('')
  }

  function renderValues (missionId) {
    return valueEntries
      .filter(item => item.from <= missionId)
      .map(item => [
        '<button class="value-card glossary-token" type="button" data-tooltip="' + escapeHtml(item.description) + '">',
        '<span class="value-icon">' + escapeHtml(item.icon) + '</span>',
        '<span><code>' + escapeHtml(item.code) + '</code><small>' + escapeHtml(item.reading) + '</small></span>',
        '</button>'
      ].join(''))
      .join('')
  }

  function getMissionId () {
    const missionNumber = document.getElementById('mission-number')
    const text = missionNumber ? missionNumber.textContent : ''
    const match = text.match(/(\d+)/)
    return match ? Number(match[1]) : 1
  }

  function render () {
    const missionId = getMissionId()
    const functions = document.getElementById('reference-functions')
    const parameters = document.getElementById('reference-parameters')
    const concepts = document.getElementById('reference-concepts')
    const values = document.getElementById('reference-values')
    const range = document.getElementById('reference-range')
    if (!functions || !parameters || !concepts || !values) return

    if (range) range.textContent = 'ミッション1〜' + missionId + 'で出てきた言葉'
    functions.innerHTML = renderFunctions(missionId)
    parameters.innerHTML = renderParameters(missionId)
    concepts.innerHTML = renderConcepts(missionId)
    values.innerHTML = renderValues(missionId)
    bindTooltipClicks()
  }

  function bindTooltipClicks () {
    document.querySelectorAll('#reference-panel .glossary-token').forEach(element => {
      if (element.dataset.tooltipBound) return
      element.dataset.tooltipBound = 'true'
      element.addEventListener('click', event => {
        event.stopPropagation()
        const wasOpen = element.classList.contains('is-open')
        document.querySelectorAll('#reference-panel .glossary-token.is-open').forEach(open => open.classList.remove('is-open'))
        element.classList.toggle('is-open', !wasOpen)
      })
    })
  }

  function init () {
    const missionNumber = document.getElementById('mission-number')
    if (!missionNumber) return
    new MutationObserver(render).observe(missionNumber, { childList: true, characterData: true, subtree: true })
    document.addEventListener('click', () => {
      document.querySelectorAll('#reference-panel .glossary-token.is-open').forEach(open => open.classList.remove('is-open'))
    })
    render()
  }

  if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', init)
  else init()
})()
