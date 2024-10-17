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

function saveDataOnXML(name,s,enc)
    local save = xmlLoadFile("save.xml")
    if not save then 
        save = xmlCreateFile("save.xml","blackWhite")
    end
    local node = xmlFindChild(save,tostring(name),0)
    if not node then 
        node = xmlCreateChild(save,tostring(name))
    end
    if enc then 
        xmlNodeSetValue(node,encryptString(tostring(s),getLocalPlayer()))
    else
        xmlNodeSetValue(node,tostring(s))
    end
    xmlSaveFile(save)
    xmlUnloadFile(save)
    return true
end

function getDataFromXML(name,enc)
    local save = xmlLoadFile("save.xml")
    if save then 
        local node = xmlFindChild(save,tostring(name),0)
        if node then 
            if enc then 
                local datas = decryptString(tostring(xmlNodeGetValue(node)),getLocalPlayer())
                xmlUnloadFile(save)
                return datas 
            else
                local datas = tostring(xmlNodeGetValue(node))
                xmlUnloadFile(save)
                return datas 
            end
        end
    end
    return ""
end

local white = "#FFFFFF";
local sX, sY = guiGetScreenSize();
local screen = {guiGetScreenSize()}
local width, height = 0,0;
local posX,posY = 5, sY-height-15;
local waterColor = tocolor(174, 182, 190, 255) or tocolor(0,150,255);
local bSize = 20;
local showBigMap = false;
local minimapTarget = dxCreateRenderTarget(350,250,false);local recTarget = dxCreateRenderTarget(1000,1000,false)
local arrowTexture = dxCreateTexture("files/arrow.png","dxt3",true);
local targetTexture = dxCreateTexture("files/logo.png","dxt3",true);
local shadowTexture = dxCreateTexture("files/shadow.png","dxt3",true);
local textures = {dxCreateTexture( "files/radar.jpg", "dxt5", true),dxCreateTexture( "files/map3.png", "dxt5", true)}
for i,t in ipairs(textures) do 
	dxSetTextureEdge(t, 'border', waterColor);
end
local texture = textures[tonumber(getDataFromXML("state")) or 1];local flash = dxCreateTexture("files/flash3D.png")
local imageWidth, imageHeight = dxGetMaterialSize(texture);
local blipTextures = {};
local zoneHeight = 25
local gpsLineHeight = 60
local markColor = false 
local iconSize = 40
local lines3D = true 
local radarshowstatus = true
local vipVehicles = {555,558,507,535,579,434,589,474,526,491,527,411,436,477,400,533,401,603,559,502,562,541,561,480,419}

local mapRatio = 6000 / imageWidth;

blipNames = {
    ["target"] = "nothing",
    [1] = "Police",
    [2] = "North",
    [3] = "Rob",
    [4] = "Rob",
    [5] = "Rob",
    [6] = "Army",
    [7] = "Kelid Sazi",
    [8] = "Amoo Kasif",
    [9] = "BoatShop",
    [10] = "BookStore",
    [11] = "CarShop",
    [12] = "GPS Location ",
    [13] = "Bank",
    [14] = "Bar",
    [15] = "Court",
    [16] = "Electronic",
    [17] = "Fishing",
    [18] = "FixCar",
    [19] = "CostumeShop",
    [20] = "Sale",
    [21] = "GunShop",
    [22] = "ChopperShop",
    [23] = "Island",
    [24] = "Jewerly",
    [25] = "Fuel",
    [26] = "Ghasabi",
    [27] = "SkinShop",
    [28] = "SkinShop",
    [29] = "Mechanic",
    [30] = "BikeShop",
    [31] = "Nav",
    [32] = "Parking",
    [33] = "Estakhr",
    [34] = "Magsad",
    [35] = "Sheriff",
    [36] = "SuperMarket",
    [37] = "Taxi",
    [38] = "TownHall",
    [39] = "Restaurant",
	[40] = "Medic",
	[41] = "Premium SkinShop",
	[42] = "Store PR",
	[43] = "House PR",
 	[44] = "TV",
 	[45] = "Federal",
 	[46] = "Delivery",
 	[47] = "Forodgah",
	[50] = "Kelisa",
	[51] = "Prison",
	[52] = "Hack-Prison",
	[53] = "Hack-Prison",
	[55] = "Mohal Tamire Bargh",
	[56] = "Daryafte Mashin Electronic",
	[57] = "Camp Tark Etiad",
	[58] = "Spin",
	[63] = "Uncuff",
	[61] = "Mohal Ghate Choob",
}

addCommandHandler ("togradar", function()
	radarshowstatus = not radarshowstatus
end)

addEventHandler("onClientResourceStart",getRootElement(),function(res)
	if tostring(getResourceName(res)) == "fv_engine" or res == getThisResource() then
		font = "arial"
		font2 = "arial"  
		font3 = dxCreateFont("files/fonts/font.ttf",20)
		dxSetRenderTarget(recTarget,true)
		dxDrawRectangle(0,0,1000,1000,tocolor(255,255,255))
		dxSetRenderTarget()
	end
end)

addEventHandler("onClientRestore",getRootElement(),function(did)
	if did then 
		dxSetRenderTarget(recTarget,true)
		dxDrawRectangle(0,0,1000,1000,tocolor(255,255,255))
		dxSetRenderTarget()
	end
end)

function drawMy3DMaterial(x,y,z,vx,vy,vz,material,w,h,color,rot)
	local offFaceX = math.atan2(vz,(vx^2+vy^2)^0.5)
	local offFaceZ = math.atan2(vx,vy)
	local _x,_y,_z = math.sin(offFaceX)*math.sin(offFaceZ)*math.cos(rot)+math.sin(rot)*math.cos(offFaceZ),math.sin(offFaceX)*math.cos(offFaceZ)*math.cos(rot)-math.sin(rot)*math.sin(offFaceZ),-math.cos(offFaceX)*math.cos(rot)
	w,h = w/2,h/2
	local topX,topY,topZ = _x*h,_y*h,_z*h
	local leftX,leftY,leftZ = topY*vz-vy*topZ,topZ*vx-vz*topX,topX*vy-vx*topY --Left Point
	local leftModel = (leftX^2+leftY^2+leftZ^2)^0.5
	local leftX,leftY,leftZ = leftX/leftModel*w,leftY/leftModel*w,leftZ/leftModel*w
	local rightBottom = {leftX+topX+x,leftY+topY+y,leftZ+topZ+z,color,0,1}
	local rightTop = {leftX-topX+x,leftY-topY+y,leftZ-topZ+z,color,0,0}
	local leftBottom = {-leftX+topX+x,-leftY+topY+y,-leftZ+topZ+z,color,1,1}
	local leftTop= {-leftX-topX+x,-leftY-topY+y,-leftZ-topZ+z,color,1,0}
	dxDrawMaterialPrimitive3D("trianglestrip",material,false,leftTop,leftBottom,rightTop,rightBottom)
