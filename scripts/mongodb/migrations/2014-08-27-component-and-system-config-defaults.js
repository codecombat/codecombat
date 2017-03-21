load('bower_components/lodash/dist/lodash.js');
load('bower_components/underscore.string/dist/underscore.string.min.js');
load('bower_components/tv4/tv4.js');
load('bower_components/treema/treema-utils.js');

print(db.level.components.count());

// This script can be modified later to also remove the old defaults in these components and systems.

migrateDefault = function (doc) {
  thisTv4 = tv4.freshApi();
  thisTv4.addSchema('#', doc.configSchema || {});
  var data = TreemaUtils.cloneDeep(doc.configSchema.default) || {};
  TreemaUtils.populateRequireds(data, doc.configSchema);
  var props = doc.configSchema.properties;
  if(props) {
    _.keys(doc.configSchema.properties).forEach(function (key) {
      if(data[key]) return;
      var childSchema = props[key];
      var workingSchema = TreemaUtils.buildWorkingSchemas(childSchema, thisTv4)[0];
      if(workingSchema.default)
        return data[key] = TreemaUtils.cloneDeep(workingSchema.default);
      var type = props[key].type;
      if(!type) return;
      if(Array.isArray(type)) type = type[0];
      data[key] = TreemaUtils.defaultForType(type);
    })
  }
  delete doc.configSchema.required;
  doc.configSchema.default = data;
//  print('\n\n--------------------', doc.name);
//  print("SCHEMA: ", JSON.stringify(doc.configSchema, null, '\t'));
  if(doc.system) {
    print('saving component', doc.name);
    db.level.components.save(doc);
  }
  else {
    print('saving system', doc.name);
    db.level.systems.save(doc);
  }
};

db.level.components.find({slug: {$exists: true}}).forEach(migrateDefault);
db.level.systems.find({slug: {$exists: true}}).forEach(migrateDefault);

