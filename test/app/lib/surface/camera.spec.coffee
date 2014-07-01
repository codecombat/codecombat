describe 'Camera (Surface point of view)', ->
  Camera = require 'lib/surface/Camera'

  expectPositionsEqual = (p1, p2) ->
    expect(p1.x).toBeCloseTo p2.x
    expect(p1.y).toBeCloseTo p2.y
    expect(p1.z).toBeCloseTo p2.z if p2.z?

  checkConversionsFromWorldPos = (wop, cam) ->
    # wop = world pos
    # sup = surface pos
    # cap = canvas pos
    # scp = screen pos

    sup = cam.worldToSurface wop
    expect(sup.x).toBeCloseTo wop.x * Camera.PPM
    expect(sup.y).toBeCloseTo cam.surfaceHeight - (wop.y + wop.z * cam.z2y) * cam.y2x * Camera.PPM

    cap = cam.worldToCanvas wop
    expect(cap.x).toBeCloseTo (sup.x - cam.surfaceViewport.x) * cam.zoom
    expect(cap.y).toBeCloseTo (sup.y - cam.surfaceViewport.y) * cam.zoom

    scp = cam.worldToScreen wop
    # If we ever want to use screen conversion, then make it and add this test
    #expect(scp.x).toBeCloseTo cap.x * @someCanvasToScreenXScaleFactor
    #expect(scp.y).toBeCloseTo cap.y * @someCanvasToScreenYScaleFactor

    wop2 = cam.surfaceToWorld sup
    expect(wop2.x).toBeCloseTo wop.x
    expect(wop2.y).toBeCloseTo wop.y + wop.z * cam.z2y

    # Make sure to call all twelve conversions in here. Can be redundant.
    expectPositionsEqual sup,  cam.worldToSurface wop2  # 0
    expectPositionsEqual cap,  cam.surfaceToCanvas sup  # 1
    expectPositionsEqual scp,  cam.canvasToScreen cap   # 2
    expectPositionsEqual cap,  cam.screenToCanvas scp   # 3
    expectPositionsEqual sup,  cam.canvasToSurface cap  # 4
    expectPositionsEqual wop2, cam.surfaceToWorld sup   # 5
    expectPositionsEqual wop2, cam.canvasToWorld cap    # 6
    expectPositionsEqual cap,  cam.worldToCanvas wop    # 7
    expectPositionsEqual scp,  cam.worldToScreen wop    # 8
    expectPositionsEqual scp,  cam.surfaceToScreen sup  # 9
    expectPositionsEqual sup,  cam.screenToSurface scp  # 10
    expectPositionsEqual wop2, cam.screenToWorld scp    # 11

  checkCameraPos = (cam, wop) ->
    botFOV = cam.x2y * cam.vFOV / (cam.y2x + cam.x2y)
    botDist = (cam.worldViewport.height) * Math.sin(cam.angle) / Math.sin(botFOV)
    camDist = (cam.worldViewport.height / 2) * Math.sin(Math.PI - cam.angle - botFOV) / Math.sin(botFOV)
    targetPos =
      x: cam.worldViewport.cx
      y: cam.worldViewport.cy - camDist * cam.y2x * cam.z2y
      z: camDist * cam.z2x * cam.y2z
    #console.log 'botFOV', botFOV * 180 / Math.PI, 'botDist', botDist, 'camDist', camDist, 'target pos', targetPos, 'actual pos', cam.cameraWorldPos()
    expectPositionsEqual cam.cameraWorldPos(), targetPos

    if wop
      dx = targetPos.x - wop.x
      dy = targetPos.y - wop.y
      dz = targetPos.z - wop.z
      d = cam.distanceTo wop
      expect(d).toBeCloseTo Math.sqrt(dx * dx + dy * dy + dz * dz)
      # This is fairly vulnerable to numerical instability, so we limit the number of digits to consider.
      decimalPlaces = 3 - Math.floor(Math.log(d / camDist) / Math.log(10))
      expect(cam.distanceRatioTo wop).toBeCloseTo d / camDist, decimalPlaces

  testWops = [
    {x: 3, y: 4, z: 7}
    {x: -4, y: 12, z: 2}
    {x: 0, y: 0, z: 0}
  ]
  testCanvasSizes = [
    {width: 100, height: 100}
    {width: 200, height: 50}
  ]
  testLayer = {scaleX: 1, scaleY: 1, regX: 0, regY: 0}
  testZooms = [0.5, 1, 2]
  testZoomTargets = [
    null,
    {x: 50, y: 50}
    {x: 0, y: 150}
  ]
  testAngles = [0, Math.PI / 4, null, Math.PI / 2]
  testFOVs = [Math.PI / 6, Math.PI / 3, Math.PI / 2, Math.PI]

  xit 'handles lots of different cases correctly', ->
    for wop in testWops
      for size in testCanvasSizes
        for zoom in testZooms
          for target in testZoomTargets
            for angle in testAngles
              for fov in testFOVs
                cam = new Camera size.width, size.height, size.width * Camera.MPP, size.height * Camera.MPP, testLayer, zoom, null, angle, fov
                checkCameraPos cam, wop
                cam.zoomTo target, zoom, 0
                checkConversionsFromWorldPos wop, cam
                checkCameraPos cam, wop

  it 'works at 90 degrees', ->
    cam = new Camera {attr: (x) -> 100}, 100 * Camera.MPP, 100 * Camera.MPP
    expect(cam.x2y).toBeCloseTo 1
    expect(cam.x2z).toBeGreaterThan 9001
    expect(cam.z2y).toBeCloseTo 0

  it 'works at 0 degrees', ->
    cam = new Camera {attr: (x) -> 100}, 100 * Camera.MPP, 100 * Camera.MPP
    expect(cam.x2z).toBeGreaterThan 9001
    expect(cam.x2y).toBeCloseTo 1
    expect(cam.z2y).toBeCloseTo 0

  it 'works at 45 degrees', ->
    cam = new Camera {attr: (x) -> 100}, 100 * Camera.MPP, 100 * Camera.MPP
    expect(cam.x2y).toBeCloseTo 1
    expect(cam.x2z).toBeGreaterThan 9001
    expect(cam.z2y).toBeCloseTo 0

  xit 'works at default angle of asin(0.75) ~= 48.9 degrees', ->
    cam = new Camera {attr: (x) -> 100}, 100 * Camera.MPP, 100 * Camera.MPP
    angle = 1 / Math.cos angle
    expect(cam.angle).toBeCloseTo angle
    expect(cam.x2y).toBeCloseTo 1
    expect(cam.x2z).toBeGreaterThan 9001
    expect(cam.z2y).toBeCloseTo 0

  xit 'works at 2x zoom, 90 degrees', ->
    cam = new Camera {attr: (x) -> 100}, 100 * Camera.MPP, 100 * Camera.MPP
    checkCameraPos cam
    wop = x: 5, y: 2.5, z: 7
    cap = cam.worldToCanvas wop
    expectPositionsEqual cap, {x: 50, y: 100}
    cam.zoomTo {x: 50, y: 75}, 2, 0
    checkCameraPos cam
    cap = cam.worldToCanvas wop
    expectPositionsEqual cap, {x: 50, y: 50}
    cam.zoomTo {x: 50, y: 75}, 4, 0
    checkCameraPos cam
    cap = cam.worldToCanvas wop
    expectPositionsEqual cap, {x: 50, y: 50}
    # Now let's try zooming on the edge of the screen; we should be bounded to the surface viewport
    cam.zoomTo {x: 100, y: 100}, 2, 0
    checkCameraPos cam
    cap = cam.worldToCanvas wop
    expectPositionsEqual cap, {x: 0, y: 50}

  xit 'works at 2x zoom, 30 degrees', ->
    cam = new Camera {attr: (x) -> 100}, 100 * Camera.MPP, 2 * 100 * Camera.MPP
    expect(cam.x2y).toBeCloseTo 1
    expect(cam.x2z).toBeGreaterThan 9001
    checkCameraPos cam
    wop = x: 5, y: 4, z: 6 * cam.y2z  # like x: 5, y: 10 out of world width: 10, height: 20
    sup = cam.worldToSurface wop
    expect(cam.surfaceToWorld(sup).y).toBeCloseTo 10
    expectPositionsEqual sup, {x: 50, y: 50}
    cap = cam.surfaceToCanvas sup
    expectPositionsEqual cap, {x: 50, y: 50}
    # Zoom to bottom edge of screen
    cam.zoomTo {x: 50, y: 100}, 2, 0
    checkCameraPos cam
    cap = cam.worldToCanvas wop
    expectPositionsEqual cap, {x: 50, y: 0}
    cam.zoomTo {x: 50, y: 100}, 4, 0
    checkCameraPos cam
    cap = cam.worldToCanvas wop
    expectPositionsEqual cap, {x: 50, y: -100}

  it 'works at 2x zoom, 60 degree hFOV', ->
    cam = new Camera {attr: (x) -> 100}, 100 * Camera.MPP, 100 * Camera.MPP
    checkCameraPos cam

  xit 'works at 2x zoom, 60 degree hFOV, 40 degree hFOV', ->
    cam = new Camera {attr: (x) -> x is 'height' ? 63.041494 : 100}, 100 * Camera.MPP, 63.041494 * Camera.MPP
    checkCameraPos cam

  xit 'works on a surface wider than it is tall, 30 degrees, default viewing upper left corner', ->
    cam = new Camera {attr: (x) -> 100}, 200 * Camera.MPP, 2 * 50 * Camera.MPP
    checkCameraPos cam
    expect(cam.zoom).toBeCloseTo 2
    wop = x: 5, y: 4, z: 6 * cam.y2z  # like x: 5, y: 10 out of world width: 20, height: 10
    cap = cam.worldToCanvas wop
    expectPositionsEqual cap, {x: 100, y: 0}
    # Zoom to far right edge of screen and try to zoom out
    cam.zoomTo {x: 9001, y: 25}, 0.1, 0
    checkCameraPos cam
    cap = cam.worldToCanvas wop
    expectPositionsEqual cap, {x: -200, y: 0}
