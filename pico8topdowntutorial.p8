pico-8 cartridge // http://www.pico-8.com
version 41
__lua__
global=_ENV
finish=false
gameover=false
gameovertmr=30

function resetgame()
	gameovertmr-=1	
	if gameovertmr<=0 then
		crrtlv-=1
		nextlv=true
		gameover=false
		gameovertmr=30
	end
end

function _init()
 menuitem(1, "restart", function() crrtlv-=1 nextlv=true end)
 menuitem(2, "next", function() nextlv=true end)
end

function _update()
	if gameover then
	 resetgame()
		return
	end
	
	if crrtlv == 25 then
	 finish=true
		return
	end
	
	if nextlv then
	 crrtlv+=1
		nextlv=false
		generatlevel()
	end
	foreach(enemies, function(e)
		e:control()
	end)
	foreach(fires, function(f)
		f:control()
	end)
	foreach(enemyfires,function(f)
		f:control()
	end)	
	p:control()
	levellogic()
end

function _draw()
	cls()
	map()
	if gameover then
		reload()
		print("you died",40,63,8)
		return
	end
	
	if finish then
		reload()
		print("congratulations",35,63,10)
		return
	end
	
	p:draw()
	foreach(enemies,function(e)
		e:draw()
	end)
	foreach(fires,function(f)
		f:draw()
	end)
	foreach(enemyfires,function(f)
		f:draw()
	end)
	print(crrtlv,120,120,2)	
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

flgmtch=function(t, fs)
  for f in all(fs) do
    if fget(t,f) then
      return true
    end
  end
  return false
end

collideflag=function(x,y,b,flags)
	 for i=x+b.x,x+b.x+b.w-1,b.w-1 do
    if flgmtch(mget(i/8,(y+b.y)/8),flags) or
         flgmtch(mget(i/8,(y+b.y+b.h-1)/8),flags) then
          return true
    end
  end
  for i=y+b.y,y+b.y+b.h-1,b.h-1 do
    if flgmtch(mget((x+b.x)/8,i/8),flags) or
         flgmtch(mget((x+b.x+b.w-1)/8,i/8),flags) then
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

--dinamic reference values needs to set everytime
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
ptnf=25--potion full
ptntmr=0--potion stop time

function outsidemap(o)
	return o.x>121 or o.y>121 or o.x<7 or o.y<7
end

function getptnsprt()
	local ptnsprt=20+flr(p.potion*0.5)
	return ptnsprt>ptnf and ptnf or ptnsprt
end

function getxy()
  local a,b,dir=p.x,p.y,butarr[btn()&0b1111]
  if lastdir!=dir and dir>=5 then
	  a=flr(a)+0.5
	  b=flr(b)+0.5
	 end	 
	 if dir>0 then
	  a+=dirx[dir]*p.spd
	  b+=diry[dir]*p.spd
  end
	 lastdir=dir
	 return {x=a,y=b,dir=dir}
end

p = class:new({
	sprt=1,
	x=63,
	y=63,
	spd=1,
	potion=0,
	clde=true,--collideable
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

		if btn(5) and getptnsprt()==ptnf then
			potion=0
			sfx(2)
			global.ptntmr=35
		end
		
		if global.ptntmr>0 then
			global.ptntmr-=1
			clde=false
		else
			clde=true
		end		
			
		if collideflag(x,y,box,{5}) then
			spd=0.2
		end
		local xy=getxy()
		spd=1--reset spd
		
		if xy.dir>0 then
	  sprt=updateanimation(dirsprt[xy.dir]).sprt
	  fx=dirf[xy.dir]==1
  else
   sprt=1
  end
  
  if clde then
			foreach(enemies, function(e)
				if rects_overlap({x=xy.x,y=y,box=box},e) then cex=true	end
				if rects_overlap({x=x,y=xy.y,box=box},e) then cey=true	end
			end)
		end
		
		if cex==false and cey==false then
			cetmr=60
		else
			cetmr-=1
		end
		
		if cetmr<=0 then
			sfx(1)
			global.gameover=true
		end
		
		if outsidemap({x=xy.x,y=xy.y}) then
			return
		end
		
		if cex==false and collideflag(xy.x,y,box,{0})==false then
			x=xy.x -- no collsion in x
		end
		
		if cey==false and collideflag(x,xy.y,box,{0})==false then
			y=xy.y -- no collsion in y
		end
		
		if collideflag(x,y,box,{2}) then
			local ix,cdv=0,crlvl.dinval
			for i=1,#cdv do
			 if abs(cdv[i][1]*8-x)<1 and
			 	 abs(cdv[i][2]*8-y)<1 then
				 ix=i
				 break
			 end
			end
			
			if ix>0 then
				mset(cdv[ix][1],cdv[ix][2],0)
				mset(cdv[ix][3],cdv[ix][4],16)
			end
		end
		
		if collideflag(x,y,box,{4}) then
			local ge=global.enemyfires
			for i=1,#ge do
				if abs(ge[i].ax-x)<1 and
			 	 abs(ge[i].ay-y)<1 then
				 ge[i].inactive=false
					break
				end
			end
		end
	end,
	draw = function(_ENV)
		spr(sprt,x,y,1,1,fx,fy)
		printpotion()
	end
})

