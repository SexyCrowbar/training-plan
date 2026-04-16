/** @type {import('tailwindcss').Config} */
export default {
  content: ['./index.html', './src/**/*.{js,jsx}'],
  theme: {
    extend: {
      colors: {
        iron: { primary: '#f0c040', dim: 'rgba(240,192,64,0.12)', surface: '#1a1f2e', surface2: '#212840' },
        body: { primary: '#22d3ee', dim: 'rgba(34,211,238,0.12)', surface: '#0d2535', surface2: '#112d40' },
        rest: { primary: '#818cf8', dim: 'rgba(129,140,248,0.12)', surface: '#181825', surface2: '#201f30' },
      },
      fontFamily: {
        sans: ['-apple-system', 'BlinkMacSystemFont', '"Segoe UI"', 'Roboto', 'sans-serif'],
      }
    }
  },
  plugins: []
}
