/** @type {import('tailwindcss').Config} */
export default {
  content: [
    "./index.html",
    "./src/**/*.{js,ts,jsx,tsx}",
  ],
  darkMode: 'class',
  theme: {
    extend: {
      colors: {
        calora: {
          accent: '#B8FF3B',
          'accent-soft': '#E7FF8C',
          lavender: '#8B7CFF',
          protein: '#FF6B57',
          carbs: '#FFC24B',
          fat: '#7C9CFF',
          success: '#3DDC84',
          warning: '#FFB020',
          danger: '#FF5A5F',
          // Dark botanical surfaces
          'dark-bg': '#0F1410',
          'dark-surface': '#181E19',
          'dark-surface-alt': '#202820',
          'dark-elevated': '#293329',
          'dark-border': '#303830',
          'dark-text': '#F3F5EF',
          'dark-muted': '#A5AEA3',
          // Light surfaces
          'light-bg': '#FAFAF8',
          'light-surface': '#FFFFFF',
          'light-surface-alt': '#F4F4F2',
          'light-border': '#ECECEC',
          'light-text': '#111111',
          // Reference canvas tones
          canvas: '#EAECE8',
          card: '#FFFFFF',
          'green-banner': '#66CC00',
          'green-bright': '#76D700',
          'dark-panel': '#1B241E',
          'dark-card': '#252F28',
          'dark-pill': '#2E3931',
        },
        prodex: {
          navy: '#1B1D28',
          'navy-hover': '#242736',
          lime: '#D4FF32',
          'lime-soft': '#E6FFA1',
          orange: '#FFA048',
          bg: '#EDEFEA',
          card: '#FFFFFF',
          'light-gray': '#F4F5F7',
          border: '#E8EAE6',
        },
      },
      fontFamily: {
        sans: ['Inter', 'system-ui', '-apple-system', 'BlinkMacSystemFont', 'sans-serif'],
      },
      borderRadius: {
        '2xl': '1.25rem',
        '3xl': '1.5rem',
        '4xl': '2rem',
        '5xl': '2.5rem',
      },
      boxShadow: {
        xs: '0 1px 2px 0 rgba(0, 0, 0, 0.05)',
        card: '0 4px 20px -2px rgba(0, 0, 0, 0.03)',
        'card-elevated': '0 12px 32px -4px rgba(0, 0, 0, 0.06)',
      },
    },
  },
  plugins: [],
}
