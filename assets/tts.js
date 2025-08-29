(function () {
  if (typeof window === "undefined") return;
  const synth = window.speechSynthesis;
  if (!synth) {
    console.warn("Speech Synthesis not supported in this browser.");
    return;
  }

  function initTTS(container) {
    const playBtn  = container.querySelector(".tts-play");
    const pauseBtn = container.querySelector(".tts-pause");
    const stopBtn  = container.querySelector(".tts-stop");
    const rateCtl  = container.querySelector(".tts-rate");

    let utter = null;
    let paused = false;

    function setState(state) {
      // state: "idle" | "playing" | "paused"
      if (state === "idle") {
        playBtn.disabled = false; pauseBtn.disabled = true; stopBtn.disabled = true;
        playBtn.textContent = "▶︎ Play";
      } else if (state === "playing") {
        playBtn.disabled = true; pauseBtn.disabled = false; stopBtn.disabled = false;
        paused = false;
      } else { // paused
        playBtn.disabled = false; pauseBtn.disabled = false; stopBtn.disabled = false;
        playBtn.textContent = "▶︎ Resume";
      }
    }

    function textFrom(container) {
      // Read visible text of the abstract; customize selector if needed
      const clone = container.cloneNode(true);
      // Remove controls from readout
      Array.from(clone.querySelectorAll(".tts-controls")).forEach(el => el.remove());
      return clone.textContent.replace(/\s+/g, " ").trim();
    }

    function speak() {
      if (paused && synth.paused) { synth.resume(); setState("playing"); return; }
      if (synth.speaking) synth.cancel();
      utter = new SpeechSynthesisUtterance(textFrom(container));
      utter.rate = parseFloat(rateCtl?.value || "1.0");
      // Optional: pick a voice (commented—defaults are fine)
      // utter.voice = synth.getVoices().find(v => /en-US/i.test(v.lang)) || null;
      utter.onend = () => setState("idle");
      utter.onerror = () => setState("idle");
      synth.speak(utter);
      playBtn.textContent = "▶︎ Play";
      setState("playing");
    }

    function pause() {
      if (synth.speaking && !synth.paused) { synth.pause(); paused = true; setState("paused"); }
    }
    function stop() {
      if (synth.speaking || synth.paused) { synth.cancel(); paused = false; setState("idle"); }
    }
    function updateRate() {
      // Rate affects only future utterances; if speaking, restart smoothly.
      if (synth.speaking) { const wasPaused = synth.paused; stop(); speak(); if (wasPaused) pause(); }
    }

    playBtn?.addEventListener("click", speak);
    pauseBtn?.addEventListener("click", pause);
    stopBtn?.addEventListener("click", stop);
    rateCtl?.addEventListener("change", updateRate);

    setState("idle");
  }

  function initAll() {
    document.querySelectorAll(".abstract-tts").forEach(initTTS);
  }

  // Some browsers load voices async; re-init if necessary.
  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", initAll);
  } else {
    initAll();
  }
  if (window.speechSynthesis && typeof window.speechSynthesis.onvoiceschanged !== "undefined") {
    window.speechSynthesis.onvoiceschanged = () => {}; // triggers voices load
  }
})();
