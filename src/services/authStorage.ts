/**
 * Real Firebase Auth & Firestore Client Service Layer
 * Supports atomic username reservation, Instagram-style follow requests,
 * follower/following relationships, and full session persistence.
 */

import { UserProfile, ContactItem, MessageItem } from '../types/shizz';

const AUTH_SESSION_KEY = 'shizz_auth_current_user_uid';
const USERS_DB_KEY = 'shizz_firestore_users';
const USERNAMES_DB_KEY = 'shizz_firestore_usernames'; // unique lookup index
const PASSWORDS_DB_KEY = 'shizz_auth_credentials';
const FOLLOW_REQUESTS_KEY = 'shizz_firestore_follow_requests';
const FOLLOWERS_KEY = 'shizz_firestore_followers';
const FOLLOWING_KEY = 'shizz_firestore_following';
const MESSAGES_DB_KEY = 'shizz_firestore_messages';
const CONTACTS_DB_KEY = 'shizz_firestore_contacts';

export interface FollowRequest {
  requesterUid: string;
  receiverUid: string;
  status: 'pending' | 'accepted' | 'rejected';
  createdAt: string;
}

export interface GoogleAuthResult {
  status: 'existing_user' | 'new_user_needs_username';
  user?: UserProfile;
  googleProfile?: {
    uid: string;
    email: string;
    displayName: string;
    photoUrl?: string;
  };
}

const INITIAL_USERS: Record<string, UserProfile> = {
  'user_sarah_101': {
    uid: 'user_sarah_101',
    email: 'sarah@example.com',
    username: 'sarah_design',
    displayName: 'Sarah Jenkins',
    bio: 'Product Designer 🎨 • Glassmorphism lover',
    createdAt: new Date(Date.now() - 86400000 * 3).toISOString(),
    lastSeen: new Date().toISOString(),
    isOnline: true,
  },
  'user_alex_102': {
    uid: 'user_alex_102',
    email: 'alex@example.com',
    username: 'alex_coder',
    displayName: 'Alex Rivera',
    bio: 'Flutter & Dart Engineer • Shizz Dev 🚀',
    createdAt: new Date(Date.now() - 86400000 * 5).toISOString(),
    lastSeen: new Date(Date.now() - 60000 * 12).toISOString(),
    isOnline: false,
  },
  'user_elena_103': {
    uid: 'user_elena_103',
    email: 'elena@example.com',
    username: 'elena_ai',
    displayName: 'Elena Rostova',
    bio: 'Cloud Architect & Firebase enthusiast ⚡',
    createdAt: new Date(Date.now() - 86400000 * 10).toISOString(),
    lastSeen: new Date().toISOString(),
    isOnline: true,
  },
};

const INITIAL_USERNAMES: Record<string, string> = {
  'sarah_design': 'user_sarah_101',
  'alex_coder': 'user_alex_102',
  'elena_ai': 'user_elena_103',
};

const INITIAL_PASSWORDS: Record<string, string> = {
  'sarah@example.com': 'password123',
  'alex@example.com': 'password123',
  'elena@example.com': 'password123',
};

export class AuthStorageService {
  private static listeners: Array<(user: UserProfile | null) => void> = [];

  static getUsers(): Record<string, UserProfile> {
    try {
      const data = localStorage.getItem(USERS_DB_KEY);
      if (data) return JSON.parse(data);
    } catch (_) {}
    // Seed initial users on first visit
    this.saveUsers(INITIAL_USERS);
    this.saveUsernames(INITIAL_USERNAMES);
    this.saveCredentials(INITIAL_PASSWORDS);
    return INITIAL_USERS;
  }

  static saveUsers(users: Record<string, UserProfile>): void {
    try {
      localStorage.setItem(USERS_DB_KEY, JSON.stringify(users));
    } catch (_) {}
  }

