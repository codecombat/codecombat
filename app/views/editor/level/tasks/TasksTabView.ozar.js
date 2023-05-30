// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS103: Rewrite code to no longer use __guard__, or convert again using --optional-chaining
 * DS104: Avoid inline assignments
 * DS204: Change includes calls to have a more natural evaluation order
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let TasksTabView;
import 'app/styles/editor/level/tasks-tab.sass';
import CocoView from 'views/core/CocoView';
import template from 'app/templates/editor/level/tasks-tab';
import Level from 'models/Level';

export default TasksTabView = (function() {
  TasksTabView = class TasksTabView extends CocoView {
    static initClass() {
      this.prototype.id = 'editor-level-tasks-tab-view';
      this.prototype.className = 'tab-pane';
      this.prototype.template = template;
      this.prototype.events = {
        'click .task-row': 'onClickTaskRow',
        'click .task-input': 'onClickTaskInput',
        'click .start-edit': 'onClickStartEdit',
        'click #create-task': 'onClickCreateTask',
        'keydown #cur-edit': 'onKeyDownCurEdit',
        'blur #cur-edit': 'onBlurCurEdit'
      };
  
      this.prototype.subscriptions =
        {'editor:level-loaded': 'onLevelLoaded'};
    }

    applyTaskName(_task, _input) {
      const name = _input.value;
      const potentialTask = this.tasks.findWhere({'name':_input});
      if (potentialTask && (potentialTask !== _task)) {
        noty({
          timeout: 5000,
          text: 'Task with name already exists!',
          type: 'error',
          layout: 'topCenter'
        });
        return _input.focus();
      } else if (name === '') {
        this.tasks.remove(_task);
        this.pushTasks();
        return this.render();
      } else {
        _task.set('name', name);
        _task.set('curEdit', false);
        this.pushTasks();
        return this.render();
      }
    }

    focusEditInput() {
      const editInput = this.$('#cur-edit')[0];
      if (editInput) {
        editInput.focus();
        const len = editInput.value.length * 2;
        return editInput.setSelectionRange(len, len);
      }
    }

    getTaskByCID(_cid) {
      return this.tasks.get(_cid);
    }

    taskMap() {
      return this.tasks != null ? this.tasks.map(_obj => ({
        name: _obj.get('name'),
        complete: (_obj.get('complete') || false)
      })) : undefined;
    }

    taskArray() {
      return (this.tasks != null ? this.tasks.toArray() : undefined);
    }

    onLevelLoaded(e) {
      this.level = e.level;
      this.defaultTasks = tasksForLevel(this.level);
      this.level.set('tasks', _.clone(this.defaultTasks));
      const Task = Backbone.Model.extend({
        initialize() {
          // We want to keep track of the revertAttributes easily without digging back into the level every time.
          // So per TaskModel we check to see if there is a revertAttribute associated with the task's name.
          // If there is a reversion available, we use it, otherwise (e.g. new tasks without a reversion) we just use the Task's current name/completion status.
          if (__guard__(__guard__(e != null ? e.level : undefined, x1 => x1._revertAttributes), x => x.tasks) != null) {
            if (_.find(e.level._revertAttributes.tasks, {name:arguments[0].name})) {
              return this.set('revert', _.find(e.level._revertAttributes.tasks, {name:arguments[0].name}));
            } else {
              return this.set('revert', arguments[0]);
            }
          } else {
            return this.set('revert', arguments[0]);
          }
        }
      });
      const TaskList = Backbone.Collection.extend({
        model: Task
      });
      this.tasks = new TaskList(this.level.get('tasks'));
      this.pushTasks();
      return this.render();
    }

    pushTasks() {
      return this.level.set('tasks', this.taskMap());
    }

    onClickTaskRow(e) {
      if (!$(e.target).is('input') && !$(e.target).is('a') && !$(e.target).hasClass('start-edit') && (this.$('#cur-edit').length === 0)) {
        const task = this.tasks.get($(e.target).closest('tr').data('task-cid'));
        const checkbox = $(e.currentTarget).find('.task-input')[0];
        if (task.get('complete')) {
          task.set('complete', false);
        } else {
          task.set('complete', true);
        }
        checkbox.checked = task.get('complete');
        return this.pushTasks();
      }
    }

    onClickTaskInput(e) {
      const task = this.tasks.get($(e.target).closest('tr').data('task-cid'));
      task.set('complete', e.currentTarget.checked);
      return this.pushTasks();
    }

    onClickStartEdit(e) {
      if (this.$('#cur-edit').length === 0) {
        const task = this.tasks.get($(e.target).closest('tr').data('task-cid'));
        task.set('curEdit', true);
        this.render();
        return this.focusEditInput();
      }
    }

    onKeyDownCurEdit(e) {
      if (e.keyCode === 13) {
        const editInput = this.$('#cur-edit')[0];
        return editInput.blur();
      }
    }

    onBlurCurEdit(e) {
      const editInput = this.$('#cur-edit')[0];
      const task = this.tasks.get($(e.target).closest('tr').data('task-cid'));
      return this.applyTaskName(task, editInput);
    }

    onClickCreateTask(e) {
      if (this.$('#cur-edit').length === 0) {
        this.tasks.add({
          name: '',
          complete: false,
          curEdit: true,
          revert: {
            name: 'null',
            complete: false
          }
        });
        this.render();
        return this.focusEditInput();
      }
    }

    getTaskURL(_n) {
      if (_.find(this.defaultTasks, {name:_n}) != null) {
        return _.string.slugify(_n);
      }
      return null;
    }
  };
  TasksTabView.initClass();
  return TasksTabView;
})();


