#!/usr/bin/env node
// tools/gen_sprites.js
// Procedural art pack for Bastion Blast: flat cartoon shapes, thick dark outlines,
// blue/red teams, gold gates. No dependencies (zlib is built in).
//
//   node tools/gen_sprites.js
//
// Writes PNGs to main/assets/art, regenerates main/assets/game.atlas and a contact
// sheet at captures/art_sheet.png.

'use strict';

const fs = require('fs');
const path = require('path');
const zlib = require('zlib');

const ROOT = path.resolve(__dirname, '..');
const ART = path.join(ROOT, 'main', 'assets', 'art');
const ATLAS = path.join(ROOT, 'main', 'assets', 'game.atlas');
const SHEET = path.join(ROOT, 'captures', 'art_sheet.png');

// ---------------------------------------------------------------- PNG writer
const CRC_TABLE = (() => {
  const t = new Int32Array(256);
  for (let n = 0; n < 256; n++) {
    let c = n;
    for (let k = 0; k < 8; k++) c = (c & 1) ? (0xedb88320 ^ (c >>> 1)) : (c >>> 1);
    t[n] = c;
  }
  return t;
})();

function crc32(buf) {
  let c = -1;
  for (let i = 0; i < buf.length; i++) c = CRC_TABLE[(c ^ buf[i]) & 0xff] ^ (c >>> 8);
  return (c ^ -1) >>> 0;
}

function pngChunk(type, data) {
  const len = Buffer.alloc(4);
  len.writeUInt32BE(data.length, 0);
  const t = Buffer.from(type, 'ascii');
  const crc = Buffer.alloc(4);
  crc.writeUInt32BE(crc32(Buffer.concat([t, data])), 0);
  return Buffer.concat([len, t, data, crc]);
}

function savePNG(file, w, h, rgba) {
  const sig = Buffer.from([137, 80, 78, 71, 13, 10, 26, 10]);
  const ihdr = Buffer.alloc(13);
  ihdr.writeUInt32BE(w, 0);
  ihdr.writeUInt32BE(h, 4);
  ihdr[8] = 8;  // bit depth
  ihdr[9] = 6;  // RGBA
  const stride = w * 4;
  const raw = Buffer.alloc((stride + 1) * h);
  for (let y = 0; y < h; y++) {
    raw[y * (stride + 1)] = 0;
    Buffer.from(rgba.buffer, rgba.byteOffset + y * stride, stride).copy(raw, y * (stride + 1) + 1);
  }
  const idat = zlib.deflateSync(raw, { level: 9 });
  fs.writeFileSync(file, Buffer.concat([
    sig,
    pngChunk('IHDR', ihdr),
    pngChunk('IDAT', idat),
    pngChunk('IEND', Buffer.alloc(0)),
  ]));
}

// ---------------------------------------------------------------- canvas
const clamp = (v, a, b) => v < a ? a : (v > b ? b : v);
const lerp = (a, b, t) => a + (b - a) * t;
const hex = (h) => {
  const n = parseInt(h.replace('#', ''), 16);
  return [((n >> 16) & 255) / 255, ((n >> 8) & 255) / 255, (n & 255) / 255];
};

class Canvas {
  constructor(w, h) {
    this.w = w;
    this.h = h;
    this.px = new Float32Array(w * h * 4);
  }

  blend(x, y, r, g, b, a) {
    if (a <= 0.0005) return;
    const i = (y * this.w + x) * 4;
    const da = this.px[i + 3];
    const oa = a + da * (1 - a);
    if (oa <= 0) return;
    this.px[i] = (r * a + this.px[i] * da * (1 - a)) / oa;
    this.px[i + 1] = (g * a + this.px[i + 1] * da * (1 - a)) / oa;
    this.px[i + 2] = (b * a + this.px[i + 2] * da * (1 - a)) / oa;
    this.px[i + 3] = oa;
  }

  paint(shape, colorFn, mul = 1) {
    const b = shape.bbox;
    const x0 = Math.max(0, Math.floor(b[0]));
    const y0 = Math.max(0, Math.floor(b[1]));
    const x1 = Math.min(this.w - 1, Math.ceil(b[2]));
    const y1 = Math.min(this.h - 1, Math.ceil(b[3]));
    for (let y = y0; y <= y1; y++) {
      for (let x = x0; x <= x1; x++) {
        const d = shape.d(x + 0.5, y + 0.5);
        const cov = clamp(0.5 - d, 0, 1);
        if (cov <= 0.002) continue;
        const c = colorFn(x + 0.5, y + 0.5);
        this.blend(x, y, c[0], c[1], c[2], (c[3] === undefined ? 1 : c[3]) * cov * mul);
      }
    }
  }

  toRGBA() {
    const out = new Uint8Array(this.w * this.h * 4);
    for (let i = 0; i < out.length; i++) {
      out[i] = Math.round(clamp(this.px[i], 0, 1) * 255);
    }
    return out;
  }
}

// ---------------------------------------------------------------- colors
const OUTLINE = hex('#121826');
const WHITE = [1, 1, 1, 1];
const BLACK = [0, 0, 0, 1];

const PAL = {
  blueTop: hex('#5A93FF'), blueBot: hex('#2D70F6'), blueDark: hex('#173C9E'),
  redTop: hex('#FF6B5E'), redBot: hex('#F63A2D'), redDark: hex('#A8221A'),
  goldTop: hex('#FFD766'), goldBot: hex('#F5B82E'), goldDark: hex('#B47A12'),
  woodTop: hex('#C98B57'), woodBot: hex('#8A5430'), woodDark: hex('#5E3418'),
  stoneTop: hex('#C3CCDA'), stoneBot: hex('#8794A8'), stoneDark: hex('#5B6779'),
  steelTop: hex('#8A99AE'), steelBot: hex('#4E5A6E'), steelDark: hex('#2E3746'),
  cream: hex('#F6E7C9'), creamDark: hex('#D9C39B'),
  orange: hex('#FF8A2A'), orangeDark: hex('#C0561A'),
  purple: hex('#A06BFF'), purpleDark: hex('#6B3FC4'),
  green: hex('#54D06A'), greenDark: hex('#2B8F41'),
  cyan: hex('#5EE0F0'), cyanDark: hex('#2296B4'),
  skin: hex('#FFE0C2'), glove: hex('#7A4A2C'),
  grass: hex('#7FBF3F'), grassDark: hex('#4E8A22'),
};

function solid(color) {
  const c = [color[0], color[1], color[2], color[3] === undefined ? 1 : color[3]];
  return () => c;
}

function vgrad(top, bottom, h) {
  return (x, y) => {
    const t = clamp(y / Math.max(1, h - 1), 0, 1);
    return [lerp(top[0], bottom[0], t), lerp(top[1], bottom[1], t), lerp(top[2], bottom[2], t), 1];
  };
}

function withAlpha(color, a) {
  return () => [color[0], color[1], color[2], a];
}

