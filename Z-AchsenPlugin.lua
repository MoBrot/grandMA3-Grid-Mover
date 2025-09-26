pluginID = 60;

function executeCommand(cmd)
  Cmd(cmd)
end

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

    x = fixture.gridX
    y = fixture.gridY
    z = fixture.gridZ

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
  local name = "Grid Mover - " .. mode .. " " .. string.upper(axis) .. " " .. value
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

  nextID = startingID
  value = math.abs(value)

  if mode then
    mode = "relative"
  else
    mode = "absolute"
  end 

  nextID = storeMacro(-value, nextID, axis, mode)
  nextID = storeMacro(value, nextID, axis, mode)

end

function createMacrosUI()

  return MessageBox({
    title = "Create Macro Shortcuts",
    name = "Axis",
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

  local value = 0
  local axis = ""
  local relative = true

  if args == "" or args == nil then 
    local result = mainUI()
    local command = result.result

    value = result.inputs["Value"];
    if value == nil then
      showError("Value cannot be empty!")
    end

    value = tonumber(value)
      
    if result.selectors["Mode"] == 1 then
      relative = false
    end

    axisResult = result.selectors["Axis"];
    if axisResult == 0 then
      axis="x"
    elseif axisResult == 1 then
      axis="y"
    elseif axisResult == 2 then
      axis="z"
    end

    if command == 0 or result.success == false then
      return
    elseif command == 2 then
      macroUIResult = createMacrosUI()

      macroCommand = macroUIResult.result

      if macroCommand == 0 then
        return
      elseif macroCommand == 1 then
        
        macroStartingID = tonumber(macroUIResult.inputs["Macro start ID"])
        if macroStartingID == 0 then
          showError("The Macro ID must be a number between 1 and 9999")
          return
        end

        createMacros(macroStartingID, relative, axis, value)
      end

      return
    end
  else
    -- Args could be Plugin X "relative,x,5"

    

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
