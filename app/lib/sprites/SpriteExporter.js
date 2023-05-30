// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS002: Fix invalid constructor
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS205: Consider reworking code to avoid use of IIFEs
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
import SpriteBuilder from './SpriteBuilder';

import ThangType from 'models/ThangType';
import CocoClass from 'core/CocoClass';
import createjs from 'lib/createjs-parts';


class SpriteExporter extends CocoClass {
  static initClass() {
    `\
To be used by the ThangTypeEditView to export ThangTypes to single sprite sheets which can be uploaded to
GridFS and used in gameplay, avoiding rendering vector images.
  
Code has been copied and reworked and simplified from LayerAdapter. Some shared code has been refactored into
ThangType, but more work could be done to rethink and reorganize Sprite rendering.\
`;
  }

  constructor(thangType, options) {
    this.thangType = thangType;
    if (options == null) { options = {}; }
    this.colorConfig = options.colorConfig || {};
    this.resolutionFactor = options.resolutionFactor || 1;
    this.actionNames = options.actionNames || (Array.from(this.thangType.getDefaultActions()).map((action) => action.name));
    this.spriteType = options.spriteType || this.thangType.get('spriteType') || 'segmented';
    super();
  }

  build() {
    const spriteSheetBuilder = new createjs.SpriteSheetBuilder();
    if (this.spriteType === 'segmented') {
      this.renderSegmentedThangType(spriteSheetBuilder);
    } else {
      this.renderSingularThangType(spriteSheetBuilder);
    }
    try {
      spriteSheetBuilder.buildAsync();
    } catch (e) {
      this.resolutionFactor *= 0.9;
      return this.build();
    }
    spriteSheetBuilder.on('complete', this.onBuildSpriteSheetComplete, this, true, spriteSheetBuilder);
    return this.asyncBuilder = spriteSheetBuilder;
  }

  renderSegmentedThangType(spriteSheetBuilder) {
    const containersToRender = this.thangType.getContainersForActions(this.actionNames);
    const spriteBuilder = new SpriteBuilder(this.thangType, {colorConfig: this.colorConfig});
    return (() => {
      const result = [];
      for (var containerGlobalName of Array.from(containersToRender)) {
        var container = spriteBuilder.buildContainerFromStore(containerGlobalName);
        var frame = spriteSheetBuilder.addFrame(container, null, this.resolutionFactor * (this.thangType.get('scale') || 1));
        result.push(spriteSheetBuilder.addAnimation(containerGlobalName, [frame], false));
      }
      return result;
    })();
  }

  renderSingularThangType(spriteSheetBuilder) {
    let a, action, actions, scale;
    let frame;
    const actionObjects = _.values(this.thangType.getActions());
    const animationActions = [];
    for (a of Array.from(actionObjects)) {
      if (!a.animation) { continue; }
      if (!Array.from(this.actionNames).includes(a.name)) { continue; }
      animationActions.push(a);
    }

    const spriteBuilder = new SpriteBuilder(this.thangType, {colorConfig: this.colorConfig});

    const animationGroups = _.groupBy(animationActions, action => action.animation);
    for (var animationName in animationGroups) {
      actions = animationGroups[animationName];
      scale = actions[0].scale || this.thangType.get('scale') || 1;
      var mc = spriteBuilder.buildMovieClip(animationName, null, null, null, {'temp':0});
      spriteSheetBuilder.addMovieClip(mc, null, scale * this.resolutionFactor);
      var {
        frames
      } = spriteSheetBuilder._animations['temp'];
      var framesMap = _.zipObject(_.range(frames.length), frames);
      for (action of Array.from(actions)) {
        if (action.frames) {
          frames = ((() => {
            const result = [];
            for (frame of Array.from(action.frames.split(','))) {               result.push(framesMap[parseInt(frame)]);
            }
            return result;
          })());
        } else {
          frames = _.sortBy(_.values(framesMap));
        }
        var next = this.thangType.nextForAction(action);
        spriteSheetBuilder.addAnimation(action.name, frames, next);
      }
    }

    const containerActions = [];
    for (a of Array.from(actionObjects)) {
      if (!a.container) { continue; }
      if (!Array.from(this.actionNames).includes(a.name)) { continue; }
      containerActions.push(a);
    }

    const containerGroups = _.groupBy(containerActions, action => action.container);
    return (() => {
      const result1 = [];
      for (var containerName in containerGroups) {
        actions = containerGroups[containerName];
        var container = spriteBuilder.buildContainerFromStore(containerName);
        scale = actions[0].scale || this.thangType.get('scale') || 1;
        frame = spriteSheetBuilder.addFrame(container, null, scale * this.resolutionFactor);
        result1.push((() => {
          const result2 = [];
          for (action of Array.from(actions)) {
            result2.push(spriteSheetBuilder.addAnimation(action.name, [frame], false));
          }
          return result2;
        })());
      }
      return result1;
    })();
  }

  onBuildSpriteSheetComplete(e, builder) {
    if (builder.spriteSheet._images.length > 1) {
      let total = 0;
      // get a rough estimate of how much smaller the spritesheet needs to be
      for (let index = 0; index < builder.spriteSheet._images.length; index++) {
        var image = builder.spriteSheet._images[index];
        total += image.height / builder.maxHeight;
      }
      this.resolutionFactor /= (Math.max(1.1, Math.sqrt(total)));
      this._renderNewSpriteSheet(e.async);
      return;
    }

    return this.trigger('build', { spriteSheet: builder.spriteSheet });
  }
}
SpriteExporter.initClass();



export default SpriteExporter;