function mix(a, b, t) {
  return [lerp(a[0], b[0], t), lerp(a[1], b[1], t), lerp(a[2], b[2], t), 1];
}

// ---------------------------------------------------------------- shapes
function circle(cx, cy, r) {
  return {
    bbox: [cx - r - 2, cy - r - 2, cx + r + 2, cy + r + 2],
    d: (x, y) => Math.hypot(x - cx, y - cy) - r,
  };
}

function ellipse(cx, cy, rx, ry) {
  const k = Math.min(rx, ry);
  return {
    bbox: [cx - rx - 2, cy - ry - 2, cx + rx + 2, cy + ry + 2],
    d: (x, y) => (Math.hypot((x - cx) / rx, (y - cy) / ry) - 1) * k,
  };
}

function rrect(cx, cy, w, h, r) {
  const hw = w / 2, hh = h / 2;
  const rr = Math.min(r, hw, hh);
  return {
    bbox: [cx - hw - 2, cy - hh - 2, cx + hw + 2, cy + hh + 2],
    d: (x, y) => {
      const qx = Math.abs(x - cx) - (hw - rr);
      const qy = Math.abs(y - cy) - (hh - rr);
      return Math.hypot(Math.max(qx, 0), Math.max(qy, 0)) + Math.min(Math.max(qx, qy), 0) - rr;
    },
  };
}

function capsule(x1, y1, x2, y2, r) {
  const dx = x2 - x1, dy = y2 - y1;
  const len2 = Math.max(1e-6, dx * dx + dy * dy);
  return {
    bbox: [Math.min(x1, x2) - r - 2, Math.min(y1, y2) - r - 2, Math.max(x1, x2) + r + 2, Math.max(y1, y2) + r + 2],
    d: (x, y) => {
      const t = clamp(((x - x1) * dx + (y - y1) * dy) / len2, 0, 1);
      return Math.hypot(x - (x1 + dx * t), y - (y1 + dy * t)) - r;
    },
  };
}

function ring(cx, cy, r, thickness) {
  return {
    bbox: [cx - r - thickness, cy - r - thickness, cx + r + thickness, cy + r + thickness],
    d: (x, y) => Math.abs(Math.hypot(x - cx, y - cy) - r) - thickness / 2,
  };
}

function poly(points) {
  let minX = 1e9, minY = 1e9, maxX = -1e9, maxY = -1e9;
  for (const p of points) {
    minX = Math.min(minX, p[0]); maxX = Math.max(maxX, p[0]);
    minY = Math.min(minY, p[1]); maxY = Math.max(maxY, p[1]);
  }
  return {
    bbox: [minX - 2, minY - 2, maxX + 2, maxY + 2],
    d: (x, y) => {
      let d = 1e9;
      let s = 1;
      for (let i = 0, j = points.length - 1; i < points.length; j = i++) {
        const vix = points[i][0], viy = points[i][1];
        const vjx = points[j][0], vjy = points[j][1];
        const ex = vjx - vix, ey = vjy - viy;
        const wx = x - vix, wy = y - viy;
        const t = clamp((wx * ex + wy * ey) / Math.max(1e-6, ex * ex + ey * ey), 0, 1);
        const bx = wx - ex * t, by = wy - ey * t;
        d = Math.min(d, bx * bx + by * by);
        const c1 = y >= viy, c2 = y < vjy, c3 = ex * wy > ey * wx;
        if ((c1 && c2 && c3) || (!c1 && !c2 && !c3)) s = -s;
      }
      return s * Math.sqrt(d);
    },
  };
}

function starShape(cx, cy, ro, ri, points, rot = -Math.PI / 2) {
  const pts = [];
  for (let i = 0; i < points * 2; i++) {
    const a = rot + i * Math.PI / points;
    const r = i % 2 === 0 ? ro : ri;
    pts.push([cx + Math.cos(a) * r, cy + Math.sin(a) * r]);
  }
  return poly(pts);
}

function offsetShape(shape, by) {
  return { bbox: shape.bbox, d: (x, y) => shape.d(x, y) + by };
}

function outlined(cv, shape, fill, lw = 2, outline = OUTLINE, outlineAlpha = 1) {
  cv.paint(shape, solid(outline), outlineAlpha);
  cv.paint(offsetShape(shape, lw), fill);
}

function arcShape(cx, cy, r, thickness, a0, a1) {
  const base = ring(cx, cy, r, thickness);
  return {
    bbox: base.bbox,
    d: (x, y) => {
      let a = Math.atan2(y - cy, x - cx);
      let lo = a0, hi = a1;
      while (a < lo) a += Math.PI * 2;
      while (a > hi + Math.PI * 2) a -= Math.PI * 2;
      if (a <= hi) return base.d(x, y);
      // outside the arc: distance to the nearest rounded end
      const p0 = [cx + Math.cos(a0) * r, cy + Math.sin(a0) * r];
      const p1 = [cx + Math.cos(a1) * r, cy + Math.sin(a1) * r];
      return Math.min(Math.hypot(x - p0[0], y - p0[1]), Math.hypot(x - p1[0], y - p1[1])) - thickness / 2;
    },
  };
}

// ---------------------------------------------------------------- registry
const sprites = [];
function make(name, w, h, fn) {
  const cv = new Canvas(w, h);
  fn(cv);
  sprites.push({ name, w, h, cv });
}

// ---------------------------------------------------------------- bricks
function drawBrick(cv, colors, state, w = 25, h = 21) {
  const base = rrect(w / 2, h / 2, w - 1, h - 1, 4);
  if (state < 2) {
    outlined(cv, base, vgrad(colors[0], colors[1], h), 2);
    cv.paint(rrect(w / 2, 4.2, w - 8, 4.5, 2), withAlpha(WHITE, 0.38));
    cv.paint(rrect(w / 2, h - 3.4, w - 7, 3, 1.5), withAlpha(colors[2], 0.55));
    if (state === 1) {
      const crack = withAlpha(hex('#2A1A12'), 0.65);
      cv.paint(capsule(6, 5, 11, 14, 0.9), crack);
      cv.paint(capsule(11, 14, 8, 18, 0.9), crack);
      cv.paint(capsule(16, 4, 14, 10, 0.8), crack);
      cv.paint(capsule(18, 12, 21, 16, 0.8), crack);
    }
  } else {
    // rubble: four chunks with gaps
    const chunks = [
      [7, 12, 8, 6, 0.3], [15, 8, 7, 5, -0.4], [17, 16, 6, 4, 0.2], [6, 5, 4, 3, 0],
    ];
    for (const [x, y, cw, ch, rot] of chunks) {
      const pts = [];
      const n = 4;
      for (let i = 0; i < n; i++) {
        const a = rot + i * Math.PI * 2 / n + 0.4;
        pts.push([x + Math.cos(a) * cw / 2, y + Math.sin(a) * ch / 2]);
      }
      outlined(cv, poly(pts), vgrad(colors[0], colors[1], h), 1.2);
    }
  }
}

