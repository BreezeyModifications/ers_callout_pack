---Created by Breezey Modifications---
Config.Callouts["fake_id"] = {
    Enabled = true,
    CalloutName = "Fake ID",
    CalloutDescriptions = {
        "Bar security reports a possible fake ID.",
        "Bouncer is requesting law enforcement for a patron using a suspicious ID.",
        "Patron at a bar may be underage and attempting to gain entry with false identification.",
        "Security has detained a college-age patron over a questionable driver's license."
    },
    CalloutUnitsRequired = {
        description = "Police response required.",
        policeRequired = true,
        ambulanceRequired = false,
        fireRequired = false,
        towRequired = false,
    },
    CalloutLocations = {
        [1] = vector3(128.95, -1284.87, 29.27),
        [2] = vector3(-1388.34, -586.91, 30.22),
        [3] = vector3(-560.12, 286.79, 82.18),
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
        local bouncer, patron
        local outcomeRoll = math.random(1, 100)
        local outcome = "compliant"

        if outcomeRoll <= 75 then
            outcome = "compliant"
        elseif outcomeRoll <= 85 then
            outcome = "flee"
        else
            outcome = "fight"
        end

        for i, pedNetId in pairs(pedList) do
            local ped = NetToPed(pedNetId)
            if DoesEntityExist(ped) then
                local timeout = GetGameTimer() + 5000
                while not NetworkHasControlOfEntity(ped) and GetGameTimer() < timeout do
                    ERS_RequestNetControlForEntity(ped)
                    Wait(50)
                end

                if i == 1 then
                    bouncer = ped
                elseif i == 2 then
                    patron = ped
                end
            end
        end

        if not DoesEntityExist(bouncer) or not DoesEntityExist(patron) then
            TriggerEvent("chat:addMessage", {
                args = {"[ERS]", "Fake ID callout failed to initialize correctly."}
            })
            return
        end

        ClearPedTasksImmediately(bouncer)
        TaskStandStill(bouncer, -1)
        SetBlockingOfNonTemporaryEvents(bouncer, true)
        FreezeEntityPosition(bouncer, true)

        ClearPedTasksImmediately(patron)
        TaskStandStill(patron, -1)
        SetBlockingOfNonTemporaryEvents(patron, true)
        TaskTurnPedToFaceEntity(patron, bouncer, -1)

        ERS_CreateTemporaryBlipForEntities(pedList, 15000)

        CreateThread(function()
            local triggered = false

            while DoesEntityExist(patron) and not triggered do
                Wait(1000)

                local playerCoords = GetEntityCoords(PlayerPedId())
                local patronCoords = GetEntityCoords(patron)
                local distance = #(playerCoords - patronCoords)

                if distance <= 12.0 then
                    triggered = true

                    if outcome == "compliant" then
                        TriggerEvent("chat:addMessage", {
                            args = {"[ERS]", "The patron appears agitated but remains compliant. Have the officer retrieve the ID and verify it through MDT."}
                        })

                        TaskStandStill(patron, -1)

                    elseif outcome == "flee" then
                        TriggerEvent("chat:addMessage", {
                            args = {"[ERS]", "The patron suddenly takes off on foot!"}
                        })

                        Wait(1500)
                        TaskSmartFleePed(patron, PlayerPedId(), 150.0, -1, false, false)

                    elseif outcome == "fight" then
                        TriggerEvent("chat:addMessage", {
                            args = {"[ERS]", "The patron becomes hostile and starts fighting!"}
                        })

                        Wait(1000)
                        SetPedAsEnemy(patron, true)
                        SetPedCombatAbility(patron, 1)
                        SetPedCombatMovement(patron, 2)
                        SetPedCombatRange(patron, 0)
                        TaskCombatPed(patron, PlayerPedId(), 0, 16)
                    end
                end
            end
        end)
    end,

    server = function(request, src, calloutData, pedList, vehicleList, objectList, propList, playersList, fireList, smokeList)
        local sceneCoords = vector3(calloutData.Coordinates.x, calloutData.Coordinates.y, calloutData.Coordinates.z)

        local bouncerCoords = sceneCoords
        local patronCoords = sceneCoords + vector3(1.2, 0.0, 0.0)

        local bouncerHeading = 180.0
        local patronHeading = 0.0

        local bouncerModel = "s_m_m_bouncer_01"
        local bouncerNetId = ERS_CreatePed(bouncerModel, bouncerCoords, bouncerHeading)
        table.insert(pedList, bouncerNetId)

        local patronModels = {
            "a_m_y_business_01",
            "a_m_y_beach_01",
            "a_m_y_hipster_01",
            "a_m_y_stbla_01"
        }
        local patronModel = patronModels[math.random(#patronModels)]
        local patronNetId = ERS_CreatePed(patronModel, patronCoords, patronHeading)
        table.insert(pedList, patronNetId)

        return true
    end
}
