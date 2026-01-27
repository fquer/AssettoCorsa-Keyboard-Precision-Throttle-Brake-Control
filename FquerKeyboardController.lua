---@ext:basic
-- Fquer Keyboard Controller (Smooth Version)
-- Precise and lagged throttle / brake control with keyboard

local car = ac.getCar(0) or error()
local sim = ac.getSim()

local controls = ac.overrideCarControls()

------------------------------------------------
-- CONTROL BUTTONS (ac.ControlButton)
------------------------------------------------
local keyGasLow = ac.ControlButton("FQUER_GAS_LOW")
local keyGasMed = ac.ControlButton("FQUER_GAS_MED")
local keyGasHigh = ac.ControlButton("FQUER_GAS_HIGH")

local keyBrakeLow = ac.ControlButton("FQUER_BRAKE_LOW")
local keyBrakeMed = ac.ControlButton("FQUER_BRAKE_MED")
local keyBrakeHigh = ac.ControlButton("FQUER_BRAKE_HIGH")

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
  
  -- Med -> 50%, Lag 4
  gasTargetMed = 50,
  gasLagMed = 4.0,

  -- High -> 100%, Lag 5
  gasTargetHigh = 100,
  gasLagHigh = 5.0,

  gasReleaseLag = 10.0, -- Throttle release speed

  -- BRAKE SETTINGS (Default)
  -- Low -> 20%, Lag 1
  brakeTargetLow = 20,
  brakeLagLow = 1.0,

  -- Med -> 50%, Lag 6
  brakeTargetMed = 50,
  brakeLagMed = 6.0,

  -- High -> 100%, Lag 6
  brakeTargetHigh = 100,
  brakeLagHigh = 6.0,

  brakeReleaseLag = 10.0 -- Brake release speed
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

local function readInputs()
  -- Throttle Control
  if keyGasHigh:down() then
    targetGas = settings.gasTargetHigh / 100.0
    activeGasSpeed = getSpeedFromLag(settings.gasLagHigh)
  elseif keyGasMed:down() then
    targetGas = settings.gasTargetMed / 100.0
    activeGasSpeed = getSpeedFromLag(settings.gasLagMed)
  elseif keyGasLow:down() then
    targetGas = settings.gasTargetLow / 100.0
    activeGasSpeed = getSpeedFromLag(settings.gasLagLow)
  else
    targetGas = 0
    activeGasSpeed = getSpeedFromLag(settings.gasReleaseLag)
  end

  -- Brake Control
  if keyBrakeHigh:down() then
    targetBrake = settings.brakeTargetHigh / 100.0
    activeBrakeSpeed = getSpeedFromLag(settings.brakeLagHigh)
  elseif keyBrakeMed:down() then
    targetBrake = settings.brakeTargetMed / 100.0
    activeBrakeSpeed = getSpeedFromLag(settings.brakeLagMed)
  elseif keyBrakeLow:down() then
    targetBrake = settings.brakeTargetLow / 100.0
    activeBrakeSpeed = getSpeedFromLag(settings.brakeLagLow)
  else
    targetBrake = 0
    activeBrakeSpeed = getSpeedFromLag(settings.brakeReleaseLag)
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
local function renderControlRow(label, controlBtn, targetKey, lagKey)
  ui.pushID(label)
  
  -- Label and Button
  -- Using smaller label width to fit in column
  ui.textAligned(label, vec2(0, 0.5), vec2(50, 30))
  ui.sameLine()
  controlBtn:control(vec2(ui.availableSpaceX(), 30))
  
  -- Target Percent Slider
  local targetVal = settings[targetKey]
  local newTarget = ui.slider('##target', targetVal, 0, 100, 'Pow: %.0f%%')
  if newTarget ~= targetVal then
    settings[targetKey] = newTarget
  end

  -- Lag Slider
  local lagVal = settings[lagKey]
  local newLag = ui.slider('##lag', lagVal, 1, 30, 'Lag: %.1f')
  if ui.itemHovered() then
     ui.setTooltip("Low = Fast Response\nHigh = Slow/Smooth Response")
  end
  
  if newLag ~= lagVal then
    settings[lagKey] = newLag
  end
  
  ui.newLine(10)
  ui.popID()
end

------------------------------------------------
-- UI
------------------------------------------------
function script.windowMain(dt)
  ui.text('Fquer Keyboard Controller (Pro)')
  ui.text('Configure Power and Lag per key')
  ui.separator()

  local halfWidth = (ui.availableSpaceX() - 10) / 2
  local columnHeight = 420 -- Estimated height for controls

  -- LEFT COLUMN: THROTTLE
  ui.beginChild('ThrottleCol', vec2(halfWidth, columnHeight))
    ui.pushFont(ui.Font.Main)
    ui.text('THROTTLE')
    ui.popFont()
    ui.separator()
    
    renderControlRow('Low', keyGasLow, 'gasTargetLow', 'gasLagLow')
    renderControlRow('Med', keyGasMed, 'gasTargetMed', 'gasLagMed')
    renderControlRow('High', keyGasHigh, 'gasTargetHigh', 'gasLagHigh')
    
    ui.text('Release Lag')
    settings.gasReleaseLag = ui.slider('##gasRel', settings.gasReleaseLag, 1, 30, '%.1f')
  ui.endChild()

  ui.sameLine()

  -- RIGHT COLUMN: BRAKE
  ui.beginChild('BrakeCol', vec2(halfWidth, columnHeight))
    ui.pushFont(ui.Font.Main)
    ui.text('BRAKE')
    ui.popFont()
    ui.separator()

    renderControlRow('Low', keyBrakeLow, 'brakeTargetLow', 'brakeLagLow')
    renderControlRow('Med', keyBrakeMed, 'brakeTargetMed', 'brakeLagMed')
    renderControlRow('High', keyBrakeHigh, 'brakeTargetHigh', 'brakeLagHigh')

    ui.text('Release Lag')
    settings.brakeReleaseLag = ui.slider('##brakeRel', settings.brakeReleaseLag, 1, 30, '%.1f')
  ui.endChild()

  ui.separator()

  ui.text('LIVE STATUS')
  local size = vec2 and vec2(-1, 18) or ac.vec2(-1, 18)
  
  ui.progressBar(currentGas, size, string.format('Throttle: %.0f%%', currentGas * 100))
  ui.progressBar(currentBrake, size, string.format('Brake: %.0f%%', currentBrake * 100))
end
