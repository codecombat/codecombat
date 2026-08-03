(function () {
  'use strict'

  const MISSION_COUNT = 23
  const INFINITE_MISSION_ID = 14
  const STORAGE_KEY = 'japanese-js-quest-progress-v1'
  const INFINITE_PREPARE_KEY = 'japanese-js-quest-infinite-prepared-v1'
  const PAGE_INSTANCE = String(Date.now()) + '-' + Math.random().toString(36).slice(2)
  const PREPARE_MESSAGE = 'Ctrl+F5 でページを再読み込みしてね。そうすれば、ぼくは無限ループの中へ進めるよ。'
  let infiniteLoopRunning = false

  function currentMissionId () {
    const match = (document.getElementById('mission-number')?.textContent || '').match(/(\d+)/)
    return match ? Number(match[1]) : 0
  }

  function currentMission () {
    return (window.JSQuestMissions || []).find(item => item.id === currentMissionId()) || null
  }

  function savedProgress () {
    try {
      return JSON.parse(localStorage.getItem(STORAGE_KEY) || '{}')
    } catch (_) {
      return {}
    }
  }

  function isInfiniteCompleted () {
    const completed = savedProgress().completed
    return Array.isArray(completed) && completed.includes(INFINITE_MISSION_ID)
  }

  function preparedOnEarlierPageLoad () {
    try {
      const prepared = JSON.parse(sessionStorage.getItem(INFINITE_PREPARE_KEY) || 'null')
      return Boolean(prepared && prepared.pageInstance && prepared.pageInstance !== PAGE_INSTANCE)
    } catch (_) {
      return false
    }
  }

  function markInfinitePreparation () {
    sessionStorage.setItem(INFINITE_PREPARE_KEY, JSON.stringify({ pageInstance: PAGE_INSTANCE }))
  }

  function clearInfinitePreparation () {
    sessionStorage.removeItem(INFINITE_PREPARE_KEY)
  }

  function patchMissionCount () {
    const subtitle = document.querySelector('.subtitle')
    if (subtitle) subtitle.textContent = '23のミッションで、関数・条件・ループを学ぼう'
    const progress = document.getElementById('progress-label')
    if (progress && /\/\s*21\b/.test(progress.textContent)) {
      progress.textContent = progress.textContent.replace(/\/\s*21\b/, '/ 23')
    }
  }

  function renderProgressiveLegend () {
    const legend = document.querySelector('.game-panel .legend')
    if (!legend) return
    const missionId = currentMissionId()
    const entries = [
      { from: 0, text: '🧙 ヒーロー' },
      { from: 1, text: '💎 宝石' },
      { from: 1, text: '🏁 ゴール' },
      { from: 2, text: '🐸 カエル' },
      { from: 7, text: '⚠️ ワナ' },
      { from: 9, text: '🔑 カギ' },
      { from: 9, text: '🚪 ドア' },
      { from: 15, text: '👹 敵' }
    ]
    legend.innerHTML = entries
      .filter(entry => entry.from <= missionId)
      .map(entry => '<span>' + entry.text + '</span>')
      .join('')
  }

  function hidePrematureStats () {
    const stats = document.getElementById('stats')
    if (!stats) return
    const missionId = currentMissionId()
    stats.querySelectorAll('.stat').forEach(stat => {
      const text = stat.textContent.trim()
      if (text.startsWith('⚠️') && missionId < 7) stat.remove()
      if (text.startsWith('🔑') && missionId < 9) stat.remove()
    })
  }

  function correctFinalMessage () {
    const feedback = document.getElementById('feedback')
    if (!feedback) return
    const current = feedback.textContent
    const corrected = current
      .replace('全20ミッション', '全' + MISSION_COUNT + 'ミッション')
      .replace('全21ミッション', '全' + MISSION_COUNT + 'ミッション')
    if (corrected !== current) feedback.textContent = corrected
  }

  function renderFieldMissionHeading () {
    const mission = currentMission()
    const progress = document.getElementById('field-progress')
    if (!mission || !progress) return

    let heading = document.getElementById('field-mission-heading')
    if (!heading) {
      heading = document.createElement('div')
      heading.id = 'field-mission-heading'
      heading.className = 'field-mission-heading'
      progress.insertAdjacentElement('beforebegin', heading)
    }

    heading.innerHTML = ''
    const number = document.createElement('span')
    number.className = 'eyebrow field-mission-number'
    number.textContent = 'MISSION ' + String(mission.id).padStart(2, '0')
    const title = document.createElement('span')
    title.className = 'field-mission-title'
    title.textContent = ' - ' + mission.title
    heading.append(number, title)
  }

  function renderVictoryConditions () {
    const mission = currentMission()
    const progress = document.getElementById('field-progress')
    if (!mission || !progress) return

    let conditions = document.getElementById('victory-conditions')
    if (!conditions) {
      conditions = document.createElement('div')
      conditions.id = 'victory-conditions'
      conditions.className = 'victory-conditions'
      const track = progress.querySelector('.field-progress-track')
      if (track) track.insertAdjacentElement('beforebegin', conditions)
      else progress.appendChild(conditions)
    }

    const items = Array.isArray(mission.victoryConditions) ? mission.victoryConditions : []
    conditions.hidden = items.length === 0
    conditions.innerHTML = ''
    for (const item of items) {
      const chip = document.createElement('span')
      chip.className = 'victory-condition'
      chip.textContent = item.label
      conditions.appendChild(chip)
    }
  }

  function setEditorPreparationLocked (locked) {
    const codePanel = document.querySelector('.code-panel')
    const fallback = document.getElementById('editor-fallback')
    const reset = document.getElementById('reset-code')
    if (codePanel) codePanel.classList.toggle('infinite-preparation', locked)
    if (fallback) {
      fallback.readOnly = locked
      fallback.setAttribute('aria-disabled', String(locked))
    }
    if (reset) reset.disabled = locked

    if (window.ace) {
      const aceEditor = window.ace.edit('editor')
      aceEditor.setReadOnly(locked)
    }
  }

  function setNormalRunButton () {
    const run = document.getElementById('run-code')
    if (!run) return
    run.classList.remove('infinite-prepare')
    run.classList.add('primary')
    run.textContent = '▶ 実行する'
  }

  function setPreparationRunButton (waitingForReload) {
    const run = document.getElementById('run-code')
    if (!run) return
    run.classList.remove('primary')
    run.classList.add('infinite-prepare')
    run.textContent = waitingForReload
      ? '↻ Ctrl+F5 で再読み込み'
      : '↻ 無限ループを準備する'
  }

  function configureInfiniteMissionGate () {
    if (currentMissionId() !== INFINITE_MISSION_ID || isInfiniteCompleted()) {
      setEditorPreparationLocked(false)
      setNormalRunButton()
      return
    }

    if (preparedOnEarlierPageLoad()) {
      setEditorPreparationLocked(false)
      setNormalRunButton()
      return
    }

    setEditorPreparationLocked(true)
    setPreparationRunButton(sessionStorage.getItem(INFINITE_PREPARE_KEY) != null)
  }

  async function prepareInfiniteReload () {
    markInfinitePreparation()
    setPreparationRunButton(true)
    const feedback = document.getElementById('feedback')
    if (feedback) {
      feedback.className = 'feedback neutral'
      feedback.textContent = '準備できました。Ctrl+F5 でページを再読み込みすると、編集と実行ができるようになります。'
    }
    await window.JSQuestSpeechUI.showSpeechBubble(PREPARE_MESSAGE)
  }

  function persistInfiniteCompletion () {
    const progress = savedProgress()
    progress.completed = Array.isArray(progress.completed) ? progress.completed : []
    if (!progress.completed.includes(INFINITE_MISSION_ID)) progress.completed.push(INFINITE_MISSION_ID)
    progress.completed.sort((a, b) => a - b)
    progress.unlocked = Math.max(Number(progress.unlocked) || 1, INFINITE_MISSION_ID + 2)
    localStorage.setItem(STORAGE_KEY, JSON.stringify(progress))

    const badge = document.getElementById('mission-badge')
    if (badge) {
      badge.textContent = 'クリア！'
      badge.className = 'mission-badge completed'
    }
    const saveStatus = document.getElementById('save-status')
    if (saveStatus) saveStatus.textContent = 'クリア記録を先に保存しました'
  }

  function collectDemonstrationGem () {
    const grid = document.getElementById('game-grid')
    if (!grid) return
    const tiles = Array.from(grid.children)
    const heroIndex = tiles.findIndex(tile => tile.classList.contains('hero'))
    if (heroIndex < 0) return
    const target = tiles[heroIndex + 1]
    const hero = tiles[heroIndex]
    if (!target) return

    hero.classList.remove('hero', 'form-wizard', 'form-frog', 'form-dragon')
    target.classList.remove('gem')
    target.classList.add('floor', 'hero', 'form-wizard')
    target.textContent = ''
    target.setAttribute('aria-label', 'ヒーロー、床')

    const stats = document.getElementById('stats')
    if (stats) {
      stats.querySelectorAll('.stat').forEach(stat => {
        if (stat.textContent.trim().startsWith('移動')) stat.textContent = '移動 1'
        if (stat.textContent.trim().startsWith('💎')) stat.textContent = '💎 1'
      })
    }
  }

  function updateInfiniteFieldProgress () {
    const number = document.getElementById('field-progress-number')
    const status = document.getElementById('field-progress-status')
    const fill = document.getElementById('field-progress-fill')
    const track = document.querySelector('.field-progress-track')
    if (number) number.textContent = '1 / 1'
    if (status) status.textContent = '無限ループを実行中'
    if (fill) fill.style.width = '100%'
    if (track) track.setAttribute('aria-valuenow', '1')
  }

  function disableAdventureControls () {
    document.body.classList.add('infinite-loop-running')
    document.querySelectorAll('button').forEach(button => {
      if (!button.classList.contains('speech-close')) button.disabled = true
    })
  }

  function delay (milliseconds) {
    return new Promise(resolve => window.setTimeout(resolve, milliseconds))
  }

  async function startInfiniteLoopDemo () {
    if (infiniteLoopRunning) return
    infiniteLoopRunning = true
    const mission = currentMission()
    if (!mission) return

    clearInfinitePreparation()
    persistInfiniteCompletion()
    const next = document.getElementById('next-mission')
    if (next) next.hidden = true
    const hint = document.getElementById('hint-box')
    if (hint) hint.hidden = true
    const feedback = document.getElementById('feedback')
    if (feedback) {
      feedback.className = 'feedback neutral'
      feedback.textContent = 'クリア記録は保存されました。無限ループから出るには、丸い矢印か Ctrl+F5 でページを再読み込みしてください。'
    }

    collectDemonstrationGem()
    updateInfiniteFieldProgress()
    disableAdventureControls()
    await delay(120)

    while (true) {
      await window.JSQuestSpeechUI.showSpeechBubble(mission.infiniteLoopMessage)
      await delay(80)
    }
  }

  function interceptRun (event) {
    if (currentMissionId() !== INFINITE_MISSION_ID) return
    event.preventDefault()
    event.stopImmediatePropagation()

    if (!isInfiniteCompleted() && !preparedOnEarlierPageLoad()) {
      prepareInfiniteReload()
      return
    }
    startInfiniteLoopDemo()
  }

  function installRunInterception () {
    const run = document.getElementById('run-code')
    if (!run) return
    run.addEventListener('click', interceptRun, true)

    const fallback = document.getElementById('editor-fallback')
    fallback?.addEventListener('keydown', event => {
      if ((event.ctrlKey || event.metaKey) && event.key === 'Enter') {
        event.preventDefault()
        event.stopImmediatePropagation()
        run.click()
      }
    }, true)

    if (window.ace) {
      const editor = window.ace.edit('editor')
      editor.commands.addCommand({
        name: 'runMission',
        bindKey: { win: 'Ctrl-Enter', mac: 'Command-Enter' },
        exec: () => run.click()
      })
    }
  }

  function refreshMissionUi () {
    patchMissionCount()
    renderProgressiveLegend()
    hidePrematureStats()
    correctFinalMessage()
    renderFieldMissionHeading()
    renderVictoryConditions()
    configureInfiniteMissionGate()
  }

  function init () {
    patchMissionCount()
    installRunInterception()
    refreshMissionUi()
    document.addEventListener('jsquest:missionloaded', refreshMissionUi)
    document.addEventListener('jsquest:missioncompleted', correctFinalMessage)

    const stats = document.getElementById('stats')
    if (stats) new MutationObserver(hidePrematureStats).observe(stats, { childList: true })
  }

  if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', init)
  else init()
})()
