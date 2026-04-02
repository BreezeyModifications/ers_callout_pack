---Created by Breezey Modifications---
Config.Callouts["suspicious_vehicle"] = {
    Enabled = true,
    CalloutName = "Suspicious Vehicle",
    CalloutDescriptions = {
        "A suspicious vehicle has been reported parked in the area.",
        "Caller reports an unfamiliar vehicle sitting in the area for an extended period.",
        "Suspicious vehicle reported. Officer to locate and investigate.",
        "Vehicle is reportedly acting suspicious in the area. Check the scene."
    },
    CalloutUnitsRequired = {
        description = "Police response required.",
        policeRequired = true,
        ambulanceRequired = false,
        fireRequired = false,
        towRequired = false,
    },
    CalloutLocations = {
        [1] = vector3(215.14, -810.22, 30.73),
        [2] = vector3(-562.44, 286.91, 82.18),
        [3] = vector3(1203.28, -1462.15, 34.85),
        [4] = vector3(1688.56, 3585.72, 35.62),
        [5] = vector3(-321.84, -1545.27, 27.54),
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
        local suspiciousVehicle
        local occupantPed

        for _, vehNetId in pairs(vehicleList) do
            local veh = NetToVeh(vehNetId)
            if DoesEntityExist(veh) then
                suspiciousVehicle = veh
                ERS_RequestNetControlForEntity(suspiciousVehicle)
                break
            end
        end

        for _, pedNetId in pairs(pedList) do
            local ped = NetToPed(pedNetId)
            if DoesEntityExist(ped) then
                local timeout = GetGameTimer() + 5000
                while not NetworkHasControlOfEntity(ped) and GetGameTimer() < timeout do
                    ERS_RequestNetControlForEntity(ped)
                    Wait(50)
                end
                occupantPed = ped
                break
            end
        end

        if not DoesEntityExist(suspiciousVehicle) then
            TriggerEvent("chat:addMessage", {
                args = {"[ERS]", "Suspicious Vehicle callout failed to initialize correctly."}
            })
            return
        end

        ERS_CreateTemporaryBlipForEntities(vehicleList, 15000)
        if #pedList > 0 then
            ERS_CreateTemporaryBlipForEntities(pedList, 15000)
        end

        SetVehicleEngineOn(suspiciousVehicle, false, true, true)
        SetVehicleDoorsLocked(suspiciousVehicle, 1)

        if DoesEntityExist(occupantPed) then
            SetBlockingOfNonTemporaryEvents(occupantPed, true)
            TaskVehicleTempAction(occupantPed, suspiciousVehicle, 1, 2000)

            TriggerEvent("chat:addMessage", {
                args = {"[ERS]", "A suspicious vehicle has been located. The vehicle appears occupied."}
            })
        else
            TriggerEvent("chat:addMessage", {
                args = {"[ERS]", "A suspicious vehicle has been located. The vehicle appears unoccupied."}
            })
        end
    end,

    -- SERVER SIDE
    server = function(request, src, calloutData, pedList, vehicleList, objectList, propList, playersList, fireList, smokeList)
        local vehCoords = vector3(calloutData.Coordinates.x, calloutData.Coordinates.y, calloutData.Coordinates.z)
        local vehHeading = math.random(0, 359)

        local vehiclePool = {
            -- Sedans
            "asea",
            "premier",
            "primo",
            "tailgater",
            "stanier",

            -- SUVs
            "baller",
            "granger",
            "rocoto",
            "xls",

            -- Sports / Coupes
            "buffalo",
            "comet2",
            "fusilade",
            "felon",

            -- Trucks / Vans
            "bobcatxl",
            "bison",
            "sadler",
            "speedo"
        }

        local vehicleModel = vehiclePool[math.random(#vehiclePool)]
        local vehNetId = ERS_CreateVehicle(vehicleModel, "automobile", vehCoords, vehHeading)
        table.insert(vehicleList, vehNetId)

        -- 50/50 chance of a ped being inside the vehicle
        local spawnOccupant = math.random() < 0.5

        if spawnOccupant then
            local pedModel = ERS_GetRandomModel(Config.randomPeds)
            local pedCoords = vehCoords + vector3(0.0, 0.0, 1.0)
            local pedNetId = ERS_CreatePed(pedModel, pedCoords, vehHeading)

            local vehicleEntity = NetworkGetEntityFromNetworkId(vehNetId)
            local pedEntity = NetworkGetEntityFromNetworkId(pedNetId)

            if DoesEntityExist(vehicleEntity) and DoesEntityExist(pedEntity) then
                SetPedIntoVehicle(pedEntity, vehicleEntity, -1)
            end

            table.insert(pedList, pedNetId)
        end

        return true
    end
}