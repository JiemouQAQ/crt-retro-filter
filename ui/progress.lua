-- ============================================================
-- CRT Retro Filter - Progress Dialog
-- Lightweight non-blocking progress bar (Aseprite has no built-in
-- progress widget, so the bar is drawn on a canvas). Uses
-- Dialog:show{ wait=false } so the script keeps running while the
-- dialog is visible.
-- ============================================================

local Progress = {}

-- Show a non-blocking progress dialog.
-- Returns an object with setValue(frac01, text), canceled(), close().
-- Note: the Cancel button is best-effort — it responds while Aseprite
-- pumps events between frames; on very old builds it may only take
-- effect after the script finishes.
function Progress.show(title, initialText)
  local state = { value = 0, text = initialText or "", canceled = false }
  local W, H = 340, 26

  local dlg = Dialog(title or "Processing...")
  dlg:label{ id = "msg", text = state.text }
  dlg:canvas{
    id = "bar",
    width = W,
    height = H,
    onpaint = function(ev)
      local gc = ev.context
      gc:fillRect(Rectangle(0, 0, W, H), app.pixelColor.rgba(22, 24, 32, 255))
      local bw = math.max(0, math.min(W - 4, math.floor((W - 4) * state.value)))
      if bw > 0 then
        gc:fillRect(Rectangle(2, 2, bw, H - 4), app.pixelColor.rgba(80, 205, 150, 255))
      end
    end
  }
  dlg:button{ id = "cancel", text = "Cancel",
    onclick = function()
      state.canceled = true
    end }
  dlg:show{ wait = false }
  dlg:repaint()

  return {
    setValue = function(frac, text)
      state.value = math.max(0, math.min(1, frac))
      if text then state.text = text end
      dlg:modify{ id = "msg", text = state.text }
      dlg:repaint()
    end,
    canceled = function()
      if state.canceled then return true end
      local d = dlg.data
      return d ~= nil and d.cancel == true
    end,
    close = function()
      dlg:close()
    end,
  }
end

return Progress
