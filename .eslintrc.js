module.exports = {
  plugins: ['@babel'],
  extends: [
    'standard',
    'plugin:vue/recommended'
  ],

  globals: {
    Vue: 'readonly',
    application: 'readonly',
    me: 'readonly',
    noty: 'readonly'
  },

  env: {
    browser: true,
    es6: true,
    es2020: true
  },

  parserOptions: {
    ecmaVersion: 11,
    sourceType: 'module'
  },

  rules: {},

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