const MATS = {
  blue: [PAL.blueTop, PAL.blueBot, PAL.blueDark],
  red: [PAL.redTop, PAL.redBot, PAL.redDark],
  wood: [PAL.woodTop, PAL.woodBot, PAL.woodDark],
  stone: [PAL.stoneTop, PAL.stoneBot, PAL.stoneDark],
  steel: [PAL.steelTop, PAL.steelBot, PAL.steelDark],
  brick: [hex('#E06A5C'), hex('#C7463A'), hex('#7F231B')],
};

for (const key of Object.keys(MATS)) {
  for (let state = 0; state < 3; state++) {
    make(`brick_${key}_${state}`, 25, 21, (cv) => drawBrick(cv, MATS[key], state));
  }
}

// beams (3 segments side by side = 100x16)
for (const key of ['wood', 'stone', 'steel']) {
  const colors = MATS[key];
  for (let state = 0; state < 3; state++) {
    make(`beam_${key}_${state}`, 100, 16, (cv) => {
      if (state < 2) {
        outlined(cv, rrect(50, 8, 98, 14, 4), vgrad(colors[0], colors[1], 16), 2);
        cv.paint(rrect(50, 4, 90, 3, 1.5), withAlpha(WHITE, 0.32));
        cv.paint(capsule(12, 9, 40, 9, 0.8), withAlpha(colors[2], 0.5));
        cv.paint(capsule(60, 9, 88, 9, 0.8), withAlpha(colors[2], 0.5));
        for (const bx of [10, 90]) {
          cv.paint(circle(bx, 8, 2.6), solid(colors[2]));
          cv.paint(circle(bx, 8, 1.3), withAlpha(WHITE, 0.6));
        }
        if (state === 1) {
          cv.paint(capsule(40, 5, 46, 12, 0.9), withAlpha(hex('#2A1A12'), 0.65));
          cv.paint(capsule(70, 4, 74, 11, 0.8), withAlpha(hex('#2A1A12'), 0.6));
        }
      } else {
        for (let i = 0; i < 4; i++) {
          const x = 14 + i * 24;
          outlined(cv, poly([[x - 8, 10], [x + 7, 8], [x + 9, 13], [x - 6, 14]]), vgrad(colors[0], colors[1], 16), 1.2);
        }
      }
    });
  }
}

// barrels (explosive)
for (let state = 0; state < 3; state++) {
  make(`barrel_${state}`, 32, 40, (cv) => {
    if (state < 2) {
      outlined(cv, rrect(16, 21, 28, 34, 8), vgrad(PAL.redTop, PAL.redBot, 40), 2.4);
      for (const y of [10, 21, 32]) {
        outlined(cv, rrect(16, y, 30, 4, 2), solid(PAL.goldDark), 1.2);
      }
      cv.paint(rrect(16, 7, 24, 3, 1.5), withAlpha(WHITE, 0.35));
      // bomb icon
      cv.paint(circle(16, 22, 7), solid(hex('#2A2A33')));
      cv.paint(circle(13.5, 19.5, 2), withAlpha(WHITE, 0.6));
      cv.paint(capsule(20, 16, 24, 12, 1.4), solid(hex('#6E4A22')));
      cv.paint(circle(25, 11, 1.6), solid(PAL.goldTop));
      if (state === 1) {
        cv.paint(capsule(7, 10, 12, 22, 1), withAlpha(hex('#3A0D08'), 0.7));
        cv.paint(capsule(24, 14, 21, 26, 1), withAlpha(hex('#3A0D08'), 0.6));
      }
    } else {
      for (const [x, y, w, h] of [[10, 30, 12, 6], [22, 28, 10, 8], [16, 12, 9, 5]]) {
        outlined(cv, rrect(x, y, w, h, 2), vgrad(PAL.redTop, PAL.redBot, 40), 1.2);
      }
      cv.paint(ellipse(16, 36, 12, 3), withAlpha(hex('#1A0B06'), 0.5));
    }
  });
}

// cart platform + wheels
make('castle_platform', 340, 58, (cv) => {
  outlined(cv, rrect(170, 30, 330, 40, 10), vgrad(PAL.steelTop, PAL.steelBot, 58), 3);
  outlined(cv, rrect(170, 12, 330, 16, 6), vgrad(PAL.woodTop, PAL.woodBot, 58), 3);
  cv.paint(rrect(170, 9, 300, 4, 2), withAlpha(WHITE, 0.35));
  for (const x of [50, 170, 290]) {
    cv.paint(rrect(x, 30, 46, 24, 4), solid(PAL.steelDark));
    cv.paint(circle(x, 30, 3), solid(PAL.steelTop));
  }
  cv.paint(rrect(170, 50, 300, 5, 2.5), solid(PAL.blueBot));
});
make('wheel', 58, 58, (cv) => {
  outlined(cv, circle(29, 29, 27), solid(hex('#2B3242')), 3);
  outlined(cv, circle(29, 29, 19), vgrad(PAL.woodTop, PAL.woodBot, 58), 2);
  for (let i = 0; i < 6; i++) {
    const a = i * Math.PI / 3;
    cv.paint(capsule(29 + Math.cos(a) * 5, 29 + Math.sin(a) * 5, 29 + Math.cos(a) * 17, 29 + Math.sin(a) * 17, 2), solid(PAL.woodDark));
  }
  outlined(cv, circle(29, 29, 6), solid(PAL.goldBot), 2);
});
make('flag', 30, 40, (cv) => {
  outlined(cv, capsule(6, 6, 6, 36, 2.2), solid(PAL.steelDark), 1.6);
  const flag = poly([[8, 8], [28, 13], [8, 22]]);
  outlined(cv, flag, vgrad(PAL.redTop, PAL.redBot, 40), 2);
  cv.paint(circle(14, 14, 2.4), solid(PAL.goldTop));
});

// ---------------------------------------------------------------- units
function drawBody(cv, cx, cy, color) {
  // feet
  outlined(cv, ellipse(cx - 7, cy + 16, 6, 4.5), solid(color), 2);
  outlined(cv, ellipse(cx + 7, cy + 16, 6, 4.5), solid(color), 2);
  // body
  outlined(cv, ellipse(cx, cy, 16, 17), vgrad(
    [Math.min(1, color[0] + 0.18), Math.min(1, color[1] + 0.18), Math.min(1, color[2] + 0.18), 1],
    [color[0] * 0.78, color[1] * 0.78, color[2] * 0.82, 1], 48), 2.6);
  cv.paint(ellipse(cx - 6, cy - 8, 5, 3), withAlpha(WHITE, 0.55));
}

