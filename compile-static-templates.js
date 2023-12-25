/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let WebpackStaticStuff;
const pug = require('pug');
const path = require('path');
const cheerio = require('cheerio');
const en = require('./app/locale/en');
const zh = require('./app/locale/zh-HANS');
const basePath = path.resolve('./app');
const _ = require('lodash');
const fs = require('fs');
const load = require('pug-load');
const devUtils = require('./development/utils');
const {
  minify
} = require('html-minifier');

// TODO: stop webpack build on error (e.g. http://dev.topheman.com/how-to-fail-webpack-build-on-error/)

const {
  product
} = devUtils;
const {
  productSuffix
} = devUtils;
const {
  publicFolderName
} = devUtils;


const productFallbackPlugin = {
  read(path) {
    if (!fs.existsSync(path)) {
      const other = path.replace(/pug$/, `${productSuffix}.pug`);
      if (fs.existsSync(other)) {
        return load.read(other);
      }
    }
    return load.read(path);
  }
};

const compile = function(contents, locals, filename, cb) {
  // console.log "Compile", filename, basePath
  let str;
  const outFile = filename.replace(new RegExp(`.static.(${productSuffix}\\.)?pug$`), '.html');
  // console.log {outFile, filename, basePath}
  let out = pug.compileClientWithDependenciesTracked(contents, {
    filename: path.join(basePath, 'templates/static', filename),
    basedir: basePath,
    plugins: [productFallbackPlugin]
  });

  const outFn = pug.compile(contents, {
    filename: path.join(basePath, 'templates/static', filename),
    basedir: basePath,
    plugins: [productFallbackPlugin]
  });

  const translate = function(key, chinaInfra) {
    let type = 'text';

    const html = /^\[html\]/.test(key);
    if (html) { key = key.substring(6); }
    if (html) { type = 'html'; }

    const content = /^\[content\]/.test(key);
    if (content) { key = key.substring(9); }
    if (content) { type = 'content'; }

    let t = chinaInfra ? zh.translation : en.translation;
    //TODO: Replace with _.property when we get modern lodash
    const translationPath = key.split(/[.]/);
    while (translationPath.length > 0) {
      var k = translationPath.shift();
      t = t[k];
      if (t == null) { return key; }
    }

    return out = {
      text: t,
      type
    };
  };

  const i18n = function(k,v) {
    if (Array.from(k).includes('i18n')) { return k.i18n.en[a]; }
    return k[v];
  };

  try {
    locals = _.merge({_, i18n}, locals, require('./static-mock'));
    // NOTE: do NOT add more build env-driven feature flags here if at all possible.
    // NOTE: instead, use showingStaticPagesWhileLoading (in static-mock) to delay/hide UI until features flags loaded
    locals.me.useDexecure = () => !(locals.chinaInfra != null ? locals.chinaInfra : false);
    locals.me.useSocialSignOn = () => !(locals.chinaInfra != null ? locals.chinaInfra : false);
    locals.me.useGoogleAnalytics = () => !(locals.chinaInfra != null ? locals.chinaInfra : false);
    locals.me.useStripe = () => !(locals.chinaInfra != null ? locals.chinaInfra : false);
    locals.me.useQiyukf = () => false;  // Netease Qiyu Live Chat Plugin
    locals.me.useDataDog = () => !(locals.chinaInfra != null ? locals.chinaInfra : false);
    locals.me.showChinaVideo = () => locals.chinaInfra != null ? locals.chinaInfra : false;
    locals.me.getProduct = () => product;
    str = outFn(locals);
    str = minify(str, {
      removeComments: true,
      removeRedundantAttributes: true,
      minifyJS: true
    });
  } catch (error) {
    const e = error;
    console.log("Compile", filename, basePath);
    console.log('ERROR', e.message);
    throw new Error(e.message);
    return cb(e.message);
  }

  const c = cheerio.load(str);
  const elms = c('[data-i18n]');
  elms.each(function(i, e) {
    i = c(this);
    const t = translate(i.data('i18n'), locals.chinaInfra);
    if (t.type === 'html') {
      return i.html(t.text);
    } else if (t.type === 'content') {
      return i.attr("content", t.text);
    } else {
      return i.text(t.text);
    }
  });

  const deps = ['static-mock.coffee'].concat(out.dependencies);
  // console.log "Wrote to #{outFile}", deps

  // console.log {outFile}

  if (!fs.existsSync(path.resolve(`./${publicFolderName}`))) {
    fs.mkdirSync(path.resolve(`./${publicFolderName}`));
  }
  if (!fs.existsSync(path.resolve(`./${publicFolderName}/templates`))) {
    fs.mkdirSync(path.resolve(`./${publicFolderName}/templates`));
  }
  if (!fs.existsSync(path.resolve(`./${publicFolderName}/templates/static`))) {
    fs.mkdirSync(path.resolve(`./${publicFolderName}/templates/static`));
  }
  fs.writeFileSync(path.join(path.resolve(`./${publicFolderName}/templates/static`), outFile), c.html());
  return cb();
};
  // cb(null, [{filename: outFile, content: c.html()}], deps) # old brunch callback

module.exports = (WebpackStaticStuff = function(options) {
  if (options == null) { options = {}; }
  this.options = options;
  this.prevTemplates = {};
  return null; // Need this for webpack to be happy
});

WebpackStaticStuff.prototype.apply = function(compiler) {
  // Compile the static files
  // https://github.com/ionic-team/stencil-webpack/pull/9
  compiler.hooks.emit.tapAsync('CompileStaticTemplatesEmit', (compilation, callback) => {
    const files = fs.readdirSync(path.resolve('./app/templates/static'));
    const promises = [];
    for (var filename of Array.from(files)) {
      var relativeFilePath = path.join(path.resolve('./app/templates/static/'), filename);
      var content = fs.readFileSync(path.resolve('./app/templates/static/'+filename)).toString();
      if (this.prevTemplates[filename] === content) {
        continue;
      }
      this.prevTemplates[filename] = content;
      var chunkPaths = {};
      Array.from(compilation.chunks).map(function(c) {
        if (c.name) {
          return chunkPaths[c.name] = compiler.options.output.chunkFilename.replace('[name]',c.name).replace('[chunkhash]',c.renderedHash);
        }
      });

      var locals = _.merge({}, this.options.locals, {
        chunkPaths
      });
      try {
        compile(content, locals, filename, _.noop);
        console.log(`\nCompiled static file: ${filename}`);
      } catch (err) {
        console.log(`\nError compiling ${filename}:`, err);
        return callback(`\nError compiling ${filename}:`, err);
      }
    }
    return callback();
  });

  // Watch the static template files for changes
  return compiler.hooks.afterEmit.tapAsync('CompileStaticTemplatesAfterEmit', (compilation, callback) => {
    const files = fs.readdirSync(path.resolve('./app/templates/static'));
    const compilationFileDependencies = compilation.fileDependencies;
    _.forEach(files, filename => {
      const absoluteFilePath = path.join(path.resolve('./app/templates/static/'), filename);
      if (!compilationFileDependencies.has(absoluteFilePath)) {
        return compilation.fileDependencies.add(absoluteFilePath);
      }
    });
    return callback();
  });
};
