import { useState, useEffect, useMemo } from 'react';
import { CaptureCard } from './CaptureCard';
import { CaptureFile } from '../types';

interface CaptureGridProps {
  captures: CaptureFile[];
  onCaptureSelect: (capture: CaptureFile) => void;
  selectedCapture: CaptureFile | null;
}

export function CaptureGrid({ captures, onCaptureSelect, selectedCapture }: CaptureGridProps) {
  const [columns, setColumns] = useState(4);

  useEffect(() => {
    const updateColumns = () => {
      const width = window.innerWidth;
      if (width < 640) {
        setColumns(1);
      } else if (width < 1024) {
        setColumns(2);
      } else if (width < 1536) {
        setColumns(3);
      } else {
        setColumns(4);
      }
    };

    updateColumns();
    window.addEventListener('resize', updateColumns);
    return () => window.removeEventListener('resize', updateColumns);
  }, []);

  const columnedCaptures = useMemo(() => {
    const cols: CaptureFile[][] = Array.from({ length: columns }, () => []);
    
    captures.forEach((capture, index) => {
      const columnIndex = index % columns;
      cols[columnIndex].push(capture);
    });

    return cols;
  }, [captures, columns]);

  if (captures.length === 0) {
    return (
      <div className="flex flex-col items-center justify-center h-64 text-white/60">
        <div className="text-6xl mb-4">📂</div>
        <div className="text-xl font-medium mb-2">No captures found</div>
        <div className="text-sm text-white/40">
          Start capturing to see your grabs here
        </div>
      </div>
    );
  }

  return (
    <div className="p-6">
      <div className="grid gap-4" style={{ gridTemplateColumns: `repeat(${columns}, 1fr)` }}>
        {columnedCaptures.map((column, columnIndex) => (
          <div key={columnIndex} className="space-y-4">
            {column.map((capture) => (
              <CaptureCard
                key={capture.name}
                capture={capture}
                isSelected={selectedCapture?.name === capture.name}
                onClick={() => onCaptureSelect(capture)}
              />
            ))}
          </div>
        ))}
      </div>
    </div>
  );
}