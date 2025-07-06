import React, { useState, useEffect } from 'react';
import { listen } from '@tauri-apps/api/event';

interface DeepLinkExampleProps {
  onDeepLinkReceived?: (captureId: string) => void;
}

export const DeepLinkExample: React.FC<DeepLinkExampleProps> = ({ onDeepLinkReceived }) => {
  const [lastDeepLink, setLastDeepLink] = useState<string | null>(null);
  const [deepLinkHistory, setDeepLinkHistory] = useState<string[]>([]);

  useEffect(() => {
    // Listen for deep link events
    const unlisten = listen('deep-link-capture', (event) => {
      const captureId = event.payload as string;
      console.log('Deep link event received:', captureId);
      
      setLastDeepLink(captureId);
      setDeepLinkHistory(prev => [captureId, ...prev].slice(0, 5)); // Keep last 5
      
      // Call optional callback
      if (onDeepLinkReceived) {
        onDeepLinkReceived(captureId);
      }
    });

    return () => {
      unlisten.then(fn => fn());
    };
  }, [onDeepLinkReceived]);

  return (
    <div className="p-4 bg-gray-800 rounded-lg border border-gray-700">
      <h3 className="text-lg font-semibold text-white mb-3">Deep Link Monitor</h3>
      
      <div className="space-y-3">
        <div>
          <label className="block text-sm font-medium text-gray-300 mb-1">
            Last Deep Link:
          </label>
          <div className="px-3 py-2 bg-gray-900 rounded border border-gray-600 text-white font-mono text-sm">
            {lastDeepLink || 'None'}
          </div>
        </div>

        <div>
          <label className="block text-sm font-medium text-gray-300 mb-1">
            Recent Deep Links:
          </label>
          <div className="space-y-1">
            {deepLinkHistory.length > 0 ? (
              deepLinkHistory.map((link, index) => (
                <div
                  key={index}
                  className="px-3 py-2 bg-gray-900 rounded border border-gray-600 text-white font-mono text-sm"
                >
                  {link}
                </div>
              ))
            ) : (
              <div className="px-3 py-2 bg-gray-900 rounded border border-gray-600 text-gray-400 italic">
                No deep links received yet
              </div>
            )}
          </div>
        </div>

        <div className="text-sm text-gray-400 mt-4">
          <p><strong>To test deep linking:</strong></p>
          <p>Launch the app with: <code className="bg-gray-700 px-2 py-1 rounded">grab-viewer://capture-id-123</code></p>
          <p>Or use the Swift app to launch with a specific capture ID</p>
        </div>
      </div>
    </div>
  );
};