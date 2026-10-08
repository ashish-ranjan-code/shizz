/**
 * @license
 * SPDX-License-Identifier: Apache-2.0
 */

import React, { useState } from 'react';
import {
  Smartphone,
  FolderGit2,
  Flame,
  Sparkles,
  Shield,
  Layers,
  ArrowRight
} from 'lucide-react';
import { PhoneSimulator } from './components/PhoneSimulator';
import { CodeInspector } from './components/CodeInspector';
import { FirebaseGuide } from './components/FirebaseGuide';
import { FLUTTER_FILES } from './data/flutterFiles';

export default function App() {
  const [activeView, setActiveView] = useState<'simulator' | 'code' | 'firebase'>('simulator');

  return (
    <div className="min-h-screen bg-[#07090E] text-slate-100 flex flex-col font-sans selection:bg-indigo-500 selection:text-white">
      {/* Top Glass Navigation Bar */}
      <header className="sticky top-0 z-40 bg-[#090C14]/80 backdrop-blur-2xl border-b border-white/10 px-4 py-3">
        <div className="max-w-6xl mx-auto flex flex-wrap items-center justify-between gap-3">
          {/* Logo & Project Tag */}
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 rounded-2xl bg-gradient-to-tr from-indigo-600 via-indigo-500 to-cyan-400 flex items-center justify-center shadow-lg shadow-indigo-600/30">
              <Sparkles size={20} className="text-white" />
            </div>
            <div>
              <div className="flex items-center gap-2">
                <span className="font-black text-lg text-white tracking-tight">Shizz</span>
                <span className="text-[10px] uppercase font-bold tracking-wider px-2 py-0.5 rounded-full bg-indigo-500/10 text-indigo-400 border border-indigo-500/20">
                  Messenger
                </span>
              </div>
              <p className="text-xs text-slate-400 hidden sm:block">
                Real-Time Direct Messaging
              </p>
            </div>
          </div>

          {/* Mode Switcher Buttons */}
          <div className="flex items-center bg-slate-900/90 rounded-2xl p-1 border border-white/10 shadow-inner">
            <button
              onClick={() => setActiveView('simulator')}
              className={`flex items-center gap-1.5 px-3.5 py-1.5 rounded-xl text-xs font-semibold transition-all ${
                activeView === 'simulator'
                  ? 'bg-gradient-to-r from-indigo-600 to-indigo-700 text-white shadow-md shadow-indigo-600/30'
                  : 'text-slate-400 hover:text-white'
              }`}
            >
              <Smartphone size={15} />
              <span>Interactive App</span>
            </button>
            <button
              onClick={() => setActiveView('code')}
              className={`flex items-center gap-1.5 px-3.5 py-1.5 rounded-xl text-xs font-semibold transition-all ${
                activeView === 'code'
                  ? 'bg-gradient-to-r from-indigo-600 to-indigo-700 text-white shadow-md shadow-indigo-600/30'
                  : 'text-slate-400 hover:text-white'
              }`}
            >
              <FolderGit2 size={15} />
              <span>Codebase ({FLUTTER_FILES.length})</span>
            </button>
            <button
              onClick={() => setActiveView('firebase')}
              className={`flex items-center gap-1.5 px-3.5 py-1.5 rounded-xl text-xs font-semibold transition-all ${
                activeView === 'firebase'
                  ? 'bg-gradient-to-r from-indigo-600 to-indigo-700 text-white shadow-md shadow-indigo-600/30'
                  : 'text-slate-400 hover:text-white'
              }`}
            >
              <Flame size={15} />
              <span>Firebase Guide</span>
            </button>
          </div>
        </div>
      </header>

      {/* Main Body View */}
      <main className="flex-1 py-6 px-3 flex flex-col justify-center">
        {activeView === 'simulator' && <PhoneSimulator />}
        {activeView === 'code' && <CodeInspector />}
        {activeView === 'firebase' && <FirebaseGuide />}
      </main>

      {/* Footer Status Bar */}
      <footer className="border-t border-white/5 py-3 px-4 text-center text-xs text-slate-500 bg-[#06080C]">
        <div className="max-w-6xl mx-auto flex flex-wrap items-center justify-between gap-2">
          <span>Project Root: <code className="text-slate-400">D:\shizz\app</code></span>
          <span className="flex items-center gap-1 text-slate-400">
            <Shield size={12} className="text-emerald-400" />
            <span>Firestore Rules: Secured (zero open read/write)</span>
          </span>
          <span className="text-indigo-400 font-mono text-[11px]">End-to-End Synced • Cross-Platform</span>
        </div>
      </footer>
    </div>
  );
}
