/** @type {import('tailwindcss').Config} */
export default {
  content: [
    "./index.html",
    "./src/**/*.{js,ts,jsx,tsx}",
  ],
  theme: {
    extend: {
      colors: {
        brandDark: '#0B121E',
        brandSurface: '#141F32',
        gainGreen: '#00D09C',
        lossRed: '#FF5353',
      },
    },
  },
  plugins: [],
}
