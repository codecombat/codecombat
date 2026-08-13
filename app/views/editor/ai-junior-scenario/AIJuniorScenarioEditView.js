// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS002: Fix invalid constructor
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let AIJuniorScenarioEditView
require('app/styles/editor/ai-junior-scenario/edit.sass')
const RootView = require('views/core/RootView')
const template = require('app/templates/editor/ai-junior-scenario/edit')
const AIJuniorScenario = require('models/AIJuniorScenario')
const ConfirmModal = require('views/core/ConfirmModal')
const AIJuniorWorksheet = require('components/common/elements/AIJuniorWorksheet').default

const nodes = require('views/editor/level/treema_nodes')

require('lib/game-libraries')
require('lib/setupTreema')
require('core/treema-ext')

// Input geometry is stored as percentages of the worksheet's printable area, so layout mode works
// entirely in percentages and only touches pixels to measure the scaled sheet on screen.
const GEOMETRY_KEYS = ['left', 'top', 'width', 'height']
const MIN_INPUT_SIZE = 2
// Given to inputs that have no geometry yet, so that they show up somewhere draggable.
const DEFAULT_GEOMETRY = { left: 0, top: 0, width: 20, height: 20 }
// Only bare `<%= someId %>` references get checked; anything with an expression in it is left alone.
const TEMPLATE_REFERENCE = /<%[=-]([^%]*?)%>/g
const BARE_IDENTIFIER = /^[a-zA-Z_$][a-zA-Z0-9_$]*$/

const clamp = (value, min, max) => Math.min(Math.max(value, min), Math.max(min, max))
const roundPercent = value => Math.round(value * 100) / 100
const isPercent = value => typeof value === 'number' && isFinite(value)

