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
      if relativ then
        x = x + value;
      else
        x = value
      end
    elseif axis == "y" then
      if relativ then
        y = y + value;
      else
        y = value
      end
    elseif axis == "z" then
      if relativ then
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

function createMacros()
  -- TODO: implement
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
        tpye = 1,
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

  local value = 0
  local axis = ""
  local relative = true

  if args == "" or args == nil then 
    local result = mainUI()
    local command = result.result

    if command == 0 or result.success == false then
      return
    elseif command == 1 then
      
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

    elseif command == 2 then
      createMacros()
      return
    end
  else
    -- Args could be Plugin X "relative,x,5"



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
