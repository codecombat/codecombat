(function () {
  'use strict'

  const guides = {
    0: {
      title: 'はじめてのプログラムを分けて見よう',
      cards: [
        ['<code>hero</code> はオブジェクト', 'オブジェクトは、プログラムの中に存在して、世界に働きかけられるものです。<code>hero</code> は主人公そのものを表します。'],
        ['<code>.say</code> はメソッド', 'メソッドは、そのオブジェクトにしてほしい行動です。<code>hero</code> のあとに点 <code>.</code> とメソッド名を書くと、主人公にどの命令を実行してほしいか伝えられます。'],
        ['<code>(message)</code> はパラメーター', '丸いかっこの中には、行動を詳しく指定する情報を入れます。<code>hero.say(message)</code> では、主人公が言う言葉を指定します。'],
        ['<code>"Hello Yuzu"</code> は文字列リテラル', 'ふつう、ローマ字はプログラムの命令を書くために使います。でも <code>" "</code> の中に入れると、主人公の世界で使う「文字そのもの」になります。これは文字列という値です。'],
      ],
    },
    1: {
      title: '新しいメソッド：動く',
      cards: [
        ['<code>hero.move(direction)</code>', '<code>move</code> は動くメソッドです。パラメーター <code>direction</code> に <code>"left"</code> や <code>"right"</code> を渡して、動く方向を指定します。'],
      ],
    },
    2: {
      title: 'プログラムは上から順番に進む',
      cards: [
        ['実行する順番', 'JavaScript は、上の行から下の行へ、一つの命令が終わってから次の命令を実行します。順番を変えると、主人公の動きも変わります。'],
      ],
    },
    3: {
      title: '看板の値で最初の if を動かそう',
      cards: [
        ['<code>hero.readSign()</code> の戻り値', 'メソッドは行動するだけでなく、結果の値を返すことがあります。<code>readSign()</code> は、看板に書かれた <code>"right"</code> や <code>"left"</code> を返します。'],
        ['<code>if (条件) { ... }</code>', '<code>if</code> は条件分岐です。丸いかっこの条件が正しいときだけ、波かっこ <code>{ }</code> の中を実行します。'],
        ['<code>===</code> は比較', '<code>direction === "right"</code> のように、左と右の値が同じかを調べます。値を入れる <code>=</code> とは役割が違います。'],
      ],
    },
    4: {
      title: '新しい分岐：else',
      cards: [['<code>else</code>', '<code>if</code> の条件が正しくなかった場合に、代わりに実行する道です。<code>if</code> と <code>else</code> のどちらか一方だけが動きます。']],
    },
    5: {
      title: '戻り値をその場で比べる',
      cards: [['<code>hero.look(direction)</code>', 'となりのマスを調べて、<code>"gem"</code> などの文字列を戻り値として返します。その値を <code>===</code> で直接比較できます。']],
    },
    6: {
      title: '二つの条件を同時に調べる',
      cards: [['<code>&&</code> と <code>!==</code>', '<code>&&</code> は左右の条件が両方とも正しいときだけ正しくなります。<code>!==</code> は「同じではない」を表す比較です。']],
    },
    7: {
      title: 'どちらか一方なら正しい',
      cards: [['<code>||</code>', '<code>||</code> は、左右の条件のどちらか一方でも正しければ、全体を正しいと判断します。']],
    },
    8: {
      title: 'true / false を返すメソッド',
      cards: [['<code>hero.hasKey()</code>', 'カギを持っていれば <code>true</code>、持っていなければ <code>false</code> を返します。この二つは真偽値と呼ばれ、<code>if</code> の条件にそのまま使えます。']],
    },
    9: {
      title: '三つ以上の道を順番に調べる',
      cards: [['<code>else if</code>', '最初の <code>if</code> が正しくなかったとき、次の条件を調べます。最後の <code>else</code> は、それまでのどの条件にも当てはまらない場合です。']],
    },
    10: {
      title: '同じ処理を繰り返す for ループ',
      cards: [['<code>for (let i = 0; i &lt; 6; i++)</code>', '<code>let i = 0</code> で数え始め、<code>i &lt; 6</code> の間だけ繰り返し、<code>i++</code> で毎回 1 増やします。波かっこの中が繰り返す処理です。']],
    },
    11: {
      title: '回数にも名前をつけられる',
      cards: [['<code>const steps = 5</code>', '数字の値にも名前をつけられます。意味のある名前を使うと、あとで回数を変えたり、コードを読んだりしやすくなります。']],
    },
    12: {
      title: '条件が正しい間つづける while',
      cards: [['<code>while (条件) { ... }</code>', '回数を先に決めず、条件が正しい間ずっと繰り返します。毎回、条件をもう一度確認してから次の繰り返しへ進みます。']],
    },
    13: {
      title: 'ループの中でも判断できる',
      cards: [['<code>while</code> の中の <code>if</code>', '繰り返すたびに状況を調べ、行動を変えられます。先頭の <code>!</code> は真偽値を反対にして、「まだゴールではない間」を表します。']],
    },
    14: {
      title: '条件がループを始める',
      cards: [['<code>if</code> の中の <code>for</code>', 'まず距離が 0 より大きいかを <code>&gt;</code> で比較し、必要な場合だけループを開始します。定数をループの回数として再利用できます。']],
    },
    15: {
      title: 'ループの中にループを入れる',
      cards: [['二重ループ', '外側のループが段を数え、内側のループが一つの段の移動を繰り返します。<code>条件 ? 値1 : 値2</code> は、条件によって使う値を選ぶ短い書き方です。']],
    },
    16: {
      title: '一回の繰り返しに複数の行動',
      cards: [['ループの波かっこ', '波かっこの中には複数の命令を書けます。中の命令を上から順番に全部終えてから、次の繰り返しへ進みます。']],
    },
    17: {
      title: '優先順位のある判断',
      cards: [['while + if / else if / else', '毎回まず右を調べ、無理なら上、どちらも無理なら左という順番で判断します。先に正しくなった分岐だけが実行されます。']],
    },
    18: {
      title: '値をあとから変える let',
      cards: [['<code>let</code>、代入、<code>%</code>', '<code>let</code> で作った変数は、あとから別の値を代入できます。<code>%</code> は割り算の余りを求め、偶数と奇数を見分けるために使えます。']],
    },
    19: {
      title: '分岐ごとに別のループ',
      cards: [['条件の中の繰り返し', '状況ごとに、異なるループを選んで実行できます。どの分岐に入っても、必要な行動が完成するように書きます。']],
    },
    20: {
      title: '今までの仕組みを組み合わせる',
      cards: [['総復習', '定数、戻り値、条件分岐、真偽値、二重ループを組み合わせます。大きなプログラムも、一つずつの小さな判断と行動に分ければ読めます。']],
    },
  }

  const readings = {
    条件分岐: 'じょうけんぶんき',
    文字列: 'もじれつ',
    真偽値: 'しんぎち',
    優先順位: 'ゆうせんじゅんい',
    再利用: 'さいりよう',
    主人公: 'しゅじんこう',
    存在: 'そんざい',
    行動: 'こうどう',
    世界: 'せかい',
    命令: 'めいれい',
    実行: 'じっこう',
    方法: 'ほうほう',
    指定: 'してい',
    情報: 'じょうほう',
    言葉: 'ことば',
    表示: 'ひょうじ',
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
    総復習: 'そうふくしゅう',
    経験値: 'けいけんち',
    宝石: 'ほうせき',
    看板: 'かんばん',
    方向: 'ほうこう',
  }
  const readingWords = Object.keys(readings).sort((a, b) => b.length - a.length)

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

  function bindTokens (root) {
    root.querySelectorAll('.reading-token:not([data-reading-bound])').forEach(element => {
      element.dataset.readingBound = 'true'
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
    bindTokens(root)
  }

  function renderGuide () {
    const missionId = currentMissionId()
    const guide = guides[missionId]
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
      guide.cards.map(card => '<article><h4>' + card[0] + '</h4><p>' + card[1] + '</p></article>').join(''),
      '</div>',
    ].join('')

    window.setTimeout(() => {
      annotateText(section, false)
      annotateText(document.getElementById('mission-instructions'), false)
      annotateText(document.getElementById('mission-story'), false)
      annotateText(document.getElementById('mission-concept'), false)
      annotateText(document.getElementById('reference-panel'), true)
    }, 0)
  }

  function init () {
    document.addEventListener('jsquest:missionloaded', renderGuide)
    const reference = document.getElementById('reference-panel')
    if (reference) {
      new MutationObserver(() => window.setTimeout(() => annotateText(reference, true), 0))
        .observe(reference, { childList: true, subtree: true })
    }
    renderGuide()
  }

  if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', init)
  else init()
})()