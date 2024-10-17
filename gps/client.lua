--<~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~>--
--------------
--------------                Scripted By : Mobin Yengejehi 
--------------
--<~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~>--

if fileExists("script.lua") then 
	fileDelete("script.lua")
end
if fileExists("gps/client.lua") then 
	fileDelete("gps/client.lua")
end
if fileExists("gps/vehicleNodes.lua") then 
	fileDelete("gps/vehicleNodes.lua")
end
if fileExists("3dBlips.lua") then 
	fileDelete("3dBlips.lua") 
end
if fileExists("script.luac") then 
	fileDelete("script.luac")
end
if fileExists("gps/client.luac") then 
	fileDelete("gps/client.luac")
end
if fileExists("gps/vehicleNodes.luac") then 
	fileDelete("gps/vehicleNodes.luac")
end

min, max, cos, sin, rad, deg, atan2 = math.min, math.max, math.cos, math.sin, math.rad, math.deg, math.atan2
sqrt, abs, floor, ceil, random = math.sqrt, math.abs, math.floor, math.ceil, math.random
gsub = string.gsub

local disallowedNodes = {

}

gpsRoute = false
gpsThread = false
gpsWaypoints = {}
nextWp = false
turnAround = false
currentWaypoint = false
waypointInterpolation = false
waypointEndInterpolation = false
reRouting = false

local waypointColShapes = false
local colShapes = {}

local currentSound = false
local playedSounds = {}

local checkForRerouteTimer = false
local rerouteCheckRate = 1500

local distanceDivider = 0.9

addEventHandler("onClientVehicleEnter", getRootElement(),
	function (player)
		if player == localPlayer then
			--carCanGPS()

			local destination = getElementData(source, "gpsDestination")
			if destination then

				gpsThread = coroutine.create(makeRoute)

				coroutine.resume(gpsThread, destination[1], destination[2], true)
			end
		end
	end
)

addEventHandler("onClientVehicleExit", getRootElement(),
	function (player)
		if player == localPlayer and gpsRoute then
			endRoute()
		end
	end
)

addEventHandler("onClientElementDestroy", getRootElement(),
	function ()
		if source == occupiedVehicle and getElementData(source, "gpsDestination") then
			setElementData(source, "gpsDestination", false)
			
			if gpsRoute then
				endRoute()
			end
		end
	end
)

addEventHandler("onClientResourceStart", getResourceRootElement(),
	function ()
		for _, node in ipairs(disallowedNodes) do
			local area = math.floor(node[1] / 65536)
			local copy = shallowcopy(vehicleNodes[area][node[1]].neighbours)
			
			vehicleNodes[area][node[1]].neighbours = {}
			
			for k, v in pairs(copy) do
				if k ~= node[2] then
					vehicleNodes[area][node[1]].neighbours[k] = v
				end
			end

		end

		occupiedVehicle = getPedOccupiedVehicle(localPlayer)
		
		if occupiedVehicle then
			--carCanGPS()

			local destination = getElementData(occupiedVehicle, "gpsDestination")
			if destination then

				gpsThread = coroutine.create(makeRoute)

				coroutine.resume(gpsThread, destination[1], destination[2], true)
			end
		end
	end
)

local nodesRendering = false
--[[
addCommandHandler("tognodes",
	function ()
		if getElementData(localPlayer, "admin_level") >= 2 then
			if nodesRendering then
				nodesRendering = false
				removeEventHandler("onClientRender", getRootElement(), renderTheNodes)
			else
				nodesRendering = true
				addEventHandler("onClientRender", getRootElement(), renderTheNodes)
			end
		end
	end
)

function renderTheNodes()
	local playerPosX, playerPosY, playerPosZ = getElementPosition(localPlayer)
	local areaID = math.floor((playerPosX + 3000) / 750) + math.floor((playerPosY + 3000) / 750) * 8
	local drawn = {}
	
	for id, node in pairs(vehicleNodes[areaID]) do
		local distance = getDistanceBetweenPoints3D(playerPosX, playerPosY, playerPosZ, node.x, node.y, playerPosZ)

		if distance <= 50 then
			local screenX, screenY = getScreenFromWorldPosition(node.x, node.y, node.z + 1)
			
			if screenX and screenY then
				dxDrawText(tostring(id), screenX - 10, screenY - 5, 0, 0, -1, 0.75, Roboto18)
			end
			
			for neighbour in pairs(node.neighbours) do
				if not drawn[id .. "-" .. neighbour] then
					local nodeNeighbour = vehicleNodes[math.floor(neighbour / 65536)][neighbour]

					dxDrawLine3D(node.x, node.y, node.z + 1, nodeNeighbour.x, nodeNeighbour.y, nodeNeighbour.z + 1, tocolor(50, 50, 200), 3)

					drawn[id .. "-" .. neighbour] = true
				end
			end
		end
	end
end]]

