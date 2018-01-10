fs = require 'fs-extra'
path = require 'path'
 
if process.argv.length <= 2
  console.log "Usage: #{__filename} snowplow-schema-dir"
  process.exit -1

source = path.join __dirname, '..', 'app', 'schemas', 'events'
target = process.argv[2]
 
fs.readdir source, (err, items) ->
  if err?
    console.log err
    process.exit -1

  items.forEach (item) ->
    str = fs.readFileSync path.join source, item
    data = JSON.parse str
    target_path = path.join target, data.self.vendor, data.self.name, 'jsonschema', data.self.version
    target_dir = path.join target, data.self.vendor, data.self.name, 'jsonschema'
    unless fs.existsSync target_path
      fs.mkdirs target_dir, (err) ->
        if err?
          console.log err
          process.exit -1

        console.log target_path
        fs.writeFileSync target_path, str