end

local circleShader = dxCreateShader([==[
	// Scripted By : Mobin Yengejehi
	float width = 100;float height = 100;
	float ringRate = 10;
	float start = -3.14;float stop = 3.14;
	float4 createCircle(float4 dif : COLOR0,float2 tex : TEXCOORD0):COLOR0{
		float2 uv = float2(tex.x,tex.y) - float2(0.5,0.5);
		float angle = atan2(-uv.x,uv.y);
		if (start > stop){
			if (angle < start && angle > stop){
				return 0;
			}
		}else{
			if (angle < start || angle > stop){
				return 0;
			}
		}
		float2 vectors = normalize(uv);
		float radius = lerp(width,height,vectors.y*vectors.y);float ringWidth = ringRate/radius;
		float dis = sqrt(dot(uv,uv));
		if ((dis > 0.5) || (dis < 0.5 - ringWidth)){
			return 0;
		}else{
			return dif;
		} 
	}
	technique drawCircle{
		pass P0{
			PixelShader = compile ps_2_0 createCircle();
		}
	}
]==])

function drawCustomRing(x, y, width, height, color, angleStart, angleSweep, borderWidth,gui )
	if not isElement(circleShader) then 
		return false 
	end
	height = height or width
	color = color or tocolor(255,255,255)
	borderWidth = borderWidth or 1e9
	angleStart = angleStart or 0
	angleSweep = angleSweep or 360 - angleStart
	if ( angleSweep < 360 ) then
		angleEnd = math.fmod( angleStart + angleSweep, 360 ) + 0
	else
		angleStart = 0
		angleEnd = 360
	end
	x = x - width / 2
	y = y - height / 2
	dxSetShaderValue ( circleShader, "width", width );
	dxSetShaderValue ( circleShader, "height", height );
	dxSetShaderValue ( circleShader, "ringRate", borderWidth );
	dxSetShaderValue ( circleShader, "start", math.rad( angleStart ) - math.pi );
	dxSetShaderValue ( circleShader, "stop", math.rad( angleEnd ) - math.pi );
	dxDrawImage( x, y, width, height, circleShader, 0, 0, 0, color ,gui)
end

function drawZone(x,y,w,r,g,b,a,gui)
	a = tonumber(a) or 255
	local ticks = {getTickCount()/700,(getTickCount() - 1000)/700,(getTickCount() - 1500)/700}
	local alphas = {math.mobin(ticks[1])*a + 50,math.mobin(ticks[2])*a + 50,math.mobin(ticks[3])*a + 50}
	drawCustomRing(x,y,w,_,tocolor(r,g,b,alphas[1]),0,360,w/10,gui)
	drawCustomRing(x,y,w + (w/10)*4,_,tocolor(r,g,b,alphas[2]),0,360,w/10,gui)
	drawCustomRing(x,y,w + (w/10)*8,_,tocolor(r,g,b,alphas[3]),0,360,w/10,gui)
end

