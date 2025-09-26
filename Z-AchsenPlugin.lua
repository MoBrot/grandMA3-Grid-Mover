variable_prefix = "z-ajustment-" 
variable_name = variable_prefix .. "selectionconfig"
variable_hookID = variable_prefix .. "hookID"

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

function ajustZForSelect(toAdd, selection)
  for _, fixture in pairs(selection) do
    executeCommand("Grid " .. (fixture.gridX) .. "/" .. (fixture.gridY) .. "/" .. (fixture.gridZ - toAdd))
    executeCommand("Fixture " .. fixture.asFixture.FID)
  end
end

function reselectAllFixtures(selection)
  for _, fixture in pairs(selection) do
    executeCommand("Fixture " .. fixture.asFixture.FID)
  end
end

function main(display, args)

  setupToggle = Selection().SETUPMODE;

  if setupToggle == false then
    Printf("Fixtures Must nbe selected in the Selectiongrid Setup mode!")
    return;
  end

  selection = GetSelectionTable()

  if #selection == 0 then
    Printf("Atleast one Fixture must be selected")
    return;
  end

  Selection().SETUPMODE = false;

  ajustZForSelect(-1, selection);

  Selection().SETUPMODE = true

  reselectAllFixtures(selection)
end

return main
