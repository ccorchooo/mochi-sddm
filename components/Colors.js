.pragma library
// Material You-style tonal scheme generator, built on OKLCH (perceptually
// uniform, so "tone" behaves like Material's HCT tone without the full CAM16).

function _lin(c) { return c <= 0.04045 ? c / 12.92 : Math.pow((c + 0.055) / 1.055, 2.4) }
function _gam(c) { return c <= 0.0031308 ? 12.92 * c : 1.055 * Math.pow(c, 1 / 2.4) - 0.055 }

// r,g,b in 0..1 -> {L, C, H(deg)}
function rgbToOklch(r, g, b) {
    r = _lin(r); g = _lin(g); b = _lin(b)
    var l = Math.cbrt(0.4122214708 * r + 0.5363325363 * g + 0.0514459929 * b)
    var m = Math.cbrt(0.2119034982 * r + 0.6806995451 * g + 0.1073969566 * b)
    var s = Math.cbrt(0.0883024619 * r + 0.2817188376 * g + 0.6299787005 * b)
    var L = 0.2104542553 * l + 0.7936177850 * m - 0.0040720468 * s
    var A = 1.9779984951 * l - 2.4285922050 * m + 0.4505937099 * s
    var B = 0.0259040371 * l + 0.7827717662 * m - 0.8086757660 * s
    var H = Math.atan2(B, A) * 180 / Math.PI
    if (H < 0) H += 360
    return { L: L, C: Math.sqrt(A * A + B * B), H: H }
}

function _oklchToLinear(L, C, H) {
    var h = H * Math.PI / 180
    var a = C * Math.cos(h), b = C * Math.sin(h)
    var l = L + 0.3963377774 * a + 0.2158037573 * b
    var m = L - 0.1055613458 * a - 0.0638541728 * b
    var s = L - 0.0894841775 * a - 1.2914855480 * b
    l = l * l * l; m = m * m * m; s = s * s * s
    return [ 4.0767416621 * l - 3.3077115913 * m + 0.2309699292 * s,
            -1.2684380046 * l + 2.6097574011 * m - 0.3413193965 * s,
            -0.0041960863 * l - 0.7034186147 * m + 1.7076147010 * s]
}

function _inGamut(c) {
    var e = 0.0001
    return c[0] >= -e && c[0] <= 1 + e && c[1] >= -e && c[1] <= 1 + e && c[2] >= -e && c[2] <= 1 + e
}

function _hex(v) {
    var n = Math.round(Math.max(0, Math.min(1, _gam(Math.max(0, v)))) * 255)
    return (n < 16 ? "0" : "") + n.toString(16)
}

// OKLCH -> "#rrggbb", reducing chroma until the color fits in sRGB.
function oklch(L, C, H) {
    L = Math.max(0, Math.min(1, L))
    var c = _oklchToLinear(L, C, H)
    if (!_inGamut(c)) {
        var lo = 0, hi = C
        for (var i = 0; i < 18; i++) {
            var mid = (lo + hi) / 2
            if (_inGamut(_oklchToLinear(L, mid, H))) lo = mid; else hi = mid
        }
        c = _oklchToLinear(L, lo, H)
    }
    return "#" + _hex(c[0]) + _hex(c[1]) + _hex(c[2])
}

// Pick a seed (hue + chroma) from RGBA pixel data, Material "score" style:
// hue histogram weighted by chroma, smoothed, ignoring near-gray/black/white.
function extractSeed(data, count) {
    var r = _extract(data, count, 0.035, 0.18, 0.01)
    if (!r.found) r = _extract(data, count, 0.008, 0.06, 0.002)
    return r
}

function _extract(data, count, minC, minL, minFrac) {
    var bins = 36, w = [], cs = [], hx = [], hy = []
    for (var i = 0; i < bins; i++) { w.push(0); cs.push(0); hx.push(0); hy.push(0) }
    var colorful = 0, total = 0, lum = 0
    for (var p = 0; p < count; p++) {
        var o = p * 4
        if (data[o + 3] < 128) continue
        var c = rgbToOklch(data[o] / 255, data[o + 1] / 255, data[o + 2] / 255)
        total++
        lum += c.L
        if (c.C < minC || c.L < minL || c.L > 0.94) continue
        colorful++
        var bi = Math.floor(c.H / (360 / bins)) % bins
        var wt = c.C * c.C
        w[bi] += wt; cs[bi] += c.C * wt
        var hr = c.H * Math.PI / 180
        hx[bi] += Math.cos(hr) * wt; hy[bi] += Math.sin(hr) * wt
    }
    var best = -1, bestScore = 0
    for (var j = 0; j < bins; j++) {
        var sc = w[j] + 0.5 * (w[(j + 1) % bins] + w[(j + bins - 1) % bins])
        if (sc > bestScore) { bestScore = sc; best = j }
    }
    var res = { hue: 255, chroma: 0.02, luminance: total ? lum / total : 0.5, found: false }
    if (best < 0 || total === 0 || colorful / total < minFrac) return res
    var X = 0, Y = 0, W = 0, CS = 0
    for (var k = -1; k <= 1; k++) {
        var b = (best + k + bins) % bins
        X += hx[b]; Y += hy[b]; W += w[b]; CS += cs[b]
    }
    var hue = Math.atan2(Y, X) * 180 / Math.PI
    if (hue < 0) hue += 360
    res.hue = hue
    res.chroma = W > 0 ? CS / W : 0.08
    res.found = true
    return res
}