const notIntros = ['hero', 'course', 'hero-ladder', 'course-ladder', 'game-dev'];
const heroBased = ['hero', 'course', 'hero-ladder', 'course-ladder'];
const ladder = ['hero-ladder', 'course-ladder'];

const defaultTasks = [
  {name: '--PROTOTYPE--', types: notIntros},
  {name: 'Set level type', },
  {name: 'Create base layout', types: heroBased},
  {name: 'Define Movement system', types: heroBased},
  {name: 'Setup the Hero Placeholder', types: heroBased},
  {name: 'Base instruction through scripts', types: notIntros},
  {name: 'Sample code combined with solution', types: notIntros},
  {name: 'Level is Published', complete(level) { return level.isPublished(); }},
  {name: 'Setup main game goals', types: heroBased},
  {name: 'Game and unit logic', types: notIntros},
  {name: 'Set Existence/Random type', types: notIntros},
  {name: 'Set timespan for level and framerate', types: notIntros},
  {name: 'Setup camera (size and bounds)', types: heroBased},
  {name: 'Check the slug'},
  {name: 'Set ozariaType.', types: notIntros},
  {name: 'Playtest prototype to be sure it\'s playable', types: notIntros},

  {name: '--IMPLEMENTATION--', types: notIntros},
  {name: 'Apply Prototype feedback', types: notIntros},
  {name: 'Added Learning Goals', types: heroBased},
  {name: 'Write Display Name'},
  {name: 'Added Intermediate/concept goals', types: heroBased},
  {name: 'Setup the clear sample code', types: heroBased},
  {name: 'Add solution', types: heroBased},
  {name: 'Set draft decorations', types: heroBased},
  {name: 'Set Code Bank', types: heroBased},
  {name: 'Move to components logic that can be moved', types: heroBased},
  {name: 'Playtest functional level to be sure it\'s playable', types: heroBased},

  {name: '--POLISHING--', types: notIntros},
  {name: 'Update Outlines for the level (layout, code, description)', types: notIntros},
  {name: 'Put final art/assets', types: notIntros},
  {name: 'Added Hints through scripts', types: heroBased},
  {name: 'Added Tutorial', types: heroBased},
  {name: 'Check and remove redundant collision and special zones', types: heroBased},
  {name: 'Programming concepts', types: notIntros},
  {name: 'Choose music', types: notIntros},
  {name: 'Clear code from prints/asserts', types: notIntros},
  {name: 'Setup solution verifier', types: notIntros},

  {name: '--AFTERMATH--', types: notIntros},
  {name: 'Playtest as a student', types: notIntros},
  {name: 'Add more tests for verifier', types: heroBased},
  {name: 'Populate i18n'}
];

