import { writeText } from '@tauri-apps/api/clipboard';
import { invoke } from '@tauri-apps/api/tauri';
import { Action, CORE_ACTIONS } from './index';

export const viewAction: Action = {
  id: CORE_ACTIONS.VIEW,
  name: 'View',
  description: 'View capture with zoom and rotation controls',
  icon: 'Eye',
  category: 'view',
  supportedTypes: ['screenshot', 'text', 'link'],
  execute: async (capture, options) => {
    // This is handled by the UI state, not a separate action
    console.log('View action executed for', capture.id);
  },
};

export const copyAction: Action = {
  id: CORE_ACTIONS.COPY,
  name: 'Copy',
  description: 'Copy content to clipboard',
  icon: 'Copy',
  category: 'export',
  supportedTypes: ['screenshot', 'text', 'link'],
  execute: async (capture, options) => {
    if (capture.type === 'screenshot') {
      await invoke('copy_image_to_clipboard', { path: capture.content });
    } else {
      await writeText(capture.content);
    }
  },
};

export const downloadAction: Action = {
  id: CORE_ACTIONS.DOWNLOAD,
  name: 'Download',
  description: 'Save capture to downloads folder',
  icon: 'Download',
  category: 'export',
  supportedTypes: ['screenshot', 'text', 'link'],
  execute: async (capture, options) => {
    if (capture.type === 'screenshot') {
      await invoke('save_capture_to_downloads', { 
        id: capture.id, 
        filename: `grab-${capture.id}.png` 
      });
    } else {
      const blob = new Blob([capture.content], { type: 'text/plain' });
      const url = URL.createObjectURL(blob);
      const a = document.createElement('a');
      a.href = url;
      a.download = `grab-${capture.id}.txt`;
      a.click();
      URL.revokeObjectURL(url);
    }
  },
};

export const shareAction: Action = {
  id: CORE_ACTIONS.SHARE,
  name: 'Share',
  description: 'Share capture using native sharing',
  icon: 'Share2',
  category: 'share',
  supportedTypes: ['screenshot', 'text', 'link'],
  execute: async (capture, options) => {
    if (navigator.share) {
      await navigator.share({
        title: capture.metadata?.title || 'Grab Capture',
        text: capture.type === 'text' ? capture.content : `Captured ${capture.type}`,
        url: capture.type === 'link' ? capture.content : undefined,
      });
    } else {
      // Fallback to copy
      await copyAction.execute(capture, options);
    }
  },
};

export const deleteAction: Action = {
  id: CORE_ACTIONS.DELETE,
  name: 'Delete',
  description: 'Delete capture permanently',
  icon: 'Trash2',
  category: 'manage',
  supportedTypes: ['screenshot', 'text', 'link'],
  execute: async (capture, options) => {
    if (window.confirm('Are you sure you want to delete this capture?')) {
      await invoke('delete_capture', { id: capture.id });
      if (options?.onDelete) {
        options.onDelete(capture.id);
      }
    }
  },
};

export const CORE_ACTION_LIST = [
  viewAction,
  copyAction,
  downloadAction,
  shareAction,
  deleteAction,
];