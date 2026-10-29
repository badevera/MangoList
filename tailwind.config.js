/** @type {import('tailwindcss').Config} */
export default {
  content: ['./src/**/*.{html,js,svelte,ts}'],
  theme: {
    extend: {
      colors: {
        ink: '#18231b',
        cream: '#fffaf0',
        mango: '#f5aa3c',
        leaf: '#4d8056'
      },
      fontFamily: {
        display: ['"Fraunces"', 'Georgia', 'serif'],
        sans: ['"DM Sans"', 'ui-sans-serif', 'system-ui', 'sans-serif']
      },
      boxShadow: {
        card: '0 12px 35px rgba(48, 69, 45, 0.08)'
      }
    }
  },
  plugins: [require('daisyui')],
  daisyui: {
    themes: false
  }
};
