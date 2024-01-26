module.exports = {
  plugins: [
    '@babel'
  ],
  extends: [
    'standard',
    'plugin:vue/recommended',
    'plugin:json/recommended'
  ],

  globals: {
    Vue: 'readonly',
    application: 'readonly',
    me: 'readonly',
    noty: 'readonly',
    features: 'readonly',
    gapi: 'readonly',
    _: 'readonly',
    Backbone: 'readonly',
    jasmine: 'readonly',
    zE: 'readonly',
    ga: 'readonly',
    moment: 'readonly',
    webkit: 'readonly',
    Vuex: 'readonly',
    d3: 'readonly',
    algoliasearch: 'readonly',
    FB: 'readonly',
    lscache: 'readonly',
    tv4: 'readonly',
    TreemaUtils: 'readonly',
    TreemaObjectNode: 'readonly',
    TreemaArrayNode: 'readonly',
    CoffeeScript: 'readonly',
    i18n: 'readonly',
    marked: 'readonly'
  },

  env: {
    browser: true,
    es2022: true,
    jquery: true
  },

  parserOptions: {
    ecmaVersion: 13,
    sourceType: 'module'
  },

  rules: {
    'vue/script-indent': ['warn', 2, {
      baseIndent: 0,
      switchCase: 0,
      ignores: []
    }],
    'vue/comment-directive': 'off',
    'eol-last': 'off', // Disables the enforcement for having no newline at the end of files
    'comma-dangle': ['error', 'only-multiline']
  },

  ignorePatterns: [
    '*.coffee',
    '*.png',
    '*.pug',
    '*.sass',
    '*.jpg',
    '*.svg',
    '*.scss',
    '*.webp',
    '*.webm',
    '*.mp4'
  ],

  overrides: [
    // Disable indent in .vue files - this will be handled by vue/script-indent
    {
      files: ['*.vue'],
      rules: {
        indent: 'off'
      }
    }
  ]
}
