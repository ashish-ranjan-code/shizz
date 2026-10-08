import React, { useState, useEffect } from 'react';
import { AtSign, CheckCircle2, XCircle, Sparkles, AlertCircle, ArrowRight, Check } from 'lucide-react';
import { AuthStorageService } from '../../services/authStorage';
import { UserProfile } from '../../types/shizz';

interface ChooseUsernameScreenProps {
  googleProfile: {
    uid: string;
    email: string;
    displayName: string;
    photoUrl?: string;
  };
  onSuccess: (user: UserProfile) => void;
  onCancel: () => void;
}

export const ChooseUsernameScreen: React.FC<ChooseUsernameScreenProps> = ({
  googleProfile,
  onSuccess,
  onCancel,
}) => {
  // Pre-suggest initial handle based on email prefix or display name
  const defaultSuggestion = (googleProfile.email.split('@')[0] || googleProfile.displayName.replace(/\s+/g, '_'))
    .toLowerCase()
    .replace(/[^a-z0-9_]/g, '');

  const [username, setUsername] = useState(defaultSuggestion);
  const [isUsernameAvailable, setIsUsernameAvailable] = useState<boolean | null>(null);
  const [usernameFeedback, setUsernameFeedback] = useState<string | null>(null);
  const [isLoading, setIsLoading] = useState(false);
  const [errorMessage, setErrorMessage] = useState<string | null>(null);

  // Check username availability in real-time
  useEffect(() => {
    const clean = username.trim().toLowerCase().replace(/[^a-z0-9_]/g, '');

    if (!clean) {
      setIsUsernameAvailable(null);
      setUsernameFeedback(null);
      return;
    }

    if (clean.length < 3) {
      setIsUsernameAvailable(false);
      setUsernameFeedback('Username must be at least 3 characters');
      return;
    }

    const available = AuthStorageService.isUsernameAvailable(clean);
    setIsUsernameAvailable(available);
    setUsernameFeedback(available ? 'Username available ✓' : 'Username already taken');
  }, [username]);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setErrorMessage(null);

    const clean = username.trim().toLowerCase().replace(/[^a-z0-9_]/g, '');

    if (clean.length < 3 || clean.length > 20) {
      setErrorMessage('Username must be between 3 and 20 characters.');
      return;
    }

    if (isUsernameAvailable === false) {
      setErrorMessage('This username is already taken. Please choose another.');
      return;
    }

    setIsLoading(true);

    try {
      const newUser = await AuthStorageService.completeGoogleSignUp(googleProfile, clean);
      setIsLoading(false);
      onSuccess(newUser);
    } catch (err: any) {
      setIsLoading(false);
      setErrorMessage(err.message || 'Failed to complete registration.');
    }
  };

  return (
    <div className="relative w-full h-full min-h-[580px] bg-[#090C14] flex flex-col justify-center p-6 text-slate-100 overflow-y-auto">
      {/* Ambient background glows */}
      <div className="absolute -top-20 -left-20 w-64 h-64 bg-indigo-600/30 rounded-full blur-3xl pointer-events-none" />
      <div className="absolute -bottom-20 -right-20 w-64 h-64 bg-cyan-500/20 rounded-full blur-3xl pointer-events-none" />

      <div className="relative z-10 w-full max-w-sm mx-auto space-y-5">
        {/* Header */}
        <div className="text-center space-y-2">
          {/* Google Avatar */}
          <div className="relative inline-block mx-auto">
            <div className="w-16 h-16 rounded-full bg-gradient-to-tr from-indigo-500 to-cyan-400 p-0.5 shadow-xl shadow-indigo-600/30">
              <div className="w-full h-full rounded-full bg-slate-900 overflow-hidden flex items-center justify-center font-bold text-lg text-white">
                {googleProfile.photoUrl ? (
                  <img src={googleProfile.photoUrl} alt="Google Avatar" className="w-full h-full object-cover" />
                ) : (
                  googleProfile.displayName.slice(0, 2).toUpperCase()
                )}
              </div>
            </div>
            {/* Google G badge */}
            <div className="absolute -bottom-1 -right-1 w-6 h-6 rounded-full bg-white p-1 shadow flex items-center justify-center">
              <svg className="w-3.5 h-3.5" viewBox="0 0 24 24">
                <path fill="#4285F4" d="M23.745 12.27c0-.7-.06-1.4-.19-2.07H12v4.51h6.6c-.29 1.52-1.14 2.82-2.4 3.68v3.05h3.88c2.27-2.09 3.665-5.17 3.665-9.17Z"/>
                <path fill="#34A853" d="M12 24c3.24 0 5.95-1.08 7.93-2.91l-3.88-3.05c-1.08.72-2.45 1.16-4.05 1.16-3.12 0-5.77-2.1-6.72-4.93H1.25v3.15C3.27 21.36 7.34 24 12 24Z"/>
                <path fill="#FBBC05" d="M5.28 14.27c-.25-.72-.38-1.49-.38-2.27s.13-1.55.38-2.27V6.58H1.25C.45 8.17 0 9.99 0 12s.45 3.83 1.25 5.42l4.03-3.15Z"/>
                <path fill="#EA4335" d="M12 4.75c1.77 0 3.35.61 4.6 1.8l3.42-3.42C17.94 1.19 15.24 0 12 0 7.34 0 3.27 2.64 1.25 6.58l4.03 3.15c.95-2.83 3.6-4.98 6.72-4.98Z"/>
              </svg>
            </div>
          </div>

          <h2 className="text-2xl font-black text-white tracking-tight">Choose Your Username</h2>
          <p className="text-xs text-slate-400">
            Welcome, <strong className="text-slate-200">{googleProfile.displayName}</strong>! Pick a unique @handle for Shizz.
          </p>
        </div>

        {/* Error Alert */}
        {errorMessage && (
          <div className="p-3 rounded-2xl bg-rose-500/10 border border-rose-500/30 text-rose-300 text-xs flex items-start gap-2.5 backdrop-blur-md">
            <AlertCircle size={16} className="shrink-0 mt-0.5 text-rose-400" />
            <span className="leading-relaxed">{errorMessage}</span>
          </div>
        )}

        {/* Form Card */}
        <form onSubmit={handleSubmit} className="p-5 rounded-3xl bg-white/5 border border-white/10 backdrop-blur-xl shadow-xl space-y-4">
          {/* Connected Google Account pill */}
          <div className="p-2.5 rounded-xl bg-white/5 border border-white/10 flex items-center justify-between text-xs">
            <div className="flex items-center gap-2 truncate">
              <span className="w-2 h-2 rounded-full bg-emerald-400 shrink-0" />
              <span className="text-slate-400 truncate">{googleProfile.email}</span>
            </div>
            <span className="text-[10px] uppercase font-bold tracking-wider px-2 py-0.5 rounded-full bg-indigo-500/20 text-indigo-300 shrink-0">
              Google Verified
            </span>
          </div>

          {/* Unique Username Input */}
          <div className="space-y-1.5">
            <div className="flex justify-between items-center">
              <label className="text-xs font-semibold text-slate-300">Shizz Username</label>
              {usernameFeedback && (
                <span
                  className={`text-[10px] font-bold ${
                    isUsernameAvailable ? 'text-emerald-400' : 'text-rose-400'
                  }`}
                >
                  {usernameFeedback}
                </span>
              )}
            </div>

            <div className="relative">
              <div className="absolute left-3.5 top-1/2 -translate-y-1/2 text-cyan-400 font-bold text-xs select-none">
                @
              </div>
              <input
                type="text"
                required
                value={username}
                onChange={e => {
                  const raw = e.target.value.replace(/^@/, '');
                  setUsername(raw);
                }}
                placeholder="alex_coder"
                className={`w-full pl-8 pr-9 py-2.5 rounded-xl bg-white/5 border text-xs text-white placeholder-slate-500 focus:outline-none ${
                  isUsernameAvailable === true
                    ? 'border-emerald-500/60 focus:border-emerald-500'
                    : isUsernameAvailable === false
                    ? 'border-rose-500/60 focus:border-rose-500'
                    : 'border-white/10 focus:border-indigo-500'
                }`}
              />
              <div className="absolute right-3 top-1/2 -translate-y-1/2">
                {isUsernameAvailable === true && (
                  <CheckCircle2 size={16} className="text-emerald-400" />
                )}
                {isUsernameAvailable === false && (
                  <XCircle size={16} className="text-rose-400" />
                )}
              </div>
            </div>
            <p className="text-[11px] text-slate-500">
              Only letters, numbers, and underscores (3–20 chars).
            </p>
          </div>

          {/* Submit Button */}
          <button
            type="submit"
            disabled={isLoading || isUsernameAvailable === false}
            className="w-full mt-2 py-3 rounded-xl bg-gradient-to-r from-indigo-600 via-indigo-500 to-cyan-500 text-white font-bold text-xs tracking-wide shadow-lg shadow-indigo-600/30 hover:opacity-95 active:scale-[0.99] transition-all flex items-center justify-center gap-2 disabled:opacity-50"
          >
            {isLoading ? (
              <div className="w-4 h-4 border-2 border-white/30 border-t-white rounded-full animate-spin" />
            ) : (
              <>
                <span>Complete & Start Chatting</span>
                <ArrowRight size={15} />
              </>
            )}
          </button>

          <button
            type="button"
            onClick={onCancel}
            className="w-full py-2 text-xs text-slate-400 hover:text-white transition-colors"
          >
            Cancel and return to Login
          </button>
        </form>
      </div>
    </div>
  );
};
