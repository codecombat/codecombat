load('bower_components/lodash/dist/lodash.js');
load('bower_components/underscore.string/dist/underscore.string.min.js');
load('bower_components/tv4/tv4.js');
load('bower_components/treema/treema-utils.js');
print(typeof TreemaUtils);

print(db.level.components.count());
db.level.components.find().limit(3000000).forEach(function (levelComponent) {
  thisTv4 = tv4.freshApi();
  thisTv4.addSchema('#', levelComponent.configSchema || {});
  var data = levelComponent.configSchema.default || {};
  TreemaUtils.populateRequireds(data, levelComponent.configSchema);
  var props = levelComponent.configSchema.properties;
  if(props) {
    _.keys(levelComponent.configSchema.properties).forEach(function (key) {
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
  delete levelComponent.configSchema.required;
  levelComponent.configSchema.default = data;
  print('\n\n--------------------', levelComponent.name);
  print("SCHEMA: ", JSON.stringify(levelComponent.configSchema, null, '\t'));
  
});

