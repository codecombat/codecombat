const c = require('./../schemas');
const metaschema = require('./../metaschema');

const attackSelfCode = `\
class AttacksSelf extends Component
  @className: 'AttacksSelf'
  chooseAction: ->
    @attack @\
`;
const systems = [
  'action', 'ai', 'alliance', 'collision', 'combat', 'display', 'event', 'existence', 'hearing',
  'inventory', 'movement', 'programming', 'targeting', 'ui', 'vision', 'misc', 'physics', 'effect',
  'magic', 'game'
];

const DependencySchema = c.object({
  title: 'Component Dependency',
  description: 'A Component upon which this Component depends.',
  required: ['original', 'majorVersion'],
  format: 'latest-version-reference',
  links: [{rel: 'db', href: '/db/level.component/{(original)}/version/{(majorVersion)}'}]
}, {
  original: c.objectId({title: 'Original', description: 'A reference to another Component upon which this Component depends.'}),
  majorVersion: {
    title: 'Major Version',
    description: 'Which major version of the Component this Component needs.',
    type: 'integer',
    minimum: 0
  }
}
);

const LevelComponentSchema = c.object({
  title: 'Component',
  description: 'A Component which can affect Thang behavior.',
  required: ['system', 'name', 'code'],
  default: {
    system: 'ai',
    name: 'AttacksSelf',
    description: 'This Component makes the Thang attack itself.',
    code: attackSelfCode,
    codeLanguage: 'coffeescript',
    dependencies: [],  // TODO: should depend on something by default
    propertyDocumentation: [],
    configSchema: {},
    context: {}
  }
});
c.extendNamedProperties(LevelComponentSchema);  // let's have the name be the first property
LevelComponentSchema.properties.name.pattern = c.classNamePattern;
_.extend(LevelComponentSchema.properties, {
  system: {
    title: 'System',
    description: 'The short name of the System this Component belongs to, like \"ai\".',
    type: 'string',
    'enum': systems
  },
  description: {
    title: 'Description',
    description: 'A short explanation of what this Component does.',
    type: 'string',
    maxLength: 2000
  },
  codeLanguage: {
    type: 'string',
    title: 'Language',
    description: 'Which programming language this Component is written in.',
    'enum': ['coffeescript', 'javascript']
  },
  code: {
    title: 'Code',
    description: 'The code for this Component, as a CoffeeScript/JavaScript class. TODO: add link to documentation for how to write these.',
    type: 'string',
    format: 'coffee'
  },
  js: {
    title: 'JavaScript',
    description: 'The transpiled JavaScript code for this Component',
    type: 'string',
    format: 'hidden'
  },
  dependencies: c.array({title: 'Dependencies', description: 'An array of Components upon which this Component depends.', uniqueItems: true}, DependencySchema),
  propertyDocumentation: c.array({title: 'Property Documentation', description: 'An array of documentation entries for each notable property this Component will add to its Thang which other Components might want to also use.'}, c.PropertyDocumentationSchema),
  configSchema: _.extend(metaschema, {title: 'Configuration Schema', description: 'A schema for validating the arguments that can be passed to this Component as configuration.', default: {type: 'object'}}),
  official: {
    type: 'boolean',
    title: 'Official',
    description: 'Whether this is an official CodeCombat Component.'
  },
  searchStrings: {type: 'string'},
  context: {
    type: 'object',
    title: 'Code context',
    additionalProperties: { type: 'string' },
    default: {}
  },
  i18n: {
    type: 'object',
    format: 'i18n',
    props: ['context'], description: 'Help translate the code context'
  },
  archived: { type: 'integer', description: 'Marks this component to be hidden from searches and lookups. Number is milliseconds since 1 January 1970 UTC, when it was marked as hidden.'}
});

c.extendBasicProperties(LevelComponentSchema, 'level.component');
c.extendSearchableProperties(LevelComponentSchema);
c.extendVersionedProperties(LevelComponentSchema, 'level.component');
c.extendPermissionsProperties(LevelComponentSchema, 'level.component');
c.extendPatchableProperties(LevelComponentSchema);
c.extendTranslationCoverageProperties(LevelComponentSchema);

module.exports = LevelComponentSchema;
