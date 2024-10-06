local files = love.filesystem.getDirectoryItems("assets")
local loaded = {}
local scalingFactor = 0.2
local isBouncing = false
local bounceTime = 0
local bounceDuration = 0.2



-- require("ssl")
-- local https = require("ssl.https")
-- local body, code, headers, status = https.request("https://www.google.com")
-- print(status)

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
    currencyPerClick = 1,
    currencyPerSecond = 0,
    carbon = 37400000000000,
    lastCarbonCheck = 37400000000000,
    carbonRemovalPerSecond = 0,
    upgrades = {
        u1 = {
            name = "Beach Cleaner",
            desc = "Goes to the beach each day to clean up trash. Removes 28 pounds of debris per hour (1 game second).",
            level = 1,
            cost = 10,
            scalingCost = 1.2,
            effect = "hydro",
            amount = 28,
            color = {0.678, 0.847, 0.902},
            tempColor = nil,
            tempColorDuration = 0
        },
        u2 = {
            name = "Trash Diver",
            desc = "Cleans up trash on the ocean floor using trained personnel and advanced equipment. Removes 300 pounds of debris per hour (1 game second).",
            level = 1,
            cost = 200,
            scalingCost = 1.5,
            effect = "hydro",
            amount = 300,
            color = {0.678, 0.847, 0.902},
            tempColor = nil,
            tempColorDuration = 0
        },
        u3 = {
            name = "Cleaner Boat",
            desc = "Specialized boats designed to clean up floating trash on the ocean. Removes 3,000 pounds of debris per hour (1 game second).",
            level = 1,
            cost = 2000,
            scalingCost = 2,
            effect = "hydro",
            amount = 3000,
            color = {0.678, 0.847, 0.902},
            tempColor = nil,
            tempColorDuration = 0
        },
        u4 = {
            name = "Tree planter",
            desc = "Goes to land devastated by deforestation and plants trees. Plants 30 trees per hour (1 game second).",
            level = 1, 
            cost = 30,
            scalingCost = 2,
            effect = "bio",
            amount = 30,
            color = {0.596, 0.984, 0.596},
            tempColor = nil,
            tempColorDuration = 0
        },
        u5 = {
            name = "Robot foresters",
            desc = "These autonomous robots can plant and care for young trees. Plants 700 trees per hour (1 game second).",
            level = 1,
            cost = 25000,
            scalingCost = 2,
            effect = "bio",
            amount = 700,
            color = {0.596, 0.984, 0.596},
            tempColor = nil,
            tempColorDuration = 0
        },
        u6 = {
            name = "Carbon Scrubbers",
            desc = "Carbon scrubbers are put on car exhausts and factory smoke stacks to limit the amount of carbon being released into the atmosphere. Removes 50 carbon per hour (1 game second).",
            level = 1,
            cost = 2000,
            scalingCost = 1.5,
            effect = "atmo",
            amount = 50,
            color = {0.83, 0.83, 0.83},
            tempColor = nil,
            tempColorDuration = 0
        },
        u7 = {
            name = "Seeding Drones",
            desc = "Map areas where trees would grow best using AI and drop seeds in seed vessels that ensure seed growth. Plants 4,000 trees per hour (1 game second).",
            level = 1,
            cost = 50000,
            scalingCost = 3,
            effect = "bio",
            amount = 4000,
            color = {0.596, 0.984, 0.596},
            tempColor = nil,
            tempColorDuration = 0
        },
        u8 = {
            name = "Solar Panels",
            desc = "Converts solar energy from the Sun into electricity. Solar power produces no emissions during generation itself, replacing the electricity that would’ve been made from emission based methods. Prevents 550 carbon per hour (1 game second).",
            level = 1,
            cost = 1500,
            scalingCost = 1.5,
            effect = "atmo",
            amount = 550,
            color = {0.83, 0.83, 0.83},
            tempColor = nil,
            tempColorDuration = 0
        },
        u9 = {
            name = "Public Transport",
            desc = "A massive network that can transport large amounts of people. Operates for the general public in a safe, affordable, environmentally friendly way. Prevents 10 carbon per hour (1 game second).",
            level = 1,
            cost = 550000,
            scalingCost = 1.1,
            effect = "atmo",
            amount = 93,
            color = {0.83, 0.83, 0.83},
            tempColor = nil,
            tempColorDuration = 0
        }
    }
}

