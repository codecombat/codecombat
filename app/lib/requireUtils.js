// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
module.exports.getParentFolders = function(subPath, urlPrefix) {
  if (urlPrefix == null) { urlPrefix = '/test/'; }
  if (!subPath) { return []; }
  const paths = [];
  const parts = subPath.split('/');
  while (parts.length) {
    parts.pop();
    paths.unshift({
      name: parts[parts.length-1] || 'All',
      url: urlPrefix + parts.join('/')
    });
  }
  return paths;
};

module.exports.parseImmediateChildren = function(allChildren, subPath, baseRequirePath, urlPrefix) {
  let name;
  if (baseRequirePath == null) { baseRequirePath = 'test/app/'; }
  if (urlPrefix == null) { urlPrefix = '/test/'; }
  if (!allChildren) { return []; }
  const folders = {};
  const files = {};

  let requirePrefix = baseRequirePath + subPath;
  if (requirePrefix[requirePrefix.length-1] !== '/') {
    requirePrefix += '/';
  }

  for (var f of Array.from(allChildren)) {
    f = f.slice(requirePrefix.length);
    if (!f) { continue; }
    var parts = f.split('/');
    name = parts[0];
    var group = parts.length === 1 ? files : folders;
    if (group[name] == null) { group[name] = 0; }
    group[name] += 1;
  }

  const children = [];
  urlPrefix += subPath;
  if (urlPrefix[urlPrefix.length-1] !== '/') { urlPrefix += '/'; }

  for (name of Array.from(_.keys(folders))) {
    children.push({
      type: 'folder',
      url: urlPrefix+name,
      name: name+'/',
      size: folders[name]
    });
  }
  for (name of Array.from(_.keys(files))) {
    children.push({
      type: 'file',
      url: urlPrefix+name,
      name
    });
  }
  return children;
};
