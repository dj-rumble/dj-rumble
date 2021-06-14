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
        'card':
          '0px 0px 0px #000000, 4px 4px 4px #000000',
        'inner-button':
          'inset 0px 0px 20px #323637, inset -2px 0px 2px #323637 !important',
        'inner-input':
          'inset -4px -4px 10px #323637, inset 4px 4px 10px #080a0a'
      }
    },
    fontFamily: {
      'sans': ['Helvetica', 'Arial', 'sans-serif'],
      'street-ruler': ['Street Ruler']
    }
  },
  variants: {
    extend: {
      scale: ['focus-within']
    }
  }
}
