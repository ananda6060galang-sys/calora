import React from 'react';
import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom';
import { AdminProvider } from './context/AdminContext';
import { AdminLayout } from './components/layout/AdminLayout';
import { Login } from './pages/Login';
import { Dashboard } from './pages/Dashboard';
import { FoodRequests } from './pages/FoodRequests';
import { Foods } from './pages/Foods';
import { Categories } from './pages/Categories';
import { UsersPage } from './pages/Users';
import { Analytics } from './pages/Analytics';
import { Settings } from './pages/Settings';
import { AccessDenied } from './pages/AccessDenied';

import { ThemeLanguageProvider } from './context/ThemeLanguageContext';

export const App: React.FC = () => {
  return (
    <BrowserRouter>
      <ThemeLanguageProvider>
        <AdminProvider>
          <Routes>
            {/* Public Auth Routes */}
            <Route path="/login" element={<Login />} />
            <Route path="/access-denied" element={<AccessDenied />} />

            {/* Authenticated Admin Dashboard Routes */}
            <Route element={<AdminLayout />}>
              <Route path="/dashboard" element={<Dashboard />} />
              <Route path="/food-requests" element={<FoodRequests />} />
              <Route path="/foods" element={<Foods />} />
              <Route path="/categories" element={<Categories />} />
              <Route path="/users" element={<UsersPage />} />
              <Route path="/analytics" element={<Analytics />} />
              <Route path="/settings" element={<Settings />} />
            </Route>

            {/* Fallback Root Redirect */}
            <Route path="/" element={<Navigate to="/dashboard" replace />} />
            <Route path="*" element={<Navigate to="/dashboard" replace />} />
          </Routes>
        </AdminProvider>
      </ThemeLanguageProvider>
    </BrowserRouter>
  );
};
