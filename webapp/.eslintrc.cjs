module.exports = {
    root: true,
    env: { browser: true, es2020: true },
    extends: [
        'eslint:recommended',
        'plugin:@typescript-eslint/recommended',
        'plugin:react-hooks/recommended'
    ],
    ignorePatterns: ['dist', '.eslintrc.cjs'],
    parser: '@typescript-eslint/parser',
    plugins: ['react-refresh'],
    rules: {
        'react-refresh/only-export-components': 'off',
        'no-unused-vars': ['error', { argsIgnorePattern: '^_' }],
        quotes: [
            'error',
            'single',
            { avoidEscape: true, allowTemplateLiterals: true }
        ]
    }
}