function getPositionFromElementOffset(element, x, y, z)
	local matrix = getElementMatrix(element)
	local posX = x * matrix[1][1] + y * matrix[2][1] + z * matrix[3][1] + matrix[4][1]
	local posY = x * matrix[1][2] + y * matrix[2][2] + z * matrix[3][2] + matrix[4][2]
	local posZ = x * matrix[1][3] + y * matrix[2][3] + z * matrix[3][3] + matrix[4][3]
	return posX, posY, posZ
end

local function getAngle(x1, y1, x2, y2)
	local angle = math.atan2(x2, y2) - math.atan2(x1, y1)
	
	if angle <= -math.pi then
		angle = angle + math.pi * 2
	elseif angle > math.pi then
		angle = angle - math.pi * 2
	end
	
	return angle
end

function shallowcopy(t)
	if type(t) ~= "table" then
		return t
	end
	
	local target = {}
	for k,v in pairs(t) do
		target[k] = v
	end

	return target
end

local function calculatePath(startNode, endNode)
	local usedNodes = {[startNode.id] = true}
	local currentNodes = {}
	local ways = {}
	
	for id, distance in pairs(startNode.neighbours) do
		usedNodes[id] = true
		currentNodes[id] = distance
		ways[id] = {startNode.id}
	end
	
	while true do
		local currentNode = -1
		local maxDistance = 10000
		
		for id, distance in pairs(currentNodes) do
			if distance < maxDistance then
				currentNode = id
				maxDistance = distance
			end
		end
		
		if currentNode == -1 then
			return false
		end
		
		if endNode.id == currentNode then
			local lastNode = currentNode
			local foundedNodes = {}
			
			while tonumber(lastNode) do
				local node = getVehicleNodeByID(lastNode)

				table.insert(foundedNodes, 1, node)

				lastNode = ways[lastNode]
			end
			
			return foundedNodes
		end
		
		for id, distance in pairs(getVehicleNodeByID(currentNode).neighbours) do
			if not usedNodes[id] then
				ways[id] = currentNode
				currentNodes[id] = maxDistance + distance
				usedNodes[id] = true
			end
		end
		
		currentNodes[currentNode] = nil
	end
end

function getVehicleNodeByID(nodeID)
	local areaID = math.floor(nodeID / 65536)

	if areaID >= 0 and areaID <= 63 then
		return vehicleNodes[areaID][nodeID]
	end
end

function getVehicleNodeClosestToPoint(x, y)
	local foundedNode = -1
	local lastNodeDistance = 10000
	local areaID = math.floor((x + 3000) / 750) + math.floor((y + 3000) / 750) * 8
	
	if not vehicleNodes[areaID] then
		return false
	end
	
	for _, node in pairs(vehicleNodes[areaID]) do
		local nodeDistance = getDistanceBetweenPoints2D(x, y, node.x, node.y)
		
		if lastNodeDistance > nodeDistance then
			lastNodeDistance = nodeDistance
			foundedNode = node
		end
	end
	
	return foundedNode
end

function playGPSSound(sounds)
	if isElement(currentSound) then
		destroyElement(currentSound)
	end
	
	if isTimer(currentSoundTimer) then
		killTimer(currentSoundTimer)
	end

	if carCanGPSVal ~= "off" then
		--currentSound = playSound("widgets/radar/files/gps/sounds/" .. carCanGPSVal .. "/ding.ogg")
		--currentSoundTimer = setTimer(playNextGPSSound, getSoundLength(currentSound) * 1000, 1, split(sounds, ";"), 1)
	end
end

function playNextGPSSound(sounds, count)
	if carCanGPSVal ~= "off" then
		--currentSound = playSound("widgets/radar/files/gps/sounds/" .. carCanGPSVal .. "/" .. sounds[count] .. ".ogg")
		
		if count < #sounds then
			--currentSoundTimer = setTimer(playNextGPSSound, getSoundLength(currentSound) * 1000, 1, sounds, count + 1)
		end
	end
