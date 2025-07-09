import { useState, useEffect } from 'react';
import { invoke } from '@tauri-apps/api/tauri';
import { open } from '@tauri-apps/api/dialog';
import { X, Folder, Save, RotateCcw } from 'lucide-react';

interface SettingsProps {
  onClose: () => void;
}

interface AppSettings {
  captureFolder: string;
  defaultCaptureFolder: string;
}

export function Settings({ onClose }: SettingsProps) {
  const [settings, setSettings] = useState<AppSettings>({
    captureFolder: '',
    defaultCaptureFolder: ''
  });
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    loadSettings();
  }, []);

  const loadSettings = async () => {
    try {
      setLoading(true);
      setError(null);
      const loadedSettings = await invoke<AppSettings>('get_app_settings');
      setSettings(loadedSettings);
    } catch (err) {
      console.error('Failed to load settings:', err);
      setError('Failed to load settings');
    } finally {
      setLoading(false);
    }
  };

  const selectFolder = async () => {
    try {
      const selected = await open({
        directory: true,
        multiple: false,
        defaultPath: settings.captureFolder || settings.defaultCaptureFolder,
      });

      if (selected && typeof selected === 'string') {
        setSettings(prev => ({
          ...prev,
          captureFolder: selected
        }));
      }
    } catch (err) {
      console.error('Failed to select folder:', err);
      setError('Failed to select folder');
    }
  };

  const saveSettings = async () => {
    try {
      setSaving(true);
      setError(null);
      await invoke('save_app_settings', { settings });
      // Show success feedback briefly
      setTimeout(() => setSaving(false), 1000);
    } catch (err) {
      console.error('Failed to save settings:', err);
      setError('Failed to save settings');
      setSaving(false);
    }
  };

  const resetToDefault = () => {
    setSettings(prev => ({
      ...prev,
      captureFolder: prev.defaultCaptureFolder
    }));
  };

  if (loading) {
    return (
      <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center p-4 z-50">
        <div className="bg-white rounded-lg p-6">
          <div className="text-center">Loading settings...</div>
        </div>
      </div>
    );
  }

  return (
    <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center p-4 z-50">
      <div className="bg-white rounded-lg max-w-2xl w-full max-h-[80vh] flex flex-col">
        {/* Header */}
        <div className="flex items-center justify-between p-6 border-b border-gray-200">
          <h2 className="text-xl font-semibold text-gray-900">Settings</h2>
          <button
            onClick={onClose}
            className="p-2 hover:bg-gray-100 rounded-full transition-colors"
          >
            <X className="w-5 h-5 text-gray-500" />
          </button>
        </div>

        {/* Content */}
        <div className="flex-1 overflow-auto p-6">
          {error && (
            <div className="mb-4 p-3 bg-red-100 border border-red-300 text-red-700 rounded-lg">
              {error}
            </div>
          )}

          <div className="space-y-6">
            {/* Capture Folder Setting */}
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2">
                Capture Storage Folder
              </label>
              <p className="text-sm text-gray-500 mb-3">
                Choose where screenshots and clipboard captures are saved. Both the menu bar app and actions interface will use this location.
              </p>
              
              <div className="space-y-3">
                {/* Current folder display */}
                <div className="flex items-center p-3 bg-gray-50 rounded-lg border">
                  <Folder className="w-5 h-5 text-gray-400 mr-3" />
                  <span className="flex-1 text-sm text-gray-700 font-mono break-all">
                    {settings.captureFolder || 'No folder selected'}
                  </span>
                </div>

                {/* Action buttons */}
                <div className="flex gap-2">
                  <button
                    onClick={selectFolder}
                    className="flex items-center space-x-2 px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors"
                  >
                    <Folder className="w-4 h-4" />
                    <span>Choose Folder</span>
                  </button>
                  
                  <button
                    onClick={resetToDefault}
                    className="flex items-center space-x-2 px-4 py-2 bg-gray-600 text-white rounded-lg hover:bg-gray-700 transition-colors"
                  >
                    <RotateCcw className="w-4 h-4" />
                    <span>Reset to Default</span>
                  </button>
                </div>

                {/* Default folder info */}
                <div className="text-xs text-gray-500">
                  <strong>Default:</strong> {settings.defaultCaptureFolder}
                </div>
              </div>
            </div>

            {/* Future settings can be added here */}
            <div className="border-t border-gray-200 pt-6">
              <h3 className="text-sm font-medium text-gray-700 mb-2">
                More Settings Coming Soon
              </h3>
              <p className="text-sm text-gray-500">
                Additional configuration options like hotkeys, file naming patterns, and export formats will be added here.
              </p>
            </div>
          </div>
        </div>

        {/* Footer */}
        <div className="flex items-center justify-between p-6 border-t border-gray-200 bg-gray-50">
          <div className="text-sm text-gray-500">
            Settings are automatically synced between the menu bar app and actions interface.
          </div>
          
          <div className="flex gap-2">
            <button
              onClick={onClose}
              className="px-4 py-2 text-gray-700 hover:bg-gray-200 rounded-lg transition-colors"
            >
              Cancel
            </button>
            <button
              onClick={saveSettings}
              disabled={saving}
              className="flex items-center space-x-2 px-4 py-2 bg-green-600 text-white rounded-lg hover:bg-green-700 disabled:opacity-50 transition-colors"
            >
              <Save className="w-4 h-4" />
              <span>{saving ? 'Saved!' : 'Save Settings'}</span>
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}