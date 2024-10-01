local files = love.filesystem.getDirectoryItems("assets")
local loaded = {}
local scalingFactor = 0.2
local isBouncing = false
local bounceTime = 0
local bounceDuration = 0.2

function formatNumber(num)
    if num >= 1e12 then
        return string.format("%.1ft", num / 1e12):gsub("%.0t", "t")
    elseif num >= 1e9 then
        return string.format("%.1fb", num / 1e9):gsub("%.0b", "b")
    elseif num >= 1e6 then
        return string.format("%.1fm", num / 1e6):gsub("%.0m", "m")
    elseif num >= 1e3 then
        return string.format("%.1fk", num / 1e3):gsub("%.0k", "k")
    else
        return tostring(num)
    end
end

local data = {
    currency = 0,
    currencyPerClick = 100,
    currencyPerSecond = 0,
    trashRemoved = 0,
    treesPlanted = 0,
    carbonRemoved = 0,
    upgrades = {
        u1 = {
            name = "Beach Cleaner",
            desc = "Goes to the beach each day to clean up trash.",
            level = 1,
            cost = 10,
            scalingCost = 1.2,
            effect = "ocean",
            amount = 28,
            color = {0.678, 0.847, 0.902}
        },
        u2 = {
            name = "Trash Diver",
            desc = "Cleans up trash on the ocean floor using trained personnel and advanced equipment.",
            level = 1,
            cost = 200,
            scalingCost = 1.5,
            effect = "ocean",
            amount = 300,
            color = {0.678, 0.847, 0.902}
        },
        u3 = {
            name = "Cleaner Boat",
            desc = "Specialized boats designed to clean up floating trash on the ocean.",
            level = 1,
            cost = 2000,
            scalingCost = 2,
            effect = "ocean",
            amount = 3000,
            color = {0.678, 0.847, 0.902}
        },
        u4 = {
            name = "Tree planter",
            desc = "Goes to land devastated by deforestation and plants trees.", 
            level = 1, 
            cost = 30,
            scalingCost = 2,
            effect = "bio",
            amount = 30,
            color = {0.596, 0.984, 0.596}
        },
        u5 = {
            name = "Robot foresters",
            desc = "These autonomous robots can plant and care for young trees.",
            level = 1,
            cost = 25000,
            scalingCost = 2,
            effect = "bio",
            amount = 700,
            color = {0.596, 0.984, 0.596}
        },
        u6 = {
            name = "Carbon Scrubbers",
            desc = "Carbon scrubbers are put on car exhausts and factory smoke stacks to limit the amount of carbon being released into the atmosphere.",
            level = 1,
            cost = 2000,
            scalingCost = 1.5,
            effect = "atmo",
            amount = 50,
            color = {0.83, 0.83, 0.83}
        },
        u7 = {
            name = "Seeding Drones",
            desc = "Map areas where trees would grow best using AI and drop seeds in seed vessels that ensure seed growth.",
            level = 1,
            cost = 50000,
            scalingCost = 3,
            effect = "bio",
            amount = 4000,
            color = {0.596, 0.984, 0.596}
        },
        u8 = {
            name = "Solar Panels",
            desc = "Converts solar energy from the Sun into electricity. Solar power produces no emissions during generation itself, replacing the electricity that would’ve been made from emission based methods.",
            level = 1,
            cost = 1500,
            scalingCost = 1.5,
            effect = "atmo",
            amount = 550,
            color = {0.83, 0.83, 0.83}
        },
        u9 = {
            name = "Public Transport Network",
            desc = "A massive network that can transport large amounts of people. Operates for the general public in a safe, affordable, environmentally friendly way.",
            level = 1,
            cost = 550000,
            scalingCost = 1.1,
            effect = "atmo",
            amount = 10,
            color = {0.83, 0.83, 0.83}
        }
    }
}

local sortedUpgrades = {}

function love.load()
    love.window.setMode(800, 600)
    love.window.setTitle("EcoClicker Game")
    love.graphics.setFont(love.graphics.newFont(24))
    customFont = love.graphics.newFont("fonts/SilverFont.ttf", 24)
    for i, file in ipairs(files) do
        local fname = file:gsub("%.png", "")
        local newFile = love.graphics.newImage("assets/" .. file)
        loaded[fname] = newFile
    end

    for key, upgrade in pairs(data.upgrades) do
        table.insert(sortedUpgrades, upgrade)
    end

    table.sort(sortedUpgrades, function(a, b)
        if a.effect == b.effect then
            return a.cost < b.cost
        else
            return a.effect < b.effect
        end
    end)
end


function love.mousepressed(x, y, button)
    if button == 1 then
        local trashWidth, trashHeight = loaded["trash"]:getDimensions()
        if x >= 25 and x <= 25 + trashWidth * scalingFactor and y >= 250 and y <= 250 + trashHeight * scalingFactor then
            data.currency = data.currency + data.currencyPerClick
            isBouncing = true
            bounceTime = 0
        end
        local alignY = 100
        
        for _, upgrade in ipairs(sortedUpgrades) do
            if x >= 610 and x <= 790 and y >= alignY and y <= alignY + 50 then
                if data.currency >= upgrade.cost then
                    data.currency = data.currency - upgrade.cost
                    upgrade.level = upgrade.level + 1
                    upgrade.cost = math.ceil(upgrade.cost * upgrade.scalingCost)
                    data.currencyPerSecond = data.currencyPerSecond + upgrade.amount
                end
            end
            alignY = alignY + 60
        end
    end
