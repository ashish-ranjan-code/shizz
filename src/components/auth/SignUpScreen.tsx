import React, { useState, useEffect } from 'react';
import { User, AtSign, Mail, Lock, Eye, EyeOff, UserPlus, AlertCircle, Sparkles, CheckCircle2, XCircle, X } from 'lucide-react';
import { AuthStorageService } from '../../services/authStorage';
import { UserProfile } from '../../types/shizz';

interface SignUpScreenProps {
  onSuccess: (user: UserProfile) => void;
  onNavigateToLogin: () => void;
  onGoogleSignInNeedsUsername: (googleProfile: {
    uid: string;
    email: string;
    displayName: string;
    photoUrl?: string;
  }) => void;
}

export const SignUpScreen: React.FC<SignUpScreenProps> = ({
  onSuccess,
  onNavigateToLogin,
  onGoogleSignInNeedsUsername,
}) => {
  const [displayName, setDisplayName] = useState('');
  const [username, setUsername] = useState('');
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [confirmPassword, setConfirmPassword] = useState('');
  const [showPassword, setShowPassword] = useState(false);
  const [showConfirmPassword, setShowConfirmPassword] = useState(false);

  // Real-time username validation state
  const [isUsernameAvailable, setIsUsernameAvailable] = useState<boolean | null>(null);
  const [usernameFeedback, setUsernameFeedback] = useState<string | null>(null);
  const [isLoading, setIsLoading] = useState(false);
  const [errorMessage, setErrorMessage] = useState<string | null>(null);
  const [showGoogleModal, setShowGoogleModal] = useState(false);
  const [customGoogleEmail, setCustomGoogleEmail] = useState('');
  const [customGoogleName, setCustomGoogleName] = useState('');
  const [isCustomGoogleOpen, setIsCustomGoogleOpen] = useState(false);

  const handleSelectGoogleAccount = async (account: {
    email: string;
    displayName: string;
    photoUrl?: string;
  }) => {
    setShowGoogleModal(false);
    setIsCustomGoogleOpen(false);
    setIsLoading(true);
    setErrorMessage(null);

    try {
      const result = await AuthStorageService.signInWithGoogle(account);
      setIsLoading(false);

      if (result.status === 'existing_user' && result.user) {
        onSuccess(result.user);
      } else if (result.status === 'new_user_needs_username' && result.googleProfile) {
        onGoogleSignInNeedsUsername(result.googleProfile);
      }
    } catch (err: any) {
      setIsLoading(false);
      setErrorMessage(err.message || 'Google sign-in failed.');
    }
  };

  // Check username in real time as user types
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

    const cleanUsername = username.trim().toLowerCase().replace(/[^a-z0-9_]/g, '');

    if (!displayName.trim() || !cleanUsername || !email.trim() || !password || !confirmPassword) {
      setErrorMessage('Please fill out all registration fields.');
      return;
    }

    if (password !== confirmPassword) {
      setErrorMessage('Passwords do not match.');
      return;
    }

    if (password.length < 6) {
      setErrorMessage('Password must be at least 6 characters long.');
      return;
    }

    if (isUsernameAvailable === false) {
      setErrorMessage('Please choose a different username. This one is already taken.');
      return;
    }

    setIsLoading(true);

    try {
      const newUser = await AuthStorageService.signUp(
        email,
        password,
        confirmPassword,
        cleanUsername,
        displayName
      );
      setIsLoading(false);
      onSuccess(newUser);
    } catch (err: any) {
      setIsLoading(false);
      setErrorMessage(err.message || 'Account registration failed.');
    }
  };

  return (
    <div className="relative w-full h-full min-h-[580px] bg-[#090C14] flex flex-col justify-center p-6 text-slate-100 overflow-y-auto">
      {/* Ambient background glows */}
      <div className="absolute -top-20 -left-20 w-64 h-64 bg-indigo-600/30 rounded-full blur-3xl pointer-events-none" />
      <div className="absolute -bottom-20 -right-20 w-64 h-64 bg-cyan-500/20 rounded-full blur-3xl pointer-events-none" />

      <div className="relative z-10 w-full max-w-sm mx-auto space-y-4">
        {/* Header */}
        <div className="text-center space-y-1">
          <div className="w-14 h-14 mx-auto rounded-2xl bg-gradient-to-tr from-indigo-600 via-indigo-500 to-cyan-400 p-0.5 shadow-lg shadow-indigo-600/30 flex items-center justify-center">
            <div className="w-full h-full rounded-[14px] bg-slate-950/40 backdrop-blur-md flex items-center justify-center">
              <Sparkles size={24} className="text-white" />
            </div>
          </div>
          <h2 className="text-2xl font-black text-white tracking-tight">Create Account</h2>
          <p className="text-xs text-slate-400">
            Choose your unique @username and profile
          </p>
        </div>

        {/* Error Alert */}
        {errorMessage && (
          <div className="p-3 rounded-2xl bg-rose-500/10 border border-rose-500/30 text-rose-300 text-xs flex items-start gap-2.5 backdrop-blur-md animate-shake">
            <AlertCircle size={16} className="shrink-0 mt-0.5 text-rose-400" />
            <span className="leading-relaxed">{errorMessage}</span>
          </div>
        )}

        {/* Form Card */}
        <form onSubmit={handleSubmit} className="p-4.5 rounded-3xl bg-white/5 border border-white/10 backdrop-blur-xl shadow-xl space-y-3">
          {/* Display Name */}
          <div className="space-y-1">
            <label className="text-[11px] font-semibold text-slate-300">Display Name</label>
            <div className="relative">
              <User size={15} className="absolute left-3.5 top-1/2 -translate-y-1/2 text-slate-400" />
              <input
                type="text"
                required
                value={displayName}
                onChange={e => setDisplayName(e.target.value)}
                placeholder="Ashish Kumar"
                className="w-full pl-9 pr-3 py-2 rounded-xl bg-white/5 border border-white/10 text-xs text-white placeholder-slate-500 focus:outline-none focus:border-indigo-500"
              />
            </div>
          </div>

          {/* Unique Username with @ Prefix */}
          <div className="space-y-1">
            <div className="flex justify-between items-center">
              <label className="text-[11px] font-semibold text-slate-300">Unique Username</label>
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
                placeholder="ashish_dev"
                className={`w-full pl-8 pr-8 py-2 rounded-xl bg-white/5 border text-xs text-white placeholder-slate-500 focus:outline-none ${
                  isUsernameAvailable === true
                    ? 'border-emerald-500/60 focus:border-emerald-500'
                    : isUsernameAvailable === false
                    ? 'border-rose-500/60 focus:border-rose-500'
                    : 'border-white/10 focus:border-indigo-500'
                }`}
              />
              <div className="absolute right-2.5 top-1/2 -translate-y-1/2">
                {isUsernameAvailable === true && (
                  <CheckCircle2 size={15} className="text-emerald-400" />
                )}
                {isUsernameAvailable === false && (
                  <XCircle size={15} className="text-rose-400" />
                )}
              </div>
            </div>
          </div>

          {/* Email Input */}
          <div className="space-y-1">
            <label className="text-[11px] font-semibold text-slate-300">Email Address</label>
            <div className="relative">
              <Mail size={15} className="absolute left-3.5 top-1/2 -translate-y-1/2 text-slate-400" />
              <input
                type="email"
                required
                value={email}
                onChange={e => setEmail(e.target.value)}
                placeholder="ashish@example.com"
                className="w-full pl-9 pr-3 py-2 rounded-xl bg-white/5 border border-white/10 text-xs text-white placeholder-slate-500 focus:outline-none focus:border-indigo-500"
              />
            </div>
          </div>

          {/* Password Input */}
          <div className="space-y-1">
            <label className="text-[11px] font-semibold text-slate-300">Password (min 6 chars)</label>
            <div className="relative">
              <Lock size={15} className="absolute left-3.5 top-1/2 -translate-y-1/2 text-slate-400" />
              <input
                type={showPassword ? 'text' : 'password'}
                required
                minLength={6}
                value={password}
                onChange={e => setPassword(e.target.value)}
                placeholder="••••••••"
                className="w-full pl-9 pr-9 py-2 rounded-xl bg-white/5 border border-white/10 text-xs text-white placeholder-slate-500 focus:outline-none focus:border-indigo-500"
              />
              <button
                type="button"
                onClick={() => setShowPassword(!showPassword)}
                className="absolute right-3 top-1/2 -translate-y-1/2 text-slate-400 hover:text-white"
              >
                {showPassword ? <EyeOff size={14} /> : <Eye size={14} />}
              </button>
            </div>
          </div>

          {/* Confirm Password Input */}
          <div className="space-y-1">
            <label className="text-[11px] font-semibold text-slate-300">Confirm Password</label>
            <div className="relative">
              <Lock size={15} className="absolute left-3.5 top-1/2 -translate-y-1/2 text-slate-400" />
              <input
                type={showConfirmPassword ? 'text' : 'password'}
                required
                minLength={6}
                value={confirmPassword}
                onChange={e => setConfirmPassword(e.target.value)}
                placeholder="••••••••"
                className="w-full pl-9 pr-9 py-2 rounded-xl bg-white/5 border border-white/10 text-xs text-white placeholder-slate-500 focus:outline-none focus:border-indigo-500"
              />
              <button
                type="button"
                onClick={() => setShowConfirmPassword(!showConfirmPassword)}
                className="absolute right-3 top-1/2 -translate-y-1/2 text-slate-400 hover:text-white"
              >
                {showConfirmPassword ? <EyeOff size={14} /> : <Eye size={14} />}
              </button>
            </div>
          </div>

          {/* Submit Button */}
          <button
            type="submit"
            disabled={isLoading || isUsernameAvailable === false}
            className="w-full mt-2 py-2.5 rounded-xl bg-gradient-to-r from-indigo-600 via-indigo-500 to-cyan-500 text-white font-bold text-xs tracking-wide shadow-lg shadow-indigo-600/30 hover:opacity-95 active:scale-[0.99] transition-all flex items-center justify-center gap-2 disabled:opacity-50"
          >
            {isLoading ? (
              <div className="w-4 h-4 border-2 border-white/30 border-t-white rounded-full animate-spin" />
            ) : (
              <>
                <UserPlus size={15} />
                <span>Create Account</span>
              </>
            )}
          </button>

          {/* Divider "OR" */}
          <div className="flex items-center gap-3 pt-1">
            <div className="flex-1 h-px bg-white/10" />
            <span className="text-[10px] font-bold text-slate-500 uppercase tracking-wider">or fast sign up with</span>
            <div className="flex-1 h-px bg-white/10" />
          </div>

          {/* Continue with Google Button */}
          <button
            type="button"
            disabled={isLoading}
            onClick={() => setShowGoogleModal(true)}
            className="w-full py-2.5 px-4 rounded-xl bg-white/10 hover:bg-white/15 border border-white/15 text-white text-xs font-semibold flex items-center justify-center gap-2.5 transition-all shadow-sm active:scale-[0.99] disabled:opacity-50"
          >
            <svg className="w-4 h-4 shrink-0" viewBox="0 0 24 24">
              <path fill="#4285F4" d="M23.745 12.27c0-.7-.06-1.4-.19-2.07H12v4.51h6.6c-.29 1.52-1.14 2.82-2.4 3.68v3.05h3.88c2.27-2.09 3.665-5.17 3.665-9.17Z"/>
              <path fill="#34A853" d="M12 24c3.24 0 5.95-1.08 7.93-2.91l-3.88-3.05c-1.08.72-2.45 1.16-4.05 1.16-3.12 0-5.77-2.1-6.72-4.93H1.25v3.15C3.27 21.36 7.34 24 12 24Z"/>
              <path fill="#FBBC05" d="M5.28 14.27c-.25-.72-.38-1.49-.38-2.27s.13-1.55.38-2.27V6.58H1.25C.45 8.17 0 9.99 0 12s.45 3.83 1.25 5.42l4.03-3.15Z"/>
              <path fill="#EA4335" d="M12 4.75c1.77 0 3.35.61 4.6 1.8l3.42-3.42C17.94 1.19 15.24 0 12 0 7.34 0 3.27 2.64 1.25 6.58l4.03 3.15c.95-2.83 3.6-4.98 6.72-4.98Z"/>
            </svg>
            <span>Continue with Google</span>
          </button>
        </form>

        {/* Switch to Login */}
        <div className="text-center text-xs text-slate-400">
          <span>Already have an account? </span>
          <button
            type="button"
            onClick={onNavigateToLogin}
            className="text-cyan-400 font-bold hover:underline"
          >
            Sign In
          </button>
        </div>
      </div>

      {/* Google Account Selector Sheet/Modal */}
      {showGoogleModal && (
        <div className="fixed inset-0 z-50 bg-black/70 backdrop-blur-sm flex items-center justify-center p-4">
          <div className="w-full max-w-sm bg-slate-900 border border-white/15 rounded-3xl p-5 shadow-2xl text-slate-100 animate-in fade-in zoom-in-95 duration-200">
            <div className="flex items-center justify-between pb-3 border-b border-white/10 mb-3">
              <div className="flex items-center gap-2">
                <svg className="w-4 h-4" viewBox="0 0 24 24">
                  <path fill="#4285F4" d="M23.745 12.27c0-.7-.06-1.4-.19-2.07H12v4.51h6.6c-.29 1.52-1.14 2.82-2.4 3.68v3.05h3.88c2.27-2.09 3.665-5.17 3.665-9.17Z"/>
                  <path fill="#34A853" d="M12 24c3.24 0 5.95-1.08 7.93-2.91l-3.88-3.05c-1.08.72-2.45 1.16-4.05 1.16-3.12 0-5.77-2.1-6.72-4.93H1.25v3.15C3.27 21.36 7.34 24 12 24Z"/>
                  <path fill="#FBBC05" d="M5.28 14.27c-.25-.72-.38-1.49-.38-2.27s.13-1.55.38-2.27V6.58H1.25C.45 8.17 0 9.99 0 12s.45 3.83 1.25 5.42l4.03-3.15Z"/>
                  <path fill="#EA4335" d="M12 4.75c1.77 0 3.35.61 4.6 1.8l3.42-3.42C17.94 1.19 15.24 0 12 0 7.34 0 3.27 2.64 1.25 6.58l4.03 3.15c.95-2.83 3.6-4.98 6.72-4.98Z"/>
                </svg>
                <h3 className="font-bold text-sm text-white">Choose a Google Account</h3>
              </div>
              <button
                onClick={() => {
                  setShowGoogleModal(false);
                  setErrorMessage('Google sign-in was cancelled.');
                }}
                className="p-1 rounded-lg text-slate-400 hover:text-white"
              >
                <X size={16} />
              </button>
            </div>

            <p className="text-xs text-slate-400 mb-3">
              to continue to <strong className="text-white">Shizz</strong>
            </p>

            {/* List of Accounts */}
            <div className="space-y-2 mb-3">
              {/* Option A: Existing Google Account */}
              <button
                onClick={() =>
                  handleSelectGoogleAccount({
                    email: 'sarah@example.com',
                    displayName: 'Sarah Jenkins',
                    photoUrl: 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=150',
                  })
                }
                className="w-full p-2.5 rounded-2xl bg-white/5 hover:bg-white/10 border border-white/10 flex items-center gap-3 text-left transition-all"
              >
                <div className="w-9 h-9 rounded-full bg-gradient-to-tr from-pink-500 to-indigo-500 flex items-center justify-center font-bold text-white text-xs shrink-0">
                  SJ
                </div>
                <div className="flex-1 truncate">
                  <h4 className="font-bold text-xs text-white">Sarah Jenkins (Existing)</h4>
                  <p className="text-[11px] text-slate-400 truncate">sarah@example.com</p>
                </div>
                <span className="text-[10px] text-emerald-400 font-semibold px-2 py-0.5 rounded-full bg-emerald-500/10 shrink-0">
                  Direct Home
                </span>
              </button>

              {/* Option B: New Google Account */}
              <button
                onClick={() =>
                  handleSelectGoogleAccount({
                    email: 'alex.rivera.dev@gmail.com',
                    displayName: 'Alex Rivera',
                    photoUrl: 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=150',
                  })
                }
                className="w-full p-2.5 rounded-2xl bg-white/5 hover:bg-white/10 border border-white/10 flex items-center gap-3 text-left transition-all"
              >
                <div className="w-9 h-9 rounded-full bg-gradient-to-tr from-cyan-500 to-blue-600 flex items-center justify-center font-bold text-white text-xs shrink-0">
                  AR
                </div>
                <div className="flex-1 truncate">
                  <h4 className="font-bold text-xs text-white">Alex Rivera (New Google User)</h4>
                  <p className="text-[11px] text-slate-400 truncate">alex.rivera.dev@gmail.com</p>
                </div>
                <span className="text-[10px] text-cyan-400 font-semibold px-2 py-0.5 rounded-full bg-cyan-500/10 shrink-0">
                  Pick @handle
                </span>
              </button>

              {/* Custom Google Account */}
              {!isCustomGoogleOpen ? (
                <button
                  onClick={() => setIsCustomGoogleOpen(true)}
                  className="w-full py-2 px-3 rounded-xl border border-dashed border-white/20 text-slate-400 hover:text-white text-xs flex items-center justify-center gap-1.5 transition-colors"
                >
                  <User size={14} />
                  <span>Use another Google account</span>
                </button>
              ) : (
                <div className="p-3 rounded-2xl bg-white/5 border border-white/15 space-y-2 mt-2">
                  <input
                    type="email"
                    value={customGoogleEmail}
                    onChange={e => setCustomGoogleEmail(e.target.value)}
                    placeholder="google.user@gmail.com"
                    className="w-full px-3 py-1.5 rounded-xl bg-white/5 border border-white/10 text-xs text-white placeholder-slate-500 focus:outline-none focus:border-indigo-500"
                  />
                  <input
                    type="text"
                    value={customGoogleName}
                    onChange={e => setCustomGoogleName(e.target.value)}
                    placeholder="Your Google Display Name"
                    className="w-full px-3 py-1.5 rounded-xl bg-white/5 border border-white/10 text-xs text-white placeholder-slate-500 focus:outline-none focus:border-indigo-500"
                  />
                  <button
                    disabled={!customGoogleEmail.includes('@')}
                    onClick={() =>
                      handleSelectGoogleAccount({
                        email: customGoogleEmail,
                        displayName: customGoogleName || customGoogleEmail.split('@')[0],
                      })
                    }
                    className="w-full py-2 rounded-xl bg-indigo-600 text-white text-xs font-bold disabled:opacity-50"
                  >
                    Authenticate with this Google Account
                  </button>
                </div>
              )}
            </div>

            <button
              onClick={() => {
                setShowGoogleModal(false);
                setErrorMessage('Google sign-in was cancelled.');
              }}
              className="w-full py-1.5 text-xs text-slate-400 hover:text-white text-center"
            >
              Cancel
            </button>
          </div>
        </div>
      )}
    </div>
  );
};
