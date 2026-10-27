/* Presence-only camera check for the web Meetings screen. Opens its own
 * getUserMedia stream (separate from whatever the Jitsi iframe is doing —
 * cross-origin, so we can't read its feed) and periodically reports whether
 * a face is in frame. No backend calls here: this page only ever posts a
 * boolean up to Flutter (meeting_room_view_web.dart), which owns the
 * join/presence-check/leave API calls via the normal meetingService, same
 * as the mobile app does with its ML Kit result.
 */
(() => {
  const video = document.getElementById('video');
  const post = (msg) => parent.postMessage({ source: 'meeting-presence', ...msg }, '*');

  // TinyFaceDetector only — presence is yes/no, no landmarks or recognition
  // needed, matching what ML Kit does on the mobile path.
  const detectOpts = new faceapi.TinyFaceDetectorOptions({
    inputSize: 320,
    scoreThreshold: 0.5,
  });

  const CHECK_INTERVAL_MS = 7000;
  let checking = false;

  async function checkPresence() {
    if (checking) return;
    checking = true;
    try {
      const det = await faceapi.detectSingleFace(video, detectOpts);
      post({ type: 'presence', faceDetected: !!det });
    } catch (e) {
      // A single bad detection shouldn't stop the whole loop — just skip
      // this round, same as the mobile side treats a failed frame.
      post({ type: 'error', message: String(e && e.message || e) });
    } finally {
      checking = false;
    }
  }

  async function start() {
    try {
      await faceapi.nets.tinyFaceDetector.loadFromUri('/face/models');

      const stream = await navigator.mediaDevices.getUserMedia({
        video: { facingMode: 'user', width: { ideal: 320 }, height: { ideal: 240 } },
        audio: false,
      });
      video.srcObject = stream;
      await video.play();

      post({ type: 'ready' });
      setInterval(checkPresence, CHECK_INTERVAL_MS);
    } catch (e) {
      // Model load failed, or this second getUserMedia prompt was denied —
      // report it and stop. The caller (Dart) just logs this; it must never
      // affect the actual Jitsi video call.
      post({ type: 'error', message: String(e && e.message || e) });
    }
  }

  start();
})();