end

function playOneGPSSound(sound)
	if isElement(currentSound) then
		destroyElement(currentSound)
	end
	if isTimer(currentSoundTimer) then
		killTimer(currentSoundTimer)
	end

	if carCanGPSVal ~= "off" then
		--currentSound = playSound("widgets/radar/files/gps/sounds/" .. carCanGPSVal .. "/" .. sound .. ".ogg")
	end
end

function calculateRoute(x1, y1, x2, y2)
	local startNode = getVehicleNodeClosestToPoint(x1, y1)
	local endNode = getVehicleNodeClosestToPoint(x2, y2)
	
	if not startNode then
		playOneGPSSound("gpslost")
		return false
	end
	
	if not endNode then
		exports["MG_notification"]:addNotification("Baraye Maghsade Morede Nazar Masiri Yaft Nashod.","error")
		return false
	end
	
	return calculatePath(startNode, endNode)
end

function endRoute()
	if gpsRoute then
		if waypointColShapes then
			for k, v in pairs(waypointColShapes) do
				colShapes[waypointColShapes[k]] = nil
				
				if isElement(v) then
					destroyElement(v)
				end
					
				waypointColShapes[k] = nil
			end
		end
		
		nextWp = false
		
		if isTimer(checkForRerouteTimer) then
			killTimer(checkForRerouteTimer)
		end
		
		checkForRerouteTimer = false
		clearGPSRoute()
		waypointEndInterpolation = getTickCount()
		gpsRoute = false
		gpsThread = false
	end
end

function reRoute(checkShape)
	if not gpsRoute or not occupiedVehicle then
		return
	end
	
	local vehiclePosX, vehiclePosY = getElementPosition(occupiedVehicle)
	
	if getDistanceBetweenPoints2D(gpsRoute[checkShape].x, gpsRoute[checkShape].y, vehiclePosX, vehiclePosY) >= 50 then
		if not makeRoute(lastDestinationX, lastDestinationY, true) then
			checkForRerouteTimer = setTimer(checkForReroute, 10000, 1)
			reRouting = true
		end
	else
		checkForRerouteTimer = setTimer(checkForReroute, rerouteCheckRate, 1)
		reRouting = false
	end
end

function checkForReroute()
	if not gpsRoute or not occupiedVehicle then
		return
	end
	
	local vehiclePosX, vehiclePosY = getElementPosition(occupiedVehicle)
	local dist = getDistanceBetweenPoints2D(gpsRoute[currentNode].x, gpsRoute[currentNode].y, vehiclePosX, vehiclePosY)

	if dist >= 30 and dist < 80 and gpsRoute[currentNode + 1] and lastTurnAroundCheck and getTickCount() - lastTurnAroundCheck > 5000 then
		local x, y = getPositionFromElementOffset(occupiedVehicle, -1, 0, 0)
		local angle = math.deg(getAngle(gpsRoute[currentNode + 1].x - gpsRoute[currentNode].x, gpsRoute[currentNode + 1].y - gpsRoute[currentNode].y, x - vehiclePosX, y - vehiclePosY))
		
		if angle > 0 then
			lastTurnAroundCheck = getTickCount()
			checkForRerouteTimer = setTimer(checkForReroute, rerouteCheckRate, 1)

			playGPSSound("forduljvissza")

			turnAround = true
			reRouting = false

			return
		else
			turnAround = false
			reRouting = false
		end
	end
	
	if isTimer(checkForRerouteTimer) then
		killTimer(checkForRerouteTimer)
	end
	
	if dist > 100 then
		checkForRerouteTimer = setTimer(reRoute, math.random(3000, 5000), 1, currentNode)
		reRouting = getTickCount()
		playGPSSound("ujratervezes")
	else
		checkForRerouteTimer = setTimer(checkForReroute, rerouteCheckRate, 1)
	end
end

