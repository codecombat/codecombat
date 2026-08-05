(function () {
  'use strict'

  let tooltip = null
  let activeTrigger = null
  let pinned = false

  function ensureTooltip () {
    if (tooltip) return tooltip
    tooltip = document.createElement('div')
    tooltip.id = 'global-tooltip-layer'
    tooltip.className = 'global-tooltip-layer'
    tooltip.setAttribute('role', 'tooltip')
    tooltip.hidden = true
    document.body.appendChild(tooltip)
    return tooltip
  }

  function visibleModal () {
    return Array.from(document.querySelectorAll('[aria-modal="true"]'))
      .find(element => !element.hidden && element.getClientRects().length > 0) || null
  }

  function triggerIsAvailable (trigger) {
    const modal = visibleModal()
    return !modal || modal.contains(trigger)
  }

  function positionTooltip () {
    if (!tooltip || tooltip.hidden || !activeTrigger?.isConnected) return

    const triggerRect = activeTrigger.getBoundingClientRect()
    tooltip.classList.remove('is-below')
    tooltip.style.left = '0px'
    tooltip.style.top = '0px'
    tooltip.style.visibility = 'hidden'

    const tooltipRect = tooltip.getBoundingClientRect()
    const viewportPadding = 8
    const idealLeft = triggerRect.left + triggerRect.width / 2 - tooltipRect.width / 2
    const maxLeft = Math.max(viewportPadding, window.innerWidth - tooltipRect.width - viewportPadding)
    const left = Math.min(Math.max(idealLeft, viewportPadding), maxLeft)
    let top = triggerRect.top - tooltipRect.height - 10

    if (top < viewportPadding) {
      top = triggerRect.bottom + 10
      tooltip.classList.add('is-below')
    }
    top = Math.min(top, window.innerHeight - tooltipRect.height - viewportPadding)

    tooltip.style.left = left + 'px'
    tooltip.style.top = Math.max(viewportPadding, top) + 'px'
    tooltip.style.setProperty('--tooltip-anchor-x', (triggerRect.left + triggerRect.width / 2 - left) + 'px')
    tooltip.style.visibility = 'visible'
  }

  function showTooltip (trigger, pin) {
    if (!trigger?.dataset.tooltip || !triggerIsAvailable(trigger)) return
    const layer = ensureTooltip()
    activeTrigger = trigger
    pinned = Boolean(pin)
    layer.textContent = trigger.dataset.tooltip
    layer.hidden = false
    window.requestAnimationFrame(positionTooltip)
  }

  function hideTooltip (force) {
    if (!tooltip || (!force && pinned)) return
    tooltip.hidden = true
    tooltip.style.visibility = ''
    activeTrigger = null
    pinned = false
  }

  document.addEventListener('pointerover', event => {
    const trigger = event.target.closest('[data-tooltip]')
    if (!trigger || trigger === activeTrigger) return
    showTooltip(trigger, false)
  }, true)

  document.addEventListener('pointerout', event => {
    if (!activeTrigger || activeTrigger.contains(event.relatedTarget)) return
    if (event.target.closest('[data-tooltip]') !== activeTrigger) return
    hideTooltip(false)
  }, true)

  document.addEventListener('focusin', event => {
    const trigger = event.target.closest('[data-tooltip]')
    if (trigger) showTooltip(trigger, false)
  }, true)

  document.addEventListener('focusout', event => {
    if (!activeTrigger || activeTrigger.contains(event.relatedTarget)) return
    hideTooltip(false)
  }, true)

  document.addEventListener('click', event => {
    const trigger = event.target.closest('[data-tooltip]')
    if (!trigger) {
      document.querySelectorAll('[data-tooltip].is-open').forEach(element => element.classList.remove('is-open'))
      hideTooltip(true)
      return
    }

    window.setTimeout(() => {
      const open = trigger.classList.contains('is-open')
      if (open) showTooltip(trigger, true)
      else if (activeTrigger === trigger) hideTooltip(true)
    }, 0)
  }, true)

  window.addEventListener('resize', positionTooltip)
  window.addEventListener('scroll', positionTooltip, true)

  const modalObserver = new MutationObserver(() => {
    if (activeTrigger && !triggerIsAvailable(activeTrigger)) hideTooltip(true)
  })
  modalObserver.observe(document.body, {
    childList: true,
    subtree: true,
    attributes: true,
    attributeFilter: ['hidden', 'aria-modal']
  })
})()
