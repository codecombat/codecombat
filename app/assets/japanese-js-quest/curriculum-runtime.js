(function () {
  'use strict'

  const MISSION_COUNT = 23
  const INFINITE_MISSION_ID = 14
  const STORAGE_KEY = 'japanese-js-quest-progress-v1'
  let infiniteLoopRunning = false

  function currentMissionId () {
    const match = (document.getElementById('mission-number')?.textContent || '').match(/(\d+)/)
    return match ? Number(match[1]) : 0
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

  function persistInfiniteCompletion () {
    let progress
    try {
      progress = JSON.parse(localStorage.getItem(STORAGE_KEY) || '{}')
    } catch (_) {
      progress = {}
    }
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
    const mission = (window.JSQuestMissions || []).find(item => item.id === INFINITE_MISSION_ID)
    if (!mission) return

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
