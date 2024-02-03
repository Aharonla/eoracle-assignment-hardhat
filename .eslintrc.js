module.exports = {
  "root": true,
  "env": {
    "mocha": true,
  },
  "extends":[
    "eslint:recommended",
  ],
  "globals": {
    "module": "writable",
    "require": "writable",
    "console": "writable",
    "process": "writable",
  },
  "parserOptions": {
    "ecmaVersion": 2023,
  },
}