function drawEyes(cv, cx, cy, state) {
  const sclera = (x, y, rx, ry) => {
    outlined(cv, ellipse(x, y, rx, ry), solid(WHITE), 1.4);
  };
  if (state === 'idle' || state === 'scared') {
    const big = state === 'scared' ? 1.12 : 1;
    sclera(cx - 6, cy, 5.2 * big, 5.8 * big);
    sclera(cx + 6, cy, 5.2 * big, 5.8 * big);
    const pr = state === 'scared' ? 1.5 : 2.4;
    const py = state === 'scared' ? cy - 1.4 : cy;
    cv.paint(circle(cx - 5.2, py, pr), solid(OUTLINE));
    cv.paint(circle(cx + 6.8, py, pr), solid(OUTLINE));
    cv.paint(circle(cx - 6, py - 1.4, 0.9), solid(WHITE));
    cv.paint(circle(cx + 6, py - 1.4, 0.9), solid(WHITE));
    if (state === 'scared') {
      cv.paint(capsule(cx - 11, cy - 9, cx - 3, cy - 11, 0.9), solid(OUTLINE));
      cv.paint(capsule(cx + 3, cy - 11, cx + 11, cy - 9, 0.9), solid(OUTLINE));
    }
  } else if (state === 'happy') {
    sclera(cx - 6, cy, 5.2, 5.6);
    sclera(cx + 6, cy, 5.2, 5.6);
    cv.paint(capsule(cx - 9, cy + 1, cx - 3, cy + 1, 1.2), solid(OUTLINE));
    cv.paint(capsule(cx + 3, cy + 1, cx + 9, cy + 1, 1.2), solid(OUTLINE));
    cv.paint(capsule(cx - 9, cy + 1, cx - 8, cy - 1, 1.1), solid(OUTLINE));
    cv.paint(capsule(cx + 8, cy - 1, cx + 9, cy + 1, 1.1), solid(OUTLINE));
  } else if (state === 'dead') {
    sclera(cx - 6, cy, 5.4, 5.4);
    sclera(cx + 6, cy, 5.4, 5.4);
    for (const sx of [-1, 1]) {
      const ex = cx + sx * 6;
      cv.paint(capsule(ex - 3, cy - 3, ex + 3, cy + 3, 1.1), solid(OUTLINE));
      cv.paint(capsule(ex - 3, cy + 3, ex + 3, cy - 3, 1.1), solid(OUTLINE));
    }
  }
}

const STEEL = vgrad(PAL.steelTop, PAL.steelBot, 48);
const WOOD = vgrad(PAL.woodTop, PAL.woodBot, 48);

function drawGear(cv, id) {
  const cx = 24, cy = 24;
  switch (id) {
    case 'bombardier': {
      outlined(cv, ellipse(cx, cy - 15, 11, 8), STEEL, 2);
      outlined(cv, rrect(cx, cy - 10, 24, 5, 2.5), solid(PAL.steelDark), 1.5);
      cv.paint(circle(cx, cy - 18, 3), solid(PAL.goldBot));
      outlined(cv, circle(cx + 18, cy + 10, 7), solid(hex('#2A2A33')), 2);
      cv.paint(circle(cx + 16, cy + 8, 1.8), withAlpha(WHITE, 0.7));
      cv.paint(capsule(cx + 22, cy + 5, cx + 25, cy + 1, 1.2), solid(hex('#6E4A22')));
      cv.paint(circle(cx + 26, cy, 1.5), solid(PAL.goldTop));
      cv.paint(circle(cx + 14, cy + 8, 3), solid(PAL.glove));
      break;
    }
    case 'triplet': {
      outlined(cv, ellipse(cx, cy - 14, 10, 8), STEEL, 2);
      outlined(cv, capsule(cx - 9, cy - 16, cx - 17, cy - 24, 3), solid(PAL.cream), 1.8);
      outlined(cv, capsule(cx + 9, cy - 16, cx + 17, cy - 24, 3), solid(PAL.cream), 1.8);
      cv.paint(circle(cx + 18, cy + 10, 4.2), solid(hex('#2A2A33')));
      cv.paint(circle(cx + 12, cy + 14, 4.2), solid(hex('#2A2A33')));
      cv.paint(circle(cx + 18, cy + 14, 4.2), solid(hex('#2A2A33')));
      cv.paint(circle(cx + 16.4, cy + 8.4, 1.2), withAlpha(WHITE, 0.6));
      break;
    }
    case 'driller': {
      outlined(cv, ellipse(cx, cy - 14, 11, 8), vgrad(PAL.goldTop, PAL.goldBot, 48), 2);
      outlined(cv, rrect(cx, cy - 9, 25, 4, 2), solid(PAL.goldDark), 1.2);
      outlined(cv, poly([[cx + 14, cy + 9], [cx + 30, cy + 13], [cx + 14, cy + 17]]), STEEL, 1.8);
      cv.paint(rrect(cx + 9, cy + 13, 9, 6, 2), solid(PAL.goldBot));
      cv.paint(circle(cx + 13, cy + 9, 2.6), solid(PAL.glove));
      break;
    }
    case 'sniper': {
      outlined(cv, ellipse(cx, cy - 14, 10, 7), solid(hex('#3C5A3A')), 2);
      outlined(cv, capsule(cx - 10, cy - 12, cx + 10, cy - 12, 2.2), solid(hex('#2C442B')), 1.4);
      outlined(cv, capsule(cx + 14, cy + 8, cx + 30, cy + 4, 2), solid(PAL.steelDark), 1.6);
      outlined(cv, rrect(cx + 22, cy + 2, 8, 3, 1), solid(PAL.goldBot), 1);
      cv.paint(circle(cx + 14, cy + 10, 2.6), solid(PAL.glove));
      break;
    }
    case 'pyro': {
      const flame = poly([
        [cx - 12, cy - 16], [cx - 4, cy - 26], [cx - 2, cy - 18],
        [cx + 6, cy - 27], [cx + 8, cy - 16], [cx + 13, cy - 10],
        [cx + 8, cy - 5], [cx - 8, cy - 5], [cx - 13, cy - 10],
      ]);
      outlined(cv, flame, vgrad(PAL.goldTop, PAL.orange, 48), 2);
      cv.paint(circle(cx + 1, cy - 11, 4), solid(PAL.orangeDark));
      outlined(cv, rrect(cx + 18, cy + 11, 8, 12, 3), solid(hex('#55B36A')), 1.6);
      cv.paint(capsule(cx + 18, cy + 4, cx + 21, cy - 1, 1.2), solid(PAL.cream));
      cv.paint(circle(cx + 22, cy - 2, 1.8), solid(PAL.goldTop));
      cv.paint(circle(cx + 14, cy + 10, 2.6), solid(PAL.glove));
      break;
    }
    case 'barrel': {
      outlined(cv, rrect(cx, cy + 10, 32, 22, 7), WOOD, 2.2);
      for (const y of [cy + 2, cy + 10, cy + 18]) {
        outlined(cv, rrect(cx, y, 34, 3.4, 1.6), solid(PAL.steelDark), 1);
      }
      cv.paint(rrect(cx, cy + 3, 26, 2.5, 1), withAlpha(WHITE, 0.35));
      cv.paint(circle(cx - 15, cy + 8, 3), solid(PAL.glove));
      cv.paint(circle(cx + 15, cy + 8, 3), solid(PAL.glove));
      break;
    }
    case 'tank': {
      outlined(cv, ellipse(cx, cy - 14, 11, 8), STEEL, 2);
      outlined(cv, rrect(cx, cy - 8, 22, 4, 2), solid(PAL.steelDark), 1.2);
      outlined(cv, rrect(cx - 17, cy + 8, 13, 20, 5), vgrad(PAL.steelTop, PAL.steelBot, 48), 2);
      cv.paint(circle(cx - 17, cy + 8, 2.2), solid(PAL.goldBot));
      cv.paint(capsule(cx - 17, cy + 2, cx - 17, cy + 14, 0.9), solid(PAL.steelDark));
      break;
    }
    case 'engineer': {
      outlined(cv, ellipse(cx, cy - 14, 10, 7), vgrad(PAL.blueTop, PAL.blueBot, 48), 2);
      outlined(cv, rrect(cx + 2, cy - 10, 16, 4, 2), solid(PAL.blueDark), 1.2);
      outlined(cv, capsule(cx + 16, cy + 10, cx + 28, cy + 2, 2), solid(PAL.steelTop), 1.6);
      outlined(cv, arcShape(cx + 29, cy + 1, 4.5, 3, -1.2, 1.9), solid(PAL.steelTop), 1.2);
      cv.paint(circle(cx + 14, cy + 11, 2.6), solid(PAL.glove));
      break;
    }
  }
}

