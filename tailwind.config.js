/** @type {import('tailwindcss').Config} */
export default {
  content: [
    "./app/**/*.elm",
    "./src/**/*.elm"
  ],
  theme: {
    extend: {
      colors: {
        'iko': {
          500: '#30651A'
        }
      }
    },
  },
  plugins: [],
}

