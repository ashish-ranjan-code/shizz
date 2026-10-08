import React, { useState, useEffect, useRef } from 'react';
import {
  MessageSquare,
  Users,
  User as UserIcon,
  Search,
  Send,
  ArrowLeft,
  Check,
  CheckCheck,
  Smartphone,
  Maximize2,
  Minimize2,
  Paperclip,
  LogOut,
  Edit3,
  UserPlus,
  UserCheck,
  Palette,
  Sun,
  Moon,
  Monitor,
  X,
  Info,
  Clock,
  UserMinus,
  Settings,
  Bell,
  AlertCircle
} from 'lucide-react';
import { UserProfile, MessageItem } from '../types/shizz';
import { AuthStorageService, FollowRequest } from '../services/authStorage';
import { SplashScreen } from './auth/SplashScreen';
import { LoginScreen } from './auth/LoginScreen';
import { SignUpScreen } from './auth/SignUpScreen';
import { ChooseUsernameScreen } from './auth/ChooseUsernameScreen';

export const PhoneSimulator: React.FC = () => {
  // Authentication State
  const [authStatus, setAuthStatus] = useState<'splash' | 'login' | 'signup' | 'choose_username' | 'authenticated'>('splash');
  const [pendingGoogleProfile, setPendingGoogleProfile] = useState<{
    uid: string;
    email: string;
    displayName: string;
    photoUrl?: string;
  } | null>(null);
  const [currentUser, setCurrentUser] = useState<UserProfile | null>(null);

  // Data Store
  const [users, setUsers] = useState<Record<string, UserProfile>>({});
  const [messages, setMessages] = useState<MessageItem[]>([]);
  const [themeMode, setThemeMode] = useState<'dark' | 'light' | 'system'>('dark');

  // Navigation State
  const [activeTab, setActiveTab] = useState<'chats' | 'search' | 'profile'>('chats');
  const [activeChatRecipientId, setActiveChatRecipientId] = useState<string | null>(null);
  const [searchQuery, setSearchQuery] = useState('');
  const [userSearchText, setUserSearchText] = useState('');
  const [messageInput, setMessageInput] = useState('');
  const [isEditingProfile, setIsEditingProfile] = useState(false);
  const [isAppearanceOpen, setIsAppearanceOpen] = useState(false);
  const [selectedUserModal, setSelectedUserModal] = useState<UserProfile | null>(null);
  const [expandedImage, setExpandedImage] = useState<string | null>(null);

  // Social Sub-views
  const [activeSocialModal, setActiveSocialModal] = useState<'followers' | 'following' | 'requests' | null>(null);
  const [socialModalTargetUid, setSocialModalTargetUid] = useState<string | null>(null);

  // Edit fields
  const [editName, setEditName] = useState('');
  const [editUsername, setEditUsername] = useState('');
  const [editBio, setEditBio] = useState('');
  const [profileEditError, setProfileEditError] = useState<string | null>(null);
  const [deviceFrame, setDeviceFrame] = useState(true);

  const fileInputRef = useRef<HTMLInputElement>(null);
  const messagesEndRef = useRef<HTMLDivElement>(null);

  const isLight = themeMode === 'light';

  // Load Initial Users & Messages Database
  const reloadData = () => {
    const loadedUsers = AuthStorageService.getUsers();
    setUsers(loadedUsers);

    const loadedMessages = AuthStorageService.getMessages();
    setMessages(loadedMessages);

    const sessionUser = AuthStorageService.getCurrentUser();
    if (sessionUser && loadedUsers[sessionUser.uid]) {
      setCurrentUser(loadedUsers[sessionUser.uid]);
    }
  };

  useEffect(() => {
    reloadData();
  }, []);

  // Auth State Listener
  useEffect(() => {
    const unsubscribe = AuthStorageService.subscribeAuth(user => {
      setCurrentUser(user);
      if (user) {
        setAuthStatus('authenticated');
      } else if (authStatus !== 'splash') {
        setAuthStatus('login');
      }
    });
    return () => unsubscribe();
  }, [authStatus]);

  // Deterministic Chat ID generator
  const getChatId = (uid1: string, uid2: string) => {
    return uid1 < uid2 ? `${uid1}_${uid2}` : `${uid2}_${uid1}`;
  };

  useEffect(() => {
    if (activeChatRecipientId) {
      messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
    }
  }, [messages, activeChatRecipientId]);

  // Mark messages as read when opening a conversation
  useEffect(() => {
    if (activeChatRecipientId && currentUser) {
      const activeChatId = getChatId(currentUser.uid, activeChatRecipientId);
      setMessages(prev => {
        const updated = prev.map(msg => {
          if (msg.chatId === activeChatId && msg.receiverId === currentUser.uid && !msg.isRead) {
            return { ...msg, isRead: true };
          }
          return msg;
        });
        AuthStorageService.saveMessages(updated);
        return updated;
      });
    }
  }, [activeChatRecipientId, currentUser]);

  const handleSplashFinish = () => {
    const sessionUser = AuthStorageService.getCurrentUser();
    if (sessionUser) {
      setCurrentUser(sessionUser);
      setAuthStatus('authenticated');
    } else {
      setAuthStatus('login');
    }
  };

  const handleSignOut = async () => {
    await AuthStorageService.signOut();
    setCurrentUser(null);
    setActiveChatRecipientId(null);
    setSelectedUserModal(null);
    setAuthStatus('login');
  };

  const handleSendMessage = (e?: React.FormEvent) => {
    if (e) e.preventDefault();
    if (!messageInput.trim() || !activeChatRecipientId || !currentUser) return;

    const activeChatId = getChatId(currentUser.uid, activeChatRecipientId);
    const now = new Date();
    const timeString = now.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });

    const newMsg: MessageItem = {
      messageId: `msg_${Date.now()}`,
      chatId: activeChatId,
      senderId: currentUser.uid,
      receiverId: activeChatRecipientId,
      text: messageInput.trim(),
      timestamp: timeString,
      type: 'text',
      isRead: false,
    };

    setMessages(prev => {
      const updated = [...prev, newMsg];
      AuthStorageService.saveMessages(updated);
      return updated;
    });
    setMessageInput('');
  };

  const handleFileChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file || !activeChatRecipientId || !currentUser) return;

    const reader = new FileReader();
    reader.onload = () => {
      const base64Data = reader.result as string;
      const activeChatId = getChatId(currentUser.uid, activeChatRecipientId);
      const now = new Date();
      const timeString = now.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });

      const newMsg: MessageItem = {
        messageId: `msg_img_${Date.now()}`,
        chatId: activeChatId,
        senderId: currentUser.uid,
        receiverId: activeChatRecipientId,
        text: messageInput.trim() ? `${base64Data}||${messageInput.trim()}` : base64Data,
        timestamp: timeString,
        type: 'image',
        isRead: false,
      };

      setMessages(prev => {
        const updated = [...prev, newMsg];
        AuthStorageService.saveMessages(updated);
        return updated;
      });
      setMessageInput('');
      if (fileInputRef.current) fileInputRef.current.value = '';
    };
    reader.readAsDataURL(file);
  };

  // Follow Action Handler
  const handleFollowAction = (targetUid: string) => {
    if (!currentUser) return;
    const status = AuthStorageService.getFollowStatus(currentUser.uid, targetUid);

    if (status === 'none') {
      AuthStorageService.sendFollowRequest(currentUser.uid, targetUid);
    } else if (status === 'requested') {
      AuthStorageService.cancelFollowRequest(currentUser.uid, targetUid);
    } else if (status === 'following') {
      AuthStorageService.unfollow(currentUser.uid, targetUid);
    }
    reloadData();
  };

  const handleAcceptRequest = (requesterUid: string) => {
    if (!currentUser) return;
    AuthStorageService.acceptFollowRequest(currentUser.uid, requesterUid);
    reloadData();
  };

  const handleRejectRequest = (requesterUid: string) => {
    if (!currentUser) return;
    AuthStorageService.rejectFollowRequest(currentUser.uid, requesterUid);
    reloadData();
  };

  // Save Profile Details
  const handleSaveProfile = () => {
    if (!currentUser) return;
    setProfileEditError(null);
    try {
      const updated = AuthStorageService.updateProfile(currentUser.uid, {
        displayName: editName,
        newUsername: editUsername,
        bio: editBio,
      });
      setCurrentUser(updated);
      setIsEditingProfile(false);
      setProfileEditError(null);
      reloadData();
    } catch (err: any) {
      setProfileEditError(err.message || 'Failed to update profile.');
    }
  };

  // Toggle Online Status
  const handleToggleOnline = () => {
    if (!currentUser) return;
    const updatedUser = {
      ...currentUser,
      isOnline: !currentUser.isOnline,
      lastSeen: new Date().toISOString(),
    };
    setCurrentUser(updatedUser);
    const allUsers = { ...users, [currentUser.uid]: updatedUser };
    setUsers(allUsers);
    AuthStorageService.saveUsers(allUsers);
  };

  // Chat conversation list
  const currentChatId = activeChatRecipientId && currentUser ? getChatId(currentUser.uid, activeChatRecipientId) : '';
  const currentChatMessages = messages.filter(m => m.chatId === currentChatId);

  const chatPartners = currentUser
    ? Object.keys(users).filter(uid => uid !== currentUser.uid)
    : [];

  const chatList = currentUser
    ? chatPartners.map(partnerUid => {
        const partner = users[partnerUid];
        const chatId = getChatId(currentUser.uid, partnerUid);
        const partnerMessages = messages.filter(m => m.chatId === chatId);
        const lastMsg = partnerMessages[partnerMessages.length - 1];
        const unreadCount = partnerMessages.filter(m => m.receiverId === currentUser.uid && !m.isRead).length;

        return { partner, chatId, lastMsg, unreadCount };
      }).filter(c => c.lastMsg || searchQuery)
      .filter(c => {
        if (!searchQuery.trim()) return true;
        const q = searchQuery.toLowerCase();
        return (
          c.partner.displayName.toLowerCase().includes(q) ||
          c.partner.username.toLowerCase().includes(q) ||
          (c.lastMsg?.text || '').toLowerCase().includes(q)
        );
      })
    : [];

  // Follow stats for active profile
  const pendingRequests = currentUser ? AuthStorageService.getPendingRequestsForUser(currentUser.uid) : [];
  const followerUids = currentUser ? AuthStorageService.getFollowerUids(currentUser.uid) : [];
  const followingUids = currentUser ? AuthStorageService.getFollowingUids(currentUser.uid) : [];

  return (
    <div className="flex flex-col items-center justify-center p-2">
      {/* Top Simulator Control Bar */}
      <div className="w-full max-w-xl mb-3 bg-slate-900/90 backdrop-blur-xl border border-white/10 rounded-2xl p-3 flex flex-wrap items-center justify-between gap-3 text-sm">
        <div className="flex items-center gap-2">
          <span className="text-xs font-semibold uppercase tracking-wider text-slate-400">Account:</span>
          {currentUser ? (
            <div className="flex items-center gap-2 bg-indigo-500/15 border border-indigo-500/30 px-2.5 py-1 rounded-xl text-xs text-white">
              <span className="w-2 h-2 rounded-full bg-emerald-400 animate-pulse" />
              <span className="font-bold">@{currentUser.username}</span>
              <span className="text-slate-400">({currentUser.displayName})</span>
            </div>
          ) : (
            <div className="flex items-center gap-1.5 bg-rose-500/10 border border-rose-500/20 px-2.5 py-1 rounded-xl text-xs text-rose-300">
              <span className="w-1.5 h-1.5 rounded-full bg-rose-400" />
              <span>Unauthenticated</span>
            </div>
          )}
        </div>

        <div className="flex items-center gap-2">
          {currentUser && Object.keys(users).length > 1 && (
            <select
              value={currentUser.uid}
              onChange={e => {
                AuthStorageService.switchUser(e.target.value);
                reloadData();
              }}
              className="bg-slate-800 text-slate-200 border border-white/10 rounded-lg px-2 py-1 text-xs focus:outline-none focus:border-indigo-500 cursor-pointer"
              title="Quick-switch user to test multi-user messaging and live interaction"
            >
              {Object.values(users).map(u => (
                <option key={u.uid} value={u.uid}>
                  Switch: @{u.username}
                </option>
              ))}
            </select>
          )}

          {currentUser && (
            <button
              onClick={handleSignOut}
              className="flex items-center gap-1 px-2.5 py-1 rounded-lg bg-rose-500/10 hover:bg-rose-500/20 border border-rose-500/30 text-rose-300 text-xs transition-colors"
              title="Sign Out"
            >
              <LogOut size={13} />
              <span>Logout</span>
            </button>
          )}

          <button
            onClick={() => setThemeMode(themeMode === 'dark' ? 'light' : 'dark')}
            className="flex items-center gap-1 px-2 py-1 rounded-lg bg-slate-800 border border-white/10 text-slate-300 hover:text-white text-xs"
            title="Toggle theme (Dark / Light)"
          >
            {themeMode === 'dark' ? <Moon size={13} className="text-indigo-400" /> : <Sun size={13} className="text-amber-400" />}
            <span className="capitalize">{themeMode}</span>
          </button>

          <button
            onClick={() => setDeviceFrame(!deviceFrame)}
            className="p-1.5 rounded-lg bg-slate-800 text-slate-300 hover:text-white border border-white/10"
            title={deviceFrame ? 'Expand viewport' : 'Phone frame'}
          >
            {deviceFrame ? <Maximize2 size={15} /> : <Minimize2 size={15} />}
          </button>
        </div>
      </div>

      {/* Main Glass Frame */}
      <div
        className={`relative transition-all duration-300 overflow-hidden ${
          isLight ? 'bg-slate-100 text-slate-900' : 'bg-[#090C14] text-slate-100'
        } ${
          deviceFrame
            ? 'w-full max-w-[410px] h-[780px] rounded-[48px] border-[8px] border-slate-800 shadow-2xl shadow-indigo-950/40'
            : 'w-full max-w-2xl h-[780px] rounded-3xl border border-white/10 shadow-2xl'
        }`}
      >
        {/* Dynamic Ambient Blur Glows */}
        <div className={`absolute -top-20 -left-20 w-64 h-64 rounded-full blur-3xl pointer-events-none ${isLight ? 'bg-indigo-300/30' : 'bg-indigo-600/25'}`} />
        <div className={`absolute top-1/3 -right-24 w-72 h-72 rounded-full blur-3xl pointer-events-none ${isLight ? 'bg-cyan-300/25' : 'bg-cyan-500/20'}`} />

        {/* Phone Notch */}
        {deviceFrame && (
          <div className="relative z-30 pt-3 pb-1 flex justify-center">
            <div className={`w-24 h-4 rounded-full border flex items-center justify-center ${isLight ? 'bg-slate-300 border-slate-400/30' : 'bg-slate-900 border-white/10'}`}>
              <div className="w-10 h-1 bg-slate-600 rounded-full" />
            </div>
          </div>
        )}

        {/* View Router */}
        <div className="relative z-20 flex flex-col h-full overflow-hidden">
          {authStatus === 'splash' ? (
            <SplashScreen onFinish={handleSplashFinish} />
          ) : authStatus === 'choose_username' && pendingGoogleProfile ? (
            <ChooseUsernameScreen
              googleProfile={pendingGoogleProfile}
              onSuccess={user => {
                setCurrentUser(user);
                setPendingGoogleProfile(null);
                setAuthStatus('authenticated');
                reloadData();
              }}
              onCancel={() => {
                setPendingGoogleProfile(null);
                setAuthStatus('login');
              }}
            />
          ) : authStatus === 'signup' ? (
            <SignUpScreen
              onSuccess={user => {
                setCurrentUser(user);
                setAuthStatus('authenticated');
                reloadData();
              }}
              onNavigateToLogin={() => setAuthStatus('login')}
              onGoogleSignInNeedsUsername={profile => {
                setPendingGoogleProfile(profile);
                setAuthStatus('choose_username');
              }}
            />
          ) : authStatus === 'login' || !currentUser ? (
            <LoginScreen
              onSuccess={user => {
                setCurrentUser(user);
                setAuthStatus('authenticated');
                reloadData();
              }}
              onNavigateToSignUp={() => setAuthStatus('signup')}
              onGoogleSignInNeedsUsername={profile => {
                setPendingGoogleProfile(profile);
                setAuthStatus('choose_username');
              }}
            />
          ) : activeChatRecipientId ? (
            /* ================= 1-TO-1 CHAT VIEW ================= */
            <div className="flex flex-col h-full">
              {/* Chat Header */}
              {(() => {
                const recipient = users[activeChatRecipientId];
                return (
                  <div className={`p-3.5 backdrop-blur-xl border-b flex items-center justify-between ${
                    isLight ? 'bg-white/80 border-slate-200' : 'bg-slate-900/80 border-white/10'
                  }`}>
                    <div className="flex items-center gap-3">
                      <button
                        onClick={() => setActiveChatRecipientId(null)}
                        className={`p-1.5 rounded-xl border transition-colors ${
                          isLight ? 'bg-slate-200/80 border-slate-300 text-slate-700' : 'bg-white/5 border-white/10 text-slate-300 hover:text-white'
                        }`}
                      >
                        <ArrowLeft size={18} />
                      </button>
                      <div
                        onClick={() => setSelectedUserModal(recipient)}
                        className="flex items-center gap-2.5 cursor-pointer"
                      >
                        <div className="relative">
                          <div className="w-10 h-10 rounded-full bg-gradient-to-tr from-indigo-600 to-cyan-400 flex items-center justify-center font-bold text-sm text-white">
                            {recipient?.displayName?.slice(0, 2).toUpperCase() || 'U'}
                          </div>
                          {recipient?.isOnline && (
                            <span className="absolute bottom-0 right-0 w-3 h-3 bg-emerald-500 border-2 border-slate-900 rounded-full" />
                          )}
                        </div>
                        <div>
                          <h3 className="font-bold text-sm leading-tight">{recipient?.displayName}</h3>
                          <p className="text-xs text-cyan-400">@{recipient?.username}</p>
                        </div>
                      </div>
                    </div>

                    <button
                      onClick={() => setSelectedUserModal(recipient)}
                      className={`p-1.5 rounded-xl border ${
                        isLight ? 'bg-slate-100 border-slate-300 text-slate-600' : 'bg-white/5 border-white/10 text-slate-400 hover:text-white'
                      }`}
                      title="Profile Info"
                    >
                      <Info size={17} />
                    </button>
                  </div>
                );
              })()}

              {/* Chat Messages */}
              <div className="flex-1 overflow-y-auto p-4 space-y-3">
                {currentChatMessages.length === 0 ? (
                  <div className="h-full flex flex-col items-center justify-center text-center p-6">
                    <div className="w-14 h-14 rounded-2xl bg-indigo-500/15 border border-indigo-500/30 flex items-center justify-center text-indigo-400 mb-3">
                      <MessageSquare size={26} />
                    </div>
                    <p className="text-sm font-semibold">No messages yet</p>
                    <p className="text-xs text-slate-400 mt-1 max-w-[220px]">
                      Send a message or attach a photo to begin chatting.
                    </p>
                  </div>
                ) : (
                  currentChatMessages.map(msg => {
                    const isMe = msg.senderId === currentUser.uid;
                    const isImage = msg.type === 'image';

                    let imageUrl = '';
                    let caption = '';
                    if (isImage) {
                      if (msg.text.includes('||')) {
                        const parts = msg.text.split('||');
                        imageUrl = parts[0];
                        caption = parts[1];
                      } else {
                        imageUrl = msg.text;
                      }
                    }

                    return (
                      <div key={msg.messageId} className={`flex ${isMe ? 'justify-end' : 'justify-start'}`}>
                        <div
                          className={`max-w-[80%] rounded-2xl text-sm backdrop-blur-md transition-all ${
                            isImage ? 'p-1.5' : 'px-3.5 py-2.5'
                          } ${
                            isMe
                              ? 'bg-gradient-to-br from-indigo-600 to-indigo-700 text-white rounded-br-xs border border-white/20 shadow-md shadow-indigo-600/20'
                              : isLight
                              ? 'bg-white text-slate-800 rounded-bl-xs border border-slate-200 shadow-sm'
                              : 'bg-white/10 text-slate-100 rounded-bl-xs border border-white/10'
                          }`}
                        >
                          {isImage ? (
                            <div className="space-y-1.5">
                              <img
                                src={imageUrl}
                                alt="Attachment"
                                onClick={() => setExpandedImage(imageUrl)}
                                className="w-full max-h-52 object-cover rounded-xl cursor-pointer hover:opacity-95 transition-opacity"
                              />
                              {caption && (
                                <p className="px-2 py-0.5 text-xs leading-relaxed">{caption}</p>
                              )}
                            </div>
                          ) : (
                            <p className="leading-relaxed">{msg.text}</p>
                          )}

                          <div
                            className={`flex items-center gap-1 mt-1 text-[10px] px-1 ${
                              isMe ? 'justify-end text-indigo-200' : 'text-slate-400'
                            }`}
                          >
                            <span>{msg.timestamp}</span>
                            {isMe && (
                              <span>
                                {msg.isRead ? (
                                  <CheckCheck size={12} className="text-cyan-300 inline" />
                                ) : (
                                  <Check size={12} className="inline text-white/70" />
                                )}
                              </span>
                            )}
                          </div>
                        </div>
                      </div>
                    );
                  })
                )}
                <div ref={messagesEndRef} />
              </div>

              {/* Chat Input */}
              <form
                onSubmit={handleSendMessage}
                className={`p-3 backdrop-blur-xl border-t flex items-center gap-2 ${
                  isLight ? 'bg-white/90 border-slate-200' : 'bg-slate-900/90 border-white/10'
                }`}
              >
                <input
                  type="file"
                  ref={fileInputRef}
                  accept="image/*"
                  onChange={handleFileChange}
                  className="hidden"
                />

                <button
                  type="button"
                  onClick={() => fileInputRef.current?.click()}
                  className={`p-2.5 rounded-2xl border transition-colors ${
                    isLight
                      ? 'bg-slate-100 border-slate-300 text-indigo-600 hover:bg-slate-200'
                      : 'bg-white/5 border-white/10 text-cyan-400 hover:bg-white/10'
                  }`}
                  title="Attach Photo"
                >
                  <Paperclip size={18} />
                </button>

                <input
                  type="text"
                  value={messageInput}
                  onChange={e => setMessageInput(e.target.value)}
                  placeholder="Type a message or attach photo..."
                  className={`flex-1 border rounded-2xl px-4 py-2.5 text-sm focus:outline-none focus:border-indigo-500 ${
                    isLight
                      ? 'bg-slate-100 border-slate-300 text-slate-800 placeholder-slate-400'
                      : 'bg-white/5 border-white/10 text-white placeholder-slate-500'
                  }`}
                />

                <button
                  type="submit"
                  disabled={!messageInput.trim()}
                  className="w-10 h-10 rounded-2xl bg-gradient-to-r from-indigo-600 to-cyan-500 text-white flex items-center justify-center disabled:opacity-40 hover:shadow-lg hover:shadow-indigo-500/25 transition-all"
                >
                  <Send size={17} />
                </button>
              </form>
            </div>
          ) : (
            /* ================= MAIN BOTTOM TABS VIEW ================= */
            <div className="flex flex-col h-full">
              <div className="flex-1 overflow-y-auto p-4">
                {/* TAB 1: CHATS / CONVERSATIONS */}
                {activeTab === 'chats' && (
                  <div>
                    <div className="flex items-center justify-between mb-3">
                      <div>
                        <h1 className="text-2xl font-black tracking-tight">Messages</h1>
                        <p className="text-xs text-slate-400">Direct Messages</p>
                      </div>
                      <button
                        onClick={() => setActiveTab('search')}
                        className={`p-2 rounded-2xl border transition-colors ${
                          isLight ? 'bg-white border-slate-300 text-indigo-600' : 'bg-white/5 border-white/10 text-cyan-400 hover:bg-white/10'
                        }`}
                        title="Search Users"
                      >
                        <UserPlus size={20} />
                      </button>
                    </div>

                    {/* Search Field */}
                    <div className="relative mb-4">
                      <Search size={16} className="absolute left-3.5 top-1/2 -translate-y-1/2 text-slate-400" />
                      <input
                        type="text"
                        value={searchQuery}
                        onChange={e => setSearchQuery(e.target.value)}
                        placeholder="Search chats..."
                        className={`w-full pl-9 pr-3 py-2 rounded-xl border text-xs focus:outline-none focus:border-indigo-500 ${
                          isLight ? 'bg-white border-slate-300 text-slate-800' : 'bg-white/5 border-white/10 text-white placeholder-slate-500'
                        }`}
                      />
                    </div>

                    {/* Conversations List */}
                    <div className="space-y-2.5">
                      {chatList.length === 0 ? (
                        <div className={`p-8 text-center rounded-3xl border my-6 ${
                          isLight ? 'bg-white border-slate-200' : 'bg-white/5 border-white/10'
                        }`}>
                          <MessageSquare size={36} className="mx-auto text-slate-400 mb-2" />
                          <p className="font-bold text-sm">No conversations yet</p>
                          <p className="text-xs text-slate-400 mt-1 mb-4">
                            Find users by @username to follow and message them.
                          </p>
                          <button
                            onClick={() => setActiveTab('search')}
                            className="px-4 py-2 rounded-xl bg-gradient-to-r from-indigo-600 to-cyan-500 text-xs font-bold text-white shadow-lg shadow-indigo-600/30"
                          >
                            Discover Users
                          </button>
                        </div>
                      ) : (
                        chatList.map(({ partner, lastMsg, unreadCount }) => (
                          <div
                            key={partner.uid}
                            onClick={() => setActiveChatRecipientId(partner.uid)}
                            className={`p-3 rounded-2xl backdrop-blur-md border transition-all cursor-pointer flex items-center justify-between ${
                              unreadCount > 0
                                ? 'bg-indigo-950/40 border-indigo-500/40 shadow-lg shadow-indigo-950/40'
                                : isLight
                                ? 'bg-white hover:bg-slate-50 border-slate-200 shadow-sm'
                                : 'bg-white/5 hover:bg-white/10 border-white/10'
                            }`}
                          >
                            <div className="flex items-center gap-3">
                              <div className="relative">
                                <div className="w-12 h-12 rounded-full bg-gradient-to-tr from-indigo-600 to-cyan-400 flex items-center justify-center font-bold text-white">
                                  {partner.displayName.slice(0, 2).toUpperCase()}
                                </div>
                                {partner.isOnline && (
                                  <span className="absolute bottom-0 right-0 w-3 h-3 bg-emerald-500 border-2 border-slate-900 rounded-full" />
                                )}
                              </div>
                              <div>
                                <h3 className="font-bold text-sm leading-tight">{partner.displayName}</h3>
                                <p className="text-xs text-slate-400 mt-0.5 max-w-[160px] truncate">
                                  {lastMsg
                                    ? (lastMsg.type === 'image'
                                        ? '📷 Photo'
                                        : (lastMsg.senderId === currentUser.uid ? `You: ${lastMsg.text}` : lastMsg.text))
                                    : 'Start conversation'}
                                </p>
                              </div>
                            </div>

                            <div className="flex flex-col items-end gap-1.5">
                              {lastMsg && (
                                <span className={`text-[10px] ${unreadCount > 0 ? 'text-indigo-400 font-semibold' : 'text-slate-400'}`}>
                                  {lastMsg.timestamp}
                                </span>
                              )}
                              {unreadCount > 0 && (
                                <span className="px-2 py-0.5 rounded-full bg-gradient-to-r from-indigo-500 to-cyan-500 text-white text-[10px] font-extrabold shadow-sm shadow-indigo-500/50">
                                  {unreadCount}
                                </span>
                              )}
                            </div>
                          </div>
                        ))
                      )}
                    </div>
                  </div>
                )}

                {/* TAB 2: INSTAGRAM-STYLE USERNAME SEARCH */}
                {activeTab === 'search' && (
                  <div>
                    <div className="mb-4">
                      <h1 className="text-2xl font-black tracking-tight">Explore & Connect</h1>
                      <p className="text-xs text-slate-400">Search users by @username to connect</p>
                    </div>

                    {/* Search Field */}
                    <div className="relative mb-4">
                      <div className="absolute left-3.5 top-1/2 -translate-y-1/2 text-cyan-400 font-bold text-xs select-none">
                        @
                      </div>
                      <input
                        type="text"
                        value={userSearchText}
                        onChange={e => setUserSearchText(e.target.value.replace(/^@/, ''))}
                        placeholder="Search username (e.g. ashish)..."
                        className={`w-full pl-8 pr-4 py-2.5 rounded-2xl border text-sm focus:outline-none focus:border-indigo-500 ${
                          isLight ? 'bg-white border-slate-300 text-slate-800' : 'bg-white/5 border-white/10 text-white placeholder-slate-500'
                        }`}
                      />
                    </div>

                    {/* Results List */}
                    <div className="space-y-2.5">
                      {Object.values(users)
                        .filter(u => u.uid !== currentUser.uid)
                        .filter(u => {
                          if (!userSearchText.trim()) return true;
                          const q = userSearchText.toLowerCase();
                          return u.username.toLowerCase().includes(q) || u.displayName.toLowerCase().includes(q);
                        })
                        .map(targetUser => {
                          const followStatus = AuthStorageService.getFollowStatus(currentUser.uid, targetUser.uid);

                          return (
                            <div
                              key={targetUser.uid}
                              className={`p-3.5 rounded-2xl backdrop-blur-md border flex items-center justify-between ${
                                isLight ? 'bg-white border-slate-200 shadow-sm' : 'bg-white/5 border-white/10'
                              }`}
                            >
                              <div
                                onClick={() => setSelectedUserModal(targetUser)}
                                className="flex items-center gap-3 cursor-pointer flex-1"
                              >
                                <div className="relative">
                                  <div className="w-11 h-11 rounded-full bg-gradient-to-tr from-indigo-500 to-cyan-400 flex items-center justify-center font-bold text-white">
                                    {targetUser.displayName.slice(0, 2).toUpperCase()}
                                  </div>
                                  {targetUser.isOnline && (
                                    <span className="absolute bottom-0 right-0 w-2.5 h-2.5 bg-emerald-500 border-2 border-slate-900 rounded-full" />
                                  )}
                                </div>
                                <div>
                                  <h4 className="font-bold text-sm leading-tight">{targetUser.displayName}</h4>
                                  <p className="text-xs text-indigo-400">@{targetUser.username}</p>
                                </div>
                              </div>

                              <div className="flex items-center gap-2">
                                <button
                                  onClick={() => handleFollowAction(targetUser.uid)}
                                  className={`px-3 py-1.5 rounded-xl text-xs font-bold transition-all ${
                                    followStatus === 'following'
                                      ? 'bg-white/10 text-slate-300 hover:bg-rose-500/20 hover:text-rose-300'
                                      : followStatus === 'requested'
                                      ? 'bg-cyan-500/15 border border-cyan-500/30 text-cyan-400'
                                      : 'bg-indigo-600 hover:bg-indigo-500 text-white shadow-md shadow-indigo-600/30'
                                  }`}
                                >
                                  {followStatus === 'following'
                                    ? 'Following'
                                    : followStatus === 'requested'
                                    ? 'Requested'
                                    : 'Follow'}
                                </button>
                                <button
                                  onClick={() => setActiveChatRecipientId(targetUser.uid)}
                                  className={`p-1.5 rounded-xl border ${
                                    isLight ? 'bg-slate-100 border-slate-300 text-indigo-600' : 'bg-white/5 border-white/10 text-cyan-400 hover:bg-white/10'
                                  }`}
                                  title="Send Message"
                                >
                                  <MessageSquare size={16} />
                                </button>
                              </div>
                            </div>
                          );
                        })}
                    </div>
                  </div>
                )}

                {/* TAB 3: USER PROFILE & FOLLOW MANAGEMENT */}
                {activeTab === 'profile' && (
                  <div>
                    <div className="flex items-center justify-between mb-4">
                      <h1 className="text-2xl font-black tracking-tight">Profile</h1>
                      <div className="flex items-center gap-1.5">
                        <button
                          onClick={() => setIsAppearanceOpen(true)}
                          className={`p-2 rounded-xl border ${
                            isLight ? 'bg-white border-slate-300 text-slate-700' : 'bg-white/5 border-white/10 text-cyan-400 hover:text-white'
                          }`}
                          title="Theme Settings"
                        >
                          <Palette size={18} />
                        </button>
                        <button
                          onClick={() => {
                            setEditName(currentUser.displayName);
                            setEditUsername(currentUser.username);
                            setEditBio(currentUser.bio || '');
                            setProfileEditError(null);
                            setIsEditingProfile(true);
                          }}
                          className={`p-2 rounded-xl border ${
                            isLight ? 'bg-white border-slate-300 text-slate-700' : 'bg-white/5 border-white/10 text-indigo-400 hover:text-white'
                          }`}
                          title="Edit Profile"
                        >
                          <Edit3 size={18} />
                        </button>
                      </div>
                    </div>

                    {/* Profile Header & Stats */}
                    <div className={`p-5 rounded-3xl backdrop-blur-xl border ${
                      isLight ? 'bg-white border-slate-200 shadow-sm' : 'bg-white/5 border-white/10'
                    }`}>
                      <div className="flex items-center gap-4">
                        <div className="relative">
                          <div className="w-16 h-16 rounded-full bg-gradient-to-tr from-indigo-600 via-indigo-500 to-cyan-400 flex items-center justify-center font-extrabold text-xl text-white shadow-xl shadow-indigo-600/30">
                            {currentUser.displayName.slice(0, 2).toUpperCase()}
                          </div>
                          <span
                            onClick={handleToggleOnline}
                            className={`absolute bottom-0 right-0 w-4 h-4 rounded-full border-2 border-slate-900 cursor-pointer ${
                              currentUser.isOnline ? 'bg-emerald-500' : 'bg-slate-500'
                            }`}
                            title="Toggle online presence"
                          />
                        </div>

                        {/* Followers / Following Counter Bars */}
                        <div className="flex-1 flex justify-around text-center">
                          <div
                            onClick={() => {
                              setSocialModalTargetUid(currentUser.uid);
                              setActiveSocialModal('followers');
                            }}
                            className="cursor-pointer hover:opacity-80 transition-opacity"
                          >
                            <span className="block font-black text-lg text-white">{followerUids.length}</span>
                            <span className="text-[11px] text-slate-400">Followers</span>
                          </div>
                          <div
                            onClick={() => {
                              setSocialModalTargetUid(currentUser.uid);
                              setActiveSocialModal('following');
                            }}
                            className="cursor-pointer hover:opacity-80 transition-opacity"
                          >
                            <span className="block font-black text-lg text-white">{followingUids.length}</span>
                            <span className="text-[11px] text-slate-400">Following</span>
                          </div>
                        </div>
                      </div>

                      <div className="mt-3">
                        <h2 className="font-extrabold text-base">{currentUser.displayName}</h2>
                        <span className="text-xs font-semibold text-cyan-400">
                          @{currentUser.username}
                        </span>
                        <p className="text-xs text-slate-300 mt-1 italic">"{currentUser.bio}"</p>
                      </div>
                    </div>

                    {/* Follow Requests Tile (Receiver Side) */}
                    {pendingRequests.length > 0 && (
                      <div
                        onClick={() => {
                          setSocialModalTargetUid(currentUser.uid);
                          setActiveSocialModal('requests');
                        }}
                        className="mt-3 p-3.5 rounded-2xl bg-indigo-950/40 border border-indigo-500/40 backdrop-blur-md flex items-center justify-between cursor-pointer hover:bg-indigo-950/60 transition-all"
                      >
                        <div className="flex items-center gap-3">
                          <div className="w-8 h-8 rounded-full bg-cyan-500/20 text-cyan-400 flex items-center justify-center">
                            <Bell size={16} />
                          </div>
                          <div>
                            <h4 className="font-bold text-xs text-white">Follow Requests</h4>
                            <p className="text-[11px] text-slate-400">
                              {pendingRequests.length} user{pendingRequests.length > 1 ? 's' : ''} requested to follow you
                            </p>
                          </div>
                        </div>
                        <span className="px-2 py-0.5 rounded-full bg-gradient-to-r from-indigo-500 to-cyan-500 text-white font-extrabold text-[10px]">
                          {pendingRequests.length}
                        </span>
                      </div>
                    )}

                    {/* Account Settings List */}
                    <div className={`mt-4 p-3.5 rounded-3xl backdrop-blur-xl border space-y-2.5 text-xs ${
                      isLight ? 'bg-white border-slate-200' : 'bg-white/5 border-white/10'
                    }`}>
                      <div className="flex justify-between items-center py-1 border-b border-white/5">
                        <span className="text-slate-400">Email Address</span>
                        <span className="font-medium">{currentUser.email}</span>
                      </div>
                      <div className="flex justify-between items-center py-1 border-b border-white/5">
                        <span className="text-slate-400">User UID</span>
                        <span className="font-mono text-[10px] text-slate-400">{currentUser.uid}</span>
                      </div>
                      <div className="flex justify-between items-center py-1">
                        <span className="text-slate-400">Presence</span>
                        <span className={`font-semibold ${currentUser.isOnline ? 'text-emerald-400' : 'text-slate-400'}`}>
                          {currentUser.isOnline ? 'Online (Real-time)' : 'Offline'}
                        </span>
                      </div>
                    </div>

                    <div className="mt-4">
                      <button
                        onClick={handleSignOut}
                        className="w-full py-2.5 rounded-2xl bg-rose-500/10 hover:bg-rose-500/20 border border-rose-500/30 text-rose-400 font-bold text-xs flex items-center justify-center gap-2 transition-all"
                      >
                        <LogOut size={15} />
                        <span>Sign Out of Shizz</span>
                      </button>
                    </div>
                  </div>
                )}
              </div>

              {/* Bottom Nav */}
              <div className="p-3">
                <div className={`backdrop-blur-2xl border rounded-full p-1.5 flex items-center justify-around shadow-2xl ${
                  isLight ? 'bg-white/90 border-slate-300' : 'bg-slate-900/90 border-white/10'
                }`}>
                  <button
                    onClick={() => setActiveTab('chats')}
                    className={`flex items-center gap-1.5 px-4 py-2 rounded-full text-xs font-semibold transition-all ${
                      activeTab === 'chats'
                        ? 'bg-gradient-to-r from-indigo-600 to-indigo-700 text-white shadow-md shadow-indigo-600/30'
                        : 'text-slate-400 hover:text-white'
                    }`}
                  >
                    <MessageSquare size={16} />
                    <span>Chats</span>
                  </button>
                  <button
                    onClick={() => setActiveTab('search')}
                    className={`flex items-center gap-1.5 px-4 py-2 rounded-full text-xs font-semibold transition-all ${
                      activeTab === 'search'
                        ? 'bg-gradient-to-r from-indigo-600 to-indigo-700 text-white shadow-md shadow-indigo-600/30'
                        : 'text-slate-400 hover:text-white'
                    }`}
                  >
                    <Search size={16} />
                    <span>Search</span>
                  </button>
                  <button
                    onClick={() => setActiveTab('profile')}
                    className={`flex items-center gap-1.5 px-4 py-2 rounded-full text-xs font-semibold transition-all ${
                      activeTab === 'profile'
                        ? 'bg-gradient-to-r from-indigo-600 to-indigo-700 text-white shadow-md shadow-indigo-600/30'
                        : 'text-slate-400 hover:text-white'
                    }`}
                  >
                    <UserIcon size={16} />
                    <span>Profile</span>
                  </button>
                </div>
              </div>
            </div>
          )}
        </div>
      </div>

      {/* Edit Profile Modal */}
      {isEditingProfile && currentUser && (
        <div className="fixed inset-0 z-50 bg-black/60 backdrop-blur-sm flex items-center justify-center p-4">
          <div className="w-full max-w-sm bg-slate-900 border border-white/10 rounded-3xl p-5 shadow-2xl text-slate-100">
            <h3 className="text-base font-bold text-white mb-3">Edit Profile</h3>

            {profileEditError && (
              <div className="mb-3 p-2.5 rounded-xl bg-rose-500/15 border border-rose-500/30 text-rose-300 text-xs flex items-center gap-2">
                <AlertCircle size={15} className="shrink-0 text-rose-400" />
                <span>{profileEditError}</span>
              </div>
            )}

            <div className="space-y-3 text-xs">
              <div>
                <label className="text-slate-400 block mb-1">Display Name</label>
                <input
                  type="text"
                  value={editName}
                  onChange={e => setEditName(e.target.value)}
                  className="w-full bg-white/5 border border-white/10 rounded-xl px-3 py-2 text-white focus:outline-none focus:border-indigo-500"
                />
              </div>
              <div>
                <label className="text-slate-400 block mb-1">Username (@unique)</label>
                <input
                  type="text"
                  value={editUsername}
                  onChange={e => setEditUsername(e.target.value)}
                  className="w-full bg-white/5 border border-white/10 rounded-xl px-3 py-2 text-white focus:outline-none focus:border-indigo-500"
                />
              </div>
              <div>
                <label className="text-slate-400 block mb-1">Bio</label>
                <textarea
                  value={editBio}
                  onChange={e => setEditBio(e.target.value)}
                  rows={3}
                  className="w-full bg-white/5 border border-white/10 rounded-xl px-3 py-2 text-white focus:outline-none focus:border-indigo-500"
                />
              </div>
            </div>
            <div className="flex justify-end gap-2 mt-4">
              <button
                onClick={() => setIsEditingProfile(false)}
                className="px-3 py-1.5 rounded-xl text-xs text-slate-400 hover:text-white"
              >
                Cancel
              </button>
              <button
                onClick={handleSaveProfile}
                className="px-4 py-1.5 rounded-xl text-xs font-bold bg-indigo-600 text-white hover:bg-indigo-500 shadow-md shadow-indigo-600/30"
              >
                Save Changes
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Social Modal: Followers / Following / Requests */}
      {activeSocialModal && socialModalTargetUid && currentUser && (
        <div className="fixed inset-0 z-50 bg-black/70 backdrop-blur-sm flex items-center justify-center p-4">
          <div className="w-full max-w-sm bg-slate-900 border border-white/10 rounded-3xl p-5 shadow-2xl text-slate-100 flex flex-col max-h-[80vh]">
            <div className="flex items-center justify-between pb-3 border-b border-white/10 mb-3">
              <h3 className="text-sm font-bold text-white capitalize">
                {activeSocialModal === 'requests' ? 'Follow Requests' : activeSocialModal}
              </h3>
              <button
                onClick={() => setActiveSocialModal(null)}
                className="p-1 rounded-lg text-slate-400 hover:text-white"
              >
                <X size={16} />
              </button>
            </div>

            <div className="flex-1 overflow-y-auto space-y-2 text-xs">
              {activeSocialModal === 'requests' ? (
                pendingRequests.length === 0 ? (
                  <p className="text-center text-slate-500 py-6">No pending follow requests</p>
                ) : (
                  pendingRequests.map(req => {
                    const reqUser = users[req.requesterUid];
                    if (!reqUser) return null;
                    return (
                      <div
                        key={req.requesterUid}
                        className="p-3 rounded-2xl bg-white/5 border border-white/10 flex items-center justify-between"
                      >
                        <div
                          onClick={() => {
                            setActiveSocialModal(null);
                            setSelectedUserModal(reqUser);
                          }}
                          className="flex items-center gap-2.5 cursor-pointer"
                        >
                          <div className="w-9 h-9 rounded-full bg-gradient-to-tr from-indigo-500 to-cyan-400 flex items-center justify-center font-bold text-white text-xs">
                            {reqUser.displayName.slice(0, 2).toUpperCase()}
                          </div>
                          <div>
                            <h4 className="font-bold text-xs text-white leading-tight">{reqUser.displayName}</h4>
                            <p className="text-[11px] text-cyan-400">@{reqUser.username}</p>
                          </div>
                        </div>

                        <div className="flex items-center gap-1.5">
                          <button
                            onClick={() => handleAcceptRequest(req.requesterUid)}
                            className="px-2.5 py-1 rounded-xl bg-indigo-600 hover:bg-indigo-500 text-white font-bold text-[11px]"
                          >
                            Accept
                          </button>
                          <button
                            onClick={() => handleRejectRequest(req.requesterUid)}
                            className="p-1 rounded-xl bg-white/5 hover:bg-white/10 text-slate-400"
                          >
                            <X size={14} />
                          </button>
                        </div>
                      </div>
                    );
                  })
                )
              ) : activeSocialModal === 'followers' ? (
                (() => {
                  const targetFollowers = AuthStorageService.getFollowerUids(socialModalTargetUid);
                  if (targetFollowers.length === 0) {
                    return <p className="text-center text-slate-500 py-6">No followers yet</p>;
                  }
                  return targetFollowers.map(uid => {
                    const fUser = users[uid];
                    if (!fUser) return null;
                    return (
                      <div
                        key={uid}
                        onClick={() => {
                          setActiveSocialModal(null);
                          setSelectedUserModal(fUser);
                        }}
                        className="p-2.5 rounded-2xl bg-white/5 hover:bg-white/10 border border-white/10 flex items-center gap-3 cursor-pointer"
                      >
                        <div className="w-9 h-9 rounded-full bg-gradient-to-tr from-indigo-500 to-cyan-400 flex items-center justify-center font-bold text-white text-xs">
                          {fUser.displayName.slice(0, 2).toUpperCase()}
                        </div>
                        <div>
                          <h4 className="font-bold text-xs text-white">{fUser.displayName}</h4>
                          <p className="text-[11px] text-cyan-400">@{fUser.username}</p>
                        </div>
                      </div>
                    );
                  });
                })()
              ) : (
                (() => {
                  const targetFollowing = AuthStorageService.getFollowingUids(socialModalTargetUid);
                  if (targetFollowing.length === 0) {
                    return <p className="text-center text-slate-500 py-6">Not following anyone yet</p>;
                  }
                  return targetFollowing.map(uid => {
                    const fUser = users[uid];
                    if (!fUser) return null;
                    return (
                      <div
                        key={uid}
                        onClick={() => {
                          setActiveSocialModal(null);
                          setSelectedUserModal(fUser);
                        }}
                        className="p-2.5 rounded-2xl bg-white/5 hover:bg-white/10 border border-white/10 flex items-center gap-3 cursor-pointer"
                      >
                        <div className="w-9 h-9 rounded-full bg-gradient-to-tr from-indigo-500 to-cyan-400 flex items-center justify-center font-bold text-white text-xs">
                          {fUser.displayName.slice(0, 2).toUpperCase()}
                        </div>
                        <div>
                          <h4 className="font-bold text-xs text-white">{fUser.displayName}</h4>
                          <p className="text-[11px] text-cyan-400">@{fUser.username}</p>
                        </div>
                      </div>
                    );
                  });
                })()
              )}
            </div>
          </div>
        </div>
      )}

      {/* User Profile Inspection Modal (Instagram-Style) */}
      {selectedUserModal && currentUser && (
        <div className="fixed inset-0 z-50 bg-black/70 backdrop-blur-sm flex items-center justify-center p-4">
          <div className="w-full max-w-sm bg-slate-900 border border-white/10 rounded-3xl p-5 shadow-2xl text-slate-100 text-center">
            <div className="w-16 h-16 rounded-full bg-gradient-to-tr from-indigo-600 to-cyan-400 flex items-center justify-center font-extrabold text-xl text-white mx-auto mb-3">
              {selectedUserModal.displayName.slice(0, 2).toUpperCase()}
            </div>
            <h3 className="text-base font-bold text-white">{selectedUserModal.displayName}</h3>
            <p className="text-xs text-cyan-400 mb-1">@{selectedUserModal.username}</p>
            <p className="text-xs text-slate-300 italic mb-3">"{selectedUserModal.bio}"</p>

            {/* Target User Stats */}
            <div className="flex justify-around py-2 border-y border-white/10 mb-4 text-xs">
              <div
                onClick={() => {
                  setSocialModalTargetUid(selectedUserModal.uid);
                  setActiveSocialModal('followers');
                }}
                className="cursor-pointer hover:opacity-80"
              >
                <span className="font-bold text-white block">
                  {AuthStorageService.getFollowerUids(selectedUserModal.uid).length}
                </span>
                <span className="text-[10px] text-slate-400">Followers</span>
              </div>
              <div
                onClick={() => {
                  setSocialModalTargetUid(selectedUserModal.uid);
                  setActiveSocialModal('following');
                }}
                className="cursor-pointer hover:opacity-80"
              >
                <span className="font-bold text-white block">
                  {AuthStorageService.getFollowingUids(selectedUserModal.uid).length}
                </span>
                <span className="text-[10px] text-slate-400">Following</span>
              </div>
            </div>

            {/* Follow / Message Actions */}
            {selectedUserModal.uid !== currentUser.uid && (
              <div className="flex gap-2">
                {(() => {
                  const status = AuthStorageService.getFollowStatus(currentUser.uid, selectedUserModal.uid);
                  return (
                    <button
                      onClick={() => handleFollowAction(selectedUserModal.uid)}
                      className={`flex-1 py-2 rounded-xl text-xs font-bold transition-all ${
                        status === 'following'
                          ? 'bg-white/10 text-slate-300 hover:bg-rose-500/20 hover:text-rose-300'
                          : status === 'requested'
                          ? 'bg-cyan-500/15 border border-cyan-500/30 text-cyan-400'
                          : 'bg-indigo-600 text-white hover:bg-indigo-500'
                      }`}
                    >
                      {status === 'following' ? 'Following' : status === 'requested' ? 'Requested' : 'Follow'}
                    </button>
                  );
                })()}

                <button
                  onClick={() => {
                    const targetUid = selectedUserModal.uid;
                    setSelectedUserModal(null);
                    setActiveChatRecipientId(targetUid);
                  }}
                  className="flex-1 py-2 rounded-xl text-xs font-bold bg-white/10 hover:bg-white/15 text-white"
                >
                  Message
                </button>
              </div>
            )}

            <button
              onClick={() => setSelectedUserModal(null)}
              className="mt-3 text-xs text-slate-400 hover:text-white"
            >
              Close
            </button>
          </div>
        </div>
      )}

      {/* Expanded Image Viewer Modal */}
      {expandedImage && (
        <div
          onClick={() => setExpandedImage(null)}
          className="fixed inset-0 z-50 bg-black/90 backdrop-blur-md flex items-center justify-center p-4 cursor-pointer"
        >
          <div className="relative max-w-xl max-h-[90vh]">
            <img src={expandedImage} alt="Attachment" className="max-w-full max-h-[85vh] rounded-2xl object-contain shadow-2xl" />
            <button
              onClick={() => setExpandedImage(null)}
              className="absolute top-3 right-3 p-2 rounded-full bg-black/60 text-white hover:bg-black/80"
            >
              <X size={18} />
            </button>
          </div>
        </div>
      )}
    </div>
  );
};
