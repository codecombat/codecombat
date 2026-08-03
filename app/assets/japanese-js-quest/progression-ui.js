(function () {
  'use strict'

  const missions = window.JSQuestMissions || []
  let celebratedMission = null
  let lastMissionId = null

  function missionId () {
    const match = (document.getElementById('mission-number')?.textContent || '').match(/(\d+)/)
    return match ? Number(match[1]) : 0
  }

  function missionById (id) {
    return missions.find(mission => mission.id === id)
  }

  function ensurePanel () {
    let panel = document.getElementById('wizard-progress')
    if (panel) return panel
    const heading = document.querySelector('.mission-card .mission-heading')
    if (!heading) return null
    panel = document.createElement('section')
    panel.id = 'wizard-progress'
    panel.className = 'wizard-progress'
    panel.setAttribute('aria-label', '魔法使いのレベルと経験値')
    panel.innerHTML = [
      '<div class="wizard-progress-avatar" aria-hidden="true">🧙</div>',
      '<div class="wizard-progress-main">',
      '  <div class="wizard-progress-labels">',
      '    <strong id="wizard-level-label">魔法使い レベル0</strong>',
      '    <span id="wizard-xp-label">経験値 0 / 1</span>',
      '  </div>',
      '  <div class="wizard-xp-track" role="progressbar" aria-label="経験値">',
      '    <div id="wizard-xp-fill" class="wizard-xp-fill"></div>',
      '  </div>',
      '  <p class="wizard-lore">💎 宝石を集めると経験値が増え、新しい魔法が使えるようになるよ。</p>',
      '</div>'
    ].join('')
    heading.insertAdjacentElement('afterend', panel)
    return panel
  }

  function valuesFor (mission, completed) {
    const xp = completed ? mission.wizardXpAfter : mission.wizardXpBefore
    const level = completed ? mission.wizardLevelAfter : mission.wizardLevel
    const floor = window.JSQuestProgression.thresholdForLevel(level)
    const ceiling = window.JSQuestProgression.thresholdForLevel(level + 1)
    const percent = Math.max(0, Math.min(100, ((xp - floor) / Math.max(1, ceiling - floor)) * 100))
    return { xp, level, floor, ceiling, percent }
  }

  function render (completed) {
    const panel = ensurePanel()
    const mission = missionById(missionId())
    if (!panel || !mission) return
    const values = valuesFor(mission, Boolean(completed))
    const levelLabel = document.getElementById('wizard-level-label')
    const xpLabel = document.getElementById('wizard-xp-label')
    const fill = document.getElementById('wizard-xp-fill')
    levelLabel.textContent = '魔法使い レベル' + values.level
    xpLabel.textContent = '経験値 ' + values.xp + ' / ' + values.ceiling
    fill.style.width = values.percent + '%'
    panel.dataset.level = String(values.level)
    panel.querySelector('.wizard-xp-track').setAttribute('aria-valuenow', String(values.xp))
    panel.querySelector('.wizard-xp-track').setAttribute('aria-valuemin', String(values.floor))
    panel.querySelector('.wizard-xp-track').setAttribute('aria-valuemax', String(values.ceiling))
  }

  function showLevelUp (mission) {
    if (!window.JSQuestSpeechUI || mission.wizardLevelAfter <= mission.wizardLevel) return Promise.resolve()
    const learned = mission.wizardLevelAfter === 1
      ? '<p class="level-up-power">新しい力：<code>hero.transform(form)</code></p><p>カエルの姿に変身できるようになった！</p>'
      : '<p>新しい力に近づいた！</p>'
    return window.JSQuestSpeechUI.showLevelUpModal([
      '<div class="level-up-stars">✨ ⭐ ✨</div>',
      '<h2>レベルアップ！</h2>',
      '<p>魔法使いは <strong>レベル' + mission.wizardLevelAfter + '</strong> になった！</p>',
      learned
    ].join(''))
  }

  function onBadgeChange () {
    const badge = document.getElementById('mission-badge')
    const mission = missionById(missionId())
    if (!badge || !mission) return
    if (badge.textContent !== 'クリア！') return
    render(true)
    if (celebratedMission === mission.id) return
    celebratedMission = mission.id
    window.setTimeout(() => showLevelUp(mission), 380)
  }

  function onMissionChange () {
    const id = missionId()
    if (id !== lastMissionId) {
      lastMissionId = id
      celebratedMission = null
      window.JSQuestSpeechUI?.setForm('hero')
    }
    render(false)
  }

  function correctFinalMessage () {
    const feedback = document.getElementById('feedback')
    if (feedback && feedback.textContent.includes('全20ミッション')) {
      feedback.textContent = feedback.textContent.replace('全20ミッション', '全21ミッション')
    }
  }

  function init () {
    ensurePanel()
    const number = document.getElementById('mission-number')
    const badge = document.getElementById('mission-badge')
    const feedback = document.getElementById('feedback')
    if (number) new MutationObserver(onMissionChange).observe(number, { childList: true, subtree: true, characterData: true })
    if (badge) new MutationObserver(onBadgeChange).observe(badge, { childList: true, subtree: true, characterData: true })
    if (feedback) new MutationObserver(correctFinalMessage).observe(feedback, { childList: true, subtree: true, characterData: true })
    onMissionChange()
    correctFinalMessage()
  }

  if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', init)
  else init()
})()
