pug = require 'pug'
path = require 'path'
cheerio = require 'cheerio'
en = require './app/locale/en'
basePath = path.resolve('./app')
_ = require 'lodash'
fs = require('fs')

# TODO: stop webpack build on error (e.g. http://dev.topheman.com/how-to-fail-webpack-build-on-error/)

compile = (contents, locals, filename, cb) ->
  # console.log "Compile", filename, basePath
  outFile = filename.replace /.static.pug$/, '.html'
  # console.log {outFile, filename, basePath}
  out = pug.compileClientWithDependenciesTracked contents,
    filename: path.join(basePath, 'templates/static', filename)
    basedir: basePath

  outFn = pug.compile(contents, {
    filename: path.join(basePath, 'templates/static', filename),
    basedir: basePath
  })

  translate = (key) ->
    html = /^\[html\]/.test(key)
    key = key.substring(6) if html

    t = en.translation
    #TODO: Replace with _.property when we get modern lodash
    translationPath = key.split(/[.]/)
    while translationPath.length > 0
      k = translationPath.shift()
      t = t[k]
      return key unless t?

    return out =
      text: t
      html: html

  i18n = (k,v) ->
    return k.i18n.en[a] if 'i18n' in k
    k[v]

  try
    locals = _.merge({_, i18n}, locals, require './static-mock')
    # NOTE: do NOT add more build env-driven feature flags here if at all possible.
    # NOTE: instead, use showingStaticPagesWhileLoading (in static-mock) to delay/hide UI until features flags loaded
    locals.me.useDexecure = -> not (locals.chinaInfra ? false)
    locals.me.useSocialSignOn = -> not (locals.chinaInfra ? false)
    locals.me.useGoogleAnalytics = -> not (locals.chinaInfra ? false)
    str = outFn(locals)
  catch e
    console.log "Compile", filename, basePath
    console.log 'ERROR', e.message
    throw new Error(e.message)
    return cb(e.message)

  c = cheerio.load(str)
  elms = c('[data-i18n]')
  elms.each (i, e) ->
    i = c(@)
    t = translate(i.data('i18n'))
    if t.html
      i.html(t.text)
    else
      i.text(t.text)

  deps = ['static-mock.coffee'].concat(out.dependencies)
  # console.log "Wrote to #{outFile}", deps

  # console.log {outFile}

  if not fs.existsSync(path.resolve('./public'))
    fs.mkdirSync(path.resolve('./public'))
  if not fs.existsSync(path.resolve('./public/templates'))
    fs.mkdirSync(path.resolve('./public/templates'))
  if not fs.existsSync(path.resolve('./public/templates/static'))
    fs.mkdirSync(path.resolve('./public/templates/static'))
  fs.writeFileSync(path.join(path.resolve('./public/templates/static'), outFile), c.html())
  cb()
  # cb(null, [{filename: outFile, content: c.html()}], deps) # old brunch callback

module.exports = WebpackStaticStuff = (options = {}) ->
  @options = options
  @prevTemplates = {}
  return null # Need this for webpack to be happy

WebpackStaticStuff.prototype.apply = (compiler) ->
  # Compile the static files
  compiler.plugin 'emit', (compilation, callback) =>
    files = fs.readdirSync(path.resolve('./app/templates/static'))
    promises = []
    for filename in files
      relativeFilePath = path.join(path.resolve('./app/templates/static/'), filename)
      content = fs.readFileSync(path.resolve('./app/templates/static/'+filename)).toString()
      if @prevTemplates[filename] is content
        continue
      @prevTemplates[filename] = content
      locals = _.merge({}, @options.locals, {
        chunkPaths: _.zipObject.apply(null, _.zip(compilation.chunks.map((c)=>[
          c.name,
          compiler.options.output.chunkFilename.replace('[name]',c.name).replace('[chunkhash]',c.renderedHash)
        ])))
      })
      try
        compile(content, locals, filename, _.noop)
        console.log "\nCompiled static file: #{filename}"
      catch err
        console.log "\nError compiling #{filename}:", err
        return callback("\nError compiling #{filename}:", err)
    callback()

  # Watch the static template files for changes
  compiler.plugin 'after-emit', (compilation, callback) =>
    files = fs.readdirSync(path.resolve('./app/templates/static'))
    compilationFileDependencies = new Set(compilation.fileDependencies)
    _.forEach(files, (filename) =>
      absoluteFilePath = path.join(path.resolve('./app/templates/static/'), filename)
      unless compilationFileDependencies.has(absoluteFilePath)
        compilation.fileDependencies.push(absoluteFilePath)
    )
    callback()
