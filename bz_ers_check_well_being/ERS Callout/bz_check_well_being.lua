---Created by Breezey Modifications---
Config.Callouts["check_well_being"] = {
    Enabled = true,
    CalloutName = "Check Well Being",
    CalloutDescriptions = {
        "Caller requests a welfare check on an individual at the reported location.",
        "Subject has been reported lying or standing in the area. Officer to check well being.",
        "Concerned citizen requests law enforcement check on a person at the location.",
        "Unknown condition of subject reported. Respond and assess the individual's status."
    },
    CalloutUnitsRequired = {
        description = "Police response required.",
        policeRequired = true,
        ambulanceRequired = false,
        fireRequired = false,
        towRequired = false,
    },
    CalloutLocations = {
        [1] = vector3(42.55, -1854.97, 22.83),
        [2] = vector3(426.58, -1821.11, 27.98),
        [3] = vector3(4.01, -1445.95, 30.55),
        [4] = vector3(-5.66, -19.36, 71.11),
        [5] = vector3(-206.43, 615.32, 198.2),
        [6] = vector3(390.49, 2585.3, 43.52),
        [7] = vector3(1698.02, 3850.19, 34.91),
        [8] = vector3(1717.68, 4671.75, 43.22),
        [9] = vector3(-158.28, 6411.66, 31.92),
        [10] = vector3(55.69, 6644.89, 32.28),
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
        local welfarePed
        local pedState = "healthy"

        -- Decide state:
        -- Injured = 10%
        -- Healthy = 40%
        -- Deceased = 50%
        local roll = math.random(1, 100)
        if roll <= 10 then
            pedState = "injured"
        elseif roll <= 50 then
            pedState = "healthy"
        else
            pedState = "deceased"
        end

        -- Get spawned ped
        for _, pedNetId in pairs(pedList) do
            local ped = NetToPed(pedNetId)
            if DoesEntityExist(ped) then
                local timeout = GetGameTimer() + 5000
                while not NetworkHasControlOfEntity(ped) and GetGameTimer() < timeout do
                    ERS_RequestNetControlForEntity(ped)
                    Wait(50)
                end

                welfarePed = ped
                break
            end
        end

        if not DoesEntityExist(welfarePed) then
            TriggerEvent("chat:addMessage", {
                args = {"[ERS]", "Check Well Being callout failed to initialize correctly."}
            })
            return
        end

        ERS_CreateTemporaryBlipForEntities(pedList, 15000)

        SetBlockingOfNonTemporaryEvents(welfarePed, true)
        ClearPedTasksImmediately(welfarePed)

        if pedState == "injured" then
            -- Injured, alive
            SetEntityHealth(welfarePed, 120)
            TaskStartScenarioInPlace(welfarePed, "WORLD_HUMAN_BUM_SLUMPED", 0, true)

            TriggerEvent("chat:addMessage", {
                args = {"[ERS]", "The subject appears injured but alive."}
            })

        elseif pedState == "healthy" then
            -- Normal / healthy
            local healthyScenarios = {
                "WORLD_HUMAN_STAND_IMPATIENT",
                "WORLD_HUMAN_SMOKING",
                "WORLD_HUMAN_AA_STAND",
                "WORLD_HUMAN_HANG_OUT_STREET"
            }

            local chosenScenario = healthyScenarios[math.random(#healthyScenarios)]
            TaskStartScenarioInPlace(welfarePed, chosenScenario, 0, true)

            TriggerEvent("chat:addMessage", {
                args = {"[ERS]", "The subject appears conscious and healthy."}
            })

        elseif pedState == "deceased" then
            -- Deceased
            SetEntityHealth(welfarePed, 0)
            ClearPedTasksImmediately(welfarePed)
            SetPedDropsWeaponsWhenDead(welfarePed, false)
            SetPedCanRagdoll(welfarePed, true)

            TriggerEvent("chat:addMessage", {
                args = {"[ERS]", "The subject appears to be deceased."}
            })
        end
    end,

    -- SERVER SIDE
    server = function(request, src, calloutData, pedList, vehicleList, objectList, propList, playersList, fireList, smokeList)
        local pedCoords = vector3(calloutData.Coordinates.x, calloutData.Coordinates.y, calloutData.Coordinates.z)
        local pedHeading = math.random(0, 359)

        local pedModel = ERS_GetRandomModel(Config.randomPeds)
        local pedNetId = ERS_CreatePed(pedModel, pedCoords, pedHeading)
        table.insert(pedList, pedNetId)

        return true
    end
}