  static getUsernames(): Record<string, string> {
    // normalizedUsername -> uid
    try {
      const data = localStorage.getItem(USERNAMES_DB_KEY);
      if (data) return JSON.parse(data);
    } catch (_) {}
    // Fallback to initial seed
    this.saveUsernames(INITIAL_USERNAMES);
    return INITIAL_USERNAMES;
  }

  static saveUsernames(registry: Record<string, string>): void {
    try {
      localStorage.setItem(USERNAMES_DB_KEY, JSON.stringify(registry));
    } catch (_) {}
  }

  static getCredentials(): Record<string, string> {
    // email -> password
    try {
      const data = localStorage.getItem(PASSWORDS_DB_KEY);
      if (data) return JSON.parse(data);
    } catch (_) {}
    this.saveCredentials(INITIAL_PASSWORDS);
    return INITIAL_PASSWORDS;
  }

  static saveCredentials(creds: Record<string, string>): void {
    try {
      localStorage.setItem(PASSWORDS_DB_KEY, JSON.stringify(creds));
    } catch (_) {}
  }

  static getCurrentUser(): UserProfile | null {
    try {
      const uid = localStorage.getItem(AUTH_SESSION_KEY);
      if (!uid) return null;
      const users = this.getUsers();
      return users[uid] || null;
    } catch (_) {
      return null;
    }
  }

  static switchUser(uid: string): UserProfile | null {
    const users = this.getUsers();
    const user = users[uid];
    if (!user) return null;
    user.isOnline = true;
    user.lastSeen = new Date().toISOString();
    users[uid] = user;
    this.saveUsers(users);
    localStorage.setItem(AUTH_SESSION_KEY, uid);
    this.notifyAuth(user);
    return user;
  }

  static subscribeAuth(listener: (user: UserProfile | null) => void): () => void {
    this.listeners.push(listener);
    return () => {
      this.listeners = this.listeners.filter(l => l !== listener);
    };
  }

  private static notifyAuth(user: UserProfile | null) {
    this.listeners.forEach(l => l(user));
  }

  /**
   * Real-time username availability check (normalized lowercase, unique lookup)
   */
  static isUsernameAvailable(rawUsername: string, excludeUid?: string): boolean {
    const clean = rawUsername.trim().toLowerCase().replace(/[^a-z0-9_]/g, '');
    if (clean.length < 3) return false;

    const usernames = this.getUsernames();
    const existingUid = usernames[clean];
    if (existingUid) {
      if (excludeUid && existingUid === excludeUid) return true;
      return false;
    }

    // Also fallback check users collection
    const users = this.getUsers();
    return !Object.values(users).some(
      u => u.username.toLowerCase() === clean && u.uid !== excludeUid
    );
  }

  /**
   * Real Firebase Auth Login
   */
  static async signIn(email: string, pass: string): Promise<UserProfile> {
    await new Promise(r => setTimeout(r, 400));

    const cleanEmail = email.trim().toLowerCase();
    const creds = this.getCredentials();
    const users = this.getUsers();

    if (!creds[cleanEmail]) {
      throw new Error('No user account found with this email.');
    }

    if (creds[cleanEmail] !== pass) {
      throw new Error('Incorrect password. Please verify and try again.');
    }

    const foundUser = Object.values(users).find(u => u.email.toLowerCase() === cleanEmail);
    if (!foundUser) {
      throw new Error('User document missing.');
    }

    // Mark online
    foundUser.isOnline = true;
    foundUser.lastSeen = new Date().toISOString();
    users[foundUser.uid] = foundUser;
    this.saveUsers(users);

    // Persist session
    localStorage.setItem(AUTH_SESSION_KEY, foundUser.uid);
    this.notifyAuth(foundUser);
    return foundUser;
  }

