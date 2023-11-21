// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS002: Fix invalid constructor
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS103: Rewrite code to no longer use __guard__, or convert again using --optional-chaining
 * DS104: Avoid inline assignments
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let ThangTypeEditView;
require('app/styles/editor/thang/thang-type-edit-view.sass');
const ThangType = require('models/ThangType');
const SpriteParser = require('lib/sprites/SpriteParser');
const SpriteBuilder = require('lib/sprites/SpriteBuilder');
const Lank = require('lib/surface/Lank');
const LayerAdapter = require('lib/surface/LayerAdapter');
const Camera = require('lib/surface/Camera');
const DocumentFiles = require('collections/DocumentFiles');
require('lib/setupTreema');
const createjs = require('lib/createjs-parts');
const LZString = require('lz-string');
const initSlider = require('lib/initSlider');
const utils = require('core/utils');
const replaceRgbaWithCustomizableHex = require('./replaceRgbaWithCustomizableHex.js').default;
const SpriteOptimizer = require('lib/sprites/SpriteOptimizer');

// in the template, but need to require to load them
require('views/modal/RevertModal');

const RootView = require('views/core/RootView');
const ThangComponentsEditView = require('views/editor/component/ThangComponentsEditView');
const ThangTypeVersionsModal = require('./ThangTypeVersionsModal');
const ThangTypeColorsTabView = require('./ThangTypeColorsTabView');
const PatchesView = require('views/editor/PatchesView');
const ForkModal = require('views/editor/ForkModal');
const VectorIconSetupModal = require('views/editor/thang/VectorIconSetupModal');
const SaveVersionModal = require('views/editor/modal/SaveVersionModal');
const template = require('app/templates/editor/thang/thang-type-edit-view');
const storage = require('core/storage');
const ExportThangTypeModal = require('./ExportThangTypeModal');
const RevertModal = require('views/modal/RevertModal');

require('lib/game-libraries');

const AnimateImporterWorker = require('./animate-import.worker.js');

const CENTER = {x: 200, y: 400};

const commonTasks = [
  'Upload the art.',
  'Set up the vector icon.'
];

const displayedThangTypeTasks = [
  'Configure the idle action.',
  'Configure the positions (registration point, etc.).',
  'Set shadow diameter to 0 if needed.',
  'Set scale to 0.3, 0.5, or whatever is appropriate.',
  'Set rotation to isometric if needed.',
  'Set accurate Physical size, shape, and default z.',
  'Set accurate Collides collision information if needed.',
  'Double-check that fixedRotation is accurate, if it collides.'
];

const animatedThangTypeTasks = displayedThangTypeTasks.concat([
  'Configure the non-idle actions.',
  'Configure any per-action registration points needed.',
  'Add flipX per action if needed to face to the right.',
  'Make sure any death and attack actions do not loop.',
  'Add defaultSimlish if needed.',
  'Add selection sounds if needed.',
  'Add per-action sound triggers.',
  'Add team color groups.'
]);

const containerTasks = displayedThangTypeTasks.concat([
  'Select viable terrains if not universal.',
  'Set Exists stateless: true if needed.'
]);

const purchasableTasks = [
  'Add a tier, or 10 + desired tier if not ready yet.',
  'Add a gem cost.',
  'Write a description.',
  'Click the Populate i18n button.'
];

const defaultTasks = {
  Unit: commonTasks.concat(animatedThangTypeTasks.concat([
    'Start a new name category in names.coffee if needed.',
    'Set to Allied to correct team (ogres, humans, or neutral).',
    'Add AutoTargetsNearest or FightsBack if needed.',
    'Add other Components like Shoots or Casts if needed.',
    'Configure other Components, like Moves, Attackable, Attacks, etc.',
    'Override the HasAPI type if it will not be correctly inferred.',
    'Add to Existence System power table.'
  ])),
  Hero: commonTasks.concat(animatedThangTypeTasks.concat(purchasableTasks.concat([
    'Set the hero class.',
    'Add Extended Hero Name.',
    'Add Short Hero Name.',
    'Add Hero Gender.',
    'Upload Hero Doll Images.',
    'Upload Pose Image.',
    'Start a new name category in names.coffee.',
    'Set up hero stats in Equips, Attackable, Moves.',
    'Set Collects collectRange to 2, Sees visualRange to 60.',
    'Add any custom hero abilities.',
    'Add to ThangTypeConstants hard-coded hero ids/classes list.',
    'Add hero gender.',
    'Add hero short name.'
  ]))),
  Floor: commonTasks.concat(containerTasks.concat([
    'Add 10 x 8.5 snapping.',
    'Set fixed rotation.',
    'Make sure everything is scaled to tile perfectly.',
    'Adjust SingularSprite floor scale list if necessary.'
  ])),
  Wall: commonTasks.concat(containerTasks.concat([
    'Add 4x4 snapping.',
    'Set fixed rotation.',
    'Set up and tune complicated wall-face actions.',
    'Make sure everything is scaled to tile perfectly.'
  ])),
  Doodad: commonTasks.concat(containerTasks.concat([
    'Add to GenerateTerrainModal logic if needed.'
  ])),
  Misc: commonTasks.concat([
    'Add any misc tasks for this misc ThangType.'
  ]),
  Mark: commonTasks.concat([
    'Check the animation framerate.',
    'Double-check that bottom of mark is just touching registration point.'
  ]),
  Item: commonTasks.concat(purchasableTasks.concat([
    'Set the hero class if class-specific.',
    'Upload Paper Doll Images.',
    'Configure item stats and abilities.'
  ])),
  Missile: commonTasks.concat(animatedThangTypeTasks.concat([
    'Make sure there is a launch sound trigger.',
    'Make sure there is a hit sound trigger.',
    'Make sure there is a die animation.',
    'Add Arrow, Shell, Beam, or other missile Component.',
    'Choose Missile.leadsShots and Missile.shootsAtGround.',
    'Choose Moves.maxSpeed and other config.',
    'Choose Expires.lifespan config if needed.',
    'Set spriteType: singular if needed for proper rendering.',
    'Add HasAPI if the missile should show up in findEnemyMissiles.'
  ]))
};

