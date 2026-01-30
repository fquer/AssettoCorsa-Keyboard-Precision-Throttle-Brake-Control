---@ext:basic
-- Fquer Keyboard Controller (Smooth Version)
-- Precise and lagged throttle / brake control with keyboard

local car = ac.getCar(0) or error()
local sim = ac.getSim()

local controls = ac.overrideCarControls()

------------------------------------------------
-- CONTROL BUTTONS (ac.ControlButton)
------------------------------------------------
------------------------------------------------
-- CONTROL BUTTONS
-- Replaced with custom bindings in settings
------------------------------------------------


------------------------------------------------
-- SETTINGS (TARGET PERCENTAGES AND LAGS)
------------------------------------------------
-- Higher value = Slower response (More LAG)
-- Slider: 1 (Fast) -> 30 (Very Slow)
local settings = ac.storage{
  -- THROTTLE SETTINGS (Default)
  -- Low -> 20%, Lag 1
  gasTargetLow = 20,
  gasLagLow = 1.0,
  gasReleaseLagLow = 2.0,
  
  -- Med -> 50%, Lag 4
  gasTargetMed = 50,
  gasLagMed = 4.0,
  gasReleaseLagMed = 2.0,

  -- High -> 100%, Lag 5
  gasTargetHigh = 100,
  gasLagHigh = 5.0,
  gasReleaseLagHigh = 2.0,

  -- BRAKE SETTINGS (Default)
  -- Low -> 20%, Lag 1
  brakeTargetLow = 20,
  brakeLagLow = 1.0,
  brakeReleaseLagLow = 2.0,

  -- Med -> 50%, Lag 6
  brakeTargetMed = 50,
  brakeLagMed = 6.0,
  brakeReleaseLagMed = 2.0,

  -- High -> 100%, Lag 6
  brakeTargetHigh = 100,
  brakeLagHigh = 6.0,
  brakeReleaseLagHigh = 2.0,

  -- BINDINGS (Key Codes)
  bindGasLow = -1,
  bindGasMed = -1,
  bindGasHigh = -1,
  bindBrakeLow = -1,
  bindBrakeMed = -1,
  bindBrakeHigh = -1
}

------------------------------------------------
-- STATE
------------------------------------------------
local currentGas = 0
local currentBrake = 0

local targetGas = 0
local targetBrake = 0

local activeGasSpeed = 10.0
local activeBrakeSpeed = 10.0

local activeGasReleaseSpeed = 10.0
local activeBrakeReleaseSpeed = 10.0

------------------------------------------------
-- SMOOTH TRANSITION FUNCTION
------------------------------------------------
local function smooth(current, target, speed, dt)
  return current + (target - current) * math.min(speed * dt, 1)
end

------------------------------------------------
-- INPUT READING & SPEED CALCULATION
------------------------------------------------
local SPEED_CONSTANT = 30.0 

local function getSpeedFromLag(lagValue)
  local safeLag = math.max(lagValue, 0.1)
  return SPEED_CONSTANT / safeLag
end

local function isBindDown(bindKey)
  -- ui.keyboardButtonDown is more reliable for checking key state in this context
  -- as it matches the API used to detect the key press during binding.
  return bindKey and bindKey > 0 and ui.keyboardButtonDown(bindKey)
end

