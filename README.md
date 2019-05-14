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

UPDATE 14.05.2019
- there are multiple spawnpoints of the vehicle
- it will looking for the best spawn (the nearest)
- first option in GCPHONE is to call the taxi
(you can not call a taxi twice)
- second option is to cancel the order


here are two vids (one with AI-Traffic and one without)

https://plays.tv/video/5cd94b7883d9ca60be/aitaxi-without-traffic

https://plays.tv/video/5cd94c1f9f000a9f19/aitaxi-with-traffic

TO GET IT WORK WITH YOUR GCPHONE YOU HAVE TO EDIT:
**esx_addons_gcphone**
*server.lua*

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
 **and replace it with:**

```
RegisterServerEvent('esx_addons_gcphone:startCall')
AddEventHandler('esx_addons_gcphone:startCall', function (number, message, coords)
  local source = source

  if PhoneNumbers[number] ~= nil then
	if number == 'taxi' then
		if message == 'cancel' then
			TriggerClientEvent('esx_aiTaxi:cancelTaxi', source, true)
		else
			TriggerClientEvent('esx_aiTaxi:callTaxi', source, coords)
		end
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

Add this to the *config.json* of gcphone
these are the last lines in area of "serviceCall"

```
    },
    {
      "display": "Taxi",
      "backgroundColor": "yellow",
      "subMenu": [
	  {
			"title": "Taxi bestellen",
			"eventName": "esx_addons_gcphone:call",
			"type": {
				"number": "taxi",
				"message": "i need a ride"
			}
		},
        {
          "title": "Taxi abbestellen",
          "eventName": "esx_addons_gcphone:call",
          "type": {
				"number": "taxi",
				"message": "cancel"
			}
        }
      ]
    }
  ],

  "defaultContacts": [{
```

Known Bugs:
- sometimes if the taxidriver hits another car he will stop driving and you have to cancel the order.
- sometime the drivingmode is a little bit weird. if someone gets a better one feel free to share
