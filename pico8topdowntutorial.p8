pico-8 cartridge // http://www.pico-8.com
version 41
__lua__
global=_ENV
gameover=false
gameovertmr=60

function resetgame()
	gameovertmr-=0.5	
	if gameovertmr<=0 then
		crrtlv=1
		nextlv=true
		gameover=false
		gameovertmr=60
	end
end

function _init()
end

function _update()
	if gameover then
	 resetgame()
		return
	end
	
	if nextlv then
		nextlv=false
		generatlevel()
	end
	foreach(enemies, function(e)
		e:control()
	end)
	foreach(fires, function(f)
		f:control()
	end)	
	p:control()
	passlevel()
end

function _draw()
	cls()
	map()
	if gameover then
		print("game over",40,63,8)
		return
	end
	
	p:draw()
	foreach(enemies, function(e)
		e:draw()
	end)
	foreach(fires, function(f)
		f:draw()
	end)	
end
-->8
-- utils --
anim=function(sf,d,t)
	return {sprt=d,sf=sf,si=1,sl=count(sf),st=t}
end

updateanimation=function(o)
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
 return o
end
	
getsgn = function(v)
	return v==0 and 0 or sgn(v)
end

pointcollideflag=function(x,y,flag) 
  return fget(mget(x/8,y/8))==flag
end

collideflag=function(x,y,b,flag)
	 for i=x+b.x,x+b.x+b.w-1,b.w-1 do
    if (fget(mget(i/8,(y+b.y)/8))==flag) or
         (fget(mget(i/8,(y+b.y+b.h-1)/8))==flag) then
          return true
    end
  end
  for i=y+b.y,y+b.y+b.h-1,b.h-1 do
    if (fget(mget((x+b.x)/8,i/8))==flag) or
         (fget(mget((x+b.x+b.w-1)/8,i/8))==flag) then
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

class = setmetatable({
		new=function(self,tbl)
			tbl = tbl or {}
			
			return setmetatable(tbl,{ __index=self})
		end
},{ __index=_ENV})
-->8
-- player --
butarr={1,2,0,3,5,6,3,4,8,7,4,0,1,2,0}
butarr[0]=0
dirx={-1,1, 0,0,-0.7, 0.7,0.7,-0.7}
diry={ 0,0,-1,1,-0.7,-0.7,0.7, 0.7}

function getxy()
  local a,b,dir=p.x,p.y,butarr[btn()&0b1111]
  if lastdir!=dir and dir>=5 then
	  a=flr(a)+0.5
	  b=flr(b)+0.5
	 end	 
	 if dir>0 then
	  a+=dirx[dir]
	  b+=diry[dir]
  end
	 lastdir=dir
	 return {x=a,y=b,dir=dir}
end

p = class:new({
	sprt=1,
	x=63,
	y=63,
	dirsprt={
 	anim({1,2},1,0.1),
 	anim({1,2},1,0.1),
 	anim({3,4},3,0.1),
 	anim({1,2},1,0.1),
 	anim({3,4},3,0.1),
 	anim({3,4},3,0.1),
 	anim({1,2},1,0.1),
 	anim({1,2},1,0.1)
 },
 dirf={1,0,0,0,1,0,0,1},
 fx=false,
 fy=false,
	box={x=0,y=0,w=8,h=8},
	cetmr=60,
	control = function(_ENV)
		local lx,ly,cex,cey=x,y,false,false
		local xy=getxy()
		
		if xy.dir>0 then
	  sprt=updateanimation(dirsprt[xy.dir]).sprt
	  fx=dirf[xy.dir]==1
  else
   sprt=1
  end
  
		foreach(enemies, function(e)
			if rects_overlap({x=xy.x,y=y,box=box},e) then cex=true	end
			if rects_overlap({x=x,y=xy.y,box=box},e) then cey=true	end
		end)
		
		if cex==false and cey==false then
			cetmr=60
		else
			cetmr-=1
		end
		
		if cetmr<=0 then
			global.gameover=true
		end
		
		if cex==false and collideflag(xy.x,y,box,1)==false then
			x=xy.x -- no collsion in x
		end
		
		if cey==false and collideflag(x,xy.y,box,1)==false then
			y=xy.y -- no collsion in y
		end
	end,
	draw = function(_ENV)
		spr(sprt,x,y,1,1,fx,fy)
	end
})
-->8
-- fire --
fire = class:new({
	sprt=8,
	anmspt=anim({8,9,10,11,12},8,0.1),
	x=0,
	y=0,
	tmr=60,
	control=function(_ENV)
		tmr-=0.5
		sprt=updateanimation(anmspt).sprt
		if tmr<=0 then
			del(fires,_ENV)
		end
	end,
	draw=function(_ENV)
		spr(sprt,x,y)
	end
})

