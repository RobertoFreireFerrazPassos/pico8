pico-8 cartridge // http://www.pico-8.com
version 41
__lua__
function _init()
end

function _update()
	s:control()
	timemanager:update()
end

function _draw()
	cls()
	s:draw()
	foreach(towers,function(t)
		t:draw()
	end)
end

-->8
-- utils --
global=_ENV

class = setmetatable({
		new=function(self,tbl)
			tbl = tbl or {}
			
			return setmetatable(tbl,{ __index=self})
		end
},{ __index=_ENV})

function drawsprite(o)
	spr(o.sprt,o.x,o.y)
end

collideflag=function(x,y,flag)
	 for i=x,x+7,7 do
    if (fget(mget(i/8,y/8))==flag) or
         (fget(mget(i/8,(y+7)/8))==flag) then
          return true
    end
  end
  for i=y,y+7,7 do
    if (fget(mget(x/8,i/8))==flag) or
         (fget(mget((x+7)/8,i/8))==flag) then
          return true
    end
  end  
  return false
end

function rects_overlap(o1,o2)
		local o1x,o1y,o2x,o2y=
			o1.x+o1.box.x,
			o1.y+o1.box.y,
			o2.x+o2.box.x,
			o2.y+o2.box.y
		
  return o1x < o2x + o2.box.w and
         o1x + o1.box.w - 1 > o2x and
         o1y < o2y + o2.box.h and
         o1y + o1.box.h - 1 > o2y
end

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

-->8
-- objects --
towertypes = {
	{c=8,s=2},
	{c=9,s=3}
}

s = class:new({
	x=0,
	y=0,
	hm=false,--hasmoved
	at=false,--addedtower
	ctp=false,--changedtowertype
	tpi=1,--towertype index
	move=function(_ENV)
		if btn(0) then x=max(x - 8, 0) -- left
		elseif btn(1) then x=min(x + 8, 96) -- right
		elseif btn(2) then y=max(y - 8, 0) -- up
		elseif btn(3) then y=min(y + 8, 112) end -- down
	end,
	control=function(_ENV)
		if not hm and (btn(0) or btn(1) or btn(2) or btn(3)) then
			move(_ENV)
			hm=true
			timemanager:addtimer(5,function() s.hm=false end,1)
		end
		
		if not at and btn(4) then
			add(towers,t:new({x=x,y=y,s=towertypes[tpi].s}))
			at=true
			timemanager:addtimer(15,function() s.at=false end,1)
		end
		
		if not ctp and btn(5) then
			tpi+=1
			if tpi>#towertypes then tpi=1 end
			ctp=true
			timemanager:addtimer(10,function() s.ctp=false end,1)
		end
	end,
	draw=function(_ENV)
		pal(6,towertypes[tpi].c)
		spr(1,x,y)
		pal()
	end
})

towers= {}

t = class:new({
	x=0,
	y=0,
	s=0,
	control=function(_ENV)

	end,
	draw=function(_ENV)
		spr(s,x,y)
	end
})
__gfx__
00000000660660660000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000600000060888888009999990000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000888888009999990000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000600000060888888009999990000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000600000060888888009999990000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000888888009999990000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000600000060888888009999990000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000660660660000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