function printpotion()
 spr(getptnsprt(),0,0)
	local txt,clr=flr(ptntmr),10
		
	if ptntmr<=0 then
		txt=""
	elseif ptntmr<10 then
	 clr=8
	end
	
	print(txt,120,0,clr)	
end
-->8
-- fire --
fire = class:new({
	sprt=8,
	anmspt={},
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
		anmspt={},
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
		fov={{6,3},{3,1},{2,0}},--field of view number of sprites
		findplayer = function(_ENV)
			if global.ptntmr>0 then
				return
			end
			
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
			if global.ptntmr>0 then
				return
			end
			
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
				if collideflag(xy.x,y,box,{0}) then
					xy.x=x
				 xyc.x=x
					xy.y=y+ysd*spd
			 	xyc.y=y+ysd*2
				end
			else
			 xy.y=y+ysd*spd
			 xyc.y=y+ysd*2
			 
			 -- try to go around wall
			 if collideflag(x,xy.y,box,{0}) then
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
			
			if cex==false and collideflag(xy.x,y,box,{0,3})==false then
				x=xy.x -- no collsion in x
				didmv=true
			end
			
			if cey==false and collideflag(x,xy.y,box,{0,3})==false then
				y=xy.y -- no collsion in y
				didmv=true
			end
			
			if didmv then
				sprt=updateanimation(anmspt).sprt
			end
			
			if collideflag(x,y,box,{1}) then
				add(fires,fire:new({x=x,y=y,anmspt=anim({8,9,10,11,12},8,0.1)}))
				del(enemies,_ENV)
				sfx(0)
				p.potion+=1
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

enemyfire=class:new({
	sprt=35,
	inactive=true,
	anmspt={},
	x=0,
	y=0,
	ax=0,
	ay=0,
	box={x=2,y=2,w=6,h=6},
	control=function(_ENV)
		if inactive then
			return
		end 
		sprt=updateanimation(anmspt).sprt
		if rects_overlap({x=x,y=y,box=box},p) then 
			global.gameover=true
		end
	end,
	draw=function(_ENV)
	 if inactive then
			return
		end
		spr(sprt,x,y)
	end
})
-->8
-- levels --
function generatlevel()
	crlvl=crtlvl(levels[crrtlv])
	p.potion=0--reset potion
	fires={}
	enemies={}
	enemyfires={}
	enyhlstmr=0
	enemyeggs={}
	p.x=crlvl.p.x
	p.y=crlvl.p.y
	foreach(crlvl.enemies, function (e)
		add(enemies,enemy:new({x=e[1],y=e[2],anmspt=anim({5,6,7},5,0.2)}))
	end)
	foreach(crlvl.enemyeggs, function (e)
		add(enemyeggs,{e[1],e[2],e[3],e[4],e[5],e[6],e[7],e[8]})
	end)
	foreach(crlvl.eneyfires, function (ef)
		add(enemyfires,enemyfire:new(
				{	x=ef[3]*8,y=ef[4]*8,
					ax=ef[1]*8,ay=ef[2]*8,
					anmspt=anim({35,36,37,38,39},35,0.1)
				})
			)
	end)	
	reload()	
	crlvl.createmap()
end

function levellogic()
	if crlvl.pass() then
		nextlv=true
		return
	end
	enyhlstmr+=0.1
	if enemyeggs!=nil or
		#enemyeggs==0 then
		foreach(enemyeggs,function(e)
			if enyhlstmr>=e[7]-5 and
			 e[8]==0 then
			 e[8]=1
				gnrspr(e[1],e[2],e[3],e[4],e[5],e[6],42)
			end
			if enyhlstmr>=e[7] then
				gnrspr(e[1],e[2],e[3],e[4],e[5],e[6],0)
				local nes={}
				gnrens(e[1],e[2],e[3],e[4],e[5],e[6],nes)
				foreach(nes, function (ne)
					add(enemies,enemy:new({x=ne[1],y=ne[2],anmspt=anim({5,6,7},5,0.2)}))
				end)
				del(enemyeggs,e)
			end
		end)
	end
end

function noenemiespass()
	return #enemies == 0 and 
		#enemyeggs == 0 
end

function gnrens(i,j,w,h,k,l,ar)
	for n=0,w-1,k do
		for m=0,h-1,l do
			add(ar,{(i+n)*8+1,(j+m)*8+1})
		end
	end
end

function gnrspr(i,j,w,h,k,l,sprt)
	for n=0,w-1,k do
		for m=0,h-1,l do
			mset((i+n),(j+m),sprt)
		end
	end
end

--create level
crtlvl=function(lv)
	local lo={}
	lo.p={x=lv[1][1],y=lv[1][2]}
	local ar={}
	foreach(lv[2],function (e)		
		gnrens(e[1],e[2],e[3],e[4],e[5],e[6],ar)		
	end)
	lo.enemies=ar
	lo.eneyfires=lv[6] or {}
	lo.enemyeggs=lv[7] or {}
	lo.pass=noenemiespass
	lo.createmap=function()
		foreach(lv[3],function (b)
			mset(b[1],b[2],17)
			mset(b[1],b[2]+1,33)
			mset(b[1]+1,b[2],18)
			mset(b[1]+1,b[2]+1,34)
		end)
		
		if lv[4]==nil then return end
		
		foreach(lv[4],function (c)		
			if c[1]==0 then
				for i=c[2],c[3] do
					mset(c[4],i,16)
				end
			else
			 for i=c[2],c[3] do
					mset(i,c[4],16)
				end
			end
		end)
		
		if lv[5]!=nil then
			foreach(lv[5], function(o)
				mset(o[1],o[2],32)
				mset(o[3],o[4],19)
			end)
		end
		
		if lv[6]!=nil then
			foreach(lv[6], function(o)
				mset(o[1],o[2],40)
			end)
		end
		
		if lv[7]!=nil then
			foreach(lv[7], function(e)
				gnrspr(e[1],e[2],e[3],e[4],e[5],e[6],41)
			end)
		end
		
		if lv[8]!=nil then
			foreach(lv[8], function(o)
				gnrspr(o[1],o[2],o[3],o[4],1,1,26)
			end)
		end			
		lo.dinval=lv[5]
	end
	return lo
end

crrtlv=0
nextlv=true
levels = {
	{
		{8,8},
		{
			{3,8,3,4,1,1}
		},
		{{6,6}},
		{},
		{},
		{},
		{{4,4,2,2,1,1,40,0}}
	},{
		{8,110},
		{
		 {7,2,2,1,1,1},
			{7,1,2,7,1,3}
		},
		{{11,11},{13,11}},
		{{0,4,14,9}}
	},{
		{63,63},
		{{1,7,3,2,1,1}},
		{{11,5},{13,5}},
		{{0,5,14,5},{0,1,10,10}}
	},{
	 {8,110},
	 {{2,2,3,5,1,2}},
	 {{7,1}},
	 {
	 	{0,3,14,6}
	 }
	},{
	 {8,8},
	 {{13,1,2,6,1,1}},
	 {{13,12}},
	 {
	 	{0,1,13,2},{0,1,13,3},
	 	{0,2,14,6},{0,2,14,7},
	 	{0,1,13,11},{0,1,13,12}
	 },
	 {
	 	{2,2,3,2},{2,4,3,4},
	 	{2,6,3,6},{2,8,3,8},
	 	{2,14,3,14},{3,10,2,10}
	 },
	 {{7,1,8,8},{1,8,9,8}}
	},{
		{20,112},
		{{1,4,4,2,1,1}},
		{{1,2},{3,2}},
		{{0,1,14,5}}
	},{
	 {8,110},
	 {{2,2,3,5,1,2},
	 	{5,1,1,6,1,1}},
	 {{7,1}},
	 {
	 	{0,3,14,6}
	 }
	},{
		{40,110},
		{{1,7,2,3,1,1}},
		{{1,11}},
		{{0,2,14,3},{0,2,14,4},{0,1,14,6}},
		{{3,8,4,8}}
	},{
		{60,112},
		{{1,4,2,4,1,1},{12,4,2,3,1,1},{13,7,2,2,1,1}},
		{{1,2},{12,2}},
		{{0,1,13,3},{1,4,10,13},{0,1,13,11}},
		{{3,14,5,14}}
	},{
	 {8,110},
	 {{2,1,3,5,1,2},
	 	{2,2,2,5,1,2},
	 	{5,1,1,6,1,1}},
	 {{7,1}},
	 {
	 	{0,3,14,6}
	 }
	},{
		{8,8},
		{
			{8,1,3,8,2,1},
			{1,10,8,3,1,2}
		},
		{{10,11},{11,6},{6,13}},
		{
	 	{0,2,2,7},{1,2,2,9}
	 }
	},{
	 {8,8},
	 {{13,1,2,6,1,1}},
	 {{13,12}},
	 {
	 	{0,1,13,2},{0,2,14,4},
	 	{0,1,13,6},{0,2,14,8},
	 	{0,1,13,11},{0,1,13,12}
	 },
	 {},
	 {{4,14,11,14},{8,14,12,14}}
	},{
		{8,8},
		{
			{8,1,3,8,2,1},
			{1,10,8,3,1,2}
		},
		{{10,11},{11,6},{6,13}},
		{
	 	{0,2,4,7},{1,2,4,9}
	 }
	},{
		{8,8},
		{},
		{{10,11}},
		{},
		{},
		{},
		{{8,9,7,1,1,1,20,0},{7,9,1,6,1,1,30,0}}
	},{
	 {80,100},
	 {{12,5,2,6,1,3}},
	 {{7,8},{9,8}},
	 {{0,1,10,6},{0,6,10,11},{1,6,11,11}}
	},{
	 {8,110},
	 {{2,1,3,5,1,2},
	 	{1,2,3,5,1,2},
	 	{5,1,1,6,1,1}},
	 {{7,1}},
	 {
	 	{0,3,14,6}
	 }
	},{
	 {8,110},
	 {{1,1,3,5,1,2},
	 	{2,2,2,5,1,2},
	 	{5,1,1,6,1,1}},
	 {{7,3}},
	 {
	 	{0,1,3,6},{0,5,14,6}
	 },
	 {
	 	{1,11,1,12},{2,11,2,12},
	 	{3,11,3,12},{4,11,4,12},
	 	{5,11,5,12}
	 }
	},{
		{8,8},
		{
			{1,10,6,2,1,1},
			{8,3,7,1,1,1}
		},
		{{10,1},{2,13},{4,13}},
		{
			{0,1,12,7},
	 }
	},{
		{8,8},
		{
			{1,10,4,3,1,1},
			{8,3,7,4,1,1}
		},
		{{10,1},{5,13}},
		{
			{0,1,12,5},
			{0,1,12,6},
			{0,1,12,7},
			{1,8,14,11},
			{1,8,14,12}
	 },
	 {{11,11,11,12}}
	},{
	 {25,110},
	 {{1,1,5,5,1,2},
	 	{2,2,3,5,1,2}},
	 {{7,1}},
	 {
	 	{0,3,14,6}
	 }
	},{
	 {8,110},
	 {{1,1,5,6,1,1}},
	 {{7,1}},
	 {
	 	{0,3,14,6}
	 }
	},{
		{8,8},
		{
		 {1,6,2,1,1,1},
		 {12,10,3,1,1,1},
		},
		{{12,1}},
		{
			{0,2,9,4},{1,4,10,11},
			{0,1,11,11},{0,1,10,9},
			{0,3,9,7},{1,5,7,2},
		},
		{{5,1,4,1},{4,10,5,10}},
		{},
		{
			{1,4,2,2,1,1,60,0},
			{4,13,8,2,1,1,40,0}
		},
		{{8,3,1,6}}
	},{
		{8,16},
		{
			{10,1,3,5,1,1},
			{3,14,3,1,1,1}
		},
		{{13,7}},
		{
		 {0,1,6,2},{0,1,6,3},
			{0,6,13,12},{1,1,11,10},
			{1,4,10,6},{1,2,10,7},
			{1,2,10,8},{1,3,11,13}
		},
		{
			{2,1,3,1},{2,3,3,3},
			{3,5,2,5},{3,9,2,9},
			{11,12,12,12},{11,12,12,12}
		},
		{{12,14,10,14}}
	},{
		{8,8},
		{{6,12,7,3,1,1},{12,5,2,6,1,3}},
		{{9,8}},
		{
			{0,1,10,6},{0,6,10,11},
			{1,6,11,11},{0,1,10,8},
		}
	},{
		{63,63},
		{{1,1,1,1,1,1}}
	}	
}
__gfx__
000000000444444000000000044ff440000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000004fffff00444444004444440044ff4400000000000000000000000000000000000000000000100000000100000000000000000000000000000000000
007007000ff5f5f004fffff00f4444f0044444400000000000000000000000000000000000001000000010000001000000010000000000000000000000000000
0007700009fffff009f5f5f002ffff290f4444f0080880800808808008088080000110000001d000000d10000001d000000d1000000000000000000000000000
000770009992f277999ffff07722227702ffff29025225200252252002522520001dd100001cc100001cc100001cc100001cc100000000000000000000000000
007007007972a2777972a277777777777722227700288200002882000028820001cccc1001cccc1001cccc1001cccc1001cccc10000000000000000000000000
00000000f972a27ff972a27ff777777ff777777f0200002002000200002000200000000000000000000000000000000000000000000000000000000000000000
00000000077777700777777007777770077777700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000cccccc0000000000000000440000004400000044000000440000004400000044000500000050000000000000000000000000000000000000000
55555550000ccc0000ccc00005555550006006000060060000600600006006000060060000688600050660500000000000000000000000000000000000000000
5555555000cc0c0000c0cc0005000050006006000060060000600600006006000068860000688600005005000000000000000000000000000000000000000000
0000000000cc00c00c00cc0005055050000660000006600000066000000660000006600000066000060660600000000000000000000000000000000000000000
550550500c0c00cccc00c0c005055050006076000060760000607600006876000068760000687600060660600000000000000000000000000000000000000000
000000000c00c000000c00c005000050060007600600076006888760068887600688876006888760005005000000000000000000000000000000000000000000
505505500c00cc0cc0cc00c005555550060000600688886006888860068888600688886006888860050660500000000000000000000000000000000000000000
00000000c00c0cc00cc0c00c00000000006666000066660000666600006666000066660000666600500000050000000000000000000000000000000000000000
00000000c0c00c0000c00c0c00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
02222220cccccc0000cccccc00000000000000000008000000008000000000000999999000077000000000000000000000000000000000000000000000000000
020000200c0000cccc0000c000000000000080000000800000080000000800000900009000766300000000000000000000000000000000000000000000000000
020220200c0000c00c0000c00008800000089000000880000008800000098000090aa09003666630080880800000000000000000000000000000000000000000
0202202000c000c00c000c00008998000089a8000089a800008a9800008a9800090aa09007633660025225200000000000000000000000000000000000000000
02000020000c000cc000c000008aa80008aaaa80008aaa8008aaa80008aaaa800900009006636660062882600000000000000000000000000000000000000000
02222220000ccc0000ccc00008aaaa8008a77a8008aa7a8008a7aa8008a77a800999999003666360036663600000000000000000000000000000000000000000
0000000000000cccccc0000008a77a8008a77a8008a77a8008a77a8008a77a800000000000366600003666000000000000000000000000000000000000000000
__gff__
00000000000000000000000000000000010202080000000000002000000000000c0202000000000010010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0010101010101010101010101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
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
1010101010101010101010101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
000200001b050220502b0502e0502a050210501a050120501105015050180501e050280502c0502c0502a05027050220501b05015050100500b05008050000000000000000000000000000000000000000000000
0010000038050370503505034050320502f05029050230501c050150500e0500b0500805000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000001d7501f75024750277502975028750247501b750117500c75023300223002130020300203001e30000300043001b3001a300193001830017300153001430013300133000000000000000000000000000
001000001a7501e750277502a7502b750297502b750227501c7501875016700177001670017700177001770000000000000000000000000000000000000000000000000000000000000000000000000000000000