addEventHandler("onClientPreRender",root,function()
	if not getElementData(localPlayer,"loggedin") or getElementData(localPlayer,"loggedin") ~= 1 or isTransferBoxActive() or (getElementData(getLocalPlayer(),"hide_hud") == "0") then return false end
	if showBigMap then
		return
	end
	if getElementDimension(localPlayer) == 0 and radarshowstatus == true then
		width, height = screen[1] / 4.5 or 350, screen[2]/4 or 250;
		posX,posY = screen[1]/90,screen[2]/1.4;
		local px,py, pz = getElementPosition(localPlayer);
		local _, _, camZ = getElementRotation(getCamera());

		local mW, mH = dxGetMaterialSize(minimapTarget);
		if mW ~= width or mH ~= height then 
			destroyElement(minimapTarget);
			minimapTarget = dxCreateRenderTarget(width, height,false);
		end
		dxSetRenderTarget(minimapTarget, true);
		local mW, mH = dxGetMaterialSize(minimapTarget);
		local ex,ey = mW/2 -px/(6000/imageWidth), mH/2 + py/(6000/imageHeight);
		dxDrawRectangle(0,0,mW,mH, waterColor);
		dxDrawImage(ex - imageWidth/2, (ey - imageHeight/2), imageWidth, imageHeight, texture, camZ, (px/(6000/imageWidth)), -(py/(6000/imageHeight)), tocolor(255, 255, 255, 255));
		if isElement(recTarget) then 
			for i,area in ipairs(getElementsByType("radararea")) do 
				local data = {};data["pos"] = {getElementPosition(area)}
				data["size"] = {getRadarAreaSize(area)}
				data["color"] = {getRadarAreaColor(area)};data["middleColor"] = getElementData(area,"middleColor")
				data["type"] = getElementData(area,"areaType") or "default"
				local dis = getDistanceBetweenPoints2D(px,py,data["pos"][1],data["pos"][2])
				local dist = dis/(6000/((imageWidth + imageHeight)/2))
				local rot = findRotation(data["pos"][1],data["pos"][2],px,py) - camZ
				local pos = {getPointFromDistanceRotation( (posX+width+posX)/2, (posY+posY+height)/2, math.min(dist, math.sqrt((posY+posY+height)/2-posY^2 + posX+width-(posX+width+posX)/2^2)), rot )}
				if data["type"] == "circle" then 
					dxDrawCircle(pos[1] - posX,pos[2] - posY,data["size"][1],0,360,tocolor(unpack(data["color"])),tocolor(unpack(data["middleColor"] or data["color"])),32,1)
				elseif data["type"] == "danger" then 
					drawZone(pos[1] - posX,pos[2] - posY,data["size"][1],data["color"][1],data["color"][2],data['color'][3],data['color'][4])
				else
				    dxDrawImage(pos[1] - data["size"][1]/2 - posX,pos[2] - data["size"][2]/2 - posY,data["size"][1],data["size"][2],recTarget,camZ,0,0,tocolor(unpack(data["color"])))
				end
			end
		end
		dxSetRenderTarget();

		local sin = math.mobin(getTickCount()/2000)*255

		dxDrawRectangle(posX, posY, width, height, tocolor(255, 255, 255, 255),true); --radar_color
		dxDrawRectangle(posX, posY, 5, height, tocolor(sin,30,-sin, 255),true);

		dxDrawImage(posX+6,posY+3,width-9,height-6,minimapTarget,0,0,0,tocolor(255,255,255),true);

		markColor = math.mobin(getTickCount()/5000)*255
		local mCenterX , mCenterY = posX + width/2, posY + (height - zoneHeight) /2

		--GPS Line--
		if #gpsLines > 0 then 
			local streetX, streetY = false, false;
			for k,v in pairs(gpsLines) do 
				local bx, by, bz = unpack(v);
				local actualDist = getDistanceBetweenPoints2D(px,py, bx, by);
				if actualDist < 300 then 
				    local dist = actualDist/(6000/((imageWidth+imageHeight)/2));
				    local rot = findRotation(bx, by, px, py)-camZ;
				    local blipX, blipY = getPointFromDistanceRotation( (posX+width+posX)/2, (posY+posY+height)/2, math.min(dist, math.sqrt((posY+posY+height)/2-posY^2 + posX+width-(posX+width+posX)/2^2)), rot );
					
				    local blipX = math.max(posX+5, math.min(posX+width-5, blipX))
				    local blipY = math.max(posY+5, math.min(posY+height-25, blipY))
				    if blipX ~= posX+5 and blipX ~= posX+width-5 and blipY ~= posY+5 and blipY ~= posY+height-25 then 
					    if(streetX and streetY) then
						    dxDrawLine (streetX, streetY, blipX, blipY, tocolor(-markColor,0,markColor, 255), 4,true)
						    streetX, streetY = blipX, blipY;
					    else
						    streetX, streetY = blipX, blipY;
					    end
				    end
				    if gpsLines[k + 1] then 
					    local next = Vector3(gpsLines[k + 1]);
					    if lines3D then 
						    --local dis = getDistanceBetweenPoints3D(px,py,pz,bx,by,bz)
						    --if dis < 300 then 
					            --dxDrawLine3D(bx,by,bz + 0.5, next.x, next.y, next.z+0.5,tocolor(-markColor,30,markColor,180),80);
						        dxDrawMaterialLine3D(bx,by,bz + 0.2,next.x,next.y,next.z + 0.2,flash,4,tocolor(-markColor,30,markColor,180),false,next.x,next.y,next.z)
						    --end
					    end
					end
				end
			end
			local icons = "arial";
			local plus = 0
			local plus2 = 0 
			if gpsWaypoints[nextWp] then 
			    if gpsWaypoints[nextWp][2] == "left" then 
				    plus2 = 5
			    end
			    if floor((gpsWaypoints[nextWp][3] or 0)/10)*10 == 0 then 
				    plus = 21
			    elseif floor((gpsWaypoints[nextWp][3] or 0)/10)*10 < 10 and floor((gpsWaypoints[nextWp][3] or 0)/10)*10 >= 0 then 
				    plus = 19
			    elseif floor((gpsWaypoints[nextWp][3] or 0)/10)*10 < 100 and floor((gpsWaypoints[nextWp][3] or 0)/10)*10 >= 10 then 
				    plus = 17
			    elseif floor((gpsWaypoints[nextWp][3] or 0)/10)*10 < 1000 and floor((gpsWaypoints[nextWp][3] or 0)/10)*10 >= 100 then 
				    plus = 15
			    elseif floor((gpsWaypoints[nextWp][3] or 0) / 10) * 10 < 10000 and floor((gpsWaypoints[nextWp][3] or 0) / 10) * 10 >= 1000 then 
				    plus = 13
			    end
			    if currentWaypoint ~= nextWp and not tonumber(reRouting) then
				    if nextWp > 1 then
					    waypointInterpolation = {getTickCount(), currentWaypoint}
				    end
				    currentWaypoint = nextWp
			    end

			    if lines3D then 
				    local bPos = {getElementPosition(gpsBlip)}
				    local myS = {getScreenFromWorldPosition(bPos[1],bPos[2],bPos[3])}
				    local pPos = {getElementPosition(getLocalPlayer())}
				    local dis = getDistanceBetweenPoints3D(pPos[1],pPos[2],pPos[3],bPos[1],bPos[2],bPos[3])
				    if myS[1] and myS[2] then 
					    if isElement(gpsBlip) then 
							--setElementData(gpsBlip,"blip >> color",{-markColor,30,markColor,180});
							--setBlipColor(gpsBlip,-markColor,30,markColor,180)
 						    dxDrawImage(myS[1],myS[2] + 15,25,25,"blips/34.png",0,0,0,tocolor(-markColor,30,markColor,180))
						    dxDrawText(getElementData(gpsBlip,"blip >> name") .. "\n " .. math.floor(dis) .. " m",myS[1],myS[2] + 40,myS[1] + 30,0,tocolor(255,255,255),1,"arial","center","top" )
					    end
				    end
			    end
			
			    dxDrawRectangle(posX + 6 , posY + height - zoneHeight - gpsLineHeight , width - 6 , gpsLineHeight,tocolor(0,0,0,150),true) 

			    if turnAround then 
				    currentWaypoint = nextWp 
				    dxDrawImage(mCenterX - iconSize/2 + 5 , posY + height - zoneHeight - 55 ,iconSize + 5 ,iconSize + 5 ,"files/images/around.png",0,0,0,tocolor(sin,30,-sin),true)
		            dxDrawText("Lotfan Dor Bezanid!",mCenterX - iconSize/2 - 25,posY + height -zoneHeight - 15,posX + width,mCenterY + iconSize /2 + 32,tocolor(sin,30,-sin),0.9,"default-bold","left","top",false,false ,true,true)
			    elseif not waypointInterpolation then 
				    dxDrawImage(mCenterX - iconSize/2 - plus2 , posY + height - zoneHeight - 60 ,iconSize + 5 , iconSize + 5 , "files/images/" .. gpsWaypoints[nextWp][2] .. ".png",0,0,0,tocolor(30,30,255,255),true)
				    dxDrawText(floor((gpsWaypoints[nextWp][3] or 0) / 10) * 10 .. " m",mCenterX + plus - 28 , posY + height - zoneHeight - 15 , posX + width , mCenterY + iconSize / 2 + 32 , tocolor(30,30,255,255),0.9,"default-bold","left","top",false,false,true,true)

				    if gpsWaypoints[nextWp + 1] then 
					    dxDrawImage(posX + ((gpsLineHeight - iconSize) / 2) , posY + height - zoneHeight - iconSize - 8 , iconSize , iconSize , "files/images/" .. gpsWaypoints[nextWp + 1][2] .. ".png", 0,0,0,tocolor(180,40,30),true)
				    end
			    else
				    local startPolation, endPolation = (getTickCount() - waypointInterpolation[1]) / 750, 0
				    local firstAlpha, firstOffset, secondOffset = interpolateBetween(255, (height - zoneHeight) / 2 - iconSize/2, height - zoneHeight - iconSize - 8, 0, 0, (height - zoneHeight) / 2 - iconSize / 2, startPolation, "Linear")
				    local changeX,changeY,changeSize = interpolateBetween(mCenterX - iconSize/2 - plus2, posY + height - zoneHeight - 60, iconSize + 5 ,mCenterX + ((gpsLineHeight - iconSize) / 2) - plus2 + (mCenterX - 15),posY + height - iconSize - zoneHeight - 8,iconSize,startPolation, "Linear")
				    local changeXText,_,_ = interpolateBetween(mCenterX + plus - 28,0,0,mCenterX + plus + (mCenterX - 15),0,0,startPolation, "Linear")

				    dxDrawImage(changeX, changeY , changeSize, changeSize, "files/images/" .. gpsWaypoints[waypointInterpolation[2]][2] .. ".png", 0, 0, 0, tocolor(30, 30, 255, firstAlpha),true)
				    dxDrawText(floor((gpsWaypoints[waypointInterpolation[2]][3] or 0) / 10) * 10 .. " m", changeXText, posY + height - zoneHeight - 15,posX + width, mCenterY + iconSize/2 + 16, tocolor(30, 30, 255, firstAlpha), 0.9,"default-bold", "left", "top",false,false,true,true)

				    if gpsWaypoints[waypointInterpolation[2] + 1] then
					    local r, g, b = interpolateBetween(180, 40, 30, 30, 30, 255, startPolation, "Linear")
					    local alpha = interpolateBetween(0, 0,0, 255, 0, 0, startPolation, "Linear")
					    local changeX2,changeY2,changeSize2 = interpolateBetween(posX + ((gpsLineHeight - iconSize/2) / 2) , posY + height - zoneHeight - iconSize - 8,iconSize,mCenterX - iconSize/2 - plus2, posY + height - zoneHeight - 60,iconSize + 5,startPolation,"Linear") 
					    local changeXText2,_,_ = interpolateBetween(posX + plus,0,0,mCenterX + plus - 28,0,0,startPolation,"Linear")

					    dxDrawImage(changeX2,changeY2, changeSize2,changeSize2, "files/images/" .. gpsWaypoints[waypointInterpolation[2] + 1][2] .. ".png", 0, 0, 0, tocolor(r, g, b),true)
					    dxDrawText(floor((gpsWaypoints[waypointInterpolation[2] + 1][3] or 0) / 10) * 10 .. " m", changeXText2,posY + height - zoneHeight - 15, posX + width, mCenterY + iconSize/2 + 16, tocolor(r, g, b, alpha), 0.9, "default-bold", "left", "top",false,false,true,true)
					
					    if startPolation > 1 then
						    endPolation = (getTickCount() - waypointInterpolation[1] - 750) / 500
					    end

					    if gpsWaypoints[waypointInterpolation[2] + 2] then
						    local thirdAlpha = interpolateBetween(0, 0, 0, 255, 0, 0, endPolation, "Linear")
						    dxDrawImage(posX + ((gpsLineHeight - iconSize) / 2), posY + height - zoneHeight - iconSize - 8, iconSize, iconSize, "files/images/" .. gpsWaypoints[waypointInterpolation[2] + 2][2] .. ".png", 0, 0, 0, tocolor(180, 40, 40, thirdAlpha),true)
					    end

					    if endPolation > 1 then
						    waypointInterpolation = false
					    end
					end
				end
			end 
		end

		for k, v in ipairs(getElementsByType("blip")) do
			local bx, by = getElementPosition(v);
			local actualDist = getDistanceBetweenPoints2D(px,py, bx, by);
			local bIcon = getBlipIcon(v);
			local bSize = getElementData(v,"blip >> size") or 22;
			if actualDist <= 200 or (getElementData(v, "blip >> maxVisible")) then
				local dist = actualDist/(6000/((imageWidth+imageHeight)/2));
				local rot = findRotation(bx, by, px, py)-camZ;
				local blipX, blipY = getPointFromDistanceRotation( (posX+width+posX)/2, (posY+posY+height)/2, math.min(dist, math.sqrt((posY+posY+height)/2-posY^2 + posX+width-(posX+width+posX)/2^2)), rot );
					
				local blipX = math.max(posX+17, math.min(posX+width-15, blipX))
				local blipY = math.max(posY+15, math.min(posY+height-40, blipY))
				
				local bblipiconnum = bIcon or 10
				if bblipiconnum == 0 then
					br, bg, bb, ba = getBlipColor(v)
				else
					br, bg, bb, ba = unpack({255,255,255,255})
				end
				
				local r,g,b = unpack({br,bg,bb});
				if bIcon then 
					if fileExists("blips/" .. bIcon .. ".png") then 
				        dxDrawImage(blipX - bSize/2, blipY - bSize/2, bSize, bSize, "blips/" .. bIcon .. ".png" or "blips/0.png", 0, 0, 0, tocolor(r,g,b),true);
					end
				end
			end
		end
		-----------------

		dxDrawImage(posX+6,posY+3,width-9,height-6,shadowTexture,0,0,0,tocolor(255,255,255),true);

		dxDrawImage(posX + width/2 - 15/2, posY + height/2 -15/2, 18, 18, arrowTexture, camZ-getPedRotation(localPlayer), 0, 0, tocolor(255, 255, 255, 255), true);
		dxDrawRectangle(posX + 5, posY+height-27, width-5, zoneHeight, tocolor(255,255,255,255),true); --radar_color
		local zoneName = getZoneName(px, py, pz);
		dxDrawText(zoneName, posX + 10, posY+height-27, width - 12,posY+height-27+28, tocolor(0, 0, 0, 255), 0.6, font3, "right", "center", false, false, true, true);
	end
end)

