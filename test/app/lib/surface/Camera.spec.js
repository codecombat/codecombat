/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS205: Consider reworking code to avoid use of IIFEs
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
describe('Camera (Surface point of view)', function() {
  const Camera = require('lib/surface/Camera');

  const expectPositionsEqual = function(p1, p2) {
    expect(p1.x).toBeCloseTo(p2.x);
    expect(p1.y).toBeCloseTo(p2.y);
    if (p2.z != null) { return expect(p1.z).toBeCloseTo(p2.z); }
  };

  const checkConversionsFromWorldPos = function(wop, cam) {
    // wop = world pos
    // sup = surface pos
    // cap = canvas pos
    // scp = screen pos

    const sup = cam.worldToSurface(wop);
    expect(sup.x).toBeCloseTo(wop.x * Camera.PPM);
    expect(sup.y).toBeCloseTo(-(wop.y + (wop.z * cam.z2y)) * cam.y2x * Camera.PPM);

    const cap = cam.worldToCanvas(wop);
    expect(cap.x).toBeCloseTo((sup.x - cam.surfaceViewport.x) * cam.zoom);
    expect(cap.y).toBeCloseTo((sup.y - cam.surfaceViewport.y) * cam.zoom);

    const scp = cam.worldToScreen(wop);
    // If we ever want to use screen conversion, then make it and add this test
    //expect(scp.x).toBeCloseTo cap.x * @someCanvasToScreenXScaleFactor
    //expect(scp.y).toBeCloseTo cap.y * @someCanvasToScreenYScaleFactor

    const wop2 = cam.surfaceToWorld(sup);
    expect(wop2.x).toBeCloseTo(wop.x);
    expect(wop2.y).toBeCloseTo(wop.y + (wop.z * cam.z2y));

    // Make sure to call all twelve conversions in here. Can be redundant.
    expectPositionsEqual(sup,  cam.worldToSurface(wop2));  // 0
    expectPositionsEqual(cap,  cam.surfaceToCanvas(sup));  // 1
    expectPositionsEqual(scp,  cam.canvasToScreen(cap));   // 2
    expectPositionsEqual(cap,  cam.screenToCanvas(scp));   // 3
    expectPositionsEqual(sup,  cam.canvasToSurface(cap));  // 4
    expectPositionsEqual(wop2, cam.surfaceToWorld(sup));   // 5
    expectPositionsEqual(wop2, cam.canvasToWorld(cap));    // 6
    expectPositionsEqual(cap,  cam.worldToCanvas(wop));    // 7
    expectPositionsEqual(scp,  cam.worldToScreen(wop));    // 8
    expectPositionsEqual(scp,  cam.surfaceToScreen(sup));  // 9
    expectPositionsEqual(sup,  cam.screenToSurface(scp));  // 10
    return expectPositionsEqual(wop2, cam.screenToWorld(scp));    // 11
  };

  const checkCameraPos = function(cam, wop) {
    const botFOV = (cam.x2y * cam.vFOV) / (cam.y2x + cam.x2y);
    const botDist = ((cam.worldViewport.height) * Math.sin(cam.angle)) / Math.sin(botFOV);
    const camDist = ((cam.worldViewport.height / 2) * Math.sin(Math.PI - cam.angle - botFOV)) / Math.sin(botFOV);
    const targetPos = {
      x: cam.worldViewport.cx,
      y: cam.worldViewport.cy - (camDist * cam.y2x * cam.z2y),
      z: camDist * cam.z2x * cam.y2z
    };
    //console.log 'botFOV', botFOV * 180 / Math.PI, 'botDist', botDist, 'camDist', camDist, 'target pos', targetPos, 'actual pos', cam.cameraWorldPos()
    expectPositionsEqual(cam.cameraWorldPos(), targetPos);

    if (wop) {
      const dx = targetPos.x - wop.x;
      const dy = targetPos.y - wop.y;
      const dz = targetPos.z - wop.z;
      const d = cam.distanceTo(wop);
      expect(d).toBeCloseTo(Math.sqrt((dx * dx) + (dy * dy) + (dz * dz)));
      // This is fairly vulnerable to numerical instability, so we limit the number of digits to consider.
      const decimalPlaces = 3 - Math.floor(Math.log(d / camDist) / Math.log(10));
      return expect(cam.distanceRatioTo(wop)).toBeCloseTo(d / camDist, decimalPlaces);
    }
  };

  const testWops = [
    {x: 3, y: 4, z: 7},
    {x: -4, y: 12, z: 2},
    {x: 0, y: 0, z: 0}
  ];
  const testCanvasSizes = [
    {width: 100, height: 100},
    {width: 200, height: 50}
  ];
  const testLayer = {scaleX: 1, scaleY: 1, regX: 0, regY: 0};
  const testZooms = [0.5, 1, 2];
  const testZoomTargets = [
    null,
    {x: 50, y: 50},
    {x: 0, y: 150}
  ];
  const testAngles = [0, Math.PI / 4, null, Math.PI / 2];
  const testFOVs = [Math.PI / 6, Math.PI / 3, Math.PI / 2, Math.PI];

  it('handles lots of different cases correctly', () => Array.from(testWops).map((wop) =>
    Array.from(testCanvasSizes).map((size) =>
      Array.from(testZooms).map((zoom) =>
        Array.from(testZoomTargets).map((target) =>
          Array.from(testAngles).map((angle) =>
            (() => {
              const result = [];
              for (var fov of Array.from(testFOVs)) {
                var cam = new Camera({attr(attr) { if ('attr' === 'width') { return size.width; } else { return size.height; } }}, angle, fov);
                checkCameraPos(cam, wop);
                cam.zoomTo(target, zoom, 0);
                checkConversionsFromWorldPos(wop, cam);
                result.push(checkCameraPos(cam, wop));
              }
              return result;
            })()))))));

  it('works at default angle of asin(0.75) ~= 48.9 degrees', function() {
    const cam = new Camera({attr(attr) { return 100; }}, null);
    const angle = Math.asin(3 / 4);
    expect(cam.angle).toBeCloseTo(angle);
    expect(cam.x2y).toBeCloseTo(4 / 3);
    expect(cam.x2z).toBeCloseTo(1 / Math.cos(angle));
    return expect(cam.z2y).toBeCloseTo((4 / 3) * Math.cos(angle));
  });

  xit('works at 2x zoom, 90 degrees', function() {
    const cam = new Camera({attr(attr) { return 100; }}, Math.PI / 2);
    cam.zoomTo(null, 2, 0);
    checkCameraPos(cam);
    const wop = {x: 5, y: 2.5, z: 7};
    let cap = cam.worldToCanvas(wop);
    expectPositionsEqual(cap, {x: 50, y: 100});
    cam.zoomTo({x: 50, y: 75}, 2, 0);
    checkCameraPos(cam);
    cap = cam.worldToCanvas(wop);
    expectPositionsEqual(cap, {x: 50, y: 50});
    cam.zoomTo({x: 50, y: 75}, 4, 0);
    checkCameraPos(cam);
    cap = cam.worldToCanvas(wop);
    expectPositionsEqual(cap, {x: 50, y: 50});
    // Now let's try zooming on the edge of the screen; we should be bounded to the surface viewport
    cam.zoomTo({x: 100, y: 100}, 2, 0);
    checkCameraPos(cam);
    cap = cam.worldToCanvas(wop);
    return expectPositionsEqual(cap, {x: 0, y: 50});
});

  xit('works at 2x zoom, 30 degrees', function() {
    const cam = new Camera({attr(attr) { return 100; }}, Math.PI / 6);
    cam.zoomTo(null, 2, 0);
    expect(cam.x2y).toBeCloseTo(1);
    expect(cam.x2z).toBeGreaterThan(9001);
    checkCameraPos(cam);
    const wop = {x: 5, y: 4, z: 6 * cam.y2z};  // like x: 5, y: 10 out of world width: 10, height: 20
    const sup = cam.worldToSurface(wop);
    expect(cam.surfaceToWorld(sup).y).toBeCloseTo(10);
    expectPositionsEqual(sup, {x: 50, y: 50});
    let cap = cam.surfaceToCanvas(sup);
    expectPositionsEqual(cap, {x: 50, y: 50});
    // Zoom to bottom edge of screen
    cam.zoomTo({x: 50, y: 100}, 2, 0);
    checkCameraPos(cam);
    cap = cam.worldToCanvas(wop);
    expectPositionsEqual(cap, {x: 50, y: 0});
    cam.zoomTo({x: 50, y: 100}, 4, 0);
    checkCameraPos(cam);
    cap = cam.worldToCanvas(wop);
    return expectPositionsEqual(cap, {x: 50, y: -100});
});

  it('works at 2x zoom, 60 degree hFOV', function() {
    const cam = new Camera({attr(attr) { return 100; }}, null, Math.PI / 3);
    cam.zoomTo(null, 2, 0);
    return checkCameraPos(cam);
  });

  it('works at 2x zoom, 60 degree hFOV, 40 degree vFOV', function() {
    const cam = new Camera({attr(attr) { if (attr === 'height') { return 63.041494; } else { return 100; } }}, null, Math.PI / 3);
    cam.zoomTo(null, 2, 0);
    return checkCameraPos(cam);
  });

  return xit('works at 2x zoom on a surface wider than it is tall, 30 degrees, default viewing upper left corner', function() {
    const cam = new Camera({attr(attr) { return 100; }}, Math.PI / 6);  // 200 * Camera.MPP, 2 * 50 * Camera.MPP
    cam.zoomTo(null, 2, 0);
    checkCameraPos(cam);
    expect(cam.zoom).toBeCloseTo(2);
    const wop = {x: 5, y: 4, z: 6 * cam.y2z};  // like x: 5, y: 10 out of world width: 20, height: 10
    let cap = cam.worldToCanvas(wop);
    expectPositionsEqual(cap, {x: 100, y: 0});
    // Zoom to far right edge of screen and try to zoom out
    cam.zoomTo({x: 9001, y: 25}, 0.1, 0);
    checkCameraPos(cam);
    cap = cam.worldToCanvas(wop);
    return expectPositionsEqual(cap, {x: -200, y: 0});
});
});
