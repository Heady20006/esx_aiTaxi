RP-Taxijob is really hard.
If everyone has cars this job is really hard.

Thats why decided to eliminate this job on our RP-Server.

But what if you need a taxi and no one can do this job anymore?
RIGHT... lets call a NPC-Taxi.

Features:
- With gcphone you can call a NPC-Taxi
- Ped will spawn at DowntownCab in LS
- Taxi will spawn at DowntownCab in LS
(you can change the models and the speed in the config.lua)
- You can follow the  Taxi on minimap or fullscreenmap in the menu (there is a moving blip)
- if the taxi is arrived you have to enter and set a waypoint to the destination
- taxi will despawn after 15 seconds after reaching the destination
- you can change the drivemode in config
(use this site to create a drivingmode: https://vespura.com/drivingstyle/)
(thx @Vespura for this greate site :heavy_heart_exclamation:)

here are two vids (one with AI-Traffic and one without)

https://plays.tv/video/5cd94b7883d9ca60be/aitaxi-without-traffic


https://plays.tv/video/5cd94c1f9f000a9f19/aitaxi-with-traffic

If you want to get it work with gcphone you have to do a little edit:
esx_addons_gcphone:
server/main.lua

find:
```
RegisterServerEvent('esx_addons_gcphone:startCall')
AddEventHandler('esx_addons_gcphone:startCall', function (number, message, coords)
  local source = source
  if PhoneNumbers[number] ~= nil then
    getPhoneNumber(source, function (phone) 
      notifyAlertSMS(number, {
        message = message,
        coords = coords,
        numero = phone,
      }, PhoneNumbers[number].sources)
    end)
  else
    print('Appels sur un service non enregistre => numero : ' .. number)
  end
end)
```
 and replace it with:

```
AddEventHandler('esx_addons_gcphone:startCall', function (number, message, coords)
  local source = source
  if PhoneNumbers[number] ~= nil then
	if number == 'taxi' then
		TriggerClientEvent('esx_aiTaxi:callTaxi', source, coords)
	else
		getPhoneNumber(source, function (phone) 
		  notifyAlertSMS(number, {
			message = message,
			coords = coords,
			numero = phone,
		  }, PhoneNumbers[number].sources)
		end)
	end
  else
    print('Appels sur un service non enregistre => numero : ' .. number)
  end
end)
```

Known Bugs:
- sometimes if the taxidriver hits another car he will stop driving and a script restart is needed
(actually dont know how to fix)
