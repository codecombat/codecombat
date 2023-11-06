// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS002: Fix invalid constructor
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS202: Simplify dynamic range loops
 * DS205: Consider reworking code to avoid use of IIFEs
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let CampaignAnalyticsModal;
require('app/styles/editor/campaign/campaign-analytics-modal.sass');
const template = require('app/templates/editor/campaign/campaign-analytics-modal');
const utils = require('core/utils');
require('d3/d3.js'); // TODO Webpack: Extract this modal from main chunk
const ModalView = require('views/core/ModalView');

// TODO: jquery-ui datepicker doesn't work well in this view
// TODO: the date format handling is confusing (yyyy-mm-dd <=> yyyymmdd)

module.exports = (CampaignAnalyticsModal = (function() {
  CampaignAnalyticsModal = class CampaignAnalyticsModal extends ModalView {
    static initClass() {
      this.prototype.id = 'campaign-analytics-modal';
      this.prototype.template = template;
      this.prototype.plain = true;

      this.prototype.events = {
        'click #reload-button': 'onClickReloadButton',
        'dblclick .level': 'onDblClickLevel',
        'change #option-show-left-game': 'updateShowLeftGame',
        'change #option-show-subscriptions': 'updateShowSubscriptions'
      };
    }

    constructor(options, campaignHandle, campaignCompletions) {
      super(options);
      this.onClickReloadButton = this.onClickReloadButton.bind(this);
      this.getCampaignAnalytics = this.getCampaignAnalytics.bind(this);
      this.getCampaignAveragePlaytimes = this.getCampaignAveragePlaytimes.bind(this);
      this.getCampaignLevelCompletions = this.getCampaignLevelCompletions.bind(this);
      this.getCompaignLevelDrops = this.getCompaignLevelDrops.bind(this);
      this.getCampaignLevelSubscriptions = this.getCampaignLevelSubscriptions.bind(this);
      this.campaignHandle = campaignHandle;
      this.campaignCompletions = campaignCompletions;
      this.showLeftGame = true;
      this.showSubscriptions = utils.isOzaria;
      if (me.isAdmin()) { this.getCampaignAnalytics(); }
    }

    getRenderData() {
      const c = super.getRenderData();
      c.showLeftGame = this.showLeftGame;
      c.showSubscriptions = this.showSubscriptions;
      c.campaignCompletions = this.campaignCompletions;
      return c;
    }

    afterRender() {
      super.afterRender();
      $("#input-startday").datepicker({dateFormat: "yy-mm-dd"});
      $("#input-endday").datepicker({dateFormat: "yy-mm-dd"});
      return this.addCompletionLineGraphs();
    }

    updateShowLeftGame() {
      this.showLeftGame = this.$el.find('#option-show-left-game').prop('checked');
      return this.render();
    }

    updateShowSubscriptions() {
      this.showSubscriptions = this.$el.find('#option-show-subscriptions').prop('checked');
      return this.render();
    }

    onClickReloadButton() {
      const startDay = $('#input-startday').val();
      const endDay = $('#input-endday').val();
      delete this.campaignCompletions.levels;
      this.campaignCompletions.startDay = startDay;
      this.campaignCompletions.endDay = endDay;
      this.render();
      return this.getCampaignAnalytics(startDay, endDay);
    }

    onDblClickLevel(e) {
      const row = $(e.target).parents('.level');
      Backbone.Mediator.publish('editor:campaign-analytics-modal-closed', {targetLevelSlug: row.data('level-slug')});
      return this.hide();
    }

    addCompletionLineGraphs() {
      // TODO: no line graphs if some levels without completion rates?
      if (!this.campaignCompletions.levels) { return; }
      return (() => {
        const result = [];
        for (var level of Array.from(this.campaignCompletions.levels)) {
          var day;
          var days = [];
          for (day in level['days']) {
            if (!(level['days'][day].started > 0)) { continue; }
            days.push({
              day,
              rate: level['days'][day].finished / level['days'][day].started,
              count: level['days'][day].started
            });
          }
          days.sort((a, b) => a.day - b.day);
          var data = [];
          for (var i = 0, end = days.length, asc = 0 <= end; asc ? i < end : i > end; asc ? i++ : i--) {
            data.push({
              x: i,
              y: days[i].rate,
              c: days[i].count
            });
          }
          result.push(this.addLineGraph('#background' + level.level, data));
        }
        return result;
      })();
    }

    addLineGraph(containerSelector, lineData, lineColor, min, max) {
      // Add a line chart to the given container
      // Adjust stroke-weight based on segment count: width 0.3 to 3.0 for counts roughly 100 to 10000
      // TODO: Move this to a utility library
      if (lineColor == null) { lineColor = 'green'; }
      if (min == null) { min = 0; }
      if (max == null) { max = 1.0; }
      const vis = d3.select(containerSelector);
      const width = $(containerSelector).width();
      const height = $(containerSelector).height();
      const xRange = d3.scale.linear().range([0, width]).domain([d3.min(lineData, d => d.x), d3.max(lineData, d => d.x)]);
      const yRange = d3.scale.linear().range([height, 0]).domain([min, max]);
      const lines = [];
      for (let i = 0, end = lineData.length-1, asc = 0 <= end; asc ? i < end : i > end; asc ? i++ : i--) {
        lines.push({
          x1: xRange(lineData[i].x),
          y1: yRange(lineData[i].y),
          x2: xRange(lineData[i + 1].x),
          y2: yRange(lineData[i + 1].y),
          strokeWidth: Math.min(3, Math.max(0.3, Math.log(lineData[i].c/10)/2))
        });
      }
      return vis.selectAll('.line')
        .data(lines)
        .enter()
        .append("line")
        .attr("x1", d => d.x1)
        .attr("y1", d => d.y1)
        .attr("x2", d => d.x2)
        .attr("y2", d => d.y2)
        .style("stroke-width", d => d.strokeWidth)
        .style("stroke", lineColor);
    }

    getCampaignAnalytics(startDay, endDay) {
      let endDayDashed, startDayDashed;
      if (startDay != null) {
        startDayDashed = startDay;
        startDay = startDay.replace(/-/g, '');
      } else {
        startDay = utils.getUTCDay(-14);
        startDayDashed = `${startDay.slice(0, 4)}-${startDay.slice(4, 6)}-${startDay.slice(6, 8)}`;
      }
      if (endDay != null) {
        endDayDashed = endDay;
        endDay = endDay.replace(/-/g, '');
      } else {
        endDay = utils.getUTCDay(-1);
        endDayDashed = `${endDay.slice(0, 4)}-${endDay.slice(4, 6)}-${endDay.slice(6, 8)}`;
      }
      this.campaignCompletions.startDay = startDayDashed;
      this.campaignCompletions.endDay = endDayDashed;

      // Chain these together so we can calculate relative metrics (e.g. left game per second)
      return this.getCampaignLevelCompletions(startDay, endDay, () => {
        if (typeof this.render === 'function') {
          this.render();
        }
        return this.getCompaignLevelDrops(startDay, endDay, () => {
          if (typeof this.render === 'function') {
            this.render();
          }
          return this.getCampaignAveragePlaytimes(startDayDashed, endDayDashed, () => {
            if (typeof this.render === 'function') {
              this.render();
            }
            return this.getCampaignLevelSubscriptions(startDay, endDay, () => {
              return (typeof this.render === 'function' ? this.render() : undefined);
            });
          });
        });
      });
    }

    getCampaignAveragePlaytimes(startDay, endDay, doneCallback) {
      // Fetch level average playtimes
      // Needs date format yyyy-mm-dd
      const success = data => {
        if (this.destroyed) { return doneCallback(); }
        // console.log 'getCampaignAveragePlaytimes success', data
        const levelAverages = {};
        let maxPlaytime = 0;
        for (var item of Array.from(data)) {
          if (levelAverages[item.level] == null) { levelAverages[item.level] = []; }
          levelAverages[item.level].push(item.average);
        }
        for (var level of Array.from(this.campaignCompletions.levels)) {
          if (levelAverages[level.level]) {
            if (levelAverages[level.level].length > 0) {
              var total = _.reduce(levelAverages[level.level], ((sum, num) => sum + num));
              level.averagePlaytime = total / levelAverages[level.level].length;
              if (maxPlaytime < level.averagePlaytime) { maxPlaytime = level.averagePlaytime; }
              if ((level.averagePlaytime > 0) && (level.dropped > 0)) {
                level.droppedPerSecond = level.dropped / level.averagePlaytime;
              }
            } else {
              level.averagePlaytime = 0.0;
            }
          }
        }

        const addPlaytimePercentage = function(item) {
          if (maxPlaytime !== 0) { item.playtimePercentage = Math.round((item.averagePlaytime / maxPlaytime) * 100.0); }
          return item;
        };
        this.campaignCompletions.levels = _.map(this.campaignCompletions.levels, addPlaytimePercentage, this);

        let sortedLevels = _.cloneDeep(this.campaignCompletions.levels);
        sortedLevels = _.filter(sortedLevels, (a => a.droppedPerSecond > 0), this);
        sortedLevels.sort((a, b) => b.droppedPerSecond - a.droppedPerSecond);
        this.campaignCompletions.top3DropPerSecond = _.pluck(sortedLevels.slice(0, 3), 'level');
        return doneCallback();
      };

      const levelSlugs = _.pluck(this.campaignCompletions.levels, 'level');

      const request = this.supermodel.addRequestResource('playtime_averages', {
        url: '/db/level/-/playtime_averages',
        data: {startDay, endDay, slugs: levelSlugs},
        method: 'POST',
        success
      }, 0);
      return request.load();
    }

    getCampaignLevelCompletions(startDay, endDay, doneCallback) {
      // Needs date format yyyymmdd
      const success = data => {
        let maxStarted;
        if (this.destroyed) { return doneCallback(); }
        // console.log 'getCampaignLevelCompletions success', data
        const countCompletions = function(item) {
          item.started = _.reduce(item.days, ((result, current) => result + current.started), 0);
          item.finished = _.reduce(item.days, ((result, current) => result + current.finished), 0);
          item.completionRate = item.started > 0 ? (item.finished / item.started) * 100 : 0.0;
          return item;
        };
        const addUserRemaining = function(item) {
          if (maxStarted !== 0) { item.usersRemaining = Math.round((item.started / maxStarted) * 100.0); }
          return item;
        };

        this.campaignCompletions.levels = _.map(data, countCompletions, this);
        if (this.campaignCompletions.levels.length > 0) {
          maxStarted = (_.max(this.campaignCompletions.levels, (a => a.started))).started;
        } else {
          maxStarted = 0;
        }
        this.campaignCompletions.levels = _.map(this.campaignCompletions.levels, addUserRemaining, this);

        let sortedLevels = _.cloneDeep(this.campaignCompletions.levels);
        sortedLevels = _.filter(sortedLevels, (a => a.finished >= 10), this);
        if (sortedLevels.length >= 3) {
          sortedLevels.sort((a, b) => b.completionRate - a.completionRate);
          this.campaignCompletions.top3 = _.pluck(sortedLevels.slice(0, 3), 'level');
          this.campaignCompletions.bottom3 = _.pluck(sortedLevels.slice(sortedLevels.length - 4, sortedLevels.length - 1), 'level');
        }

        return doneCallback();
      };

      // TODO: Why do we need this url dash?
      const request = this.supermodel.addRequestResource('campaign_completions', {
        url: '/db/analytics_perday/-/campaign_completions',
        data: {startDay, endDay, slug: this.campaignHandle},
        method: 'POST',
        success
      }, 0);
      return request.load();
    }

    getCompaignLevelDrops(startDay, endDay, doneCallback) {
      // Fetch level drops
      // Needs date format yyyymmdd
      const success = data => {
        if (this.destroyed) { return; }
        // console.log 'getCompaignLevelDrops success', data
        const levelDrops = {};
        for (var item of Array.from(data)) {
          if (levelDrops[item.level] == null) { levelDrops[item.level] = item.dropped; }
        }
        for (var level of Array.from(this.campaignCompletions.levels)) {
          level.dropped = levelDrops[level.level] != null ? levelDrops[level.level] : 0;
          level.dropPercentage = level.started > 0 ? (level.dropped / level.started) * 100 : 0.0;
        }

        let sortedLevels = _.cloneDeep(this.campaignCompletions.levels);
        sortedLevels = _.filter(sortedLevels, (a => a.dropPercentage > 0), this);
        if (sortedLevels.length >= 3) {
          sortedLevels.sort((a, b) => b.dropPercentage - a.dropPercentage);
          this.campaignCompletions.top3DropPercentage = _.pluck(sortedLevels.slice(0, 3), 'level');
        }
        return doneCallback();
      };

      if ((this.campaignCompletions != null ? this.campaignCompletions.levels : undefined) == null) { return doneCallback(); }
      const levelSlugs = _.pluck(this.campaignCompletions.levels, 'level');

      const request = this.supermodel.addRequestResource('level_drops', {
        url: '/db/analytics_perday/-/level_drops',
        data: {startDay, endDay, slugs: levelSlugs},
        method: 'POST',
        success
      }, 0);
      return request.load();
    }

    getCampaignLevelSubscriptions(startDay, endDay, doneCallback) {
      // Fetch level subscriptions
      // Needs date format yyyymmdd
      const success = data => {
        if (this.destroyed) { return doneCallback(); }
        // console.log 'getCampaignLevelSubscriptions success', data
        const levelSubs = {};
        for (var item of Array.from(data)) {
          levelSubs[item.level] = {shown: item.shown, purchased: item.purchased};
        }
        for (var level of Array.from(this.campaignCompletions.levels)) {
          level.subsShown = levelSubs[level.level] != null ? levelSubs[level.level].shown : undefined;
          level.subsPurchased = levelSubs[level.level] != null ? levelSubs[level.level].purchased : undefined;
        }
        return doneCallback();
      };

      if ((this.campaignCompletions != null ? this.campaignCompletions.levels : undefined) == null) { return doneCallback(); }
      const levelSlugs = _.pluck(this.campaignCompletions.levels, 'level');

      const request = this.supermodel.addRequestResource('campaign_subscriptions', {
        url: '/db/analytics_perday/-/level_subscriptions',
        data: {startDay, endDay, slugs: levelSlugs},
        method: 'POST',
        success
      }, 0);
      return request.load();
    }
  };
  CampaignAnalyticsModal.initClass();
  return CampaignAnalyticsModal;
})());