-- enemy --
enemy = class:new({
		sprt=5,
		anmspt=anim({5,6,7},5,0.2),
		x=0,
		y=0,
		xd=0,-- step x 0 upto 8
		yd=0,-- step y 0 upto 8
		mx=0,
		my=0,
		tmr=60,
		spd=0.4, -- speed
		st=0,-- 0- far 1-wall  2-find
		box={x=2,y=4,w=5,h=3},
		fov={{7,4},{3,1},{2,0}},--field of view number of sprites
		findplayer = function(_ENV)
			local cfov=fov[1]
			if abs(p.x-x)<15 and abs(p.y-y)<15 then
			 cfov=fov[3]
			elseif abs(p.x-x)<23 and abs(p.y-y)<23 then
				cfov=fov[2]
			end
			
			xd=flr((p.x-x)/cfov[1])
		 yd=flr((p.y-y)/cfov[1])
			if abs(xd)>8 or abs(yd)>8 then
				st=0
				return
			end
			
			mx=x+4
		 my=y+4 
	 	st=2

		 for i=1,cfov[2] do
		 	mx+=xd
		 	my+=yd		 	
		 	if pointcollideflag(mx,my,1) then
		 	 st=1
		 	end
		 end
		end,
		move = function(_ENV)
			tmr-=2			
			local xy,xyc,xsd,ysd,cex,cey,didmv=
				{x=x,y=y},
				{x=x,y=y},
				getsgn(xd),
				getsgn(yd),
				false,
				false,
				false
			
			if abs(xd)>=abs(yd) then
				xy.x=x+xsd*spd
				xyc.x=x+xsd*2--2 must be > spd for collision detection
			 
			 -- try to go around wall
				if collideflag(xy.x,y,box,1) then
					xy.x=x
				 xyc.x=x
					xy.y=y+ysd*spd
			 	xyc.y=y+ysd*2
				end
			else
			 xy.y=y+ysd*spd
			 xyc.y=y+ysd*2
			 
			 -- try to go around wall
			 if collideflag(x,xy.y,box,1) then
					xy.y=y
			  xyc.y=y
					xy.x=x+xsd*spd
				 xyc.x=x+xsd*2				
				end
			end
			
			foreach(enemies, function(e)
				if e != _ENV then
					if rects_overlap({x=xyc.x,y=y,box=box},e) then cex=true	end
				 if rects_overlap({x=x,y=xyc.y,box=box},e) then cey=true	end
				end				
			end)
			
			if cex==false and collideflag(xy.x,y,box,1)==false then
				x=xy.x -- no collsion in x
				didmv=true
			end
			
			if cey==false and collideflag(x,xy.y,box,1)==false then
				y=xy.y -- no collsion in y
				didmv=true
			end
			
			if didmv then
				sprt=updateanimation(anmspt).sprt
			end
			
			if collideflag(x,y,box,2) then
				add(fires,fire:new({x=x,y=y}))
				del(enemies,_ENV)
			end
				
			if tmr<=0 then
				tmr=60
				st=0
			end
		end,
		control = function(_ENV)		
			if st==0 then
				findplayer(_ENV)
			elseif  st==1 then
				findplayer(_ENV)
			elseif st==2 then
				move(_ENV)
			end
		end,
		draw = function(_ENV)		
			spr(sprt,x,y)
		end
})
-->8
-- levels --
function generatlevel()
	local crlvl=levels[crrtlv]
	fires={}
	enemies={}
	p.x=crlvl.p.x
	p.y=crlvl.p.y
	foreach(crlvl.enemies, function (e)
		add(enemies,enemy:new({x=e[1],y=e[2]}))
	end)
	reload()	
	crlvl.createmap()