function getPointFromDistanceRotation(x, y, dist, angle)
    local a = math.rad(90 - angle);
    local dx = math.cos(a) * dist;
    local dy = math.sin(a) * dist;
    return x+dx, y+dy;
end

function findRotation(x1,y1,x2,y2)
	local t = -math.deg(math.atan2(x2-x1,y2-y1))
	if t < 0 then t = t + 360 end;
	return t;
end

local playerX,playerY,playerZ = getElementPosition(localPlayer);
local mapUnit = imageWidth / 6000;
local currentZoom = 1.5;
local minZoom, maxZoom = 1.5, 3;

local mapOffsetX, mapOffsetY = 0,0;
local mapMoved = false;
local changeTick = 0;

function bigMapRender()
	if getElementDimension(localPlayer) ~= 0 or getElementInterior(localPlayer) ~= 0 or isTransferBoxActive() then return end;
	posX, posY, width, height = 25, 25, sX - 50, sY - 50;

	if(isCursorShowing()) and mapMoved then
		local cursorX, cursorY = getCursorPosition();
		local mapX, mapY = getWorldFromMapPosition(cursorX, cursorY);

		local absoluteX = cursorX * sX;
		local absoluteY = cursorY * sY;

		if getKeyState("mouse1") and mouseInPos(posX, posY, width, height) then
			playerX = -(absoluteX * currentZoom - mapOffsetX);
			playerY = absoluteY * currentZoom - mapOffsetY;
	
			playerX = math.max(-3000, math.min(3000, playerX));
			playerY = math.max(-3000, math.min(3000, playerY));
		end
	else 
		if (not mapMoved) then
			playerX, playerY, playerZ = getElementPosition(localPlayer);
		end
	end

	local _, _, playerRotation = getElementRotation(localPlayer);
	local mapX = (((3000 + playerX) * mapUnit) - (width / 2) * currentZoom);
	local mapY = (((3000 - playerY) * mapUnit) - (height / 2) * currentZoom);
	local mapWidth, mapHeight = width * currentZoom, height * currentZoom;
	local localX, localY, localZ = getElementPosition(localPlayer);

	local sin = math.mobin(getTickCount()/3000)*255

	dxDrawRectangle(posX - 5, posY - 5, width + 10, height + 10,tocolor(255,255,255,255)); --f12 border
	dxDrawRectangle(posX - 10, posY - 5, 5, height + 10,tocolor(sin,30,-sin,180));
	dxDrawImageSection(posY, posX, width, height, mapX, mapY, mapWidth, mapHeight, texture, 0, 0, 0, tocolor(255, 255, 255, 255), false);
	dxDrawImage(posX, posY, width, height, "files/shadow.png");

	if isElement(recTarget) then 
	    for i,area in ipairs(getElementsByType("radararea")) do 
		    local data = {};data["pos"] = {getElementPosition(area)}
		    data["size"] = {getRadarAreaSize(area)};data["color"] = {getRadarAreaColor(area)};data["middleColor"] = getElementData(area,"middleColor")
			data["type"] = getElementData(area,"areaType") or "default"
			data["lastSize"] = {getRadarAreaSize(area)}
		    local dis = getDistanceBetweenPoints2D(data["pos"][1],data["pos"][2],playerX,playerY)
		    local pos = {posX + width/2,posY + height/2}
			pos["size"] = {0,0}
			data["size"][1],data["size"][2] = data["size"][1]/currentZoom,data["size"][2]/currentZoom
		    pos["x"],pos["y"] = getMapFromWorldPosition(data["pos"][1],data["pos"][2])
			if pos["x"] + data["size"][1]/2 >= posX + width then 
				pos["size"][1] = pos["x"] + data["size"][1]/2 - (posX + width)
				data["size"][1] = data["size"][1] - pos["size"][1]
			end
			if pos["x"] - data["size"][1]/2 <= posX then 
				pos["size"][1] = ((pos["x"] - data["size"][1]/2) - posX)
				data["size"][1] = data["size"][1] + pos["size"][1]
			end
			if pos["y"] + data["size"][2]/2 >= posY + height then 
				pos["size"][2] = pos["y"] + data["size"][2]/2 - (posY + height)
				data["size"][2] = data["size"][2] - pos["size"][2]
			end
			if pos["y"] - data["size"][2]/2 <= posY then 
				pos["size"][2] = ((pos["y"] - data["size"][2]/2) - posY)
				data["size"][2] = data["size"][2] + pos["size"][2]
			end
			if data["size"][1] < 0 then 
				data["size"][1] = 0
			end
			if data["size"][2] < 0 then
				data["size"][2] = 0
			end
			local areaLeft,areaRight,areaTop,areaBottom = pos["x"] - data["lastSize"][1],pos["x"] + data["lastSize"][1],pos["y"] - data["lastSize"][1],pos["y"] + data["lastSize"][1]
			if data["type"] == "circle" then
				if areaLeft > posX and areaRight < posX + width and areaTop > posY and areaBottom < posY + height then 
				    dxDrawCircle(pos["x"] - pos["size"][1]/2,pos["y"] - pos["size"][2]/2,data["size"][1],0,360,tocolor(unpack(data["color"])),tocolor(unpack(data["middleColor"] or data["color"])),32,1)
				end
			elseif data["type"] == "danger" then 
				if areaLeft > posX and areaRight < posX + width and areaTop > posY and areaBottom < posY + height then 
				    drawZone(pos["x"] - pos["size"][1]/2,pos["y"] - pos["size"][2]/2,data["size"][1],data["color"][1],data["color"][2],data['color'][3],data['color'][4])
				end
			else
			    dxDrawImage(pos["x"] - (data["size"][1]/2) - pos["size"][1]/2,pos["y"] - (data["size"][2]/2) - pos["size"][2]/2,data["size"][1],data["size"][2],recTarget,0,0,0,tocolor(unpack(data["color"])))
			end
		end
	end

	dxDrawRectangle(posX, posY + height - 30, width, 30,tocolor(0,0,0,180));

	--GPS Line--
	local streetX, streetY = false, false;
	for k,v in pairs(gpsLines) do
		local gpsX,gpsY = unpack(v);
		local centerX, centerY = (posX + (width / 2)), (posY + (height / 2));
		local leftFrame = (centerX - width / 2) + (30/2);
		local rightFrame = (centerX + width / 2) - (30/2);
		local topFrame = (centerY - height / 2) + (30/2);
		local bottomFrame = (centerY + height / 2) - 40;
		gpsX,gpsY = getMapFromWorldPosition(gpsX,gpsY);
		gpsX, gpsY = math.max(leftFrame, math.min(rightFrame, gpsX)), math.max(topFrame, math.min(bottomFrame, gpsY));
		if streetX and streetY then 
			dxDrawLine (streetX, streetY, gpsX, gpsY, tocolor(-markColor,30,markColor, 255), 4,true);
			streetX, streetY = gpsX, gpsY;
		else 
			streetX, streetY = gpsX, gpsY;
		end
	end
	-------

	for i, blip in ipairs(getElementsByType("blip")) do
		local blipX, blipY, blipZ = getElementPosition(blip);
		local icon = getBlipIcon(blip);
		local size = (getElementData(blip,"blip >> size") or 22);
		
		local bblipiconnum = icon or 10
		if bblipiconnum == 0 then
			br, bg, bb, ba = getBlipColor(blip)
		else
			br, bg, bb, ba = unpack({255,255,255,255})
		end
		
		
		local color = {br,bg,bb};
		--[[local color ={255,255,255}
		if icon == 34 then 
			color = {255,0,0}
		end--]]

		local blipDistance = getDistanceBetweenPoints2D(blipX, blipY, playerX, playerY);
		if (blipDistance <= (1000*(currentZoom*3))) then 
			local centerX, centerY = (posX + (width / 2)), (posY + (height / 2));
			local leftFrame = (centerX - width / 2) + (30/2);
			local rightFrame = (centerX + width / 2) - (30/2);
			local topFrame = (centerY - height / 2) + (30/2);
			local bottomFrame = (centerY + height / 2) - 40;
			local blipX, blipY = getMapFromWorldPosition(blipX, blipY);
			centerX = math.max(leftFrame, math.min(rightFrame, blipX));
			centerY = math.max(topFrame, math.min(bottomFrame, blipY));

			if icon then
				if fileExists("blips/" .. icon .. ".png") then  
			        dxDrawImage(centerX - (size / 2), centerY - (size / 2), size, size, "blips/" .. icon .. ".png", 0, 0, 0, tocolor(color[1],color[2],color[3], a));
				end
			end

			if mouseInPos(centerX - (size / 2), centerY - (size / 2), size, size) then 
				local blipName = getElementData(blip, "blip >> name") or blipNames[icon] or "Blip Nashenakhte";
				local textWidth = dxGetTextWidth(blipName,1,font2,true);
				local cursorX, cursorY = getCursorPosition()
				cursorX, cursorY = cursorX*sX + 10, cursorY*sY + 10
				dxDrawRectangle(cursorX,cursorY,textWidth + 10, 20,tocolor(0,0,0,180));
				dxDrawText(blipName,cursorX,cursorY,cursorX + textWidth + 10,cursorY+20,tocolor(255,255,255),1,font2,"center","center",false,false,false,true);
			end
		end
	end

	local textColor = tocolor(255,0,0);
	if getElementData(localPlayer,"3dBlip") or false then 
		textColor = tocolor(0,255,0);
	end
	dxDrawRectangle(posX, posY + height - 30, dxGetTextWidth("3D Blips",1,font,false)+10, 30,tocolor(0,0,0,180));
	dxDrawText("3D Blips",posX+5, posY + height-30, 20,posY + height+2,textColor,1,font,"left","center");

	local textColor2 = tocolor(255,0,0)
	if lines3D then 
		textColor2 = tocolor(0,255,0)
	end

	dxDrawRectangle(posX + dxGetTextWidth("3D Blips",1,font,false) + 10 , posY + height - 30 , dxGetTextWidth("3D GPSLines",1,font,false) + 10,30,tocolor(0,0,0,180))
	dxDrawText("3D GPSLines",posX + dxGetTextWidth("3D Blips",1,font,false) + 10 + 5,posY + height - 30 , 20,posY + height + 2 , textColor2,1,font,"left","center")
	-------------

	dxDrawRectangle(posX + dxGetTextWidth("3D Blips",1,font,false) + dxGetTextWidth("3D GPSLines",1,font,false) + 20 , posY + height - 30) --, dxGetTextWidth("3D Speed Meter",1,font,false) + 10,30,tocolor(0,0,0,180)
	dxDrawText("",posX + dxGetTextWidth("3D Blips",1,font,false) + dxGetTextWidth("3D GPSLines",1,font,false) + 20 + 5,posY + height - 30 , 20,posY + height + 2 ,tocolor(0,255,0) or tocolor(255,0,0),1,font,"left","center")


	dxDrawRectangle(posX + dxGetTextWidth("3D Blips",1,font,false) + dxGetTextWidth("3D GPSLines",1,font,false)+ 30 , posY + height - 30)
	dxDrawText("",posX + dxGetTextWidth("3D Blips",1,font,false) + dxGetTextWidth("3D GPSLines",1,font,false) + 30 + 5,posY + height - 30 , 20,posY + height + 2 ,texture == textures[1] and tocolor(0,255,0) or tocolor(255,0,0),1,font,"left","center")
    
	--Player Arrow--
	local blipX, blipY = getMapFromWorldPosition(localX, localY);
	if (blipX >= posX and blipX <= posX + width) then
		if (blipY >= posY and blipY <= posY + height) then
			dxDrawImage(blipX - 7, blipY - 7, 17, 17, arrowTexture, 360 - playerRotation, 0, 0, tocolor(255, 255, 255, a), true);
		end
	end
	----------------

	if mapMoved then 
		dxDrawImage(posX + width/2 - 128/2,posY + height / 2 - 128 /2,128,128,"files/images/cross.png",0,0,0,tocolor(255,255,255),true)
		dxDrawText("Baraye Bazgasht Be Nemaye Khod Dokmeye #ff00ffSPACE #ffffffRa Feshar Dahid!",posX, posY + height-30, posX + width,posY + height+2,tocolor(255,255,255),1,font,"center","center",false,false,false,true);
	end

	dxDrawText(getZoneName(playerX,playerY,0),posX, posY + height-30, posX + width - 10,posY + height+2,tocolor(255,255,255),1,font,"right","center",false,false,false,true);
