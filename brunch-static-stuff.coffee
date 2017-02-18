pug = require 'pug'
path = require 'path'
cheerio = require 'cheerio'
en = require './app/locale/en'
basePath = path.join(__dirname, 'app')
_ = require 'lodash'

class BrunchStaticStuff
  constructor: (config) ->
    @locals = config.locals or {}
  
  handles: /.static.pug$/
  compile: (contents, filename, cb) ->
    console.log "Compile", filename, basePath 
    outFile = filename.replace /.static.pug$/, '.html'
    out = pug.compileClientWithDependenciesTracked contents,
      pretty: true
      filename: filename
      basedir: basePath

    translate = (key) ->
      html = /^\[html\]/.test(key)
      key = key.substring(6) if html

      t = en.translation
      #TODO: Replace with _.property when we get modern lodash
      path = key.split(/[.]/)
      while path.length > 0
        k = path.shift()
        t = t[k]
        return key unless t?

      return out =
        text: t
        html: html    

    i18n = (k,v) ->
      return k.i18n.en[a] if 'i18n' in k
      k[v]
    

    try
      fn = new Function(out.body + '\n return template;')()
      str = fn(_.merge {_, i18n}, @locals, require './static-mock')
    catch e
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
    console.log "Wrote to #{outFile}", deps

    cb(null, [{filename: outFile, content: c.html()}], deps)

module.exports = (config) ->
  console.log "Loaded brunch static stuff"
  new BrunchStaticStuff(config)