make('unit_body', 48, 48, (cv) => drawBody(cv, 24, 24, [1, 1, 1]));
for (const id of ['bombardier', 'triplet', 'driller', 'sniper', 'pyro', 'barrel', 'tank', 'engineer']) {
  make(`gear_${id}`, 48, 48, (cv) => drawGear(cv, id));
}
for (const state of ['idle', 'scared', 'happy', 'dead']) {
  make(`eyes_${state}`, 32, 16, (cv) => drawEyes(cv, 16, 8, state));
}

// portraits (HUD) - body baked blue
function makePortrait(id) {
  const tmp = new Canvas(48, 48);
  drawBody(tmp, 24, 24, PAL.blueBot);
  drawGear(tmp, id);
  drawEyes(tmp, 24, 26, 'idle');
  const out = new Canvas(64, 64);
  for (let y = 0; y < 64; y++) {
    for (let x = 0; x < 64; x++) {
      const sx = clamp((x - 8) / 1.2, 0, 47);
      const sy = clamp((y - 8) / 1.2, 0, 47);
      const i = (Math.floor(sy) * 48 + Math.floor(sx)) * 4;
      tmp.px[i + 3] && out.blend(x, y, tmp.px[i], tmp.px[i + 1], tmp.px[i + 2], tmp.px[i + 3]);
    }
  }
  sprites.push({ name: `portrait_${id}`, w: 64, h: 64, cv: out });
}
for (const id of ['bombardier', 'triplet', 'driller', 'sniper', 'pyro', 'barrel', 'tank', 'engineer']) {
  makePortrait(id);
}

// ---------------------------------------------------------------- projectiles
make('proj_bomb', 28, 28, (cv) => {
  outlined(cv, circle(13, 15, 9), solid(hex('#2E2A33')), 2.2);
  cv.paint(circle(10, 12, 3), withAlpha(WHITE, 0.5));
  cv.paint(capsule(18, 8, 23, 3, 1.6), solid(hex('#6E4A22')));
  cv.paint(circle(24, 2, 2.2), solid(PAL.goldTop));
  cv.paint(circle(24, 2, 1), solid(WHITE));
});
make('proj_pellet', 14, 14, (cv) => {
  outlined(cv, circle(7, 7, 5), solid(hex('#2E2A33')), 1.8);
  cv.paint(circle(5.5, 5.5, 1.5), withAlpha(WHITE, 0.6));
});
make('proj_drill', 40, 18, (cv) => {
  outlined(cv, rrect(16, 9, 22, 12, 4), vgrad(PAL.steelTop, PAL.steelBot, 18), 2);
  outlined(cv, poly([[26, 3], [38, 9], [26, 15]]), solid(PAL.goldTop), 1.8);
  cv.paint(rrect(7, 9, 6, 12, 2), solid(PAL.goldBot));
  cv.paint(circle(9, 9, 2), solid(PAL.steelDark));
  cv.paint(capsule(14, 3, 14, 15, 2), solid(PAL.orange));
});
make('proj_laser', 34, 10, (cv) => {
  outlined(cv, capsule(4, 5, 30, 5, 3.2), solid(PAL.redTop), 1.6);
  cv.paint(capsule(8, 5, 26, 5, 1.6), solid(hex('#FFE6E0')));
});
make('proj_molotov', 22, 32, (cv) => {
  outlined(cv, rrect(11, 19, 14, 18, 5), solid(hex('#4FA86A')), 2);
  cv.paint(rrect(11, 16, 6, 7, 2), solid(hex('#2F6B40')));
  cv.paint(capsule(12, 13, 14, 6, 2), solid(PAL.cream));
  outlined(cv, poly([[14, 8], [19, 2], [18, 8], [22, 5], [20, 11]]), solid(PAL.orange), 1.2);
  cv.paint(rrect(9, 24, 7, 4, 1.5), withAlpha(WHITE, 0.4));
});
make('proj_barrel', 30, 32, (cv) => {
  outlined(cv, rrect(15, 16, 26, 28, 7), vgrad(PAL.woodTop, PAL.woodBot, 32), 2.2);
  for (const y of [8, 16, 24]) outlined(cv, rrect(15, y, 28, 3, 1.4), solid(PAL.steelDark), 1);
  cv.paint(rrect(15, 5, 20, 2.5, 1), withAlpha(WHITE, 0.35));
});
make('proj_orb', 28, 28, (cv) => {
  outlined(cv, circle(14, 14, 10), vgrad(PAL.cyan, PAL.purple), 2.2);
  cv.paint(ring(14, 14, 7, 1.6), withAlpha(WHITE, 0.8));
  cv.paint(circle(10, 10, 2.6), withAlpha(WHITE, 0.8));
});
make('proj_hammer', 26, 26, (cv) => {
  outlined(cv, rrect(13, 8, 20, 9, 3), vgrad(PAL.steelTop, PAL.steelBot, 26), 2);
  outlined(cv, capsule(13, 14, 13, 23, 2.2), solid(PAL.woodBot), 1.6);
  cv.paint(rrect(13, 5, 12, 3, 1.2), withAlpha(WHITE, 0.4));
});

// ---------------------------------------------------------------- gates
const GATE_COLORS = {
  x2: [PAL.goldTop, PAL.goldBot],
  x3: [PAL.goldTop, PAL.goldBot],
  fire: [hex('#FFC14D'), PAL.orange],
  giant: [hex('#C9A6FF'), PAL.purple],
  pierce: [PAL.steelTop, PAL.steelBot],
  speed: [hex('#A6F0A0'), PAL.green],
};