end

addEventHandler("onClientClick",root,function(button,state,x,y)
if showBigMap then 
	if button == "left" then 
		if state == "down" then 
			if mouseInPos(posX,posY,width,height-30) then 
				mapOffsetX = x * currentZoom + playerX;
				mapOffsetY = y * currentZoom - playerY;
				mapMoved = true;
			end
			if mouseInPos(posX, posY + height - 30, dxGetTextWidth("3D Blips",1,font,false)+10, 30) then 
				if changeTick+300 > getTickCount() then return end;
				setElementData(localPlayer,"3dBlip",not getElementData(localPlayer,"3dBlip"));
				if getElementData(localPlayer,"3dBlip") then 
					exports.MG_Notification:addNotification("Halate Blip Haye 3D Faal Shod!","success");
				else 
					exports.MG_Notification:addNotification("Halate Blip Haye 3D Gheyre Faal Shod!","error");
				end
				changeTick = getTickCount();
			elseif (mouseInPos(posX + dxGetTextWidth("3D Blips",1,font,false) + 10 , posY + height - 30, dxGetTextWidth("3D GPSLines",1,font,false) +10 , 30)) then 
				if changeTick + 300 > getTickCount() then 
					return false 
				end
				lines3D = not lines3D
				if lines3D then 
					exports.MG_Notification:addNotification("Halate GPSLine 3D Faal Shod!","success")
				else
					exports.MG_Notification:addNotification("Halate GPSLine 3D Gheyre Faal Shod!","error")
				end
				changeTick = getTickCount()
			elseif (mouseInPos(posX + dxGetTextWidth("3D Blips",1,font,false) + dxGetTextWidth("3D GPSLines",1,font,false) + 20 , posY + height - 30 , dxGetTextWidth("3D Speed Meter",1,font,false) + 10,30)) then 
				if changeTick + 300 > getTickCount() then 
					return false 
				end
				if isElement(occupiedVehicle) then 
					if not isVehicleVIP(occupiedVehicle) then 
						return exports.MG_Notification:addNotification("Mashine Shoma Az In System Poshtibani Nemikonad!","error")
					end
					setElementData(occupiedVehicle,"3DSpeedMeter",not getElementData(occupiedVehicle,"3DSpeedMeter"))
					exports.MG_Notification:addNotification("Halate 3D Speed Meter " .. (getElementData(occupiedVehicle,"3DSpeedMeter") and "" or "Gheyre") .. " Faal Shod!",getElementData(occupiedVehicle,"3DSpeedMeter") and "success" or "error")
					changeTick = getTickCount()
				end
			elseif (mouseInPos(posX + dxGetTextWidth("3D Blips",1,font,false) + dxGetTextWidth("3D GPSLines",1,font,false) + dxGetTextWidth("3D Speed Meter",1,font,false) + 30 , posY + height - 30 , dxGetTextWidth("Light/Dark",1,font,false) + 10,30)) then 
				if changeTick + 300 > getTickCount() then 
					return 
				end
				texture = (texture == textures[1]) and textures[2] or textures[1] 
				saveDataOnXML("state",texture == textures[1] and "1" or "2")
				waterColor = (texture == textures[1]) and tocolor(97,101,107) or tocolor(0,150,255)
				dxSetTextureEdge(texture,"border",waterColor)
				exports.MG_Notification:addNotification("Halate Dark Radar " .. (texture == textures[1] and "" or "Gheyre") .. " Faal Shod!",texture == textures[1] and "success" or "error")
			end
		end
	end
	if button == "right" and state == "down" then 
		if occupiedVehicle and isElement(occupiedVehicle) then 
			local cursorX, cursorY = getCursorPosition();
			local gpsX,gpsY = getWorldFromMapPosition(cursorX, cursorY);

			if getElementData(occupiedVehicle, "gpsDestination") then
				setElementData(occupiedVehicle, "gpsDestination", false)
			else
				setElementData(occupiedVehicle, "gpsDestination", {gpsX, gpsY});
			end
		end
	end
end
end);

