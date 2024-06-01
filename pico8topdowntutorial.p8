pico-8 cartridge // http://www.pico-8.com
version 41
__lua__
global=_ENV

function _init()
end

function _update()
	if nextlv then
		nextlv=false
		generatlevel()
	end
	foreach(enemies, function(e)
		e:control()
	end)
	p:control()
	passlevel()
end

function _draw()
	cls()
	map()
	p:draw()
	foreach(enemies, function(e)
		e:draw()
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
-- enemy --
enemy = class:new({
		sprt=5,
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
		findplayer = function(_ENV)
			local fov=7--field of view number of sprites
			if abs(p.x-x)<23 and abs(p.y-y)<23 then
			 fov=3
			end
			
			xd=flr((p.x-x)/fov)
		 yd=flr((p.y-y)/fov)
			if abs(xd)>=8 or abs(yd)>=8 then
				st=0
				return
			end
			
			mx=x+4
		 my=y+4 
	 	st=2
		 
		 local fovc = fov==7 and 4 or 1
		 
		 for i=1,fov-fovc do
		 	mx+=xd
		 	my+=yd		 	
		 	if pointcollideflag(mx,my,1) then
		 	 st=1
		 	end
		 end
		end,
		move = function(_ENV)
			tmr-=2			
			local xy,xyc,xsd,ysd,cex,cey=
				{x=x,y=y},
				{x=x,y=y},
				getsgn(xd),
				getsgn(yd),
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
			end
			
			if cey==false and collideflag(x,xy.y,box,1)==false then
				y=xy.y -- no collsion in y
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
		 --line(x+4, y+4, mx, my)
			pal(11,11-st)			
			spr(sprt,x,y)
		end
})
-->8
-- levels --
function generatlevel()
	enemies={}
	foreach(levels[crrtlv].enemies, function (e)
		add(enemies,enemy:new({x=e[1],y=e[2]}))
	end)
	levels[crrtlv].createmap()
end

function passlevel()
	if levels[crrtlv].pass() then
		crrtlv+=1
		nextlv=true
	end
end

function generatemap()
	 reload()	 
end

function collectallpass()
 local c=0
	foreach(enemies, function(e)
		if pointcollideflag(e.x+4,e.y+6,2) then
			c+=1
		end
	end)
	
	return #enemies == c
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
		enemies={
			{8,20},{8,30},{8,40},
			{8,50},{8,60},{8,70}
		},
		pass=collectallpass,
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
007007000ff2f2f00ddddddd0ffffff00ddddddd0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000770000ffffff00ff2f2f00ffffff00ffffff00605506000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000dd77f7dd0ffffff0dddddddd0ffffff00757757000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700dd7787dddd7787dddddddddddddddddd0076670000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000fd7787dffd7787dffddddddffddddddf0700007000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000dddddd00dddddd00dddddd00dddddd00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000cccccc0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
55555550000ccc0000ccc00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5555555000cc0c0000c0cc0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
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
