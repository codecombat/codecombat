module.exports = {
    'extends': [
        'standard',
        'plugin:vue/recommended'
    ],

    'globals': {
        'Vue': 'readonly',
        'application': 'readonly',
        'me': 'readonly',
        'noty': 'readonly'
    },

    'env': {
        'browser': true,
        'es6': true
    },

    'parserOptions': {
        'ecmaVersion': 2018,
        'sourceType': 'module'
    },

    'rules': {
        'vue/script-indent': ['error', 2, {
            'baseIndent': 1,
            'switchCase': 0,
            'ignores': []
        }]
    },

    'overrides': [
        // Disable indent in .vue files - this will be handled by vue/script-indent
        {
            'files': ['*.vue'],
            'rules': {
                'indent': 'off'
            }
        }
    ]
}