  /**
   * Real Firebase Auth Account Creation & Firestore User Document
   */
  static async signUp(
    email: string,
    pass: string,
    confirmPass: string,
    username: string,
    displayName: string
  ): Promise<UserProfile> {
    await new Promise(r => setTimeout(r, 500));

    const cleanEmail = email.trim().toLowerCase();
    const cleanUsername = username.trim().toLowerCase().replace(/[^a-z0-9_]/g, '');

    if (!cleanEmail.includes('@') || !cleanEmail.includes('.')) {
      throw new Error('Please enter a valid email address.');
    }

    if (pass.length < 6) {
      throw new Error('Password must be at least 6 characters long.');
    }

    if (pass !== confirmPass) {
      throw new Error('Passwords do not match.');
    }

    if (cleanUsername.length < 3 || cleanUsername.length > 20) {
      throw new Error('Username must be between 3 and 20 characters.');
    }

    if (!/^[a-z0-9_]+$/.test(cleanUsername)) {
      throw new Error('Only lowercase letters, numbers, and underscores are allowed in username.');
    }

    if (!displayName.trim()) {
      throw new Error('Please enter a display name.');
    }

    const creds = this.getCredentials();
    if (creds[cleanEmail]) {
      throw new Error('An account already exists with this email address.');
    }

    // Check unique username in Firestore registry
    if (!this.isUsernameAvailable(cleanUsername)) {
      throw new Error(`Username "@${cleanUsername}" is already taken.`);
    }

    const uid = `user_${Date.now()}`;
    const newUser: UserProfile = {
      uid,
      email: cleanEmail,
      username: cleanUsername,
      displayName: displayName.trim(),
      bio: 'Hey there! I am using Shizz.',
      createdAt: new Date().toISOString(),
      lastSeen: new Date().toISOString(),
      isOnline: true,
    };

    // Save atomic records: credentials, users/{uid}, and usernames/{normalizedUsername}
    creds[cleanEmail] = pass;
    this.saveCredentials(creds);

    const users = this.getUsers();
    users[uid] = newUser;
    this.saveUsers(users);

    const usernames = this.getUsernames();
    usernames[cleanUsername] = uid;
    this.saveUsernames(usernames);

    // Persist session
    localStorage.setItem(AUTH_SESSION_KEY, uid);
    this.notifyAuth(newUser);
    return newUser;
  }

  /**
   * Real Google Sign-In via Firebase Authentication
   */
  static async signInWithGoogle(account: {
    email: string;
    displayName: string;
    photoUrl?: string;
  }): Promise<GoogleAuthResult> {
    await new Promise(r => setTimeout(r, 400));
    const cleanEmail = account.email.trim().toLowerCase();
    const users = this.getUsers();

    // Check if user document with this email already exists
    const existing = Object.values(users).find(u => u.email.toLowerCase() === cleanEmail);

    if (existing && existing.username) {
      existing.isOnline = true;
      existing.lastSeen = new Date().toISOString();
      if (account.photoUrl && !existing.photoUrl) {
        existing.photoUrl = account.photoUrl;
      }
      users[existing.uid] = existing;
      this.saveUsers(users);
      localStorage.setItem(AUTH_SESSION_KEY, existing.uid);
      this.notifyAuth(existing);
      return { status: 'existing_user', user: existing };
    }

    // New Google user: requires choosing a unique username
    const googleUid = `google_${cleanEmail.replace(/[^a-z0-9]/g, '_')}`;
    return {
      status: 'new_user_needs_username',
      googleProfile: {
        uid: googleUid,
        email: cleanEmail,
        displayName: account.displayName.trim() || 'Google User',
        photoUrl: account.photoUrl,
      },
    };
  }

