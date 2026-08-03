(function () {
  'use strict'

  const missions = window.JSQuestMissions
  const engine = window.JSQuestEngine
  const storageKey = 'japanese-js-quest-progress-v1'
  const codeKeyPrefix = 'japanese-js-quest-code-v1-'
  const adminMode = new URLSearchParams(window.location.search).has('admin') &&
    new URLSearchParams(window.location.search).get('admin') !== '0'

  if (!missions || !engine) {
    document.body.innerHTML = '<p>JavaScript クエストを読み込めませんでした。</p>'
    return
  }

  const els = {
    missionList: document.getElementById('mission-list'),
    progressLabel: document.getElementById('progress-label'),
    missionNumber: document.getElementById('mission-number'),
    missionTitle: document.getElementById('mission-title'),
    missionConcept: document.getElementById('mission-concept'),
    missionStory: document.getElementById('mission-story'),
    missionInstructions: document.getElementById('mission-instructions'),
    missionApi: document.getElementById('mission-api'),
    missionBadge: document.getElementById('mission-badge'),
    signDisplay: document.getElementById('sign-display'),
    stats: document.getElementById('stats'),
    grid: document.getElementById('game-grid'),
    legend: document.querySelector('.game-panel .legend'),
    editor: document.getElementById('editor'),
    fallback: document.getElementById('editor-fallback'),
    run: document.getElementById('run-code'),
    resetCode: document.getElementById('reset-code'),
    hint: document.getElementById('show-hint'),
    solution: document.getElementById('show-solution'),
    feedback: document.getElementById('feedback'),
    hintBox: document.getElementById('hint-box'),
    next: document.getElementById('next-mission'),
    resetProgress: document.getElementById('reset-progress'),
    saveStatus: document.getElementById('save-status')
  }

  let editor
  let currentIndex = 0
  let currentVariant = 0
  let hintIndex = 0
  let running = false
  let attempts = {}
  let progress = loadProgress()
  let fieldProgress

  function loadProgress () {
    try {
      const saved = JSON.parse(localStorage.getItem(storageKey) || '{}')
      return {
        completed: Array.isArray(saved.completed) ? saved.completed : [],
        unlocked: Math.max(1, Number(saved.unlocked) || 1)
      }
    } catch (_) {
      return { completed: [], unlocked: 1 }
    }
  }

  function saveProgress () {
    localStorage.setItem(storageKey, JSON.stringify(progress))
    els.saveStatus.textContent = '保存しました'
    window.setTimeout(() => { els.saveStatus.textContent = '自動保存' }, 900)
  }

  function initEditor () {
    if (window.ace) {
      window.ace.config.set('basePath', '../javascripts/ace')
      editor = window.ace.edit('editor')
      editor.setTheme('ace/theme/monokai')
      editor.session.setMode('ace/mode/javascript')
      editor.session.setUseSoftTabs(true)
      editor.session.setTabSize(2)
      editor.setOptions({ fontSize: '15px', showPrintMargin: false, wrap: true })
      editor.commands.addCommand({
        name: 'runMission',
        bindKey: { win: 'Ctrl-Enter', mac: 'Command-Enter' },
        exec: runCurrentCode
      })
      editor.session.on('change', saveCurrentCodeSoon)
    } else {
      els.editor.style.display = 'none'
      els.fallback.style.display = 'block'
      editor = {
        getValue: () => els.fallback.value,
        setValue: value => { els.fallback.value = value },
        focus: () => els.fallback.focus()
      }
      els.fallback.addEventListener('input', saveCurrentCodeSoon)
      els.fallback.addEventListener('keydown', event => {
        if ((event.ctrlKey || event.metaKey) && event.key === 'Enter') runCurrentCode()
      })
    }
  }

  let saveTimer
  function saveCurrentCodeSoon () {
    window.clearTimeout(saveTimer)
    saveTimer = window.setTimeout(() => {
      localStorage.setItem(codeKeyPrefix + missions[currentIndex].id, editor.getValue())
      els.saveStatus.textContent = 'コードを保存しました'
      window.setTimeout(() => { els.saveStatus.textContent = '自動保存' }, 900)
    }, 300)
  }

  function escapeHtml (value) {
    return String(value)
      .replace(/&/g, '&amp;')
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;')
      .replace(/"/g, '&quot;')
      .replace(/'/g, '&#039;')
  }

  function inlineCode (text) {
    return escapeHtml(text).replace(/`([^`]+)`/g, '<code>$1</code>')
  }

  function isCompleted (id) {
    return progress.completed.includes(id)
  }

  function renderMissionList () {
    els.missionList.innerHTML = ''
    for (const [index, mission] of missions.entries()) {
      const unlocked = index + 1 <= progress.unlocked
      const completed = isCompleted(mission.id)
      const button = document.createElement('button')
      button.type = 'button'
      button.className = 'mission-item' + (index === currentIndex ? ' active' : '') + (completed ? ' completed' : '')
      button.disabled = !unlocked
      button.innerHTML = [
        '<span class="mission-index">' + (completed ? '✓' : mission.id) + '</span>',
        '<span class="mission-name">' + escapeHtml(mission.title) + '</span>',
        '<span class="mission-state">' + (completed ? 'クリア' : unlocked ? '▶' : '🔒') + '</span>'
      ].join('')
      button.addEventListener('click', () => loadMission(index))
      els.missionList.appendChild(button)
    }
    els.progressLabel.textContent = progress.completed.length + ' / ' + missions.length
  }

  function ensureFieldProgress () {
    if (fieldProgress) return fieldProgress
    const panelHeading = document.querySelector('.game-panel .panel-heading')
    if (!panelHeading) return null

    fieldProgress = document.createElement('section')
    fieldProgress.id = 'field-progress'
    fieldProgress.className = 'field-progress'
    fieldProgress.setAttribute('aria-label', 'フィールドの進みぐあい')
    fieldProgress.innerHTML = [
      '<div class="field-progress-labels">',
      '  <span>フィールド <strong id="field-progress-number">1 / 1</strong></span>',
      '  <span id="field-progress-status" class="field-progress-status">スタート</span>',
      '</div>',
      '<div class="field-progress-track" role="progressbar" aria-valuemin="0" aria-valuemax="1" aria-valuenow="0">',
      '  <div id="field-progress-fill" class="field-progress-fill"></div>',
      '</div>'
    ].join('')
    panelHeading.insertAdjacentElement('afterend', fieldProgress)
    return fieldProgress
  }

  function updateFieldProgress (variantIndex, total, state) {
    const panel = ensureFieldProgress()
    if (!panel) return
    const safeTotal = Math.max(1, total)
    const displayed = Math.min(safeTotal, variantIndex + 1)
    const completedFields = state === 'passed' ? displayed : Math.max(0, displayed - 1)
    const statusText = state === 'running'
      ? 'このフィールドを実行中'
      : state === 'passed'
        ? 'クリア！'
        : '実行するとフィールド1から始まります'

    panel.querySelector('#field-progress-number').textContent = displayed + ' / ' + safeTotal
    panel.querySelector('#field-progress-status').textContent = statusText
    panel.querySelector('#field-progress-fill').style.width = ((completedFields / safeTotal) * 100) + '%'
    const track = panel.querySelector('.field-progress-track')
    track.setAttribute('aria-valuemax', String(safeTotal))
    track.setAttribute('aria-valuenow', String(completedFields))
  }

  function renderLegend (missionId) {
    if (!els.legend) return
    const entries = [
      { from: 0, text: '🧙 ヒーロー' },
      { from: 1, text: '💎 宝石' },
      { from: 1, text: '🏁 ゴール' },
      { from: 2, text: '🐸 カエル' },
      { from: 6, text: '⚠️ ワナ' },
      { from: 8, text: '🔑 カギ' },
      { from: 8, text: '🚪 ドア' },
      { from: 13, text: '👹 敵' }
    ]
    els.legend.innerHTML = entries
      .filter(entry => entry.from <= missionId)
      .map(entry => '<span>' + entry.text + '</span>')
      .join('')
  }

  function installAdminControls () {
    if (!adminMode) return
    const topActions = document.querySelector('.top-actions')
    if (!topActions || document.getElementById('admin-unlock-all')) return

    const badge = document.createElement('span')
    badge.className = 'admin-mode-badge'
    badge.textContent = 'ADMIN'

    const button = document.createElement('button')
    button.id = 'admin-unlock-all'
    button.type = 'button'
    button.className = 'button admin-unlock-button'
    button.textContent = '全ミッションを開く'
    button.addEventListener('click', () => {
      progress.unlocked = missions.length
      saveProgress()
      renderMissionList()
      setFeedback('管理者モードですべてのミッションを開きました。クリア記録は変更していません。', 'neutral')
      button.textContent = '全ミッション開放済み'
      button.disabled = true
    })

    topActions.prepend(button)
    topActions.prepend(badge)
  }

  function loadMission (index) {
    if (index + 1 > progress.unlocked || running) return
    window.JSQuestSpeechUI?.resetForRun()
    currentIndex = index
    currentVariant = 0
    const mission = missions[index]
    hintIndex = 0
    els.hintBox.hidden = true
    els.next.hidden = true
    setFeedback('コードを書いて「実行する」を押そう。実行するたびにフィールド1から始まります。', 'neutral')

    els.missionNumber.textContent = 'MISSION ' + String(mission.id).padStart(2, '0')
    els.missionTitle.textContent = mission.title
    els.missionConcept.textContent = mission.concept
    els.missionStory.textContent = mission.story
    els.missionInstructions.innerHTML = mission.instructions.map(text => '<p>・' + inlineCode(text) + '</p>').join('')
    els.missionApi.innerHTML = mission.api.map(item => '<code>' + escapeHtml(item) + '</code>').join('')
    els.missionBadge.textContent = isCompleted(mission.id) ? 'クリア済み' : 'チャレンジ中'
    els.missionBadge.className = 'mission-badge' + (isCompleted(mission.id) ? ' completed' : '')

    const savedCode = localStorage.getItem(codeKeyPrefix + mission.id)
    const useStarter = savedCode == null || savedCode === mission.originalStarterCode
    setEditorValue(useStarter ? mission.starterCode : savedCode)
    updateSolutionButton()
    renderLegend(mission.id)
    renderInitialState(0, 'ready')
    renderMissionList()
    document.dispatchEvent(new CustomEvent('jsquest:missionloaded', { detail: { mission } }))
    editor.focus()
  }

  function setEditorValue (value) {
    if (window.ace && editor && editor.session) editor.setValue(value, -1)
    else editor.setValue(value)
  }

  function renderInitialState (variantIndex, progressState) {
    window.JSQuestSpeechUI?.resetForRun()
    const mission = missions[currentIndex]
    currentVariant = variantIndex
    const state = engine.createState(mission, variantIndex)
    renderGrid(state.grid.map(row => row.join('')), state.hero.x, state.hero.y, 'hero')
    renderStats({ moves: 0, gems: 0, hasKey: false, trapHits: 0 })
    const sign = state.variant.sign
    els.signDisplay.textContent = sign == null ? '看板：なし' : '看板：' + String(sign)
    updateFieldProgress(variantIndex, mission.variants.length, progressState || 'ready')
  }

  function renderStats (state) {
    const missionId = missions[currentIndex].id
    const stats = ['<span class="stat">移動 ' + (state.moves || 0) + '</span>']
    if (missionId >= 1) stats.push('<span class="stat">💎 ' + (state.gems || 0) + '</span>')
    if (missionId >= 6) stats.push('<span class="stat">⚠️ ' + (state.trapHits || 0) + '</span>')
    if (missionId >= 8) stats.push('<span class="stat">🔑 ' + (state.hasKey ? 'あり' : 'なし') + '</span>')
    els.stats.innerHTML = stats.join('')
  }

  const tileVisual = {
    '#': { text: '🧱', className: 'wall', label: '壁' },
    '.': { text: '', className: 'floor', label: '床' },
    G: { text: '🏁', className: 'goal', label: 'ゴール' },
    '*': { text: '💎', className: 'gem', label: '宝石' },
    K: { text: '🔑', className: 'key', label: 'カギ' },
    D: { text: '🚪', className: 'door', label: 'ドア' },
    T: { text: '⚠️', className: 'trap', label: 'ワナ' },
    E: { text: '👹', className: 'enemy', label: '敵' }
  }

  function renderGrid (rows, heroX, heroY, form) {
    els.grid.innerHTML = ''
    els.grid.style.gridTemplateColumns = 'repeat(' + rows[0].length + ', minmax(0, 1fr))'
    for (let y = 0; y < rows.length; y++) {
      for (let x = 0; x < rows[y].length; x++) {
        const visual = tileVisual[rows[y][x]] || tileVisual['.']
        const isHero = x === heroX && y === heroY
        const tile = document.createElement('div')
        let formClass = ''
        if (isHero) {
          if (form === 'frog') formClass = ' form-frog'
          else if (form === 'dragon') formClass = ' form-dragon'
          else formClass = ' form-wizard'
        }
        tile.className = 'tile ' + visual.className + (isHero ? ' hero' : '') + formClass
        tile.textContent = visual.text
        tile.setAttribute('role', 'gridcell')
        const heroLabel = form === 'frog'
          ? 'カエルの姿のヒーロー、'
          : form === 'dragon'
            ? 'ドラゴンの姿のヒーロー、'
            : 'ヒーロー、'
        tile.setAttribute('aria-label', (isHero ? heroLabel : '') + visual.label)
        els.grid.appendChild(tile)
      }
    }
  }

  function setFeedback (message, type) {
    els.feedback.textContent = message
    els.feedback.className = 'feedback ' + type
  }

  function workerRun (code, mission, variantIndex) {
    return new Promise((resolve, reject) => {
      const engineUrl = new URL('engine.js', window.location.href).href
      const workerSource = [
        'importScripts(' + JSON.stringify(engineUrl) + ');',
        'self.onmessage = function (event) {',
        '  const data = event.data;',
        '  const result = self.JSQuestEngine.simulate(data.code, data.mission, data.variantIndex);',
        '  const evaluation = self.JSQuestEngine.evaluate(data.mission, result, data.code);',
        '  self.postMessage({ result: result, evaluation: evaluation });',
        '};'
      ].join('\n')
      const blobUrl = URL.createObjectURL(new Blob([workerSource], { type: 'application/javascript' }))
      const worker = new Worker(blobUrl)
      const timeout = window.setTimeout(() => {
        worker.terminate()
        URL.revokeObjectURL(blobUrl)
        reject(new Error('コードの実行が終わりません。ループの条件を確認してください。'))
      }, 1800)

      worker.onmessage = event => {
        window.clearTimeout(timeout)
        worker.terminate()
        URL.revokeObjectURL(blobUrl)
        resolve(event.data)
      }
      worker.onerror = error => {
        window.clearTimeout(timeout)
        worker.terminate()
        URL.revokeObjectURL(blobUrl)
        reject(new Error(error.message || 'コードを実行できませんでした。'))
      }
      worker.postMessage({ code, mission, variantIndex })
    })
  }

  function delay (milliseconds) {
    return new Promise(resolve => window.setTimeout(resolve, milliseconds))
  }

  async function animateTrace (trace, fallbackState) {
    if (!trace || !trace.length) {
      const fallbackGrid = fallbackState.grid || engine.createState(missions[currentIndex], currentVariant).grid.map(row => row.join(''))
      renderGrid(fallbackGrid, fallbackState.x, fallbackState.y, fallbackState.form || 'hero')
      renderStats(fallbackState)
      return
    }

    for (const frame of trace) {
      renderGrid(frame.grid, frame.x, frame.y, frame.form || 'hero')
      renderStats(frame)

      if (frame.type === 'say') {
        await window.JSQuestSpeechUI.showSpeechBubble(frame.speech)
        await delay(70)
      } else if (frame.type === 'transform') {
        await delay(260)
      } else {
        await delay(130)
      }
    }
  }

  async function runCurrentCode () {
    if (running) return
    const mission = missions[currentIndex]
    const code = editor.getValue()
    attempts[mission.id] = (attempts[mission.id] || 0) + 1
    updateSolutionButton()
    running = true
    els.run.disabled = true
    els.next.hidden = true
    els.hintBox.hidden = true

    try {
      for (let variantIndex = 0; variantIndex < mission.variants.length; variantIndex++) {
        renderInitialState(variantIndex, 'running')
        setFeedback('フィールド ' + (variantIndex + 1) + ' / ' + mission.variants.length + ' を実行しています……', 'neutral')
        await delay(60)

        const execution = await workerRun(code, mission, variantIndex)
        await animateTrace(execution.result.trace, execution.result.state)

        if (!execution.evaluation.passed) {
          const logs = execution.result.logs && execution.result.logs.length
            ? '\n\n出力:\n' + execution.result.logs.join('\n')
            : ''
          setFeedback(
            'フィールド ' + (variantIndex + 1) + ' で止まりました。\n' +
            execution.evaluation.messages.join('\n') + logs +
            '\n\nもう一度実行すると、フィールド1から始まります。',
            'error'
          )
          return
        }

        updateFieldProgress(variantIndex, mission.variants.length, 'passed')
        if (variantIndex < mission.variants.length - 1) {
          setFeedback('フィールド ' + (variantIndex + 1) + ' クリア！ 同じコードで次のフィールドへ進みます。', 'neutral')
          await delay(420)
        }
      }

      completeMission(mission)
    } catch (error) {
      setFeedback(error.message, 'error')
    } finally {
      running = false
      els.run.disabled = false
    }
  }

  function completeMission (mission) {
    if (!isCompleted(mission.id)) {
      progress.completed.push(mission.id)
      progress.completed.sort((a, b) => a - b)
    }
    progress.unlocked = Math.min(missions.length, Math.max(progress.unlocked, currentIndex + 2))
    saveProgress()
    renderMissionList()
    els.missionBadge.textContent = 'クリア！'
    els.missionBadge.className = 'mission-badge completed'
    const isFinal = currentIndex === missions.length - 1
    setFeedback(
      isFinal
        ? '全21ミッション、クリア！ JavaScript マスターへの第一歩です！ 🎉'
        : 'ミッションクリア！ 同じコードですべてのフィールドに成功しました。 🎉',
      'success'
    )
    els.next.hidden = isFinal
    document.dispatchEvent(new CustomEvent('jsquest:missioncompleted', { detail: { mission } }))
  }

  function updateSolutionButton () {
    const count = attempts[missions[currentIndex].id] || 0
    els.solution.disabled = count < 3
    els.solution.textContent = count < 3 ? '答えを見る（あと' + (3 - count) + '回）' : '答えを見る'
  }

  els.run.addEventListener('click', runCurrentCode)
  els.resetCode.addEventListener('click', () => {
    if (!window.confirm('このミッションのコードを最初にもどしますか？')) return
    const mission = missions[currentIndex]
    setEditorValue(mission.starterCode)
    localStorage.removeItem(codeKeyPrefix + mission.id)
    setFeedback('最初のコードにもどしました。', 'neutral')
    renderInitialState(0, 'ready')
    editor.focus()
  })

  els.hint.addEventListener('click', () => {
    const hints = missions[currentIndex].hints
    const hint = hints[Math.min(hintIndex, hints.length - 1)]
    hintIndex++
    els.hintBox.textContent = 'ヒント ' + Math.min(hintIndex, hints.length) + '：' + hint
    els.hintBox.hidden = false
  })

  els.solution.addEventListener('click', () => {
    if (els.solution.disabled) return
    if (!window.confirm('答えを見ると、自分のコードが答えに置きかわります。よろしいですか？')) return
    const mission = missions[currentIndex]
    setEditorValue(mission.solution)
    localStorage.setItem(codeKeyPrefix + mission.id, mission.solution)
    setFeedback('答えを表示しました。1行ずつ読んでから実行してみよう。', 'neutral')
    editor.focus()
  })

  els.next.addEventListener('click', () => loadMission(Math.min(currentIndex + 1, missions.length - 1)))

  els.resetProgress.addEventListener('click', () => {
    if (!window.confirm('クリア記録と保存したコードをすべて消しますか？')) return
    localStorage.removeItem(storageKey)
    for (const mission of missions) localStorage.removeItem(codeKeyPrefix + mission.id)
    progress = { completed: [], unlocked: 1 }
    attempts = {}
    loadMission(0)
  })

  ensureFieldProgress()
  installAdminControls()
  initEditor()
  const firstIncomplete = missions.findIndex(mission => !isCompleted(mission.id))
  const initialIndex = firstIncomplete >= 0 && firstIncomplete < progress.unlocked
    ? firstIncomplete
    : Math.min(progress.unlocked - 1, missions.length - 1)
  loadMission(initialIndex)
})()
