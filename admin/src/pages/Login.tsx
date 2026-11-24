import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { authService } from '../services/authService';
import { useAdmin } from '../context/AdminContext';
import {
  ArrowRight,
  AlertCircle,
} from 'lucide-react';
import bannerLogin from '../assets/banner_login.png';

export const Login: React.FC = () => {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState<string | null>(null);
  const [isLoading, setIsLoading] = useState(false);

  const { setUser, refreshAll } = useAdmin();
  const navigate = useNavigate();

  const handleLogin = async (e: React.FormEvent) => {
    e.preventDefault();
    setIsLoading(true);
    setError(null);

    const result = await authService.login(email.trim(), password.trim());

    if (result.error) {
      setIsLoading(false);
      if (result.error === 'ACCESS_DENIED') {
        setError('Access Denied: This account does not possess administrative privileges.');
      } else {
        setError(result.error);
      }
      return;
    }

    setUser(result.user);
    await refreshAll();
    setIsLoading(false);
    navigate('/dashboard');
  };

  return (
    <div className="min-h-screen w-screen bg-[#FAFAF8] flex items-center justify-center p-4 sm:p-8 select-none font-sans">
      
      {/* Main Card */}
      <div className="w-full max-w-[1000px] bg-white rounded-[2rem] shadow-2xl shadow-gray-200/60 flex flex-col lg:flex-row p-2.5">
        
        {/* Left Image Section */}
        <div className="relative w-full lg:w-[45%] h-[280px] lg:h-[600px] rounded-[1.5rem] overflow-hidden bg-black flex-shrink-0">
          <img 
            src={bannerLogin} 
            alt="Calora Banner" 
            className="w-full h-full object-cover"
          />
        </div>

        {/* Right Form Section */}
        <div className="w-full lg:w-[55%] flex items-center justify-center p-8 lg:p-16">
          <div className="w-full max-w-sm space-y-10">
            
            <div className="space-y-2">
              <h1 className="text-3xl font-black text-[#111111] tracking-tight">
                Log in
              </h1>
              <p className="text-sm text-gray-500 font-medium">
                Calora Admin Console Access
              </p>
            </div>

            {error && (
              <div className="p-3.5 bg-red-50 border border-red-200 rounded-2xl flex items-center space-x-3 text-sm font-semibold text-red-600">
                <AlertCircle className="w-4.5 h-4.5 shrink-0 text-red-500" strokeWidth={2} />
                <span>{error}</span>
              </div>
            )}

            {/* Login Form */}
            <form onSubmit={handleLogin} className="space-y-5">
              <div className="space-y-1.5">
                <label className="text-sm font-semibold text-stone-900 block">
                  Email Address
                </label>
                <input
                  type="email"
                  required
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                  placeholder="admin@calora.app"
                  className="w-full px-4.5 py-3 rounded-full border border-stone-200 bg-white text-sm font-medium text-stone-900 focus:outline-none focus:ring-2 focus:ring-[#B8FF3B]/70 focus:border-transparent transition-all placeholder:font-normal placeholder:text-stone-400"
                />
              </div>

              <div className="space-y-1.5">
                <label className="text-sm font-semibold text-stone-900 block">
                  Password
                </label>
                <input
                  type="password"
                  required
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  placeholder="••••••••"
                  className="w-full px-4.5 py-3 rounded-full border border-stone-200 bg-white text-sm font-medium text-stone-900 focus:outline-none focus:ring-2 focus:ring-[#B8FF3B]/70 focus:border-transparent transition-all placeholder:font-normal placeholder:text-stone-400"
                />
              </div>

              <div className="pt-2">
                <button
                  type="submit"
                  disabled={isLoading}
                  className="w-full py-3.5 bg-[#B8FF3B] hover:brightness-105 text-[#0C2417] font-bold text-sm rounded-full shadow-xs transition-all flex items-center justify-center space-x-2 active:scale-[0.98] cursor-pointer disabled:opacity-70 disabled:cursor-not-allowed"
                >
                  <span>{isLoading ? 'Authenticating...' : 'Log in'}</span>
                  {!isLoading && <ArrowRight className="w-4.5 h-4.5 text-[#0C2417]" strokeWidth={2.5} />}
                </button>
              </div>
            </form>

            <div className="text-center pt-4">
              <p className="text-xs text-stone-500 font-medium leading-relaxed">
                Protected by Supabase Auth &amp; PostgreSQL RLS.
              </p>
            </div>

          </div>
        </div>
      </div>
    </div>
  );
};
