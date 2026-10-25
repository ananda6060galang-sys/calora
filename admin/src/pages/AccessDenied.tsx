import React from 'react';
import { useNavigate } from 'react-router-dom';
import { useAdmin } from '../context/AdminContext';
import { ShieldAlert, ArrowLeft } from 'lucide-react';

export const AccessDenied: React.FC = () => {
  const { logout } = useAdmin();
  const navigate = useNavigate();

  const handleReturnToLogin = async () => {
    await logout();
    navigate('/login');
  };

  return (
    <div className="min-h-screen w-screen bg-[#FAFAF8] flex items-center justify-center p-6 select-none font-sans">
      <div className="w-full max-w-md bg-white rounded-3xl shadow-xl border border-gray-100 p-8 text-center space-y-5">
        <div className="w-14 h-14 rounded-2xl bg-red-50 text-calora-danger mx-auto flex items-center justify-center">
          <ShieldAlert className="w-8 h-8" />
        </div>

        <div className="space-y-1">
          <h2 className="text-2xl font-black text-calora-light-text">
            Access Denied
          </h2>
          <p className="text-xs text-gray-500 font-medium">
            This console is restricted to administrators. Your account does not have permission to view this resource.
          </p>
        </div>

        <div className="p-4 bg-gray-50 rounded-xl text-left border border-gray-100">
          <p className="text-[11px] font-semibold text-gray-500">
            Current session role: <strong className="text-calora-light-text">user</strong>
          </p>
          <p className="text-[10px] text-gray-400 mt-1">
            To view personal food logs and workouts, please open the Calora mobile application.
          </p>
        </div>

        <button
          onClick={handleReturnToLogin}
          className="w-full py-3 bg-[#111111] hover:bg-black text-white font-extrabold text-xs rounded-xl transition-all flex items-center justify-center space-x-2"
        >
          <ArrowLeft className="w-4 h-4" />
          <span>Return to Admin Login</span>
        </button>
      </div>
    </div>
  );
};
