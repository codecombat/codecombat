path = require 'path'
fs = require 'fs-extra'
_ = require 'lodash'
async = require 'async'
cores = require('os').cpus().length
child_process = require 'child_process'

root = path.join(__dirname, '..', 'public','javascripts');
dest = path.join(__dirname, '..', 'public','javascripts-min');

console.log root
dirStack = [path.join(root)]
files = []

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
		smArgs = []

		if fs.existsSync fpath + '.map'
			smArgs = [
				'--in-source-map', fpath + '.map',
				'--source-map', dpath + '.map',
				'--source-map-include-sources',
				'--source-map-url', '/javascripts/' + file.replace('/\\/g', '/') + '.map'
			]

		args = [fpath, '-m', '-r', 'require' , '-b', 'beautify=false,semicolons=false'].concat smArgs, ['-o', dpath]
		async.waterfall [
			_.bind(fs.mkdirs, fs, path.dirname dpath),
			(last, cb) ->
				child = child_process.spawn 'uglifyjs', args, stdio:'inherit'
				child.on 'close', (code) -> 
					if code == 0 then cb null
					else cb code
				child.on 'error', (err) ->
					cb err
		], cb2

async.parallelLimit jobs, cores, (err, res)->
	if err
		console.log "ERROR:", err
	else
		console.log "Done, minified " + jobs.length + " files."
		fs.renameSync(root, root + "-old")
		fs.renameSync(dest, root)
		fs.removeSync(root + "-old")