module.exports = (AIJuniorScenarioEditView = (function () {
  AIJuniorScenarioEditView = class AIJuniorScenarioEditView extends RootView {
    static initClass () {
      this.prototype.id = 'editor-ai-junior-scenario-edit-view'
      this.prototype.template = template

      this.prototype.events = {
        'click #save-button': 'onClickSaveButton',
        'click #i18n-button': 'onPopulateI18N',
        'click #delete-button': 'confirmDeletion',
        'click #layout-mode-button': 'onClickLayoutModeButton',
        'mousedown .layout-box': 'onLayoutBoxMouseDown',
      }
    }

    constructor (options, scenarioID) {
      super(options)
      this.pushChangesToPreview = this.pushChangesToPreview.bind(this)
      this.pushChangesToPreview = _.throttle(this.pushChangesToPreview, 500)
      this.deleteAIJuniorScenario = this.deleteAIJuniorScenario.bind(this)
      this.onLayoutDragMove = this.onLayoutDragMove.bind(this)
      this.onLayoutDragEnd = this.onLayoutDragEnd.bind(this)
      this.onWindowResize = _.debounce(this.onWindowResize.bind(this), 150)
      this.layoutMode = false
      this.layoutDrag = null
      this.scenarioID = scenarioID
      this.scenario = new AIJuniorScenario({ _id: this.scenarioID })
      this.scenario.saveBackups = true
      this.propsData = {
        slug: scenarioID,
      }
      this.supermodel.loadModel(this.scenario)
      $(window).on('resize.ai-junior-layout', this.onWindowResize)
    }

    afterRender () {
      this.attachVueComponent()
      this.renderLayoutOverlay()
      this.renderValidationWarnings()
      return super.afterRender(...arguments)
    }

    // The worksheet is mounted once and then kept alive for the life of the view. Backbone empties
    // the view element on every render, so the component's element gets moved back into the fresh
    // placeholder rather than being mounted again.
    attachVueComponent () {
      const placeholder = this.$el.find('#ai-junior-worksheet')[0]
      if (!this.vueComponent) {
        if (!placeholder) { return }
        this.vueComponent = new AIJuniorWorksheet({
          el: placeholder,
          propsData: this.propsData,
        })
        return
      }
      const el = this.vueComponent.$el
      if (!el || document.body.contains(el)) { return }
      if (!placeholder) { return }
      $(placeholder).replaceWith(el)
      // The sheet scales itself to whatever container it is in, and it just changed containers.
      _.defer(() => {
        if (this.destroyed) { return }
        this.vueComponent.scaleWorksheet?.()
        this.renderLayoutOverlay()
      })
    }

    onLoaded () {
      super.onLoaded()
      this.buildTreema()
      this.listenTo(this.scenario, 'change', () => {
        this.scenario.updateI18NCoverage()
        this.treema.set('/', this.scenario.attributes)
        this.updateVueComponent()
      })
    }

    buildTreema () {
      if ((this.treema != null) || (!this.scenario.loaded)) { return }
      const data = $.extend(true, {}, this.scenario.attributes)
      const options = {
        data,
        filePath: `db/ai_junior_scenario/${this.scenario.get('_id')}`,
        schema: AIJuniorScenario.schema,
        readOnly: me.get('anonymous'),
        supermodel: this.supermodel,
        nodeClasses: {
          'chat-message-link': nodes.ChatMessageLinkNode,
        },
        callbacks: {
          change: this.pushChangesToPreview,
        },
      }
      this.treema = this.$el.find('#ai-junior-scenario-treema').treema(options)
      this.treema.build()
      this.treema.open(5)
      this.pushChangesToPreview()
    }

    pushChangesToPreview () {
      this.updateVueComponent()
      this.renderLayoutOverlay()
      this.renderValidationWarnings()
    }

    updateVueComponent () {
      if (!this.treema || !this.vueComponent) { return }
      // A fresh copy each time: Treema edits its data in place, and Vue only notices a new object.
      this.propsData.scenario = $.extend(true, {}, this.treema.get('/'))
      this.vueComponent.scenario = this.propsData.scenario
    }

    // Layout mode ---------------------------------------------------------------

    onClickLayoutModeButton (e) {
      this.layoutMode = !this.layoutMode
      this.$el.find('#layout-mode-button').toggleClass('active', this.layoutMode)
      this.renderLayoutOverlay()
      // The overlay is measured off the worksheet, which may still be scaling itself into place.
      _.defer(() => {
        if (!this.destroyed) { this.renderLayoutOverlay() }
      })
    }

    // The inputs are positioned within the sheet's printable area, inside the page margins, so that
    // is the box the overlay has to line up with.
    getWorksheetSheetEl () {
      const root = this.vueComponent != null ? this.vueComponent.$el : null
      if (!root || !root.querySelector) { return null }
      return root.querySelector('.worksheet-inner-container') || root
    }

    getScenarioInputs () {
      if (!this.treema) { return [] }
      const inputs = this.treema.get('/inputs')
      return _.isArray(inputs) ? inputs : []
    }

    inputGeometry (input) {
      const geometry = {}
      for (const key of GEOMETRY_KEYS) {
        geometry[key] = isPercent(input != null ? input[key] : null) ? input[key] : DEFAULT_GEOMETRY[key]
      }
      return geometry
    }

    hasCompleteGeometry (input) {
      return _.every(GEOMETRY_KEYS, key => isPercent(input != null ? input[key] : null))
    }

    renderLayoutOverlay () {
      const overlay = this.$el.find('#layout-overlay')
      if (!overlay.length) { return }
      // Never yank the box out from under a drag in progress.
      if (this.layoutDrag) { return }
      if (!this.layoutMode) {
        return overlay.removeClass('layout-overlay-active').empty()
      }

      const sheet = this.getWorksheetSheetEl()
      const container = this.$el.find('#worksheet-preview-container')[0]
      if (!sheet || !container) { return overlay.removeClass('layout-overlay-active').empty() }
      const sheetRect = sheet.getBoundingClientRect()
      const containerRect = container.getBoundingClientRect()
      if (!(sheetRect.width > 0) || !(sheetRect.height > 0)) {
        return overlay.removeClass('layout-overlay-active').empty()
      }

      overlay.addClass('layout-overlay-active').css({
        left: sheetRect.left - containerRect.left,
        top: sheetRect.top - containerRect.top,
        width: sheetRect.width,
        height: sheetRect.height,
      })

      overlay.empty()
      this.getScenarioInputs().forEach((input, index) => {
        overlay.append(this.buildLayoutBox(input, index))
      })
    }

    buildLayoutBox (input, index) {
      const geometry = this.inputGeometry(input)
      const box = $('<div class="layout-box"></div>')
        .attr('data-index', index)
        .css({
          left: `${geometry.left}%`,
          top: `${geometry.top}%`,
          width: `${geometry.width}%`,
          height: `${geometry.height}%`,
        })
      if (!this.hasCompleteGeometry(input)) {
        box.addClass('layout-box-incomplete')
      }
      const label = [(input != null ? input.id : null) || '(no id)', (input != null ? input.type : null) || '(no type)'].join(' · ')
      box.append($('<span class="layout-box-label"></span>').text(label))
      for (const handle of ['e', 's', 'se']) {
        box.append($('<div class="layout-handle"></div>').attr('data-handle', handle))
      }
      return box
    }

    onLayoutBoxMouseDown (e) {
      if (!this.layoutMode || this.layoutDrag) { return }
      const box = $(e.target).closest('.layout-box')
      if (!box.length) { return }
      const index = parseInt(box.attr('data-index'), 10)
      const input = this.getScenarioInputs()[index]
      if (!input) { return }
      const sheet = this.getWorksheetSheetEl()
      const sheetRect = sheet != null ? sheet.getBoundingClientRect() : null
      if (!sheetRect || !(sheetRect.width > 0) || !(sheetRect.height > 0)) { return }
      e.preventDefault()

      this.layoutDrag = {
        index,
        box,
        mode: $(e.target).attr('data-handle') || 'move',
        startX: e.pageX,
        startY: e.pageY,
        sheetWidth: sheetRect.width,
        sheetHeight: sheetRect.height,
        origin: this.inputGeometry(input),
        geometry: null,
      }
      box.addClass('layout-box-active')
      $(document).on('mousemove.ai-junior-layout', this.onLayoutDragMove)
      $(document).on('mouseup.ai-junior-layout', this.onLayoutDragEnd)
    }

    onLayoutDragMove (e) {
      const drag = this.layoutDrag
      if (!drag) { return }
      e.preventDefault()
      const dx = ((e.pageX - drag.startX) / drag.sheetWidth) * 100
      const dy = ((e.pageY - drag.startY) / drag.sheetHeight) * 100
      drag.geometry = this.dragGeometry(drag, dx, dy)
      drag.box.css({
        left: `${drag.geometry.left}%`,
        top: `${drag.geometry.top}%`,
        width: `${drag.geometry.width}%`,
        height: `${drag.geometry.height}%`,
      })
    }

    dragGeometry (drag, dx, dy) {
      const origin = drag.origin
      const geometry = _.pick(origin, GEOMETRY_KEYS)
      if (drag.mode === 'move') {
        geometry.left = clamp(origin.left + dx, 0, 100 - origin.width)
        geometry.top = clamp(origin.top + dy, 0, 100 - origin.height)
      } else {
        if (drag.mode.indexOf('e') !== -1) {
          geometry.width = clamp(origin.width + dx, MIN_INPUT_SIZE, 100 - origin.left)
        }
        if (drag.mode.indexOf('s') !== -1) {
          geometry.height = clamp(origin.height + dy, MIN_INPUT_SIZE, 100 - origin.top)
        }
      }
      for (const key of GEOMETRY_KEYS) {
        geometry[key] = roundPercent(geometry[key])
      }
      return geometry
    }

    onLayoutDragEnd (e) {
      const drag = this.layoutDrag
      $(document).off('.ai-junior-layout')
      this.layoutDrag = null
      if (!drag) { return }
      drag.box.removeClass('layout-box-active')
      if (drag.geometry) {
        this.saveInputGeometry(drag.index, drag.geometry)
      }
      this.renderLayoutOverlay()
      this.renderValidationWarnings()
    }

    saveInputGeometry (index, geometry) {
      if (!this.treema) { return }
      let saved = true
      for (const key of GEOMETRY_KEYS) {
        saved = this.treema.set(`/inputs/${index}/${key}`, geometry[key]) && saved
      }
      if (!saved) {
        // Treema could not reach the leaves (collapsed nodes, say), so hand it the whole array back.
        const inputs = this.getScenarioInputs()
        if (inputs[index]) {
          _.assign(inputs[index], geometry)
          this.treema.set('/inputs', inputs)
        }
      }
      this.updateVueComponent()
    }

    onWindowResize () {
      if (this.destroyed || !this.layoutMode) { return }
      this.renderLayoutOverlay()
    }

    // Validation ----------------------------------------------------------------

    getValidationWarnings () {
      if (!this.treema) { return [] }
      const scenario = this.treema.get('/') || {}
      const inputs = _.isArray(scenario.inputs) ? scenario.inputs : []
      const prompts = _.isArray(scenario.prompts) ? scenario.prompts : []
      const inputIds = _.compact(_.map(inputs, 'id'))
      const promptIds = _.compact(_.map(prompts, 'id'))
      const warnings = []

      for (const [id, count] of Object.entries(_.countBy(inputIds.concat(promptIds)))) {
        if (count > 1) {
          warnings.push(`The id "${id}" is used ${count} times; input and prompt ids should be unique.`)
        }
      }

      inputs.forEach((rawInput, index) => {
        const input = rawInput || {}
        const name = input.id || `input ${index}`
        if (!input.id) {
          warnings.push(`Input ${index} (${input.type || 'no type'}) has no id, so prompts and output templates cannot reference it.`)
        }
        if (!this.hasCompleteGeometry(input)) {
          const missing = GEOMETRY_KEYS.filter(key => !isPercent(input[key]))
          warnings.push(`Input "${name}" is missing geometry: ${missing.join(', ')}. Turn on layout mode to place it.`)
        }
      })

      for (const prompt of prompts) {
        const name = (prompt != null ? prompt.id : null) || 'unnamed prompt'
        for (const file of (prompt != null ? prompt.files : null) || []) {
          if (!inputIds.includes(file)) {
            warnings.push(`Prompt "${name}" includes file "${file}", which is not an input id.`)
          }
        }
      }

      const known = inputIds.concat(promptIds)
      for (const reference of this.getTemplateReferences(scenario.output != null ? scenario.output.html : null)) {
        if (!known.includes(reference)) {
          warnings.push(`Output HTML uses <%= ${reference} %>, which is neither a prompt id nor an input id. It will only resolve if a prompt returns it as a JSON key.`)
        }
      }

      return warnings
    }

    getTemplateReferences (html) {
      if (!_.isString(html)) { return [] }
      const references = []
      let match = TEMPLATE_REFERENCE.exec(html)
      while (match) {
        const expression = match[1].trim()
        if (BARE_IDENTIFIER.test(expression) && !references.includes(expression)) {
          references.push(expression)
        }
        match = TEMPLATE_REFERENCE.exec(html)
      }
      TEMPLATE_REFERENCE.lastIndex = 0
      return references
    }

    renderValidationWarnings () {
      const panel = this.$el.find('#scenario-validation')
      if (!panel.length) { return }
      const warnings = this.getValidationWarnings()
      panel.empty()
      if (!warnings.length) {
        return panel.removeClass('scenario-validation-active')
      }
      const list = $('<ul></ul>')
      for (const warning of warnings) {
        list.append($('<li></li>').text(warning))
      }
      return panel
        .addClass('scenario-validation-active')
        .append($('<h4></h4>').text(`${warnings.length} thing${warnings.length === 1 ? '' : 's'} to look at`))
        .append(list)
    }

    // ---------------------------------------------------------------------------

    onPopulateI18N () {
      this.scenario.populateI18N()
    }

    onClickSaveButton (e) {
      this.treema.endExistingEdits()
      for (const key in this.treema.data) {
        const value = this.treema.data[key]
        this.scenario.set(key, value)
      }
      this.scenario.updateI18NCoverage()

      const res = this.scenario.save()

      res.error((collection, response, options) => {
        console.error(response)
      })

      res.success(() => {
        const url = `/editor/ai-junior-scenario/${this.scenario.get('slug') || this.scenario.id}`
        document.location.href = url
      })
    }

    confirmDeletion () {
      const renderData = {
        title: 'Are you really sure?',
        body: 'This will completely delete the scenario.',
        decline: 'Not really',
        confirm: 'Definitely',
      }

      const confirmModal = new ConfirmModal(renderData)
      confirmModal.on('confirm', this.deleteAIJuniorScenario)
      this.openModalView(confirmModal)
    }

    deleteAIJuniorScenario () {
      $.ajax({
        type: 'DELETE',
        success () {
          noty({
            timeout: 5000,
            text: 'Aaaand it\'s gone.',
            type: 'success',
            layout: 'topCenter',
          })
          _.delay(() => application.router.navigate('/editor/ai-junior-scenario', { trigger: true })
            , 500)
        },
        error (jqXHR, status, error) {
          console.error(jqXHR)
          noty({
            timeout: 5000,
            text: `Deleting scenario message failed with error code ${jqXHR.status}`,
            type: 'error',
            layout: 'topCenter',
          })
        },
        url: `/db/ai_junior_scenario/${this.scenario.id}`,
      })
    }

    destroy () {
      $(document).off('.ai-junior-layout')
      $(window).off('resize.ai-junior-layout', this.onWindowResize)
      if (this.vueComponent) { this.vueComponent.$destroy() }
      return super.destroy()
    }
  }

  AIJuniorScenarioEditView.initClass()
  return AIJuniorScenarioEditView
})())
