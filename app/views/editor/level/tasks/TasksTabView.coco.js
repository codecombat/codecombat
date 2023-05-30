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
require('app/styles/editor/level/tasks-tab.sass');
const CocoView = require('views/core/CocoView');
const template = require('app/templates/editor/level/tasks-tab');
const Level = require('models/Level');

module.exports = (TasksTabView = (function() {
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
})());


const notWebDev = ['hero', 'course', 'hero-ladder', 'course-ladder', 'game-dev'];
const heroBased = ['hero', 'course', 'hero-ladder', 'course-ladder'];
const ladder = ['hero-ladder', 'course-ladder', 'ladder'];

const defaultTasks = [
  {name: 'Set level type.', complete(level) { return level.get('type'); }},
  {name: 'Name the level.'},
  {name: 'Create a Referee stub, if needed.', types: notWebDev},
  {name: 'Replace "Hero Placeholder" with mcp.', types: ['game-dev']},
  {name: 'Do basic set decoration.', types: notWebDev},
  {name: 'Publish.', complete(level) { return level.isPublished(); }},
  {name: 'Choose the Existence System lifespan and frame rate.', types: notWebDev},
  {name: 'Choose the UI System paths and coordinate hover if needed.', types: notWebDev},
  {name: 'Choose the AI System pathfinding and Vision System line of sight.', types: notWebDev},
  {name: 'Build the level.'},
  {name: 'Set up goals.'},
  {name: 'Add the "win-game" goal.', types: ['game-dev']},
  {name: 'Write the sample code.', complete(level) { if (level.isType('web-dev')) { return level.getSampleCode().html; } else { return level.getSampleCode().javascript && level.getSampleCode().python; } }},
  {name: 'Write the solution.', complete(level) { if (level.isType('web-dev')) { return _.find(level.getSolutions(), {language: 'html'}); } else { return _.find(level.getSolutions(), {language: 'javascript'}) && _.find(level.getSolutions(), {language: 'python'}); } }},
  {name: 'Make both teams playable and non-defaulted.', types: ladder},
  {name: 'Set up goals for both teams.', types: ladder},
  {name: 'Fill out the sample code for both Hero Placeholders.', types: ladder},
  {name: 'Fill out default AI for both Hero Placeholders.', types: ladder},
  {name: 'Make sure the level ends promptly on success and failure.'},
  {name: 'Adjust script camera bounds.', types: notWebDev},
  {name: 'Choose music file in Introduction script.', types: notWebDev},
  {name: 'Choose autoplay in Introduction script.', types: heroBased},
  {name: 'Write the description.'},
  {name: 'Write the guide.'},
  {name: 'Write intro guide.'},
  {name: 'Write a loading tip, if needed.', complete(level) { return level.get('loadingTip'); }},
  {name: 'Add programming concepts covered.'},
  {name: 'Set level kind.', complete(level) { return level.get('kind'); }},
  {name: 'Mark whether it requires a subscription.', complete(level) { return (level.get('requiresSubscription') != null); }},
  {name: 'Choose leaderboard score types.', types: ['hero', 'course'], complete(level) { return (level.get('scoreTypes') != null); }},
  {name: 'Do thorough set decoration.', types: notWebDev},
  {name: 'Playtest with a slow/tough hero.', types: ['hero', 'hero-ladder']},
  {name: 'Playtest with a fast/weak hero.', types: ['hero', 'hero-ladder']},
  {name: 'Playtest with a couple random seeds.', types: heroBased},
  {name: 'Remove/simplify unnecessary doodad collision.', types: notWebDev},
  {name: 'Add to a campaign.'},
  {name: 'Choose level options like required/restricted gear.', types: ['hero', 'hero-ladder']},
  {name: 'Create achievements, including unlocking next level.'},
  {name: 'Configure the hero\'s expected equipment.', types: ['hero', 'course', 'course-ladder']},
  {name: 'Configure the API docs.', types: ['web-dev', 'game-dev']},
  {name: 'Write victory text.', complete(level) { return __guard__(level.get('victory'), x => x.body); }},
  {name: 'Write level hints.'},
  {name: 'Set up solutions for the Verifier.'},
  {name: 'Click the Populate i18n button.'},
  {name: 'Add slug to ladder levels that should be simulated, if needed.', types: ladder},
  {name: 'Write the advanced AIs (shaman, brawler, chieftain, etc).', types: ladder},
  {name: 'Add achievements for defeating the advanced AIs.', types: ['hero-ladder']},
  {name: 'Release to adventurers.'},
  {name: 'Release to everyone.'},
  {name: 'Create two sample projects.', types: ['game-dev', 'web-dev']}
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
  'Write Lua sample code.',
  'Write Java sample code.',
  'Write C++ sample code.',
  'Write CoffeeScript sample code.',
  'Write Lua solution.',
  'Write Java solution.',
  'Write C++ solution.',
  'Write CoffeeScript solution.'
];

const renamedTaskNames = {
  'Release to adventurers.': 'Release to adventurers via MailChimp.',
  'Release to everyone.': 'Release to everyone via MailChimp.'
};

var tasksForLevel = function(level) {
  let left, oldTask, task;
  const tasks = [];
  const inappropriateTasks = {};
  for (task of Array.from(defaultTasks)) {
    var needle;
    if ((task.name === 'Create two sample projects') && (level.get('shareable') !== 'project')) {
      inappropriateTasks[task.name] = task;
    } else if (task.types && (((needle = level.get('realType') || level.get('type', true)), !Array.from(task.types).includes(needle)))) {
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