function isVehicleVIP(veh)
	if isElement(veh) then 
		for i,id in ipairs(vipVehicles) do 
			if getElementModel(veh) == tonumber(id) then 
				return true
			end
		end
	end
	return false
end

setPlayerHudComponentVisible(localPlayer,"radar",false)
toggleControl("radar", false)

addEventHandler("onClientKey",root,function(button,state)
	if button == "F11" and state then 
		cancelEvent();
		if not getElementData(localPlayer,"loggedin") or getElementData(localPlayer,"loggedin") ~= 1 then return end
		if not showBigMap then 
			removeEventHandler("onClientRender",root,bigMapRender);
			addEventHandler("onClientRender",root,bigMapRender);
			showBigMap = true;
			mapMoved = false;
			exports["realism-system"]:hideSpeedo()
			--setElementData(localPlayer,"togHUD",false);
			showChat(false);
		else 
			removeEventHandler("onClientRender",root,bigMapRender);
			showBigMap = false;
			exports["realism-system"]:showSpeedo()
			--setElementData(localPlayer,"togHUD",true);
			showChat(true);
		end
	end
	if showBigMap then 
		if button == "space" and state then 
			mapMoved = false;
		end

		if button == "mouse_wheel_up" and state then 
			currentZoom = math.max(currentZoom - 0.05, minZoom);
		end

		if button == "mouse_wheel_down" and state then 
			currentZoom = math.min(currentZoom + 0.05, maxZoom);
		end
	end
end);

