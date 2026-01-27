/** @type {import('tailwindcss').Config} */
export default {
  content: [
    "./index.html",
    "./src/**/*.{svelte,js,ts,jsx,tsx}",
  ],
  darkMode: 'class', // Enable class-based dark mode
  theme: {
    extend: {
      colors: {
        // Maccy-inspired color palette
        maccy: {
          // Light mode
          bg: '#ffffff',
          bgAlt: '#f5f5f7',
          text: '#1d1d1f',
          textSecondary: '#86868b',
          border: '#d2d2d7',
          accent: '#007aff',
          accentHover: '#0051d5',
          // Dark mode
          darkBg: '#1c1c1e',
          darkBgAlt: '#2c2c2e',
          darkText: '#f5f5f7',
          darkTextSecondary: '#98989d',
          darkBorder: '#38383a',
          darkAccent: '#0a84ff',
          darkAccentHover: '#409cff',
        },
      },
      animation: {
        'fade-in': 'fadeIn 150ms ease-in',
        'slide-up': 'slideUp 200ms ease-out',
      },
      keyframes: {
        fadeIn: {
          '0%': { opacity: '0' },
          '100%': { opacity: '1' },
        },
        slideUp: {
          '0%': { transform: 'translateY(10px)', opacity: '0' },
          '100%': { transform: 'translateY(0)', opacity: '1' },
        },
      },
    },
  },
  plugins: [],
}
