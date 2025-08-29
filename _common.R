```{r tts-setup, include=FALSE}
tts_box <- function(text, id = paste0("abs", as.integer(as.numeric(Sys.time())))) {
  if (!knitr::is_html_output()) {
    return(htmltools::tagList(htmltools::tags$p(text)))
  }
  
  css <- "
  .abstract-tts { border:1px solid #e5e7eb; border-radius:8px; padding:.75rem 1rem; background:#fafafa; margin:.5rem 0 1rem; }
  .tts-controls { display:flex; align-items:center; gap:.5rem; margin-top:.5rem; flex-wrap:wrap; }
  .tts-controls button { padding:.35rem .6rem; border-radius:.5rem; border:1px solid #d1d5db; background:#fff; cursor:pointer; }
  .tts-controls button:disabled { opacity:.5; cursor:not-allowed; }"
  
  js <- "
  (function () {
    const synth = window.speechSynthesis;
    let currentToken = 0;          // increments on each (re)start
    let currentContainer = null;   // track which box is speaking

    function getContainer(el){ return el.closest('.abstract-tts'); }
    function getText(container){
      const clone = container.cloneNode(true);
      clone.querySelectorAll('.tts-controls').forEach(el=>el.remove());
      return (clone.textContent || '').replace(/\\s+/g,' ').trim();
    }
    function setState(container, state){
      container.dataset.state = state;
      const play  = container.querySelector('.tts-play');
      const pause = container.querySelector('.tts-pause');
      const stop  = container.querySelector('.tts-stop');
      if(!play || !pause || !stop) return;
      if(state==='idle'){
        play.disabled=false; pause.disabled=true; stop.disabled=true; play.textContent='▶︎ Play';
      }else if(state==='playing'){
        play.disabled=true; pause.disabled=false; stop.disabled=false; pause.textContent='⏸ Pause';
      }else{ // paused
        play.disabled=false; pause.disabled=false; stop.disabled=false; play.textContent='▶︎ Resume'; pause.textContent='▶︎ Pause';
      }
    }

    function speak(container){
      if(!synth){ alert('Speech Synthesis not supported in this browser.'); return; }
      // If resuming from paused, just resume
      if (synth.paused && currentContainer === container) {
        synth.resume(); setState(container,'playing'); return;
      }
      // Fresh start
      if (synth.speaking) synth.cancel();
      const token = ++currentToken;
      currentContainer = container;
      const rate = parseFloat(container.querySelector('.tts-rate')?.value || '1.0');
      const utter = new SpeechSynthesisUtterance(getText(container));
      utter.rate = rate;
      utter.onend = () => { if (token === currentToken) setState(container,'idle'); };
      utter.onerror = () => { if (token === currentToken) setState(container,'idle'); };
      synth.speak(utter);
      setState(container,'playing');
    }

    function pause(container){
      if(!synth || currentContainer !== container) return;
      if (synth.speaking && !synth.paused){ synth.pause(); setState(container,'paused'); }
      else if (synth.paused){ synth.resume(); setState(container,'playing'); }
    }

    function stop(container){
      if(!synth) return;
      if (synth.speaking || synth.paused){
        synth.cancel();
        currentToken++;            // invalidate any pending onend from prior utterances
        setState(container,'idle');
      }
    }

    function restartWithRate(container){
      if(!synth) return;
      const wasPaused = synth.paused && currentContainer === container;
      if (synth.speaking || synth.paused){ synth.cancel(); currentToken++; }
      // Defer to next tick so cancel fully flushes before speaking again
      setTimeout(() => {
        speak(container);
        if (wasPaused) { synth.pause(); setState(container,'paused'); }
      }, 0);
    }

    function initAll(){ document.querySelectorAll('.abstract-tts').forEach(c => setState(c,'idle')); }

    // Event delegation (robust with gitbook/bs4 dynamic loads)
    document.addEventListener('click', function(ev){
      const btn = ev.target.closest('.tts-play, .tts-pause, .tts-stop');
      if(!btn) return;
      const container = getContainer(btn);
      if(!container) return;
      ev.preventDefault();
      if (btn.classList.contains('tts-play'))  speak(container);
      if (btn.classList.contains('tts-pause')) pause(container);
      if (btn.classList.contains('tts-stop'))  stop(container);
    });

    // Use 'change' (not 'input') to avoid rapid restarts while dragging
    document.addEventListener('change', function(ev){
      if (!ev.target.matches('.tts-rate')) return;
      const container = getContainer(ev.target);
      if(!container) return;
      if (synth && (synth.speaking || synth.paused)) restartWithRate(container);
      // If idle, the new rate will apply on next Play automatically
    });

    if (document.readyState === 'loading') {
      document.addEventListener('DOMContentLoaded', initAll);
    } else { initAll(); }
  })();
  "
  
  htmltools::tagList(
    htmltools::tags$style(css),
    htmltools::tags$div(
      class="abstract-tts", id=id,
      htmltools::tags$p(text),
      htmltools::tags$div(
        class="tts-controls", `aria-label`="Abstract audio controls",
        htmltools::tags$button(class="tts-play",  type="button", "▶︎ Play"),
        htmltools::tags$button(class="tts-pause", type="button", disabled=NA, "⏸ Pause"),
        htmltools::tags$button(class="tts-stop",  type="button", disabled=NA, "⏹ Stop"),
        htmltools::tags$label(
          style="margin-left:.5rem;",
          "Speed ",
          htmltools::tags$input(class="tts-rate", type="range", min="0.6", max="1.6", step="0.1", value="1.0")
        )
      )
    ),
    htmltools::tags$script(js)
  )
}
```
