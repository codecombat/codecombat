CocoView = require 'views/core/CocoView'
template = require 'templates/editor/level/tasks_tab'
Level = require 'models/Level'

module.exports = class TasksTabView extends CocoView
  id: 'editor-level-tasks-tab-view'
  className: 'tab-pane'
  template: template
  events:
    'click .taskRow': 'onTaskRowClicked'
    'click .taskInput': 'onTaskCompletionClicked'
    'click .startEdit': 'onTaskEditClicked'
    'click #createTask': 'onTaskCreateClicked'
    'keydown #curEdit': 'onCurEditKeyDown'

  subscriptions:
    'editor:level-loaded': 'onLevelLoaded'

  defaultTaskLinks:
    # Order doesn't matter.
    'Name the level.':'./'
    'Create a Referee stub, if needed.':'./'
    'Build the level.':'./'
    'Set up goals.':'./'
    'Choose the Existence System lifespan and frame rate.':'./'
    'Choose the UI System paths and coordinate hover if needed.':'./'
    'Choose the AI System pathfinding and Vision System line of sight.':'./'
    'Write the sample code.':'./'
    'Do basic set decoration.':'./'
    'Adjust script camera bounds.':'./'
    'Choose music file in Introduction script.':'./'
    'Choose autoplay in Introduction script.':'./'
    'Add to a campaign.':'./'
    'Publish.':'./'
    'Choose level options like required/restricted gear.':'./'
    'Create achievements, including unlocking next level.':'./'
    'Choose leaderboard score types.':'./'
    'Playtest with a slow/tough hero.':'./'
    'Playtest with a fast/weak hero.':'./'
    'Playtest with a couple random seeds.':'./'
    'Make sure the level ends promptly on success and failure.':'./'
    'Remove/simplify unnecessary doodad collision.':'./'
    'Release to adventurers via MailChimp.':'./'
    'Write the description.':'./'
    'Add i18n field for the sample code comments.':'./'
    'Add Clojure/Lua/CoffeeScript.':'./'
    'Write the guide.':'./'
    'Write a loading tip, if needed.':'./'
    'Click the Populate i18n button.':'./'
    'Add programming concepts covered.':'./'
    'Mark whether it requires a subscription.':'./'
    'Release to everyone via MailChimp.':'./'
    'Check completion/engagement/problem analytics.':'./'
    'Do thorough set decoration.':'./'
    'Add a walkthrough video.':'./'

  constructor: (options) ->
    super options
    @render()

  onLoaded: ->
  onLevelLoaded: (e) ->
    @level = e.level
    if e.level._revertAttributes
      @revertTasks = e.level._revertAttributes.tasks
    else
      @revertTasks = @level.get 'tasks'
    @tasks = @level.get 'tasks'
    @tTasks = _.clone @tasks, true
    for task in @tTasks
      if @revertTasks[_.findKey(@revertTasks, {'name':task.name})]
        task.reversion = @revertTasks[_.findKey(@revertTasks, {'name':task.name})].complete || null
      else
        task.reversion = false
    @render()
  
  getRenderData: ->
    c = super()
    c.tasks = @tasks
    c.status
    c

  pushTasks: ->
    for task in @tTasks
      taskKey = @findTaskByName(@tasks, task.name)
      oTaskKey = @findTaskByName(@tasks, task.oldName)
      if taskKey?
        @tasks[taskKey].complete = task.complete
      else if oTaskKey?
        if task.name is ''
          @tasks.splice(oTaskKey, 1)
          @tTasks.splice(@tTasks.indexOf(task), 1)
          break
          @pushTasks()
        else
          @tasks[oTaskKey].name = task.name
          @tasks[oTaskKey].complete = task.complete
      else
        if task.name is ''
          @tasks.splice(oTaskKey, 1)
          @tTasks.splice(@tTasks.indexOf(task), 1)
        else
          @tasks.push
            name: task.name
            complete: task.complete
    @level.set 'tasks', @tasks
    @parent.renderSelectors '#tasks-tab'

  onTaskRowClicked: (e) ->
    if not $(e.target).is('input') and not $(e.target).is('a') and not $(e.target).hasClass('startEdit')
      checkBox = $(e.currentTarget).find('.taskInput')[0]
      tTaskKey = @findTaskByName(@tTasks, @getData e)
      if tTaskKey?
        if checkBox.checked
          checkBox.checked = false
        else
          checkBox.checked = true
        console.log(checkBox.checked)
        @tTasks[tTaskKey].complete = checkBox.checked
      @pushTasks()

  onTaskCompletionClicked: (e) ->
    tTaskKey = @findTaskByName(@tTasks, @getData e)
    if tTaskKey?
      @tTasks[tTaskKey].complete = e.currentTarget.checked
    @pushTasks()

  onTaskCreateClicked: (e) ->
    if $('#curEdit').length is 0
      @tTasks.push
        name: ''
        complete: false
        reversion: false
        curEdit: true
      @render()
    editDiv = $('#curEdit')[0]
    editDiv.focus()
    len = editDiv.value.length * 2
    editDiv.setSelectionRange len, len

  onCurEditKeyDown: (e) ->
    editDiv = $('#curEdit')[0]
    if e.keyCode is 13
      taskIndex = @findTaskByName(@tasks, editDiv.value)
      tTaskIndex = _.findKey(@tTasks, {'curEdit':true})
      if taskIndex? and tTaskIndex? and taskIndex isnt tTaskIndex
        noty
          timeout: 5000
          text: 'Task with name already exists.'
          type: 'error'
          layout: 'topCenter'
      else
        @tTasks[tTaskIndex].oldName = @tTasks[tTaskIndex].name
        @tTasks[tTaskIndex].name = curEdit.value
        @tTasks[tTaskIndex].curEdit = false

      @pushTasks()
      @render()

  onTaskEditClicked: (e) ->
    if $('#curEdit').length is 0
      taskIndex = @findTaskByName(@tTasks, @getData e)
      @tTasks[taskIndex].curEdit = true
      @render()
    editDiv = $('#curEdit')[0]
    editDiv.focus()
    len = editDiv.value.length * 2
    editDiv.setSelectionRange len, len

  findTaskByName: (obj, name) ->
    return _.findKey(obj, {'name':name})

  getData: (elem) ->
    return elem.currentTarget.getAttribute('data')

    