function drawArea(x,y,r,cr,cg,cb)
	local tick = {getTickCount()/1000,(getTickCount()+500)/1000,(getTickCount()+1000)/1000}
	local sin = {math.mobin(tick[1])*255,math.mobin(tick[2])*255,math.mobin(tick[3])*255}

	drawRing(x,y,r,r*0.2,0,360,tocolor(cr,cg,cb,sin[3]),true,1)
	drawRing(x,y,r + (r),r*0.2,0,360,tocolor(cr,cg,cb,sin[2]),true,1)
	drawRing(x,y,r + (r*2),r*0.2,0,360,tocolor(cr,cg,cb,sin[1]),true,1)
end

function drawRing (posX, posY, radius, width, startAngle, amount, color, postGUI, absoluteAmount, anglesPerLine)
	if (type (posX) ~= "number") or (type (posY) ~= "number") or (type (startAngle) ~= "number") or (type (amount) ~= "number") then
		return false
	end
	
	if absoluteAmount then
		stopAngle = amount + startAngle
	else
		stopAngle = (amount * 360) + startAngle
	end
	
	anglesPerLine = type (anglesPerLine) == "number" and anglesPerLine or 1
	radius = type (radius) == "number" and radius or 50
	width = type (width) == "number" and width or 5
	color = color or tocolor (255, 255, 255, 255)
	postGUI = type (postGUI) == "boolean" and postGUI or false
	absoluteAmount = type (absoluteAmount) == "boolean" and absoluteAmount or false
	
	for i = startAngle, stopAngle, anglesPerLine do
		local startX = math.cos (math.rad (i)) * (radius - width)
		local startY = math.sin (math.rad (i)) * (radius - width)
		local endX = math.cos (math.rad (i)) * (radius + width)
		local endY = math.sin (math.rad (i)) * (radius + width)
		dxDrawLine (startX + posX, startY + posY, endX + posX, endY + posY, color, width, postGUI)
	end
	return math.floor ((stopAngle - startAngle)/anglesPerLine)
