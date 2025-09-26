local luaCOmponentHandle = select(4, ...)
local pluginID = 60;

local pluginPrefix = "Grid Mover - "

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
----------------

local function GetSelectionTable()
  local result = {}
  local fixtureIndex, gridX, gridY, gridZ = SelectionFirst()

  while fixtureIndex do
    table.insert(result, {
      fixtureIndex = fixtureIndex,
      gridX = gridX,
      gridY = gridY,
      gridZ = gridZ,
      asFixture = GetSubfixture(fixtureIndex)
    })
    fixtureIndex, gridX, gridY, gridZ = SelectionNext(fixtureIndex)
  end

  return result
end

function ajustGridForSelect(relative, axis, value, selection)

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
    executeCommand("Fixture " .. fixture.asFixture.FID)
  end
end

function reselectAllFixtures(selection)
  for _, fixture in pairs(selection) do
    executeCommand("Fixture " .. fixture.asFixture.FID)
  end
end

function showError(errmessage)
  MessageBox({
    title="Error!",
    message=errmessage,
    timeout=5000,
    commands={
      {value=1, name="Ok"}
    }
  })
end

-- return the id where it was stored + 1
function storeMacro(value, id, axis, mode)
  local name = pluginPrefix .. mode .. " " .. string.upper(axis) .. " " .. value
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
    macroObject[1].Command = "#[Plugin " .. pluginID .. "] \"".. mode .."," .. axis .. "," .. value .. "\""
    macroObject[1].name = "Move"

    return currentID + 1
  end
end


function createMacros(startingID, mode, axis, value)

  local nextID = startingID
  value = math.abs(value)

  nextID = storeMacro(-value, nextID, axis, mode)
  nextID = storeMacro(value, nextID, axis, mode)

end

function createMacrosUI(mode, axis, value)

  return MessageBox({
    title = "Create Macro Shortcuts",
    name = "Axis",
    message = "The created Macros will use the configuration of the Main UI." ..
              "\n None of the existing Macros will be overwritten." ..
              "\n \n -- Info -- \n Mode: " .. mode .. " | Axis: " .. axis .. " | Value: " .. value,
    commands = {
      { value = 0, name = "Cancel" },
      { value = 1, name = "Create!" }
    },
    inputs = {
      {
        name = "Macro start ID",
        value = 1,
        whitefilter="0123456789",
        vkPlugin="TextInputNumOnly",
        maxtextLength = 4
      }
    },
  })
end

function mainUI()
  return MessageBox({
    title="Grid Mover - By MNLichtdesign",
    selectors = {
      {
        name = "Axis",
        type = 1,
        selectedValue = 2,
        values = {
          ["Grid X"] = 0,
          ["Grid Y"] = 1,
          ["Grid Z"] = 2
        }
      },
      {
        name="Mode",
        type = 0,
        selectedValue = 0,
        values = {
          ["Relative"] = 0,
          ["Absolute"] = 1
        }
      }
    },
    inputs = {
      {
        name = "Value",
        value = 1,
        whitefilter="+-0123456789",
        vkPlugin="TextInputNumOnly"
      }
    },
    commands={
      { value=0, name="Close" },
      { value=1, name="Move" },
      { value=2, name="Create Macros" }
    }
  })
end

function main(display, args)
  pluginID =  luaCOmponentHandle:Parent().NO

  local value = 0
  local axis = ""
  local relative = true

  if args == "" or args == nil then 
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
      
    if result.selectors["Mode"] == 1 then
      relative = false
    end

    local axisResult = result.selectors["Axis"];
    if axisResult == 0 then
      axis="x"
    elseif axisResult == 1 then
      axis="y"
    elseif axisResult == 2 then
      axis="z"
    end

    -- Create Macros
    if command == 2 then

      local mode = ""
      if relative then
        mode = "relative"
      else
        mode = "absolute"
      end 

      local macroUIResult = createMacrosUI(mode, axis, value)
      local macroCommand = macroUIResult.result

      if macroCommand == 0 then
        return
      elseif macroCommand == 1 then
        
        local macroStartingID = tonumber(macroUIResult.inputs["Macro start ID"])
        if macroStartingID == 0 then
          showError("The Macro ID must be a number between 1 and 9999")
          return
        end

        createMacros(macroStartingID, mode, axis, value)
      end

      return
    end
    else
      -- Args could be Plugin X "relative,x,5"
      local splittet = split(args)
      local errorPrefix = pluginPrefix .. "Commandlineinput - "

      if #splittet < 3 then
        showError(errorPrefix .. "Not enough parameters.")
        return
      end

      local mode = splittet[1]
      axis = string.lower(splittet[2])
      value = splittet[3]

      -- Validate inputs
      if not mode == "relative " or not mode == "absolute" then
        showError(errorPrefix .. "First parameter needs to be 'absolute' or 'relative'.")
        return
      end

      if not axis == "x" or not axis == "y" or not axis == "z" then
        showError(errorPrefix .. "Second parameter needs to be x/y/z.")
        return
      end

      if not isNumber(value) then
        showError(errorPrefix .. "Third paramter needs to be a number.")
        return
      end
    end

  local setupToggle = Selection().SETUPMODE

  if setupToggle == false then
    showError("Fixtures must be selected in the Selectiongrid Setup mode!")
    return
  end

  local selection = GetSelectionTable()
  if #selection == 0 then
    showError("At least one Fixture must be selected!")
    return
  end

  Printf("Relative: " .. tostring(relative))
  Printf("Axis: " .. axis)
  Printf("Value: " .. value)

  Selection().SETUPMODE = false
  ajustGridForSelect(relative, axis, value, selection)
  Selection().SETUPMODE = true
  reselectAllFixtures(selection)
end

return main