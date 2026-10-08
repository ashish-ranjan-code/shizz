import React from 'react';
import {
  Flame,
  ShieldCheck,
  CheckCircle2,
  Terminal,
  Database,
  KeyRound,
  HardDrive,
  Copy,
  ExternalLink
} from 'lucide-react';

export const FirebaseGuide: React.FC = () => {
  return (
    <div className="w-full max-w-4xl mx-auto p-4 space-y-6 text-slate-100">
      {/* Header */}
      <div className="bg-gradient-to-r from-amber-500/10 via-slate-900 to-indigo-950/40 border border-amber-500/30 rounded-3xl p-6 backdrop-blur-xl">
        <div className="flex items-center gap-2 mb-2">
          <Flame className="text-amber-400" size={24} />
          <h2 className="text-xl font-black text-white">Firebase Console Configuration Guide</h2>
        </div>
        <p className="text-xs text-slate-300 max-w-2xl leading-relaxed">
          Follow these quick steps in your Firebase Console project to finalize your live database, authentication, and storage configuration for <strong className="text-white">Shizz</strong>.
        </p>
      </div>

      {/* Troubleshooting Alert: Why no user data is shown yet */}
      <div className="bg-rose-500/10 border border-rose-500/30 rounded-3xl p-5 backdrop-blur-xl space-y-3">
        <div className="flex items-center gap-2 text-rose-400 font-bold text-sm">
          <Database size={18} />
          <span>Why is no database or user data showing in Firebase Console?</span>
        </div>
        <p className="text-xs text-slate-300 leading-relaxed">
          If you open the Firebase Console and don't see any database, collections, or user data, this happens for two specific reasons:
        </p>
        <div className="grid grid-cols-1 md:grid-cols-2 gap-3 text-xs">
          <div className="bg-black/30 p-3.5 rounded-2xl border border-white/5 space-y-1.5">
            <span className="font-bold text-amber-300">1. Firestore is NOT auto-created</span>
            <p className="text-slate-400 leading-relaxed">
              Firebase does not create a database automatically. In Firebase Console, navigate to <strong>Build &gt; Firestore Database</strong>. If you see the button <strong className="text-white">"Create database"</strong>, you <strong>must click it</strong>, choose a location (e.g. <code className="text-cyan-400">nam5</code> / <code className="text-cyan-400">us-central1</code>), and select <strong>Enable</strong>. Until you do this, the database does not exist.
            </p>
          </div>
          <div className="bg-black/30 p-3.5 rounded-2xl border border-white/5 space-y-1.5">
            <span className="font-bold text-cyan-300">2. Collections appear only on the first write</span>
            <p className="text-slate-400 leading-relaxed">
              Firestore is a schemaless document store. Collections like <code className="text-cyan-400">users</code> and <code className="text-cyan-400">usernames</code> do not exist as empty tables—they are created dynamically the moment your first user signs up on your Flutter app (`flutter run`).
            </p>
          </div>
        </div>
      </div>

      {/* Grid of Steps */}
      <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
        {/* Step 1: Authentication */}
        <div className="bg-slate-900/60 border border-white/10 rounded-2xl p-5 backdrop-blur-md flex flex-col justify-between">
          <div>
            <div className="flex items-center gap-2 text-indigo-400 mb-2 font-bold text-sm">
              <KeyRound size={18} />
              <span>1. Enable Email/Password & Google Auth</span>
            </div>
            <ul className="text-xs text-slate-300 space-y-2 mt-3">
              <li className="flex items-start gap-2">
                <CheckCircle2 size={14} className="text-emerald-400 mt-0.5 shrink-0" />
                <span>Go to <strong>Firebase Console &gt; Build &gt; Authentication &gt; Sign-in method</strong>.</span>
              </li>
              <li className="flex items-start gap-2">
                <CheckCircle2 size={14} className="text-emerald-400 mt-0.5 shrink-0" />
                <span>Enable <strong>Email/Password</strong> provider.</span>
              </li>
              <li className="flex items-start gap-2">
                <CheckCircle2 size={14} className="text-emerald-400 mt-0.5 shrink-0" />
                <span>Click <strong>Add new provider</strong>, select <strong>Google</strong>, turn on <strong>Enable</strong>, and set your support email.</span>
              </li>
            </ul>
          </div>
          <div className="mt-4 pt-3 border-t border-white/5 text-[11px] text-slate-400">
            Used by <code className="text-cyan-400">AuthService</code>, <code className="text-cyan-400">AuthProvider</code>, and <code className="text-cyan-400">google_sign_in</code>.
          </div>
        </div>

        {/* Step 2: Firestore Database */}
        <div className="bg-slate-900/60 border border-cyan-500/30 rounded-2xl p-5 backdrop-blur-md flex flex-col justify-between">
          <div>
            <div className="flex items-center gap-2 text-cyan-400 mb-2 font-bold text-sm">
              <Database size={18} />
              <span>2. Click "Create database" in Firestore</span>
            </div>
            <ul className="text-xs text-slate-300 space-y-2 mt-3">
              <li className="flex items-start gap-2">
                <CheckCircle2 size={14} className="text-emerald-400 mt-0.5 shrink-0" />
                <span>Go to <strong>Firebase Console &gt; Build &gt; Firestore Database</strong>.</span>
              </li>
              <li className="flex items-start gap-2">
                <CheckCircle2 size={14} className="text-emerald-400 mt-0.5 shrink-0" />
                <span>Click the <strong>"Create database"</strong> button (Firestore won't exist until you do this!).</span>
              </li>
              <li className="flex items-start gap-2">
                <CheckCircle2 size={14} className="text-emerald-400 mt-0.5 shrink-0" />
                <span>Choose your region (e.g. <code>nam5</code> or <code>us-central1</code>) and click <strong>Enable</strong>.</span>
              </li>
              <li className="flex items-start gap-2">
                <CheckCircle2 size={14} className="text-emerald-400 mt-0.5 shrink-0" />
                <span>Under the <strong>Rules</strong> tab, paste <code className="text-cyan-300">firestore.rules</code> and click <strong>Publish</strong>.</span>
              </li>
            </ul>
          </div>
          <div className="mt-4 pt-3 border-t border-white/5 text-[11px] text-slate-400">
            Stores <code className="text-cyan-400">users</code>, unique <code className="text-cyan-400">usernames</code> index, follow requests, and 1-to-1 <code className="text-cyan-400">chats</code>.
          </div>
        </div>

        {/* Step 3: Android Package & SHA-1 / SHA-256 Setup */}
        <div className="bg-slate-900/60 border border-amber-500/30 rounded-2xl p-5 backdrop-blur-md flex flex-col justify-between">
          <div>
            <div className="flex items-center gap-2 text-amber-400 mb-2 font-bold text-sm">
              <ShieldCheck size={18} />
              <span>3. Android Google Sign-In SHA-1 / SHA-256</span>
            </div>
            <ul className="text-xs text-slate-300 space-y-2 mt-3">
              <li className="flex items-start gap-2">
                <CheckCircle2 size={14} className="text-emerald-400 mt-0.5 shrink-0" />
                <span>Android Package: <strong className="text-white font-mono">com.shizz.messenger</strong></span>
              </li>
              <li className="flex items-start gap-2">
                <CheckCircle2 size={14} className="text-amber-400 mt-0.5 shrink-0" />
                <span><strong>Required for Android Google Sign-In:</strong> Add your SHA-1 &amp; SHA-256 fingerprint in <strong>Project Settings &gt; Your apps &gt; Android app</strong>.</span>
              </li>
              <li className="flex items-start gap-2">
                <CheckCircle2 size={14} className="text-emerald-400 mt-0.5 shrink-0" />
                <span>Command:
                  <div className="mt-1 bg-slate-950 p-2 rounded-lg font-mono text-[10px] text-cyan-300">
                    cd android &amp;&amp; ./gradlew signingReport
                  </div>
                </span>
              </li>
              <li className="flex items-start gap-2">
                <CheckCircle2 size={14} className="text-emerald-400 mt-0.5 shrink-0" />
                <span>Place downloaded <code className="text-amber-300">google-services.json</code> at <code className="text-amber-300">android/app/google-services.json</code>.</span>
              </li>
            </ul>
          </div>
          <div className="mt-4 pt-3 border-t border-white/5 text-[11px] text-amber-400/90">
            ⚠️ Without SHA-1 configured in Firebase, Google Sign-In on Android will fail with <code className="text-rose-400">ApiException: 10</code>.
          </div>
        </div>

        {/* Step 4: Firebase Storage */}
        <div className="bg-slate-900/60 border border-white/10 rounded-2xl p-5 backdrop-blur-md flex flex-col justify-between">
          <div>
            <div className="flex items-center gap-2 text-violet-400 mb-2 font-bold text-sm">
              <HardDrive size={18} />
              <span>4. Firebase Storage (Profile Photos)</span>
            </div>
            <ul className="text-xs text-slate-300 space-y-2 mt-3">
              <li className="flex items-start gap-2">
                <CheckCircle2 size={14} className="text-emerald-400 mt-0.5 shrink-0" />
                <span>Go to <strong>Firebase Console &gt; Build &gt; Storage</strong>.</span>
              </li>
              <li className="flex items-start gap-2">
                <CheckCircle2 size={14} className="text-emerald-400 mt-0.5 shrink-0" />
                <span>Click <strong>Get Started</strong> to provision the default storage bucket.</span>
              </li>
              <li className="flex items-start gap-2">
                <CheckCircle2 size={14} className="text-emerald-400 mt-0.5 shrink-0" />
                <span>Deploy the security rules from <code className="text-violet-300">storage.rules</code>.</span>
              </li>
            </ul>
          </div>
          <div className="mt-4 pt-3 border-t border-white/5 text-[11px] text-slate-400">
            Uploads saved under <code className="text-cyan-400">profile_images/{'{uid}'}.jpg</code>.
          </div>
        </div>

        {/* Step 5: Run Commands */}
        <div className="bg-slate-900/60 border border-white/10 rounded-2xl p-5 backdrop-blur-md flex flex-col justify-between">
          <div>
            <div className="flex items-center gap-2 text-emerald-400 mb-2 font-bold text-sm">
              <Terminal size={18} />
              <span>5. Run on Device / Emulator</span>
            </div>
            <div className="bg-slate-950/80 rounded-xl p-3 border border-white/5 font-mono text-[11px] text-slate-300 space-y-1.5 mt-2">
              <p className="text-slate-500"># Navigate to project</p>
              <p className="text-emerald-400">cd D:\shizz\app</p>
              <p className="text-slate-500"># Install updated dependencies</p>
              <p className="text-cyan-300">flutter pub get</p>
              <p className="text-slate-500"># Launch real-time messaging app</p>
              <p className="text-indigo-400">flutter run</p>
            </div>
          </div>
          <div className="mt-4 pt-3 border-t border-white/5 text-[11px] text-slate-400">
            Runs on Android, iOS, or Web with zero code changes.
          </div>
        </div>
      </div>
    </div>
  );
};
