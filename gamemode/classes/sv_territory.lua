--[[
	Ovias
	Copyright © Slidefuse LLC - 2012
]]--


SF.Territory = {}
SF.Territory.buffer = {}

entss = {}
concommand.Add("tt", function(ply, cmd, args)
	local tr = ply:GetEyeTraceNoCursor()
	local t = SF.Territory:AddTerritory(1, tr.HitPos, 128)
	print(t)

	for k, v in pairs(entss) do
		v:Remove()
		entss[k] = nil
	end

	/*for k, v in pairs(t.points) do
		local e = ents.Create("prop_physics")
		e:SetModel("models/roller.mdl")
		e:Spawn()
		e:SetPos(v)
		table.insert(entss, e)
		e:GetPhysicsObject():EnableMotion(false)
	end*/

	SF:Net(ply, "territoryTest", {
		org = tr.HitPos,
		points = t.points
	})

end)


local TCLASS = {}
TCLASS.__index = TCLASS

function TCLASS:Init(pos, radius)

	self.points = {}
	self.triangles = {}

	self.position = pos
	self.radius = radius

	self:Calculate()
end

function TCLASS:Calculate()

	local position = self.position + Vector(0, 0, 5)
	local zPos = position.z
	local s = (math.pi*2)/32
	local index = 1

	local skipDistance = 5

	//Loop through all our segments (32 into a 360 degree circle)
	for i = 0, math.pi*2, s do
		//Define our starting parameters
		local vOffset = Vector(math.cos(i), math.sin(i), 0)
		
		local vUp = Vector(0, 0, 1)
		local vDown = Vector(0, 0, -1)

		local org = position
		local length = 0

		//Setup our initial tracestruct
		local t = { 
			start = org,
			endpos = org + vOffset*self.radius,
		}
		local tr = util.TraceLine(t)

		local prevHit = position
		
		//Safely iterate... (Not)
		while true do
			local newHit = false
			local tt = util.TraceLine({
				start = prevHit,
				endpos = prevHit + vOffset*skipDistance
			})

			if (!tt.Hit) then
				newHit = prevHit + vOffset*skipDistance
				local dt = util.TraceLine({
					start = newHit,
					endpos = newHit + vDown*15
				})

				if (!dt.Hit) then
					print(index, "Terminated on a CLIFF")
					self.points[index] = newHit
					break;
				else
					newHit = dt.HitPos
				end
			else
				//Only check our vertical slope, above was the bottom.
				local ut = util.TraceLine({
					start = prevHit + vUp*5,
					endpos = prevHit + vUp*5 + vOffset*skipDistance
				})
		
				if (ut.Hit) then
					newHit = ut.HitPos
				else
					print(index, "Terminated on a WALL")
					self.points[index] = prevHit
					break
				end
			end

			length = length + prevHit:Distance(newHit)
			

			if (length >= self.radius) then
				print(index, "terminated proper bast")
				self.points[index] = prevHit
				//Find Ground
				local lt = util.TraceLine({
					start = prevHit,
					endpos = prevHit - Vector(0, 0, 100)
				})
				break
			end

			prevHit = newHit
		end
		index = index + 1
	end

end


function SF.Territory:AddTerritory(team, pos, radius)

	local o = table.Copy(TCLASS)
	setmetatable(o, TCLASS)
	o:Init(pos, radius)
	//o:SetTeam(team)
	
	return o

end


SF:RegisterClass("svTerritory", SF.Territory)