function makeRoute(destinationX, destinationY, uTurned)
	waypointInterpolation = false
	
	if isElement(currentSound) then
		destroyElement(currentSound)
	end
	
	if isTimer(currentSoundTimer) then
		killTimer(currentSoundTimer)
	end
	
	if isTimer(checkForRerouteTimer) then
		killTimer(checkForRerouteTimer)
	end
	
	clearGPSRoute()
	gpsWaypoints = {}
	turnAround = false
	gpsLines = {}
	gpsRoute = false
	
	if waypointColShapes then
		for k, v in pairs(waypointColShapes) do
			colShapes[waypointColShapes[k]] = nil
			
			if isElement(v) then
				destroyElement(v)
			end
				
			waypointColShapes[k] = nil
		end
	end
	
	waypointColShapes = {}
	colShapes = {}
	
	if not occupiedVehicle then
		return
	end
	
	local vehiclePosX, vehiclePosY = getElementPosition(occupiedVehicle)
	
	local currentZoneName = getZoneName(vehiclePosX, vehiclePosY, 0)
	local currentCityName = getZoneName(vehiclePosX, vehiclePosY, 0, true)
	local zoneName = getZoneName(destinationX, destinationY, 0)
	local cityName = getZoneName(destinationX, destinationY, 0, true)
	local routePath = calculateRoute(vehiclePosX, vehiclePosY, destinationX, destinationY)
	
	if not routePath then
		if not uTurned then
			exports["MG_notification"]:addNotification("Baraye Maghsade Morede Nazar Masiri Yaft Nashod.","error")
		else
			playOneGPSSound("gpslost")
		end
		
		setElementData(occupiedVehicle, "gpsDestination", false)

		return false
	end
	
	gpsRoute = routePath
	nextWp = 1
	currentWaypoint = 0
	currentNode = 1
	checkForRerouteTimer = setTimer(checkForReroute, rerouteCheckRate, 1)

	local turns = {}

	for i, node in ipairs(gpsRoute) do
		local nextNode = gpsRoute[i + 1]
		local previousNode = gpsRoute[i - 1]
		
		if i > 1 and i < #gpsRoute then
			for k in pairs(node.neighbours) do
				if previousNode and nextNode and k ~= previousNode.id and k ~= nextNode.id then
					local angle = math.deg(getAngle(node.x - previousNode.x, node.y - previousNode.y, nextNode.x - node.x, nextNode.y - node.y))
					
					if angle > 10 then
						table.insert(turns, {i, "right"})
						break
					end
					
					if angle < -10 then
						table.insert(turns, {i, "left"})
					end
					
					break
				end
			end
		end
		
		waypointColShapes[i] = createColTube(node.x, node.y, node.z - 0.3, 8, 5)
		colShapes[waypointColShapes[i]] = i
		addGPSLine(node.x, node.y,node.z)
	end
	
	local currentWaypoint = 1

	for i = 1, #turns do
		local currentWaypointData = gpsRoute[currentWaypoint]
		local nodeId = tonumber(turns[i][1])

		if not nodeId then
			nodeId = #gpsRoute
		end

		local waypointDistance = 0

		for j = currentWaypoint, nodeId do
			waypointDistance = waypointDistance + getDistanceBetweenPoints2D(gpsRoute[j].x, gpsRoute[j].y, currentWaypointData.x, currentWaypointData.y)
			currentWaypointData = gpsRoute[j]
		end
		
		currentWaypointData = gpsRoute[currentWaypoint]
		
		if waypointDistance > 600 then
			local nodeDistance = 0
			
			for j = currentWaypoint, nodeId do
				nodeDistance = nodeDistance + getDistanceBetweenPoints2D(gpsRoute[j].x, gpsRoute[j].y, currentWaypointData.x, currentWaypointData.y)
				
				if waypointDistance - 500 < nodeDistance then
					table.insert(gpsWaypoints, {j, "forward"})
					break
				end
			end
		end
	
		currentWaypoint = nodeId
		table.insert(gpsWaypoints, turns[i])
	end
	
	table.insert(gpsWaypoints, {"end", "end"})
	
	local firstWaypointDistance, prevWaypointData = 0, gpsRoute[1]

	for i = 1, tonumber(gpsWaypoints[nextWp][1]) or #gpsRoute do
		firstWaypointDistance = firstWaypointDistance + getDistanceBetweenPoints2D(gpsRoute[i].x, gpsRoute[i].y, prevWaypointData.x, prevWaypointData.y)
		prevWaypointData = gpsRoute[i]
	end

	gpsWaypoints[nextWp][3] = firstWaypointDistance / distanceDivider
	
	local x, y = getPositionFromElementOffset(occupiedVehicle, -1, 0, 0)
	local angle = math.deg(getAngle(gpsRoute[2].x - gpsRoute[1].x, gpsRoute[2].y - gpsRoute[1].y, x - vehiclePosX, y - vehiclePosY))
	
	if angle > 0 then
		lastTurnAroundCheck = getTickCount()
		
		if not uTurned then
			currentSound = setTimer(playGPSSound, 1750, 1, "forduljvissza")
		else
			playGPSSound("forduljvissza")
		end
		
		turnAround = true
	end

	lastDestinationX = destinationX
	lastDestinationY = destinationY

	processGPSLines()
	
	if isElement(selectedRouteSound) then
		destroyElement(selectedRouteSound)
	end
	
	selectedRouteSound = false
	
	if not uTurned then
		if carCanGPSVal ~= "off" then
			--selectedRouteSound = playSound("widgets/radar/files/gps/sounds/" .. carCanGPSVal .. "/uticel.ogg")
		end
	end
