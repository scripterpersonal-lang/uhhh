local Ps = game:GetService("PathfindingService")
local Tags = game:GetService("CollectionService")

------------------ Settings ------------------
local WalkCost = 0.25
local MaxWalkDistance = 100
local animal = script.Parent
local human = animal:WaitForChild("Humanoid")
local root = animal:WaitForChild("HumanoidRootPart")
local body = animal:WaitForChild("Body")
local sight = root:WaitForChild("Sight")
local interact = root:WaitForChild("Interact")

--------------- Found Items ----------------------
local founditems = {["Food"] = {}, ["Water"] = {}}
function founditems:Has(Item:BasePart)
if not Item:IsDescendantOf(workspace) then return false end
if table.find(founditems.Food, Item) then
return Item, "Food"
elseif table.find(founditems.Water, Item) then
return Item, "Water"
end
end

function founditems:Remove(Item:BasePart)
if table.find(founditems.Food, Item) then
table.remove(founditems.Food, table.find(founditems.Food, Item))
elseif table.find(founditems.Water, Item) then
table.remove(founditems.Water, table.find(founditems.Water, Item))
end
end

function founditems:Add(Item:BasePart)
if Item:HasTag("Food") then
table.insert(founditems.Food, Item)
elseif Item:HasTag("Water") then
table.insert(founditems.Water, Item)
end
local highlihgt = Instance.new("Highlight")
highlihgt.Parent = Item
highlihgt.FillTransparency = 0.75
highlihgt.FillColor = Color3.new(1, 0.917647, 0)
highlihgt.OutlineColor = Color3.new(0.00784314, 0.478431, 0)
highlihgt.DepthMode = Enum.HighlightDepthMode.Occluded
end

function founditems:Clear()
for i, v in pairs(founditems.Food) do
founditems:Remove(v)
end
for i, v in pairs(founditems.Water) do
founditems:Remove(v)
end
end

function founditems:FindClosest(Category)
local object = nil
local distance = math.huge
for i, v:BasePart in pairs(founditems[Category]) do
local currentdistance = (root.Position - v.Position).Magnitude
if currentdistance <= distance then
distance = currentdistance
object = v
end
end
if object then
return object
end
end
local function search()
local searchterms = OverlapParams.new()
searchterms.FilterType = Enum.RaycastFilterType.Include
searchterms.FilterDescendantsInstances = {
Tags:GetTagged("Food"),
Tags:GetTagged("Water")}
for i, basepart in pairs(workspace:GetPartsInPart(sight, searchterms)) do
if founditems:Has(basepart) or basepart:IsDescendantOf(animal) then continue end

	if basepart:HasTag("Food") then
		founditems:Add(basepart)
	elseif basepart:HasTag("Water") then
		founditems:Add(basepart)
	end
end

for i, v:BasePart in pairs(founditems.Food) do
	if not v:IsDescendantOf(workspace) then
		founditems:Remove(v)
	end
end

for i, v:BasePart in pairs(founditems.Water) do
	if not v:IsDescendantOf(workspace) then
		founditems:Remove(v)
	end
end
end

-- Thirst, Hunger, Health
local function attribute(name:string, set:boolean, value:number)
if set then
animal:SetAttribute(name, value)
else
return animal:GetAttribute(name)
end
end

local function walkto(destination:Vector3)
while (root.Position - destination).Magnitude > 8 do
local path = Ps:CreatePath({AgentCanJump = true, AgentCanClimb = true, WaypointSpacing = 3})
path:ComputeAsync(root.Position, destination)

	local currentpoint:PathWaypoint = path:GetWaypoints()[3]
	local nextwaypoint:PathWaypoint = path:GetWaypoints()[2]

	attribute("Hunger", true, attribute("Hunger") - 0.06)
	attribute("Thirst", true, attribute("Thirst") - 0.06)
	
	human:Move((nextwaypoint.Position - root.Position).Unit)
	if currentpoint.Action == Enum.PathWaypointAction.Jump then
		human.Jump = true
	end
end
human:Move(Vector3.zero)
end

local function wander()
local pos = root.Position + Vector3.new(
math.random(-MaxWalkDistance, MaxWalkDistance),
0,
math.random(-MaxWalkDistance, MaxWalkDistance)
)

local cast = workspace:Raycast(pos, Vector3.yAxis*-1000)
if cast and cast.Instance then
	return walkto(pos)
end
end

-- Multiuse
local function carry(tag)
local include = OverlapParams.new()
include.FilterType = Enum.RaycastFilterType.Include
include.FilterDescendantsInstances = {Tags:GetTagged(attribute(tag))}

local partsinsight = workspace:GetPartsInPart(sight, include)
local foodpart = nil
if #founditems.Food > 0 then
	foodpart = founditems:FindClosest("Food")
elseif #partsinsight > 0 then
	foodpart = partsinsight[1]
end

