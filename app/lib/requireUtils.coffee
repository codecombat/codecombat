module.exports.getParentFolders = (subPath, urlPrefix='/test/') ->
  return [] unless subPath
  paths = []
  parts = subPath.split('/')
  while parts.length
    parts.pop()
    paths.unshift {
      name: parts[parts.length-1] or 'All'
      url: urlPrefix + parts.join('/')
    }
  paths
  
module.exports.parseImmediateChildren = (allChildren, subPath, baseRequirePath='test/app/', urlPrefix='/test/') ->
  return [] unless allChildren
  folders = {}
  files = {}

  requirePrefix = baseRequirePath + subPath
  if requirePrefix[requirePrefix.length-1] isnt '/'
    requirePrefix += '/'

  for f in allChildren
    f = f[requirePrefix.length..]
    continue unless f
    parts = f.split('/')
    name = parts[0]
    group = if parts.length is 1 then files else folders
    group[name] ?= 0
    group[name] += 1

  children = []
  urlPrefix += subPath
  urlPrefix += '/' if urlPrefix[urlPrefix.length-1] isnt '/'

  for name in _.keys(folders)
    children.push {
      type:'folder',
      url: urlPrefix+name
      name: name+'/'
      size: folders[name]
    }
  for name in _.keys(files)
    children.push {
      type:'file',
      url: urlPrefix+name
      name: name
    }
  children