function seedFromColor(col) {
    var c = rgbToOklch(col.r, col.g, col.b)
    return { hue: c.H, chroma: c.C, found: true }
}

function _clamp(v, a, b) { return Math.max(a, Math.min(b, v)) }

// Chroma/hue recipe per variant (mirrors Material's scheme variants).
function _recipe(h, c, variant) {
    var gray = c < 0.025
    switch (variant) {
    case "vibrant":
        return { ph: h, pc: gray ? c : _clamp(c * 1.3, 0.14, 0.2), sh: h + 15, sc: 0.07, th: h + 45, tc: 0.1, nh: h, nc: 0.014, nvc: 0.026 }
    case "expressive":
        return { ph: h + 240, pc: gray ? c : 0.14, sh: h + 15, sc: 0.06, th: h + 120, tc: 0.1, nh: h + 15, nc: 0.02, nvc: 0.032 }
    case "fidelity":
        return { ph: h, pc: _clamp(c, 0.0, 0.22), sh: h, sc: _clamp(c / 3, 0, 0.06), th: h + 60, tc: _clamp(c / 1.5, 0, 0.12), nh: h, nc: _clamp(c / 10, 0, 0.016), nvc: _clamp(c / 6, 0, 0.03) }
    case "neutral":
        return { ph: h, pc: 0.045, sh: h, sc: 0.02, th: h + 60, tc: 0.03, nh: h, nc: 0.004, nvc: 0.01 }
    case "monochrome":
        return { ph: h, pc: 0, sh: h, sc: 0, th: h, tc: 0, nh: h, nc: 0, nvc: 0 }
    default: // tonalspot
        return { ph: h, pc: gray ? c * 2 : _clamp(c, 0.07, 0.125), sh: h, sc: 0.035, th: h + 60, tc: 0.07, nh: h, nc: 0.008, nvc: 0.018 }
    }
}

// L values per role. [dark, light]
var _tones = {
    primary:                 [0.86, 0.50], onPrimary:               [0.28, 1.00],
    primaryContainer:        [0.40, 0.91], onPrimaryContainer:      [0.93, 0.28],
    secondary:               [0.84, 0.50], onSecondary:             [0.28, 1.00],
    secondaryContainer:      [0.38, 0.90], onSecondaryContainer:    [0.92, 0.28],
    tertiary:                [0.85, 0.50], onTertiary:              [0.28, 1.00],
    tertiaryContainer:       [0.40, 0.91], onTertiaryContainer:     [0.93, 0.28],
    surface:                 [0.17, 0.98], surfaceDim:              [0.15, 0.90],
    surfaceContainerLowest:  [0.13, 1.00], surfaceContainerLow:     [0.20, 0.96],
    surfaceContainer:        [0.23, 0.94], surfaceContainerHigh:    [0.27, 0.92],
    surfaceContainerHighest: [0.31, 0.89], onSurface:               [0.93, 0.21],
    onSurfaceVariant:        [0.81, 0.40], outline:                 [0.61, 0.56],
    outlineVariant:          [0.39, 0.82], inverseSurface:          [0.93, 0.27],
    inverseOnSurface:        [0.27, 0.95], inversePrimary:          [0.50, 0.86]
}

function scheme(hue, chroma, variant, mode) {
    var r = _recipe(hue, chroma, variant)
    var t = mode === "light" ? 1 : 0
    var out = {}
    function role(name, H, C) { out[name] = oklch(_tones[name][t], C, H) }
    role("primary", r.ph, r.pc);              role("onPrimary", r.ph, r.pc * 0.8)
    role("primaryContainer", r.ph, r.pc * 0.9); role("onPrimaryContainer", r.ph, r.pc * 0.5)
    role("inversePrimary", r.ph, r.pc)
    role("secondary", r.sh, r.sc);            role("onSecondary", r.sh, r.sc)
    role("secondaryContainer", r.sh, r.sc * 1.2); role("onSecondaryContainer", r.sh, r.sc)
    role("tertiary", r.th, r.tc);             role("onTertiary", r.th, r.tc * 0.8)
    role("tertiaryContainer", r.th, r.tc);    role("onTertiaryContainer", r.th, r.tc * 0.5)
    var nn = ["surface", "surfaceDim", "surfaceContainerLowest", "surfaceContainerLow", "surfaceContainer",
              "surfaceContainerHigh", "surfaceContainerHighest", "onSurface", "inverseSurface", "inverseOnSurface"]
    for (var i = 0; i < nn.length; i++) role(nn[i], r.nh, r.nc)
    role("onSurfaceVariant", r.nh, r.nvc); role("outline", r.nh, r.nvc); role("outlineVariant", r.nh, r.nvc)
    out.error = oklch(t ? 0.52 : 0.80, 0.16, 27)
    out.onError = oklch(t ? 1.0 : 0.30, 0.10, 27)
    out.errorContainer = oklch(t ? 0.91 : 0.40, 0.12, 27)
    out.onErrorContainer = oklch(t ? 0.30 : 0.92, 0.06, 27)
    return out
}
