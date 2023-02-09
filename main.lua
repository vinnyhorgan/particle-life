Camera = require("hump.camera")
nuklear = require("nuklear")
Object = require("classic")
vector = require("hump.vector")

ui = nuklear.newUI()

atoms = {}
groups = {}
rules = {}

camera = Camera()
camSpeed = 50
running = true

senseRadius = {value = 80, min = 0, max = 500, step = 1}
newGroupName = {value = ""}
newGroupNumber = {value = "0"}
newGroupColor = {value = "#FF0000"}
newRuleGroup1 = {value = 1, items = {"Null"}}
newRuleGroup2 = {value = 1, items = {"Null"}}
newRuleForce = {value = "0"}

math.randomseed(os.time())

love.window.maximize()

function reset()
    atoms = {}
    groups = {}
    rules = {}
end

function getGroupByName(name)
    for _, group in ipairs(groups) do
        if group.name == name then
            return group
        end
    end
end

function removeByValue(value, t)
    for i, v in ipairs(t) do
        if v == value then
            table.remove(t, i)
        end
    end
end

function randomFromTable(t)
    return t[math.random(#t)]
end

Atom = Object:extend()

function Atom:new(x, y, color)
    self.position = vector(x, y)
    self.color = color
    self.velocity = vector(0, 0)

    table.insert(atoms, self)
end

Group = Object:extend()

function Group:new(name, number, color)
    self.name = name
    self.number = number
    self.color = color
    self.atoms = {}

    for i = 0, number do
        local newAtom = Atom(math.random(500), math.random(500), color)
        table.insert(self.atoms, newAtom)
    end

    table.insert(groups, self)
end

Rule = Object:extend()

function Rule:new(group1, group2, g)
    self.group1 = group1
    self.group2 = group2
    self.value = g
    self.min = -1
    self.max = 1

    table.insert(rules, self)
end

function Rule:update()
    for _, a in ipairs(self.group1.atoms) do
        local force = vector(0, 0)

        for _, b in ipairs(self.group2.atoms) do
            local deltaPos = a.position - b.position

            local distance = math.sqrt(deltaPos.x * deltaPos.x + deltaPos.y * deltaPos.y)

            if distance > 0 and distance < senseRadius.value then
                local F = (self.value * 1) / distance

                force = force + F * deltaPos
            end
        end

        a.velocity = (a.velocity + force) * 0.5
        a.position = a.position + a.velocity

        if a.position.x <= 0 or a.position.x >= 500 then
            a.velocity.x = a.velocity.x * -1
        end

        if a.position.y <= 0 or a.position.y >= 500 then
            a.velocity.y = a.velocity.y * -1
        end
    end
end

function love.update(dt)
    if love.keyboard.isDown("lshift") then
        camSpeed = 250
    else
        camSpeed = 50
    end

    if love.keyboard.isDown("w") then
        camera.y = camera.y - camSpeed * dt
    elseif love.keyboard.isDown("s") then
        camera.y = camera.y + camSpeed * dt
    end

    if love.keyboard.isDown("a") then
        camera.x = camera.x - camSpeed * dt
    elseif love.keyboard.isDown("d") then
        camera.x = camera.x + camSpeed * dt
    end

    ui:frameBegin()

    if ui:windowBegin("Controls", love.graphics.getWidth() - 250, 0, 250, 200, "border", "title") then
        ui:layoutRow("dynamic", 30, 1)

        if ui:button("Reset") then
            reset()
        end

        if ui:button("Start / Stop") then
            running = not running
        end

        if ui:button("Randomize All") then
            atoms = {}
            groups = {}
            rules = {}

            for i = 0, math.random(1, 5) do
                Group(tostring(math.random(0, 1000000)), math.random(50, 400), nuklear.colorRGBA(math.random(0, 255), math.random(0, 255), math.random(0, 255)))
            end

            for _, group1 in ipairs(groups) do
                for _, group2 in ipairs(groups) do
                    Rule(group1, group2, math.random(-100, 100) / 100)
                end
            end

            senseRadius.value = math.random(20, 400)
        end

        ui:label("Sense Radius: " .. senseRadius.value)
        senseRadius.value = ui:slider(senseRadius.min, senseRadius.value, senseRadius.max, senseRadius.step)
    end
    ui:windowEnd()

    if ui:windowBegin("Groups", love.graphics.getWidth() - 250, 200, 250, love.graphics.getHeight() - 200, "border", "title", "scrollbar", "scroll auto hide") then
        ui:layoutRow("dynamic", 30, 1)

        ui:label("Create new Group")
        ui:label("Name")
        ui:edit("simple", newGroupName)
        ui:label("Number of atoms")
        ui:edit("simple", newGroupNumber)
        ui:label("Color of atoms")

        ui:layoutRow("dynamic", 80, 1)
        ui:colorPicker(newGroupColor)
        ui:layoutRow("dynamic", 30, 1)

        if ui:button("Create") and newGroupName.value ~= "" and newGroupNumber.value ~= "0" then
            Group(newGroupName.value, tonumber(newGroupNumber.value), newGroupColor.value)

            table.insert(newRuleGroup1.items, newGroupName.value)
            table.insert(newRuleGroup2.items, newGroupName.value)

            newGroupName.value = ""
            newGroupNumber.value = "0"
            newGroupColor.value = "#FF0000"
        end

        if ui:button("Random") then
            Group(tostring(math.random(0, 1000000)), math.random(50, 400), nuklear.colorRGBA(math.random(0, 255), math.random(0, 255), math.random(0, 255)))
        end

        ui:label("Groups")

        for _, group in ipairs(groups) do
            ui:label("- " .. group.name)

            if ui:button("Delete") then
                for _, atom in ipairs(group.atoms) do
                    removeByValue(atom, atoms)
                end

                removeByValue(group, groups)
                removeByValue(group.name, newRuleGroup1.items)
                removeByValue(group.name, newRuleGroup2.items)
            end
        end
    end
    ui:windowEnd()

    if ui:windowBegin("Rules", 0, 0, 250, love.graphics.getHeight(), "border", "title", "scrollbar", "scroll auto hide") then
        ui:layoutRow("dynamic", 30, 1)

        ui:label("Create new Rule")
        ui:label("Group 1")

        if ui:combobox(newRuleGroup1, newRuleGroup1.items) then

        end

        ui:label("Group 2")

        if ui:combobox(newRuleGroup2, newRuleGroup2.items) then

        end

        ui:label("Force")
        ui:edit("simple", newRuleForce)

        if ui:button("Create") and newRuleGroup1.value ~= 1 and newRuleGroup2.value ~= 1 then
            Rule(getGroupByName(newRuleGroup1.items[newRuleGroup1.value]), getGroupByName(newRuleGroup2.items[newRuleGroup2.value]), newRuleForce.value)

            newRuleGroup1.value = 1
            newRuleGroup2.value = 1
            newRuleForce = {value = "0"}
        end

        if ui:button("Random") then
            rules = {}

            for _, group1 in ipairs(groups) do
                for _, group2 in ipairs(groups) do
                    Rule(group1, group2, math.random(-100, 100) / 100)
                end
            end
        end

        ui:label("Rules")

        for _, rule in ipairs(rules) do
            ui:label("- " .. rule.group1.name .. " -> " .. rule.group2.name .. "   " .. rule.value)
            rule.value = ui:slider(-1, rule.value, 1, 0.1)

            if ui:button("Delete") then
                removeByValue(rule, rules)
            end
        end
    end
    ui:windowEnd()

    ui:frameEnd()

    if running then
        for _, rule in ipairs(rules) do
            rule:update()
        end
    end
end

function love.draw()
    camera:attach()

    for _, atom in ipairs(atoms) do
        r, g, b = nuklear.colorParseRGBA(atom.color)
        love.graphics.setColor(r / 255, g / 255, b / 255)
        love.graphics.circle("fill", atom.position.x, atom.position.y, 2)
    end

    love.graphics.setColor(1, 1, 1)
    love.graphics.rectangle("line", 0, 0, 500, 500)

    camera:detach()

    love.graphics.setColor(1, 1, 1)
    love.graphics.print("FPS: " .. love.timer.getFPS(), 260, 10)
    love.graphics.print("RUNNING: " .. tostring(running), 260, 40)
    love.graphics.print("Pan around with middle click.\nZoom with ctrl + wheel.\nHave fun :)", 260, 80)

    ui:draw()
end

function love.mousemoved(x, y, dx, dy, istouch)
    if love.mouse.isDown(3) then
        camera:move(-dx, -dy)
    end

    ui:mousemoved(x, y, dx, dy, istouch)
end

function love.wheelmoved(x, y)
    if love.keyboard.isDown("lctrl") then
        camera.scale = camera.scale + y * 0.1

        if camera.scale < 0.2 then
            camera.scale = 0.2
        elseif camera.scale > 3 then
            camera.scale = 3
        end
    end

    ui:wheelmoved(x, y)
end

function love.keypressed(key, scancode, isrepeat)
    ui:keypressed(key, scancode, isrepeat)
end

function love.keyreleased(key, scancode)
    ui:keyreleased(key, scancode)
end

function love.mousepressed(x, y, button, istouch, presses)
    ui:mousepressed(x, y, button, istouch, presses)
end

function love.mousereleased(x, y, button, istouch, presses)
    ui:mousereleased(x, y, button, istouch, presses)
end

function love.textinput(text)
    ui:textinput(text)
end
