LatestGameState = LatestGameState or nil
InAction = InAction or false -- Prevents the agent from taking multiple actions at once.
local Game = "0rVZYFxvfJpO__EfOz0_PUQ3GFE9kEaES0GkUDNXjvE"

-- New shield and sword positions
local shields = {{x = math.random(1, 100), y = math.random(1, 100)}, {x = math.random(1, 100), y = math.random(1, 100)}}
local sword = {x = math.random(1, 100), y = math.random(1, 100)}

-- Function to check proximity
function isInProximity(x1, y1, x2, y2, range)
    return math.sqrt((x1 - x2)^2 + (y1 - y2)^2) <= range
end

-- Handle attack considering shields and sword
function handleAttack(attacker, target)
    -- Check if target is in shield range
    for i, shield in ipairs(shields) do
        if isInProximity(target.x, target.y, shield.x, shield.y, 5) then
            print("Target is shielded. No damage taken.")
            table.remove(shields, i)
            return
        end
    end

    -- Check if attacker is in sword range
    if isInProximity(attacker.x, attacker.y, sword.x, sword.y, 5) then
        target.energy = 0
        print("Attacker used the sword. Target is dead.")
        print("Target is killed instantly by the sword.")
        sword = nil
        return
    end

    -- Normal attack logic here
    if target.energy > 0 then
        target.energy = target.energy - attacker.energy
    end
end

-- Decides the next action based on proximity, energy, and speed
function decideNextAction()
    local player = LatestGameState.Players[ao.id]
    local targetInRange = false
    local speedFactor = 0.5 -- Adjust this value to represent the player's speed

    -- Calculate the expected utility of attacking
    local expectedUtility = function(energy, distance, speed)
        -- Incorporate speed into the utility calculation
        return energy * (1 - distance / 40) * speed
    end

    local bestMove = nil
    local bestUtility = -math.huge

    for target, state in pairs(LatestGameState.Players) do
        if target ~= ao.id then
            local distance = math.sqrt((player.x - state.x)^2 + (player.y - state.y)^2)
            if inRange(player.x, player.y, state.x, state.y, 1) then
                targetInRange = true
                -- Include speed in the utility calculation
                local utility = expectedUtility(player.energy, distance, speedFactor)
                if utility > bestUtility then
                    bestUtility = utility
                    bestMove = "Attack"
                end
            end
        end
    end

    -- Check if the player should attack quickly based on the utility and speed
    if player.energy > 5 and targetInRange and bestMove == "Attack" then
        print("Player in range. Attacking quickly.")
        -- Send the attack command with a speed factor
        ao.send({ Target = Game, Action = "PlayerAttack", Player = ao.id, AttackEnergy = tostring(player.energy * speedFactor) })
    else
        print("No player in range or insufficient energy. Moving randomly.")
        local directionMap = {"Up", "Down", "Left", "Right", "UpRight", "UpLeft", "DownRight", "DownLeft"}
        local randomIndex = math.random(#directionMap)
        -- Move quickly in a random direction
        ao.send({ Target = Game, Action = "PlayerMove", Player = ao.id, Direction = directionMap[randomIndex], Speed = speedFactor })
    end
end

-- Handler to print game announcements directly in the terminal.
Handlers.add(
    "PrintAnnouncements",
    Handlers.utils.hasMatchingTag("Action", "Announcement"),
    function (msg)
        print(msg.Event .. ": " .. msg.Data)
    end
)

-- Handler to handle game announcements.
Handlers.add(
    "HandleAnnouncements",
    Handlers.utils.hasMatchingTag("Action", "Announcement"),
    function (msg)
        ao.send({Target = Game, Action = "GetGameState"})
        print(msg.Event .. ": " .. msg.Data)
    end
)

-- Handler to update the game state upon receiving game state information.
Handlers.add(
    "UpdateGameState",
    Handlers.utils.hasMatchingTag("Action", "GameState"),
    function (msg)
        local json = require("json")
        LatestGameState = json.decode(msg.Data)
        ao.send({Target = ao.id, Action = "UpdatedGameState"})
        print("Game state updated. Print 'LatestGameState' for detailed view.")
    end
)

-- Handler to decide the next action based on the updated game state.
Handlers.add(
    "decideNextAction",
    Handlers.utils.hasMatchingTag("Action", "UpdatedGameState"),
    function ()
        if LatestGameState.GameMode ~= "Playing" then
            return
        end
        print("Deciding next action.")
        decideNextAction()
    end
)

-- Handler to automatically attack when hit by another player.
Handlers.add(
    "ReturnAttack",
    Handlers.utils.hasMatchingTag("Action", "Hit"),
    function (msg)
        local attacker = LatestGameState.Players[msg.Player]
        local target = LatestGameState.Players[ao.id]

        handleAttack(attacker, target)

        InAction = false
        ao.send({ Target = ao.id, Action = "Tick" })
    end
)

-- Handler to request game state on each tick.
Handlers.add("GetGameStateOnTick", Handlers.utils.hasMatchingTag("Action", "Tick"), function ()
    if not InAction then
        InAction = true
        ao.send({Target = Game, Action = "GetGameState"})
    end
end)

-- Handler to automate payment confirmation when waiting period starts.
Handlers.add(
    "AutoPay",
    Handlers.utils.hasMatchingTag("Action", "AutoPay"),
    function (msg)
        print("Auto-paying confirmation fees.")
        ao.send({ Target = Game, Action = "Transfer", Recipient = Game, Quantity = "1000"})
    end
)
