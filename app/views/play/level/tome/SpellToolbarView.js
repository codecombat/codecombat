/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS103: Rewrite code to no longer use __guard__, or convert again using --optional-chaining
 * DS104: Avoid inline assignments
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let SpellToolbarView;
const CocoView = require('views/core/CocoView');
const template = require('app/templates/play/level/tome/spell_toolbar');

module.exports = (SpellToolbarView = (function() {
  SpellToolbarView = class SpellToolbarView extends CocoView {
    static initClass() {
      this.prototype.className = 'spell-toolbar-view';
      this.prototype.template = template;
      this.prototype.progressHoverDelay = 500;
  
      this.prototype.subscriptions = {
        'tome:spell-step-backward': 'onStepBackward',
        'tome:spell-step-forward': 'onStepForward'
      };
  
      this.prototype.events = {
        'mousedown .spell-progress': 'onProgressMouseDown',
        'mouseup .spell-progress': 'onProgressMouseUp',
        'mousemove .spell-progress': 'onProgressMouseMove',
        'tapstart .spell-progress': 'onProgressTapStart',
        'tapend .spell-progress': 'onProgressTapEnd',
        'tapmove .spell-progress': 'onProgressTapMove',
        'click .step-backward': 'onStepBackward',
        'click .step-forward': 'onStepForward'
      };
    }

    constructor(options) {
      super(options);
      this.ace = options.ace;
    }

    afterRender() {
      return super.afterRender();
    }

    toggleFlow(to) {
      return this.$el.find('.flow').toggle(to);
    }

    setStatementIndex(statementIndex) {
      let total;
      if (!(total = this.callState != null ? this.callState.statementsExecuted : undefined)) { return; }
      this.statementIndex = Math.min(total - 1, Math.max(0, statementIndex));
      this.statementRatio = this.statementIndex / (total - 1);
      this.statementTime = (this.callState.statements[this.statementIndex] != null ? this.callState.statements[this.statementIndex].userInfo.time : undefined) != null ? (this.callState.statements[this.statementIndex] != null ? this.callState.statements[this.statementIndex].userInfo.time : undefined) : 0;
      this.$el.find('.progress-bar').css('width', (100 * this.statementRatio) + '%');
      this.$el.find('.step-backward').prop('disabled', this.statementIndex === 0);
      this.$el.find('.step-forward').prop('disabled', this.statementIndex === (total - 1));
      this.updateMetrics();
      return _.defer(() => {
        return Backbone.Mediator.publish('tome:spell-statement-index-updated', {statementIndex: this.statementIndex, ace: this.ace});
      });
    }

    updateMetrics() {
      const {
        statementsExecuted
      } = this.callState;
      const $metrics = this.$el.find('.metrics');
      if (this.suppressMetricsUpdates || !(statementsExecuted || this.metrics.statementsExecuted)) { return $metrics.hide(); }
      if (this.metrics.callsExecuted > 1) {
        $metrics.find('.call-index').text(this.callIndex + 1);
        $metrics.find('.calls-executed').text(this.metrics.callsExecuted);
        $metrics.find('.calls-metric').show().attr('title', `Method call ${this.callIndex + 1} of ${this.metrics.callsExecuted} calls`);
      } else {
        $metrics.find('.calls-metric').hide();
      }
      if (this.metrics.statementsExecuted) {
        let titleSuffix;
        $metrics.find('.statement-index').text(this.statementIndex + 1);
        $metrics.find('.statements-executed').text(statementsExecuted);
        if (this.metrics.statementsExecuted > statementsExecuted) {
          $metrics.find('.statements-executed-total').text(` (${this.metrics.statementsExecuted})`);
          titleSuffix = ` (${this.metrics.statementsExecuted} statements total)`;
        } else {
          $metrics.find('.statements-executed-total').text('');
          titleSuffix = '';
        }
        $metrics.find('.statements-metric').show().attr('title', `Statement ${this.statementIndex + 1} of ${statementsExecuted} this call${titleSuffix}`);
      } else {
        $metrics.find('.statements-metric').hide();
      }
      const left = this.$el.find('.scrubber-handle').position().left + this.$el.find('.spell-progress').position().left;
      return $metrics.finish().show().css({left: left - ($metrics.width() / 2)}).delay(2000).fadeOut('fast');
    }

    setStatementRatio(ratio) {
      let total;
      if (!(total = this.callState != null ? this.callState.statementsExecuted : undefined)) { return; }
      const statementIndex = Math.floor(ratio * total);
      if (statementIndex !== this.statementIndex) { return this.setStatementIndex(statementIndex); }
    }

    onProgressMouseDown(e) {
      this.dragging = true;
      this.scrubProgress(e);
      return Backbone.Mediator.publish('level:set-playing', {playing: false});
    }

    onProgressMouseUp(e) {
      return this.dragging = false;
    }

    onProgressMouseMove(e) {
      if (!this.dragging) { return; }
      return this.scrubProgress(e);
    }

    onProgressTapStart(e, touchData) {
      // Haven't tested tap versions, don't even need them for iPad app, but hey, it worked for the playback scrubber.
      this.dragging = true;
      return this.scrubProgress(e, touchData);
    }

    onProgressTapEnd(e, touchData) {
      return this.dragging = false;
    }

    onProgressTapMove(e, touchData) {
      if (!this.dragging) { return; }
      return this.scrubProgress(e, touchData);
    }

    scrubProgress(e, touchData) {
      let left;
      const screenOffsetX = (left = e.clientX != null ? e.clientX : (touchData != null ? touchData.position.x : undefined)) != null ? left : 0;
      let offsetX = screenOffsetX - this.$el.find('.spell-progress').offset().left;
      offsetX = Math.max(offsetX, 0);
      this.setStatementRatio(offsetX / this.$el.find('.spell-progress').width());
      this.updateTime();
      return this.updateScroll();
    }

    onStepBackward(e) { return this.step(-1); }
    onStepForward(e) { return this.step(1); }
    step(delta) {
      const lastTime = this.statementTime;
      this.setStatementIndex(this.statementIndex + delta);
      if (this.statementTime !== lastTime) { this.updateTime(); }
      this.updateScroll();
      return Backbone.Mediator.publish('level:set-playing', {playing: false});
    }

    updateTime() {
      this.maintainIndexScrub = true;
      if (this.maintainIndexScrubTimeout) { clearTimeout(this.maintainIndexScrubTimeout); }
      this.maintainIndexScrubTimeout = _.delay((() => { return this.maintainIndexScrub = false; }), 500);
      return Backbone.Mediator.publish('level:set-time', {time: this.statementTime, scrubDuration: 500});
    }

    updateScroll() {
      let statementStart;
      if (!(statementStart = __guard__(__guard__(this.callState != null ? this.callState.statements : undefined, x1 => x1[this.statementIndex]), x => x.range[0]))) { return; }
      const text = this.ace.getValue(); // code in editor
      const currentLine = statementStart.row;
      return this.ace.scrollToLine(currentLine, true, true);
    }

    setCallState(callState, statementIndex, callIndex, metrics) {
      this.callIndex = callIndex;
      this.metrics = metrics;
      if ((callState === this.callState) && (statementIndex === this.statementIndex)) { return; }
      if (!(this.callState = callState)) { return; }
      this.suppressMetricsUpdates = true;
      if (!this.maintainIndexScrub && !this.dragging && (statementIndex != null) && ((callState.statements[statementIndex] != null ? callState.statements[statementIndex].userInfo.time : undefined) !== this.statementTime)) {
        this.setStatementIndex(statementIndex);
      } else {
        this.setStatementRatio(this.statementRatio);
      }
      return this.suppressMetricsUpdates = false;
    }
  };
  SpellToolbarView.initClass();
  return SpellToolbarView;
})());

function __guard__(value, transform) {
  return (typeof value !== 'undefined' && value !== null) ? transform(value) : undefined;
}