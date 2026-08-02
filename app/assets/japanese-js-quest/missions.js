(function (root, factory) {
  const missions = factory()
  if (typeof module === 'object' && module.exports) module.exports = missions
  else root.JSQuestMissions = missions
})(typeof self !== 'undefined' ? self : this, function () {
  'use strict'

  const syntax = (type, message) => ({ type, message })

  return [
    {
      id: 1,
      title: 'はじめの一歩',
      concept: '関数を呼ぶ・文字を渡す',
      story: '宝石を取ってから、光るゴールまで歩こう。',
      instructions: [
        '`hero.move("right")` のように、進む方向を文字で渡します。',
        'まず左の宝石を取り、そのあと右へ進みましょう。'
      ],
      api: ['hero.move("right")', 'hero.move("left")'],
      starterCode: '// 左の宝石を取ろう\nhero.move("left");\n\n// つぎにゴールまで右へ進もう\n',
      hints: [
        '`hero.move("right");` を1行書くと、右へ1マス進みます。',
        '左へ1回、そのあと右へ4回進みます。'
      ],
      solution: 'hero.move("left");\nhero.move("right");\nhero.move("right");\nhero.move("right");\nhero.move("right");',
      variants: [{ map: ['########', '#*H..G.#', '########'], sign: null }],
      requirements: {
        state: { goal: true, minGems: 1, maxMoves: 5 },
        syntax: [syntax('moveParameter', '方向を引数にした hero.move(...) を使いましょう。')]
      }
    },
    {
      id: 2,
      title: '曲がり道',
      concept: '命令を順番に実行する',
      story: '上へ進んでから右へ曲がり、旗までたどり着こう。',
      instructions: [
        'JavaScriptは上の行から順番に命令を実行します。',
        '`up` と `right` を正しい順番で使いましょう。'
      ],
      api: ['hero.move("up")', 'hero.move("right")'],
      starterCode: '// 上へ2マス、そのあと右へ3マス\n',
      hints: ['同じ命令を何回か書いても大丈夫です。'],
      solution: 'hero.move("up");\nhero.move("up");\nhero.move("right");\nhero.move("right");\nhero.move("right");',
      variants: [{ map: ['#######', '#...G.#', '#.....#', '#H....#', '#######'], sign: null }],
      requirements: {
        state: { goal: true, maxMoves: 5 },
        syntax: [syntax('moveParameter', 'hero.move(...) に方向を渡しましょう。')]
      }
    },
    {
      id: 3,
      title: '最初の if',
      concept: '条件が正しいときだけ動く',
      story: '看板は、ゴールが右か左かを教えてくれます。',
      instructions: [
        '`hero.readSign()` で看板の文字を読みます。',
        '`if (条件) { ... }` の中は、条件が正しいときだけ実行されます。'
      ],
      api: ['hero.readSign()', 'hero.move(direction)'],
      starterCode: 'const direction = hero.readSign();\n\nif (direction === "right") {\n  // 右へ3マス\n}\n\nif (direction === "left") {\n  // 左へ3マス\n}\n',
      hints: ['`===` は、左と右が同じかを調べます。'],
      solution: 'const direction = hero.readSign();\n\nif (direction === "right") {\n  hero.move("right");\n  hero.move("right");\n  hero.move("right");\n}\n\nif (direction === "left") {\n  hero.move("left");\n  hero.move("left");\n  hero.move("left");\n}',
      variants: [
        { map: ['########', '#H..G..#', '########'], sign: 'right' },
        { map: ['########', '#..G..H#', '########'], sign: 'left' }
      ],
      requirements: {
        state: { goal: true, maxMoves: 3 },
        syntax: [
          syntax('if', 'if を使って条件を作りましょう。'),
          syntax('comparison', '=== などで値を比べましょう。'),
          syntax('readSign', 'hero.readSign() で看板を読みましょう。')
        ]
      }
    },
    {
      id: 4,
      title: 'if と else',
      concept: '二つの道から選ぶ',
      story: '看板が up なら上へ。それ以外なら右へ進もう。',
      instructions: [
        '`else` は、if の条件が正しくなかったときに実行されます。'
      ],
      api: ['hero.readSign()', 'hero.move(direction)'],
      starterCode: 'const direction = hero.readSign();\n\nif (direction === "up") {\n  // 上へ2マス\n} else {\n  // 右へ2マス\n}\n',
      hints: ['if と else のどちらか一方だけが実行されます。'],
      solution: 'const direction = hero.readSign();\n\nif (direction === "up") {\n  hero.move("up");\n  hero.move("up");\n} else {\n  hero.move("right");\n  hero.move("right");\n}',
      variants: [
        { map: ['#######', '#..G..#', '#.....#', '#..H..#', '#######'], sign: 'up' },
        { map: ['#######', '#.....#', '#.....#', '#..H.G#', '#######'], sign: 'right' }
      ],
      requirements: {
        state: { goal: true, maxMoves: 2 },
        syntax: [syntax('if', 'if を使いましょう。'), syntax('else', 'else を使いましょう。'), syntax('readSign', '看板を読みましょう。')]
      }
    },
    {
      id: 5,
      title: 'となりを調べる',
      concept: '戻り値を比べる',
      story: '宝石がある方向にゴールがあります。',
      instructions: [
        '`hero.look("right")` は、右のマスの種類を文字で返します。',
        '返ってきた文字が `"gem"` かどうかを調べましょう。'
      ],
      api: ['hero.look(direction)', 'hero.move(direction)'],
      starterCode: 'if (hero.look("right") === "gem") {\n  // 右へ2マス\n} else {\n  // 上へ2マス\n}\n',
      hints: ['右に宝石がなければ、宝石は上にあります。'],
      solution: 'if (hero.look("right") === "gem") {\n  hero.move("right");\n  hero.move("right");\n} else {\n  hero.move("up");\n  hero.move("up");\n}',
      variants: [
        { map: ['#######', '#.....#', '#.....#', '#H*G..#', '#######'], sign: null },
        { map: ['#######', '#G....#', '#*....#', '#H....#', '#######'], sign: null }
      ],
      requirements: {
        state: { goal: true, minGems: 1, maxMoves: 2 },
        syntax: [syntax('if', 'if を使いましょう。'), syntax('else', 'else を使いましょう。'), syntax('look', 'hero.look(...) でとなりを調べましょう。'), syntax('comparison', '調べた値を比較しましょう。')]
      }
    },
    {
      id: 6,
      title: '安全な道',
      concept: 'AND（&&）',
      story: '右へ進めて、しかもワナでないときだけ右へ行こう。',
      instructions: [
        '`&&` は「左の条件と右の条件が両方とも正しい」という意味です。'
      ],
      api: ['hero.canMove(direction)', 'hero.look(direction)'],
      starterCode: 'const rightIsSafe = hero.canMove("right") &&\n  hero.look("right") !== "trap";\n\nif (rightIsSafe) {\n  // 右へ2マス\n} else {\n  // 上へ2マス\n}\n',
      hints: ['`!==` は「同じではない」という意味です。'],
      solution: 'const rightIsSafe = hero.canMove("right") &&\n  hero.look("right") !== "trap";\n\nif (rightIsSafe) {\n  hero.move("right");\n  hero.move("right");\n} else {\n  hero.move("up");\n  hero.move("up");\n}',
      variants: [
        { map: ['########', '#......#', '#..H.G.#', '#......#', '########'], sign: null },
        { map: ['########', '#..G...#', '#......#', '#..HT..#', '########'], sign: null }
      ],
      requirements: {
        state: { goal: true, noTrap: true, maxMoves: 2 },
        syntax: [syntax('logicalAnd', '&& を使って二つの条件をつなぎましょう。'), syntax('canMove', 'hero.canMove(...) を使いましょう。'), syntax('look', 'hero.look(...) を使いましょう。')]
      }
    },
    {
      id: 7,
      title: '二つの合言葉',
      concept: 'OR（||）',
      story: 'left と west は、どちらも左という意味です。',
      instructions: [
        '`||` は「どちらか一方が正しい」という意味です。'
      ],
      api: ['hero.readSign()', 'hero.move(direction)'],
      starterCode: 'const word = hero.readSign();\n\nif (word === "left" || word === "west") {\n  // 左へ3マス\n} else {\n  // 右へ3マス\n}\n',
      hints: ['right と east のときは else 側へ進みます。'],
      solution: 'const word = hero.readSign();\n\nif (word === "left" || word === "west") {\n  hero.move("left");\n  hero.move("left");\n  hero.move("left");\n} else {\n  hero.move("right");\n  hero.move("right");\n  hero.move("right");\n}',
      variants: [
        { map: ['#########', '#G..H...#', '#########'], sign: 'left' },
        { map: ['#########', '#G..H...#', '#########'], sign: 'west' },
        { map: ['#########', '#...H..G#', '#########'], sign: 'right' },
        { map: ['#########', '#...H..G#', '#########'], sign: 'east' }
      ],
      requirements: {
        state: { goal: true, maxMoves: 3 },
        syntax: [syntax('logicalOr', '|| を使って二つの言葉をまとめましょう。'), syntax('if', 'if を使いましょう。'), syntax('else', 'else を使いましょう。')]
      }
    },
    {
      id: 8,
      title: 'カギとドア',
      concept: '条件を二段階で確認する',
      story: '看板の方向へカギを取りに行き、カギがあればドアを開けよう。',
      instructions: [
        '`hero.hasKey()` は、カギを持っていると true を返します。'
      ],
      api: ['hero.readSign()', 'hero.hasKey()', 'hero.move(direction)'],
      starterCode: 'const keyDirection = hero.readSign();\n\nif (keyDirection === "left") {\n  // 左へ3マス行き、中央へ戻る\n} else {\n  // 右へ3マス行き、中央へ戻る\n}\n\nif (hero.hasKey()) {\n  // 上へ2マス進む\n}\n',
      hints: ['カギを取ると、ドアのマスへ進めるようになります。'],
      solution: 'const keyDirection = hero.readSign();\n\nif (keyDirection === "left") {\n  hero.move("left");\n  hero.move("left");\n  hero.move("left");\n  hero.move("right");\n  hero.move("right");\n  hero.move("right");\n} else {\n  hero.move("right");\n  hero.move("right");\n  hero.move("right");\n  hero.move("left");\n  hero.move("left");\n  hero.move("left");\n}\n\nif (hero.hasKey()) {\n  hero.move("up");\n  hero.move("up");\n}',
      variants: [
        { map: ['#########', '#...G...#', '#...D...#', '#K..H...#', '#########'], sign: 'left' },
        { map: ['#########', '#...G...#', '#...D...#', '#...H..K#', '#########'], sign: 'right' }
      ],
      requirements: {
        state: { goal: true, key: true, maxMoves: 8 },
        syntax: [syntax('if', 'if を使いましょう。'), syntax('else', 'else を使いましょう。'), syntax('hasKey', 'hero.hasKey() でカギを確認しましょう。')]
      }
    },
    {
      id: 9,
      title: '三つの分かれ道',
      concept: 'if / else if / else',
      story: '看板は up、left、right のどれかです。',
      instructions: [
        '`else if` を使うと、三つ以上の選択肢を順番に調べられます。'
      ],
      api: ['hero.readSign()', 'hero.move(direction)'],
      starterCode: 'const direction = hero.readSign();\n\nif (direction === "up") {\n  // 上へ2マス\n} else if (direction === "left") {\n  // 左へ2マス\n} else {\n  // 右へ2マス\n}\n',
      hints: ['最後の else は right の場合です。'],
      solution: 'const direction = hero.readSign();\n\nif (direction === "up") {\n  hero.move("up");\n  hero.move("up");\n} else if (direction === "left") {\n  hero.move("left");\n  hero.move("left");\n} else {\n  hero.move("right");\n  hero.move("right");\n}',
      variants: [
        { map: ['#######', '#..G..#', '#.....#', '#..H..#', '#######'], sign: 'up' },
        { map: ['#######', '#.....#', '#.....#', '#G.H..#', '#######'], sign: 'left' },
        { map: ['#######', '#.....#', '#.....#', '#..H.G#', '#######'], sign: 'right' }
      ],
      requirements: {
        state: { goal: true, maxMoves: 2 },
        syntax: [syntax('if', 'if を使いましょう。'), syntax('elseIf', 'else if を使いましょう。'), syntax('else', 'else を使いましょう。')]
      }
    },
    {
      id: 10,
      title: 'はじめてのループ',
      concept: 'for で同じ命令を繰り返す',
      story: '長い廊下を、短いコードで進もう。',
      instructions: [
        '`for` は、決めた回数だけ同じ処理を繰り返します。',
        '`i++` は、i を1ずつ増やします。'
      ],
      api: ['hero.move("right")'],
      starterCode: 'for (let i = 0; i < 6; i++) {\n  // 右へ1マス\n}\n',
      hints: ['ループの中には hero.move("right"); を1回だけ書きます。'],
      solution: 'for (let i = 0; i < 6; i++) {\n  hero.move("right");\n}',
      variants: [{ map: ['##########', '#H.....G.#', '##########'], sign: null }],
      requirements: {
        state: { goal: true, maxMoves: 6 },
        syntax: [syntax('forLoop', 'for ループを使いましょう。'), syntax('variable', 'let でカウンターを作りましょう。')]
      }
    },
    {
      id: 11,
      title: '宝石の廊下',
      concept: '回数を変数に入れる',
      story: '4個の宝石を集めて、ゴールへ進もう。',
      instructions: [
        '繰り返す回数を `const steps = 5;` のように名前で保存できます。'
      ],
      api: ['hero.move("right")'],
      starterCode: 'const steps = 5;\n\nfor (let i = 0; i < steps; i++) {\n  // 右へ進む\n}\n',
      hints: ['5回進むと、4個の宝石を通ってゴールに着きます。'],
      solution: 'const steps = 5;\n\nfor (let i = 0; i < steps; i++) {\n  hero.move("right");\n}',
      variants: [{ map: ['##########', '#H****G..#', '##########'], sign: null }],
      requirements: {
        state: { goal: true, minGems: 4, maxMoves: 5 },
        syntax: [syntax('forLoop', 'for ループを使いましょう。'), syntax('variable', 'const または let で変数を作りましょう。')]
      }
    },
    {
      id: 12,
      title: '壁まで進む',
      concept: 'while で条件が正しい間くり返す',
      story: '右へ進める間は進み、壁に着いたら上のゴールへ。',
      instructions: [
        '`while (条件) { ... }` は、条件が正しい間ずっと繰り返します。'
      ],
      api: ['hero.canMove(direction)', 'hero.move(direction)'],
      starterCode: 'while (hero.canMove("right")) {\n  // 右へ進む\n}\n\n// 壁に着いたら上へ2マス\n',
      hints: ['while の外に、上へ進む命令を書きます。'],
      solution: 'while (hero.canMove("right")) {\n  hero.move("right");\n}\n\nhero.move("up");\nhero.move("up");',
      variants: [{ map: ['#########', '#....G###', '#.....###', '#H....###', '#########'], sign: null }],
      requirements: {
        state: { goal: true, maxMoves: 6 },
        syntax: [syntax('whileLoop', 'while ループを使いましょう。'), syntax('canMove', 'hero.canMove(...) を条件に使いましょう。')]
      }
    },
    {
      id: 13,
      title: 'ループの中の if',
      concept: '繰り返しながら危険を調べる',
      story: '敵が前にいたら上の道からよけよう。',
      instructions: [
        '毎回 `hero.look("right")` で前を確認します。',
        '敵でなければ、そのまま右へ進みます。'
      ],
      api: ['hero.isAtGoal()', 'hero.look(direction)', 'hero.move(direction)'],
      starterCode: 'while (!hero.isAtGoal()) {\n  if (hero.look("right") === "enemy") {\n    // 上へ行き、敵の向こうまで進み、下へ戻る\n  } else {\n    // 右へ1マス\n  }\n}\n',
      hints: ['敵をよけるときは up, right, right, down の順です。'],
      solution: 'while (!hero.isAtGoal()) {\n  if (hero.look("right") === "enemy") {\n    hero.move("up");\n    hero.move("right");\n    hero.move("right");\n    hero.move("down");\n  } else {\n    hero.move("right");\n  }\n}',
      variants: [{ map: ['###########', '#.........#', '#H..E...G.#', '###########'], sign: null }],
      requirements: {
        state: { goal: true, maxMoves: 9 },
        syntax: [syntax('whileLoop', 'while ループを使いましょう。'), syntax('if', 'ループの中で if を使いましょう。'), syntax('look', 'hero.look(...) で敵を調べましょう。'), syntax('isAtGoal', 'hero.isAtGoal() を終了条件に使いましょう。')]
      }
    },
    {
      id: 14,
      title: '看板の数だけ',
      concept: '条件がループを開始する',
      story: '看板に書かれた数だけ右へ進もう。',
      instructions: [
        '`hero.readSign()` は、このステージでは数を返します。',
        '数が0より大きいときだけループを実行します。'
      ],
      api: ['hero.readSign()', 'hero.move("right")'],
      starterCode: 'const distance = hero.readSign();\n\nif (distance > 0) {\n  for (let i = 0; i < distance; i++) {\n    // 右へ進む\n  }\n}\n',
      hints: ['ループの回数に固定の数字ではなく distance を使います。'],
      solution: 'const distance = hero.readSign();\n\nif (distance > 0) {\n  for (let i = 0; i < distance; i++) {\n    hero.move("right");\n  }\n}',
      variants: [
        { map: ['#########', '#H..G...#', '#########'], sign: 3 },
        { map: ['#########', '#H....G.#', '#########'], sign: 5 }
      ],
      requirements: {
        state: { goal: true, maxMoves: 5 },
        syntax: [syntax('if', 'if で距離を確認しましょう。'), syntax('forLoop', 'for ループを使いましょう。'), syntax('readSign', 'hero.readSign() の数を使いましょう。'), syntax('variable', '距離を変数に保存しましょう。')]
      }
    },
    {
      id: 15,
      title: '二重ループ',
      concept: 'ループの中にループを入れる',
      story: '2段の宝石畑を、蛇のように往復しよう。',
      instructions: [
        '外側のループは段を数えます。',
        '内側のループは、1段で3マス進みます。'
      ],
      api: ['hero.move(direction)'],
      starterCode: 'for (let row = 0; row < 2; row++) {\n  const direction = row === 0 ? "right" : "left";\n\n  for (let step = 0; step < 3; step++) {\n    // direction の方向へ進む\n  }\n\n  if (row === 0) {\n    // 次の段へ下りる\n  }\n}\n',
      hints: ['hero.move(direction); のように変数をそのまま引数にできます。'],
      solution: 'for (let row = 0; row < 2; row++) {\n  const direction = row === 0 ? "right" : "left";\n\n  for (let step = 0; step < 3; step++) {\n    hero.move(direction);\n  }\n\n  if (row === 0) {\n    hero.move("down");\n  }\n}',
      variants: [{ map: ['#######', '#H***.#', '#G***.#', '#######'], sign: null }],
      requirements: {
        state: { goal: true, minGems: 6, maxMoves: 7 },
        syntax: [syntax('nestedLoops', 'ループを二つ使いましょう。'), syntax('if', '段を下りる条件に if を使いましょう。'), syntax('variable', 'direction などの変数を使いましょう。')]
      }
    },
    {
      id: 16,
      title: '階段パターン',
      concept: '一つのループで複数の命令を繰り返す',
      story: '右、上、右、上……と進んで宝石を集めよう。',
      instructions: [
        'ループの中には、命令を何行でも書けます。'
      ],
      api: ['hero.move("right")', 'hero.move("up")'],
      starterCode: 'for (let i = 0; i < 3; i++) {\n  // 右へ1マス\n  // 上へ1マス\n}\n',
      hints: ['right と up を、同じループの中に1回ずつ書きます。'],
      solution: 'for (let i = 0; i < 3; i++) {\n  hero.move("right");\n  hero.move("up");\n}',
      variants: [{ map: ['#######', '#...G.#', '#...*.#', '#..*..#', '#H*...#', '#######'], sign: null }],
      requirements: {
        state: { goal: true, minGems: 3, maxMoves: 6 },
        syntax: [syntax('forLoop', 'for ループを使いましょう。')]
      }
    },
    {
      id: 17,
      title: '迷路の判断',
      concept: 'while と else if を組み合わせる',
      story: 'ゴールまで、右を優先し、右が無理なら上へ進もう。',
      instructions: [
        'ゴールに着くまで、毎回進める方向を調べます。'
      ],
      api: ['hero.isAtGoal()', 'hero.canMove(direction)', 'hero.move(direction)'],
      starterCode: 'while (!hero.isAtGoal()) {\n  if (hero.canMove("right")) {\n    // 右へ進む\n  } else if (hero.canMove("up")) {\n    // 上へ進む\n  } else {\n    // 左へ進む\n  }\n}\n',
      hints: ['この迷路では、else は予備の道です。'],
      solution: 'while (!hero.isAtGoal()) {\n  if (hero.canMove("right")) {\n    hero.move("right");\n  } else if (hero.canMove("up")) {\n    hero.move("up");\n  } else {\n    hero.move("left");\n  }\n}',
      variants: [{ map: ['#########', '#.....G##', '#..###.##', '#H.....##', '#########'], sign: null }],
      requirements: {
        state: { goal: true, maxMoves: 7 },
        syntax: [syntax('whileLoop', 'while ループを使いましょう。'), syntax('elseIf', 'else if を使いましょう。'), syntax('canMove', 'hero.canMove(...) で道を調べましょう。'), syntax('isAtGoal', 'ゴールをループの終了条件にしましょう。')]
      }
    },
    {
      id: 18,
      title: '三段の宝石畑',
      concept: '二重ループと条件',
      story: '3段を左右交互に進み、すべての宝石を集めよう。',
      instructions: [
        'row が偶数なら右、奇数なら左へ進みます。',
        '`row % 2` は、2で割った余りです。'
      ],
      api: ['hero.move(direction)'],
      starterCode: 'for (let row = 0; row < 3; row++) {\n  let direction;\n\n  if (row % 2 === 0) {\n    direction = "right";\n  } else {\n    direction = "left";\n  }\n\n  for (let step = 0; step < 3; step++) {\n    // direction の方向へ進む\n  }\n\n  if (row < 2) {\n    // 次の段へ下りる\n  }\n}\n',
      hints: ['偶数の段は0段目と2段目です。'],
      solution: 'for (let row = 0; row < 3; row++) {\n  let direction;\n\n  if (row % 2 === 0) {\n    direction = "right";\n  } else {\n    direction = "left";\n  }\n\n  for (let step = 0; step < 3; step++) {\n    hero.move(direction);\n  }\n\n  if (row < 2) {\n    hero.move("down");\n  }\n}',
      variants: [{ map: ['########', '#H***..#', '#***...#', '#***G..#', '########'], sign: null }],
      requirements: {
        state: { goal: true, minGems: 9, maxMoves: 11 },
        syntax: [syntax('nestedLoops', '二重ループを使いましょう。'), syntax('if', '方向を選ぶために if を使いましょう。'), syntax('else', '左右を分けるために else を使いましょう。')]
      }
    },
    {
      id: 19,
      title: 'ループの分かれ道',
      concept: '条件ごとに別のループを動かす',
      story: '看板の方向へ4マス進もう。ステージの形は毎回変わります。',
      instructions: [
        'if / else if / else の各場所に、4回のループを書きます。'
      ],
      api: ['hero.readSign()', 'hero.move(direction)'],
      starterCode: 'const direction = hero.readSign();\n\nif (direction === "up") {\n  for (let i = 0; i < 4; i++) {\n    // 上へ進む\n  }\n} else if (direction === "left") {\n  // 左へ4回のループ\n} else {\n  // 右へ4回のループ\n}\n',
      hints: ['三つの分岐のすべてに for ループが必要です。'],
      solution: 'const direction = hero.readSign();\n\nif (direction === "up") {\n  for (let i = 0; i < 4; i++) {\n    hero.move("up");\n  }\n} else if (direction === "left") {\n  for (let i = 0; i < 4; i++) {\n    hero.move("left");\n  }\n} else {\n  for (let i = 0; i < 4; i++) {\n    hero.move("right");\n  }\n}',
      variants: [
        { map: ['#########', '#...G...#', '#.......#', '#.......#', '#.......#', '#...H...#', '#########'], sign: 'up' },
        { map: ['#########', '#.......#', '#.......#', '#.G...H.#', '#.......#', '#.......#', '#########'], sign: 'left' },
        { map: ['#########', '#.......#', '#.......#', '#.H...G.#', '#.......#', '#.......#', '#########'], sign: 'right' }
      ],
      requirements: {
        state: { goal: true, maxMoves: 4 },
        syntax: [syntax('if', 'if を使いましょう。'), syntax('elseIf', 'else if を使いましょう。'), syntax('else', 'else を使いましょう。'), syntax('forLoop', 'for ループを使いましょう。'), syntax('readSign', '看板の方向を使いましょう。')]
      }
    },
    {
      id: 20,
      title: '最終ミッション：光の迷宮',
      concept: '関数・条件・二重ループの総復習',
      story: 'カギと11個の宝石を集め、4段の迷宮を攻略しよう。迷宮は左右反転することがあります。',
      instructions: [
        '看板で最初の方向を読み、段ごとに方向を反転します。',
        '最初の段を終えたら、カギを持っていることを確認してドアへ進みます。'
      ],
      api: ['hero.readSign()', 'hero.hasKey()', 'hero.move(direction)'],
      starterCode: 'const firstDirection = hero.readSign();\n\nfor (let row = 0; row < 4; row++) {\n  let direction;\n\n  if (firstDirection === "right") {\n    direction = row % 2 === 0 ? "right" : "left";\n  } else {\n    direction = row % 2 === 0 ? "left" : "right";\n  }\n\n  for (let step = 0; step < 3; step++) {\n    // direction の方向へ進む\n  }\n\n  if (row < 3) {\n    if (row === 0 && hero.hasKey()) {\n      // カギを持ってドアへ下りる\n    } else if (row > 0) {\n      // 次の段へ下りる\n    }\n  }\n}\n',
      hints: [
        '横へは各段3マス、下へは全部で3マス進みます。',
        'hero.move(direction); を内側のループに書きます。'
      ],
      solution: 'const firstDirection = hero.readSign();\n\nfor (let row = 0; row < 4; row++) {\n  let direction;\n\n  if (firstDirection === "right") {\n    direction = row % 2 === 0 ? "right" : "left";\n  } else {\n    direction = row % 2 === 0 ? "left" : "right";\n  }\n\n  for (let step = 0; step < 3; step++) {\n    hero.move(direction);\n  }\n\n  if (row < 3) {\n    if (row === 0 && hero.hasKey()) {\n      hero.move("down");\n    } else if (row > 0) {\n      hero.move("down");\n    }\n  }\n}',
      variants: [
        { map: ['########', '#H**K..#', '#***D..#', '#***...#', '#G***..#', '########'], sign: 'right' },
        { map: ['########', '#..K**H#', '#..D***#', '#...***#', '#..***G#', '########'], sign: 'left' }
      ],
      requirements: {
        state: { goal: true, minGems: 11, key: true, maxMoves: 15 },
        syntax: [
          syntax('nestedLoops', '二重ループを使いましょう。'),
          syntax('if', 'if を使って方向を選びましょう。'),
          syntax('elseIf', 'else if を使って段の移動を分けましょう。'),
          syntax('logicalAnd', '&& で段とカギの二つを確認しましょう。'),
          syntax('hasKey', 'hero.hasKey() でカギを確認しましょう。'),
          syntax('readSign', 'hero.readSign() で最初の方向を読みましょう。')
        ]
      }
    }
  ]
})