module.exports = (ThangTypeEditView = (function() {
  ThangTypeEditView = class ThangTypeEditView extends RootView {
    static initClass() {
      this.prototype.id = 'thang-type-edit-view';
      this.prototype.className = 'editor';
      this.prototype.template = template;
      this.prototype.resolution = 4;
      this.prototype.scale = 3;
      this.prototype.mockThang = {
        health: 10.0,
        maxHealth: 10.0,
        hudProperties: ['health'],
        acts: true
      };

      this.prototype.events = {
        'click #clear-button': 'clearRawData',
        'click #upload-button'() { return this.$el.find('input#real-upload-button').click(); },
        'click #upload-animate-button'() { return this.$el.find('input#real-animate-upload-button').click(); },
        'click #set-vector-icon': 'onClickSetVectorIcon',
        'change #real-upload-button': 'animationFileChosen',
        'change #real-animate-upload-button': 'animateAnimationFileChosen',
        'change #animations-select': 'showAnimation',
        'click #marker-button': 'toggleDots',
        'click #stop-button': 'stopAnimation',
        'click #play-button': 'playAnimation',
        'click #history-button': 'showVersionHistory',
        'click li:not(.disabled) > #fork-start-button': 'startForking',
        'click #save-button': 'openSaveModal',
        'click #patches-tab'() { return this.patchesView.load(); },
        'click .play-with-level-button': 'onPlayLevel',
        'click .play-with-level-parent': 'onPlayLevelSelect',
        'keyup .play-with-level-input': 'onPlayLevelKeyUp',
        'click li:not(.disabled) > #pop-level-i18n-button': 'onPopulateLevelI18N',
        'click li:not(.disabled) > #toggle-archive-button': 'onToggleArchive',
        'mousedown #canvas': 'onCanvasMouseDown',
        'mouseup #canvas': 'onCanvasMouseUp',
        'mousemove #canvas': 'onCanvasMouseMove',
        'click #export-sprite-sheet-btn': 'onClickExportSpriteSheetButton',
        'click .reoptimize-btn': 'onClickReoptimizeButton',
        'click [data-toggle="coco-modal"][data-target="modal/RevertModal"]': 'openRevertModal'
      };

      this.prototype.subscriptions =
        {'editor:thang-type-color-groups-changed': 'onColorGroupsChanged'};
    }

    openRevertModal(e) {
      e.stopPropagation();
      return this.openModalView(new RevertModal());
    }

    onClickSetVectorIcon() {
      const modal = new VectorIconSetupModal({}, this.thangType);
      this.openModalView(modal);
      return modal.once('done', () => this.treema.set('/', this.getThangData()));
    }

    // init / render

    constructor(options, thangTypeID) {
      super(options);
      this.initComponents = this.initComponents.bind(this);
      this.onComponentsChanged = this.onComponentsChanged.bind(this);
      this.onAnimateFileLoad = this.onAnimateFileLoad.bind(this);
      this.onFileLoad = this.onFileLoad.bind(this);
      this.fileLoaded = this.fileLoaded.bind(this);
      this.refreshAnimation = this.refreshAnimation.bind(this);
      this.updateRotation = this.updateRotation.bind(this);
      this.updateScale = this.updateScale.bind(this);
      this.updateResolution = this.updateResolution.bind(this);
      this.updateHealth = this.updateHealth.bind(this);
      this.pushChangesToPreview = this.pushChangesToPreview.bind(this);
      this.onSelectNode = this.onSelectNode.bind(this);
      this.thangTypeID = thangTypeID;
      this.mockThang = $.extend(true, {}, this.mockThang);
      this.thangType = new ThangType({_id: this.thangTypeID});
      this.thangType = this.supermodel.loadModel(this.thangType).model;
      this.thangType.saveBackups = true;
      this.listenToOnce(this.thangType, 'sync', function() {
        this.files = this.supermodel.loadCollection(new DocumentFiles(this.thangType), 'files').model;
        return this.updateFileSize();
      });
    }
  //    @refreshAnimation = _.debounce @refreshAnimation, 500

    showLoading($el) {
      if ($el == null) { $el = this.$el.find('.outer-content'); }
      return super.showLoading($el);
    }

    getRenderData(context) {
      let left;
      if (context == null) { context = {}; }
      context = super.getRenderData(context);
      context.thangType = this.thangType;
      context.animations = this.getAnimationNames();
      context.authorized = !me.get('anonymous');
      context.recentlyPlayedLevels = (left = storage.load('recently-played-levels')) != null ? left : ['items'];
      context.fileSizeString = this.fileSizeString;
      context.spriteSheetSizeString = this.spriteSheetSizeString;
      return context;
    }

    getAnimationNames() {
      return _.sortBy(_.keys(this.thangType.get('actions') || {}), a => ({
        move: 1,
        cast: 2,
        attack: 3,
        idle: 4,
        portrait: 6
      })[a] || 5);
    }

    afterRender() {
      super.afterRender();
      if (!this.supermodel.finished()) { return; }
      this.initStage();
      this.buildTreema();
      this.initSliders();
      this.initComponents();
      this.colorsView = this.insertSubView(new ThangTypeColorsTabView(this.thangType));
      this.patchesView = this.insertSubView(new PatchesView(this.thangType), this.$el.find('.patches-view'));
      if (me.get('anonymous')) { this.showReadOnly(); }
      return this.updatePortrait();
    }

    initComponents() {
      let left;
      const options = {
        components: (left = this.thangType.get('components')) != null ? left : [],
        supermodel: this.supermodel
      };

      this.thangComponentEditView = new ThangComponentsEditView(options);
      this.listenTo(this.thangComponentEditView, 'components-changed', this.onComponentsChanged);
      return this.insertSubView(this.thangComponentEditView);
    }

    onComponentsChanged(components) {
      return this.thangType.set('components', components);
    }

    onColorGroupsChanged(e) {
      this.temporarilyIgnoringChanges = true;
      this.treema.set('colorGroups', e.colorGroups);
      return this.temporarilyIgnoringChanges = false;
    }

    makeDot(color) {
      const circle = new createjs.Shape();
      circle.graphics.beginFill(color).beginStroke('black').drawCircle(0, 0, 5);
      circle.scaleY = 0.2;
      circle.scaleX = 0.5;
      return circle;
    }

    initStage() {
      const canvas = this.$el.find('#canvas');
      this.stage = new createjs.Stage(canvas[0]);
      this.layerAdapter = new LayerAdapter({name:'Default', webGL: true});
      this.topLayer = new createjs.Container();

      this.layerAdapter.container.x = (this.topLayer.x = CENTER.x);
      this.layerAdapter.container.y = (this.topLayer.y = CENTER.y);
      this.stage.addChild(this.layerAdapter.container, this.topLayer);
      this.listenTo(this.layerAdapter, 'new-spritesheet', this.onNewSpriteSheet);
      if (this.camera != null) {
        this.camera.destroy();
      }
      this.camera = new Camera(canvas);

      this.torsoDot = this.makeDot('blue');
      this.mouthDot = this.makeDot('yellow');
      this.aboveHeadDot = this.makeDot('green');
      this.groundDot = this.makeDot('red');
      this.topLayer.addChild(this.groundDot, this.torsoDot, this.mouthDot, this.aboveHeadDot);
      this.updateGrid();
      _.defer(this.refreshAnimation);
      this.toggleDots(false);

      createjs.Ticker.framerate = 30;
      return createjs.Ticker.addEventListener('tick', this.stage);
    }

    toggleDots(newShowDots) {
      this.showDots = typeof(newShowDots) === 'boolean' ? newShowDots : !this.showDots;
      return this.updateDots();
    }

    updateDots() {
      this.topLayer.removeChild(this.torsoDot, this.mouthDot, this.aboveHeadDot, this.groundDot);
      if (!this.currentLank) { return; }
      if (!this.showDots) { return; }
      const torso = this.currentLank.getOffset('torso');
      const mouth = this.currentLank.getOffset('mouth');
      const aboveHead = this.currentLank.getOffset('aboveHead');
      this.torsoDot.x = torso.x;
      this.torsoDot.y = torso.y;
      this.mouthDot.x = mouth.x;
      this.mouthDot.y = mouth.y;
      this.aboveHeadDot.x = aboveHead.x;
      this.aboveHeadDot.y = aboveHead.y;
      return this.topLayer.addChild(this.groundDot, this.torsoDot, this.mouthDot, this.aboveHeadDot);
    }

    stopAnimation() {
      return (this.currentLank != null ? this.currentLank.queueAction('idle') : undefined);
    }

    playAnimation() {
      return (this.currentLank != null ? this.currentLank.queueAction(this.$el.find('#animations-select').val()) : undefined);
    }

    updateGrid() {
      let newLine;
      const grid = new createjs.Container();
      const line = new createjs.Shape();
      const width = 1000;
      line.graphics.beginFill('#666666').drawRect(-width/2, -0.5, width, 0.5);

      line.x = CENTER.x;
      line.y = CENTER.y;
      let {
        y
      } = line;
      const step = 10 * this.scale;
      while (y > 0) { y -= step; }
      while (y < 500) {
        y += step;
        newLine = line.clone();
        newLine.y = y;
        grid.addChild(newLine);
      }

      let {
        x
      } = line;
      while (x > 0) { x -= step; }
      while (x < 400) {
        x += step;
        newLine = line.clone();
        newLine.x = x;
        newLine.rotation = 90;
        grid.addChild(newLine);
      }

      if (this.grid) { this.stage.removeChild(this.grid); }
      this.stage.addChildAt(grid, 0);
      return this.grid = grid;
    }

    updateSelectBox() {
      const names = this.getAnimationNames();
      const select = this.$el.find('#animations-select');
      if (select.find('option').length === names.length) { return; }
      select.empty();
      return Array.from(names).map((name) => select.append($('<option></option>').text(name)));
    }

    // upload

    animationFileChosen(e) {
      const file = e.target.files[0];
      if (!file) { return; }
      if (!_.string.endsWith(file.type, 'javascript')) { return; }
  //    @$el.find('#upload-button').prop('disabled', true)
      this.reader = new FileReader();
      this.reader.onload = this.onFileLoad;
      return this.reader.readAsText(file);
    }

    animateAnimationFileChosen(e) {
      const file = e.target.files[0];
      if (!file) { return; }
      if (!_.string.endsWith(file.type, 'javascript')) {
        noty({text: "Only accepts files ending with '.js'", type:"error", timeout: 5000});
        return;
      }
      if (!confirm("This button may have unknown effects. Are you sure you want to continue?")) {
        noty({text: "Cancelled import of '.js' file", type:"info", timeout: 3000});
        return;
      }
      this.reader = new FileReader();
      this.reader.onload = this.onAnimateFileLoad;
      return this.reader.readAsText(file);
    }

    onAnimateFileLoad(e) {
      const {
        result
      } = this.reader;

      const worker = new AnimateImporterWorker();
      worker.addEventListener('message', event => {
        worker.terminate();
        this.hideLoading();

        const {
          data
        } = event;

        if (data.output) {
          this.thangType.attributes.raw = this.thangType.attributes.raw || {};
          _.merge(this.thangType.attributes.raw, JSON.parse(data.output));

          return this.fileLoaded();
        } else if (data.error) {
          noty({ text: "Error occurred. Check console. Please inform eng team and provide Adobe Animate File.", type:"error", timeout: 10000000 });
          throw data.error;
        }
      });

      this.showLoading();
      this.updateProgress(0.50);
      return worker.postMessage({ input: result });
    }

    onFileLoad(e) {
      const {
        result
      } = this.reader;
      const parser = new SpriteParser(this.thangType);
      parser.parse(result);
      return this.fileLoaded();
    }

    fileLoaded() {
      this.treema.set('raw', this.thangType.get('raw'));
      this.updateSelectBox();
      this.refreshAnimation();
      return this.updateFileSize();
    }

    updateFileSize() {
      const file = JSON.stringify(this.thangType.attributes);
      const compressed = LZString.compress(file);
      const size = (file.length / 1024).toFixed(1) + "KB";
      const compressedSize = (compressed.length / 1024).toFixed(1) + "KB";
      const gzipCompressedSize = compressedSize * 1.65;  // just based on comparing ogre barracks
      this.fileSizeString = `Size: ${size} (~${compressedSize} gzipped)`;
      return this.$el.find('#thang-type-file-size').text(this.fileSizeString);
    }

    updateSpriteSheetSize() {
      let memoryMax = 0;
      for (var s of Array.from(this.layerAdapter.spriteSheet._images)) { memoryMax += ((4 * s.width * s.height) / 1024 / 1024); }
      let memoryMin = 0;
      for (var frame of Array.from(this.layerAdapter.spriteSheet._frames)) { memoryMin += ((4 * frame.rect.width * frame.rect.height) / 1024 / 1024); }
      const spriteSheetCount = this.layerAdapter.spriteSheet._images.length;
      this.spriteSheetSizeString = `Sprite sheets: ${spriteSheetCount} (${memoryMax}MB max, ${memoryMin.toFixed(1)}MB min)`;
      return this.$el.find('#thang-type-sprite-sheet-size').text(this.spriteSheetSizeString);
    }

    // animation select

    refreshAnimation() {
      this.thangType.resetSpriteSheetCache();
      if (this.thangType.get('raster')) { return this.showRasterImage(); }
      const options = this.getLankOptions();
      console.log('refresh animation....');
      this.showAnimation();
      return this.updatePortrait();
    }

    showRasterImage() {
      const lank = new Lank(this.thangType, this.getLankOptions());
      this.showLank(lank);
      return this.updateScale();
    }

    onNewSpriteSheet() {
      $('#spritesheets').empty();
      for (var image of Array.from(this.layerAdapter.spriteSheet._images)) {
        $('#spritesheets').append(image);
      }
      this.layerAdapter.container.x = CENTER.x;
      this.layerAdapter.container.y = CENTER.y;
      this.updateScale();
      return this.updateSpriteSheetSize();
    }

    showAnimation(animationName) {
      if (!_.isString(animationName)) { animationName = this.$el.find('#animations-select').val(); }
      if (!animationName) { return; }
      this.mockThang.action = animationName;
      this.showAction(animationName);
      this.updateRotation();
      return this.updateScale(); // must happen after update rotation, because updateRotation calls the sprite update() method.
    }

    showMovieClip(animationName) {
      const vectorParser = new SpriteBuilder(this.thangType);
      const movieClip = vectorParser.buildMovieClip(animationName);
      if (!movieClip) { return; }
      const reg = __guard__(this.thangType.get('positions'), x => x.registration);
      if (reg) {
        movieClip.regX = -reg.x;
        movieClip.regY = -reg.y;
      }
      const scale = this.thangType.get('scale');
      if (scale) {
        movieClip.scaleX = (movieClip.scaleY = scale);
      }
      return this.showSprite(movieClip);
    }

    getLankOptions() {
      const options = {resolutionFactor: this.resolution, thang: this.mockThang, preloadSounds: false};
      if (/cinematic/i.test(this.thangType.get('name'))) {
        options.isCinematic = true;  // Don't render extra default actions, because the CinematicLankBoss won't
      }
      return options;
    }

    showAction(actionName) {
      const options = this.getLankOptions();
      const lank = new Lank(this.thangType, options);
      this.showLank(lank);
      return lank.queueAction(actionName);
    }

    updatePortrait() {
      const options = this.getLankOptions();
      const portrait = this.thangType.getPortraitImage(options);
      if (!portrait) { return; }
      if (portrait != null) {
        portrait.attr('id', 'portrait').addClass('img-thumbnail');
      }
      portrait.addClass('img-thumbnail');
      return $('#portrait').replaceWith(portrait);
    }

    showLank(lank) {
      this.clearDisplayObject();
      this.clearLank();
      this.layerAdapter.resetSpriteSheet();
      this.layerAdapter.addLank(lank);
      this.currentLank = lank;
      return this.currentLankOffset = null;
    }

    showSprite(sprite) {
      this.clearDisplayObject();
      this.clearLank();
      this.topLayer.addChild(sprite);
      this.currentObject = sprite;
      return this.updateDots();
    }

    clearDisplayObject() {
      if (this.currentObject != null) { return this.topLayer.removeChild(this.currentObject); }
    }

    clearLank() {
      if (this.currentLank) { this.layerAdapter.removeLank(this.currentLank); }
      return (this.currentLank != null ? this.currentLank.destroy() : undefined);
    }

    // sliders

    initSliders() {
      this.rotationSlider = initSlider($('#rotation-slider', this.$el), 50, this.updateRotation);
      this.scaleSlider = initSlider($('#scale-slider', this.$el), 29, this.updateScale);
      this.resolutionSlider = initSlider($('#resolution-slider', this.$el), 39, this.updateResolution);
      return this.healthSlider = initSlider($('#health-slider', this.$el), 100, this.updateHealth);
    }

    updateRotation() {
      const value = parseInt((180 * (this.rotationSlider.slider('value') - 50)) / 50);
      this.$el.find('.rotation-label').text(` ${value}° `);
      if (this.currentLank) {
        this.currentLank.rotation = value;
        return this.currentLank.update(true);
      }
    }

    updateScale() {
      const scaleValue = (this.scaleSlider.slider('value') + 1) / 10;
      this.layerAdapter.container.scaleX = (this.layerAdapter.container.scaleY = (this.topLayer.scaleX = (this.topLayer.scaleY = scaleValue)));
      const fixed = scaleValue.toFixed(1);
      this.scale = scaleValue;
      this.$el.find('.scale-label').text(` ${fixed}x `);
      return this.updateGrid();
    }

    updateResolution() {
      const value = (this.resolutionSlider.slider('value') + 1) / 10;
      const fixed = value.toFixed(1);
      this.$el.find('.resolution-label').text(` ${fixed}x `);
      this.resolution = value;
      return this.refreshAnimation();
    }

    updateHealth() {
      const value = parseInt((this.healthSlider.slider('value')) / 10);
      this.$el.find('.health-label').text(` ${value}hp `);
      this.mockThang.health = value;
      return (this.currentLank != null ? this.currentLank.update() : undefined);
    }

    // save

    saveNewThangType(e) {
      const newThangType = e.major ? this.thangType.cloneNewMajorVersion() : this.thangType.cloneNewMinorVersion();
      newThangType.set('commitMessage', e.commitMessage);
      if (newThangType.get('i18nCoverage')) { newThangType.updateI18NCoverage(); }

      const res = newThangType.save(null, {type: 'POST'});  // Override PUT so we can trigger postNewVersion logic
      if (!res) { return; }
      const modal = $('#save-version-modal');
      this.enableModalInProgress(modal);

      res.error(() => {
        return this.disableModalInProgress(modal);
      });

      return res.success(() => {
        const url = `/editor/thang/${newThangType.get('slug') || newThangType.id}`;
        let portraitSource = null;
        if (this.thangType.get('raster')) {
          //image = @currentLank.sprite.image  # Doesn't work?
          const image = this.currentLank.sprite.spriteSheet._images[0];
          portraitSource = imageToPortrait(image);
        }
          // bit of a hacky way to get that portrait
        const success = () => {
          this.thangType.clearBackup();
          return document.location.href = url;
        };
        return newThangType.uploadGenericPortrait(success, portraitSource);
      });
    }

    clearRawData() {
      this.thangType.resetRawData();
      this.thangType.set('actions', undefined);
      this.clearDisplayObject();
      return this.treema.set('/', this.getThangData());
    }

    getThangData() {
      let data = $.extend(true, {}, this.thangType.attributes);
      return data = _.pick(data, (value, key) => !(['components'].includes(key)));
    }

    buildTreema() {
      const data = this.getThangData();
      const schema = _.cloneDeep(ThangType.schema);
      schema.properties = _.pick(schema.properties, (value, key) => !(['components'].includes(key)));
      delete schema.properties.original.format;  // Don't hide this, we often want to see it here
      schema.properties.original.readOnly = true;
      const options = {
        data,
        schema,
        files: this.files,
        filePath: `db/thang.type/${this.thangType.get('original')}`,
        readOnly: me.get('anonymous'),
        callbacks: {
          change: this.pushChangesToPreview,
          select: this.onSelectNode
        }
      };
      const el = this.$el.find('#thang-type-treema');
      this.treema = this.$el.find('#thang-type-treema').treema(options);
      this.treema.build();
      return this.lastKind = data.kind;
    }

    pushChangesToPreview() {
      let key, kind;
      if (this.temporarilyIgnoringChanges) { return; }
      const keysProcessed = {};
      for (key in this.thangType.attributes) {
        keysProcessed[key] = true;
        if (key === 'components') { continue; }
        this.thangType.set(key, this.treema.data[key]);
      }
      for (key in this.treema.data) {
        var value = this.treema.data[key];
        if (!keysProcessed[key]) {
          this.thangType.set(key, value);
        }
      }

      this.updateSelectBox();
      this.refreshAnimation();
      this.updateDots();
      this.updatePortrait();
      if ((kind = this.treema.data.kind) !== this.lastKind) {
        this.lastKind = kind;
        Backbone.Mediator.publish('editor:thang-type-kind-changed', {kind});
        if (['Doodad', 'Floor', 'Wall'].includes(kind) && !this.treema.data.terrains) {
          this.treema.set('/terrains', ['Grass', 'Dungeon', 'Indoor', 'Desert', 'Mountain', 'Glacier', 'Volcano']);  // So editors know to set them.
        }
        if (!this.treema.data.tasks) {
          return this.treema.set('/tasks', (Array.from(defaultTasks[kind]).map((t) => ({name: t}))));
        }
      }
    }

    onSelectNode(e, selected) {
      let obj;
      selected = selected[0];
      if (this.boundsBox) { this.topLayer.removeChild(this.boundsBox); }
      if (!selected) { return this.stopShowingSelectedNode(); }
      const path = selected.getPath();
      const parts = path.split('/');
      if (!(parts.length >= 4) || !_.string.startsWith(path, '/raw/')) { return this.stopShowingSelectedNode(); }
      const key = parts[3];
      const type = parts[2];
      const vectorParser = new SpriteBuilder(this.thangType);
      if (type === 'animations') { obj = vectorParser.buildMovieClip(key); }
      if (type === 'containers') { obj = vectorParser.buildContainerFromStore(key); }
      if (type === 'shapes') { obj = vectorParser.buildShapeFromStore(key); }

      const bounds = (obj != null ? obj.bounds : undefined) || (obj != null ? obj.nominalBounds : undefined);
      if (bounds) {
        this.boundsBox = new createjs.Shape();
        this.boundsBox.graphics.beginFill('#aaaaaa').beginStroke('black').drawRect(bounds.x, bounds.y, bounds.width, bounds.height);
        this.topLayer.addChild(this.boundsBox);
        obj.regX = (this.boundsBox.regX = bounds.x + (bounds.width / 2));
        obj.regY = (this.boundsBox.regY = bounds.y + (bounds.height / 2));
      }

      if (obj) { this.showSprite(obj); }
      this.showingSelectedNode = true;
      if (this.currentLank != null) {
        this.currentLank.destroy();
      }
      this.currentLank = null;
      this.updateScale();
      return this.grid.alpha = 0.0;
    }

    stopShowingSelectedNode() {
      if (!this.showingSelectedNode) { return; }
      this.grid.alpha = 1.0;
      this.showAnimation();
      return this.showingSelectedNode = false;
    }

    //  Run this manually via the console. `currentView.fixCorruptContainerBounds()`
    //  This script has been specifically tuned to fix cinematic-ghost-vega.
    //  It is possible to verify this script worked by refreshing and then trying the
    //  actions out manually. Look for the placeholder loading circles. There should be
    //  no big ones.
    //  When dryRun is true, no mutation takes place. Instead all containers with bounds
    //  larger than the maxBounds are logged letting you find them.
    fixCorruptContainerBounds(boundsWidthToFix, dryRun, backupBounds) {
      if (boundsWidthToFix == null) { boundsWidthToFix = 400; }
      if (dryRun == null) { dryRun = true; }
      if (backupBounds == null) { backupBounds = undefined; }
      console.log(`\
Running fixCorruptContainerBounds.
  First argument is size of bounds to fix.
  Second argument is whether or not to fix the container.

To find the numbers of large bounds, run the script:
  \`currentView.fixCorruptContainerBounds()\`
To run a test run without making changes to bounds of size 700 run:
  \`currentView.fixCorruptContainerBounds(700, true)\`
And to make changes:
  \`currentView.fixCorruptContainerBounds(700, false)\`
You can always revert the changes from the editor if the animation is broken.

Finally if there are no shape bounds present you can pass in your own with the format of [x, y, width, height]
i.e.
  \`currentView.fixCorruptContainerBounds(700, false, [0, 0, 50, 100])\`
This will cut out a 50px wide and 100px tall container around the sprite.
Incorrect settings of custom bounds will cut the artwork.\
`);
      // Fix all the messed up bounds
      const data = this.thangType.attributes;
      let fixCount = 0;
      let failCount = 0;
      let backupBoundsCount = 0;
      for (var [key, container] of Array.from(Object.entries(data.raw.containers))) {
        if (dryRun) {
          if ((container.b != null ? container.b[2] : undefined) >= boundsWidthToFix) {
            console.log('found width:', container.b[2]);
          }
        } else {
          if ((container.c.length === 1) && (container.b[2] === boundsWidthToFix)) {
            var reference = container.c[0];
            if (data.raw.shapes[reference]) {
              var shape = data.raw.shapes[reference];
              if ((shape.bounds === undefined) && Array.isArray(backupBounds)) {
                backupBoundsCount += 1;
                if (shape.bounds == null) { shape.bounds = backupBounds; } // Lets user pass in backup bounds with options: [x, y, width, height]
              }
              try {
                container.b = [(shape.bounds[0] + shape.t[0]) - 5, (shape.bounds[1] + shape.t[1]) - 5, shape.bounds[2] + 10, shape.bounds[3] + 10];
                fixCount += 1;
              } catch (e) {
                failCount += 1;
              }
              console.log('.');
            }
          }
        }
      }
      return console.log('Fixed:', fixCount, 'Failed:', failCount, 'Used backup bounds:', backupBoundsCount);
    }



    showVersionHistory(e) {
      return this.openModalView(new ThangTypeVersionsModal({thangType: this.thangType}, this.thangTypeID));
    }

    onPopulateLevelI18N() {
      this.thangType.populateI18N();
      return _.delay((() => document.location.reload()), 500);
    }

    onToggleArchive() {
      if (this.thangType.get('archived')) {
        this.thangType.unset('archived');
      } else {
        this.thangType.set('archived', new Date().getTime());
      }
      this.render();
      return this.openSaveModal(null, this.thangType.get('archived') ? 'Archived' : 'Unarchived');
    }

    openSaveModal(e, commitMessage) {
      const modal = new SaveVersionModal({model: this.thangType, commitMessage});
      this.openModalView(modal);
      this.listenToOnce(modal, 'save-new-version', this.saveNewThangType);
      return this.listenToOnce(modal, 'hidden', function() { return this.stopListening(modal); });
    }

    startForking(e) {
      return this.openModalView(new ForkModal({model: this.thangType, editorPath: 'thang'}));
    }

    onPlayLevelSelect(e) {
      if (this.childWindow && !this.childWindow.closed) {
        // We already have a child window open, so we don't need to ask for a level; we'll use its existing level.
        e.stopImmediatePropagation();
        this.onPlayLevel(e);
      }
      return _.defer(() => $('.play-with-level-input').focus());
    }

    onPlayLevelKeyUp(e) {
      let left;
      if (e.keyCode !== 13) { return; }  // return
      const input = this.$el.find('.play-with-level-input');
      input.parents('.dropdown').find('.play-with-level-parent').dropdown('toggle');
      const level = _.string.slugify(input.val());
      if (!level) { return; }
      this.onPlayLevel(null, level);
      const recentlyPlayedLevels = (left = storage.load('recently-played-levels')) != null ? left : [];
      recentlyPlayedLevels.push(level);
      return storage.save('recently-played-levels', recentlyPlayedLevels);
    }

    onPlayLevel(e, level=null) {
      if (level == null) { level = $(e.target).data('level'); }
      level = _.string.slugify(level);
      if (this.childWindow && !this.childWindow.closed) {
        // Reset the LevelView's world, but leave the rest of the state alone
        this.childWindow.Backbone.Mediator.publish('level:reload-thang-type', {thangType: this.thangType});
      } else {
        // Create a new Window with a blank LevelView
        const scratchLevelID = level + '?dev=true';
        if (me.get('name') === 'Nick') {
          this.childWindow = window.open(`/play/level/${scratchLevelID}`, 'child_window', 'width=2560,height=1080,left=0,top=-1600,location=1,menubar=1,scrollbars=1,status=0,titlebar=1,toolbar=1', true);
        } else {
          this.childWindow = window.open(`/play/level/${scratchLevelID}`, 'child_window', 'width=1024,height=560,left=10,top=10,location=0,menubar=0,scrollbars=0,status=0,titlebar=0,toolbar=0', true);
        }
      }
      return this.childWindow.focus();
    }

    // Canvas mouse drag handlers

    onCanvasMouseMove(e) {
      let p1;
      if (!(p1 = this.canvasDragStart)) { return; }
      const p2 = {x: e.offsetX, y: e.offsetY};
      const offset = {x: p2.x - p1.x, y: p2.y - p1.y};
      this.currentLank.sprite.x = this.currentLankOffset.x + (offset.x / this.scale);
      this.currentLank.sprite.y = this.currentLankOffset.y + (offset.y / this.scale);
      return this.canvasDragOffset = offset;
    }

    onCanvasMouseDown(e) {
      if (!this.currentLank) { return; }
      this.canvasDragStart = {x: e.offsetX, y: e.offsetY};
      return this.currentLankOffset != null ? this.currentLankOffset : (this.currentLankOffset = {x: this.currentLank.sprite.x, y: this.currentLank.sprite.y});
    }

    onCanvasMouseUp(e) {
      let node;
      this.canvasDragStart = null;
      if (!this.canvasDragOffset) { return; }
      if (!(node = this.treema.getLastSelectedTreema())) { return; }
      const offset = node.get('/');
      offset.x += Math.round(this.canvasDragOffset.x);
      offset.y += Math.round(this.canvasDragOffset.y);
      this.canvasDragOffset = null;
      return node.set('/', offset);
    }

    onClickExportSpriteSheetButton() {
      const modal = new ExportThangTypeModal({}, this.thangType);
      return this.openModalView(modal);
    }

    onClickReoptimizeButton(e) {
      const options = {aggressiveShapes: $(e.target).data('shapes'), aggressiveContainers: $(e.target).data('containers')};
      const oldSize = this.fileSizeString + ' ' + this.spriteSheetSizeString;
      const optimizer = new SpriteOptimizer(this.thangType, options);
      optimizer.optimize();
      this.treema.set('/', this.getThangData());
      if (utils.isOzaria && _.size(this.thangType.get('colorGroups'))) {
        this.colorsView.destroy();
        this.colorsView = this.insertSubView(new ThangTypeColorsTabView(this.thangType));
      }
      this.updateFileSize();
      return this.listenToOnce(this.layerAdapter, 'new-spritesheet', () => {
        const newSize = this.fileSizeString + ' ' + this.spriteSheetSizeString;
        return noty({text: `Was: ${oldSize}.<br>Now: ${newSize}`, timeout: 5000, layout: 'topCenter'});
      });
    }

    // Run it in the editor/thang/<thang-type> view by inputting the following:
    // ```
    // currentView.normalizeColorsForCustomization()
    // ```
    // into the console. Used to normalize the shape colors for Ozaria Heroes to
    // support character customization.
    normalizeColorsForCustomization() {
      this.thangType.attributes.raw.shapes = replaceRgbaWithCustomizableHex(this.thangType.attributes.raw.shapes);
      return this.treema.set('raw', this.thangType.get('raw'));
    }

    destroy() {
      if (this.camera != null) {
        this.camera.destroy();
      }
      return super.destroy();
    }
  };
  ThangTypeEditView.initClass();
  return ThangTypeEditView;
})());

var imageToPortrait = function(img) {
  const canvas = document.createElement('canvas');
  canvas.width = 100;
  canvas.height = 100;
  const ctx = canvas.getContext('2d');
  const scaleX = 100 / img.width;
  const scaleY = 100 / img.height;
  ctx.scale(scaleX, scaleY);
  ctx.drawImage(img, 0, 0);
  return canvas.toDataURL('image/png');
};

function __guard__(value, transform) {
  return (typeof value !== 'undefined' && value !== null) ? transform(value) : undefined;
}