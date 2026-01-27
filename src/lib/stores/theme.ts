import { writable } from 'svelte/store';

type Theme = 'light' | 'dark';

// Check if we're in browser environment
const isBrowser = typeof window !== 'undefined';

// Detect system theme preference
function getSystemTheme(): Theme {
  if (!isBrowser) return 'light';
  return window.matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'light';
}

// Load saved theme or use system preference
function getInitialTheme(): Theme {
  if (!isBrowser) return 'light';
  const saved = localStorage.getItem('theme') as Theme | null;
  return saved || getSystemTheme();
}

export const theme = writable<Theme>(getInitialTheme());

// Subscribe to theme changes and update DOM
if (isBrowser) {
  theme.subscribe(value => {
    if (value === 'dark') {
      document.documentElement.classList.add('dark');
    } else {
      document.documentElement.classList.remove('dark');
    }
    localStorage.setItem('theme', value);
  });

  // Listen for system theme changes
  window.matchMedia('(prefers-color-scheme: dark)').addEventListener('change', (e) => {
    if (!localStorage.getItem('theme')) {
      theme.set(e.matches ? 'dark' : 'light');
    }
  });
}

export function toggleTheme() {
  theme.update(current => current === 'light' ? 'dark' : 'light');
}
