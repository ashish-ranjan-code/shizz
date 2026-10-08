import React, { useState } from 'react';
import {
  FileCode,
  Folder,
  FolderOpen,
  Copy,
  Check,
  Download,
  Terminal,
  ExternalLink,
  ShieldAlert,
  Sparkles
} from 'lucide-react';
import { FLUTTER_FILES } from '../data/flutterFiles';

export const CodeInspector: React.FC = () => {
  const [selectedFilePath, setSelectedFilePath] = useState<string>('lib/main.dart');
  const [copied, setCopied] = useState<boolean>(false);

  const selectedFile = FLUTTER_FILES.find(f => f.path === selectedFilePath) || FLUTTER_FILES[0];

  const handleCopy = () => {
    navigator.clipboard.writeText(selectedFile.content);
    setCopied(true);
    setTimeout(() => setCopied(false), 2000);
  };

  const categories = [
    { id: 'root', name: 'Root Config & Entry' },
    { id: 'models', name: 'Models (models/)' },
    { id: 'services', name: 'Firebase Services (services/)' },
    { id: 'providers', name: 'State Management (providers/)' },
    { id: 'screens', name: 'Screens (screens/)' },
    { id: 'widgets', name: 'UI Widgets (widgets/)' },
    { id: 'theme', name: 'Theme & Utilities' },
  ];

  return (
    <div className="w-full max-w-5xl mx-auto p-4 flex flex-col gap-4 text-slate-100">
      {/* Overview Banner */}
      <div className="bg-gradient-to-r from-indigo-950/60 via-slate-900 to-slate-900/90 border border-indigo-500/30 rounded-3xl p-5 backdrop-blur-xl flex flex-wrap items-center justify-between gap-4 shadow-xl shadow-indigo-950/20">
        <div>
          <div className="flex items-center gap-2 mb-1">
            <span className="px-2.5 py-0.5 rounded-full text-[11px] font-bold bg-indigo-500/20 text-indigo-300 border border-indigo-500/30 uppercase tracking-wider">
              Target: D:\shizz\app
            </span>
            <span className="text-xs text-slate-400">Architecture Verified</span>
          </div>
          <h2 className="text-xl font-black text-white tracking-tight">Full Flutter + Firebase Codebase</h2>
          <p className="text-xs text-slate-300 mt-1 max-w-xl">
            Modular architecture with complete separation of concerns: models, real-time listeners, Auth providers, custom UI widgets, and secure security rules.
          </p>
        </div>

        <div className="flex items-center gap-2">
          <div className="bg-slate-800/80 border border-white/10 rounded-2xl px-3 py-2 text-xs">
            <span className="text-slate-400 block text-[10px]">Total Files Created</span>
            <span className="font-bold text-white text-sm">34 Files in lib/ & root</span>
          </div>
        </div>
      </div>

      {/* Code Browser Grid */}
      <div className="grid grid-cols-1 md:grid-cols-12 gap-4 bg-slate-900/60 border border-white/10 rounded-3xl p-4 backdrop-blur-xl min-h-[580px]">
        {/* Left Sidebar: File Tree */}
        <div className="md:col-span-4 border-r border-white/10 pr-3 space-y-4 overflow-y-auto max-h-[560px]">
          <div className="text-xs font-bold uppercase tracking-wider text-slate-400 px-2 flex items-center justify-between">
            <span>Project Explorer</span>
            <span className="text-[10px] bg-white/5 px-2 py-0.5 rounded-md">lib/</span>
          </div>

          <div className="space-y-3">
            {categories.map(cat => {
              const filesInCat = FLUTTER_FILES.filter(f => {
                if (cat.id === 'root') return f.category === 'root';
                if (cat.id === 'theme') return f.category === 'theme' || f.category === 'utils';
                return f.category === cat.id;
              });

              if (filesInCat.length === 0) return null;

              return (
                <div key={cat.id} className="space-y-1">
                  <div className="flex items-center gap-1.5 text-xs font-semibold text-slate-400 px-2">
                    <FolderOpen size={14} className="text-indigo-400" />
                    <span>{cat.name}</span>
                  </div>
                  <div className="space-y-0.5 pl-3 border-l border-white/5 ml-3">
                    {filesInCat.map(file => (
                      <button
                        key={file.path}
                        onClick={() => setSelectedFilePath(file.path)}
                        className={`w-full text-left px-2.5 py-1.5 rounded-xl text-xs flex items-center justify-between transition-all ${
                          selectedFilePath === file.path
                            ? 'bg-indigo-600 text-white font-medium shadow-md shadow-indigo-600/30'
                            : 'text-slate-300 hover:bg-white/5 hover:text-white'
                        }`}
                      >
                        <div className="flex items-center gap-2 truncate">
                          <FileCode size={13} className={selectedFilePath === file.path ? 'text-white' : 'text-slate-500'} />
                          <span className="truncate">{file.path.split('/').pop()}</span>
                        </div>
                      </button>
                    ))}
                  </div>
                </div>
              );
            })}
          </div>
        </div>

        {/* Right Code Content Pane */}
        <div className="md:col-span-8 flex flex-col pl-2">
          {/* File Header */}
          <div className="flex items-center justify-between pb-3 border-b border-white/10 mb-3">
            <div>
              <div className="flex items-center gap-2">
                <FileCode size={16} className="text-cyan-400" />
                <h3 className="text-sm font-bold text-white font-mono">{selectedFile.path}</h3>
              </div>
              <p className="text-xs text-slate-400 mt-0.5">{selectedFile.description}</p>
            </div>

            <button
              onClick={handleCopy}
              className="flex items-center gap-1.5 px-3 py-1.5 rounded-xl text-xs font-semibold bg-white/10 hover:bg-white/15 border border-white/10 text-white transition-all shadow-sm"
            >
              {copied ? <Check size={14} className="text-emerald-400" /> : <Copy size={14} />}
              <span>{copied ? 'Copied to Clipboard!' : 'Copy File'}</span>
            </button>
          </div>

          {/* Syntax Display Area */}
          <div className="flex-1 bg-slate-950/80 border border-white/5 rounded-2xl p-4 overflow-x-auto overflow-y-auto max-h-[480px] font-mono text-xs text-slate-300 leading-relaxed">
            <pre className="whitespace-pre">{selectedFile.content}</pre>
          </div>

          <div className="mt-3 flex items-center justify-between text-[11px] text-slate-500">
            <span>Location on disk: {selectedFile.path}</span>
            <span className="text-indigo-400">Ready for D:\shizz\app</span>
          </div>
        </div>
      </div>
    </div>
  );
};