local function readInputs()
  -- Throttle Control
  if isBindDown(settings.bindGasHigh) then
    targetGas = settings.gasTargetHigh / 100.0
    activeGasSpeed = getSpeedFromLag(settings.gasLagHigh)
    activeGasReleaseSpeed = getSpeedFromLag(settings.gasReleaseLagHigh)
  elseif isBindDown(settings.bindGasMed) then
    targetGas = settings.gasTargetMed / 100.0
    activeGasSpeed = getSpeedFromLag(settings.gasLagMed)
    activeGasReleaseSpeed = getSpeedFromLag(settings.gasReleaseLagMed)
  elseif isBindDown(settings.bindGasLow) then
    targetGas = settings.gasTargetLow / 100.0
    activeGasSpeed = getSpeedFromLag(settings.gasLagLow)
    activeGasReleaseSpeed = getSpeedFromLag(settings.gasReleaseLagLow)
  else
    targetGas = 0
    activeGasSpeed = activeGasReleaseSpeed
  end

  -- Brake Control
  if isBindDown(settings.bindBrakeHigh) then
    targetBrake = settings.brakeTargetHigh / 100.0
    activeBrakeSpeed = getSpeedFromLag(settings.brakeLagHigh)
    activeBrakeReleaseSpeed = getSpeedFromLag(settings.brakeReleaseLagHigh)
  elseif isBindDown(settings.bindBrakeMed) then
    targetBrake = settings.brakeTargetMed / 100.0
    activeBrakeSpeed = getSpeedFromLag(settings.brakeLagMed)
    activeBrakeReleaseSpeed = getSpeedFromLag(settings.brakeReleaseLagMed)
  elseif isBindDown(settings.bindBrakeLow) then
    targetBrake = settings.brakeTargetLow / 100.0
    activeBrakeSpeed = getSpeedFromLag(settings.brakeLagLow)
    activeBrakeReleaseSpeed = getSpeedFromLag(settings.brakeReleaseLagLow)
  else
    targetBrake = 0
    activeBrakeSpeed = activeBrakeReleaseSpeed
  end
end

------------------------------------------------
-- UPDATE
------------------------------------------------
function script.update(dt)
  readInputs()

  currentGas = smooth(currentGas, targetGas, activeGasSpeed, dt)
  currentBrake = smooth(currentBrake, targetBrake, activeBrakeSpeed, dt)

  controls.gas = currentGas
  controls.brake = currentBrake
end

------------------------------------------------
-- UI HELPER
------------------------------------------------
local waitingBind = nil

local function getKeyName(k)
  if k == nil or k < 0 then return "None" end
  if k >= 65 and k <= 90 then return string.char(k) end
  if k >= 48 and k <= 57 then return string.char(k) end
  if k == ui.KeyIndex.Control then return "Ctrl" end
  if k == ui.KeyIndex.Shift then return "Shift" end
  if k == ui.KeyIndex.Alt then return "Alt" end
  return "Key "..k
end

local function renderControlRow(label, bindKeyName, targetKey, lagKey)
  ui.pushID(label)
  
  -- Section Label (e.g., Low, Med, High)
  ui.text(label)

  -- Binding Button
  local currentKey = settings[bindKeyName]
  local btnText = getKeyName(currentKey)
  local isWaiting = waitingBind == bindKeyName
  
  if isWaiting then
    btnText = "Press Key..."
    ui.pushStyleColor(ui.StyleColor.Button, rgbm(0.8, 0.4, 0.4, 1))
  end

  ui.setNextItemWidth(ui.availableSpaceX())
  if ui.button(btnText, vec2(-1, 30)) then
    if isWaiting then
        waitingBind = nil -- Cancel if clicked again
    else
        waitingBind = bindKeyName
    end
  end

  if ui.itemClicked(ui.MouseButton.Right) then
    settings[bindKeyName] = -1
    waitingBind = nil
  end

  if ui.itemHovered() then
    ui.setTooltip(isWaiting and "Press any key to bind..." or "Left-click to bind\nRight-click to clear")
  end

  if isWaiting then
    ui.popStyleColor()
    -- Check for key press
    -- Checking common range of keys
    for i = 1, 255 do
        if ui.keyboardButtonDown(i) then
            -- Avoid binding mouse buttons if mapped to low indices, but KeyIndex usually starts > mouse
            -- Just binding the first thing
            settings[bindKeyName] = i
            waitingBind = nil
            break
        end
    end
  end
  
  -- Target Percent Slider
  local targetVal = settings[targetKey]
  ui.setNextItemWidth(ui.availableSpaceX())
  local newTarget = ui.slider('##target', targetVal, 0, 100, 'Pow: %.0f%%')
  if newTarget ~= targetVal then
    settings[targetKey] = newTarget
  end

  -- Lag Slider (Attack)
  local lagVal = settings[lagKey]
  ui.setNextItemWidth(ui.availableSpaceX())
  local newLag = ui.slider('##lag'..label, lagVal, 1, 30, 'Raise Up Lag: %.1f')
  if ui.itemHovered() then
     ui.setTooltip("Raise Up Lag\nLow = Fast Response\nHigh = Slow/Smooth Response")
  end
  
  if newLag ~= lagVal then
    settings[lagKey] = newLag
  end

  -- Release Lag Slider
  local releaseLagKey = lagKey:gsub("Lag", "ReleaseLag") -- e.g. gasLagLow -> gasReleaseLagLow
  local relLagVal = settings[releaseLagKey] or 10.0
  
  ui.setNextItemWidth(ui.availableSpaceX())
  local newRelLag = ui.slider('##rellag'..label, relLagVal, 1, 30, 'Release Lag: %.1f')
  if ui.itemHovered() then
     ui.setTooltip("Release Lag\nHow fast it drops to 0 when released")
  end

  if newRelLag ~= relLagVal then
    settings[releaseLagKey] = newRelLag
  end
  
  ui.newLine(10)
  ui.popID()
