pico-8 cartridge // http://www.pico-8.com
version 41
__lua__
-- game --
function _init()
 p = {
		x = 64,
		y = 64,
 	anim=anim({1,2,3,4},1,0.1),
	}	
 trail_color = 7
 create_screen_buffer()
 frame_count = 0 
 trail_history = {}
 closed_shape = false
end

function _update()
	frame_count += 1
	didmove=false
	timemanager:update()
		
	if btn(0) or btn(1) or btn(2) or btn(3) then
		if btn(0) then p.x=max(p.x - 1, 0) -- left
		elseif btn(1) then p.x=min(p.x + 1, 120) -- right
		elseif btn(2) then p.y=max(p.y - 1, 0) -- up
		elseif btn(3) then p.y=min(p.y + 1, 120) end -- down
		didmove=true
	end
	
	if didmove then
	 updateanimation(p.anim)
	 scbfr[p.x+4][p.y+4] = {color = trail_color, timestamp = frame_count}
	 
		add(trail_history, {x=p.x+4,y=p.y+4,timestamp=frame_count})
		
		-- check for closed shape
	 if not closed_shape and check_closed_shape(p.x + 4, p.y + 4) then
	  closed_shape = true
	  define_rectangle()
	  timemanager:addtimer(60,disable_closed_shape,1)
	 else
	 	
	 end
	    
		-- remove the oldest pixel if the trail history exceeds the max length
		if #trail_history > trail_max_length then
			del(trail_history, trail_history[1])
		end
	end
end

function _draw()
	cls()
	
	if closed_shape then
  print("closed shape detected!")
		rectfill(min_x, min_y, max_x, max_y, 13)
	end
	
	for i=0,127 do
	 for j=0,127 do
	  local cell = scbfr[i][j]
	  if cell.color ~= 0 then
	   -- check if the trail should still be visible
	   if frame_count - cell.timestamp < trail_lifetime then
	    pset(i, j, cell.color)
	   else
     -- clear the cell if the trail has expired
     scbfr[i][j] = getnewtrail()
	   end
	  end
	 end
	end
	
	spr(p.anim.sprt,p.x,p.y)
end
-->8
-- utils --
global=_ENV

class = setmetatable({
		new=function(self,tbl)
			tbl = tbl or {}
			
			return setmetatable(tbl,{__index=self})
		end
},{ __index=_ENV})

timemanager = class:new({
	timers = {},
	addtimer=function(_ENV,duration,callback,dt)
		add(timers,{
			duration=duration,
		 callback=callback,
		 dt=dt,
		 elapsed=0
		})
	end,
	update=function(_ENV)
		foreach(timers,function(t)
			t.elapsed += t.dt
	  if t.elapsed >= t.duration then
	   t.callback()
	   del(timers,t)
	  end
		end)
	end
})

function disable_closed_shape() 
	global.closed_shape=false 
end

function anim(sf,d,t)
	return {sprt=d,sf=sf,si=1,sl=count(sf),st=t}
end

function updateanimation(o)
	if o==nil 
	 or o.si==nil
	 or o.sl==1 then
	 return o
	end
	
 if o.si<o.sl+0.9 then
  o.si+=o.st
 else
  o.si=1
 end
 
 o.sprt=o.sf[flr(o.si)] 
end

-->8
-- trail --
trail_lifetime = 120
trail_max_length = 120
min_shape_size = 10 

function getnewtrail()
	return {color = 0, timestamp = 0}
end

function create_screen_buffer()
	scbfr = {}
 for i=0,127 do
   scbfr[i] = {}
   for j=0,127 do
    scbfr[i][j] = getnewtrail()
   end
 end
end

function check_closed_shape(x, y)
 -- check if the current position intersects with any previous position
 -- skip the last few positions to avoid false positives
 for i = 1, #trail_history - 60  do
  local pt = trail_history[i]
  if pt.x == x and pt.y == y then
 		return true
  end
 end
 return false
end

function define_rectangle()
 min_x = 127
 max_x = 0
 min_y = 127
 max_y = 0

 for i = 1,#trail_history,10 do
  min_x = min(min_x,trail_history[i].x)
  max_x = max(max_x,trail_history[i].x)
  min_y = min(min_y,trail_history[i].y)
  max_y = max(max_y,trail_history[i].y)
 end
end
__gfx__
00000000505007705050007050500770505000700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000666000666660006666600066666000660000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700666000066660000666600006666000060000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000666666666666666666666666666666660000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000066666660666666606666666066666660000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700067666660666666606766666067666660000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000060605060066050606060506060650060000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000070706070077060707070607070760070000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
