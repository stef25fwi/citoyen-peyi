// Hibiscus flower SVG as a React component for filigrane/watermark use
const HibiscusPattern = ({ className = '' }: { className?: string }) => (
  <svg
    className={className}
    viewBox="0 0 200 200"
    fill="none"
    xmlns="http://www.w3.org/2000/svg"
  >
    {/* Petal 1 - top */}
    <path
      d="M100 20C85 20 70 45 75 70C80 85 90 90 100 85C110 90 120 85 125 70C130 45 115 20 100 20Z"
      fill="white"
      fillOpacity="0.12"
      filter="url(#hibiscusShadow)"
    />
    {/* Petal 2 - top right */}
    <path
      d="M155 55C145 42 120 38 105 55C98 65 100 78 110 82C108 92 115 100 130 100C150 100 165 78 155 55Z"
      fill="white"
      fillOpacity="0.10"
      filter="url(#hibiscusShadow)"
    />
    {/* Petal 3 - bottom right */}
    <path
      d="M150 120C155 105 145 82 125 80C112 78 105 85 108 95C100 100 98 110 108 125C120 145 148 140 150 120Z"
      fill="white"
      fillOpacity="0.08"
      filter="url(#hibiscusShadow)"
    />
    {/* Petal 4 - bottom left */}
    <path
      d="M50 120C45 105 55 82 75 80C88 78 95 85 92 95C100 100 102 110 92 125C80 145 52 140 50 120Z"
      fill="white"
      fillOpacity="0.10"
      filter="url(#hibiscusShadow)"
    />
    {/* Petal 5 - top left */}
    <path
      d="M45 55C55 42 80 38 95 55C102 65 100 78 90 82C92 92 85 100 70 100C50 100 35 78 45 55Z"
      fill="white"
      fillOpacity="0.12"
      filter="url(#hibiscusShadow)"
    />
    {/* Center pistil */}
    <circle cx="100" cy="88" r="12" fill="white" fillOpacity="0.15" filter="url(#hibiscusShadow)" />
    <circle cx="100" cy="88" r="6" fill="white" fillOpacity="0.20" />
    {/* Stamen lines */}
    <line x1="100" y1="76" x2="100" y2="50" stroke="white" strokeOpacity="0.12" strokeWidth="1.5" />
    <line x1="108" y1="80" x2="125" y2="60" stroke="white" strokeOpacity="0.10" strokeWidth="1.5" />
    <line x1="92" y1="80" x2="75" y2="60" stroke="white" strokeOpacity="0.10" strokeWidth="1.5" />
    {/* 3D shadow filter */}
    <defs>
      <filter id="hibiscusShadow" x="-20%" y="-20%" width="140%" height="140%">
        <feDropShadow dx="2" dy="3" stdDeviation="3" floodColor="rgba(0,0,0,0.35)" />
      </filter>
    </defs>
  </svg>
);

export default HibiscusPattern;
