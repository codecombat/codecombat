// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS002: Fix invalid constructor
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS103: Rewrite code to no longer use __guard__, or convert again using --optional-chaining
 * DS205: Consider reworking code to avoid use of IIFEs
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let CampaignLevelView;
require('app/styles/editor/campaign/campaign-level-view.sass');
const CocoView = require('views/core/CocoView');
const Level = require('models/Level');
const LevelSession = require('models/LevelSession');
const ModelModal = require('views/modal/ModelModal');
const User = require('models/User');
const utils = require('core/utils');

module.exports = (CampaignLevelView = (function() {
  CampaignLevelView = class CampaignLevelView extends CocoView {
    static initClass() {
      this.prototype.id = 'campaign-level-view';
      this.prototype.template = require('app/templates/editor/campaign/campaign-level-view');

      this.prototype.events = {
        'change .line-graph-checkbox': 'updateGraphCheckbox',
        'click .close': 'onClickClose',
        'click #reload-button': 'onClickReloadButton',
        'dblclick .recent-session': 'onDblClickRecentSession',
        'mouseenter .graph-point': 'onMouseEnterPoint',
        'mouseleave .graph-point': 'onMouseLeavePoint',
        'click .replay-button': 'onClickReplay',
        'click #recent-button': 'onClickRecentButton'
      };

      this.prototype.limit = 100;
    }

    constructor(options, level) {
      super(options);
      this.onClickReloadButton = this.onClickReloadButton.bind(this);
      this.makeFinishDataFetch = this.makeFinishDataFetch.bind(this);
      this.getAnalytics = this.getAnalytics.bind(this);
      this.level = level;
      this.fullLevel = new Level({_id: this.level.id});
      this.fullLevel.fetch();
      this.listenToOnce(this.fullLevel, 'sync', () => (typeof this.render === 'function' ? this.render() : undefined));
      this.levelSlug = this.level.get('slug');
      this.getAnalytics();
    }

    getRenderData() {
      const c = super.getRenderData();
      c.level = this.fullLevel.loaded ? this.fullLevel : this.level;
      c.analytics = this.analytics;
      return c;
    }

    afterRender() {
      super.afterRender();
      $("#input-startday").datepicker({dateFormat: "yy-mm-dd"});
      $("#input-endday").datepicker({dateFormat: "yy-mm-dd"});
      // TODO: Why does this have to be called from afterRender() instead of getRenderData()?
      return this.updateAnalyticsGraphs();
    }

    updateGraphCheckbox(e) {
      const lineID = $(e.target).data('lineid');
      const checked = $(e.target).prop('checked');
      for (var graph of Array.from(this.analytics.graphs)) {
        for (var line of Array.from(graph.lines)) {
          if (line.lineID === lineID) {
            line.enabled = checked;
            return this.render();
          }
        }
      }
    }

    onClickClose() {
      this.$el.addClass('hidden');
      return this.trigger('hidden');
    }

    onClickReloadButton() {
      const startDay = $('#input-startday').val();
      const endDay = $('#input-endday').val();
      return this.getAnalytics(startDay, endDay);
    }

    onDblClickRecentSession(e) {
      // Admin view of players' code
      if (!me.isAdmin()) { return; }
      const row = $(e.target).parent();
      const player = new User({_id: row.data('player-id')});
      const session = new LevelSession({_id: row.data('session-id')});
      return this.openModalView(new ModelModal({models: [session, player]}));
    }

    onMouseEnterPoint(e) {
      const pointID = $(e.target).data('pointid');
      const container = this.$el.find(`.graph-point-info-container[data-pointid=${pointID}]`).show();
      const margin = 20;
      const width = container.outerWidth();
      const height = container.outerHeight();
      container.css('left', e.offsetX - (width / 2));
      return container.css('top', e.offsetY - height - margin);
    }

    onMouseLeavePoint(e) {
      const pointID = $(e.target).data('pointid');
      return this.$el.find(`.graph-point-info-container[data-pointid=${pointID}]`).hide();
    }

    onClickReplay(e) {
      const sessionID = $(e.target).closest('tr').data('session-id');
      const session = _.find(this.analytics.recentSessions.data, {_id: sessionID});
      let url = `/play/level/${this.level.get('slug')}?session=${sessionID}&observing=true`;
      if (session.isForClassroom) {
        url += '&course=560f1a9f22961295f9427742';
      }
      return window.open(url, '_blank');
    }

    onClickRecentButton(event) {
      event.preventDefault();
      this.limit = this.$('#input-session-num').val();
      this.analytics.recentSessions = {data: [], loading: true};
      this.render(); // Hide old session data while we fetch new sessions
      return this.getRecentSessions(this.makeFinishDataFetch(this.analytics.recentSessions));
    }

    makeFinishDataFetch(data) {
      return () => {
        if (this.destroyed) { return; }
        this.updateAnalyticsGraphData();
        data.loading = false;
        return this.render();
      };
    }

    updateAnalyticsGraphData() {
      // console.log 'updateAnalyticsGraphData'
      // Build graphs based on available @analytics data
      // Currently only one graph
      let day, i;
      this.analytics.graphs = [{graphID: 'level-completions', lines: []}];

      // TODO: Where should this metadata live?
      // TODO: lineIDs assumed to be unique across graphs
      const completionLineID = 'level-completions';
      const playtimeLineID = 'level-playtime';
      const helpsLineID = 'helps-clicked';
      const videosLineID = 'help-videos';
      const lineMetadata = {};
      lineMetadata[completionLineID] = {
        description: 'Level Completion (%)',
        color: 'red'
      };
      lineMetadata[playtimeLineID] = {
        description: 'Average Playtime (s)',
        color: 'green'
      };
      lineMetadata[helpsLineID] = {
        description: 'Help click rate (%)',
        color: 'blue'
      };
      lineMetadata[videosLineID] = {
        description: 'Help video rate (%)',
        color: 'purple'
      };

      // Use this days aggregate to fill in missing days from the analytics data
      let days = {};
      if (__guard__(this.analytics != null ? this.analytics.levelCompletions : undefined, x => x.data) != null) { for (day of Array.from(this.analytics.levelCompletions.data)) { days[`${day.created.slice(0, 4)}-${day.created.slice(4, 6)}-${day.created.slice(6, 8)}`] = true; } }
      if (__guard__(this.analytics != null ? this.analytics.levelPlaytimes : undefined, x1 => x1.data) != null) { for (day of Array.from(this.analytics.levelPlaytimes.data)) { days[day.created] = true; } }
      if (__guard__(this.analytics != null ? this.analytics.levelHelps : undefined, x2 => x2.data) != null) { for (day of Array.from(this.analytics.levelHelps.data)) { days[`${day.day.slice(0, 4)}-${day.day.slice(4, 6)}-${day.day.slice(6, 8)}`] = true; } }
      days = Object.keys(days).sort(function(a, b) { if (a < b) { return -1; } else { return 1; } });
      if (days.length > 0) {
        let currentIndex = 0;
        let currentDay = days[currentIndex];
        const currentDate = new Date(currentDay + "T00:00:00.000Z");
        const lastDay = days[days.length - 1];
        while (currentDay !== lastDay) {
          if (days[currentIndex] !== currentDay) { days.splice(currentIndex, 0, currentDay); }
          currentIndex++;
          currentDate.setUTCDate(currentDate.getUTCDate() + 1);
          currentDay = currentDate.toISOString().substr(0, 10);
        }
      }

      // Update level completion graph data
      const dayStartedMap = {};
      if (__guard__(__guard__(this.analytics != null ? this.analytics.levelCompletions : undefined, x4 => x4.data), x3 => x3.length) > 0) {
        // Build line data
        const levelPoints = [];
        for (i = 0; i < this.analytics.levelCompletions.data.length; i++) {
          day = this.analytics.levelCompletions.data[i];
          dayStartedMap[day.created] = day.started;
          var rate = parseFloat(day.rate);
          levelPoints.push({
            x: i,
            y: rate,
            started: day.started,
            day: `${day.created.slice(0, 4)}-${day.created.slice(4, 6)}-${day.created.slice(6, 8)}`,
            pointID: `${completionLineID}${i}`,
            values: [`Started: ${day.started}`, `Finished: ${day.finished}`, `Completion rate: ${rate.toFixed(2)}%`]});
        }
        // Ensure points for each day
        for (i = 0; i < days.length; i++) {
          day = days[i];
          if ((levelPoints.length <= i) || (levelPoints[i].day !== day)) {
            levelPoints.splice(i, 0, {
              y: 0.0,
              day,
              values: []
            });
          }
          levelPoints[i].x = i;
          levelPoints[i].pointID = `${completionLineID}${i}`;
        }
        this.analytics.graphs[0].lines.push({
          lineID: completionLineID,
          enabled: true,
          points: levelPoints,
          description: lineMetadata[completionLineID].description,
          lineColor: lineMetadata[completionLineID].color,
          min: 0,
          max: 100.0
        });
      }

      // Update average playtime graph data
      if (__guard__(__guard__(this.analytics != null ? this.analytics.levelPlaytimes : undefined, x6 => x6.data), x5 => x5.length) > 0) {
        // Build line data
        const playtimePoints = [];
        for (i = 0; i < this.analytics.levelPlaytimes.data.length; i++) {
          day = this.analytics.levelPlaytimes.data[i];
          var avg = parseFloat(day.average);
          playtimePoints.push({
            x: i,
            y: avg,
            day: day.created,
            pointID: `${playtimeLineID}${i}`,
            values: [`Average playtime: ${avg.toFixed(2)}s, ${day.count} players`]});
        }
        // Ensure points for each day
        for (i = 0; i < days.length; i++) {
          day = days[i];
          if ((playtimePoints.length <= i) || (playtimePoints[i].day !== day)) {
            playtimePoints.splice(i, 0, {
              y: 0.0,
              day,
              values: []
            });
          }
          playtimePoints[i].x = i;
          playtimePoints[i].pointID = `${playtimeLineID}${i}`;
        }
        this.analytics.graphs[0].lines.push({
          lineID: playtimeLineID,
          enabled: true,
          points: playtimePoints,
          description: lineMetadata[playtimeLineID].description,
          lineColor: lineMetadata[playtimeLineID].color,
          min: 0,
          max: d3.max(playtimePoints, d => d.y)
        });
      }

      // Update help graph data
      if (__guard__(__guard__(this.analytics != null ? this.analytics.levelHelps : undefined, x8 => x8.data), x7 => x7.length) > 0) {
        // Build line data
        const helpPoints = [];
        const videoPoints = [];
        for (i = 0; i < this.analytics.levelHelps.data.length; i++) {
          day = this.analytics.levelHelps.data[i];
          var helpCount = day.alertHelps + day.paletteHelps;
          var started = dayStartedMap[day.day] != null ? dayStartedMap[day.day] : 0;
          var clickRate = started > 0 ? (helpCount / started) * 100 : 0;
          var videoRate = (day.videoStarts / helpCount) * 100;
          helpPoints.push({
            x: i,
            y: clickRate,
            day: `${day.day.slice(0, 4)}-${day.day.slice(4, 6)}-${day.day.slice(6, 8)}`,
            pointID: `${helpsLineID}${i}`,
            values: [`Helps clicked: ${helpCount}`, `Helps click clickRate: ${clickRate.toFixed(2)}%`]});
          videoPoints.push({
            x: i,
            y: videoRate,
            day: `${day.day.slice(0, 4)}-${day.day.slice(4, 6)}-${day.day.slice(6, 8)}`,
            pointID: `${videosLineID}${i}`,
            values: [`Help videos started: ${day.videoStarts}`, `Help videos start rate: ${videoRate.toFixed(2)}%`]});
        }
        // Ensure points for each day
        for (i = 0; i < days.length; i++) {
          day = days[i];
          if ((helpPoints.length <= i) || (helpPoints[i].day !== day)) {
            helpPoints.splice(i, 0, {
              y: 0.0,
              day,
              values: []
            });
          }
          helpPoints[i].x = i;
          helpPoints[i].pointID = `${helpsLineID}${i}`;
          if ((videoPoints.length <= i) || (videoPoints[i].day !== day)) {
            videoPoints.splice(i, 0, {
              y: 0.0,
              day,
              values: []
            });
          }
          videoPoints[i].x = i;
          videoPoints[i].pointID = `${videosLineID}${i}`;
        }
        if (d3.max(helpPoints, d => d.y) > 0) {
          this.analytics.graphs[0].lines.push({
            lineID: helpsLineID,
            enabled: true,
            points: helpPoints,
            description: lineMetadata[helpsLineID].description,
            lineColor: lineMetadata[helpsLineID].color,
            min: 0,
            max: 100.0
          });
        }
        if (d3.max(videoPoints, d => d.y) > 0) {
          return this.analytics.graphs[0].lines.push({
            lineID: videosLineID,
            enabled: true,
            points: videoPoints,
            description: lineMetadata[videosLineID].description,
            lineColor: lineMetadata[videosLineID].color,
            min: 0,
            max: 100.0
          });
        }
      }
    }

    updateAnalyticsGraphs() {
      // Build d3 graphs
      if (!(__guard__(this.analytics != null ? this.analytics.graphs : undefined, x => x.length) > 0)) { return; }
      const containerSelector = '.line-graph-container';
      // console.log 'updateAnalyticsGraphs', containerSelector, @analytics.graphs

      const margin = 20;
      const keyHeight = 20;
      const xAxisHeight = 20;
      const yAxisWidth = 40;
      const containerWidth = $(containerSelector).width();
      const containerHeight = $(containerSelector).height();

      return (() => {
        const result = [];
        for (var graph of Array.from(this.analytics.graphs)) {
          var graphLineCount = _.reduce(graph.lines, (function(sum, item) { if (item.enabled) { return sum + 1; } else { return sum; } }), 0);
          var svg = d3.select(containerSelector).append("svg")
            .attr("width", containerWidth)
            .attr("height", containerHeight);
          var width = containerWidth - (margin * 2) - (yAxisWidth * graphLineCount);
          var height = containerHeight - (margin * 2) - xAxisHeight - (keyHeight * graphLineCount);
          var currentLine = 0;
          result.push((() => {
            const result1 = [];
            for (var line of Array.from(graph.lines)) {
              if (!line.enabled) { continue; }
              var xRange = d3.scale.linear().range([0, width]).domain([d3.min(line.points, d => d.x), d3.max(line.points, d => d.x)]);
              var yRange = d3.scale.linear().range([height, 0]).domain([line.min, line.max]);

              // x-Axis and guideline once
              if (currentLine === 0) {
                var startDay = new Date(line.points[0].day);
                var endDay = new Date(line.points[line.points.length - 1].day);
                var xAxisRange = d3.time.scale()
                  .domain([startDay, endDay])
                  .range([0, width]);
                var xAxis = d3.svg.axis()
                  .scale(xAxisRange);
                svg.append("g")
                  .attr("class", "x axis")
                  .call(xAxis)
                  .selectAll("text")
                  .attr("dy", ".35em")
                  .attr("transform", "translate(" + (margin + (yAxisWidth * (graphLineCount - 1))) + "," + (height + margin) + ")")
                  .style("text-anchor", "start");

                // Horizontal guidelines
                svg.selectAll(".line")
                  .data([10, 30, 50, 70, 90])
                  .enter()
                  .append("line")
                  .attr("x1", margin + (yAxisWidth * graphLineCount))
                  .attr("y1", d => margin + yRange(d))
                  .attr("x2", margin + (yAxisWidth * graphLineCount) + width)
                  .attr("y2", d => margin + yRange(d))
                  .attr("stroke", line.lineColor)
                  .style("opacity", "0.5");
              }

              // y-Axis
              var yAxisRange = d3.scale.linear().range([height, 0]).domain([line.min, line.max]);
              var yAxis = d3.svg.axis()
                .scale(yRange)
                .orient("left");
              svg.append("g")
                .attr("class", "y axis")
                .attr("transform", "translate(" + (margin + (yAxisWidth * currentLine)) + "," + margin + ")")
                .style("color", line.lineColor)
                .call(yAxis)
                .selectAll("text")
                .attr("y", 0)
                .attr("x", 0)
                .attr("fill", line.lineColor)
                .style("text-anchor", "start");

              // Key
              svg.append("line")
                .attr("x1", margin)
                .attr("y1", margin + height + xAxisHeight + (keyHeight * currentLine) + (keyHeight / 2))
                .attr("x2", margin + 40)
                .attr("y2", margin + height + xAxisHeight + (keyHeight * currentLine) + (keyHeight / 2))
                .attr("stroke", line.lineColor)
                .attr("class", "key-line");
              svg.append("text")
                .attr("x", margin + 40 + 10)
                .attr("y", margin + height + xAxisHeight + (keyHeight * currentLine) + ((keyHeight + 10) / 2))
                .attr("fill", line.lineColor)
                .attr("class", "key-text")
                .text(line.description);

              // Path and points
              svg.selectAll(".circle")
                .data(line.points)
                .enter()
                .append("circle")
                .attr("transform", "translate(" + (margin + (yAxisWidth * graphLineCount)) + "," + margin + ")")
                .attr("cx", d => xRange(d.x))
                .attr("cy", d => yRange(d.y))
                .attr("r", function(d) { if (d.started) { return Math.max(3, Math.min(10, Math.log(parseInt(d.started)))) + 2; } else { return 6; } })
                .attr("fill", line.lineColor)
                .attr("stroke-width", 1)
                .attr("class", "graph-point")
                .attr("data-pointid", d => `${line.lineID}${d.x}`);
              var d3line = d3.svg.line()
                .x(d => xRange(d.x))
                .y(d => yRange(d.y))
                .interpolate("linear");
              svg.append("path")
                .attr("d", d3line(line.points))
                .attr("transform", "translate(" + (margin + (yAxisWidth * graphLineCount)) + "," + margin + ")")
                .style("stroke-width", 1)
                .style("stroke", line.lineColor)
                .style("fill", "none");
              result1.push(currentLine++);
            }
            return result1;
          })());
        }
        return result;
      })();
    }

    getAnalytics(startDay, endDay) {
      // Analytics APIs use 2 different day formats
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

      // Initialize
      this.analytics = {
        startDay: startDayDashed,
        endDay: endDayDashed,
        commonProblems: {data: [], loading: true},
        levelCompletions: {data: [], loading: true},
        levelHelps: {data: [], loading: true},
        levelPlaytimes: {data: [], loading: true},
        recentSessions: {data: [], loading: true},
        graphs: []
      };
      this.render(); // Hide old analytics data while we fetch new data

      this.getCommonLevelProblems(startDayDashed, endDayDashed, this.makeFinishDataFetch(this.analytics.commonProblems));
      this.getLevelCompletions(startDay, endDay, this.makeFinishDataFetch(this.analytics.levelCompletions));
      this.getLevelHelps(startDay, endDay, this.makeFinishDataFetch(this.analytics.levelHelps));
      this.getLevelPlaytimes(startDayDashed, endDayDashed, this.makeFinishDataFetch(this.analytics.levelPlaytimes));
      return this.getRecentSessions(this.makeFinishDataFetch(this.analytics.recentSessions));
    }

    getCommonLevelProblems(startDay, endDay, doneCallback) {
      const success = data => {
        if (this.destroyed) { return doneCallback(); }
        // console.log 'getCommonLevelProblems', data
        this.analytics.commonProblems.data = data;
        return doneCallback();
      };
      const request = this.supermodel.addRequestResource('common_problems', {
        url: '/db/user.code.problem/-/common_problems',
        data: {startDay, endDay, slug: this.levelSlug},
        method: 'POST',
        success
      }, 0);
      return request.load();
    }

    getLevelCompletions(startDay, endDay, doneCallback) {
      const success = data => {
        if (this.destroyed) { return doneCallback(); }
        // console.log 'getLevelCompletions', data
        data.sort(function(a, b) { if (a.created < b.created) { return -1; } else { return 1; } });
        const mapFn = function(item) {
          item.rate = item.started > 0 ? (item.finished / item.started) * 100 : 0;
          return item;
        };
        this.analytics.levelCompletions.data = _.map(data, mapFn, this);
        return doneCallback();
      };
      const request = this.supermodel.addRequestResource('level_completions', {
        url: '/db/analytics_perday/-/level_completions',
        data: {startDay, endDay, slug: this.levelSlug},
        method: 'POST',
        success
      }, 0);
      return request.load();
    }

    getLevelHelps(startDay, endDay, doneCallback) {
      const success = data => {
        if (this.destroyed) { return doneCallback(); }
        // console.log 'getLevelHelps', data
        this.analytics.levelHelps.data = data.sort(function(a, b) { if (a.day < b.day) { return -1; } else { return 1; } });
        return doneCallback();
      };
      const request = this.supermodel.addRequestResource('level_helps', {
        url: '/db/analytics_perday/-/level_helps',
        data: {startDay, endDay, slugs: [this.levelSlug]},
        method: 'POST',
        success
      }, 0);
      return request.load();
    }

    getLevelPlaytimes(startDay, endDay, doneCallback) {
      const success = data => {
        if (this.destroyed) { return doneCallback(); }
        // console.log 'getLevelPlaytimes', data
        this.analytics.levelPlaytimes.data = data.sort(function(a, b) { if (a.created < b.created) { return -1; } else { return 1; } });
        return doneCallback();
      };
      const request = this.supermodel.addRequestResource('playtime_averages', {
        url: '/db/level/-/playtime_averages',
        data: {startDay, endDay, slugs: [this.levelSlug]},
        method: 'POST',
        success
      }, 0);
      return request.load();
    }

    getRecentSessions(doneCallback) {
      // limit = 100
      const success = data => {
        if (this.destroyed) { return doneCallback(); }
        // console.log 'getRecentSessions', data
        this.analytics.recentSessions.data = data;
        return doneCallback();
      };
      const request = this.supermodel.addRequestResource('level_sessions_recent', {
        url: "/db/level.session/-/recent",
        data: {slug: this.levelSlug, limit: this.limit},
        method: 'POST',
        success
      }, 0);
      return request.load();
    }
  };
  CampaignLevelView.initClass();
  return CampaignLevelView;
})());

function __guard__(value, transform) {
  return (typeof value !== 'undefined' && value !== null) ? transform(value) : undefined;
}