for (const key of Object.keys(GATE_COLORS)) {
  const [top, bot] = GATE_COLORS[key];
  make(`gate_${key}`, 96, 96, (cv) => {
    outlined(cv, ring(48, 48, 38, 11), vgrad(top, bot, 96), 3);
    cv.paint(arcShape(48, 48, 38, 3.5, -2.6, -1.6), withAlpha(WHITE, 0.65));
    for (let i = 0; i < 3; i++) {
      const a = -0.6 + i * 1.1;
      const x = 48 + Math.cos(a) * 50;
      const y = 48 + Math.sin(a) * 50;
      outlined(cv, starShape(x, y, 4, 1.8, 4), solid(PAL.goldTop), 1);
    }
  });
}

function drawX(cv, cx, cy, size, color, lw) {
  cv.paint(capsule(cx - size, cy - size, cx + size, cy + size, lw), solid(color));
  cv.paint(capsule(cx - size, cy + size, cx + size, cy - size, lw), solid(color));
}
function drawDigit(cv, cx, cy, digit, color, scale = 1) {
  const r = 7 * scale;
  const lw = 2.2 * scale;
  if (digit === '2') {
    cv.paint(arcShape(cx, cy - 5 * scale, r, lw * 2, -2.5, 0.6), solid(color));
    cv.paint(capsule(cx + 6 * scale, cy - 2 * scale, cx - 6 * scale, cy + 8 * scale, lw), solid(color));
    cv.paint(capsule(cx - 7 * scale, cy + 9 * scale, cx + 7 * scale, cy + 9 * scale, lw), solid(color));
  } else if (digit === '3') {
    cv.paint(arcShape(cx, cy - 5 * scale, r, lw * 2, -2.4, 0.4), solid(color));
    cv.paint(arcShape(cx, cy + 5 * scale, r, lw * 2, -1.4, 1.4), solid(color));
  }
}

function balloon(key, label) {
  make(`balloon_${key}`, 46, 60, (cv) => {
    const [top, bot] = GATE_COLORS[key] || [PAL.goldTop, PAL.goldBot];
    outlined(cv, ellipse(23, 24, 18, 21), vgrad(top, bot, 60), 2.4);
    cv.paint(ellipse(16, 15, 5, 7), withAlpha(WHITE, 0.55));
    outlined(cv, poly([[18, 44], [28, 44], [23, 52]]), solid(bot), 1.6);
    cv.paint(capsule(23, 51, 23, 58, 0.8), solid(OUTLINE));
    if (label === 'x2' || label === 'x3') {
      drawX(cv, 17, 25, 5.2, OUTLINE, 2.4);
      drawX(cv, 17, 25, 3.9, WHITE, 1.6);
      drawDigit(cv, 28, 24, label === 'x2' ? '2' : '3', OUTLINE, 1.55);
      drawDigit(cv, 28, 24, label === 'x2' ? '2' : '3', WHITE, 1.15);
    } else if (label === 'fire') {
      outlined(cv, poly([[23, 10], [30, 20], [26, 19], [30, 30], [22, 26], [16, 32], [16, 20], [20, 21], [18, 13]]), solid(PAL.orange), 1.4);
      cv.paint(circle(23, 24, 4), solid(PAL.goldTop));
    } else if (label === 'giant') {
      cv.paint(capsule(23, 33, 23, 17, 3), solid(OUTLINE));
      cv.paint(poly([[23, 9], [33, 21], [13, 21]]), solid(OUTLINE));
      cv.paint(capsule(23, 31, 23, 18, 1.8), solid(WHITE));
      cv.paint(poly([[23, 11], [31, 20], [15, 20]]), solid(WHITE));
    } else if (label === 'pierce') {
      outlined(cv, poly([[23, 9], [33, 30], [23, 26], [13, 30]]), solid(PAL.steelTop), 1.8);
      cv.paint(capsule(23, 12, 23, 28, 1.2), solid(WHITE));
    } else if (label === 'speed') {
      for (const dx of [-5, 3]) {
        cv.paint(capsule(23 + dx, 14, 15 + dx, 23, 2.4), solid(OUTLINE));
        cv.paint(capsule(15 + dx, 23, 23 + dx, 32, 2.4), solid(OUTLINE));
      }
      cv.paint(capsule(20, 14, 12, 23, 1.2), solid(WHITE));
      cv.paint(capsule(12, 23, 20, 32, 1.2), solid(WHITE));
    }
  });
}
balloon('x2', 'x2');
balloon('x3', 'x3');
balloon('fire', 'fire');
balloon('giant', 'giant');
balloon('pierce', 'pierce');
balloon('speed', 'speed');

// ---------------------------------------------------------------- fx
make('fx_burst', 96, 96, (cv) => {
  outlined(cv, starShape(48, 48, 40, 22, 11), vgrad(PAL.goldTop, PAL.orange, 96), 3, PAL.orangeDark);
  outlined(cv, starShape(48, 48, 26, 15, 8), solid(PAL.goldTop), 2, PAL.orangeDark);
  cv.paint(circle(48, 48, 12), solid(WHITE));
  for (let i = 0; i < 6; i++) {
    const a = i * Math.PI / 3 + 0.3;
    const x = 48 + Math.cos(a) * 33;
    const y = 48 + Math.sin(a) * 33;
    cv.paint(circle(x, y, 6), withAlpha(WHITE, 0.85));
  }
});
make('fx_smoke', 44, 44, (cv) => {
  for (const [x, y, r] of [[20, 24, 12], [30, 20, 10], [26, 30, 9]]) {
    cv.paint(circle(x, y, r), withAlpha(hex('#E8EEF5'), 0.55));
  }
  cv.paint(circle(22, 18, 5), withAlpha(WHITE, 0.8));
});
make('fx_dust', 40, 40, (cv) => {
  cv.paint(ellipse(20, 24, 17, 10), withAlpha(hex('#D8C8A8'), 0.7));
  cv.paint(ellipse(16, 18, 8, 5), withAlpha(WHITE, 0.6));
});
make('fx_spark', 12, 12, (cv) => {
  cv.paint(starShape(6, 6, 5.5, 1.8, 4), solid(PAL.goldTop));
  cv.paint(circle(6, 6, 1.6), solid(WHITE));
});
make('fx_star', 18, 18, (cv) => {
  outlined(cv, starShape(9, 9, 8, 3.6, 5), solid(PAL.goldTop), 1.2);
  cv.paint(circle(9, 9, 1.5), withAlpha(WHITE, 0.8));
});
make('fx_confetti', 12, 12, (cv) => {
  outlined(cv, rrect(6, 6, 9, 5, 1.5), solid(PAL.goldTop), 1);
});
make('fx_ring', 64, 64, (cv) => {
  cv.paint(ring(32, 32, 26, 4), withAlpha(WHITE, 0.9));
  cv.paint(ring(32, 32, 20, 2), withAlpha(PAL.goldTop, 0.7));
});
make('fx_glow', 64, 64, (cv) => {
  for (let r = 30; r > 0; r -= 1) {
    cv.paint(circle(32, 32, r), withAlpha(PAL.goldTop, 0.035));
  }
});
make('fx_dot', 10, 10, (cv) => {
  outlined(cv, circle(5, 5, 3.4), solid(WHITE), 1.1, hex('#7FA8C9'));
});
make('fx_shadow', 54, 14, (cv) => {
  cv.paint(ellipse(27, 7, 25, 5), withAlpha(hex('#0A0F1A'), 0.32));
});
make('fx_cloud', 170, 70, (cv) => {
  for (const [x, y, r] of [[45, 42, 26], [80, 34, 30], [120, 42, 24], [145, 46, 18]]) {
    cv.paint(circle(x, y, r), withAlpha(WHITE, 0.95));
  }
  cv.paint(ellipse(85, 56, 70, 12), withAlpha(WHITE, 0.95));
});
make('fx_hand', 44, 52, (cv) => {
  outlined(cv, rrect(22, 34, 24, 22, 8), solid(PAL.skin), 2.4);
  for (let i = 0; i < 4; i++) {
    outlined(cv, capsule(13 + i * 6, 28, 13 + i * 6, 14 - Math.abs(1.5 - i) * 2, 3), solid(PAL.skin), 1.8);
  }
  outlined(cv, capsule(9, 38, 4, 30, 3), solid(PAL.skin), 1.8);
});
for (const [name, colors] of [
  ['wood', MATS.wood], ['stone', MATS.stone], ['steel', MATS.steel],
  ['brick', MATS.brick], ['blue', MATS.blue], ['red', MATS.red],
]) {
  make(`fx_shard_${name}`, 14, 14, (cv) => {
    const pts = [[3, 4], [11, 2], [12, 10], [5, 12]];
    outlined(cv, poly(pts), vgrad(colors[0], colors[1], 14), 1.2);
  });
}