end

local timer = 0

function love.update(dt)
    timer = timer + dt
    if timer >= 1 then
        data.currency = data.currency + data.currencyPerSecond
        timer = 0
    end
    if isBouncing then
        bounceTime = bounceTime + dt
        local scale = 0.1 + 0.1 * math.sin((bounceTime / bounceDuration) * (math.pi))
        if bounceTime >= bounceDuration then
            scale = 0.2
            isBouncing = false
        end
        scalingFactor = scale
    else
        scalingFactor = 0.2
    end
end

local function wrapText(text, font, limit)
    local words = {}
    local lines = {}
    local currentLine = ""
    for word in text:gmatch("%S+") do
        if font:getWidth(currentLine .. " " .. word) < limit then
            currentLine = currentLine .. " " .. word
        else
            if currentLine ~= "" then
                table.insert(lines, currentLine)
            end
            currentLine = word
        end
    end
    if currentLine ~= "" then
        table.insert(lines, currentLine)
    end
    return lines
end

function love.draw()
    -- middle side
    -- love.graphics.setColor(0.5,0.5,0.5)
    -- love.graphics.rectangle("fill", 250, 0, 350, 600)

    -- Left Side 
    love.graphics.setColor(1, 1, 1)
    love.graphics.setColor(0.1, 0.5, 0.8)
    love.graphics.rectangle("fill", 0, 0, 250, 600)
    love.graphics.draw(loaded["backgroundleft"], 0, 0, 0, 250 / loaded["backgroundleft"]:getWidth(), 600 / loaded["backgroundleft"]:getHeight())

    -- Right Side
    love.graphics.setColor(0.3, 0.3, 0.3)
    love.graphics.rectangle("fill", 600, 0, 200, 600)
    love.graphics.setColor(1,1,1)
    love.graphics.draw(loaded["trash"], 25, 200, 0, scalingFactor * 1.5, scalingFactor * 1.5)
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(love.graphics.newFont(37))
    love.graphics.print("Upgrades", 610, 10)


    -- Money Text
    love.graphics.setColor(0, 1, 0)
    love.graphics.setFont(love.graphics.newFont(33))
    love.graphics.print("Money: $" .. formatNumber(math.floor(data.currency)), 15, 20)
    love.graphics.print("Money/Second: $" .. formatNumber(math.floor(data.currencyPerSecond)), 15, 65)

    -- GLOBE Text
    love.graphics.setColor(0.99, 0.99, 0.99)
    love.graphics.setFont(love.graphics.newFont(10))
    love.graphics.print("GLOBE Protocols are standardized methods", 20, 500)
    love.graphics.print("for collecting environmental data.", 20, 520)
    love.graphics.print("They cover various Earth system areas such", 20, 540)
    love.graphics.print("as the atmosphere, hydrosphere, biosphere.", 20, 560)
    
    local alignY = 65
    local mouseX, mouseY = love.mouse.getPosition()
    for _, upgrade in ipairs(sortedUpgrades) do
        local isHovered = mouseX >= 610 and mouseX <= 790 and mouseY >= alignY and mouseY <= alignY + 50
        if isHovered then
            love.graphics.setColor(0.9, 0.9, 0.9)
        else
            love.graphics.setColor(unpack(upgrade.color))
        end
        love.graphics.rectangle("fill", 610, alignY, 180, 50)
        love.graphics.setColor(0, 0, 0)
        love.graphics.setFont(love.graphics.newFont(13))
        love.graphics.print(upgrade.name .. " (Lvl. " .. upgrade.level  .. ")", 620, alignY + 5)
        love.graphics.print("Cost: $" .. formatNumber(upgrade.cost), 620, alignY + 30)
        love.graphics.setFont(love.graphics.newFont(12))
        if isHovered then
            love.graphics.setColor(0, 0, 0, 0.6)
            local tooltipPadding = 10
            local tooltipWidth = 0
            local tooltipHeight = 0
            
            local wrappedText = wrapText(upgrade.desc, love.graphics.newFont(12), 180 - tooltipPadding * 2)
            for _, line in ipairs(wrappedText) do
                local lineWidth = love.graphics.getFont():getWidth(line)
                if lineWidth > tooltipWidth then
                    tooltipWidth = lineWidth
                end
                tooltipHeight = tooltipHeight + 15
            end
            tooltipHeight = tooltipHeight + tooltipPadding * 2
        
            love.graphics.rectangle("fill", mouseX - tooltipWidth - tooltipPadding / 2, mouseY - tooltipHeight - 5, tooltipWidth + tooltipPadding, tooltipHeight)
            love.graphics.setColor(1, 1, 1)
        
            for i, line in ipairs(wrappedText) do
                love.graphics.print(line, mouseX - tooltipWidth, mouseY - tooltipHeight + (i - 1) * 15 - 5 + tooltipPadding / 2)
            end
        end
        
        alignY = alignY + 60
    end
end
