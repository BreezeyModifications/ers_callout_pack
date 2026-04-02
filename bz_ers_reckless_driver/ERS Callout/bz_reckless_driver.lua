---Created by Breezey Modifications---
Config.Callouts["reckless_driver"] = {
    Enabled = true,
    CalloutName = "Reckless Driver",
    CalloutDescriptions = {
        "A reckless driver was reported swerving through traffic in the area.",
        "Multiple callers report a vehicle driving recklessly nearby.",
        "Vehicle seen speeding and driving erratically. Locate and investigate.",
        "Reckless driver reported in the area. Officer to locate vehicle and conduct stop if appropriate."
    },
    CalloutUnitsRequired = {
        description = "Police response required.",
        policeRequired = true,
        ambulanceRequired = false,
        fireRequired = false,
        towRequired = false,
    },
    CalloutLocations = {
        [1] = vector3(215.14, -794.21, 30.84),
        [2] = vector3(-1034.55, -2733.21, 20.17),
        [3] = vector3(1215.44, -1402.36, 35.22),
        [4] = vector3(-296.44, -991.28, 30.08),
        [5] = vector3(1683.92, 3291.44, 41.15),
    },

    PedChanceToFleeFromPlayer = 0,
    PedChanceToAttackPlayer = 0,
    PedChanceToSurrender = 0,
    PedChanceToObtainWeapons = 0,
    PedActionMinimumTimeoutInMs = 10000,
    PedActionMaximumTimeoutInMs = 15000,
    PedActionOnNoActionFound = "none",
    PedWeaponData = {},

    client = function(plyPed, pedList, vehicleList, playersList, objectList, propList, fireList, smokeList, calloutDataClient)
        local recklessDriver, recklessVehicle
        local stopMessageShown = false

        -- Get spawned vehicle
        for _, vehNetId in pairs(vehicleList) do
            local veh = NetToVeh(vehNetId)
            if DoesEntityExist(veh) then
                recklessVehicle = veh
                ERS_RequestNetControlForEntity(recklessVehicle)
                break
            end
        end

        -- Get spawned driver
        for _, pedNetId in pairs(pedList) do
            local ped = NetToPed(pedNetId)
            if DoesEntityExist(ped) then
                local timeout = GetGameTimer() + 5000
                while not NetworkHasControlOfEntity(ped) and GetGameTimer() < timeout do
                    ERS_RequestNetControlForEntity(ped)
                    Wait(50)
                end

                recklessDriver = ped
                break
            end
        end

        if not DoesEntityExist(recklessVehicle) or not DoesEntityExist(recklessDriver) then
            TriggerEvent("chat:addMessage", {
                args = {"[ERS]", "Reckless Driver callout failed to initialize correctly."}
            })
            return
        end

        -- Temporary blip so officer can get into the area
        ERS_CreateTemporaryBlipForEntities(vehicleList, 20000)

        -- Driver behavior setup
        SetBlockingOfNonTemporaryEvents(recklessDriver, true)
        SetDriverAbility(recklessDriver, 1.0)
        SetDriverAggressiveness(recklessDriver, 1.0)

        -- Start reckless driving
        CreateThread(function()
            Wait(2000)

            if DoesEntityExist(recklessDriver) and DoesEntityExist(recklessVehicle) then
                TaskVehicleDriveWander(recklessDriver, recklessVehicle, 35.0, 786603)
            end
        end)

        -- Officer guidance + traffic stop detection
        CreateThread(function()
            while DoesEntityExist(recklessDriver) and DoesEntityExist(recklessVehicle) do
                Wait(1500)

                local playerCoords = GetEntityCoords(PlayerPedId())
                local vehCoords = GetEntityCoords(recklessVehicle)
                local distance = #(playerCoords - vehCoords)

                if distance <= 60.0 and not stopMessageShown then
                    stopMessageShown = true
                    TriggerEvent("chat:addMessage", {
                        args = {"[ERS]", "The suspect vehicle has been located. Conduct a traffic stop if appropriate."}
                    })
                end

                -- crude stop detection: vehicle nearly stopped and player close behind/in area
                local vehSpeed = GetEntitySpeed(recklessVehicle)
                if stopMessageShown and distance <= 20.0 and vehSpeed <= 1.5 then
                    TriggerEvent("chat:addMessage", {
                        args = {"[ERS]", "Vehicle appears stopped. Investigate and conduct your traffic stop."}
                    })
                    break
                end
            end
        end)
    end,

    -- SERVER SIDE
    server = function(request, src, calloutData, pedList, vehicleList, objectList, propList, playersList, fireList, smokeList)
        local spawnCoords = vector3(calloutData.Coordinates.x, calloutData.Coordinates.y, calloutData.Coordinates.z)
        local heading = math.random(0, 359)

        -- Randomized vehicle pool by type: SUV, Sedan, Sports Car, Truck
        local vehiclePool = {
            -- SUVs
            "baller",
            "granger",
            "rocoto",
            "xls",

            -- Sedans
            "asea",
            "premier",
            "primo",
            "tailgater",

            -- Sports Cars
            "buffalo",
            "comet2",
            "feltzer2",
            "fusilade",

            -- Trucks
            "bobcatxl",
            "sandking",
            "rebel",
            "bison"
        }

        local vehicleModel = vehiclePool[math.random(#vehiclePool)]
        local vehNetId = ERS_CreateVehicle(vehicleModel, "automobile", spawnCoords, heading)
        table.insert(vehicleList, vehNetId)

        local pedModel = ERS_GetRandomModel(Config.randomPeds)
        local pedCoords = spawnCoords + vector3(0.0, 0.0, 1.0)
        local pedNetId = ERS_CreatePed(pedModel, pedCoords, heading)

        local vehicleEntity = NetworkGetEntityFromNetworkId(vehNetId)
        local pedEntity = NetworkGetEntityFromNetworkId(pedNetId)

        if DoesEntityExist(vehicleEntity) and DoesEntityExist(pedEntity) then
            SetPedIntoVehicle(pedEntity, vehicleEntity, -1)
        end

        table.insert(pedList, pedNetId)

        return true
    end
}