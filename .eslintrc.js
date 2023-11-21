module.exports = {
  plugins: [
    '@babel'
  ],
  extends: [
    'standard',
    'plugin:vue/recommended',
    'plugin:diff/diff',
    'plugin:json/recommended'
  ],

  globals: {
    Vue: 'readonly',
    application: 'readonly',
    me: 'readonly',
    noty: 'readonly',
    features: 'readonly',
    gapi: 'readonly',
    _: 'readonly'
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
    'vue/comment-directive': 'off'
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
