import { Action, CORE_ACTIONS } from './index';

export const viewAction: Action = {
  id: CORE_ACTIONS.VIEW,
  name: 'View',
  description: 'View capture with zoom and rotation controls',
  icon: 'Eye',
  category: 'view',
  supportedTypes: ['screenshot', 'text', 'link'],
  execute: async (_capture, _options) => {
    // This is handled by the UI state, not a separate action
    console.log('View action executed');
  },
};

export const copyAction: Action = {
  id: CORE_ACTIONS.COPY,
  name: 'Copy',
  description: 'Copy content to clipboard',
  icon: 'Copy',
  category: 'export',
  supportedTypes: ['screenshot', 'text', 'link'],
  execute: async (_capture, _options) => {
    // Implementation moved to ActionView component
    console.log('Copy action executed');
  },
};

export const downloadAction: Action = {
  id: CORE_ACTIONS.DOWNLOAD,
  name: 'Download',
  description: 'Save capture to downloads folder',
  icon: 'Download',
  category: 'export',
  supportedTypes: ['screenshot', 'text', 'link'],
  execute: async (_capture, _options) => {
    // Implementation moved to ActionView component
    console.log('Download action executed');
  },
};

export const shareAction: Action = {
  id: CORE_ACTIONS.SHARE,
  name: 'Share',
  description: 'Share capture using native sharing',
  icon: 'Share2',
  category: 'share',
  supportedTypes: ['screenshot', 'text', 'link'],
  execute: async (_capture, _options) => {
    // Implementation moved to ActionView component
    console.log('Share action executed');
  },
};

export const deleteAction: Action = {
  id: CORE_ACTIONS.DELETE,
  name: 'Delete',
  description: 'Delete capture permanently',
  icon: 'Trash2',
  category: 'manage',
  supportedTypes: ['screenshot', 'text', 'link'],
  execute: async (_capture, _options) => {
    // Implementation moved to ActionView component
    console.log('Delete action executed');
  },
};

export const CORE_ACTION_LIST = [
  viewAction,
  copyAction,
  downloadAction,
  shareAction,
  deleteAction,
];