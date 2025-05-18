function loadSprite(name)
    sprites[name] = love.graphics.newImage('sprites/'..name..'.png')
end

function love.load()
    math.randomseed(os.time())
    framerate = 60

    sprites = {}
    loadSprite('background')
    loadSprite('bullet')
    loadSprite('player')
    loadSprite('zombie')
    loadSprite('deadZombie')

    player = {
        x = love.graphics.getWidth() / 2,
        y = love.graphics.getHeight() / 2,
        speed = 3*framerate,
    }

    myFont = love.graphics.newFont(30)

    zombies = {}
    bullets = {}

    gameState = 1
    score = 0
    highScore = 0
    maxTime = 2
    timer = maxTime
end

function love.update(dt)
    if gameState == 2 then
        if love.keyboard.isDown("d") and player.x < love.graphics.getWidth() then
            player.x = player.x + player.speed*dt
        end
        if love.keyboard.isDown("a") and player.x > 0 then
            player.x = player.x - player.speed*dt
        end
        if love.keyboard.isDown("w") and player.y > 0 then
            player.y = player.y - player.speed*dt
        end
        if love.keyboard.isDown("s") and player.y < love.graphics.getHeight() then
            player.y = player.y + player.speed*dt
        end
    end

    -- zombie movement
    for _, z in ipairs(zombies) do
        if distanceBetween(z.x, z.y, player.x, player.y) < 30 then
            if z.dead then
                -- player toueched a dead zombie
                z.gone = true
                score = score + 2
                goto continue
            end
            -- player touched a live zombie
            for i,z in ipairs(zombies) do
                zombies[i] = nil
                highScore = math.max(score, highScore)
                gameState = 1
                player.x = love.graphics.getWidth()/2
                player.y = love.graphics.getHeight()/2
            end
        end
        if not z.dead then
          -- dead zombies dont move
          z.alpha = zombiePlayerAngle(z)
          z.x = z.x + (math.cos(z.alpha) * z.speed * dt)
          z.y = z.y + (math.sin(z.alpha) * z.speed * dt)
        end
        ::continue::
    end

    -- bullet movement
    for i,b in ipairs(bullets) do
        b.x = b.x + (math.cos( b.direction ) * b.speed * dt)
        b.y = b.y + (math.sin( b.direction ) * b.speed * dt)
    end

    -- zombie and bullet collision
    for i,z in ipairs(zombies) do
        if z.dead then
            -- bullets dont touch dead zombies
            goto continue
        end
        for j,b in ipairs(bullets) do
            if distanceBetween(z.x, z.y, b.x, b.y) < 20 then
                z.dead = true
                b.dead = true
                score = score + 1
            end
        end
        ::continue::
    end

    -- bullet cleanup
    for i=#zombies,1,-1 do
        local z = zombies[i]
        if z.gone == true then
            table.remove(zombies, i)
        end
    end

    -- zombie cleanup
    for i=#bullets,1,-1 do
        local b = bullets[i]
        if b.dead == true or
            b.x < 0 or
            b.y < 0 or
            b.x > love.graphics.getWidth() or
            b.y > love.graphics.getHeight() then
            table.remove(bullets, i)
        end
    end

    if gameState == 2 then
        timer = timer - dt
        if timer <= 0 then
            spawnZombie()
            maxTime = 0.95 * maxTime
            timer = maxTime
        end
    end
end

function love.draw()
    love.graphics.draw(sprites.background, 0, 0)

    if gameState == 1 then
        love.graphics.setFont(myFont)
        love.graphics.printf("Click anywhere to begin!", 0, 50, love.graphics.getWidth(), "center")
    end
    love.graphics.printf("Score: " .. score, 0, love.graphics.getHeight()-100, love.graphics.getWidth(), "center")
    love.graphics.printf("High Score: " .. highScore, 0, love.graphics.getHeight()-100, love.graphics.getWidth(), "right")

    love.graphics.draw(sprites.player, player.x, player.y, playerMouseAngle(), nil, nil, sprites.player:getWidth()/2, sprites.player:getHeight()/2)

    for i,z in ipairs(zombies) do
        local zombieSprite = nil
        if z.dead then
            zombieSprite = sprites.deadZombie
        else
            zombieSprite = sprites.zombie
        end
        love.graphics.draw(zombieSprite, z.x, z.y, z.alpha, nil, nil, sprites.zombie:getWidth()/2, sprites.zombie:getHeight()/2)
    end

    for i,b in ipairs(bullets) do
        love.graphics.draw(sprites.bullet, b.x, b.y, nil, 0.5, nil, sprites.bullet:getWidth()/2, sprites.bullet:getHeight()/2)
    end
end

function love.mousepressed( x, y, button )
    if button == 1 and gameState == 2 then
        spawnBullet()
    elseif button == 1 and gameState == 1 then
        gameState = 2
        maxTime = 2
        timer = maxTime
        score = 0
    end
end

function playerMouseAngle()
    return math.atan2( player.y - love.mouse.getY(), player.x - love.mouse.getX() ) + math.pi
end

function zombiePlayerAngle(enemy)
    return math.atan2( player.y - enemy.y, player.x - enemy.x )
end

function spawnZombie()
    local zombie = {
        x = 0,
        y = 0,
        speed = 2*framerate,
        dead = false,
        gone = false,
        alpha = nil
    }

    local side = math.random(1, 4)
    if side == 1 then
        zombie.x = -30
        zombie.y = math.random(0, love.graphics.getHeight())
    elseif side == 2 then
        zombie.x = love.graphics.getWidth() + 30
        zombie.y = math.random(0, love.graphics.getHeight())
    elseif side == 3 then
        zombie.x = math.random(0, love.graphics.getWidth())
        zombie.y = -30
    elseif side == 4 then
        zombie.x = math.random(0, love.graphics.getWidth())
        zombie.y = love.graphics.getHeight() + 30
    end

    table.insert(zombies, zombie)
end

function spawnBullet()
    local bullet = {
        x = player.x,
        y = player.y,
        speed = 8*framerate,
        dead = false,
        direction = playerMouseAngle()
    }
    table.insert(bullets, bullet)
end

function distanceBetween(x1, y1, x2, y2)
    return math.sqrt( (x2 - x1)^2 + (y2 - y1)^2 )
end