end

function processGPSLines()
	return 5
end

addEventHandler("onClientColShapeHit", getRootElement(),
	function (element)
		if colShapes[source] and element == localPlayer then
			local currentShape = colShapes[source]
			
			clearGPSRoute()
			
			if currentShape >= 2 then
				if isTimer(checkForRerouteTimer) then
					killTimer(checkForRerouteTimer)
				end
				
				checkForRerouteTimer = false
				turnAround = false
			end
			
			if currentShape == #gpsRoute then
				--playGPSSound("erkezes;a_celhoz")
				exports.MG_Notification:addNotification("Shoma Be Maghsade Khod Residid.","success");
				for i = 1, currentShape do
					if isElement(waypointColShapes[i]) then
						destroyElement(waypointColShapes[i])
					end
					
					waypointColShapes[i] = nil
				end
				
				nextWp = false
				
				if isTimer(checkForRerouteTimer) then
					killTimer(checkForRerouteTimer)
				end
				
				checkForRerouteTimer = false
				setElementData(occupiedVehicle, "gpsDestination", false)

				return
			else
				for i = 1, currentShape do
					if isElement(waypointColShapes[i]) then
						destroyElement(waypointColShapes[i])
					end
					
					waypointColShapes[i] = nil
				end
				
				for i = currentShape, #gpsRoute do
					addGPSLine(gpsRoute[i].x, gpsRoute[i].y,gpsRoute[i].z)
				end
				
				if isTimer(checkForRerouteTimer) then
					killTimer(checkForRerouteTimer)
				end
				
				currentNode = currentShape + 1
				lastTurnAroundCheck = getTickCount()
				checkForRerouteTimer = setTimer(checkForReroute, rerouteCheckRate, 1)
				reRouting = false
				processGPSLines()
			end

			if gpsWaypoints[nextWp] and gpsWaypoints[nextWp][1] ~= "end" then
				if currentShape >= gpsWaypoints[nextWp][1] then -- When you reach the waypoint, get the next waypoint distance
					nextWp = nextWp + 1
					playedSounds = {}
					
					local nextWaypointDistance, prevWaypointData = 0, gpsRoute[currentShape]

					for i = currentShape, tonumber(gpsWaypoints[nextWp][1]) or #gpsRoute do
						nextWaypointDistance = nextWaypointDistance + getDistanceBetweenPoints2D(gpsRoute[i].x, gpsRoute[i].y, prevWaypointData.x, prevWaypointData.y)
						prevWaypointData = gpsRoute[i]
					end

					gpsWaypoints[nextWp][3] = nextWaypointDistance / distanceDivider
				else -- If you have not reached the next waypoint then check the distance, update and give instructions if necessary
					local nextWaypointDistance, prevWaypointData = 0, gpsRoute[currentShape]

					for i = currentShape, gpsWaypoints[nextWp][1] do
						nextWaypointDistance = nextWaypointDistance + getDistanceBetweenPoints2D(gpsRoute[i].x, gpsRoute[i].y, prevWaypointData.x, prevWaypointData.y)
						prevWaypointData = gpsRoute[i]
					end

					gpsWaypoints[nextWp][3] = nextWaypointDistance / distanceDivider

					if gpsWaypoints[nextWp][2] == "forward" and not playedSounds["forward"] and currentShape > 2 then
						if gpsWaypoints[nextWp - 1] and currentShape < 2 + gpsWaypoints[nextWp - 1][1] then
							return
						end
						
						playedSounds["forward"] = true
						playGPSSound("egyenes")

						return
					end
					
					local nextWaypointDistance = math.floor(gpsWaypoints[nextWp][3] / 10) * 10
					
					if nextWaypointDistance <= 50 and not playedSounds[50] then
						playedSounds[50] = true
						playedSounds[300] = true
						playedSounds[600] = true
						playedSounds[1000] = true
						playedSounds[1500] = true
						playedSounds[2000] = true
						
						if gpsWaypoints[nextWp][2] == "left" then
							playGPSSound("fordulj;balra")
						elseif gpsWaypoints[nextWp][2] == "right" then
							playGPSSound("fordulj;jobbra")
						end
						
						return
					end

					if nextWaypointDistance > 280 and nextWaypointDistance <= 300 and not playedSounds[300] then
						playedSounds[300] = true
						playedSounds[600] = true
						playedSounds[1000] = true
						playedSounds[1500] = true
						playedSounds[2000] = true
						
						if gpsWaypoints[nextWp][2] == "left" then
							playGPSSound("menj;300;metert;majd;fordulj;balra")
						elseif gpsWaypoints[nextWp][2] == "right" then
							playGPSSound("menj;300;metert;majd;fordulj;jobbra")
						end
						
						return
					end
					
					if nextWaypointDistance > 580 and nextWaypointDistance <= 600 and not playedSounds[600] then
						playedSounds[600] = true
						playedSounds[1000] = true
						playedSounds[1500] = true
						playedSounds[2000] = true
						
						if gpsWaypoints[nextWp][2] == "left" then
							playGPSSound("menj;600;metert;majd;fordulj;balra")
						elseif gpsWaypoints[nextWp][2] == "right" then
							playGPSSound("menj;600;metert;majd;fordulj;jobbra")
						end
						
						return
					end
					
					if nextWaypointDistance > 980 and nextWaypointDistance <= 1000 and not playedSounds[1000] then
						playedSounds[1000] = true
						playedSounds[1500] = true
						playedSounds[2000] = true

						if gpsWaypoints[nextWp][2] == "left" or gpsWaypoints[nextWp][2] == "right" then
							playGPSSound("menj;1;kilometert")
						end
						
						return
					end
					
					if nextWaypointDistance > 1480 and nextWaypointDistance <= 1500 and not playedSounds[1500] then
						playedSounds[1500] = true
						playedSounds[2000] = true
						
						if gpsWaypoints[nextWp][2] == "left" or gpsWaypoints[nextWp][2] == "right" then
							playGPSSound("menj;tobb_mint;1;kilometert")
						end
						
						return
					end

					if nextWaypointDistance > 1980 and nextWaypointDistance <= 2000 and not playedSounds[2000] then
						playedSounds[2000] = true
						
						if gpsWaypoints[nextWp][2] == "left" or gpsWaypoints[nextWp][2] == "right" then
							playGPSSound("menj;2;kilometert")
						end
						
						return
					end
				end
			else
				local nextWaypointDistance, prevWaypointData = 0, gpsRoute[currentShape]

				for i = currentShape, #gpsRoute do
					nextWaypointDistance = nextWaypointDistance + getDistanceBetweenPoints2D(gpsRoute[i].x, gpsRoute[i].y, prevWaypointData.x, prevWaypointData.y)
					prevWaypointData = gpsRoute[i]
				end
				
				gpsWaypoints[nextWp][3] = nextWaypointDistance / distanceDivider
			end

			if gpsWaypoints[nextWp] and gpsWaypoints[nextWp][1] == "end" and not playedSounds["finish"] and currentShape > 2 and currentShape > #gpsRoute - 3 then
				playedSounds["finish"] = true
				playGPSSound("erkezes;a_celhoz")
			end
		end
	end
)

function isEventHandlerAdded(eventName, attachedTo, func)
	if type(eventName) == "string" and  isElement(attachedTo) and type(func) == "function" then
		local isAttached = getEventHandlers(eventName, attachedTo)
		
		if type(isAttached) == "table" and #isAttached > 0 then
			for i, v in ipairs(isAttached) do
				if v == func then
					return true
				end
			end
		end
	end
	
	return false
end