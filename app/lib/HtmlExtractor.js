/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS104: Avoid inline assignments
 * DS205: Consider reworking code to avoid use of IIFEs
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
require('vendor/scripts/htmlparser2');

// Convert htmlparser2-formatted DOM structure into Deku format
var dekuify = function(elem) {
  if (elem.type === 'text') { return elem.data; }
  if (elem.type === 'comment') { return null; }  // TODO: figure out how to make a comment in virtual dom
  // Prevent Deku from including invalid attribute names (which DOMElement will choke on)
  elem.attribs = _.omit(elem.attribs, (val, attr) => !attr.match(/^[^\s"'<>\\\/=]+$/));
  if (!elem.name) {
    console.log('Failed to dekuify', elem);
    return elem.type;
  }
  return deku.element(elem.name, elem.attribs, (Array.from(elem.children != null ? elem.children : []).map((c) => dekuify(c))));
};

// Convert Deku-formatted DOM nodes into a flat list of their raw values
var unwrapDekuNodes = function(dekuNode) {
  let child;
  if (_.isString(dekuNode)) { return dekuNode; }
  if (_.isArray(dekuNode)) {
    return _.filter(_.flatten((() => {
      const result = [];
      for (child of Array.from(dekuNode)) {         result.push(unwrapDekuNodes(child));
      }
      return result;
    })()));
  } else {
    return _.filter(_.flatten([dekuNode.nodeValue, ((() => {
      const result1 = [];
      for (child of Array.from((dekuNode.children || []))) {         result1.push(unwrapDekuNodes(child));
      }
      return result1;
    })())]));
  }
};

// Parses user code into Deku format. Also guarantees an `html` and `body` element so that Deku doesn't explode when reading it.
// Arguments:
//   html — Raw HTML source code, possibly without html/body tags
// Returns: Parsed Deku-format DOM that includes html/body tags
const parseUserHtml = function(html) {
  let left, left1;
  const dom = htmlparser2.parseDOM(html, {});
  const bodyNode = (left = _.find(dom, {name: 'body'})) != null ? left : {name: 'body', attribs: null, children: dom};
  const htmlNode = (left1 = _.find(dom, {name: 'html'})) != null ? left1 : {name: 'html', attribs: null, children: [bodyNode]};
  return dekuify(htmlNode);
};

// Creates a deku virtual DOM for given HTML, with the <script> and <style> tags separated out (and dekuified as well)
// Arguments:
//   html — raw HTML source code
// Returns: Object
//   virtualDom: The DekuTree for the main content
//   scripts: A list of Deku nodes for the <script> tags
//   styles: A list of Deku nodes for the <style> tags
const extractStylesAndScripts = function(html) {
  const dekuTree = parseUserHtml(html);
  var recurse = function(dekuTree) {
    //base case
    if (dekuTree.type === '#text') {
      return { virtualDom: dekuTree, styles: [], scripts: [] };
    }
    if (dekuTree.type === 'style') {
      return { styles: [dekuTree], scripts: [] };
    }
    if (dekuTree.type === 'script') {
      return { styles: [], scripts: [dekuTree] };
    }
    // recurse over children
    let childStyles = [];
    let childScripts = [];
    if (dekuTree.children != null) {
      dekuTree.children.forEach((dekuChild, index) => {
      const { virtualDom, styles, scripts } = recurse(dekuChild);
      dekuTree.children[index] = virtualDom;
      childStyles = childStyles.concat(styles);
      return childScripts = childScripts.concat(scripts);
    });
    }
    dekuTree.children = _.filter(dekuTree.children); // Remove the nodes we extracted
    return { virtualDom: dekuTree, scripts: childScripts, styles: childStyles };
  };

  const { virtualDom, scripts, styles } = recurse(dekuTree);
  const wrappedStyles = deku.element('head', {}, styles);
  const wrappedScripts = deku.element('head', {}, scripts);
  return { virtualDom, scripts: wrappedScripts, styles: wrappedStyles };
};

// Returns a list of CSS selectors found in CSS code and jQuery calls
const extractCssSelectors = function(dekuStyles, dekuScripts) {
  const cssSelectors = extractSelectorsFromCss(dekuStyles);
  const jQuerySelectors = extractSelectorsFromJS(dekuScripts);
  return cssSelectors.concat(jQuerySelectors);
};

// Returns a list of CSS selectors found in jQuery calls
// Arguments:
//   styles — one (or a list of) strings or Deku nodes.
var extractSelectorsFromCss = function(styles) {
  styles = unwrapDekuNodes(styles);
  if (!_.isArray(styles)) { styles = [styles]; }
  const cssSelectors = _.flatten(styles.map(function(rawCss) {
    try {
      const parsedCss = parseCss(rawCss); // TODO: Don't put this in the global namespace
      return parsedCss.stylesheet.rules.map(rule => rule.selectors.join(', ').trim());
    } catch (e) {
      // TODO: Report this error, handle CSS errors in general
      return [];
    }}));
  return cssSelectors;
};

// Returns a list of CSS selector strings found in jQuery calls
// Arguments:
//   scripts — one (or a list of) strings or Deku nodes.
var extractSelectorsFromJS = function(scripts) {
  scripts = unwrapDekuNodes(scripts);
  if (!_.isArray(scripts)) { scripts = [scripts]; }
  const jQuerySelectors = _.flatten(scripts.map(script => (script.match(/\$\(\s*['"](?!<)(.*?)(?!>)['"]\s*\)/g) || []).map(jQueryCall => // Extract the argument (because capture groups don't work with /g)
  jQueryCall.match(/\$\(\s*['"](?!<)(.*?)(?!>)['"]\s*\)/)[1])));
  return jQuerySelectors;
};

// Converts deku style nodes into a list of lines of CSS code.
// Used to prefilter hovered lines for selectors.
const extractCssLines = function(dekuStyles) {
  let rawCssLines = [];
  dekuStyles.children.forEach(styleNode => {
    const rawCss = styleNode.children[0].nodeValue;
    return rawCssLines = rawCssLines.concat(rawCss.split('\n'));
  });
  return rawCssLines;
};

// Converts deku script nodes into a list of lines of lines of code that contain jQuery selectors
// Used to prefilter hovered lines for selectors.
const extractJQueryLines = dekuScripts => _.flatten(dekuScripts.children.map(function(dekuScript) {
  const rawScript = dekuScript.children[0].nodeValue;
  return _.filter((rawScript.split('\n').map(line => (line.match(/^.*\$\(\s*['"].*['"]\s*\).*$/g) || [])[0])));
})
);

module.exports = {
  dekuify,
  unwrapDekuNodes,
  parseUserHtml,
  extractStylesAndScripts,
  extractCssSelectors,
  extractSelectorsFromCss,
  extractSelectorsFromJS,
  extractCssLines,
  extractJQueryLines
};
