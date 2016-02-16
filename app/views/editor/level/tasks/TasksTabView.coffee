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
    editInput = @$('#cur-edit')[0]
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
    @defaultTasks = @level.schema().properties.tasks.default
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
    if not $(e.target).is('input') and not $(e.target).is('a') and not $(e.target).hasClass('start-edit') and @$('#cur-edit').length is 0
      task = @tasks.get $(e.target).closest('tr').data('task-cid')
      checkbox = $(e.currentTarget).find('.task-input')[0]
      if task.get 'complete'
        task.set 'complete', false
      else
        task.set 'complete', true
      checkbox.checked = task.get 'complete'
      @pushTasks()

  onClickTaskInput: (e) ->
    task = @tasks.get $(e.target).closest('tr').data('task-cid')
    task.set 'complete', e.currentTarget.checked
    @pushTasks()

  onClickStartEdit: (e) ->
    if @$('#cur-edit').length is 0
      task = @tasks.get $(e.target).closest('tr').data('task-cid')
      task.set 'curEdit', true
      @render()
      @focusEditInput()

  onKeyDownCurEdit: (e) ->
    if e.keyCode is 13
      editInput = @$('#cur-edit')[0]
      editInput.blur()

  onBlurCurEdit: (e) ->
    editInput = @$('#cur-edit')[0]
    task = @tasks.get $(e.target).closest('tr').data('task-cid')
    @applyTaskName(task, editInput)

  onClickCreateTask: (e) ->
    if @$('#cur-edit').length is 0
      @tasks.add
        name: ''
        complete: false
        curEdit: true
        revert:
          name: 'null'
          complete: false
      @render()
      @focusEditInput()

  getTaskURL: (_n) ->
    if _.find(@defaultTasks, {name:_n})?
      return _.string.slugify(_n)
    return null
