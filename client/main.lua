local Keys = {
  ["ESC"] = 322, ["F1"] = 288, ["F2"] = 289, ["F3"] = 170, ["F5"] = 166, ["F6"] = 167, ["F7"] = 168, ["F8"] = 169, ["F9"] = 56, ["F10"] = 57,
  ["~"] = 243, ["1"] = 157, ["2"] = 158, ["3"] = 160, ["4"] = 164, ["5"] = 165, ["6"] = 159, ["7"] = 161, ["8"] = 162, ["9"] = 163, ["-"] = 84, ["="] = 83, ["BACKSPACE"] = 177,
  ["TAB"] = 37, ["Q"] = 44, ["W"] = 32, ["E"] = 38, ["R"] = 45, ["T"] = 245, ["Y"] = 246, ["U"] = 303, ["P"] = 199, ["["] = 39, ["]"] = 40, ["ENTER"] = 18,
  ["CAPS"] = 137, ["A"] = 34, ["S"] = 8, ["D"] = 9, ["F"] = 23, ["G"] = 47, ["H"] = 74, ["K"] = 311, ["L"] = 182,
  ["LEFTSHIFT"] = 21, ["Z"] = 20, ["X"] = 73, ["C"] = 26, ["V"] = 0, ["B"] = 29, ["N"] = 249, ["M"] = 244, [","] = 82, ["."] = 81,
  ["LEFTCTRL"] = 36, ["LEFTALT"] = 19, ["SPACE"] = 22, ["RIGHTCTRL"] = 70,
  ["HOME"] = 213, ["PAGEUP"] = 10, ["PAGEDOWN"] = 11, ["DELETE"] = 178,
  ["LEFT"] = 174, ["RIGHT"] = 175, ["TOP"] = 27, ["DOWN"] = 173,
  ["NENTER"] = 201, ["N4"] = 108, ["N5"] = 60, ["N6"] = 107, ["N+"] = 96, ["N-"] = 97, ["N7"] = 117, ["N8"] = 61, ["N9"] = 118
}


ESX = nil
local hash = Config.hash
local vehicleHash = Config.vehicleHash
local ped = nil
local taxiBlip = false
local globalTaxi = nil
local customer = nil
local onTour = false
local driveFinish = nil

Citizen.CreateThread(function()
	while ESX == nil do
		TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
		Citizen.Wait(0)
	end
end)


RegisterNetEvent('esx_aiTaxi:callTaxi')
AddEventHandler('esx_aiTaxi:callTaxi', function(coords)
	if customer then
		ESX.ShowHelpNotification('Es ist bereits ein Taxi unterwegs zu ihnen')
	else
		customer = coords
		-- get best spawnpoint
		playerPed = GetPlayerPed(-1)
		myCoords = GetEntityCoords(playerPed)
		for k,v in pairs(Config.SpawnPoints) do
			heading = v.h
			v = vector3(v.x, v.y, v.z)
			spawnDistance = GetDistanceBetweenCoords(myCoords, v)
			if oldDistance then
				if spawnDistance < oldDistance then
					oldDistance = spawnDistance
					realSpawnPoint = v
				else
					oldDistance = oldDistance
				end
			else
				oldDistance = spawnDistance
				realSpawnPoint = v
			end
		end
		while not HasModelLoaded(hash) do
			RequestModel(hash)
			Wait(50)
		end
		while not HasModelLoaded(vehicleHash) do
			RequestModel(vehicleHash)
			Wait(50)
		end
		if ped == nil then
			ped =  CreatePed(4, hash, realSpawnPoint.x, realSpawnPoint.y, realSpawnPoint.z + 2, 0.0, true, true)
		end
		if DoesEntityExist(globalTaxi) then
			ESX.Game.DeleteVehicle(globalTaxi)
		end
		
		ESX.Game.SpawnVehicle(vehicleHash, realSpawnPoint, heading, function(callback_vehicle)
			TaskWarpPedIntoVehicle(ped, callback_vehicle, -1)
			SetVehicleHasBeenOwnedByPlayer(callback_vehicle, true)
			taxiBlip = true
			globalTaxi = callback_vehicle
			SetEntityAsMissionEntity(globalTaxi, true, true)
			drive(customer.x, customer.y, customer.z, false, 'start')
		end)
	end
end)

RegisterNetEvent('esx_aiTaxi:setTaxiBlip')
AddEventHandler('esx_aiTaxi:setTaxiBlip', function(coords)
	if CarBlip then
		RemoveBlip(CarBlip)
		CarBlip = nil
	elseif not onWayBack then
		CarBlip = AddBlipForCoord(coords)
		SetBlipSprite(CarBlip , 56)
		SetBlipScale(CarBlip , 0.8)
		SetBlipColour(CarBlip, 5)
		BeginTextCommandSetBlipName("STRING")
		AddTextComponentString('TAXI')
		EndTextCommandSetBlipName(CarBlip)
	end
end)

RegisterNetEvent('esx_aiTaxi:killTaxiBlip')
AddEventHandler('esx_aiTaxi:killTaxiBlip', function()
	RemoveBlip(CarBlip)
end)

RegisterNetEvent('esx_aiTaxi:cancelTaxi')
AddEventHandler('esx_aiTaxi:cancelTaxi', function(message)
	atTarget(message)
end)

