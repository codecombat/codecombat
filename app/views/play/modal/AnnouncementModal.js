/*
 * decaffeinate suggestions:
 * DS002: Fix invalid constructor
 * DS102: Remove unnecessary code created because of implicit returns
 * DS202: Simplify dynamic range loops
 * DS205: Consider reworking code to avoid use of IIFEs
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let AnnouncementModal;
require('app/styles/play/modal/announcement-modal.sass');
const ModalView = require('views/core/ModalView');
const utils = require('core/utils');
const CreateAccountModal = require('views/core/CreateAccountModal');
const SubscribeModal = require('views/core/SubscribeModal');
const Products = require('collections/Products');

module.exports = (AnnouncementModal = (function() {
  let announcementId = undefined;
  AnnouncementModal = class AnnouncementModal extends ModalView {
    static initClass() {
      this.prototype.id = 'announcement-modal';
      this.prototype.plain = true;
      this.prototype.closesOnClickOutside = true;
      this.prototype.modalPath = 'views/play/modal/AnnouncementModal';

      announcementId = null;

      this.prototype.events = {
        'click #close-modal': 'hide',
        'click .purchase-button': 'onClickPurchaseButton',
        'click .close-button': 'hide',
        'mouseover .has-tooltip': 'displayTooltip',
        'mousemove .has-tooltip': 'displayTooltip',
        'mouseout .has-tooltip': 'hideTooltip',

        'click .ability-icon': 'onClickAbilityIcon',
        'click .ritic-block': 'onClickRiticBlock'
      };
    }

    constructor(options) {
      super(options);
      this.onClickPurchaseButton = this.onClickPurchaseButton.bind(this);
      if (options == null) { options = {}; }
      if (options.announcementId == null) { options.announcementId = 1; }
      ({
        announcementId
      } = options);
      this.template = require(`templates/play/modal/announcements/${options.announcementId}`);
      this.trackTimeVisible({ trackViewLifecycle: true });
    }

    afterRender() {
      super.afterRender();
      return this.playSound('game-menu-open');
    }

    afterInsert() {
      super.afterInsert();
      return this.timerIntervalID = setInterval(() => {
        if (this.isHover) { return; }
        const elems = $(".pet-image").toArray();
        const randomNum = Math.floor(Math.random() * elems.length);
        const randomItem = elems[randomNum];
        if (randomItem) {
          $(randomItem).addClass('wiggle');
          return setTimeout(() => $(randomItem).removeClass('wiggle')
          , 1000);
        }
      }
      , 1000);
    }

    onClickAbilityIcon(e) {
      $(".gif-video").hide();
      return $("#" + $(e.currentTarget).data("gif") + "-gif").show();
    }

    onClickRiticBlock(e) {
      const elem = $(e.currentTarget);
      const spawnSomeShards = num => (() => {
        const result = [];
        for (let i = 0, end = num, asc = 0 <= end; asc ? i < end : i > end; asc ? i++ : i--) {
          var img = $("<img>").attr("src", `/images/pages/play/modal/announcement/ritic/shard${Math.floor(1 + (Math.random() * 6))}.png`).addClass("shard");
          var left = Math.floor(25 + (50 * Math.random()));
          var top =  Math.floor(75 - (30 * Math.random()));
          img.css({left: left + "%", top: top + "%"});
          img.css("transform", "rotate(0deg)");
          $("#ice-chamber").append(img);
          var randNum = Math.random() * Math.PI * 2;
          img.animate({
            opacity: 0,
            left: (left + (Math.cos(randNum) * 100)) + "%",
            top: (top + (Math.sin(randNum) * 100)) + "%"},
            740 + (Math.random() * 2000), function() {
              return $(this).remove();
          });
          result.push(img.css("transform", `rotate(${-360 + Math.floor(Math.random() * 360 * 2)}deg)`));
        }
        return result;
      })();
      if (elem.hasClass('ritic-block-1')) {
        elem.removeClass('ritic-block-1');
        elem.addClass('ritic-block-2');
        $("#clear-block").hide();
        $("#chipped-block").show();
        return spawnSomeShards(2);
      } else if (elem.hasClass('ritic-block-2')) {
        elem.removeClass('ritic-block-2');
        $("#chipped-block").hide();
        $("#shattered-block").show();
        $("#shattered-block").css("opacity", 1);
        elem.addClass('ritic-block-3');
        return spawnSomeShards(10);
      } else if (elem.hasClass('ritic-block-3')) {
        elem.removeClass('ritic-block-3');
        $("#shattered-block").css("opacity", 0);
        $("#ritic-image").addClass("breathing");
        $("#ritic-image").css("cursor", "default");
        $("#ritic-image").data("name", "announcement.ritic");
        $("#ritic-image").data("description", "announcement.ritic_description");
        this.hideTooltip();
        $(".highlight").each(function(i, elem) {
          $(this).show();
          return $(this).css("animation",`highlight${i % 2 ? '-reverse' : ''}-anim ${5 + i}s linear infinite`);
        });
        return spawnSomeShards(25);
      }
    }

    displayTooltip(e) {
      if ($(e.currentTarget).data("name") != null) {
        const w = $(".paper-area").offset();
        const x = $(".paper-area").position();
        $("#item-tooltip").show().css("left", ((e.clientX - w.left) + 96) + "px");
        $("#item-tooltip").show().css("top", ((e.clientY - w.top)) + "px");
        if ($(e.currentTarget).data('coming-soon') != null) {
          $("#item-tooltip #coming-soon").show();
        } else {
          $("#item-tooltip #coming-soon").hide();
        }
        $("#item-tooltip #pet-name").text($.i18n.t($(e.currentTarget).data("name")));
        $("#item-tooltip #pet-description").text($.i18n.t($(e.currentTarget).data("description")));
        return this.isHover = true;
      }
    }

    hideTooltip() {
      $("#item-tooltip").hide();
      return this.isHover = false;
    }

    onClickPurchaseButton(e) {
      this.playSound('menu-button-click');
      this.openModalView(new SubscribeModal());
      return (window.tracker != null ? window.tracker.trackEvent('Show subscription modal', {category: 'Subscription', label: `announcement modal id: ${announcementId}`}) : undefined);
    }

    onHidden() {
      super.onHidden();
      return this.playSound('game-menu-close');
    }

    destroy() {
      clearInterval(this.timerIntervalID);
      return super.destroy();
    }
  };
  AnnouncementModal.initClass();
  return AnnouncementModal;
})());
