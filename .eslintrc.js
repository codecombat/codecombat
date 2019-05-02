module.exports = {
    'extends': [
        'standard',
        'plugin:vue/recommended'
    ],

    'env': {
        'browser': true,
        'es6': true
    },

    'globals': {
        'Atomics': 'readonly',
        'SharedArrayBuffer': 'readonly'
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
        }],

        "vue/v-on-style": ["error", "longform"]
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
