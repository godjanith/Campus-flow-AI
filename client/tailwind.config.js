/** @type {import('tailwindcss').Config} */
export default {
  content: [
    "./index.html",
    "./src/**/*.{js,ts,jsx,tsx}",
  ],
  theme: {
    extend: {
      colors: {
        navy: {
          DEFAULT: '#0F294A',
          dark: '#0A1C33',
          light: '#1A3B63',
        },
        gold: {
          DEFAULT: '#C59B27',
          light: '#DFB847',
          subtle: '#FDF8EB',
        },
        ivory: '#F8FAFC',
        porcelain: '#FFFFFF',
        brand: {
          50: '#eef2ff',
          100: '#e0e7ff',
          500: '#0F294A',
          600: '#0F294A',
          700: '#0A1C33',
        }
      }
    },
  },
  plugins: [],
}
