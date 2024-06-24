pico-8 cartridge // http://www.pico-8.com
version 41
__lua__
function _init()	
	gameover=false
	currentlevel=1
	generatelevel()
end

function _update()
 timemanager:update()
 
	if life<=0 then
		gameover=true
		timemanager:addtimer(30,function() _init() end,1)
		return
	end
	
	if #enemies==0 then
		currentlevel+=1
		generatelevel()
	end
 
	if showenemies then
		return
	end
	
	s:control()
	
	foreach(towers,function(t)
		t:control()
	end)
	
	foreach(enemies,function(e)
		e:control()
	end)
end

function _draw()
	cls()
	draw_footer()
	
	if gameover then
		draw_gameover()
		return
	end
	
	if showenemies then
		camera(127,0)
		timemanager:addtimer(60,function() showenemies=false end,1)
	else
		camera(0,0)
	end		
	s:draw()
	foreach(towers,function(t)
		t:draw()
	end)
	foreach(enemies,function(e)
		e:draw()
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

function distance(x1, y1, x2, y2)
  return (x2 - x1)^2 + (y2 - y1)^2
end

function draw_life()
	spr(32,8*8,15*8)
	print(life,9*8+2,15*8)
end

function draw_gameover()
	print("game over",4*8,6*8,8)
end

function draw_footer()
	draw_availabletowers()
	draw_life()
end
-->8
-- selector --
s = class:new({
	x=8,
	y=0,
	hm=false,--hasmoved
	at=false,--addedtower
	ctp=false,--changedtowertype
	tpi=1,--towertype index
	move=function(_ENV)
		if btn(0) then x=max(x - 8, 8) -- left
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
		
		if not at and btn(4) 
			and	availabletowers[tpi].q>0 
			and not get_buffer(x,y).a then
				local reftower=createtower(x,y,towertypes[tpi])
				at=true
				availabletowers[tpi].q-=1
				timemanager:addtimer(10,function() s.at=false end,1)
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

-->8
-- tower --

--c color
--s sprite
--as attack speed
--d damage
--st stun
--r reach
--l life
towertypes = {
	{c=2,s=2,as=90,d=1,st=120,r=1500,l=100},
	{c=10,s=3,as=60,d=5,st=0,r=2000,l=300},
	{c=12,s=4,as=50,d=1,st=0,r=1000,l=500},
	{c=8,s=5,as=30,d=15,st=0,r=1000,l=200}
}

t = class:new({
	x=0,
	y=0,
	s=0,
	twt={},-- tower type
	ce=nil,-- closest enemy
	hd=false,--hasdetected
	f=false,--fire
	l=100,--life
	control=function(_ENV)
		if hd then
			return
		end
		
		ce=enemies[1]		
	 foreach(enemies,function(e)
	 	if distance(x,y,e.x,e.y)
	 		<	distance(x,y,ce.x,ce.y) then
	 		ce=e
	 	end
	 end)
	 
	 if ce~=nil and distance(x,y,ce.x,ce.y)<twt.r then
	 	hd=true
	 	f=true
			timemanager:addtimer(twt.as,function() _ENV.hd=false end,1)
			timemanager:addtimer(10,function() _ENV.f=false end,1)
			timemanager:addtimer(1,function() ce:takedamage(twt.d,twt.st) end,1)
		end
	end,
	takedamage=function(_ENV,damage)
		l-=damage
		if l<=0 then
			destroytower(_ENV)
		end
	end,
	draw=function(_ENV)
		if l<80 then
			spr(twt.s+4,x,y)
		else
			spr(twt.s,x,y)
		end
		
		if f then
			line(x+4,y+4,ce.x+4,ce.y+4,twt.c)
		end
	end
})

function createtower(x,y,tp)
	local reftower=t:new(
		{
			x=x,
			y=y,
			twt=tp,
			l=tp.l
		}
	)
	
	add(towers,reftower)
	set_buffer(x,y,{a=true,t=reftower})
	return reftower
end

function destroytower(t)
	del(towers,t)
	set_buffer(t.x,t.y,{a=false})
end

function generateavailabletowers(ql)
	local index=1
	foreach(ql,function(i)
		add(availabletowers,
			{
				c=towertypes[index].c,
				s=towertypes[index].s,
				q=i
			}
		)
		index+=1
	end)
end

function draw_availabletowers()
	local xx,yy=0,15
	foreach(availabletowers,function(at)
		spr(at.s,xx*8,yy*8)
		print(at.q,(xx+1)*8,yy*8,7)
		xx+=2
	end)
end
-->8
-- enemies --
e = class:new({
	x=0,
	y=0,
	s=0,
	hm=false,--hasmoved
	move=false,
	dir=1,--3 up 2 down 1 left
	l=100,--life
	stun=0,
	atk=5,--attack
	spd=60,--speed
	moveleft=function(_ENV)
		if not move and not get_buffer(x-8,y).a and x>0 then
			x-=8
			move=true
			dir=1
		end
	end,
	movedown=function(_ENV)
		if not move and not get_buffer(x,y+8).a and y<112 then
			y+=8
			move=true
			dir=2
		end
	end,
	moveup=function(_ENV)
		if not move and not get_buffer(x,y-8).a and y>0 then
			y-=8
			move=true
			dir=3
		end
	end,
	attacktower=function(_ENV)
	 local t=get_buffer(x-8,y).t	
		if t~=nil then
				t:takedamage(atk)
			return
		end
		
		t=get_buffer(x,y+8).t
		if t~=nil then
			t:takedamage(atk)
			return
		end
		
		t=get_buffer(x,y-8).t	
		if t~=nil then
			t:takedamage(atk)
			return
		end
	end,
	control=function(_ENV)	
		if stun>0 then
			stun-=1
		end
	
		local lx,ly=x,y
		move=false
				
		if not hm then			
			moveleft(_ENV)
			
			if dir==3 then
				moveup(_ENV)
			elseif dir==2 then
				movedown(_ENV)
			end
						
			if rnd({false,true}) then
			 moveup(_ENV)
				movedown(_ENV)
			else
				movedown(_ENV)
				moveup(_ENV)
			end
			
			if not move then
				attacktower(_ENV)
			end
		end
		
		if move then
			set_buffer(lx,ly,{a=false})
			
			if x<7 then
				del(enemies,_ENV)
				global.life-=1
			else
			 set_buffer(x,y,{a=true})
				hm=true
				timemanager:addtimer(spd+stun,function() _ENV.hm=false end,1)
			end
		end
	end,
	takedamage=function(_ENV,damage,stn)
		l-=damage
		stun=stn
		if l<=0 then
			del(enemies,_ENV)
		end
	end,
	draw=function(_ENV)
		if l<30 then
		 spr(s+2,x,y)
		elseif l<80 then
			spr(s+1,x,y)
		else
			spr(s,x,y)
		end
	end
})

function generateenemies(ens)
	local lx,ly=16,0
	
	foreach(ens,function(e)		
		if e[5]==1 then
			for i=e[1],e[1]+e[3]-1 do
				for j=e[2],e[2]+e[4]-1 do
					createenemy1((lx+i)*8,(ly+j)*8)
				end
			end
		elseif e[5]==2 then
			for i=e[1],e[1]+e[3]-1 do
				for j=e[2],e[2]+e[4]-1 do
					createenemy2((lx+i)*8,(ly+j)*8)
				end
			end
		end
	end)
end

function createenemy1(x,y)
	add(enemies,e:new(
		{x=x,y=y,s=16,l=200,atk=5,spd=200})
	)
end

function createenemy2(x,y)
 add(enemies,e:new(
 	{x=x,y=y,s=19,l=120,atk=5,spd=120})
 )
end


-->8
-- buffer --
function create_buffer()
 for i=0,31 do
   buffer[i] = {}
   for j=0,15 do
    buffer[i][j]={a=false}
   end
 end
end

function get_buffer(x,y)
	if x<0 or y<0 then
		return {a=false}
	end
	
	return buffer[flr(x/8)][flr(y/8)]
end

function set_buffer(x,y,value)
	buffer[flr(x/8)][flr(y/8)]=value
end
-->8
-- level --
function generatelevel()
	enemies={}
	showenemies=true
	buffer={}
	towers= {}
	availabletowers = {}
	
	local level=levels[currentlevel]
 generateavailabletowers(level[1])
 create_buffer()
	generateenemies(level[2])
	life=level[3]
end

-- 0,0,1,1,1 1 topleft enemy type 1

levels={
	{
			{5,2,3,1},
			{
				{2,4,1,6,2},
				{3,4,1,6,1}
			},
			1
	},
	{
			{1,1,1,1},
			{
				{2,4,1,4,1}
			},
			2
	}
}
__gfx__
00000000660660660000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000600000060022220000aaaa0000cccc000088880000022200000aaa00000ccc0000088800000000000000000000000000000000000000000000000000
00700700000000000022220000aaaa0000cccc00008888000022220000aaaa0000cccc0000888800000000000000000000000000000000000000000000000000
000770006000000600a22a00009aa90000dccd0000f88f0000a22a00009aa90000dccd0000f88f00000000000000000000000000000000000000000000000000
0007700060000006000aa00000099000000dd000000ff000000aa00000099000000dd000000ff000000000000000000000000000000000000000000000000000
00700700000000000004400000066000000550000004400000044000000660000005500000044000000000000000000000000000000000000000000000000000
00000000600000060044440000666600005555000044440000045000000650000005500000045000000000000000000000000000000000000000000000000000
00000000660660660444444006666660055555500444444000464400006666000056550000464400000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
06666600066667000666670006666600066667000666670000000000000000000000000000000000000000000000000000000000000000000000000000000000
55665560556677705566777055665500556677705566777000000000000000000000000000000000000000000000000000000000000000000000000000000000
68668660686687602866876068668660686687602866876000000000000000000000000000000000000000000000000000000000000000000000000000000000
66664440666644402266444066666660666666602266666000000000000000000000000000000000000000000000000000000000000000000000000000000000
66554540665545406655454066556660665566606655666000000000000000000000000000000000000000000000000000000000000000000000000000000000
06664440066644400666444006666600066666000666660000000000000000000000000000000000000000000000000000000000000000000000000000000000
04004000040040000400400006006000060060000600600000000000000000000000000000000000000000000000000000000000000000000000000000000000
08800880000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
88888888000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
88888868000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
88888868000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
88888688000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
08888880000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00888800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00088000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
