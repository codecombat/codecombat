/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS103: Rewrite code to no longer use __guard__, or convert again using --optional-chaining
 * DS104: Avoid inline assignments
 * DS205: Consider reworking code to avoid use of IIFEs
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let SpriteParser;
const createjs = require('lib/createjs-parts');
const esprima = require('esprima');

module.exports = (SpriteParser = class SpriteParser {
  constructor(thangTypeModel) {
    // Create a new ThangType, or work with one we've been building
    this.thangTypeModel = thangTypeModel;
    this.thangType = $.extend(true, {}, this.thangTypeModel.attributes.raw);
    if (this.thangType == null) { this.thangType = {}; }
    if (this.thangType.shapes == null) { this.thangType.shapes = {}; }
    if (this.thangType.containers == null) { this.thangType.containers = {}; }
    if (this.thangType.animations == null) { this.thangType.animations = {}; }

    // Internal parser state
    this.shapeLongKeys = {};
    this.containerLongKeys = {};
    this.containerRenamings = {};
    this.animationLongKeys = {};
    this.animationRenamings = {};
    this.populateLongKeys();
  }

  populateLongKeys() {
    let longKey, shortKey;
    for (shortKey in this.thangType.shapes) {
      var shape = this.thangType.shapes[shortKey];
      longKey = JSON.stringify(_.values(shape));
      this.shapeLongKeys[longKey] = shortKey;
    }
    for (shortKey in this.thangType.containers) {
      var container = this.thangType.containers[shortKey];
      longKey = JSON.stringify(_.values(container));
      this.containerLongKeys[longKey] = shortKey;
    }
    return (() => {
      const result = [];
      for (shortKey in this.thangType.animations) {
        var animation = this.thangType.animations[shortKey];
        longKey = JSON.stringify(_.values(animation));
        result.push(this.animationLongKeys[longKey] = shortKey);
      }
      return result;
    })();
  }

  parse(source) {
    // Grab the library properties' width/height so we can subtract half of each from frame bounds
    let bounds, index, left, localContainers, localShapes, movieClip, shapeKeys;
    const properties = source.match(/.*lib\.properties = \{\n.*?width: (\d+),\n.*?height: (\d+)/im);
    this.width = parseInt((properties != null ? properties[1] : undefined) != null ? (properties != null ? properties[1] : undefined) : '0', 10);
    this.height = parseInt((properties != null ? properties[2] : undefined) != null ? (properties != null ? properties[2] : undefined) : '0', 10);

    // Remove webfontAvailable line, not relevant
    source = source.replace(/lib\.webfontAvailable = (.|\n)+?};/, '');

    const options = {loc: false, range: true};
    const ast = esprima.parse(source, options);
    const blocks = this.findBlocks(ast, source);
    const containers = _.filter(blocks, {kind: 'Container'});
    const movieClips = _.filter(blocks, {kind: 'MovieClip'});

    const mainClip = (left = _.last(movieClips)) != null ? left : _.last(containers);
    this.animationName = mainClip.name;
    for (index = 0; index < containers.length; index++) {
      var c;
      var container = containers[index];
      if ((index === (containers.length - 1)) && !movieClips.length && (container.bounds != null ? container.bounds.length : undefined)) {
        container.bounds[0] -= this.width / 2;
        container.bounds[1] -= this.height / 2;
      }
      [shapeKeys, localShapes] = Array.from(this.getShapesFromBlock(container, source));
      localContainers = this.getContainersFromMovieClip(container, source, true); // Added true because anya attack was breaking, but might break other imports
      var addChildArgs = this.getAddChildCallArguments(container, source);
      var instructions = [];
      for (var bn of Array.from(addChildArgs)) {
        var gotIt = false;
        for (var shape of Array.from(localShapes)) {
          if (shape.bn === bn) {
            instructions.push(shape.gn);
            gotIt = true;
            break;
          }
        }
        if (gotIt) { continue; }
        for (c of Array.from(localContainers)) {
          if (c.bn === bn) {
            instructions.push({t: c.t, gn: c.gn});
            break;
          }
        }
      }
      if (!container.bounds || !instructions.length) { continue; }
      this.addContainer({c: instructions, b: container.bounds}, container.name);
    }

    const childrenMovieClips = [];

    for (index = 0; index < movieClips.length; index++) {
      movieClip = movieClips[index];
      var lastBounds = null;
      // fill in bounds which are null...
      for (var boundsIndex = 0; boundsIndex < movieClip.frameBounds.length; boundsIndex++) {
        bounds = movieClip.frameBounds[boundsIndex];
        if (!bounds) {
          movieClip.frameBounds[boundsIndex] = _.clone(lastBounds);
        } else {
          lastBounds = bounds;
        }
      }

      var localGraphics = this.getGraphicsFromBlock(movieClip, source);
      [shapeKeys, localShapes] = Array.from(this.getShapesFromBlock(movieClip, source));
      localContainers = this.getContainersFromMovieClip(movieClip, source, true);
      var localAnimations = this.getAnimationsFromMovieClip(movieClip, source, true);
      for (var animation of Array.from(localAnimations)) {
        childrenMovieClips.push(animation.gn);
      }
      var localTweens = this.getTweensFromMovieClip(movieClip, source, localShapes, localContainers, localAnimations);
      this.addAnimation({
        shapes: localShapes,
        containers: localContainers,
        animations: localAnimations,
        tweens: localTweens,
        graphics: localGraphics,
        bounds: movieClip.bounds,
        frameBounds: movieClip.frameBounds
      }, movieClip.name);
    }

    for (movieClip of Array.from(movieClips)) {
      if (!Array.from(childrenMovieClips).includes(movieClip.name)) {
        for (bounds of Array.from(movieClip.frameBounds)) {
          bounds[0] -= this.width / 2;
          bounds[1] -= this.height / 2;
        }
        movieClip.bounds[0] -= this.width / 2;
        movieClip.bounds[1] -= this.height / 2;
      }
    }

    this.saveToModel();
    return (movieClips[0] != null ? movieClips[0].name : undefined);
  }

  saveToModel() {
    return this.thangTypeModel.set('raw', this.thangType);
  }

  addShape(shape) {
    const longKey = JSON.stringify(_.values(shape));
    let shortKey = this.shapeLongKeys[longKey];
    if (shortKey == null) {
      shortKey = '' + _.size(this.thangType.shapes);
      while (this.thangType.shapes[shortKey]) { shortKey += '+'; }
      this.thangType.shapes[shortKey] = shape;
      this.shapeLongKeys[longKey] = shortKey;
    }
    return shortKey;
  }

  addContainer(container, name) {
    const longKey = JSON.stringify(_.values(container));
    let shortKey = this.containerLongKeys[longKey];
    if ((shortKey == null)) {
      shortKey = name;
      if (this.thangType.containers[shortKey] != null) {
        shortKey = this.animationName + ':' + name;
      }
      this.thangType.containers[shortKey] = container;
      this.containerLongKeys[longKey] = shortKey;
    }
    this.containerRenamings[name] = shortKey;
    return shortKey;
  }

  addAnimation(animation, name) {
    const longKey = JSON.stringify(_.values(animation));
    let shortKey = this.animationLongKeys[longKey];
    if (shortKey != null) {
      this.animationRenamings[shortKey] = name;
    } else {
      shortKey = name;
      if (this.thangType.animations[shortKey] != null) {
        shortKey = this.animationName + ':' + name;
      }
      this.thangType.animations[shortKey] = animation;
      this.animationLongKeys[longKey] = shortKey;
      this.animationRenamings[name] = shortKey;
    }
    return shortKey;
  }

  walk(node, parent, fn) {
    node.parent = parent;
    for (var key in node) {
      var child = node[key];
      if (key === 'parent') { continue; }
      if (_.isArray(child)) {
        for (var grandchild of Array.from(child)) {
          if (_.isString(grandchild != null ? grandchild.type : undefined)) { this.walk(grandchild, node, fn); }
        }
      } else if (_.isString(child != null ? child.type : undefined)) {
        node.parent = parent;
        this.walk(child, node, fn);
      }
    }
    return fn(node);
  }

  orphanify(node) {
    if (node.parent) { delete node.parent; }
    return (() => {
      const result = [];
      for (var key in node) {
        var child = node[key];
        if (key === 'parent') { continue; }
        if (_.isArray(child)) {
          result.push((() => {
            const result1 = [];
            for (var grandchild of Array.from(child)) {
              if (_.isString(grandchild != null ? grandchild.type : undefined)) { result1.push(this.orphanify(grandchild)); } else {
                result1.push(undefined);
              }
            }
            return result1;
          })());
        } else if (_.isString(child != null ? child.type : undefined)) {
          if (node.parent) { delete node.parent; }
          result.push(this.orphanify(child));
        } else {
          result.push(undefined);
        }
      }
      return result;
    })();
  }

  subSourceFromRange(range, source) {
    return source.slice(range[0] ,  range[1]);
  }

  grabFunctionArguments(source, literal) {
    // Replace first and last parens with brackets to turn args into array
    if (literal == null) { literal = false; }
    const args = source.replace(/.*?\(/, '[').replace(/\)[^)]*?$/, ']');
    if (literal) { return eval(args); } else { return args; }
  }

  findBlocks(ast, source) {
    const functionExpressions = [];
    const rectangles = [];
    const gatherFunctionExpressions = node => {
      if (node.type === 'FunctionExpression') {
        const name = __guard__(__guard__(node.parent != null ? node.parent.left : undefined, x1 => x1.property), x => x.name);
        if (name) {
          let bounds, frameBounds;
          const expression = node.parent.parent;
          if (!__guard__(expression.parent != null ? expression.parent.right : undefined, x2 => x2.right)) {
            if (/frame_[\d]+/.test(name)) {  // Skip some useless KR function things
              return;
            }
          }
          const kind = expression.parent.right.right.callee.property.name;
          const statement = node.parent.parent.parent.parent;
          const statementIndex = _.indexOf(statement.parent.body, statement);
          const nominalBoundsStatement = statement.parent.body[statementIndex + 1];
          const nominalBoundsRange = nominalBoundsStatement.expression.right.range;
          const nominalBoundsSource = this.subSourceFromRange(nominalBoundsRange, source);
          const nominalBounds = this.grabFunctionArguments(nominalBoundsSource, true);

          const frameBoundsStatement = statement.parent.body[statementIndex + 2];
          if (frameBoundsStatement) {
            const frameBoundsRange = frameBoundsStatement.expression.right.range;
            const frameBoundsSource = this.subSourceFromRange(frameBoundsRange, source);
            if (frameBoundsSource.search(/\[rect/) === -1) {  // some other statement; we don't have multiframe bounds
              console.log('Didn\'t have multiframe bounds for this movie clip.');
              frameBounds = [_.clone(nominalBounds)];
            } else {
              let lastRect = nominalBounds;
              frameBounds = [];
              for (let i = 0; i < frameBoundsStatement.expression.right.elements.length; i++) {
                var arg = frameBoundsStatement.expression.right.elements[i];
                bounds = null;
                var argSource = this.subSourceFromRange(arg.range, source);
                if (arg.type === 'Identifier') {
                  bounds = lastRect;
                } else if (arg.type === 'NewExpression') {
                  bounds = this.grabFunctionArguments(argSource, true);
                } else if (arg.type === 'AssignmentExpression') {
                  bounds = this.grabFunctionArguments(argSource.replace('rect=', ''), true);
                  lastRect = bounds;
                } else if ((arg.type === 'Literal') && (arg.value === null)) {
                  bounds = [0, 0, 1, 1];  // Let's try this.
                }
                frameBounds.push(_.clone(bounds));
              }
            }
          } else {
            frameBounds = [_.clone(nominalBounds)];
          }

          return functionExpressions.push({name, bounds: nominalBounds, frameBounds, expression: node.parent.parent, kind});
        }
      }
    };
    this.walk(ast, null, gatherFunctionExpressions);
    return functionExpressions;
  }

  /*
    this.shape_1.graphics.f('#605E4A').s().p('AAOD/IgOgaIAEhkIgmgdIgMgBIgPgFIgVgJQA1h9g8jXQAQAHAOASQAQAUAKAeQARAuAJBJQAHA/gBA5IAAADIACAfIAFARIACAGIAEAHIAHAHQAVAXAQAUQAUAaANAUIABACIgsgdIgggXIAAAnIABAwIgBgBg');
    this.shape_1.sett(23.2,30.1);

    this.shape.graphics.f().s('#000000').ss(0.1,1,1).p('AAAAAQAAAAAAAA');
    this.shape.sett(3.8,22.4);
  */

  getGraphicsFromBlock(block, source) {
    block = block.expression.object.right.body;
    const localGraphics = [];
    const gatherShapeDefinitions = function(node) {
      if ((node.type !== 'NewExpression') || (node.callee.property.name !== 'Graphics')) { return; }
      const blockName = node.parent.parent.parent.id.name;
      const graphicsString = node.parent.parent.arguments[0].value;
      return localGraphics.push({p:graphicsString, bn:blockName});
    }.bind(this);

    this.walk(block, null, gatherShapeDefinitions);
    return localGraphics;
  }

  getShapesFromBlock(block, source) {
    block = block.expression.object.right.body;
    const shapeKeys = [];
    const localShapes = [];
    const gatherShapeDefinitions = function(node) {
      let drawEllipse, fillColor, linearGradientFill, linearGradientStroke, mask, path, radialGradientFill, shape, shapeKey, strokeColor;
      if (node.type !== 'MemberExpression') { return; }
      let name = __guard__(__guard__(node.object != null ? node.object.object : undefined, x1 => x1.property), x => x.name);
      if (!name) {
        name = __guard__(__guard__(node.parent != null ? node.parent.parent : undefined, x3 => x3.id), x2 => x2.name);
        if (!name || (name.indexOf('mask') !== 0) || ((node.property != null ? node.property.name : undefined) !== 'Shape')) { return; }
        shape = {bn: name, im: true};
        localShapes.push(shape);
        return;
      }
      if ((name.search('shape') !== 0) || ((node.object.property != null ? node.object.property.name : undefined) !== 'graphics')) { return; }
      const fillCall = node.parent;
      if (fillCall.callee.property.name === 'lf') {
        const linearGradientFillSource = this.subSourceFromRange(fillCall.parent.range, source);
        linearGradientFill = this.grabFunctionArguments(linearGradientFillSource.replace(/.*?lf\(/, 'lf('), true);
      } else if (fillCall.callee.property.name === 'rf') {
        const radialGradientFillSource = this.subSourceFromRange(fillCall.parent.range, source);
        radialGradientFill = this.grabFunctionArguments(radialGradientFillSource.replace(/.*?lf\(/, 'lf('), true);
      } else {
        fillColor = (fillCall.arguments[0] != null ? fillCall.arguments[0].value : undefined) != null ? (fillCall.arguments[0] != null ? fillCall.arguments[0].value : undefined) : null;
        const callName = fillCall.callee.property.name;
        if (callName !== 'f') { console.error('What is this?! Not a fill!', callName); }
      }
      const strokeCall = node.parent.parent.parent.parent;
      if (strokeCall.object.callee.property.name === 'ls') {
        const linearGradientStrokeSource = this.subSourceFromRange(strokeCall.parent.range, source);
        linearGradientStroke = this.grabFunctionArguments(linearGradientStrokeSource.replace(/.*?ls\(/, 'ls(').replace(/\).ss\(.*/, ')'), true);
      } else {
        strokeColor = __guard__(strokeCall.object.arguments != null ? strokeCall.object.arguments[0] : undefined, x4 => x4.value) != null ? __guard__(strokeCall.object.arguments != null ? strokeCall.object.arguments[0] : undefined, x4 => x4.value) : null;
        if (strokeCall.object.callee.property.name !== 's') { console.error('What is this?! Not a stroke!'); }
      }
      let strokeStyle = null;
      let graphicsStatement = strokeCall.parent;
      if (strokeColor || linearGradientStroke) {
        // There might now be an extra node, ss, for stroke style
        const strokeStyleSource = this.subSourceFromRange(strokeCall.parent.range, source);
        if (strokeStyleSource.search(/ss\(/) !== -1) {
          strokeStyle = this.grabFunctionArguments(strokeStyleSource.replace(/.*?ss\(/, 'ss('), true);
          graphicsStatement = strokeCall.parent.parent.parent;
        }
      }
      if (graphicsStatement.callee.property.name === 'de') {
        const drawEllipseSource = this.subSourceFromRange(graphicsStatement.parent.range, source);
        drawEllipse = this.grabFunctionArguments(drawEllipseSource.replace(/.*?de\(/, 'de('), true);
      } else {
        path = __guard__(graphicsStatement.arguments != null ? graphicsStatement.arguments[0] : undefined, x5 => x5.value) != null ? __guard__(graphicsStatement.arguments != null ? graphicsStatement.arguments[0] : undefined, x5 => x5.value) : null;
        if (graphicsStatement.callee.property.name !== 'p') { console.error('What is this?! Not a path!'); }
      }
      const {
        body
      } = graphicsStatement.parent.parent;
      const graphicsStatementIndex = _.indexOf(body, graphicsStatement.parent);
      let t = body[graphicsStatementIndex + 1].expression;
      const tSource = this.subSourceFromRange(t.range, source);
      if (tSource.search('setTransform') === -1) {
        t = [0, 0];
      } else {
        t = this.grabFunctionArguments(tSource, true);
      }

      for (var statement of Array.from(body.slice(graphicsStatementIndex + 2))) {
        // Handle things like
        // this.shape.mask = this.shape_1.mask = this.shape_2.mask = this.shape_3.mask = mask;
        if (__guard__(__guard__(statement.expression != null ? statement.expression.left : undefined, x7 => x7.property), x6 => x6.name) !== 'mask') { continue; }
        var exp = statement.expression;
        var matchedName = false;
        while (exp) {
          matchedName = matchedName || (__guard__(__guard__(exp.left != null ? exp.left.object : undefined, x9 => x9.property), x8 => x8.name) === name);
          mask = exp.name;
          exp = exp.right;
        }
        if (!matchedName) { continue; }
        break;
      }

      shape = {t};
      if (path) { shape.p = path; }
      if (drawEllipse) { shape.de = drawEllipse; }
      if (strokeColor) { shape.sc = strokeColor; }
      if (strokeStyle) { shape.ss = strokeStyle; }
      if (fillColor) { shape.fc = fillColor; }
      if (linearGradientFill) { shape.lf = linearGradientFill; }
      if (radialGradientFill) { shape.rf = radialGradientFill; }
      if (linearGradientStroke) { shape.ls = linearGradientStroke; }
      if ((name.search('shape') !== -1) && (shape.fc === 'rgba(0,0,0,0.451)') && !shape.ss && !shape.sc) {
        console.log('Skipping a shadow', name, shape, 'because we\'re doing shadows separately now.');
        return;
      }
      //if name.search('shape') isnt -1 and shape.fc is 'rgba(0,0,0,0.498)' and not shape.ss and not shape.sc
      //  console.log 'Skipping a KR shadow', name, shape, 'because we\'re doing shadows separately now.'
      //  return
      shapeKeys.push(shapeKey = this.addShape(shape));
      const localShape = {bn: name, gn: shapeKey};
      if (mask) { localShape.m = mask; }
      return localShapes.push(localShape);
    }.bind(this);

    this.walk(block, null, gatherShapeDefinitions);
    return [shapeKeys, localShapes];
  }

  getContainersFromMovieClip(movieClip, source, possibleAnimations) {
    if (possibleAnimations == null) { possibleAnimations = false; }
    const block = movieClip.expression.object.right.body;
    const localContainers = [];
    const gatherContainerDefinitions = function(node) {
      if ((node.type !== 'Identifier') || (node.name !== 'lib')) { return; }
      const args = node.parent.parent.arguments;
      const libName = node.parent.property.name;
      if (args.length && !possibleAnimations) { return; }  // might be animation, not container
      const gn = this.containerRenamings[libName];
      if (possibleAnimations && !gn) { return; }  // not a container we know about
      const bn = node.parent.parent.parent.left.property.name;
      const expressionStatement = node.parent.parent.parent.parent;
      const {
        body
      } = expressionStatement.parent;
      const expressionStatementIndex = _.indexOf(body, expressionStatement);
      let t = body[expressionStatementIndex + 1].expression;
      const tSource = this.subSourceFromRange(t.range, source);
      t = this.grabFunctionArguments(tSource, true);
      const o = body[expressionStatementIndex + 2].expression;
      const localContainer = {bn, t, gn};
      if (o && (__guard__(__guard__(o.left != null ? o.left.object : undefined, x1 => x1.property), x => x.name) === bn) && ((o.left.property != null ? o.left.property.name : undefined) === '_off')) {
        localContainer.o = o.right.value;
      } else if (o && (__guard__(o.left != null ? o.left.property : undefined, x2 => x2.name) === 'alpha')) {
        localContainer.al = o.right.value;
      }
      return localContainers.push(localContainer);
    }.bind(this);

    this.walk(block, null, gatherContainerDefinitions);
    return localContainers;
  }

  getAnimationsFromMovieClip(movieClip, source, possibleContainers) {
    if (possibleContainers == null) { possibleContainers = false; }
    const block = movieClip.expression.object.right.body;
    const localAnimations = [];
    const gatherAnimationDefinitions = function(node) {
      if ((node.type !== 'Identifier') || (node.name !== 'lib')) { return; }
      let args = node.parent.parent.arguments;
      const libName = node.parent.property.name;
      if (!args.length && !possibleContainers) { return; }  // might be container, not animation
      if (this.containerRenamings[libName] && !this.animationRenamings[libName]) { return; }  // we have it as a container
      args = this.grabFunctionArguments(this.subSourceFromRange(node.parent.parent.range, source), true);
      const bn = node.parent.parent.parent.left.property.name;
      const expressionStatement = node.parent.parent.parent.parent;
      const {
        body
      } = expressionStatement.parent;
      const expressionStatementIndex = _.indexOf(body, expressionStatement);
      let t = body[expressionStatementIndex + 1].expression;
      const tSource = this.subSourceFromRange(t.range, source);
      t = this.grabFunctionArguments(tSource, true);
      const gn = this.animationRenamings[libName] != null ? this.animationRenamings[libName] : libName;
      const localAnimation = {bn, t, gn, a: args};
      return localAnimations.push(localAnimation);
    }.bind(this);

    this.walk(block, null, gatherAnimationDefinitions);
    return localAnimations;
  }

  getTweensFromMovieClip(movieClip, source, localShapes, localContainers, localAnimations) {
    const block = movieClip.expression.object.right.body;
    const localTweens = [];
    const gatherTweens = node => {
      if ((node.property != null ? node.property.name : undefined) !== 'addTween') { return; }
      const callExpressions = [];
      const tweenNode = node;
      const gatherCallExpressions = function(node) {
        if (node.type !== 'CallExpression') { return; }
        const name = node.callee.property != null ? node.callee.property.name : undefined;
        if (!['get', 'to', 'wait'].includes(name)) { return; }
        if ((name === 'get') && callExpressions.length) { return; } // avoid Ease calls in the tweens
        const flattenedRanges = _.flatten([(Array.from(node.arguments).map((a) => a.range))]);
        const range = [_.min(flattenedRanges), _.max(flattenedRanges)];
        // Replace 'this.<local>' references with just the 'name'
        let argsSource = this.subSourceFromRange(range, source);
        argsSource = argsSource.replace(/mask/g, 'this.mask'); // so the mask thing will be handled correctly as a blockName in the next line
        argsSource = argsSource.replace(/this\.([a-z_0-9]+)/ig, '"$1"'); // turns this.shape literal to 'shape' string
        argsSource = argsSource.replace(/cjs(.+)\)/, '"createjs$1)"'); // turns cjs.Ease.get(0.5)
        if (argsSource === 'this') { argsSource = '{}'; } // not sure what this should be but it looks like we don't need it for KR sprites

        const args = eval(`[${argsSource}]`);
        let shadowTween = (__guardMethod__(args[0], 'search', o => o.search('shape')) === 0) && !_.find(localShapes, {bn: args[0]});
        shadowTween = shadowTween || ((__guardMethod__(__guard__(__guard__(args[0] != null ? args[0].state : undefined, x1 => x1[0]), x => x.t), 'search', o1 => o1.search('shape')) === 0) && !_.find(localShapes, {bn: args[0].state[0].t}));
        if (shadowTween) {
          console.log('Skipping tween', name, argsSource, args, 'from localShapes', localShapes, 'presumably because it\'s a shadow we skipped.');
          return;
        }
        return callExpressions.push({n: name, a: args});
      }.bind(this);
      this.walk(node.parent.parent, null, gatherCallExpressions);
      return localTweens.push(callExpressions);
    };

    this.walk(block, null, gatherTweens);
    return localTweens;
  }

  getAddChildCallArguments(block, source) {
    block = block.expression.object.right.body;
    const localArgs = [];
    const gatherAddChildCalls = function(node) {
      let arg;
      if ((node.type !== 'Identifier') || (node.name !== 'addChild')) { return; }
      let args = node.parent.parent.arguments;
      args = ((() => {
        const result = [];
        for (arg of Array.from(args)) {           result.push(arg.property.name);
        }
        return result;
      })());
      for (arg of Array.from(args)) { localArgs.push(arg); }
    }.bind(this);

    this.walk(block, null, gatherAddChildCalls);
    return localArgs;
  }
});
/*

  this.timeline.addTween(cjs.Tween.get(this.instance).to({scaleX:0.82,scaleY:0.79,rotation:-10.8,x:98.4,y:-86.5},4).to({scaleY:0.7,rotation:9.3,x:95.6,y:-48.8},1).to({scaleX:0.82,scaleY:0.61,rotation:29.4,x:92.8,y:-11},1).to({regX:7.3,scaleX:0.82,scaleY:0.53,rotation:49.7,x:90.1,y:26.6},1).to({regX:7.2,regY:29.8,scaleY:0.66,rotation:19.3,x:101.2,y:-27.8},2).to({regY:29.9,scaleY:0.79,rotation:-10.8,x:98.4,y:-86.5},2).to({scaleX:0.84,scaleY:0.83,rotation:-30.7,x:68.4,y:-110},2).to({regX:7.3,scaleX:0.84,scaleY:0.84,rotation:-33.9,x:63.5,y:-114},1).wait(1));

*/

/*
simpleSample = """
(function (lib, img, cjs) {

var p; // shortcut to reference prototypes

// stage content:
(lib.enemy_flying_move_side = function(mode,startPosition,loop) {
  this.initialize(mode,startPosition,loop,{});

  // D_Head
  this.instance = new lib.Dragon_Head();
  this.instance.setTransform(227,200.5,1,1,0,0,0,51.9,42.5);

  this.timeline.addTween(cjs.Tween.get(this.instance).to({y:182.9},7).to({y:200.5},7).wait(1));

  // Layer 7
  this.shape = new cjs.Shape();
  this.shape.graphics.f('#4F6877').s().p('AgsAxQgSgVgB');
  this.shape.setTransform(283.1,146.1);

  // Layer 7 2
  this.shape_1 = new cjs.Shape();
  this.shape_1.graphics.f('rgba(255,255,255,0.4)').s().p('ArTs0QSMB7EbVGQhsBhiGBHQjg1IvVkhg');
  this.shape_1.setTransform(400.2,185.5);

  this.timeline.addTween(cjs.Tween.get({}).to({state:[]}).to({state:[{t:this.shape}]},7).to({state:[]},2).wait(6));

  // Wing
  this.instance_9 = new lib.Wing_Animation('synched',0);
  this.instance_9.setTransform(313.9,145.6,1,1,0,0,0,49,-83.5);

  this.timeline.addTween(cjs.Tween.get(this.instance_9).to({y:128,startPosition:7},7).wait(1));

  // Example hard one with two shapes
  this.timeline.addTween(cjs.Tween.get({}).to({state:[]}).to({state:[{t:this.shape}]},7).to({state:[{t:this.shape_1}]},1).to({state:[]},1).wait(7));


}).prototype = p = new cjs.MovieClip();
p.nominalBounds = new cjs.Rectangle(7.1,48.9,528.7,431.1);

(lib.Dragon_Head = function() {
  this.initialize();

  // Isolation Mode
  this.shape = new cjs.Shape();
  this.shape.graphics.f('#1D2226').s().p('AgVAwQgUgdgN');
  this.shape.setTransform(75,25.8);

  this.shape_1 = new cjs.Shape();
  this.shape_1.graphics.f('#1D2226').s().p('AgnBXQACABAF');
  this.shape_1.setTransform(80.8,22);

  this.addChild(this.shape_1,this.shape);
}).prototype = p = new cjs.Container();
p.nominalBounds = new cjs.Rectangle(5.8,0,87.9,85);

(lib.WingPart_01 = function() {
  this.initialize();

  // Layer 1
  this.shape = new cjs.Shape();
  this.shape.graphics.f('#DBDDBC').s().p('Ag3BeQgCgRA');
  this.shape.setTransform(10.6,19.7,1.081,1.081);

  this.shape_1 = new cjs.Shape();
  this.shape_1.graphics.f('#1D2226').s().p('AB4CDQgGg');
  this.shape_1.setTransform(19.9,17.6,1.081,1.081);

  this.shape_2 = new cjs.Shape();
  this.shape_2.graphics.f('#605E4A').s().p('AiECbQgRg');
  this.shape_2.setTransform(19.5,18.4,1.081,1.081);

  this.addChild(this.shape_2,this.shape_1,this.shape);
}).prototype = p = new cjs.Container();
p.nominalBounds = new cjs.Rectangle(0,-3.1,40,41.6);


(lib.Wing_Animation = function(mode,startPosition,loop) {
  this.initialize(mode,startPosition,loop,{});

  // WP_02
  this.instance = new lib.WingPart_01();
  this.instance.setTransform(53.6,-121.9,0.854,0.854,-40.9,0,0,7.2,29.9);

  this.timeline.addTween(cjs.Tween.get(this.instance).to({scaleY:0.7,rotation:9.3,x:95.6,y:-48.8},1).wait(1));

}).prototype = p = new cjs.MovieClip();
p.nominalBounds = new cjs.Rectangle(-27.7,-161.6,153.4,156.2);

})(lib = lib||{}, images = images||{}, createjs = createjs||{});
var lib, images, createjs;
"""
*/

function __guard__(value, transform) {
  return (typeof value !== 'undefined' && value !== null) ? transform(value) : undefined;
}
function __guardMethod__(obj, methodName, transform) {
  if (typeof obj !== 'undefined' && obj !== null && typeof obj[methodName] === 'function') {
    return transform(obj, methodName);
  } else {
    return undefined;
  }
}