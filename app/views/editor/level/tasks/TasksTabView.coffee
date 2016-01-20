CocoView = require 'views/core/CocoView'
template = require 'templates/editor/level/tasks-tab'
Level = require 'models/Level'

module.exports = class TasksTabView extends CocoView
  id: 'editor-level-tasks-tab-view'
  className: 'tab-pane'
  template: template
  events:
    'click .taskRow': 'onClickTaskRow'
    'click .taskInput': 'onClickTaskInput'
    'click .startEdit': 'onClickStartEdit'
    'click #createTask': 'onClickCreateTask'
    'keydown #curEdit': 'onKeyDownCurEdit'

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

  taskMap: ->
    return @tasks?.map((_obj) -> return (name: _obj.get('name'), complete: (_obj.get('complete') || false)))

  taskArray: ->
    return @tasks?.toArray()

  findTask: (_name) ->
    return @tasks.findWhere(name:_name)

  onLoaded: ->
  onLevelLoaded: (e) ->
    @level = e.level
    Task = Backbone.Model.extend({
      initialize: ->
        if e?.level?._revertAttributes?.tasks?
          if _.find(e.level._revertAttributes.tasks, {name:arguments[0].name})
            @set 'revert', _.find(e.level._revertAttributes.tasks, {name:arguments[0].name})
          else
            @set 'revert', arguments[0]
        else
          @set 'revert', arguments[0]
    })
    TaskList = Backbone.Collection.extend({
      model: Task
    })
    @tasks = new TaskList(@level.get 'tasks')
    @render()


  pushTasks: ->
    @level.set 'tasks', @taskMap()

  onClickTaskRow: (e) ->
    if not $(e.target).is('input') and not $(e.target).is('a') and not $(e.target).hasClass('startEdit')
      task = @findTask($(e.target).closest('tr').data('task').name)
      checkbox = $(e.currentTarget).find('.taskInput')[0]
      if task.get 'complete'
        task.set 'complete', false
      else
        task.set 'complete', true
      checkbox.checked = task.get 'complete'
      @pushTasks()

  onClickTaskInput: (e) ->
    task = @findTask($(e.target).closest('tr').data('task').name)
    task.set 'complete', e.currentTarget.checked
    @pushTasks()

  onClickStartEdit: (e) ->
    if $('#curEdit').length is 0
      task = @findTask($(e.target).closest('tr').data('task').name)
      task.set 'curEdit', true
      @render()
    editDiv = $('#curEdit')[0]
    editDiv.focus()
    len = editDiv.value.length * 2
    editDiv.setSelectionRange len, len

  onKeyDownCurEdit: (e) ->
    if e.keyCode is 13
      editDiv = $('#curEdit')[0]
      task = @findTask($(e.target).closest('tr').data('task').name)
      potentialTask = @findTask(editDiv.value)
      if potentialTask and potentialTask isnt task
        noty
          timeout: 5000
          text: 'Task with name already exists!'
          type: 'error'
          layout: 'topCenter'
      else if editDiv.value is ''
        @tasks.remove task
        @pushTasks()
        @render()
      else
        task.set 'name', editDiv.value
        task.set 'curEdit', false
        @pushTasks()
        @render()

  onClickCreateTask: (e) ->
    if $('#curEdit').length is 0
      @tasks.add
        name: ''
        complete: false
        curEdit: true
        revert:
          name: 'null'
          complete: false
      @render()
    editDiv = $('#curEdit')[0]
    editDiv.focus()
    len = editDiv.value.length * 2
    editDiv.setSelectionRange len, len
