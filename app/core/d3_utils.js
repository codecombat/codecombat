// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS202: Simplify dynamic range loops
 * DS205: Consider reworking code to avoid use of IIFEs
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
// Caller needs require 'd3/d3.js'

export const createContiguousDays = function(timeframeDays, skipToday, dayOffset) {
  // Return list of last 'timeframeDays' contiguous days in yyyy-mm-dd format
  if (skipToday == null) { skipToday = true; }
  if (dayOffset == null) { dayOffset = 0; }
  const days = [];
  const currentDate = new Date();
  currentDate.setUTCDate(currentDate.getUTCDate() - dayOffset);
  currentDate.setUTCDate((currentDate.getUTCDate() - timeframeDays) + 1);
  if (skipToday) { currentDate.setUTCDate(currentDate.getUTCDate() - 1); }
  for (let i = 0, end = timeframeDays, asc = 0 <= end; asc ? i < end : i > end; asc ? i++ : i--) {
    var currentDay = currentDate.toISOString().substr(0, 10);
    days.push(currentDay);
    currentDate.setUTCDate(currentDate.getUTCDate() + 1);
  }
  return days;
};

export const createLineChart = function(containerSelector, chartLines, containerWidth) {
  // Creates a line chart within 'containerSelector' based on chartLines
  let line;
  let i;
  if (!((chartLines != null ? chartLines.length : undefined) > 0) || !containerSelector) { return; }

  const margin = 20;
  const keyHeight = 35;
  const xAxisHeight = 20;
  const yAxisWidth = 40;
  if (!containerWidth) { containerWidth = $(containerSelector).width(); }
  const containerHeight = $(containerSelector).height();
  let leftKeyWidth = 0;

  let yScaleCount = 0;
  for (line of Array.from(chartLines)) { if (line.showYScale) { yScaleCount++; } }
  const svg = d3.select(containerSelector).append("svg")
    .attr("width", containerWidth)
    .attr("height", containerHeight);
  const width = containerWidth - (margin * 2) - (yAxisWidth * yScaleCount);
  const height = containerHeight - (margin * 2) - xAxisHeight - (keyHeight * chartLines.length);
  let currentLine = 0;
  let currentYScale = 0;

  // Horizontal guidelines
  const marks = ((() => {
    const result = [];
    for (i = 1; i <= 5; i++) {
      result.push(Math.round((i * height) / 5));
    }
    return result;
  })());
  let yRange = d3.scale.linear().range([height, 0]).domain([0, height]);
  svg.selectAll(".line")
    .data(marks)
    .enter()
    .append("line")
    .attr("x1", margin + (yAxisWidth * yScaleCount))
    .attr("y1", d => margin + yRange(d))
    .attr("x2", margin + (yAxisWidth * yScaleCount) + width)
    .attr("y2", d => margin + yRange(d))
    .attr("stroke", 'gray')
    .style("opacity", "0.3");

  return (() => {
    const result1 = [];
    for (line of Array.from(chartLines)) {
    // continue unless line.enabled
      var lineColor;
      var xRange = d3.scale.linear().range([0, width]).domain([d3.min(line.points, d => d.x), d3.max(line.points, d => d.x)]);
      yRange = d3.scale.linear().range([height, 0]).domain([line.min, line.max]);

      // x-Axis
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
          .attr("transform", "translate(" + (margin + (yAxisWidth * yScaleCount)) + "," + (height + margin) + ")")
          .style("text-anchor", "start");
      }

      if (line.showYScale) {
        // y-Axis
        lineColor = yScaleCount > 1 ? line.lineColor : 'black';
        var yAxisRange = d3.scale.linear().range([height, 0]).domain([line.min, line.max]);
        var yAxis = d3.svg.axis()
          .scale(yRange)
          .orient("left");
        svg.append("g")
          .attr("class", "y axis")
          .attr("transform", "translate(" + (margin + (yAxisWidth * currentYScale)) + "," + margin + ")")
          .style("color", lineColor)
          .call(yAxis)
          .selectAll("text")
          .attr("y", 0)
          .attr("x", 0)
          .attr("fill", lineColor)
          .style("text-anchor", "start");
        currentYScale++;
      }

      // Key
      var currentKeyLine = Math.floor(currentLine / 2);
      var currentKeyXOffset = margin + (currentLine % 2 ? Math.max(leftKeyWidth + margin + 40, containerWidth / 2) : 0);
      var currentKeyYOffset = margin + height + xAxisHeight + (keyHeight * currentKeyLine);
      svg.append("line")
        .attr("x1", currentKeyXOffset)
        .attr("y1", currentKeyYOffset + (keyHeight / 2))
        .attr("x2", currentKeyXOffset + 40)
        .attr("y2", currentKeyYOffset + (keyHeight / 2))
        .attr("stroke", line.lineColor)
        .attr("stroke-width", 4)
        .attr("class", "key-line");
      var what = svg.append("text")
        .attr("x", currentKeyXOffset + 40 + 10)
        .attr("y", currentKeyYOffset + ((keyHeight + 10) / 2))
        .attr("fill", line.lineColor)
        .attr("class", "key-text")
        .text(line.description)
        .each(function(d, i) { if ((currentLine % 2) === 0) { return leftKeyWidth = Math.max(leftKeyWidth, this.getComputedTextLength()); } });

      var pointRadius = line.pointRadius != null ? line.pointRadius : 2;
      // Path and points
      svg.selectAll(".circle")
        .data(line.points)
        .enter()
        .append("circle")
        .attr("transform", "translate(" + (margin + (yAxisWidth * yScaleCount)) + "," + margin + ")")
        .attr("cx", d => xRange(d.x))
        .attr("cy", d => yRange(d.y))
        .attr("r", pointRadius)
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
        .attr("transform", "translate(" + (margin + (yAxisWidth * yScaleCount)) + "," + margin + ")")
        .style("stroke-width", line.strokeWidth)
        .style("stroke", line.lineColor)
        .style("fill", "none");
      result1.push(currentLine++);
    }
    return result1;
  })();
};
