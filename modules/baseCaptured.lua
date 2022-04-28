baseCaptured={}
baseCaptured.version = "1.0.0"
baseCaptured.verbose = false
baseCaptured.requiredLibs = {
    "dcsCommon", -- always
    "cfxZones", -- Zones, of course
}

--[[--
    baseCaptured - Detects when the assigned base has been captured, idea and first implementation by cloose

    Version History
    1.0.0 - Initial version based on cloose's code
	
--]]--

baseCaptured.zones = {}


function baseCaptured.createZone(theZone)
    -- find closest base
	theZone.theBase = dcsCommon.getClosestAirbaseTo(theZone.point)
	theZone.baseName = theZone.theBase:getName()
	theZone.currentOwner = theZone.theBase:getCoalition()
	
	-- baseCaptured is the method
	theZone.capturedFlag = cfxZones.getStringFromZoneProperty(theZone, "baseCaptured!", "*none")
	
	
    -- get flag output method
    theZone.capturedMethod = cfxZones.getStringFromZoneProperty(theZone, "method", "inc")
    if cfxZones.hasProperty(theZone, "capturedMethod") then
        theZone.capturedMethod = cfxZones.getStringFromZoneProperty(theZone, "capturedMethod", "inc")
    end

    -- other outputs 
    if cfxZones.hasProperty(theZone, "blueCaptured!") then
        theZone.blueCap = cfxZones.getStringFromZoneProperty(theZone, "blueCaptured!", "*none")
    end
	
    if cfxZones.hasProperty(theZone, "blue!") then
        theZone.blueCap = cfxZones.getStringFromZoneProperty(theZone, "blue!", "*none")
    end
	
	if cfxZones.hasProperty(theZone, "redCaptured!") then
        theZone.redCap = cfxZones.getStringFromZoneProperty(theZone, "blueCaptured!", "*none")
    end
	
    if cfxZones.hasProperty(theZone, "red!") then
        theZone.redCap = cfxZones.getStringFromZoneProperty(theZone, "red!", "*none")
    end
	
	if cfxZones.hasProperty(theZone, "baseOwner") then
        theZone.baseOwner = cfxZones.getStringFromZoneProperty(theZone, "baseOwner", "*none")
		cfxZones.setFlagValueMult(theZone.baseOwner, theZone.currentOwner, theZone)
		if baseCaptured.verbose or theZone.verbose then 
			trigger.action.outText("+++bCap: setting owner for <" .. theZone.name .. "> to " .. theZone.currentOwner, 30)
		end 
    end
	
	if baseCaptured.verbose or theZone.verbose then
		trigger.action.outText("+++bCap: tracking base <" .. theZone.baseName .. "> with <" .. theZone.name .. ">", 30)
    end
end

function baseCaptured.addBaseCaptureZone(theZone)
    table.insert(baseCaptured.zones, theZone)
end

function baseCaptured.triggerZone(theZone)
	local newOwner = theZone.theBase:getCoalition()
    cfxZones.pollFlag(theZone.capturedFlag, theZone.capturedMethod, theZone)
	if newOwner == 1 then -- red 
		if theZone.redCap then 
			cfxZones.pollFlag(theZone.redCap, theZone.capturedMethod, theZone)
		end
	elseif newOwner == 2 then 
		if theZone.blueCap then 
			cfxZones.pollFlag(theZone.blueCap, theZone.capturedMethod, theZone)
		end
	else 
		-- possibly a new side? Neutral doesn't cap
	end
	
    if baseCaptured.verbose or theZone.verbose then
		trigger.action.outText("+++bCap: <" .. theZone.baseName .. "> changed hands from <" .. theZone.currentOwner .. "> to <" .. newOwner .. ">", 30)
        trigger.action.outText("+++bCap: banging captured! with <" .. theZone.capturedMethod .. "> on <" .. theZone.capturedFlag .. "> for " .. theZone.baseName, 30)
    end 
	
	-- change the ownership
	theZone.currentOwner = newOwner
	if theZone.baseOwner then 
		cfxZones.setFlagValueMult(theZone.baseOwner, newOwner, theZone)
		if baseCaptured.verbose or theZone.verbose then 
			trigger.action.outText("+++bCap: owner is " .. newOwner, 30)
		end 
	end
end

-- world event callback
function baseCaptured:onEvent(event)
    -- only interested in S_EVENT_BASE_CAPTURED events
    if event.id ~= world.event.S_EVENT_BASE_CAPTURED then
        return
    end
	if not event.place then 
		trigger.action.outText("+++bCap: capture event without place, aborting.", 30)
		return 
	end

    local baseName = event.place:getName()
    local newCoalition = event.place:getCoalition()

    for idx, aZone in pairs(baseCaptured.zones) do 
        if aZone.baseName == baseName then
            baseCaptured.triggerZone(aZone)
        end
    end
end

function baseCaptured.readConfigZone()
    -- search for configuration zone
    local theZone = cfxZones.getZoneByName("baseCapturedConfig")
    if not theZone then
        return
    end

    baseCaptured.verbose = cfxZones.getBoolFromZoneProperty(theZone, "verbose", false)

    if baseCaptured.verbose then
        trigger.action.outText("+++bCap: read configuration from zone", 30)
    end
end

function baseCaptured.start()
    -- lib check
    if not dcsCommon.libCheck then
        trigger.action.outText("baseCaptured requires dcsCommon", 30)
        return false
    end
    if not dcsCommon.libCheck("baseCaptured", baseCaptured.requiredLibs) then
        return false
    end

    --read configuration
    baseCaptured.readConfigZone()

    -- process all baseCaptured zones
    local zones = cfxZones.getZonesWithAttributeNamed("baseCaptured!")
    for k, aZone in pairs(zones) do
        baseCaptured.createZone(aZone) -- process zone attributes
        baseCaptured.addBaseCaptureZone(aZone) -- add to list
    end

    -- listen for events
    world.addEventHandler(baseCaptured)

    trigger.action.outText("baseCaptured v" .. baseCaptured.version .. " started.", 30)
    return true
end

-- start module
if not baseCaptured.start() then
    trigger.action.outText("baseCaptured aborted: missing libraries", 30)
    baseCaptured = nil
end