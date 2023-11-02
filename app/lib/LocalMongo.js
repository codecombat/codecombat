/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
const LocalMongo = module.exports;

// Checks whether func(l, r) is true for at least one value of left for at least one value of right
const mapred = (left, right, func) => _.reduce(left, ((result, singleLeft) => result || (_.reduce((_.map(right, singleRight => func(singleLeft, singleRight))),
  ((intermediate, value) => intermediate || value), false))), false);

const doQuerySelector = function(originalValue, operatorObj) {
  const value = _.isArray(originalValue) ? originalValue : [originalValue]; // left hand can be an array too
  for (var operator in operatorObj) {
    var originalBody = operatorObj[operator];
    var body = _.isArray(originalBody) ? originalBody : [originalBody]; // right hand can be an array too
    switch (operator) {
      case '$gt': if (!mapred(value, body, (l, r) => l > r)) { return false; } break;
      case '$gte': if (!mapred(value, body, (l, r) => l >= r)) { return false; } break;
      case '$lt': if (!mapred(value, body, (l, r) => l < r)) { return false; } break;
      case '$lte': if (!mapred(value, body, (l, r) => l <= r)) { return false; } break;
      case '$ne': if (mapred(value, body, (l, r) => l === r)) { return false; } break;
      case '$in': if (!_.reduce(value, ((result, val) => result || Array.from(body).includes(val)), false)) { return false; } break;
      case '$nin': if (_.reduce(value, ((result, val) => result || Array.from(body).includes(val)), false)) { return false; } break;
      case '$exists': if ((value[0] != null) !== body[0]) { return false; } break;
      default: 
        var trimmedOperator = _.pick(operatorObj, operator);
        if (!_.isObject(originalValue) || !matchesQuery(originalValue, trimmedOperator)) { return false; }
    }
  }
  return true;
};

var matchesQuery = function(target, queryObj) {
  if (!queryObj) { return true; }
  if (!target) { throw new Error('Expected an object to match a query against, instead got null'); }
  for (var prop in queryObj) {
    var query = queryObj[prop];
    if (prop[0] === '$') {
      switch (prop) {
        case '$or': if (!_.reduce(query, ((res, obj) => res || matchesQuery(target, obj)), false)) { return false; } break;
        case '$and': if (!_.reduce(query, ((res, obj) => res && matchesQuery(target, obj)), true)) { return false; } break;
        default: return false;
      }
    } else {
      // Do nested properties
      var pieces = prop.split('.');
      var obj = target;
      for (var piece of Array.from(pieces)) {
        if (!(piece in obj)) {
          obj = null;
          break;
        }
        obj = obj[piece];
      }
      if ((typeof query !== 'object') || _.isArray(query)) {
        if ((obj !== query) && (!(_.isArray(obj) ? Array.from(obj).includes(query) : undefined))) { return false; }
      } else if (!doQuerySelector(obj, query)) { return false; }
    }
  }
  return true;
};

LocalMongo.matchesQuery = matchesQuery;
