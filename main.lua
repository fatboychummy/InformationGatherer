local setPre = "gatherer."
local watching = settings.get(setPre .. "watching")
local funcs = settings.get(setPre .. "funcs")

local function readExit()
  local val = io.read()
  if string.lower(val) == "exit" then
    return false
  end
  return val
end

local function readMult(choices, eMessage)
  -- generate error message if not provided
  if not eMessage then
    eMessage = "Choices are:"
    for i = 1, #choices do
      eMessage = eMessage .. " " .. choices[i]
    end
    eMessage = eMessage .. "."
  end

  -- read
  while true do
    local val = io.read()
    for i = 1, #choices do
      if string.lower(val) == choices[i] then
        return val
      else
        printError(eMessage)
      end
    end
  end
end

local function inputList(start, bFunc, sText, max)
  start = start or {n = 0}
  if not start.n then start.n = #start end
  while true do
    term.clear()
    term.setCursorPos(1, 1)
    for i = 1, start.n do
      --print(i)
      print(string.format("%d: %s (%s)",
                          i,
                          start[i],
                          tostring(bFunc(start[i]))
                          ))
    end
    print()
    print(sText)
    print("Enter id to remove, or type 'exit' to finish.")
    term.setTextColor(colors.lightGray)
    term.setTextColor(colors.white)
    io.write("> ")
    term.setTextColor(colors.gray)
    local current = readExit()
    term.setTextColor(colors.white)
    if current then
      local nCurrent = tonumber(current)
      if nCurrent then
        if start[nCurrent] then
          print(string.format("Removed %d: %s (%s)",
                              nCurrent,
                              tostring(start[nCurrent]),
                              tostring(bFunc(start[nCurrent]))
                              ))
          table.remove(start, nCurrent)
          start.n = start.n - 1
        end
      else
        start.n = start.n + 1
        start[start.n] = current
        print(string.format("Added %d: %s (%s)",
                            start.n,
                            tostring(current),
                            tostring(bFunc(current))
                            ))
      end
    else
      if max and start.n > max then
        print("Too many inputs, maximum " .. tostring(max) .. ".")
      else
        return start
      end
    end
    os.sleep(1)
  end
end

local function funcWait(f)
  parallel.waitForAny(
    f,
    function()
      -- wait for a key event then exit
      os.pullEvent("key")
    end
  )
end

local function keyTimeout(t)
  local timeOut = false

  funcWait(function()
    -- start a timer for t seconds
    local etmr = os.startTimer(t)
    while true do
      -- pull timer events
      local ev, tmr = os.pullEvent("timer")
      if tmr == etmr then -- until our timer event is pulled
        timeOut = true -- set the main function's return value to true
        return -- exit, killing other thread
      end
    end
  end)

  return timeOut
end

local function main()

end

local function alt()
  local periphs = inputList(
    watching,
    peripheral.getType,
    "Enter peripheral names to watch."
  )
  settings.set(setPre .. "watching", periphs)


  local funcsToWatch = funcs or {}
  for i = 1, periphs.n do
    local methods = peripheral.getMethods(periphs[i])
    methods.n = #methods
    funcsToWatch[periphs[i]] = funcsToWatch[periphs[i]] or methods
    funcsToWatch[periphs[i]] = inputList(
      funcsToWatch[periphs[i]],
      function(x)
        local ok, err = pcall(peripheral.call, periphs[i], x)
        local ret = "errored without args"

        if ok then
          ret = type(err)
        else
          if err:find("No such method") then
            ret = "Doesn't exist"
          end
        end
        return ret
      end,
      "Enter function names to monitor for peripheral '" .. periphs[i] .. "' (" .. peripheral.getType(periphs[i]) .. ")"
    )
  end

  settings.set(setPre .. "funcs", funcsToWatch)


  settings.save(".settings")
  print("Settings have been set, please relaunch program.")
end

-- check if we've done initial setup
if watching and funcs then
  os.sleep()
  print("Press any key to edit watched peripherals...")
  print("(Waiting 5 seconds)")
  if keyTimeout(5) then
    main()
  else
    alt()
  end
else
  alt()
end
