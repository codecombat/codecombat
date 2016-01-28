CocoView = require 'views/core/CocoView'
template = require 'templates/editor/level/tasks-tab'
Level = require 'models/Level'

module.exports = class TasksTabView extends CocoView
  id: 'editor-level-tasks-tab-view'
  className: 'tab-pane'
  template: template
  events:
    'click .task-row': 'onClickTaskRow'
    'click .task-input': 'onClickTaskInput'
    'click .start-edit': 'onClickStartEdit'
    'click #create-task': 'onClickCreateTask'
    'keydown #cur-edit': 'onKeyDownCurEdit'
    'blur #cur-edit': 'onBlurCurEdit'
    'click #add-default-tasks': 'onClickAddDefaultTasks'

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

  missingDefaults: ->
    missingTasks = []
    if @level
      for task in @level.schema().properties.tasks.default
        unless _.findIndex(@level.get('tasks'), {name: task.name}) isnt -1
          missingTasks.push task
    return missingTasks

  onClickAddDefaultTasks: ->
    results = @missingDefaults()
    for result in results
      @tasks.add
        name: result.name
        complete: result.complete
        curEdit: false
        revert:
          name: result.name
          complete: false
    @pushTasks()
    @render()

  applyTaskName: (_task, _input) ->
    name = _input.value
    potentialTask = @tasks.findWhere({'name':_input})
    if potentialTask and potentialTask isnt _task
      noty
        timeout: 5000
        text: 'Task with name already exists!'
        type: 'error'
        layout: 'topCenter'
      _input.focus()
    else if name is ''
      @tasks.remove _task
      @pushTasks()
      @render()
    else
      _task.set 'name', name
      _task.set 'curEdit', false
      @pushTasks()
      @render()

  focusEditInput: ->
    editInput = @$el.find('#cur-edit')[0]
    if editInput
      editInput.focus()
      len = editInput.value.length * 2
      editInput.setSelectionRange len, len

  getTaskByCID: (_cid) ->
    return @tasks.get _cid

  taskMap: ->
    return @tasks?.map((_obj) -> return (name: _obj.get('name'), complete: (_obj.get('complete') || false)))

  taskArray: ->
    return @tasks?.toArray()

  onLevelLoaded: (e) ->
    @level = e.level
    Task = Backbone.Model.extend({
      initialize: ->
        # We want to keep track of the revertAttributes easily without digging back into the level every time.
        # So per TaskModel we check to see if there is a revertAttribute associated with the task's name.
        # If there is a reversion available, we use it, otherwise (e.g. new tasks without a reversion) we just use the Task's current name/completion status.
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
    if not @$el.find(e.target).is('input') and not @$el.find(e.target).is('a') and not @$el.find(e.target).hasClass('start-edit') and @$el.find('#cur-edit').length is 0
      task = @tasks.get @$el.find(e.target).closest('tr').data('task-cid')
      checkbox = @$el.find(e.currentTarget).find('.task-input')[0]
      if task.get 'complete'
        task.set 'complete', false
      else
        task.set 'complete', true
      checkbox.checked = task.get 'complete'
      @pushTasks()

  onClickTaskInput: (e) ->
    task = @tasks.get @$el.find(e.target).closest('tr').data('task-cid')
    task.set 'complete', e.currentTarget.checked
    @pushTasks()

  onClickStartEdit: (e) ->
    if @$el.find('#cur-edit').length is 0
      task = @tasks.get @$el.find(e.target).closest('tr').data('task-cid')
      task.set 'curEdit', true
      @render()
      @focusEditInput()

  onKeyDownCurEdit: (e) ->
    if e.keyCode is 13
      editInput = @$el.find('#cur-edit')[0]
      editInput.blur()

  onBlurCurEdit: (e) ->
    editInput = @$el.find('#cur-edit')[0]
    task = @tasks.get @$el.find(e.target).closest('tr').data('task-cid')
    @applyTaskName(task, editInput)

  onClickCreateTask: (e) ->
    if @$el.find('#cur-edit').length is 0
      @tasks.add
        name: ''
        complete: false
        curEdit: true
        revert:
          name: 'null'
          complete: false
      @render()
      @focusEditInput()