local effects = {
    atmo = {
        name = "Atmosphere",
        color = {0.83, 0.83, 0.83},
        removalMul = 1,

    },
    bio = {
        name = "Biosphere",
        color = {0.596, 0.984, 0.596},
        removalMul = 1.2
    },
    hydro = {
        name = "Hydrosphere",
        color = {0.678, 0.847, 0.902},
        removalMul = 1.85
    }
}


local sortedUpgrades = {}


function love.load()
    love.window.setMode(800, 600)
    love.window.setTitle("EcoClicker Game")
    love.graphics.setFont(love.graphics.newFont(24))


    
    for i, file in ipairs(files) do
        local fname = file:gsub("%.png", "")
        local newFile = love.graphics.newImage("assets/" .. file)
        loaded[fname] = newFile
    end
    
    spawnCarbonAssets()
    
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

        local alignY = 65
        for _, upgrade in ipairs(sortedUpgrades) do
            if x >= 610 and x <= 790 and y >= alignY and y <= alignY + 50 then
                if data.currency >= upgrade.cost then

                    data.carbonRemovalPerSecond = data.carbonRemovalPerSecond + (upgrade.amount * effects[upgrade.effect].removalMul)
                    
                    
                    data.currency = data.currency - upgrade.cost
                    upgrade.level = upgrade.level + 1
                    upgrade.cost = math.ceil(upgrade.cost * upgrade.scalingCost)
                    data.currencyPerSecond = data.currencyPerSecond + upgrade.amount
                    data.currencyPerClick = data.currencyPerClick + math.ceil(upgrade.amount / 10)
                    upgrade.tempColor = {0.2, 1, 0.2}
                    upgrade.tempColorDuration = 0.1
                end
            end
            alignY = alignY + 60
        end

    end
end

local timer = 0
local ftimer = 0

local fact = "Soil comprises only 25 percent of the Earth's surface, of which only 10 percent can be used to grow food."

local facts = {"Soil comprises only 25 percent of the Earth's surface, of which only 10 percent can be used to grow food.", "Earth’s surface is two-thirds water. The continents on which we live make up the remainder", "The world produces around 350 million tonnes of plastic waste each year", "Around 60% of the ocean’s plastic is floating on the surface.", "Secondary pollutants are caused by chemical reactions in the atmosphere between different primary pollutants.", "Soil characteristics also affect water quality and aquatic ecosystems.", "Between 1960 and 2015, worldwide agricultural production more than tripled due to these technologies and a significant expansion."}

