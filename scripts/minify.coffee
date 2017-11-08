path = require 'path'
fs = require 'fs-extra'
_ = require 'lodash'
async = require 'async'
cores = require('os').cpus().length
child_process = require 'child_process'
UglifyJS = require('uglify-js')

root = path.join(__dirname, '..', 'public','javascripts');
dest = path.join(__dirname, '..', 'public','javascripts-min');

console.log root
dirStack = [path.join(root)]
files = []

console.log "STARTING MINIFY"

while dirStack.length
  dir = dirStack.pop()
  contents = fs.readdirSync(dir)
  for file in contents
    fullPath = "#{dir}/#{file}"
    stat = fs.statSync(fullPath)
    if stat.isDirectory()
      dirStack.push(fullPath)
    else if /\.js$/.test(file)
      files.push fullPath.replace root + '/', ''

jobs = _.map files, (file) ->
  (cb2) ->
    fpath = path.join(root, file)
    dpath = path.join(dest, file)

    # console.log "INPUT FILE:", fpath
    # console.log "OUTPUT FILE:", dpath
    smArgs = []
    if /esper.modern.js/.test fpath
      console.log "Skipping #{fpath} due to blacklist"
      return fs.copy fpath, dpath, cb2
 
    if fs.existsSync fpath + '.map'
      # console.log "File exists: ", fpath + '.map'
      dpathRelative = dpath.replace('/Users/phoenix/work/codecombat/', '')
      smArgs = [
        "--source-map \"filename='./#{dpathRelative}.map',content='#{fpath}.map',root='/Users/phoenix/work/codecombat/public',url='/javascripts/#{file.replace('/\\/g','/')+'.map'}',includeSources\"",
      ]

    args = [fpath, '-m', '-r', 'require' , '-b', 'beautify=false,semicolons=false'].concat smArgs, ['-o', dpath]
    # console.log ['uglifyjs'].concat(args).join(' ')
    async.waterfall [
      _.bind(fs.mkdirs, fs, path.dirname dpath),
      (last, cb) ->
        cb = _.once(cb)
        # console.log fs.readFileSync(fpath).toString()
        result = UglifyJS.minify(fs.readFileSync(fpath).toString(), {
          sourceMap: if fs.existsSync("#{fpath}.map") then {
            root: '/Users/phoenix/work/codecombat/public'
            filename: "#{dpath}.map"
            content: fs.readFileSync("#{fpath}.map").toString()
            url: "/javascripts/#{file.replace('/\\/g','/')+'.map'}"
          } else {}
        })
        # console.log "RESULT:", result?.error?.stack or result?.error or result
        fs.writeFileSync("#{dpath}", result.code)
        fs.writeFileSync("#{dpath}.map", result.map)
        cb()
        
        # child = child_process.spawn 'uglifyjs', args, stdio:'inherit'
        # child.on 'close', (code) ->
        #   if code == 0
        #     console.log "Outputfile exists: #{fs.existsSync(dpath + '.map')}:", fpath + '.map'
        #     cb null
        #   else
        #     cb code
        # child.on 'error', (err) ->
        #   # console.log "Compile error!", err
        #   cb err
    ], (err, data) ->
      if err
        console.log "Couldn't minify #{dpath}, copying as-is"
        console.log "Reason:", err
        process.exit()
        fs.copy fpath, dpath, cb2
      else
        cb2 null, data


async.parallelLimit jobs, cores, (err, res) ->
  if err
    console.log "ERROR in jobs:", err
  else
    console.log "Done, minified " + jobs.length + " files."
    # fs.renameSync(root, root + "-old")
    # fs.renameSync(dest, root)
    # fs.removeSync(root + "-old")
