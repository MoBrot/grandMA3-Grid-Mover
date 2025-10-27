local luaCOmponentHandle = select(4, ...)
local pluginID;

local pluginPrefix = "Grid Mover - "

local variablePrefix = "gridmover-"
local modeVariable = variablePrefix .. "default-mode"
local axisVariable = variablePrefix .. "default-axis"
local valueVariable = variablePrefix .. "default-value"

local lastMacroIDVariable = variablePrefix .. "default-macro-id"

local dynamic = "dynamic"

--- Util ---
function executeCommand(cmd)
  Cmd(cmd)
end

function split(str)
  local sep = ","
  local result = {}

  for part in string.gmatch(str, "([^" .. sep .. "]+)") do
    table.insert(result, part)
  end

  return result
end

local function isNumber(str)
  return tonumber(str) ~= nil
end

function setVariable(var, value)
  SetVar(UserVars(), var, value)
end

function getVariable(var)
  return GetVar(UserVars(), var)
end

----------------

local function GetSelectionTable()
  local result = {}
  local fixtureIndex, gridX, gridY, gridZ = SelectionFirst()

  while fixtureIndex do
    local asFixture = GetSubfixture(fixtureIndex)

    Printf(id)

    table.insert(result, {
      fixtureIndex = fixtureIndex,
      gridX = gridX,
      gridY = gridY,
      gridZ = gridZ,
      asFixture = asFixture,
      id = asFixture:ToAddr()
    })
    fixtureIndex, gridX, gridY, gridZ = SelectionNext(fixtureIndex)
  end

  return result
end

function adjustGridForSelected(relative, axis, value, selection)
  local progressHandle = StartProgress(pluginPrefix .. "Moving Fixtures")
  local progressRangeStart, progressRangeEnd = 1, #selection
  SetProgressRange(progressHandle, progressRangeStart, progressRangeEnd)

  table.insert(selection, selection[1])

  for _, fixture in pairs(selection) do
    local x = fixture.gridX
    local y = fixture.gridY
    local z = fixture.gridZ

    if axis == "x" then
      if relative then
        x = x + value;
      else
        x = value
      end
    elseif axis == "y" then
      if relative then
        y = y + value;
      else
        y = value
      end
    elseif axis == "z" then
      if relative then
        z = z + value;
      else
        z = value
      end
    end

    executeCommand("Grid " .. x .. "/" .. y .. "/" .. z)
    executeCommand(fixture.id)

    IncProgress(progressHandle, 1)
  end

  StopProgress(progressHandle)
end