function love.update(dt)
    timer = timer + dt
    ftimer = ftimer + dt

    removeCarbonAssets()

    if timer >= 1 then
        data.currency = data.currency + data.currencyPerSecond
        data.carbon = data.carbon - data.carbonRemovalPerSecond
        timer = 0
    end

    if ftimer >= 10 then
        fact = facts[math.random(1, #facts)]
        ftimer = 0
    end

    if isBouncing then
        bounceTime = bounceTime + dt
        local scale = 0.1 + 0.1 * math.sin((bounceTime / bounceDuration) * math.pi)
        if bounceTime >= bounceDuration then
            scale = 0.2
            isBouncing = false
        end
        scalingFactor = scale
    else
        scalingFactor = 0.2
    end
    for _, upgrade in ipairs(sortedUpgrades) do
        if upgrade.tempColorDuration > 0 then
            upgrade.tempColorDuration = upgrade.tempColorDuration - dt
            if upgrade.tempColorDuration <= 0 then
                upgrade.tempColor = nil
            end
        end
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


carbonAssets = {}

function spawnCarbonAssets()
    for i = 1, 150 do 
        local x = math.random(-100, 500)
        local y = math.random(-150, 600)
        local randNum = math.random(1,3)
        table.insert(carbonAssets, {
            image = loaded["carbon_" .. randNum],
            x = x,
            y = y,
            -- width = loaded["carbon_" .. randNum]:getWidth(),
            -- height = loaded["carbon_" .. randNum]:getHeight(),
        })
    end
end

function removeCarbonAssets()
    local removeThreshold = 5000
    for _, i in ipairs(sortedUpgrades) do
        if (data.lastCarbonCheck - data.carbon) >= removeThreshold then
            table.remove(carbonAssets)
            data.lastCarbonCheck = data.carbon
        end
    end
end



function love.draw()
    
    local startY = -200

    love.graphics.setColor(1,1,1)
    love.graphics.draw(loaded["sky"], 235, 0, 0, 0.2, 0.2)
    love.graphics.draw(loaded["bio"], 145, 190, 0, 0.8, 0.8)
    love.graphics.draw(loaded["hydro"], 245, 400, 0, 0.4, 0.4)

    for _, carbonAsset in ipairs(carbonAssets) do
        love.graphics.draw(carbonAsset.image, carbonAsset.x, carbonAsset.y, 0.5, 0.5)
    end

    -- for _, treeAsset in ipairs(treeAssets) do
    --     love.graphics.draw(treeAsset.image, treeAsset.x, treeAsset.y)
    -- end


    for i, effect in ipairs(effects) do
        local y = startY + (i * 200)
        love.graphics.setFont(love.graphics.newFont(20))
        love.graphics.print(effect.name, 255, y + 5)
        love.graphics.setColor(1, 1, 1)
    end
    
    love.graphics.setColor(0.1, 0.5, 0.8)
    love.graphics.rectangle("fill", 0, 0, 250, 600)
    love.graphics.draw(loaded["backgroundleft"], 0, 0, 0, 250 / loaded["backgroundleft"]:getWidth(), 600 / loaded["backgroundleft"]:getHeight())
    

    love.graphics.setColor(0.3, 0.3, 0.3)
    love.graphics.rectangle("fill", 600, 0, 200, 600)


    -- trash
    love.graphics.setColor(1, 1, 1)
    love.graphics.draw(loaded["trash"], 10, 200, 0, scalingFactor * 1.5, scalingFactor * 1.5)

    local mouseX, mouseY = love.mouse.getPosition()
    

    love.graphics.setFont(love.graphics.newFont(37))
    love.graphics.print("Upgrades", 610, 10)

    love.graphics.setColor(0, 1, 0)
    love.graphics.setFont(love.graphics.newFont(25))
    love.graphics.draw(loaded["money"], 5, 23, 0, 0.05,0.05)
    love.graphics.draw(loaded["money"], 5, 63, 0, 0.05,0.05)
    love.graphics.draw(loaded["money"], 5, 103, 0, 0.05,0.05)
    love.graphics.print("Money: $" .. formatNumber(math.floor(data.currency)), 45, 25)
    love.graphics.print("Money/S: $" .. formatNumber(math.floor(data.currencyPerSecond)), 45, 65)
    love.graphics.print("Money/C: $" .. formatNumber(math.floor(data.currencyPerClick)), 45, 105)
    love.graphics.setColor(0,0,0)
    love.graphics.rectangle("fill", 365, 0, 230, 30)
    love.graphics.setFont(love.graphics.newFont(15))
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Carbon: ".. data.carbon, 375, 5)

    love.graphics.setColor(0.99, 0.99, 0.99)
    love.graphics.setFont(love.graphics.newFont(15))


    local wrappedFact = wrapText(fact, love.graphics.getFont(), 220)
    local factY = 500

    for i, line in ipairs(wrappedFact) do
        love.graphics.print(line, 15, factY + (i - 1) * 15)
    end

    local alignY = 65

    for _, upgrade in ipairs(sortedUpgrades) do
        local isHovered = mouseX >= 610 and mouseX <= 790 and mouseY >= alignY and mouseY <= alignY + 50
        if upgrade.tempColor then
            love.graphics.setColor(unpack(upgrade.tempColor))
        elseif isHovered then
            love.graphics.setColor(0.9, 0.9, 0.9)
        else
            love.graphics.setColor(unpack(upgrade.color))
        end

        love.graphics.rectangle("fill", 610, alignY, 180, 50)
        love.graphics.setColor(0, 0, 0)
        love.graphics.setFont(love.graphics.newFont(13))
        love.graphics.print(upgrade.name .. " (Lvl. " .. upgrade.level .. ")", 620, alignY + 5)
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
