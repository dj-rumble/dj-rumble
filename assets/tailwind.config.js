module.exports = {
  darkMode: false, // or 'media' or 'class'
  important: true,
  plugins: [],
  purge: [
    '../lib/**/*.ex',
    '../lib/**/*.leex',
    '../lib/**/*.eex',
    './js/**/*.js'
  ],
  theme: {
    extend: {
      boxShadow: {
        'inner-input': 'inset -4px -4px 10px #323637, inset 4px 4px 10px #080a0a',
        'card': '0px 0px 0px #000000, 4px 4px 4px #000000',
      }
    },
  },
  variants: {
    extend: {},
  },
}
