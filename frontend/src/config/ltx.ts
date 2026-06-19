// LTX Video 2.3 stable aspect / resolution helpers.
// The model itself works great with 16:9 and 9:16 (and documented native resolutions).
// Many Comfy nodes wrapping it (AspectRatioImageSize, various resize nodes) have
// strict client-side validators/dropdowns that only whitelist a subset of ratios.
// Strategy (as recommended by LTX usage research):
//   - Always compute and send explicit width + height (these control the actual
//     EmptyLTXVLatentVideo and pre-process resize nodes).
//   - Dimensions are snapped to multiples of 32 (required/recommended by many LTX flows
//     and the KJ resize node we use).
//   - For widgets that still require a string aspect_ratio, we map the user's choice
//     to a validator-approved value while the numeric w/h win for final output size.

export type LtxRatio =
  | '1:1' | '4:3' | '3:4' | '16:9' | '9:16' | '21:9' | '3:2' | '2:3';

export const LTX_RATIOS: LtxRatio[] = ['1:1', '4:3', '3:4', '16:9', '9:16', '21:9', '3:2', '2:3'];

const BASE_DIMS: Record<LtxRatio, [number, number]> = {
  '1:1': [768, 768],
  '4:3': [1024, 768],
  '3:4': [768, 1024],
  '16:9': [1280, 704],
  '9:16': [704, 1280],
  '21:9': [1344, 576],
  '3:2': [1152, 768],
  '2:3': [768, 1152],
};

// Safe strings accepted by common AspectRatio* nodes (from validator lists observed
// in the wild for LTX wrappers): 1:1, 16:9, 5:4, 4:3, 3:2, 2.39:1, 21:9, 18:9, 17:9, 1.85:1
const SAFE_ASPECT: Record<LtxRatio, string> = {
  '1:1': '1:1',
  '4:3': '4:3',
  '3:4': '4:3',
  '16:9': '16:9',
  '9:16': '16:9',
  '21:9': '21:9',
  '3:2': '3:2',
  '2:3': '3:2',
};

export function getLtxDimensions(ratio: LtxRatio | string) {
  const key = (LTX_RATIOS.includes(ratio as LtxRatio) ? ratio : '16:9') as LtxRatio;
  const [w, h] = BASE_DIMS[key] ?? [1024, 1024];
  const snap = (n: number) => Math.max(32, Math.round(n / 32) * 32);
  return { width: snap(w), height: snap(h) };
}

export function getSafeLtxAspect(ratio: LtxRatio | string): string {
  const key = (LTX_RATIOS.includes(ratio as LtxRatio) ? ratio : '16:9') as LtxRatio;
  return SAFE_ASPECT[key] ?? '16:9';
}

export function getLtxLabel(ratio: LtxRatio | string) {
  const { width, height } = getLtxDimensions(ratio);
  return `${ratio} · ${width}×${height}`;
}