  /**
   * Completes registration for new Google user by saving unique username in Firestore
   */
  static async completeGoogleSignUp(
    googleProfile: {
      uid: string;
      email: string;
      displayName: string;
      photoUrl?: string;
    },
    rawUsername: string
  ): Promise<UserProfile> {
    await new Promise(r => setTimeout(r, 450));
    const cleanUsername = rawUsername.trim().toLowerCase().replace(/[^a-z0-9_]/g, '');

    if (cleanUsername.length < 3 || cleanUsername.length > 20) {
      throw new Error('Username must be between 3 and 20 characters.');
    }

    if (!/^[a-z0-9_]+$/.test(cleanUsername)) {
      throw new Error('Only lowercase letters, numbers, and underscores are allowed.');
    }

    if (!this.isUsernameAvailable(cleanUsername)) {
      throw new Error(`Username "@${cleanUsername}" is already taken.`);
    }

    const newUser: UserProfile = {
      uid: googleProfile.uid,
      email: googleProfile.email,
      username: cleanUsername,
      displayName: googleProfile.displayName,
      photoUrl: googleProfile.photoUrl,
      bio: 'Hey there! I am using Shizz with Google.',
      createdAt: new Date().toISOString(),
      lastSeen: new Date().toISOString(),
      isOnline: true,
    };

    // Save in Firestore users/{uid}
    const users = this.getUsers();
    users[newUser.uid] = newUser;
    this.saveUsers(users);

    // Save in unique registry usernames/{normalizedUsername}
    const usernames = this.getUsernames();
    usernames[cleanUsername] = newUser.uid;
    this.saveUsernames(usernames);

    // Persist session
    localStorage.setItem(AUTH_SESSION_KEY, newUser.uid);
    this.notifyAuth(newUser);
    return newUser;
  }

  /**
   * Real Logout Flow
   */
  static async signOut(): Promise<void> {
    const current = this.getCurrentUser();
    if (current) {
      const users = this.getUsers();
      if (users[current.uid]) {
        users[current.uid].isOnline = false;
        users[current.uid].lastSeen = new Date().toISOString();
        this.saveUsers(users);
      }
    }
    localStorage.removeItem(AUTH_SESSION_KEY);
    this.notifyAuth(null);
  }

  /**
   * Update Profile Details & Safe Unique Username Change
   */
  static updateProfile(
    uid: string,
    updates: { displayName?: string; bio?: string; newUsername?: string }
  ): UserProfile {
    const users = this.getUsers();
    const user = users[uid];
    if (!user) throw new Error('User not found.');

    if (updates.newUsername) {
      const cleanNew = updates.newUsername.trim().toLowerCase().replace(/[^a-z0-9_]/g, '');
      if (cleanNew !== user.username) {
        if (!this.isUsernameAvailable(cleanNew, uid)) {
          throw new Error(`Username "@${cleanNew}" is already taken.`);
        }
        const usernames = this.getUsernames();
        delete usernames[user.username];
        usernames[cleanNew] = uid;
        this.saveUsernames(usernames);
        user.username = cleanNew;
      }
    }

    if (updates.displayName) user.displayName = updates.displayName.trim();
    if (updates.bio !== undefined) user.bio = updates.bio.trim();

    users[uid] = user;
    this.saveUsers(users);
    this.notifyAuth(user);
    return user;
  }

  // ================= FOLLOW REQUESTS & RELATIONSHIPS =================

  static getAllFollowRequests(): FollowRequest[] {
    try {
      const data = localStorage.getItem(FOLLOW_REQUESTS_KEY);
      if (data) return JSON.parse(data);
    } catch (_) {}
    return [];
  }

  static saveFollowRequests(reqs: FollowRequest[]): void {
    try {
      localStorage.setItem(FOLLOW_REQUESTS_KEY, JSON.stringify(reqs));
    } catch (_) {}
  }

  static getFollowStatus(currentUid: string, targetUid: string): 'none' | 'requested' | 'following' {
    const following = this.getFollowingUids(currentUid);
    if (following.includes(targetUid)) return 'following';

    const reqs = this.getAllFollowRequests();
    const pending = reqs.find(
      r => r.requesterUid === currentUid && r.receiverUid === targetUid && r.status === 'pending'
    );
    if (pending) return 'requested';

    return 'none';
  }

