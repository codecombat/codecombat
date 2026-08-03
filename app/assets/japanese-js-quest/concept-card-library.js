(function (root, factory) {
  const api = factory()
  if (typeof module === 'object' && module.exports) module.exports = api
  else root.JSQuestConceptCards = api
})(typeof self !== 'undefined' ? self : this, function () {
  'use strict'

  const cardList = [
    card('concept-card-001', 0, '<code>hero</code> はオブジェクト', 'オブジェクトは、プログラムの中に存在して、世界に働きかけられるものです。<code>hero</code> は主人公そのものを表します。'),
    card('concept-card-002', 0, '<code>.say</code> はメソッド', 'メソッドは、そのオブジェクトにしてほしい行動です。<code>hero</code> のあとに点 <code>.</code> とメソッド名を書くと、主人公にどの命令を実行してほしいか伝えられます。'),
    card('concept-card-003', 0, '<code>(message)</code> はパラメーター', '丸いかっこの中には、行動を詳しく指定する情報を入れます。<code>hero.say(message)</code> では、主人公が言う言葉を指定します。'),
    card('concept-card-004', 0, '<code>"Hello Yuzu"</code> は文字列リテラル', 'ふつう、ローマ字はプログラムの命令を書くために使います。でも <code>" "</code> の中に入れると、主人公の世界で使う「文字そのもの」になります。これは文字列という値です。'),
    card('concept-card-005', 1, '<code>hero.move(direction)</code>', '<code>move</code> は動くメソッドです。パラメーター <code>direction</code> に <code>"left"</code> や <code>"right"</code> を渡して、動く方向を指定します。'),
    card('concept-card-006', 2, '実行する順番', 'JavaScript は、上の行から下の行へ、一つの命令が終わってから次の命令を実行します。順番を変えると、主人公の動きも変わります。'),
    card('concept-card-007', 3, tooltip('ブール値', 'ぶーるち') + '（' + tooltip('Boolean', 'ブーリアン', 'tech-term') + '）', 'ブール値は <code>true</code> と <code>false</code> の二つだけを持つ値です。<code>true</code> は「正しい」、<code>false</code> は「正しくない」を表します。'),
    card('concept-card-008', 3, '<code>const</code> は ' + tooltip('定数', 'ていすう') + '（' + tooltip('Constant', 'コンスタント', 'tech-term') + '）', '<code>const</code> は、プレイヤーが値に名前をつけて固定する魔法です。固定した値は、あとで同じ名前を使って何度でも再利用できます。'),
    card('concept-card-009', 3, '<code>=</code> は ' + tooltip('代入', 'だいにゅう') + '（' + tooltip('Assignment', 'アサインメント', 'tech-term') + '）', '<code>const alwaysTrue = true;</code> では、右側の <code>true</code> を左側の <code>alwaysTrue</code> という名前へ入れます。<code>=</code> は「同じか調べる」記号ではありません。'),
    card('concept-card-010', 3, tooltip('定数', 'ていすう') + 'の名前は自分で決められる', 'この冒険では、空白を入れずにローマ字で好きな名前をつけられます。日本のプログラマーも、意味が伝わりやすい英語の名前をよく使います。たとえば <code>alwaysTrue</code> は「いつも true」という意味です。'),
    card('concept-card-011', 3, '<code>hero.isTrue(boolean)</code>', '<code>isTrue</code> はブール値だけを受け取ります。<code>true</code> なら「正しいです。」、<code>false</code> なら「違いますよ。」とヒーローが言います。'),
    card('concept-card-012', 4, '<code>hero.readSign()</code> の戻り値', 'メソッドは行動するだけでなく、結果の値を返すことがあります。<code>readSign()</code> は、看板に書かれた <code>"right"</code> や <code>"left"</code> を返します。'),
    card('concept-card-013', 4, '<code>if (条件) { ... }</code>', '<code>if</code> は条件分岐です。丸いかっこの条件が正しいときだけ、波かっこ <code>{ }</code> の中を実行します。'),
    card('concept-card-014', 4, '<code>===</code> は比較', '<code>direction === "right"</code> のように、左と右の値が同じかを調べます。値を入れる <code>=</code> とは役割が違います。'),
    card('concept-card-015', 5, '<code>else</code>', '<code>if</code> の条件が正しくなかった場合に、代わりに実行する道です。<code>if</code> と <code>else</code> のどちらか一方だけが動きます。'),
    card('concept-card-016', 6, '<code>hero.look(direction)</code>', 'となりのマスを調べて、<code>"gem"</code> などの文字列を戻り値として返します。その値を <code>===</code> で直接比較できます。'),
    card('concept-card-017', 7, '<code>&&</code> と <code>!==</code>', '<code>&&</code> は左右の条件が両方とも正しいときだけ正しくなります。<code>!==</code> は「同じではない」を表す比較です。'),
    card('concept-card-018', 8, '<code>||</code>', '<code>||</code> は、左右の条件のどちらか一方でも正しければ、全体を正しいと判断します。'),
    card('concept-card-019', 9, '<code>hero.hasKey()</code>', 'カギを持っていれば <code>true</code>、持っていなければ <code>false</code> を返します。この二つは真偽値と呼ばれ、<code>if</code> の条件にそのまま使えます。'),
    card('concept-card-020', 10, '<code>else if</code>', '最初の <code>if</code> が正しくなかったとき、次の条件を調べます。最後の <code>else</code> は、それまでのどの条件にも当てはまらない場合です。'),
    card('concept-card-021', 11, '<code>for (let i = 0; i &lt; 6; i++)</code>', '<code>let i = 0</code> で数え始め、<code>i &lt; 6</code> の間だけ繰り返し、<code>i++</code> で毎回 1 増やします。波かっこの中が繰り返す処理です。'),
    card('concept-card-022', 12, '<code>const steps = 5</code>', '数字の値にも名前をつけられます。意味のある名前を使うと、あとで回数を変えたり、コードを読んだりしやすくなります。'),
    card('concept-card-023', 13, '<code>while (条件) { ... }</code>', '回数を先に決めず、条件が正しい間ずっと繰り返します。毎回、条件をもう一度確認してから次の繰り返しへ進みます。'),
    card('concept-card-024', 14, tooltip('条件ループ', 'じょうけんるーぷ') + '（' + tooltip('Conditional loop', 'コンディショナル・ループ', 'tech-term') + '）', '<code>while (条件) { ... }</code> は、条件が <code>true</code> の間、波かっこの中を何度も繰り返します。毎回、次の周回へ進む前に条件を確かめます。'),
    card('concept-card-025', 14, '<code>while (true)</code> は ' + tooltip('無限ループ', 'むげんるーぷ') + '（' + tooltip('Infinite loop', 'インフィニット・ループ', 'tech-term') + '）', '条件そのものがずっと <code>true</code> なので、ループを終えるきっかけがありません。次の命令へ進めず、コンピューターの力を使い続ける危険があります。'),
    card('concept-card-026', 14, tooltip('世界全体', 'せかいぜんたい') + 'を再起動する', 'プログラム自身が止まれないときは、外側からシステムを再起動する必要があります。このゲームでは、ブラウザーの丸い矢印を押すか <code>Ctrl+F5</code> でページを再読み込みします。'),
    card('concept-card-027', 14, 'クリア記録を先に保存する', 'この特別なミッションでは、「実行する」を押した瞬間にクリア記録を保存してから無限ループを始めます。ページを再読み込みすると、次のミッションへ進めます。'),
    card('concept-card-028', 15, '<code>while</code> の中の <code>if</code>', '繰り返すたびに状況を調べ、行動を変えられます。先頭の <code>!</code> は真偽値を反対にして、「まだゴールではない間」を表します。'),
    card('concept-card-029', 16, '<code>if</code> の中の <code>for</code>', 'まず距離が 0 より大きいかを <code>&gt;</code> で比較し、必要な場合だけループを開始します。定数をループの回数として再利用できます。'),
    card('concept-card-030', 17, '二重ループ', '外側のループが段を数え、内側のループが一つの段の移動を繰り返します。<code>条件 ? 値1 : 値2</code> は、条件によって使う値を選ぶ短い書き方です。'),
    card('concept-card-031', 18, 'ループの波かっこ', '波かっこの中には複数の命令を書けます。中の命令を上から順番に全部終えてから、次の繰り返しへ進みます。'),
    card('concept-card-032', 19, 'while + if / else if / else', '毎回まず右を調べ、無理なら上、どちらも無理なら左という順番で判断します。先に正しくなった分岐だけが実行されます。'),
    card('concept-card-033', 20, '<code>let</code>、代入、<code>%</code>', '<code>let</code> で作った変数は、あとから別の値を代入できます。<code>%</code> は割り算の余りを求め、偶数と奇数を見分けるために使えます。'),
    card('concept-card-034', 21, '条件の中の繰り返し', '状況ごとに、異なるループを選んで実行できます。どの分岐に入っても、必要な行動が完成するように書きます。'),
    card('concept-card-035', 22, '総復習', '定数、戻り値、条件分岐、真偽値、二重ループを組み合わせます。大きなプログラムも、一つずつの小さな判断と行動に分ければ読めます。'),
  ]

  const missionGuides = {
    0: guide('はじめてのプログラムを分けて見よう', ['concept-card-001', 'concept-card-002', 'concept-card-003', 'concept-card-004']),
    1: guide('新しいメソッド：動く', ['concept-card-005']),
    2: guide('プログラムは上から順番に進む', ['concept-card-006']),
    3: guide('true と false を名前に保存しよう', ['concept-card-007', 'concept-card-008', 'concept-card-009', 'concept-card-010', 'concept-card-011']),
    4: guide('看板の値で最初の if を動かそう', ['concept-card-012', 'concept-card-013', 'concept-card-014']),
    5: guide('新しい分岐：else', ['concept-card-015']),
    6: guide('戻り値をその場で比べる', ['concept-card-016']),
    7: guide('二つの条件を同時に調べる', ['concept-card-017']),
    8: guide('どちらか一方なら正しい', ['concept-card-018']),
    9: guide('true / false を返すメソッド', ['concept-card-019']),
    10: guide('三つ以上の道を順番に調べる', ['concept-card-020']),
    11: guide('同じ処理を繰り返す for ループ', ['concept-card-021']),
    12: guide('回数にも名前をつけられる', ['concept-card-022']),
    13: guide('条件が正しい間つづける while', ['concept-card-023']),
    14: guide('止まらない条件ループを体験しよう', ['concept-card-024', 'concept-card-025', 'concept-card-026', 'concept-card-027']),
    15: guide('ループの中でも判断できる', ['concept-card-028']),
    16: guide('条件がループを始める', ['concept-card-029']),
    17: guide('ループの中にループを入れる', ['concept-card-030']),
    18: guide('一回の繰り返しに複数の行動', ['concept-card-031']),
    19: guide('優先順位のある判断', ['concept-card-032']),
    20: guide('値をあとから変える let', ['concept-card-033']),
    21: guide('分岐ごとに別のループ', ['concept-card-034']),
    22: guide('今までの仕組みを組み合わせる', ['concept-card-035']),
  }

  const cardsById = Object.freeze(Object.fromEntries(cardList.map(item => [item.id, item])))
  const frozenGuides = Object.freeze(Object.fromEntries(
    Object.entries(missionGuides).map(([missionId, missionGuide]) => [missionId, Object.freeze(missionGuide)]),
  ))

  function tooltip (text, reading, extraClass) {
    return '<span class="glossary-token ' + (extraClass || '') + '" tabindex="0" role="button" data-tooltip="' +
      text + '（' + reading + '）">' + text + '</span>'
  }

  function card (id, missionId, titleHtml, bodyHtml) {
    return Object.freeze({ id, missionId, titleHtml, bodyHtml })
  }

  function guide (title, cardIds) {
    return { title, cardIds: Object.freeze(cardIds.slice()) }
  }

  function getCard (id) {
    return cardsById[id] || null
  }

  function getMissionGuide (missionId) {
    const missionGuide = frozenGuides[missionId]
    if (!missionGuide) return null
    return {
      title: missionGuide.title,
      cardIds: missionGuide.cardIds.slice(),
      cards: missionGuide.cardIds.map(getCard),
    }
  }

  function allCards () {
    return cardList.slice()
  }

  return Object.freeze({
    cardsById,
    missionGuides: frozenGuides,
    getCard,
    getMissionGuide,
    allCards,
  })
})
