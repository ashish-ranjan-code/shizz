import React, { useEffect, useState } from 'react';
import { MessageSquare } from 'lucide-react';

interface SplashScreenProps {
  onFinish: () => void;
}

export const SplashScreen: React.FC<SplashScreenProps> = ({ onFinish }) => {
  const [fadeState, setFadeState] = useState<'entering' | 'visible' | 'exiting'>('entering');

  useEffect(() => {
    const timer1 = setTimeout(() => {
      setFadeState('visible');
    }, 100);

    const timer2 = setTimeout(() => {
      setFadeState('exiting');
    }, 1500);

    const timer3 = setTimeout(() => {
      onFinish();
    }, 1800);

    return () => {
      clearTimeout(timer1);
      clearTimeout(timer2);
      clearTimeout(timer3);
    };
  }, [onFinish]);

  return (
    <div className="relative w-full h-full min-h-[580px] bg-[#090C14] flex flex-col items-center justify-center overflow-hidden p-6 text-white">
      {/* Ambient background glows */}
      <div className="absolute -top-24 -left-24 w-72 h-72 bg-indigo-600/35 rounded-full blur-3xl pointer-events-none animate-pulse" />
      <div className="absolute -bottom-24 -right-24 w-72 h-72 bg-cyan-500/25 rounded-full blur-3xl pointer-events-none" />

      {/* Center Animated Logo */}
      <div
        className={`flex flex-col items-center text-center transition-all duration-700 transform ${
          fadeState === 'entering'
            ? 'opacity-0 scale-90'
            : fadeState === 'visible'
            ? 'opacity-100 scale-100'
            : 'opacity-0 scale-105'
        }`}
      >
        <div className="w-24 h-24 rounded-3xl bg-gradient-to-tr from-indigo-600 via-indigo-500 to-cyan-400 p-0.5 shadow-2xl shadow-indigo-600/50 flex items-center justify-center mb-6">
          <div className="w-full h-full rounded-[22px] bg-slate-950/40 backdrop-blur-md flex items-center justify-center">
            <MessageSquare size={44} className="text-white drop-shadow-md" />
          </div>
        </div>

        <h1 className="text-3xl font-extrabold tracking-tight text-white mb-2">Shizz</h1>
        <p className="text-xs text-slate-400 tracking-wide font-medium">
          Fast & Secure Messaging
        </p>

        {/* Verification Status Loader */}
        <div className="mt-8 flex items-center gap-2 px-3 py-1.5 rounded-full bg-white/5 border border-white/10 text-[11px] text-slate-300">
          <span className="w-2 h-2 rounded-full bg-cyan-400 animate-ping" />
          <span>Connecting...</span>
        </div>
      </div>
    </div>
  );
};
