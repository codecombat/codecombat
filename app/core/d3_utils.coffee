# Caller needs require 'vendor/d3'

module.exports.createContiguousDays = (timeframeDays, skipToday=true) ->
  # Return list of last 'timeframeDays' contiguous days in yyyy-mm-dd format
  days = []
  currentDate = new Date()
  currentDate.setUTCDate(currentDate.getUTCDate() - timeframeDays + 1)
  currentDate.setUTCDate(currentDate.getUTCDate() - 1) if skipToday
  for i in [0...timeframeDays]
    currentDay = currentDate.toISOString().substr(0, 10)
    days.push(currentDay)
    currentDate.setUTCDate(currentDate.getUTCDate() + 1)
  days

module.exports.createLineChart = (containerSelector, chartLines, containerWidth) ->
  # Creates a line chart within 'containerSelector' based on chartLines
  return unless chartLines?.length > 0 and containerSelector

  margin = 20
  keyHeight = 20
  xAxisHeight = 20
  yAxisWidth = 40
  containerWidth = $(containerSelector).width() unless containerWidth
  containerHeight = $(containerSelector).height()

  yScaleCount = 0
  yScaleCount++ for line in chartLines when line.showYScale
  svg = d3.select(containerSelector).append("svg")
    .attr("width", containerWidth)
    .attr("height", containerHeight)
  width = containerWidth - margin * 2 - yAxisWidth * yScaleCount
  height = containerHeight - margin * 2 - xAxisHeight - keyHeight * chartLines.length
  currentLine = 0
  currentYScale = 0

  # Horizontal guidelines
  marks = (Math.round(i * height / 5) for i in [1..5])
  yRange = d3.scale.linear().range([height, 0]).domain([0, height])
  svg.selectAll(".line")
    .data(marks)
    .enter()
    .append("line")
    .attr("x1", margin + yAxisWidth * yScaleCount)
    .attr("y1", (d) -> margin + yRange(d))
    .attr("x2", margin + yAxisWidth * yScaleCount + width)
    .attr("y2", (d) -> margin + yRange(d))
    .attr("stroke", 'gray')
    .style("opacity", "0.3")

  for line in chartLines
    # continue unless line.enabled
    xRange = d3.scale.linear().range([0, width]).domain([d3.min(line.points, (d) -> d.x), d3.max(line.points, (d) -> d.x)])
    yRange = d3.scale.linear().range([height, 0]).domain([line.min, line.max])

    # x-Axis
    if currentLine is 0
      startDay = new Date(line.points[0].day)
      endDay = new Date(line.points[line.points.length - 1].day)
      xAxisRange = d3.time.scale()
        .domain([startDay, endDay])
        .range([0, width])
      xAxis = d3.svg.axis()
        .scale(xAxisRange)
      svg.append("g")
        .attr("class", "x axis")
        .call(xAxis)
        .selectAll("text")
        .attr("dy", ".35em")
        .attr("transform", "translate(" + (margin + yAxisWidth * yScaleCount) + "," + (height + margin) + ")")
        .style("text-anchor", "start")

    if line.showYScale
      # y-Axis
      lineColor = if yScaleCount > 1 then line.lineColor else 'black' 
      yAxisRange = d3.scale.linear().range([height, 0]).domain([line.min, line.max])
      yAxis = d3.svg.axis()
        .scale(yRange)
        .orient("left")
      svg.append("g")
        .attr("class", "y axis")
        .attr("transform", "translate(" + (margin + yAxisWidth * currentYScale) + "," + margin + ")")
        .style("color", lineColor)
        .call(yAxis)
        .selectAll("text")
        .attr("y", 0)
        .attr("x", 0)
        .attr("fill", lineColor)
        .style("text-anchor", "start")
      currentYScale++

    # Key
    svg.append("line")
      .attr("x1", margin)
      .attr("y1", margin + height + xAxisHeight + keyHeight * currentLine + keyHeight / 2)
      .attr("x2", margin + 40)
      .attr("y2", margin + height + xAxisHeight + keyHeight * currentLine + keyHeight / 2)
      .attr("stroke", line.lineColor)
      .attr("class", "key-line")
    svg.append("text")
      .attr("x", margin + 40 + 10)
      .attr("y", margin + height + xAxisHeight + keyHeight * currentLine + (keyHeight + 10) / 2)
      .attr("fill", line.lineColor)
      .attr("class", "key-text")
      .text(line.description)

    # Path and points
    svg.selectAll(".circle")
      .data(line.points)
      .enter()
      .append("circle")
      .attr("transform", "translate(" + (margin + yAxisWidth * yScaleCount) + "," + margin + ")")
      .attr("cx", (d) -> xRange(d.x))
      .attr("cy", (d) -> yRange(d.y))
      .attr("r", 2)
      .attr("fill", line.lineColor)
      .attr("stroke-width", 1)
      .attr("class", "graph-point")
      .attr("data-pointid", (d) -> "#{line.lineID}#{d.x}")
    d3line = d3.svg.line()
      .x((d) -> xRange(d.x))
      .y((d) -> yRange(d.y))
      .interpolate("linear")
    svg.append("path")
      .attr("d", d3line(line.points))
      .attr("transform", "translate(" + (margin + yAxisWidth * yScaleCount) + "," + margin + ")")
      .style("stroke-width", line.strokeWidth)
      .style("stroke", line.lineColor)
      .style("fill", "none")
    currentLine++