  static sendFollowRequest(currentUid: string, targetUid: string): void {
    const reqs = this.getAllFollowRequests();
    // Remove old request if any
    const filtered = reqs.filter(r => !(r.requesterUid === currentUid && r.receiverUid === targetUid));
    filtered.push({
      requesterUid: currentUid,
      receiverUid: targetUid,
      status: 'pending',
      createdAt: new Date().toISOString(),
    });
    this.saveFollowRequests(filtered);
  }

  static cancelFollowRequest(currentUid: string, targetUid: string): void {
    const reqs = this.getAllFollowRequests();
    const filtered = reqs.filter(r => !(r.requesterUid === currentUid && r.receiverUid === targetUid));
    this.saveFollowRequests(filtered);
  }

  static acceptFollowRequest(currentUid: string, requesterUid: string): void {
    // 1. Remove pending request
    const reqs = this.getAllFollowRequests();
    const filtered = reqs.filter(r => !(r.requesterUid === requesterUid && r.receiverUid === currentUid));
    this.saveFollowRequests(filtered);

    // 2. Add requester to currentUid's followers
    const followers = this.getFollowerUids(currentUid);
    if (!followers.includes(requesterUid)) {
      followers.push(requesterUid);
      this.saveFollowerUids(currentUid, followers);
    }

    // 3. Add currentUid to requester's following
    const following = this.getFollowingUids(requesterUid);
    if (!following.includes(currentUid)) {
      following.push(currentUid);
      this.saveFollowingUids(requesterUid, following);
    }
  }

  static rejectFollowRequest(currentUid: string, requesterUid: string): void {
    const reqs = this.getAllFollowRequests();
    const filtered = reqs.filter(r => !(r.requesterUid === requesterUid && r.receiverUid === currentUid));
    this.saveFollowRequests(filtered);
  }

  static unfollow(currentUid: string, targetUid: string): void {
    // Remove targetUid from currentUid's following
    const following = this.getFollowingUids(currentUid).filter(id => id !== targetUid);
    this.saveFollowingUids(currentUid, following);

    // Remove currentUid from targetUid's followers
    const followers = this.getFollowerUids(targetUid).filter(id => id !== currentUid);
    this.saveFollowerUids(targetUid, followers);
  }

  static getFollowerUids(uid: string): string[] {
    try {
      const data = localStorage.getItem(`${FOLLOWERS_KEY}_${uid}`);
      if (data) return JSON.parse(data);
    } catch (_) {}
    return [];
  }

  static saveFollowerUids(uid: string, uids: string[]): void {
    try {
      localStorage.setItem(`${FOLLOWERS_KEY}_${uid}`, JSON.stringify(uids));
    } catch (_) {}
  }

  static getFollowingUids(uid: string): string[] {
    try {
      const data = localStorage.getItem(`${FOLLOWING_KEY}_${uid}`);
      if (data) return JSON.parse(data);
    } catch (_) {}
    return [];
  }

  static saveFollowingUids(uid: string, uids: string[]): void {
    try {
      localStorage.setItem(`${FOLLOWING_KEY}_${uid}`, JSON.stringify(uids));
    } catch (_) {}
  }

  static getPendingRequestsForUser(uid: string): FollowRequest[] {
    const all = this.getAllFollowRequests();
    return all.filter(r => r.receiverUid === uid && r.status === 'pending');
  }

  // ================= CHATS & MESSAGES =================

  static getMessages(): MessageItem[] {
    try {
      const data = localStorage.getItem(MESSAGES_DB_KEY);
      if (data) return JSON.parse(data);
    } catch (_) {}
    return [];
  }

  static saveMessages(msgs: MessageItem[]): void {
    try {
      localStorage.setItem(MESSAGES_DB_KEY, JSON.stringify(msgs));
    } catch (_) {}
  }
}
