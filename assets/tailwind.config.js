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
        'inner-card-md': 'inset 0 0 10px #000000',
        'inner-input':
          'inset -4px -4px 10px #323637, inset 4px 4px 10px #080a0a'
      },
      height: {
        '1/10': '10vh',
        '2/10': '20vh',
        '3/10': '30vh',
        '4/10': '40vh',
        '5/10': '50vh',
        '6/10': '60vh',
        '7/10': '70vh',
        '8/10': '80vh',
        '9/10': '90vh',
        '99/100': '99vh',
        'fit': 'fit-content'
      },
      maxHeight: {
        '1/10': '10vh',
        '2/10': '20vh',
        '3/10': '30vh',
        '4/10': '40vh',
        '5/10': '50vh',
        '6/10': '60vh',
        '7/10': '70vh',
        '8/10': '80vh',
        '9/10': '90vh'
      },
      minHeight: {
        '1/10': '10vh',
        '2/10': '20vh',
        '3/10': '30vh',
        '4/10': '40vh',
        '5/10': '50vh',
        '6/10': '60vh',
        '7/10': '70vh',
        '8/10': '80vh',
        '9/10': '90vh'
      },
      top: {
        'lg': '90vh',
        'md': '30vh'
      },
      transitionDuration: {
        '1500': '1500ms',
        '1750': '1750ms',
        '2000': '2000ms',
        '2500': '2500ms',
        '3000': '3000ms'
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
