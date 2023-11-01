/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let LevelHUDView;
require('app/styles/play/level/hud.sass');
const CocoView = require('views/core/CocoView');
const template = require('app/templates/play/level/hud');
const prop_template = require('app/templates/play/level/hud_prop');
const utils = require('core/utils');

module.exports = (LevelHUDView = (function() {
  LevelHUDView = class LevelHUDView extends CocoView {
    static initClass() {
      this.prototype.id = 'thang-hud';
      this.prototype.template = template;
  
      this.prototype.subscriptions = {
        'surface:frame-changed': 'onFrameChanged',
        'level:disable-controls': 'onDisableControls',
        'level:enable-controls': 'onEnableControls',
        'surface:sprite-selected': 'onSpriteSelected',
        'sprite:thang-began-talking': 'onThangBeganTalking',
        'sprite:thang-finished-talking': 'onThangFinishedTalking',
        'god:new-world-created': 'onNewWorld'
      };
  
      this.prototype.events =
        {'click': 'onClick'};
    }

    afterRender() {
      super.afterRender();
      this.$el.addClass('no-selection');
      if (this.options.level.get('hidesHUD')) {
        this.hidesHUD = true;
        return this.$el.addClass('hide-hud-properties');
      }
    }

    onClick(e) {
      if (!$(e.target).parents('.thang-props').length) { return Backbone.Mediator.publish('tome:focus-editor', {}); }
    }

    onFrameChanged(e) {
      this.timeProgress = e.progress;
      return this.update();
    }

    onDisableControls(e) {
      if (e.controls && !(Array.from(e.controls).includes('hud'))) { return; }
      this.disabled = true;
      return this.$el.addClass('controls-disabled');
    }

    onEnableControls(e) {
      if (e.controls && !(Array.from(e.controls).includes('hud'))) { return; }
      this.disabled = false;
      return this.$el.removeClass('controls-disabled');
    }

    onSpriteSelected(e) {
      if (this.disabled) { return; }
      return this.setThang(e.thang, e.sprite != null ? e.sprite.thangType : undefined);
    }

    onNewWorld(e) {
      const hadThang = this.thang;
      if (this.thang) { this.thang = e.world.thangMap[this.thang.id]; }
      if (hadThang && !this.thang) {
        return this.setThang(null, null);
      }
    }

    setThang(thang, thangType) {
      if ((thang == null) && (this.thang == null)) { return; }
      if ((thang != null) && (this.thang != null) && (thang.id === this.thang.id)) { return; }
      if ((thang != null) && this.hidesHUD && (thang.id !== 'Hero Placeholder')) { return; }  // Don't let them find the names of their opponents this way
      if (!thang) { return; }  // Don't let them deselect anything, ever.
      this.thang = thang;
      this.thangType = thangType;
      if (!this.thang) { return; }
      this.createAvatar(thangType, this.thang);
      this.createProperties();
      return this.update();
    }

    createAvatar(thangType, thang, colorConfig) {
      if (!thangType.isFullyLoaded()) {
        const args = arguments;
        if (!this.listeningToCreateAvatar) {
          this.listenToOnce(thangType, 'sync', function() { return this.createAvatar(...Array.from(args || [])); });
          this.listeningToCreateAvatar = true;
        }
        return;
      }
      this.listeningToCreateAvatar = false;
      const options = thang.getLankOptions() || {};
      options.async = false;
      if (colorConfig) { options.colorConfig = colorConfig; }
      const wrapper = this.$el.find('.thang-canvas-wrapper');
      const team = this.thang != null ? this.thang.team : undefined;
      wrapper.removeClass('hide');
      wrapper.removeClass((i, css) => (css.match(/\bteam-\S+/g) || []).join(' '));
      wrapper.addClass(`team-${team}`);
      if (thangType.get('raster')) {
        wrapper.empty().append($('<img draggable="false"/>').addClass('avatar').attr('src', '/file/'+thangType.get('raster')));
      } else {
        let stage;
        if (!(stage = thangType.getPortraitStage(options, 100))) { return; }
        const newCanvas = $(stage.canvas).addClass('thang-canvas avatar');
        wrapper.empty().append(newCanvas);
        stage.update();
        if (this.stage != null) {
          this.stage.stopTalking();
        }
        this.stage = stage;
      }
      return wrapper.append($('<img draggable="false" />').addClass('avatar-frame').attr('src', '/images/level/thang_avatar_frame.png'));
    }

    onThangBeganTalking(e) {
      if (!this.stage || (this.thang !== e.thang)) { return; }
      return (this.stage != null ? this.stage.startTalking() : undefined);
    }

    onThangFinishedTalking(e) {
      if (!this.stage || (this.thang !== e.thang)) { return; }
      return (this.stage != null ? this.stage.stopTalking() : undefined);
    }

    createProperties() {
      let name;
      if (this.options.level.isType('game-dev')) {
        name = 'Game';  // TODO: we don't need the HUD at all
      } else if (['Hero Placeholder', 'Hero Placeholder 1'].includes(this.thang.id)) {
        name = (this.thangType != null ? this.thangType.getHeroShortName() : undefined) || 'Hero';
      } else {
        name = this.thang.hudName || (this.thang.type ? `${this.thang.id} - ${this.thang.type}` : this.thang.id);
      }
      utils.replaceText(this.$el.find('.thang-name'), name);
      const props = this.$el.find('.thang-props');
      props.find('.prop').remove();
      //propNames = _.without @thang.hudProperties ? [], 'action'
      const propNames = this.thang.hudProperties;
      const iterable = propNames != null ? propNames : [];
      for (let i = 0; i < iterable.length; i++) {
        var prop = iterable[i];
        var pel = this.createPropElement(prop);
        if (pel == null) { continue; }
        if (pel.find('.bar').is('*') && props.find('.bar').is('*')) {
          props.find('.bar-prop').last().after(pel);  // Keep bars together
        } else {
          props.append(pel);
        }
      }
      return null;
    }

    update() {
      if (!this.thang) { return; }
      this.$el.find('.thang-props-column').toggleClass('nonexistent', !this.thang.exists);
      if (this.thang.exists) {
        return Array.from(this.thang.hudProperties != null ? this.thang.hudProperties : []).map((prop) => this.updatePropElement(prop, this.thang[prop]));
      }
    }

    createPropElement(prop) {
      if (['maxHealth'].includes(prop)) {
        return null;  // included in the bar
      }
      const context = {
        prop,
        hasIcon: ['health', 'pos', 'target', 'collectedThangIDs', 'gold', 'bountyGold', 'value', 'visualRange', 'attackDamage', 'attackRange', 'maxSpeed', 'attackNearbyEnemyRange'].includes(prop),
        hasBar: ['health'].includes(prop)
      };
      return $(prop_template(context));
    }

    updatePropElement(prop, val) {
      let labelText;
      const pel = this.$el.find('.thang-props *[name=' + prop + ']');
      if (['maxHealth'].includes(prop)) {
        return;  // Don't show maxes--they're built into bar labels.
      }
      if (['health'].includes(prop)) {
        const max = this.thang['max' + prop.charAt(0).toUpperCase() + prop.slice(1)];
        const regen = this.thang[prop + 'ReplenishRate'];
        const percent = Math.round((100 * val) / max);
        pel.find('.bar').css('width', percent + '%');
        labelText = prop + ': ' + this.formatValue(prop, val) + ' / ' + this.formatValue(prop, max);
        if (regen) {
          labelText += ' (+' + this.formatValue(prop, regen) + '/s)';
        }
        utils.replaceText(pel.find('.bar-prop-value'), Math.round(val));
      } else {
        const s = this.formatValue(prop, val);
        labelText = `${prop}: ${s}`;
        if (prop === 'attackDamage') {
          const {
            cooldown
          } = this.thang.actions.attack;
          const dps = this.thang.attackDamage / cooldown;
          labelText += ` / ${cooldown.toFixed(2)}s (DPS: ${dps.toFixed(2)})`;
        }
        utils.replaceText(pel.find('.prop-value'), s);
      }
      pel.attr('title', labelText);
      return pel;
    }

    formatValue(prop, val) {
      if ((prop === 'target') && !val) {
        val = this.thang['targetPos'];
        if (val != null ? val.isZero() : undefined) { val = null; }
      }
      if (prop === 'rotation') {
        return ((val * 180) / Math.PI).toFixed(0) + '˚';
      }
      if (prop.search(/Range$/) !== -1) {
        return val + 'm';
      }
      if (typeof val === 'number') {
        if ((Math.round(val) === val) || (prop === 'gold')) { return val.toFixed(0); }  // int
        if (-10 < val && val < 10) { return val.toFixed(2); }
        if (-100 < val && val < 100) { return val.toFixed(1); }
        return val.toFixed(0);
      }
      if (val && (typeof val === 'object')) {
        if (val.id) {
          return val.id;
        } else if (val.x && val.y) {
          return `x: ${val.x.toFixed(0)} y: ${val.y.toFixed(0)}`;
        }
          //return "x: #{val.x.toFixed(0)} y: #{val.y.toFixed(0)}, z: #{val.z.toFixed(0)}"  # Debugging: include z
      } else if ((val == null)) {
        return 'No ' + prop;
      }
      return val;
    }

    destroy() {
      if (this.stage != null) {
        this.stage.stopTalking();
      }
      return super.destroy();
    }
  };
  LevelHUDView.initClass();
  return LevelHUDView;
})());
