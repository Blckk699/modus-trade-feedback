import { StrictMode } from 'react';
import { createRoot } from 'react-dom/client';
import { App } from './app/App';
import { DictionariesProvider } from './app/dictionaries';
import { AuthProvider } from './auth';
import './styles/global.css';

createRoot(document.getElementById('root')!).render(
  <StrictMode>
    <DictionariesProvider>
      <AuthProvider>
        <App />
      </AuthProvider>
    </DictionariesProvider>
  </StrictMode>,
);