end

------------------------------------------------
-- UI
------------------------------------------------
function script.windowMain(dt)
  ui.text('Fquer Keyboard Controller')
  ui.text('Configure Power and Lag per key')
  ui.separator()

  local gap = 20
  local halfWidth = (ui.availableSpaceX() - gap) / 2
  local columnHeight = 500 -- Estimated height for controls

  -- LEFT COLUMN: THROTTLE
  ui.beginChild('ThrottleCol', vec2(halfWidth, columnHeight))
    ui.pushFont(ui.Font.Main)
    ui.text('THROTTLE')
    ui.popFont()
    ui.separator()
    
    renderControlRow('Low', 'bindGasLow', 'gasTargetLow', 'gasLagLow')
    renderControlRow('Med', 'bindGasMed', 'gasTargetMed', 'gasLagMed')
    renderControlRow('High', 'bindGasHigh', 'gasTargetHigh', 'gasLagHigh')
  ui.endChild()

  ui.sameLine()
  
  -- SEPARATOR LINE
  local cursor = ui.getCursor()
  -- Draw line in the middle of the gap
  local lineX = cursor.x + (gap / 2)
  ui.drawRectFilled(vec2(lineX, cursor.y), vec2(lineX + 1, cursor.y + columnHeight), rgbm(1, 1, 1, 0.2))
  
  -- Invisible spacer for the gap
  ui.dummy(vec2(gap, columnHeight))
  
  ui.sameLine()

  -- RIGHT COLUMN: BRAKE
  ui.beginChild('BrakeCol', vec2(halfWidth, columnHeight))
    ui.pushFont(ui.Font.Main)
    ui.text('BRAKE')
    ui.popFont()
    ui.separator()

    renderControlRow('Low', 'bindBrakeLow', 'brakeTargetLow', 'brakeLagLow')
    renderControlRow('Med', 'bindBrakeMed', 'brakeTargetMed', 'brakeLagMed')
    renderControlRow('High', 'bindBrakeHigh', 'brakeTargetHigh', 'brakeLagHigh')
  ui.endChild()

  ui.separator()

  ui.text('LIVE STATUS')
  local size = vec2 and vec2(-1, 18) or ac.vec2(-1, 18)
  
  ui.progressBar(currentGas, size, string.format('Throttle: %.0f%%', currentGas * 100))
  ui.progressBar(currentBrake, size, string.format('Brake: %.0f%%', currentBrake * 100))
  
end
