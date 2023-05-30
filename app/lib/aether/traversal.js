// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS205: Consider reworking code to avoid use of IIFEs
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
// Based on https://github.com/substack/node-falafel
// A similar approach could be seen in https://github.com/ariya/esmorph

export const walkAST = (node, fn) => (() => {
  const result = [];
  for (var key in node) {
    var child = node[key];
    if (_.isArray(child)) {
      for (var grandchild of Array.from(child)) {
        if (_.isString(grandchild != null ? grandchild.type : undefined)) { walkAST(grandchild, fn); }
      }
    } else if (_.isString(child != null ? child.type : undefined)) {
      walkAST(child, fn);
    }
    result.push(fn(child));
  }
  return result;
})();

export const walkASTCorrect = function(node, fn) {
  for (var key in node) {
    var child = node[key];
    if (_.isArray(child)) {
      for (var grandchild of Array.from(child)) {
        if (_.isString(grandchild != null ? grandchild.type : undefined)) {
          walkASTCorrect(grandchild, fn);
        }
      }
    } else if (_.isString(child != null ? child.type : undefined)) {
      walkASTCorrect(child, fn);
    }
  }
  return fn(node);
};

export const morphAST = function(source, transforms, parseFn, aether) {
  const chunks = source.split('');
  const ast = parseFn(source, aether);

  var morphWalk = function(node, parent) {
    insertHelpers(node, parent, chunks);
    for (var key in node) {
      var child = node[key];
      if ((key === 'parent') || (key === 'leadingComments')) { continue; }
      if (_.isArray(child)) {
        for (var grandchild of Array.from(child)) {
          if (_.isString(grandchild != null ? grandchild.type : undefined)) { morphWalk(grandchild, node); }
        }
      } else if (_.isString(child != null ? child.type : undefined)) {
        morphWalk(child, node);
      }
    }
    return Array.from(transforms).map((transform) => transform(node, aether));
  };

  morphWalk(ast, undefined);
  return chunks.join('');
};

var insertHelpers = function(node, parent, chunks) {
  if (!node.range) { return; }
  node.parent = parent;
  node.source = () => chunks.slice(node.range[0], node.range[1]).join('');
  const update = function(s) {
    chunks[node.range[0]] = s;
    return __range__(node.range[0] + 1, node.range[1], false).map((i) =>
      (chunks[i] = ''));
  };
  if (_.isObject(node.update)) {
    _.extend(update, node.update);
  }
  return node.update = update;
};

function __range__(left, right, inclusive) {
  let range = [];
  let ascending = left < right;
  let end = !inclusive ? right : ascending ? right + 1 : right - 1;
  for (let i = left; ascending ? i < end : i > end; ascending ? i++ : i--) {
    range.push(i);
  }
  return range;
}
