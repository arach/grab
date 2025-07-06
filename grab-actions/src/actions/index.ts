export interface Action {
  id: string;
  name: string;
  description: string;
  icon: string;
  category: 'view' | 'export' | 'edit' | 'share' | 'manage' | 'process';
  supportedTypes: ('screenshot' | 'text' | 'link')[];
  execute: (capture: any, options?: any) => Promise<void>;
}

export interface ActionCategory {
  id: string;
  name: string;
  description: string;
  actions: Action[];
}

// Core actions that every capture supports
export const CORE_ACTIONS = {
  VIEW: 'view',
  COPY: 'copy',
  DOWNLOAD: 'download',
  SHARE: 'share',
  DELETE: 'delete',
  TAG: 'tag',
} as const;

// Future action categories for extensibility
export const ACTION_CATEGORIES = {
  VIEW: 'view',
  EXPORT: 'export', 
  EDIT: 'edit',
  SHARE: 'share',
  MANAGE: 'manage',
  PROCESS: 'process',
} as const;