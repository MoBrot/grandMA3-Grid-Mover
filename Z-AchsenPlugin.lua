local luaComponentHandle = select(4,...)

fals = "NO"
tru = "YES"

variable_prefix = "z-ajustment-" 
variable_name = variable_prefix .. "selectionconfig"
variable_hookID = variable_prefix .. "hookID"

function executeCommand(cmd)
  Cmd(cmd)
end

local function GetSelectionTable()
    local result = {}

    local fixtureIndex, gridX, gridY, gridZ = SelectionFirst()
    assert(fixtureIndex, "Please select a (range of) fixture(s) and try again.")

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
    
end

function setVariable(name, value)
  SetVar(UserVars(), name, value)
end

function getVariable(name)
  return GetVar(UserVars(), name)
end

function SelectionCallBack()
  Printf("Selection changed!")
  Printf(Selection().COUNTTOTALSELECTED)
end

function main(display, args)
  Selection():Dump()

  if args == "initHook" then

    local pluginHandle = luaComponentHandle:Parent()
    setVariable(variable_hookID, HookObjectChange(SelectionCallBack, Selection(), pluginHandle))
    return
  end

  if args == "unhook" then

    hookID = getVariable(variable_hookID)

      if(hookID ~= "") then
        Unhook()
        setVariable(variable_hookID, "")
      end
    return
  end

  setupToggle = Selection().SETUPMODE;

  if setupToggle == fals then
    Printf("Fixtures Must nbe selected in the Selectiongrid Setup mode!")
  end

  selection = GetSelectionTable()

  if #selection == 0 then
    Print("Atleast one Fixture must be selected")
  end

  Selection().SETUPMODE = fals;

  ajustZForSelect(-1, selection);

end

return main
