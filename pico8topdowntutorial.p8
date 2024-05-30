pico-8 cartridge // http://www.pico-8.com
version 41
__lua__
function _init()
end

function _update60()
	foreach(enemies, function(e)
		e:control()
	end)
	p.control()
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
getsgn = function(v)
	return sgn(v)==0 and 0 or sgn(v)
end

pointcollideflag=function(x,y,flag) 
  return fget(mget(x/8,y/8))==flag
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

global=_ENV

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

	 return {x=a,y=b}
end

p = {
	sprt=1,
	x=8,
	y=8,
	box={x=1,y=1,w=6,h=5},
	control = function()
		local lx,ly,cex,cey=p.x,p.y,false,false
		local xy=getxy()
		
		foreach(enemies, function(e)
			if rects_overlap({x=xy.x,y=p.y,box=p.box},e) then cex=true	end
			if rects_overlap({x=p.x,y=xy.y,box=p.box},e) then cey=true	end
		end)
		
		if cex==false and collideflag(xy.x,p.y,1)==false then
			p.x=xy.x -- no collsion in x
		end
		
		if cey==false and collideflag(p.x,xy.y,1)==false then
			p.y=xy.y -- no collsion in y
		end
	end,
	draw = function(_ENV)
		spr(sprt,x,y)
	end
}
-->8
-- enemy --
fov=5--field of view number of sprites

enemy = class:new({
		sprt=2,
		x=0,
		y=0,
		xd=0,-- step x 0 upto 8
		yd=0,-- step y 0 upto 8
		mx=0,
		my=0,
		tmr=60,
		spd=0.05, -- speed
		st=0,-- 0- far 1-wall  2-find
		box={x=1,y=2,w=6,h=5},
		findplayer = function(_ENV)
			xd=flr((p.x-x)/fov)
		 yd=flr((p.y-y)/fov)
			if abs(xd)>=8 or abs(yd)>=8 then
				st=0
				return
			end
			
			mx=x+4
		 my=y+4 
	 	st=2
		 
		 for i=1,fov do
		 	mx+=xd
		 	my+=yd		 	
		 	if pointcollideflag(mx,my,1) then
		 	 st=1
		 	end
		 end
		end,
		move = function(_ENV)
			tmr-=0.5			
			
			if abs(xd)>=abs(yd) then
				x+=getsgn(xd)*spd
			else
			 y+=getsgn(yd)*spd
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
		 line(x+4, y+4, mx, my)
			pal(11,11-st)			
			spr(sprt,x,y)
		end
})

enemies={
	enemy:new({x=80,y=80}),
	enemy:new({x=40,y=80}),
	enemy:new({x=80,y=40})
}
__gfx__
00000000e000000e3000000300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000022222200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700022222200bbbbbb000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000022882200bbbbbb000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000022222200bb66bb000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700022222200bbbbbb000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000bbbbbb000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000e000000e3000000300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
55555555000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
55555555000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
55555555000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
55555555000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
55555555000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
55555555000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
55555555000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
55555555000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__gff__
0000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
1010101010101010101010101010101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1000000000000000101000101000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1000000000000000100000001000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1000000000000000100000001000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1000000010100000101000101000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1000000010000000000000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1000000000000000100000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1000000000000000100000101000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1000000010101010100000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1010101010101010101010101010101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
