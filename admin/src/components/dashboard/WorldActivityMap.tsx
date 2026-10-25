import React from 'react';
import { MoreHorizontal } from 'lucide-react';

export const WorldActivityMap: React.FC = () => {
  return (
    <div className="bg-white rounded-2xl p-6 border border-[#E8EAE6] shadow-xs flex flex-col justify-between h-full">
      {/* ── HEADER (From reference) ───────────────────────────────── */}
      <div className="flex items-center justify-between mb-4">
        <h3 className="text-base font-bold text-[#1A1C29]">
          Latest Transaction
        </h3>
        <div className="w-6 h-5 rounded-md bg-[#F4F5F7] flex items-center justify-center text-gray-400 cursor-pointer hover:text-gray-600">
          <MoreHorizontal className="w-3.5 h-3.5 stroke-[2]" />
        </div>
      </div>

      {/* ── LIME GREEN DOTTED WORLD MAP WITH CONNECTED ORANGE PATHS ── */}
      <div className="relative w-full h-52 flex items-center justify-center overflow-hidden">
        <svg
          viewBox="0 0 500 240"
          className="w-full h-full"
          fill="none"
          xmlns="http://www.w3.org/2000/svg"
        >
          {/* Group 1: Dotted Continent Shapes in Vibrant Lime Green */}
          <g fill="#D4FF32" opacity="0.85">
            {/* North America dots */}
            <circle cx="90" cy="50" r="2.5" />
            <circle cx="105" cy="45" r="2.5" />
            <circle cx="120" cy="40" r="2.5" />
            <circle cx="80" cy="65" r="2.5" />
            <circle cx="95" cy="60" r="2.5" />
            <circle cx="110" cy="58" r="2.5" />
            <circle cx="125" cy="55" r="2.5" />
            <circle cx="140" cy="50" r="2.5" />
            <circle cx="85" cy="80" r="2.5" />
            <circle cx="100" cy="75" r="2.5" />
            <circle cx="115" cy="72" r="2.5" />
            <circle cx="130" cy="70" r="2.5" />
            <circle cx="145" cy="68" r="2.5" />
            <circle cx="105" cy="90" r="2.5" />
            <circle cx="120" cy="88" r="2.5" />
            <circle cx="135" cy="85" r="2.5" />
            <circle cx="150" cy="82" r="2.5" />
            <circle cx="115" cy="105" r="2.5" />
            <circle cx="130" cy="102" r="2.5" />
            <circle cx="140" cy="118" r="2.5" />

            {/* South America dots */}
            <circle cx="150" cy="140" r="2.5" />
            <circle cx="165" cy="145" r="2.5" />
            <circle cx="160" cy="160" r="2.5" />
            <circle cx="175" cy="165" r="2.5" />
            <circle cx="165" cy="180" r="2.5" />
            <circle cx="180" cy="185" r="2.5" />
            <circle cx="170" cy="200" r="2.5" />
            <circle cx="175" cy="215" r="2.5" />

            {/* Europe dots */}
            <circle cx="230" cy="45" r="2.5" />
            <circle cx="245" cy="40" r="2.5" />
            <circle cx="260" cy="38" r="2.5" />
            <circle cx="235" cy="60" r="2.5" />
            <circle cx="250" cy="55" r="2.5" />
            <circle cx="265" cy="52" r="2.5" />
            <circle cx="280" cy="50" r="2.5" />
            <circle cx="240" cy="75" r="2.5" />
            <circle cx="255" cy="70" r="2.5" />
            <circle cx="270" cy="68" r="2.5" />
            <circle cx="285" cy="65" r="2.5" />

            {/* Africa dots */}
            <circle cx="245" cy="95" r="2.5" />
            <circle cx="260" cy="92" r="2.5" />
            <circle cx="275" cy="90" r="2.5" />
            <circle cx="250" cy="115" r="2.5" />
            <circle cx="265" cy="112" r="2.5" />
            <circle cx="280" cy="110" r="2.5" />
            <circle cx="295" cy="108" r="2.5" />
            <circle cx="255" cy="135" r="2.5" />
            <circle cx="270" cy="132" r="2.5" />
            <circle cx="285" cy="130" r="2.5" />
            <circle cx="265" cy="155" r="2.5" />
            <circle cx="280" cy="152" r="2.5" />
            <circle cx="275" cy="175" r="2.5" />

            {/* Asia dots */}
            <circle cx="310" cy="40" r="2.5" />
            <circle cx="325" cy="42" r="2.5" />
            <circle cx="340" cy="45" r="2.5" />
            <circle cx="355" cy="48" r="2.5" />
            <circle cx="370" cy="50" r="2.5" />
            <circle cx="385" cy="55" r="2.5" />
            <circle cx="400" cy="60" r="2.5" />
            <circle cx="415" cy="65" r="2.5" />
            <circle cx="320" cy="65" r="2.5" />
            <circle cx="335" cy="68" r="2.5" />
            <circle cx="350" cy="70" r="2.5" />
            <circle cx="365" cy="72" r="2.5" />
            <circle cx="380" cy="75" r="2.5" />
            <circle cx="395" cy="78" r="2.5" />
            <circle cx="410" cy="80" r="2.5" />
            <circle cx="330" cy="90" r="2.5" />
            <circle cx="345" cy="92" r="2.5" />
            <circle cx="360" cy="95" r="2.5" />
            <circle cx="375" cy="98" r="2.5" />
            <circle cx="390" cy="100" r="2.5" />
            <circle cx="405" cy="102" r="2.5" />
            <circle cx="360" cy="115" r="2.5" />
            <circle cx="375" cy="118" r="2.5" />
            <circle cx="390" cy="122" r="2.5" />

            {/* Australia / Oceania dots */}
            <circle cx="410" cy="150" r="2.5" />
            <circle cx="425" cy="155" r="2.5" />
            <circle cx="440" cy="160" r="2.5" />
            <circle cx="415" cy="170" r="2.5" />
            <circle cx="430" cy="175" r="2.5" />
            <circle cx="445" cy="180" r="2.5" />
          </g>

          {/* Group 2: Glowing Orange Connected Flight / Activity Lines from reference */}
          <g stroke="#FFA048" strokeWidth="1.5" opacity="0.85">
            {/* North America to Europe */}
            <path d="M 125 72 Q 190 30 250 55" fill="none" strokeDasharray="2 2" />
            {/* North America to South America */}
            <path d="M 125 72 L 165 145" fill="none" />
            {/* Europe to Africa */}
            <path d="M 250 55 L 265 112" fill="none" />
            {/* Europe to Asia */}
            <path d="M 250 55 Q 310 30 365 72" fill="none" />
            {/* South America to Africa */}
            <path d="M 165 145 Q 215 160 265 112" fill="none" strokeDasharray="3 3" />
            {/* Africa to Asia */}
            <path d="M 265 112 L 365 72" fill="none" />
            {/* Asia to Australia */}
            <path d="M 365 72 Q 410 110 425 155" fill="none" />
            {/* Global cross-circuit from reference */}
            <path d="M 165 145 L 365 72" fill="none" strokeDasharray="1 3" opacity="0.6" />
          </g>

          {/* Group 3: Concentric Location Pins matching reference image */}
          {/* Node 1: North America */}
          <circle cx="125" cy="72" r="7" fill="#FFA048" fillOpacity="0.25" stroke="#FFA048" strokeWidth="1" />
          <circle cx="125" cy="72" r="3.5" fill="#D4FF32" stroke="#1B1D28" strokeWidth="1" />

          {/* Node 2: Europe */}
          <circle cx="250" cy="55" r="7" fill="#FFA048" fillOpacity="0.25" stroke="#FFA048" strokeWidth="1" />
          <circle cx="250" cy="55" r="3.5" fill="#D4FF32" stroke="#1B1D28" strokeWidth="1" />

          {/* Node 3: South America */}
          <circle cx="165" cy="145" r="7" fill="#FFA048" fillOpacity="0.25" stroke="#FFA048" strokeWidth="1" />
          <circle cx="165" cy="145" r="3.5" fill="#D4FF32" stroke="#1B1D28" strokeWidth="1" />

          {/* Node 4: Asia / India */}
          <circle cx="365" cy="72" r="8" fill="#FFA048" fillOpacity="0.3" stroke="#FFA048" strokeWidth="1.5" />
          <circle cx="365" cy="72" r="4" fill="#FFA048" />

          {/* Node 5: Australia */}
          <circle cx="425" cy="155" r="6" fill="#FFA048" fillOpacity="0.25" stroke="#FFA048" strokeWidth="1" />
          <circle cx="425" cy="155" r="3" fill="#D4FF32" stroke="#1B1D28" strokeWidth="1" />
        </svg>
      </div>
    </div>
  );
};
