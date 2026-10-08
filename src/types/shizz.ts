export interface UserProfile {
  uid: string;
  email: string;
  username: string;
  displayName: string;
  photoUrl?: string;
  bio?: string;
  createdAt: string;
  lastSeen?: string;
  isOnline: boolean;
}

export interface ContactItem {
  contactUid: string;
  username: string;
  displayName: string;
  photoUrl?: string;
  addedAt: string;
}

export interface MessageItem {
  messageId: string;
  chatId: string;
  senderId: string;
  receiverId: string;
  text: string;
  timestamp: string;
  type: 'text' | 'image';
  isRead: boolean;
}

export interface ChatItem {
  chatId: string;
  participants: [string, string];
  lastMessage?: string;
  lastMessageTime?: string;
  lastSenderId?: string;
  unreadCounts: Record<string, number>;
  createdAt: string;
}

export interface FlutterCodeFile {
  path: string;
  category: 'models' | 'screens' | 'services' | 'providers' | 'widgets' | 'theme' | 'utils' | 'root' | 'android';
  description: string;
  content: string;
}
