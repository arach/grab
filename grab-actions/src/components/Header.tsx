import { useState } from 'react';
import { CaptureTypeFilter } from '../types';

interface HeaderProps {
  onRefresh: () => void;
  onFilterChange: (filters: CaptureTypeFilter) => void;
  filters: CaptureTypeFilter;
  totalCaptures: number;
}

export function Header({ onRefresh, onFilterChange, filters, totalCaptures }: HeaderProps) {
  const [showFilters, setShowFilters] = useState(false);

  const handleFilterToggle = (type: keyof CaptureTypeFilter) => {
    onFilterChange({
      ...filters,
      [type]: !filters[type]
    });
  };

  const activeFilters = Object.values(filters).filter(Boolean).length;

  return (
    <div className="bg-black/20 backdrop-blur-xl border-b border-white/10 sticky top-0 z-10">
      <div className="p-6">
        <div className="flex items-center justify-between">
          <div className="flex items-center space-x-4">
            <h1 className="text-3xl font-bold text-white flex items-center">
              Grab
              <span className="text-white/60 ml-2 text-2xl">-‿¬</span>
            </h1>
            <div className="text-white/60 text-sm">
              {totalCaptures} captures
            </div>
          </div>
          
          <div className="flex items-center space-x-3">
            <button
              onClick={() => setShowFilters(!showFilters)}
              className={`px-4 py-2 rounded-lg transition-all duration-200 ${
                showFilters 
                  ? 'bg-white/20 text-white' 
                  : 'bg-white/10 text-white/80 hover:bg-white/15'
              }`}
            >
              <div className="flex items-center space-x-2">
                <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M3 4a1 1 0 011-1h16a1 1 0 011 1v2.586a1 1 0 01-.293.707l-6.414 6.414a1 1 0 00-.293.707V17l-4 4v-6.586a1 1 0 00-.293-.707L3.293 7.707A1 1 0 013 7V4z" />
                </svg>
                <span>Filter</span>
                {activeFilters > 0 && (
                  <span className="bg-blue-500 text-white text-xs rounded-full w-5 h-5 flex items-center justify-center">
                    {activeFilters}
                  </span>
                )}
              </div>
            </button>
            
            <button
              onClick={onRefresh}
              className="px-4 py-2 bg-white/10 text-white/80 rounded-lg hover:bg-white/15 transition-all duration-200"
            >
              <div className="flex items-center space-x-2">
                <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15" />
                </svg>
                <span>Refresh</span>
              </div>
            </button>
          </div>
        </div>
        
        {showFilters && (
          <div className="mt-4 p-4 bg-white/5 rounded-lg border border-white/10">
            <div className="flex items-center space-x-4">
              <span className="text-white/80 text-sm font-medium">Show:</span>
              {Object.entries(filters).map(([type, enabled]) => (
                <label key={type} className="flex items-center space-x-2 cursor-pointer">
                  <input
                    type="checkbox"
                    checked={enabled}
                    onChange={() => handleFilterToggle(type as keyof CaptureTypeFilter)}
                    className="w-4 h-4 text-blue-500 bg-white/10 border-white/20 rounded focus:ring-blue-500 focus:ring-2"
                  />
                  <span className="text-white/80 text-sm capitalize">{type}</span>
                </label>
              ))}
            </div>
          </div>
        )}
      </div>
    </div>
  );
}