end

function passlevel()
	if levels[crrtlv].pass() then
		crrtlv+=1
		nextlv=true
	end
end

function noenemiespass()
	return #enemies == 0
end

function drawbluecircle(x,y)
		mset(x,y,17)
		mset(x,y+1,33)
		mset(x+1,y,18)
		mset(x+1,y+1,34)
end

crrtlv=1
nextlv=true
levels = {
 {
		p={x=8,y=8},
		enemies={
			{40,70},{40,80},{40,90},
			{50,70},{50,80},{50,90},
			{60,70},{60,80},{60,90}
		},
		pass=noenemiespass,
		createmap = function()
			drawbluecircle(5,2)
			drawbluecircle(7,2)
		end
	},
	{
		p={x=8,y=8},
		enemies={
			{40,70},{40,80},{40,90},
			{50,70},{50,80},{50,90},
			{60,70},{60,80},{60,90}
		},
		pass=noenemiespass,
		createmap = function()
			drawbluecircle(5,2)
			drawbluecircle(7,2)
		end
	},
	{
		p={x=20,y=110},
		enemies={
			{10,30},{10,40},{10,50},
			{20,30},{20,40},{30,30},
			{30,40},{30,50},
		},
		pass=noenemiespass,
		createmap = function()
			for i=1,14 do
				mset(5,i,16)
			end
			drawbluecircle(1,2)
			drawbluecircle(3,2)
		end
	},
	{
		p={x=63,y=63},
		enemies={
			{8,20},{8,30},{8,40},
			{8,50},{8,60},{8,70}
		},
		pass=noenemiespass,
		createmap = function()
			for i=3,13 do
				mset(5,i,16)
				mset(10,i,16)
			end
			drawbluecircle(11,5)
			drawbluecircle(13,5)
		end
	},
	{
		p={x=63,y=63},
		enemies={
			{8,10}
		},
		pass=function(enemies)
		end,
		createmap = function()
		end
	}
}
__gfx__
000000000dddddd0000000000dddddd0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000ddddddd0dddddd00ddddddd0dddddd00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
007007000ff2f2f00ddddddd0ffffff00ddddddd0000000000000000000000000000000000000000000100000000100000000000000000000000000000000000
000770000ffffff00ff2f2f00ffffff00ffffff00808808008088080080880800000000000001000000010000001000000010000000000000000000000000000
00077000dd77f7dd0ffffff0dddddddd0ffffff0025225200252252002522520000110000001d000000d10000001d000000d1000000000000000000000000000
00700700dd7787dddd7787dddddddddddddddddd002882000028820000288200001dd100001cc100001cc100001cc100001cc100000000000000000000000000
00000000fd7787dffd7787dffddddddffddddddf02000020020002000020002001cccc1001cccc1001cccc1001cccc1001cccc10000000000000000000000000
000000000dddddd00dddddd00dddddd00dddddd00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000cccccc0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
66666660000ccc0000ccc00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6666666000cc0c0000c0cc0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000cc00c00c00cc0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
550550500c0c00cccc00c0c000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000c00c000000c00c000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
505505500c00cc0cc0cc00c000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000c00c0cc00cc0c00c00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000c0c00c0000c00c0c00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000cccccc0000cccccc00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000c0000cccc0000c000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000c0000c00c0000c000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000c000c00c000c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000c000cc000c00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000ccc0000ccc00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000cccccc0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__gff__
0000000000000000000000000000000001020200000000000000000000000000000202000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
1010101010101010101010101010101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1010101010101010101010101010101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
