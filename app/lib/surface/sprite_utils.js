/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let createProgressBar;
const createjs = require('lib/createjs-parts');

const WIDTH = 20;
const HEIGHT = 2;
const EDGE = 0.3;

module.exports.createProgressBar = (createProgressBar = function(color) {
  const g = new createjs.Graphics();
  g.setStrokeStyle(1);
  g.beginFill(createjs.Graphics.getRGB(0, 0, 0));
  g.drawRect(0, -HEIGHT/2, WIDTH, HEIGHT, HEIGHT);
  g.beginFill(createjs.Graphics.getRGB(...Array.from(color || [])));
  g.drawRoundRect(EDGE, EDGE - (HEIGHT/2), WIDTH-(EDGE*2), HEIGHT-(EDGE*2), HEIGHT-(EDGE*2));
  const s = new createjs.Shape(g);
  s.z = 100;
  s.bounds = [0, -HEIGHT/2, WIDTH, HEIGHT];
  return s;
});