const deprecatedTaskNames = [
  'Add Io/Clojure/Lua/CoffeeScript.',
  'Add Lua/CoffeeScript/Java.',
  'Translate the sample code comments.',
  'Add i18n field for the sample code comments.',
  'Check completion/engagement/problem analytics.',
  'Add a walkthrough video.',
  'Do any custom scripting, if needed.',
  'Write a really awesome description.',
  'Name the level.',
  'Create a Referee stub, if needed.',
  'Replace "Hero Placeholder" with mcp.',
  'Do basic set decoration.',
  'Publish.',
  'Choose the Existence System lifespan and frame rate.',
  'Choose the UI System paths and coordinate hover if needed.',
  'Choose the AI System pathfinding and Vision System line of sight.',
  'Build the level.',
  'Set up goals.',
  'Add the "win-game" goal.',
  'Write the sample code.',
  'Write the solution.',
  'Make both teams playable and non-defaulted.',
  'Set up goals for both teams.',
  'Fill out the sample code for both Hero Placeholders.',
  'Fill out default AI for both Hero Placeholders.',
  'Make sure the level ends promptly on success and failure.',
  'Adjust script camera bounds.',
  'Choose music file in Introduction script.',
  'Choose autoplay in Introduction script.',
  'Write the description.',
  'Write the guide.',
  'Write intro guide.',
  'Write a loading tip, if needed.',
  'Add programming concepts covered.',
  'Set level kind.',
  'Mark whether it requires a subscription.',
  'Choose leaderboard score types.',
  'Do thorough set decoration.',
  'Playtest with a slow/tough hero.',
  'Playtest with a fast/weak hero.',
  'Playtest with a couple random seeds.',
  'Remove/simplify unnecessary doodad collision.',
  'Add to a campaign.',
  'Choose level options like required/restricted gear.',
  'Create achievements, including unlocking next level.',
  'Configure the hero\'s expected equipment.',
  'Configure the API docs.',
  'Write victory text.',
  'Write level hints.',
  'Set up solutions for the Verifier.',
  'Click the Populate i18n button.',
  'Add slug to ladder levels that should be simulated, if needed.',
  'Write the advanced AIs (shaman, brawler, chieftain, etc).',
  'Add achievements for defeating the advanced AIs.',
  'Release to adventurers.',
  'Release to everyone.',
  'Create two sample projects.',
  'Write Lua sample code.',
  'Write Java sample code.',
  'Write CoffeeScript sample code.',
  'Write Lua solution.',
  'Write Java solution.',
  'Write CoffeeScript solution.'
];

const renamedTaskNames = {
};

var tasksForLevel = function(level) {
  let left, oldTask, task;
  const tasks = [];
  const inappropriateTasks = {};
  for (task of Array.from(defaultTasks)) {
    var needle;
    if (task.types && (((needle = level.get('realType') || level.get('type', true)), !Array.from(task.types).includes(needle)))) {
      inappropriateTasks[task.name] = task;
    } else {
      tasks.push(task);
    }
  }
  const oldTasks = ((left = level.get('tasks')) != null ? left : []).slice();
  const newTasks = [];
  for (task of Array.from(tasks)) {
    var complete;
    var oldName = renamedTaskNames[task.name] || task.name;
    if (oldTask = (_.find(oldTasks, {name: oldName}) || _.find(oldTasks, {name: task.name}))) {
      complete = oldTask.complete || Boolean(typeof task.complete === 'function' ? task.complete(level) : undefined);
      _.remove(oldTasks, {name: oldTask.name});
    } else {
      complete = Boolean(typeof task.complete === 'function' ? task.complete(level) : undefined);
      if (!complete && task.optional) { continue; }
    }
    newTasks.push({name: task.name, complete});
  }
  for (oldTask of Array.from(oldTasks)) {
    if (!Array.from(deprecatedTaskNames).includes(oldTask.name) && !inappropriateTasks[oldTask.name]) {
      newTasks.push(oldTask);
    }
  }
  return newTasks;
};

function __guard__(value, transform) {
  return (typeof value !== 'undefined' && value !== null) ? transform(value) : undefined;
}