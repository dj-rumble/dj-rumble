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
        'inner-card-xl':
          'inset 0px 0px 10px #323637, inset 4px 0px 10px #080a0a',
        'inner-input':
          'inset -4px -4px 10px #323637, inset 4px 4px 10px #080a0a',
        'light-card':
          '0px 0px 0px #000000, 4px 4px 4px #666'
      },
      gridAutoRows: {
        'custom':
          'minmax(10%, auto) minmax(10%, auto) minmax(10%, auto) minmax(10%, auto) minmax(10%, auto) minmax(10%, auto) minmax(30%, auto) minmax(30%, auto) minmax(30%, auto) minmax(10%, auto) minmax(10%, auto) minmax(10%, auto)'
      },
      gridRow: {
        'span-10': 'span 10 / span 10',
        'span-11': 'span 11 / span 11',
        'span-12': 'span 12 / span 12',
        'span-7': 'span 7 / span 7',
        'span-8': 'span 8 / span 8',
        'span-9': 'span 9 / span 9'
      },
      gridRowEnd: {
        '10': '10',
        '11': '11',
        '12': '12',
        '7': '7',
        '8': '8',
        '9': '9'
      },
      gridRowStart: {
        '10': '10',
        '11': '11',
        '12': '12',
        '7': '7',
        '8': '8',
        '9': '9'
      },
      gridTemplateRows: {
        'custom':
          'repeat(6, minmax(10%, auto)) repeat(3, minmax(30%, auto)) repeat(3, minmax(10%, auto))'
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
        'fit': 'fit-content',
        'max-content': 'max-content',
        'screen-150': '150vh'
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
        '9/10': '90vh',
        'screen-200': '200vh'
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
    },
    zIndex: {
      '100': 100,
      '50': 50,
      '60': 60,
      '70': 70,
      '80': 80,
      '90': 90,
      '999': 999
    }
  },
  variants: {
    extend: {
      scale: ['focus-within']
    }
  }
}