Citizen.CreateThread(function()
	local playerPed = GetPlayerPed(-1)
	while true do
		Citizen.Wait(0)
		inCar = false
		if customer ~= nil then
			local vehicle = GetVehiclePedIsIn(playerPed, false)
			if vehicle == globalTaxi then
				inCar = true
				local waypoint = GetFirstBlipInfoId(8)
				if not DoesBlipExist(waypoint) and not onTour then
					ESX.ShowHelpNotification('Wo möchten Sie hin?')
					Citizen.Wait(2000)
				else
					tx, ty, tz = table.unpack(Citizen.InvokeNative(0xFA7C7F0AADF25D09, waypoint, Citizen.ResultAsVector()))
					if not onTour then
						if not targetX then
							targetX = tx
							targetY = ty
							targetZ = tz
						end
						drive(tx, ty, tz, false, false)
						onTour = true
					end
				end
			end
		end
	end
end)

--distancechecks
Citizen.CreateThread(function()
	local playerPed = GetPlayerPed(-1)
	while true do
		Citizen.Wait(0)
		if customer ~= nil then
			myCoords = GetEntityCoords(playerPed)
			taxiCoords = GetEntityCoords(ped)
			local vehicle = GetVehiclePedIsIn(playerPed, false)
			if vehicle == globalTaxi then
				route = CalculateTravelDistanceBetweenPoints(customer.x, customer.y, customer.z, taxiCoords.x, taxiCoords.y, taxiCoords.z)
				--check distance between me and the destination
				if GetDistanceBetweenCoords(myCoords, targetX, targetY, targetZ) < 20 then
					atTarget()
				end
			end
			--check if taxi is next to me 
			if customer ~= nil then
				local distanceMeTaxi = GetDistanceBetweenCoords(customer.x, customer.y, customer.z, taxiCoords.x, taxiCoords.y, taxiCoords.z, true)
				if distanceMeTaxi <= 40 then
					if not parkingDone then
						parking(customer.x, customer.y, customer.z)
						TriggerEvent('esx:showNotification', 'Ihr Taxi ist da')
					end
					if GetDistanceBetweenCoords(customer.x, customer.y, customer.z, taxiCoords.x, taxiCoords.y, taxiCoords.z, true) <= 3 then
						taxiArrived = true
					end
				end
			end
		end
	end
end)

--keycontrol
Citizen.CreateThread(function()
	while true do
		Citizen.Wait(0)
		if customer ~= nil then
			if taxiArrived and not inCar and not onWayBack then
				ESX.ShowHelpNotification('Mit ~INPUT_PICKUP~ einsteigen')
				if IsControlJustReleased(0, Keys['E']) and GetLastInputMethod(2) then
					TaskEnterVehicle(GetPlayerPed(-1), globalTaxi, 1000, math.random(0,2), 2.0, 1, 0)
					-- TaskWarpPedIntoVehicle(GetPlayerPed(-1), globalTaxi, math.random(0,2))
				end
			end
		end
	end
end)

-- taxiBlip
Citizen.CreateThread(function()
	while true do
		Citizen.Wait(450)
		if taxiBlip then
			coords = GetEntityCoords(ped)
			TriggerEvent('esx_aiTaxi:setTaxiBlip', coords)
		end
	end
end)

--draw marker
Citizen.CreateThread(function()
	while true do
		Citizen.Wait(0)
		markerCoords = GetEntityCoords(globalTaxi)
		if ped ~= nil and not onWayBack then
			if GetDistanceBetweenCoords(markerCoords, myCoords) > 2 then
				DrawMarker(0, markerCoords.x, markerCoords.y, markerCoords.z+3, 0.0, 0.0, 0.0, 0, 0.0, 0.0, 3.0, 3.0, 2.0, 244, 123, 23, 100, true, true, 2, true, false, false, false)
			end
		end
	end
end)

function atTarget(cancel)
	cancelTaxi = false
	if cancel then
		playerPed = GetPlayerPed(-1)
		local vehicle = GetVehiclePedIsIn(playerPed, false)
		if vehicle ~= globalTaxi then
			TriggerEvent('esx:showNotification', 'Taxi wurde abbestellt')
			cancelTaxi = true
		else
			TriggerEvent('esx:showNotification', 'Taxi kann nicht mehr abbestellt werden')
			return
		end
	end
	if not cancelTaxi then
		ESX.ShowHelpNotification('Wir sind am Ziel angekommen')
		route2 = CalculateTravelDistanceBetweenPoints(customer.x, customer.y, customer.z, targetX, targetY, targetZ)
		price = (route2/1000) * Config.Price
		TriggerServerEvent('esx_aiTaxi:pay', price)
		TaskLeaveVehicle(GetPlayerPed(-1), globalTaxi, 1)
		Citizen.Wait(5000)
	end
	onWayBack = true
	customer = nil
	targetX = nil
	taxiBlip = nil
	RemoveBlip(CarBlip)
	parkingDone = false
	taxiArrived = false
	onTour = false
	onWayBack = false
	drive(26.92, -1736.77, 28.3, true, 'end')
	ped = nil
	globalTaxi = nil
end

function parking(x, y ,z)
	TaskVehiclePark(ped, globalTaxi, x, y, z, 0.0, 0, 30.0, false)
	parkingDone = true
end

function drive(x, y , z, delete, status)
	if status == 'start' then
		Citizen.Wait(math.random(1000,3000))
		ESX.ShowHelpNotification('Ein Fahrer ist auf dem Weg zu Ihnen.')
	elseif status == 'end' then
		ESX.ShowHelpNotification('Vielen Dank für Ihr Vertrauen.')
	end
	TaskVehicleDriveToCoordLongrange(ped, globalTaxi, x, y, z, Config.Speed, Config.DriveMode, 20.0)
	if delete then
		Citizen.Wait(15000)
		DeletePed(ped)
		ESX.Game.DeleteVehicle(globalTaxi)
	end
end
