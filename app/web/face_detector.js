// MediaPipe FaceLandmarker wrapper (ESM, auto-init on script load).
// Sets window.faceDetector = { detect, dispose } when ready.
// Sets window.faceDetectorError = string on init failure.
// detect(video, ts) → { hasFace, ear, yaw, cx, cy, w, h, brightness }

(async () => {
  try {
    const mod = await import('./mediapipe/vision_bundle.mjs');
    const fileset = await mod.FilesetResolver.forVisionTasks('./mediapipe/wasm');
    const landmarker = await mod.FaceLandmarker.createFromOptions(fileset, {
      baseOptions: { modelAssetPath: './mediapipe/face_landmarker.task' },
      runningMode: 'VIDEO',
      numFaces: 1,
      outputFacialTransformationMatrixes: true,
    });

    const L_EYE = [33, 160, 158, 133, 153, 144];
    const R_EYE = [362, 385, 387, 263, 373, 380];

    function earOf(landmarks, eye) {
      const p = eye.map(i => landmarks[i]);
      const d = (a, b) => Math.hypot(a.x - b.x, a.y - b.y);
      return (d(p[1], p[5]) + d(p[2], p[4])) / (2 * d(p[0], p[3]));
    }

    function extractYaw(result) {
      const xs = result.facialTransformationMatrixes;
      if (!xs || xs.length === 0) return 0;
      const m = xs[0].data; // column-major 4x4
      return Math.atan2(m[2], m[10]) * 180 / Math.PI;
    }

    function bboxOf(landmarks) {
      let minX = 1, maxX = 0, minY = 1, maxY = 0;
      for (const lm of landmarks) {
        if (lm.x < minX) minX = lm.x;
        if (lm.x > maxX) maxX = lm.x;
        if (lm.y < minY) minY = lm.y;
        if (lm.y > maxY) maxY = lm.y;
      }
      return { cx: (minX + maxX) / 2, cy: (minY + maxY) / 2, w: maxX - minX, h: maxY - minY };
    }

    let brightnessCanvas = null;
    function sampleBrightness(video) {
      if (!brightnessCanvas) {
        brightnessCanvas = document.createElement('canvas');
        brightnessCanvas.width = 16;
        brightnessCanvas.height = 16;
      }
      const ctx = brightnessCanvas.getContext('2d');
      try {
        ctx.drawImage(video, 0, 0, 16, 16);
        const data = ctx.getImageData(0, 0, 16, 16).data;
        let sum = 0;
        for (let i = 0; i < data.length; i += 4) {
          sum += 0.299 * data[i] + 0.587 * data[i + 1] + 0.114 * data[i + 2];
        }
        return sum / (16 * 16);
      } catch (_) {
        return 128;
      }
    }

    function detect(video, ts) {
      if (!video) return null;
      try {
        const result = landmarker.detectForVideo(video, ts);
        if (!result || !result.faceLandmarks || result.faceLandmarks.length === 0) {
          return { hasFace: false, brightness: sampleBrightness(video) };
        }
        const lm = result.faceLandmarks[0];
        const bbox = bboxOf(lm);
        return {
          hasFace: true,
          ear: (earOf(lm, L_EYE) + earOf(lm, R_EYE)) / 2,
          yaw: extractYaw(result),
          cx: bbox.cx, cy: bbox.cy, w: bbox.w, h: bbox.h,
          brightness: sampleBrightness(video),
        };
      } catch (e) {
        console.error('[faceDetector] detect error', e);
        return { hasFace: false, error: String(e) };
      }
    }

    function dispose() {
      try { landmarker.close(); } catch (_) {}
    }

    window.faceDetector = { detect, dispose };
  } catch (e) {
    console.error('[faceDetector] init failed', e);
    window.faceDetectorError = String(e);
  }
})();
