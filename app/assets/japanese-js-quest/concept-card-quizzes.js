(function (root, factory) {
  const api = factory()
  if (typeof module === 'object' && module.exports) module.exports = api
  else root.JSQuestConceptCardQuizzes = api
})(typeof self !== 'undefined' ? self : this, function () {
  'use strict'

  function question (prompt, answer, wrongChoices) {
    return Object.freeze({
      prompt,
      answer,
      choices: Object.freeze([answer, ...wrongChoices])
    })
  }

  const quizzes = Object.freeze({
    'concept-card-001': [
      question('hero は何を表しますか？', '主人公そのもの', ['文字の色', 'ブラウザーのボタン']),
      question('オブジェクトは何ができますか？', 'プログラムの世界に働きかける', ['必ず数字になる', 'コメントだけを書く'])
    ],
    'concept-card-002': [
      question('メソッドは何を表しますか？', 'オブジェクトにしてほしい行動', ['保存した画像', 'ステージ番号']),
      question('hero のあとでメソッドを書く前に使う記号は？', '点 .', ['かけ算 ×', '疑問符 ?'])
    ],
    'concept-card-003': [
      question('丸いかっこの中には何を入れますか？', '行動を詳しく指定する情報', ['ミッションの色', 'ブラウザーの履歴']),
      question('hero.say(message) の message は何ですか？', '主人公が言う言葉', ['主人公のレベル', '地図の大きさ'])
    ],
    'concept-card-004': [
      question('" " の中に書いたものは何になりますか？', '文字列の値', ['新しいメソッド', 'コメント']),
      question('文字列の中の Hello Yuzu はどう扱われますか？', '文字そのもの', ['JavaScript の命令', '変数の名前だけ'])
    ],
    'concept-card-005': [
      question('hero.move(direction) は何をしますか？', '主人公を動かす', ['主人公に話させる', 'ページを再読み込みする']),
      question('direction に入れられる例は？', '"left"', ['"purple"', '"quiz"'])
    ],
    'concept-card-006': [
      question('JavaScript は基本的にどの順番で実行しますか？', '上の行から下の行', ['下の行から上の行', '毎回ランダム'])
    ],
    'concept-card-007': [
      question('ブール値が持てる値は？', 'true と false', ['red と blue', '1 と 100 だけ']),
      question('false は何を表しますか？', '正しくない', ['必ず停止する', '文字列'])
    ],
    'concept-card-008': [
      question('const は何をしますか？', '値に名前をつけて固定する', ['画面を閉じる', 'コメントを削除する']),
      question('固定した値はどうできますか？', '同じ名前で再利用できる', ['一度も使えない', '画像に変わる'])
    ],
    'concept-card-009': [
      question('const alwaysTrue = true; の = は何ですか？', '右の値を左の名前に入れる代入', ['左右が同じか調べる比較', 'コメントの開始']),
      question('同じか調べる記号はどれですか？', '===', ['=', '//'])
    ],
    'concept-card-010': [
      question('定数の名前はどう書きますか？', '空白なしのローマ字', ['絵文字だけ', '必ず日本語の漢字']),
      question('alwaysTrue の意味に近いものは？', 'いつも true', ['右へ動く', '宝石を数える'])
    ],
    'concept-card-011': [
      question('hero.isTrue(...) が受け取る値は？', 'ブール値', ['画像ファイル', '地図全体']),
      question('false を渡すとヒーローは何と言いますか？', '違いますよ。', ['正しいです。', '右へ進みます。'])
    ],
    'concept-card-012': [
      question('hero.readSign() は何を返しますか？', '看板に書かれた値', ['主人公の色', 'ページのURL']),
      question('メソッドは行動以外に何ができますか？', '結果の値を返す', ['必ずループを作る', 'CSSを消す'])
    ],
    'concept-card-013': [
      question('if の中はいつ実行されますか？', '条件が正しいとき', ['条件が正しくないときだけ', 'ページを開いた瞬間だけ']),
      question('if の実行内容を書く場所は？', '波かっこ { } の中', ['コメントの外側だけ', 'URLの後ろ'])
    ],
    'concept-card-014': [
      question('=== は何を調べますか？', '左右の値が同じか', ['値に名前をつける', 'ページを更新する']),
      question('= と === の役割は同じですか？', '違う', ['同じ', 'どちらもコメント'])
    ],
    'concept-card-015': [
      question('else はいつ実行されますか？', 'if の条件が正しくなかったとき', ['if が正しいときも必ず', 'コードを書く前'])
    ],
    'concept-card-016': [
      question('hero.look(direction) は何をしますか？', 'となりのマスを調べる', ['主人公を変身させる', 'ページを保存する']),
      question('hero.look(...) の戻り値の例は？', '"gem"', ['Ctrl+F5', '紫色'])
    ],
    'concept-card-017': [
      question('&& が true になるのはいつですか？', '左右の条件が両方とも正しいとき', ['どちらか一方だけ正しいとき', '両方とも正しくないとき']),
      question('!== は何を表しますか？', '同じではない', ['同じである', '値を固定する'])
    ],
    'concept-card-018': [
      question('|| が true になるのはいつですか？', 'どちらか一方でも正しいとき', ['両方とも必ず正しいときだけ', '数字が0のときだけ'])
    ],
    'concept-card-019': [
      question('hero.hasKey() は何を返しますか？', 'true または false', ['必ず "key"', '主人公の名前']),
      question('カギを持っていない場合の戻り値は？', 'false', ['true', 'undefined だけ'])
    ],
    'concept-card-020': [
      question('else if はいつ条件を調べますか？', '前の if が正しくなかったとき', ['前の if が正しかったあと', '必ず最初に']),
      question('最後の else はどの場合ですか？', '前の条件のどれにも当てはまらない場合', ['最初の条件だけ', 'コメントがある場合'])
    ],
    'concept-card-021': [
      question('let i = 0 は何をしますか？', 'i を 0 から数え始める', ['i を削除する', '6回すべてを一行に書く']),
      question('i < 6 の間はどうなりますか？', 'ループを繰り返す', ['ページを閉じる', 'コメントだけ実行する']),
      question('i++ は何をしますか？', 'i を毎回 1 増やす', ['i を true にする', 'i を文字列にする'])
    ],
    'concept-card-022': [
      question('数字に意味のある名前をつける利点は？', '回数を変えたりコードを読んだりしやすい', ['必ず処理が速くなる', 'コメントが不要になる'])
    ],
    'concept-card-023': [
      question('while はいつ繰り返しますか？', '条件が正しい間', ['最初の一回だけ', '条件が正しくない間だけ']),
      question('while は次の周回前に何をしますか？', '条件をもう一度確認する', ['ブラウザーを閉じる', '変数を全部削除する'])
    ],
    'concept-card-024': [
      question('条件ループは何を使って続くか決めますか？', 'true または false になる条件', ['背景色', 'カードの枚数']),
      question('条件を確認するタイミングは？', '毎回、次の周回へ進む前', ['最後に一度だけ', '一度も確認しない'])
    ],
    'concept-card-025': [
      question('while (true) が終わらない理由は？', '条件がずっと true だから', ['波かっこがあるから', '文字が白いから']),
      question('無限ループでは次の命令へ進めますか？', '進めない', ['必ず進める', '色によって変わる']),
      question('無限ループの危険は？', 'コンピューターの力を使い続ける', ['宝石が増えすぎる', 'コメントが赤くなる'])
    ],
    'concept-card-026': [
      question('プログラム自身が止まれないときはどうしますか？', '外側からシステムを再起動する', ['同じ命令を追加する', '文字列を長くする']),
      question('このゲームで再読み込みする方法は？', '丸い矢印または Ctrl+F5', ['Ctrl+Cだけ', 'hero.move("reload")'])
    ],
    'concept-card-027': [
      question('この特別なミッションはいつクリア記録を保存しますか？', '無限ループを始める前', ['無限ループが自然に終わった後', '一度も保存しない'])
    ],
    'concept-card-028': [
      question('while の中に if を入れると何ができますか？', '繰り返すたびに行動を変える', ['条件を使えなくする', '一回しか動けなくする']),
      question('!hero.isAtGoal() の ! は何をしますか？', 'true と false を反対にする', ['数字を1増やす', '文字列を作る'])
    ],
    'concept-card-029': [
      question('このカードではループの前に何を確認しますか？', '距離が 0 より大きいか', ['主人公が紫色か', 'コメントが二つあるか']),
      question('定数 distance はどこで再利用できますか？', 'ループの回数', ['CSSの色だけ', 'ブラウザーのタイトルだけ'])
    ],
    'concept-card-030': [
      question('二重ループの外側は何を数えますか？', '段', ['文字列の引用符', 'ブラウザーのタブ']),
      question('内側のループは何を繰り返しますか？', '一つの段の移動', ['ミッションの再読み込み', 'カードの保存']),
      question('条件 ? 値1 : 値2 は何をしますか？', '条件で使う値を選ぶ', ['必ず二つの値を足す', 'コメントを消す'])
    ],
    'concept-card-031': [
      question('ループの波かっこの中に複数の命令があるときは？', '全部を上から順番に実行してから次の周回へ進む', ['一つだけランダムに実行する', '何も実行しない'])
    ],
    'concept-card-032': [
      question('分岐を調べる順番は？', '右、上、左の順', ['左、右、下の順', '毎回ランダム']),
      question('複数の条件があるとき実行される分岐は？', '先に正しくなった分岐', ['すべての分岐', '最後の分岐だけ'])
    ],
    'concept-card-033': [
      question('let で作った変数はどうできますか？', 'あとから別の値を代入できる', ['絶対に変更できない', '必ず文字列になる']),
      question('% は何を求めますか？', '割り算の余り', ['足し算の合計', '文字列の長さ'])
    ],
    'concept-card-034': [
      question('条件の中にループを書くと何ができますか？', '状況ごとに異なる繰り返しを選ぶ', ['条件を無視する', '一度も動かなくする']),
      question('どの分岐でも必要なことは？', '必要な行動が完成すること', ['同じコメントを書くこと', '必ず同じ方向へ進むこと'])
    ],
    'concept-card-035': [
      question('最終ミッションでは何を組み合わせますか？', '定数、戻り値、条件、真偽値、二重ループ', ['色と画像だけ', 'コメントだけ']),
      question('大きなプログラムを読むコツは？', '小さな判断と行動に分ける', ['全部を一度に暗記する', '順番を無視する']),
      question('総復習の目的は？', '今までの概念を一緒に使う', ['新しい言語をインストールする', 'ブラウザーを閉じる'])
    ]
  })

  function getQuiz (cardId) {
    return quizzes[cardId] || null
  }

  function allQuizzes () {
    return quizzes
  }

  return Object.freeze({
    getQuiz,
    allQuizzes
  })
})