function reselectAllFixtures(selection)
  table.insert(selection, selection[#selection])

  for _, fixture in pairs(selection) do
    executeCommand(fixture.id)
  end
end

-- return the id where it was stored + 1
function storeMacro(value, id, axis, mode)
  local valueAsText = value;
  if not value == dynamic then
    if value < 0 then
      valueAsText = "-" .. math.abs(value)
    else
      valueAsText = "+" .. value
    end
  end


  local name = pluginPrefix .. mode .. " " .. string.upper(axis) .. " " .. valueAsText
  local macroPool = DataPool().Macros

  if id < 9999 then
    local currentID = id
    local validIDFound = false
    local macroObject = nil

    while not validIDFound do
      macroObject = macroPool[currentID]

      if macroObject == nil then
        validIDFound = true
      else
        currentID = currentID + 1
      end
    end

    Cmd("Store Macro " .. currentID)
    Cmd("Store Macro " .. currentID .. " /NoOops")
    macroObject = macroPool[currentID]
    macroObject:Set("name", name)
    macroObject[1].Command = "#[Plugin " .. pluginID .. "] \"" .. mode .. "," .. axis .. "," .. value .. "\""
    macroObject[1].name = "Move"

    return currentID + 1
  end
end

function createMacros(startingID, mode, axis, value)
  local nextID = startingID

  if value ~= dynamic then
    value = math.abs(value)
    nextID = storeMacro(-value, nextID, axis, mode)
  end

  nextID = storeMacro(value, nextID, axis, mode)
end

function createMacrosUI(mode, axis, value)
  local defaultIndex = getVariable(lastMacroIDVariable) or 1

  return MessageBox({
    title = "Create Macro Shortcuts",
    name = "Axis",
    message = "The created Macros will use the configuration of the Main UI." ..
        "\n None of the existing Macros will be overwritten." ..
        "\n \n -- Info -- \n Mode: " .. mode .. " | Axis: " .. axis .. " | Value: " .. value,
    commands = {
      { value = 0, name = "Back" },
      { value = 1, name = "Create!" }
    },
    states = {
      {
        name = "Dynamic Value",
        state = false
      }
    },
    inputs = {
      {
        name = "Macro start ID",
        value = defaultIndex,
        whitefilter = "0123456789",
        vkPlugin = "TextInputNumOnly",
        maxtextLength = 4
      }
    },
  })
end

function mainUI()
  local defaultMode = getVariable(modeVariable) or 0
  local defaultAxis = getVariable(axisVariable) or 2
  local defaultValue = getVariable(valueVariable) or 1

  return MessageBox({
    title = "Grid Mover - By MNLichtdesign",
    selectors = {
      {
        name = "Axis",
        type = 1,
        selectedValue = defaultAxis,
        values = {
          ["Grid X"] = 0,
          ["Grid Y"] = 1,
          ["Grid Z"] = 2
        }
      },
      {
        name = "Mode",
        type = 0,
        selectedValue = defaultMode,
        values = {
          ["Relative"] = 0,
          ["Absolute"] = 1
        }
      }
    },
    inputs = {
      {
        name = "Value",
        value = defaultValue,
        whitefilter = "+-0123456789",
        vkPlugin = "TextInputNumOnly"
      }
    },
    commands = {
      { value = 0, name = "Close" },
      { value = 1, name = "Move" },
      { value = 2, name = "Create Macros" }
    }
  })
end

function showError(errmessage)
  MessageBox({
    title = "Error!",
    message = errmessage,
    timeout = 5000,
    commands = {
      { value = 1, name = "Ok" }
    }
  })
end

function createDynamicValueInput()
  return MessageBox({
    title = "Input the value of your Choice",
    commands = {
      { value = 0, name = "Cencel" },
      { value = 1, name = "Move" },
    },
    inputs = {
      {
        name = "Value",
        value = "",
        whitefilter = "+-0123456789",
        vkPlugin = "TextInputNumOnly"
      }
    }
  })
end

function main(display, args)
  pluginID = luaCOmponentHandle:Parent().NO

  local value = 0
  local axis = ""
  local relative = true

  if args == "" or args == nil then
    local loop = true;

    while loop do
      local result = mainUI()
      local command = result.result

      if command == 0 or result.success == false then
        return
      end

      -- Read values
      value = result.inputs["Value"];
      if value == nil then
        showError("Value cannot be empty!")
      end

      local value = tonumber(value)
      setVariable(valueVariable, value)

      local modeSelection = result.selectors["Mode"]
      setVariable(modeVariable, modeSelection)

      if modeSelection == 1 then
        relative = false
      end

      local axisResult = result.selectors["Axis"];
      setVariable(axisVariable, axisResult)

      if axisResult == 0 then
        axis = "x"
      elseif axisResult == 1 then
        axis = "y"
      elseif axisResult == 2 then
        axis = "z"
      end

      if command == 0 then
        return;
      elseif command == 1 then
        loop = false

        -- Create Macros
      elseif command == 2 then
        local mode = ""
        if relative then
          mode = "relative"
        else
          mode = "absolute"
        end

        local macroUIResult = createMacrosUI(mode, axis, value)
        local macroCommand = macroUIResult.result

        if macroCommand == 1 then
          local macroStartingID = tonumber(macroUIResult.inputs["Macro start ID"])
          if macroStartingID == 0 then
            showError("The Macro ID must be a number between 1 and 9999")
            return
          end
          setVariable(lastMacroIDVariable, macroStartingID)

          if macroUIResult.states["Dynamic Value"] == true then
            value = dynamic
          end
          createMacros(macroStartingID, mode, axis, value)
          return
        end

        --return
      end
    end
  else
    -- Args could be Plugin X "relative,x,5"
    local splitted = split(args)
    local errorPrefix = pluginPrefix .. "Commandlineinput - "

    if #splitted < 3 then
      showError(errorPrefix .. "Not enough parameters.")
      return
    end

    local mode = splitted[1]
    axis = string.lower(splitted[2])
    value = splitted[3]

    -- Validate inputs
    if mode == "relative" or not mode == "absolute" then
      showError(errorPrefix .. "First parameter needs to be 'absolute' or 'relative'.")
      return
    end

    if not axis == "x" or not axis == "y" or not axis == "z" then
      showError(errorPrefix .. "Second parameter needs to be x/y/z.")
      return
    end

    if not value == dynamic then
      if not isNumber(value) then
        showError(errorPrefix .. "Third parameter needs to be a number.")
        return
      end
    end
  end

  if SelectionCount() == 0 then
    showError("At least one Fixture must be selected!")
    return
  end

  local selection = GetSelectionTable()
  local setupToggle = Selection().SETUPMODE

  Selection().SETUPMODE = false

  if value == dynamic then
    local dynamic = createDynamicValueInput()

    if dynamic.result == 0 then
      Selection().SETUPMODE = setupToggle
      return
    end

    local tempValue = dynamic.inputs["Value"]

    if tempValue == "" or tempValue == nil then
      showError("Value cannot be empty :)")
      return
    end

    value = tempValue
  end
  adjustGridForSelected(relative, axis, value, selection)
  Selection().SETUPMODE = setupToggle

  if setupToggle == true then
    reselectAllFixtures(selection)
  end
end

return main
