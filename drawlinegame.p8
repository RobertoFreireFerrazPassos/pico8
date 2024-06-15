pico-8 cartridge // http://www.pico-8.com
version 41
__lua__
-- constants
trail_lifetime = 120  -- lifetime of the trail in frames (e.g., 120 frames)

-- initialize the game state
function _init()
    -- sprite position
    player_x = 64
    player_y = 64

    -- trail color (7 is white)
    trail_color = 7

    -- screen buffer to keep track of painted pixels and their timestamps
    screen_buffer = {}
    for i=0,127 do
        screen_buffer[i] = {}
        for j=0,127 do
            screen_buffer[i][j] = {color = 0, timestamp = 0}
        end
    end

    -- frame counter
    frame_count = 0
end

-- update the game state
function _update()
    -- increment frame counter
    frame_count += 1

    -- move the player based on input
    if btn(0) then player_x = max(player_x - 1, 0) end -- left
    if btn(1) then player_x = min(player_x + 1, 127) end -- right
    if btn(2) then player_y = max(player_y - 1, 0) end -- up
    if btn(3) then player_y = min(player_y + 1, 127) end -- down

    -- paint the current position
    screen_buffer[player_x][player_y] = {color = trail_color, timestamp = frame_count}
end

-- draw the game
function _draw()
    -- clear the screen
    cls()

    -- draw the painted trail from the buffer
    for i=0,127 do
        for j=0,127 do
            local cell = screen_buffer[i][j]
            if cell.color ~= 0 then
                -- check if the trail should still be visible
                if frame_count - cell.timestamp < trail_lifetime then
                    pset(i, j, cell.color)
                else
                    -- clear the cell if the trail has expired
                    screen_buffer[i][j] = {color = 0, timestamp = 0}
                end
            end
        end
    end

    -- draw the player sprite
    spr(1, player_x, player_y)
end
__gfx__
00000000555555550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000005cccccc50000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
007007005cccccc50000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000770005cccccc50000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000770005cccccc50000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
007007005cccccc50000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000005cccccc50000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000555555550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