make('grass_tuft', 30, 18, (cv) => {
  for (const [x, h] of [[6, 10], [12, 15], [18, 12], [24, 8]]) {
    cv.paint(capsule(x, 18, x - 2, 18 - h, 1.7), solid(PAL.grassDark));
    cv.paint(capsule(x + 1, 18, x, 18 - h + 2, 0.8), solid(PAL.grass));
  }
});
make('flower', 16, 18, (cv) => {
  cv.paint(capsule(8, 8, 8, 16, 1), solid(PAL.grassDark));
  for (let i = 0; i < 5; i++) {
    const a = i * Math.PI * 2 / 5 + 0.3;
    cv.paint(circle(8 + Math.cos(a) * 3.4, 7 + Math.sin(a) * 3.4, 2.8), solid(hex('#FFD9E8')));
  }
  cv.paint(circle(8, 7, 2.2), solid(PAL.goldBot));
});
make('bg_bird', 20, 10, (cv) => {
  cv.paint(capsule(2, 7, 8, 2, 1.1), solid(hex('#3A4A5E')));
  cv.paint(capsule(8, 2, 14, 7, 1.1), solid(hex('#3A4A5E')));
});
// ---------------------------------------------------------------- background
make('white_pixel', 16, 16, (cv) => {
  cv.paint(rrect(8, 8, 16, 16, 0), solid(WHITE));
});
make('circle', 32, 32, (cv) => {
  cv.paint(circle(16, 16, 16), solid(WHITE));
});
make('room_dark', 78, 58, (cv) => {
  outlined(cv, rrect(39, 29, 76, 56, 9), solid(hex('#2E1D14')), 2);
  cv.paint(rrect(39, 21, 66, 30, 6), withAlpha(hex('#1E120C'), 0.9));
  cv.paint(rrect(39, 47, 66, 10, 4), solid(hex('#6B4526')));
  cv.paint(rrect(39, 42, 60, 3, 1.5), solid(hex('#8A5E38')));
  cv.paint(rrect(39, 12, 52, 2, 1), withAlpha(WHITE, 0.10));
});
make('post_wood', 18, 92, (cv) => {
  outlined(cv, rrect(9, 46, 16, 90, 4), vgrad(PAL.woodTop, PAL.woodBot, 92), 2);
  cv.paint(capsule(6, 10, 6, 82, 1), withAlpha(PAL.woodDark, 0.5));
  cv.paint(capsule(12, 12, 12, 80, 1), withAlpha(WHITE, 0.18));
  cv.paint(circle(9, 8, 2.2), solid(PAL.steelDark));
  cv.paint(circle(9, 84, 2.2), solid(PAL.steelDark));
});
make('door', 56, 72, (cv) => {
  outlined(cv, rrect(28, 38, 50, 64, 8), vgrad(PAL.woodTop, PAL.woodBot, 72), 2.6);
  cv.paint(rrect(28, 40, 38, 46, 8), solid(hex('#241610')));
  cv.paint(rrect(28, 20, 32, 6, 3), solid(hex('#1A0F0A')));
  cv.paint(circle(40, 38, 2.4), solid(PAL.goldTop));
  cv.paint(capsule(28, 10, 28, 32, 1), withAlpha(PAL.woodDark, 0.6));
  cv.paint(rrect(28, 66, 34, 3, 1.5), withAlpha(WHITE, 0.3));
});

make('bg_gradient', 8, 256, (cv) => {
  for (let y = 0; y < 256; y++) {
    const t = y / 255;
    const a = Math.pow(t, 1.1);
    for (let x = 0; x < 8; x++) cv.blend(x, y, 1, 1, 1, a);
  }
});

function hills(name, w, h, baseY, amp, phase) {
  make(name, w, h, (cv) => {
    const pts = [[0, h]];
    for (let x = 0; x <= w; x += 20) {
      const y = baseY
        + Math.sin(x * 0.004 + phase) * amp
        + Math.sin(x * 0.011 + phase * 2.3) * amp * 0.35
        + Math.sin(x * 0.025 + 1.7) * amp * 0.12;
      pts.push([x, y]);
    }
    pts.push([w, h]);
    cv.paint(poly(pts), vgrad(WHITE, [0.75, 0.75, 0.75, 1], h));
  });
}
hills('bg_hills_far', 1800, 260, 120, 34, 0.8);
hills('bg_hills_near', 1800, 190, 76, 26, 2.1);

