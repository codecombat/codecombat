# Based on https://github.com/substack/node-falafel
# A similar approach could be seen in https://github.com/ariya/esmorph

# TODO: see about consolidating
module.exports.walkAST = walkAST = (node, fn) ->
  for key, child of node
    if _.isArray child
      for grandchild in child
        walkAST grandchild, fn if _.isString grandchild?.type
    else if _.isString child?.type
      walkAST child, fn
    fn child

module.exports.walkASTCorrect = walkASTCorrect = (node, fn) ->
  for key, child of node
    if _.isArray child
      for grandchild in child
        if _.isString grandchild?.type
          walkASTCorrect grandchild, fn
    else if _.isString child?.type
      walkASTCorrect child, fn
  fn node

module.exports.morphAST = morphAST = (source, transforms, parseFn, aether) ->
  chunks = source.split ''
  ast = parseFn source, aether

  morphWalk = (node, parent) ->
    insertHelpers node, parent, chunks
    for key, child of node
      continue if key is 'parent' or key is 'leadingComments'
      if _.isArray child
        for grandchild in child
          morphWalk grandchild, node if _.isString grandchild?.type
      else if _.isString child?.type
        morphWalk child, node
    transform node, aether for transform in transforms

  morphWalk ast, undefined
  chunks.join ''

insertHelpers = (node, parent, chunks) ->
  return unless node.range
  node.parent = parent
  node.source = -> chunks.slice(node.range[0], node.range[1]).join ''
  update = (s) ->
    chunks[node.range[0]] = s
    for i in [node.range[0] + 1 ... node.range[1]]
      chunks[i] = ''
  if _.isObject node.update
    _.extend update, node.update
  node.update = update