if foodpart then
	walkto(foodpart.Position)
	
	local interactparts = workspace:GetPartsInPart(interact, include)
	if #interactparts > 0 then
		local food = interactparts[1]
		local objectHold:ObjectValue = body:WaitForChild("Occupancy")
		if objectHold.Value == nil then
			objectHold.Value = food
			local weld = body:WaitForChild("Hold")
			weld.Enabled = false
			weld.Part1 = food
			food.Position = body.Position + Vector3.new(
				0, body.Size.Y/2 + food.Size.Y/2, 0
			)
			weld.Enabled = true
			food.CanCollide = false
			food.Anchored = false
			food.CanQuery = false
			food.Parent = animal
			founditems:Remove(food)
			return
		end
	end
end
wander()
end

local function drop()
local backslot = body:WaitForChild("Occupancy")
local food:BasePart = backslot.Value
local weld = body:WaitForChild("Hold")

weld.Part1 = nil

food.CanCollide = true
food.CanQuery = true
local front = body.CFrame.LookVector * 5
food.Position = body.Position + front
food.Parent = workspace
end

local function consume(food:BasePart, eattime)
local times = 0
while task.wait(eattime/3) do
if times == 3 then
break
end
times += 1
food.Size -= food.Size/3
end
food:Destroy()
attribute("Hunger", true, attribute("Hunger") + food:GetAttribute("Nutrition"))
end

local function eat()
local include = OverlapParams.new()
include.FilterType = Enum.RaycastFilterType.Include
include.FilterDescendantsInstances = {Tags:GetTagged(attribute("Eats"))}

local interactparts = workspace:GetPartsInPart(interact, include)
if #interactparts > 0 then
	local food = interactparts[1]
	consume(food, 5)
end
end

local function hunger()
local include = OverlapParams.new()
include.FilterType = Enum.RaycastFilterType.Include
include.FilterDescendantsInstances = {Tags:GetTagged(attribute("Eats"))}
local parts = workspace:GetPartsInPart(sight, include)

local foodpart = nil
if #founditems.Food > 0 then
	foodpart = founditems:FindClosest("Food")
elseif #parts > 0 then
	foodpart = parts[1]
else
	return wander()
end

walkto(foodpart.Position)
eat()
end

local function drink()
local include = OverlapParams.new()
include.FilterType = Enum.RaycastFilterType.Include
include.FilterDescendantsInstances = Tags:GetTagged("Water")

local interactparts = workspace:GetPartsInPart(interact, include)
if #interactparts > 0 then
	local water = interactparts[1]
	task.wait(2)
	attribute("Thirst", true, 100)
end
end

local function thirst()
local include = OverlapParams.new()
include.FilterType = Enum.RaycastFilterType.Include
include.FilterDescendantsInstances = {Tags:GetTagged("Water")}

local partsinsight = workspace:GetPartsInPart(sight, include)

local waterpart = nil
if #founditems.Water > 0 then
	waterpart = founditems:FindClosest("Water")
elseif #partsinsight > 0 then
	waterpart = partsinsight[1]
else
	return wander()
end

walkto(waterpart.Position)
drink()
end

task.spawn(function()
while task.wait(0.01) do
attribute("Hunger", true, math.clamp(attribute("Hunger") - 0.01, 0, 100))
attribute("Thirst", true, math.clamp(attribute("Thirst") - 0.01, 0, 100))

	if attribute("Hunger") == 0 then
		attribute("Health", true, math.clamp(attribute("Health") - 0.01, 0, 100))
	end
	
	if attribute("Thirst") == 0 then
		attribute("Health", true, math.clamp(attribute("Health") - 0.01, 0, 100))
	end
end
end)

local function Priority()
local states = {"Hunger", "Thirst"}
local chosenstate = {"Chilling", 100}
for i, statename in pairs(states) do
local value = attribute(statename)
local thresh = attribute("Threshhold"..statename)

	if value < thresh and value < chosenstate[2] then
		chosenstate = {statename, value}
	end
end
return chosenstate
end

local function wanderstates()
local occupied = body:WaitForChild("Occupancy").Value

if occupied == nil then
	carry("Eats")
end

wander()

if occupied == nil then
	carry("Eats")
end
end

local function choose()
local chosenstate = Priority()
local state = animal:GetAttribute("State")
local value = chosenstate[2]

local occupied = body:WaitForChild("Occupancy").Value

if state == "Chilling" then
	wanderstates()
elseif state == "Hunger" or state == "Very Hungry" then
	if value < 10 and occupied then
		drop()
		hunger()
	else
		hunger()
	end
elseif state == "Thirst" then
	thirst()
else
	wander()
end
end

--------- Forever Functions ---------
task.spawn(function()
while task.wait() do
local chosenstate = Priority()
local state = chosenstate[1]
local value = chosenstate[2]
if state == "Hunger" and value < 10 then
state = "Very Hungry"
end

	animal:SetAttribute("State", state)
end
end)

task.spawn(function()
while task.wait() do
search()
end
end)
while task.wait(1) do
choose()
end
