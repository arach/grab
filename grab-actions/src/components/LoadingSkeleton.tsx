interface LoadingSkeletonProps {
  variant?: 'card' | 'list' | 'detail';
  count?: number;
}

function SkeletonCard() {
  return (
    <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-4 animate-pulse">
      <div className="flex items-start space-x-3">
        <div className="w-12 h-12 bg-gray-200 rounded-lg flex-shrink-0"></div>
        <div className="flex-1 space-y-2">
          <div className="h-4 bg-gray-200 rounded w-3/4"></div>
          <div className="h-3 bg-gray-200 rounded w-1/2"></div>
          <div className="h-3 bg-gray-200 rounded w-2/3"></div>
        </div>
      </div>
      <div className="mt-3 flex items-center justify-between">
        <div className="flex space-x-2">
          <div className="h-6 bg-gray-200 rounded-full w-12"></div>
          <div className="h-6 bg-gray-200 rounded-full w-16"></div>
        </div>
        <div className="h-3 bg-gray-200 rounded w-16"></div>
      </div>
    </div>
  );
}

function SkeletonListItem() {
  return (
    <div className="flex items-center space-x-3 p-3 border-b border-gray-200 animate-pulse">
      <div className="w-8 h-8 bg-gray-200 rounded flex-shrink-0"></div>
      <div className="flex-1 space-y-1">
        <div className="h-4 bg-gray-200 rounded w-3/4"></div>
        <div className="h-3 bg-gray-200 rounded w-1/2"></div>
      </div>
      <div className="h-3 bg-gray-200 rounded w-20"></div>
    </div>
  );
}

function SkeletonDetail() {
  return (
    <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6 animate-pulse">
      <div className="space-y-4">
        <div className="h-6 bg-gray-200 rounded w-1/2"></div>
        <div className="space-y-2">
          <div className="h-4 bg-gray-200 rounded w-full"></div>
          <div className="h-4 bg-gray-200 rounded w-5/6"></div>
          <div className="h-4 bg-gray-200 rounded w-4/6"></div>
        </div>
        <div className="h-48 bg-gray-200 rounded-lg"></div>
        <div className="flex items-center space-x-3">
          <div className="h-8 bg-gray-200 rounded w-16"></div>
          <div className="h-8 bg-gray-200 rounded w-20"></div>
          <div className="h-8 bg-gray-200 rounded w-14"></div>
        </div>
      </div>
    </div>
  );
}

export function LoadingSkeleton({ variant = 'card', count = 3 }: LoadingSkeletonProps) {
  const skeletons = Array.from({ length: count }, (_, index) => {
    switch (variant) {
      case 'list':
        return <SkeletonListItem key={index} />;
      case 'detail':
        return <SkeletonDetail key={index} />;
      case 'card':
      default:
        return <SkeletonCard key={index} />;
    }
  });

  return (
    <div className={`space-y-4 ${variant === 'list' ? 'space-y-0' : ''}`}>
      {skeletons}
    </div>
  );
}

export function LoadingSpinner({ size = 'medium' }: { size?: 'small' | 'medium' | 'large' }) {
  const sizeClasses = {
    small: 'w-4 h-4',
    medium: 'w-8 h-8',
    large: 'w-12 h-12',
  };

  return (
    <div className="flex items-center justify-center">
      <div
        className={`${sizeClasses[size]} border-2 border-gray-300 border-t-blue-600 rounded-full animate-spin`}
      ></div>
    </div>
  );
}

export function LoadingOverlay({ message = 'Loading...' }: { message?: string }) {
  return (
    <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
      <div className="bg-white rounded-lg p-6 flex items-center space-x-3">
        <LoadingSpinner size="medium" />
        <span className="text-gray-700">{message}</span>
      </div>
    </div>
  );
}