end

function mouseInPos(x,y,w,h)
	if isCursorShowing() then 
		screen["mouse"] = {getCursorPosition()}
		screen["mouse"]["x"] = screen["mouse"][1]*screen[1]
		screen["mouse"]["y"] = screen["mouse"][2]*screen[2]
		return (screen["mouse"]["x"] >= x and screen["mouse"]["x"] <= x + w and screen["mouse"]["y"] >= y and screen["mouse"]["y"] <= y +h)
	end
end

function getMapFromWorldPosition(worldX, worldY)
	local centerX, centerY = (posX + (width / 2)), (posY + (height / 2));
	local mapLeftFrame = centerX - ((playerX - worldX) / currentZoom * mapUnit);
	local mapRightFrame = centerX + ((worldX - playerX) / currentZoom * mapUnit);
	local mapTopFrame = centerY - ((worldY - playerY) / currentZoom * mapUnit);
	local mapBottomFrame = centerY + ((playerY - worldY) / currentZoom * mapUnit);

	centerX = math.max(mapLeftFrame, math.min(mapRightFrame, centerX));
	centerY = math.max(mapTopFrame, math.min(mapBottomFrame, centerY));

	return centerX, centerY;
end

function getWorldFromMapPosition(mapX, mapY)
	return playerX + ((mapX * ((width * currentZoom) * 2)) - (width * currentZoom)), playerY + ((mapY * ((height * currentZoom) * 2)) - (height * currentZoom)) * -1;
end
---------------------------------------

--GPS--
gpsLines = {};
gpsBlip = false;
waypointInterpolation = false;
function clearGPSRoute()
	gpsLines = {}
	if isElement(gpsBlip) then 
		destroyElement(gpsBlip);
	end
end

function addGPSLine(x, y, z)
	table.insert(gpsLines, {x, y, z or 0});

	local markerX, markerY, markerZ = unpack(gpsLines[#gpsLines]);
	if isElement(gpsBlip) then 
		setElementPosition(gpsBlip,markerX, markerY, markerZ);
	else
		gpsBlip = createBlip(markerX, markerY, markerZ-10,34);
	end
	setElementData(gpsBlip,"blip >> name","GPS Mark");
	setElementData(gpsBlip, "blip >> maxVisible", true);

end

addEventHandler("onClientElementDataChange", getRootElement(),function (dataName, oldValue)
	if source == occupiedVehicle then
		if dataName == "gpsDestination" then
			local dataValue = getElementData(source, dataName) or false;
			if dataValue then
				gpsThread = coroutine.create(makeRoute);
				coroutine.resume(gpsThread, unpack(dataValue));
				waypointInterpolation = false;
			else
				endRoute();
			end
		end
	end
end);
-------


--------------------
---SZERVER BLIPEK---
--------------------
north = createBlip( 733.1318359375, 3700.951171875, -200, 2, 2, 255, 255, 255, 255) -- észak blip
setBlipOrdering ( north,  -2000 )
setElementData(north, "blip >> maxVisible", true)
setElementData(north,"blip >> name","North")

function math.mobin(num)
	local sin = math.sin(num)
	if sin < 0 then 
		sin = sin*(-1)
	end
	return sin 
end

--GPS UTILS--
occupiedVehicle = getPedOccupiedVehicle(localPlayer);
addEventHandler("onClientVehicleEnter", getRootElement(),
	function (player)
		if player == localPlayer then
			if occupiedVehicle ~= source then
				occupiedVehicle = source
			end
		end
	end
)

addEventHandler("onClientVehicleExit", getRootElement(),
	function (player)
		if player == localPlayer then
			if occupiedVehicle == source then
				occupiedVehicle = false
			end
		end
	end
)

function wastedMessage(killer,weapon,bodypart)
	occupiedVehicle = false
end
addEventHandler ( "onClientPlayerWasted", getLocalPlayer(), wastedMessage )

addEventHandler("onClientElementDestroy", getRootElement(),
	function ()
		if occupiedVehicle == source then
			occupiedVehicle = false
		end
	end
)

addEventHandler("onClientVehicleExplode", getRootElement(),
	function ()
		if occupiedVehicle == source then
			occupiedVehicle = false
		end
	end
)

function windowsNot()
	if isEventHandlerAdded("onClientMinimize",getRootElement(),windowsNot) then 
		removeEventHandler("onClientMinimize",getRootElement(),windowsNot)
	end
	addEventHandler("onClientMinimize",getRootElement(),windowsNot)
	--createTrayNotification("[MadGames]:Shoma AFK Shodid. Lotfan Harche Saritar Be Bazi Bargardid . Dar Gheyre In Sorat Pas Az 30 Daghighe Time Playi Baraye Shoma Mohasebe Nemishavad!","warning")
end
addEventHandler("onClientMinimize",getRootElement(),windowsNot)