// ---------------------------------------------------------------- UI
make('ui_panel', 64, 64, (cv) => {
  outlined(cv, rrect(32, 32, 60, 60, 14), vgrad(PAL.cream, PAL.creamDark, 64), 3);
  cv.paint(rrect(32, 10, 48, 4, 2), withAlpha(WHITE, 0.5));
});
for (const [name, top, bot] of [
  ['gold', PAL.goldTop, PAL.goldBot],
  ['blue', PAL.blueTop, PAL.blueBot],
  ['red', PAL.redTop, PAL.redBot],
  ['green', PAL.green, PAL.greenDark],
  ['dark', hex('#39445A'), hex('#222A38')],
]) {
  make(`ui_btn_${name}`, 48, 48, (cv) => {
    outlined(cv, rrect(24, 24, 44, 44, 12), vgrad(top, bot, 48), 3);
    cv.paint(rrect(24, 8, 32, 4, 2), withAlpha(WHITE, 0.45));
    cv.paint(rrect(24, 40, 32, 3, 1.5), withAlpha([0, 0, 0, 1], 0.18));
  });
}
make('ui_pill', 36, 36, (cv) => {
  outlined(cv, rrect(18, 18, 32, 32, 14), vgrad(PAL.cream, PAL.creamDark, 36), 2.6);
});
make('ui_bar_bg', 16, 16, (cv) => {
  outlined(cv, rrect(8, 8, 16, 16, 6), solid(hex('#2A3346')), 1.6);
});
make('ui_bar_fill', 16, 16, (cv) => {
  outlined(cv, rrect(8, 8, 16, 16, 6), vgrad(PAL.green, PAL.greenDark, 16), 1.4);
});
make('ui_heart', 26, 26, (cv) => {
  outlined(cv, circle(9, 9, 6), solid(PAL.redTop), 2);
  outlined(cv, circle(17, 9, 6), solid(PAL.redTop), 2);
  outlined(cv, poly([[3, 11], [23, 11], [13, 22]]), solid(PAL.redTop), 2);
});
make('ui_coin', 26, 26, (cv) => {
  outlined(cv, circle(13, 13, 10), vgrad(PAL.goldTop, PAL.goldBot, 26), 2);
  cv.paint(circle(13, 13, 6), solid(PAL.goldDark));
  cv.paint(starShape(13, 13, 4.5, 2, 5), solid(PAL.goldTop));
});
make('ui_pause', 26, 26, (cv) => {
  outlined(cv, rrect(8, 13, 6, 16, 3), solid(WHITE), 1.6);
  outlined(cv, rrect(18, 13, 6, 16, 3), solid(WHITE), 1.6);
});
make('ui_lock', 22, 22, (cv) => {
  outlined(cv, rrect(11, 14, 16, 12, 4), solid(PAL.goldBot), 2);
  outlined(cv, ring(11, 9, 5, 3), solid(PAL.steelTop), 1.6);
});
make('ui_check', 22, 22, (cv) => {
  outlined(cv, capsule(4, 11, 9, 17, 2.2), solid(PAL.green), 1.6);
  outlined(cv, capsule(9, 17, 18, 5, 2.2), solid(PAL.green), 1.6);
});
make('ui_star', 22, 22, (cv) => {
  outlined(cv, starShape(11, 11, 9, 4, 5), solid(PAL.goldTop), 1.6);
});
make('ui_card', 76, 100, (cv) => {
  outlined(cv, rrect(38, 50, 72, 96, 12), vgrad(PAL.cream, PAL.creamDark, 100), 3);
  cv.paint(rrect(38, 16, 64, 22, 8), vgrad(PAL.blueTop, PAL.blueBot, 100));
  cv.paint(rrect(38, 50, 58, 4, 2), withAlpha(WHITE, 0.4));
});
make('ui_arrow_left', 26, 26, (cv) => {
  outlined(cv, poly([[17, 4], [9, 13], [17, 22]]), solid(WHITE), 2.2);
});
make('ui_arrow_right', 26, 26, (cv) => {
  outlined(cv, poly([[9, 4], [17, 13], [9, 22]]), solid(WHITE), 2.2);
});

// ---------------------------------------------------------------- output
fs.mkdirSync(ART, { recursive: true });
fs.mkdirSync(path.dirname(SHEET), { recursive: true });

for (const s of sprites) {
  savePNG(path.join(ART, `${s.name}.png`), s.w, s.h, s.cv.toRGBA());
}

// atlas
const atlasLines = ['images {'];
for (const s of sprites) {
  atlasLines.push(`  image: "/main/assets/art/${s.name}.png"`);
  atlasLines.push('  sprite_trim_mode: SPRITE_TRIM_MODE_OFF');
  atlasLines.push('}');
  atlasLines.push('images {');
}
atlasLines.pop();
fs.writeFileSync(ATLAS, atlasLines.join('\n') + '\n');

// source sizes for Lua (sprite "size" is not readable right after play_flipbook)
const sizeLines = ['-- generated by tools/gen_sprites.js - do not edit by hand', 'return {'];
for (const s of sprites) {
  sizeLines.push(`\t["${s.name}"] = { ${s.w}, ${s.h} },`);
}
sizeLines.push('}');
fs.writeFileSync(path.join(ROOT, 'lua_modules', 'art_sizes.lua'), sizeLines.join('\n') + '\n');

// contact sheet
const SHEET_W = 1600;
const pad = 14;
let x = pad, y = pad, rowH = 0, maxY = 0;
const placed = [];
for (const s of sprites) {
  const k = Math.min(1, (SHEET_W - pad * 2) / s.w, 240 / s.h);
  const w = Math.max(1, Math.round(s.w * k));
  const h = Math.max(1, Math.round(s.h * k));
  if (x + w + pad > SHEET_W) { x = pad; y += rowH + pad; rowH = 0; }
  placed.push({ s, x, y, w, h });
  x += w + pad;
  rowH = Math.max(rowH, h);
  maxY = Math.max(maxY, y + h);
}
const SHEET_H = maxY + pad;
const sheet = new Canvas(SHEET_W, SHEET_H);
for (let yy = 0; yy < SHEET_H; yy++) {
  for (let xx = 0; xx < SHEET_W; xx++) {
    const checker = (Math.floor(xx / 24) + Math.floor(yy / 24)) % 2 === 0;
    sheet.blend(xx, yy, checker ? 0.12 : 0.15, checker ? 0.15 : 0.19, checker ? 0.22 : 0.27, 1);
  }
}
for (const p of placed) {
  for (let yy = 0; yy < p.h; yy++) {
    for (let xx = 0; xx < p.w; xx++) {
      const sx = Math.min(p.s.w - 1, Math.floor(xx / p.w * p.s.w));
      const sy = Math.min(p.s.h - 1, Math.floor(yy / p.h * p.s.h));
      const i = (sy * p.s.w + sx) * 4;
      const a = p.s.cv.px[i + 3];
      if (a > 0.01) {
        sheet.blend(p.x + xx, p.y + yy, p.s.cv.px[i], p.s.cv.px[i + 1], p.s.cv.px[i + 2], a);
      }
    }
  }
}
savePNG(SHEET, SHEET_W, SHEET_H, sheet.toRGBA());

console.log(`sprites: ${sprites.length}`);
console.log(`output:  ${ART}`);
console.log(`atlas:   ${ATLAS}`);
console.log(`sheet:   ${SHEET}`);


