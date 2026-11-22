local CONFIG = {
	Name = "SA",
	FullName = "SA HUB",
	Version = "1.2.0",
	Accent = Color3.fromRGB(46, 158, 255),
	ToggleKey = Enum.KeyCode.RightShift,
	ConfigFile = "SAHub_config.json",
	RawUrl = (getgenv and getgenv().SA_HUB_RAW) or "",
}

local UI = (function()
 local Players = game:GetService("Players")
 local UserInputService = game:GetService("UserInputService")
 local TweenService = game:GetService("TweenService")
 local HttpService = game:GetService("HttpService")
 local RunService = game:GetService("RunService")
 local LocalPlayer = Players.LocalPlayer
 local Camera = workspace.CurrentCamera

 local UI = {
 	Version = "1.2.0",
 	Theme = {
 		Accent = Color3.fromRGB(46, 158, 255),
 		Secondary = Color3.fromRGB(128, 234, 255),
 		Background = Color3.fromRGB(8, 13, 26),
 		Panel = Color3.fromRGB(13, 20, 38),
 		PanelLight = Color3.fromRGB(18, 27, 50),
 		Element = Color3.fromRGB(24, 35, 60),
 		ElementHover = Color3.fromRGB(33, 47, 78),
 		Text = Color3.fromRGB(232, 241, 255),
 		SubText = Color3.fromRGB(140, 158, 190),
 		Dim = Color3.fromRGB(92, 108, 136),
 		Green = Color3.fromRGB(52, 211, 153),
 		Red = Color3.fromRGB(248, 113, 113),
 	},
 }

 local Theme = UI.Theme

 local function new(class, props, children)
 	local inst = Instance.new(class)
 	if props then
 		for key, value in pairs(props) do
 			if key ~= "Parent" then
 				inst[key] = value
 			end
 		end
 	end
 	if children then
 		for _, child in ipairs(children) do
 			child.Parent = inst
 		end
 	end
 	if props and props.Parent then
 		inst.Parent = props.Parent
 	end
 	return inst
 end

 local function corner(inst, radius)
 	return new("UICorner", { CornerRadius = UDim.new(0, radius), Parent = inst })
 end

 local function stroke(inst, color, thickness, transparency)
 	return new("UIStroke", {
 		Color = color or Color3.fromRGB(255, 255, 255),
 		Thickness = thickness or 1,
 		Transparency = transparency or 0.88,
 		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
 		Parent = inst,
 	})
 end

 local function pad(inst, top, right, bottom, left)
 	return new("UIPadding", {
 		PaddingTop = UDim.new(0, top or 0),
 		PaddingRight = UDim.new(0, right or top or 0),
 		PaddingBottom = UDim.new(0, bottom or top or 0),
 		PaddingLeft = UDim.new(0, left or right or top or 0),
 		Parent = inst,
 	})
 end

 local function layout(inst, padding, horizontal, align)
 	return new("UIListLayout", {
 		Padding = UDim.new(0, padding or 6),
 		SortOrder = Enum.SortOrder.LayoutOrder,
 		FillDirection = horizontal and Enum.FillDirection.Horizontal or Enum.FillDirection.Vertical,
 		HorizontalAlignment = align or Enum.HorizontalAlignment.Left,
 		VerticalAlignment = Enum.VerticalAlignment.Top,
 		Parent = inst,
 	})
 end

 local function tw(inst, time, props, style, dir)
 	if not inst then
 		return nil
 	end
 	local info = TweenInfo.new(time or 0.2, style or Enum.EasingStyle.Quint, dir or Enum.EasingDirection.Out)
 	local tween = TweenService:Create(inst, info, props)
 	tween:Play()
 	return tween
 end

 local function fmtNumber(n)
 	if n % 1 == 0 then
 		return tostring(math.floor(n))
 	end
 	return string.format("%.2f", n)
 end

 UI.Util = {
 	new = new,
 	corner = corner,
 	stroke = stroke,
 	pad = pad,
 	layout = layout,
 	tween = tw,
 }

 -- 挂载点
 local guiParent
 do
 	local ok, hidden = pcall(function()
 		if gethui then
 			return gethui()
 		end
 		return nil
 	end)
 	if ok and hidden then
 		guiParent = hidden
 	else
 		guiParent = LocalPlayer:WaitForChild("PlayerGui")
 	end
 end
 UI.GuiParent = guiParent

 --==========================================================================
 -- 徽标（皇冠 + 轨道环 + 霓虹渐变字）
 --   纯 UI 原生绘制，不依赖任何图片 ID，换主题色会自动跟着变
 --==========================================================================
 local function atan2(y, x)
 	if math.atan2 then
 		return math.atan2(y, x)
 	end
 	return math.atan(y, x)
 end

 local CREST_PALETTE = {
 	bright = Color3.fromRGB(128, 234, 255),
 	core = Color3.fromRGB(46, 158, 255),
 	deep = Color3.fromRGB(16, 74, 205),
 	text = Color3.fromRGB(236, 246, 255),
 }

 function UI.LerpColor(a, b, t)
 	return Color3.new(
 		a.R + (b.R - a.R) * t,
 		a.G + (b.G - a.G) * t,
 		a.B + (b.B - a.B) * t
 	)
 end

 function UI.Crest(o)
 	o = o or {}
 	local ds = o.designSize or 240
 	local compact = (o.compact == true)
 	local cy = compact and 0.60 or 0.47
 	local pal = {
 		bright = o.bright or CREST_PALETTE.bright,
 		core = o.core or CREST_PALETTE.core,
 		deep = o.deep or CREST_PALETTE.deep,
 		text = o.textColor or CREST_PALETTE.text,
 	}

 	local root = new("Frame", {
 		Name = o.Name or "Crest",
 		AnchorPoint = Vector2.new(0.5, 0.5),
 		Position = o.position or UDim2.fromScale(0.5, 0.5),
 		Size = UDim2.fromOffset(ds, ds),
 		BackgroundTransparency = 1,
 		BorderSizePixel = 0,
 		Parent = o.parent,
 	})

 	local api = {
 		Root = root,
 		Orbits = {},
 		Glow = {},
 	}
 	local coreParts, brightParts = {}, {}
 	local letterGrad = nil
 	local spikeGrads = {}
 	local baseGrad = nil

 	-- 背面光晕
 	if not compact and o.glow ~= false then
 		for i, def in ipairs({ { 0.94, 0.978 }, { 0.70, 0.966 }, { 0.47, 0.950 } }) do
 			local size = ds * def[1]
 			local disc = new("Frame", {
 				Name = "Glow" .. i,
 				AnchorPoint = Vector2.new(0.5, 0.5),
 				Position = UDim2.new(0.5, 0, cy, 0),
 				Size = UDim2.fromOffset(size, size),
 				BackgroundColor3 = pal.core,
 				BackgroundTransparency = def[2],
 				BorderSizePixel = 0,
 				ZIndex = 1,
 				Parent = root,
 			})
 			corner(disc, size * 0.5)
 			disc:SetAttribute("Base", size)
 			table.insert(coreParts, disc)
 			table.insert(api.Glow, disc)
 		end
 	end

 	-- 轨道环（由若干短划组成，可旋转）
 	local function buildOrbit(rx, ry, tilt, count, dashW, dashH, speed, name)
 		local holder = new("Frame", {
 			Name = name or "Orbit",
 			AnchorPoint = Vector2.new(0.5, 0.5),
 			Position = UDim2.new(0.5, 0, cy, 0),
 			Size = UDim2.fromOffset(ds, ds),
 			BackgroundTransparency = 1,
 			BorderSizePixel = 0,
 			Rotation = tilt,
 			Parent = root,
 		})
 		for i = 1, count do
 			local a = (i / count) * math.pi * 2
 			local x = math.cos(a) * rx * ds
 			local y = math.sin(a) * ry * ds
 			local tangent = math.deg(atan2(ry * math.cos(a), -rx * math.sin(a)))
 			local bar = new("Frame", {
 				Name = "Dash" .. i,
 				AnchorPoint = Vector2.new(0.5, 0.5),
 				Position = UDim2.new(0.5, x, 0.5, y),
 				Size = UDim2.fromOffset(ds * dashW, ds * dashH),
 				BackgroundColor3 = pal.bright,
 				BackgroundTransparency = 0.16 + 0.62 * (1 - (0.5 - 0.5 * math.cos(a))),
 				BorderSizePixel = 0,
 				Rotation = tangent,
 				ZIndex = 1,
 				Parent = holder,
 			})
 			corner(bar, ds * dashH * 0.5)
 			table.insert(brightParts, bar)
 		end
 		table.insert(api.Orbits, { holder = holder, speed = speed })
 		return holder
 	end

 	if not compact and o.orbits ~= false then
 		buildOrbit(0.475, 0.475, 0, 22, 0.024, 0.0075, 14, "OrbitOuter")
 		buildOrbit(0.415, 0.132, -16, 14, 0.018, 0.0058, -20, "OrbitBackA")
 		buildOrbit(0.415, 0.132, 16, 14, 0.018, 0.0058, 20, "OrbitBackB")
 	end

 	-- 字：投影 / 光晕 / 主体
 	local lettersText = o.text or "SA"
 	local letterSize = compact and (ds * 0.46) or (ds * 0.38)

 	local function letterLabel(color, transparency, boost, yOffset, withStroke, name)
 		local lbl = new("TextLabel", {
 			Name = name or "Letter",
 			AnchorPoint = Vector2.new(0.5, 0.5),
 			Position = UDim2.new(0.5, 0, cy, yOffset or 0),
 			Size = UDim2.fromOffset(ds, ds * 0.82),
 			BackgroundTransparency = 1,
 			BorderSizePixel = 0,
 			Text = lettersText,
 			Font = Enum.Font.GothamBlack,
 			TextSize = letterSize + (boost or 0),
 			TextColor3 = color,
 			TextTransparency = transparency or 0,
 			TextXAlignment = Enum.TextXAlignment.Center,
 			TextYAlignment = Enum.TextYAlignment.Center,
 			TextTruncate = Enum.TextTruncate.Off,
 			ZIndex = 3,
 			Parent = root,
 		})
 		if withStroke then
 			stroke(lbl, pal.bright, 1, 0.62)
 		end
 		return lbl
 	end

 	local shadow = letterLabel(pal.deep, 0.5, 0, ds * 0.022, false, "LetterShadow")
 	shadow.ZIndex = 2
 	local halo = letterLabel(pal.core, 0.58, ds * 0.04, 0, false, "LetterHalo")
 	halo.ZIndex = 2
 	local lettersMain = letterLabel(pal.text, 0, 0, 0, true, "LetterMain")
 	lettersMain.ZIndex = 3
 	letterGrad = new("UIGradient", {
 		Color = ColorSequence.new({
 			ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
 			ColorSequenceKeypoint.new(0.55, Color3.fromRGB(244, 251, 255)),
 			ColorSequenceKeypoint.new(0.85, pal.bright),
 			ColorSequenceKeypoint.new(1, pal.core),
 		}),
 		Rotation = 100,
 		Parent = lettersMain,
 	})

 	-- 皇冠
 	local crownW = ds * (compact and 0.62 or 0.58)
 	local crownH = ds * (compact and 0.30 or 0.28)
 	local crownCY = compact and (ds * 0.15) or (ds * 0.185)
 	local crown = new("Frame", {
 		Name = "Crown",
 		AnchorPoint = Vector2.new(0.5, 0.5),
 		Position = UDim2.new(0.5, 0, 0, crownCY),
 		Size = UDim2.fromOffset(crownW, crownH),
 		BackgroundTransparency = 1,
 		BorderSizePixel = 0,
 		ZIndex = 4,
 		Parent = root,
 	})
 	api.Crown = crown

 	local spikeW = crownW * 0.115
 	local spikeDefs = { { -0.42, 0.30 }, { -0.21, 0.48 }, { 0.00, 0.66 }, { 0.21, 0.48 }, { 0.42, 0.30 } }
 	for i, def in ipairs(spikeDefs) do
 		local h = crownH * def[2]
 		local spike = new("Frame", {
 			Name = "Spike" .. i,
 			AnchorPoint = Vector2.new(0.5, 1),
 			Position = UDim2.new(0.5, crownW * def[1], 1, -crownH * 0.18),
 			Size = UDim2.fromOffset(spikeW, h),
 			BackgroundColor3 = pal.core,
 			BorderSizePixel = 0,
 			ZIndex = 1,
 			Parent = crown,
 		})
 		corner(spike, spikeW * 0.5)
 		local spikeGrad = new("UIGradient", {
 			Color = ColorSequence.new({
 				ColorSequenceKeypoint.new(0, pal.bright),
 				ColorSequenceKeypoint.new(0.58, pal.core),
 				ColorSequenceKeypoint.new(1, pal.deep),
 			}),
 			Rotation = 90,
 			Parent = spike,
 		})
 		table.insert(spikeGrads, spikeGrad)
 		table.insert(coreParts, spike)

 		local orbSize = crownW * 0.098
 		local orb = new("Frame", {
 			Name = "Orb" .. i,
 			AnchorPoint = Vector2.new(0.5, 0.5),
 			Position = UDim2.new(0.5, crownW * def[1], 1, -(crownH * 0.18 + h)),
 			Size = UDim2.fromOffset(orbSize, orbSize),
 			BackgroundColor3 = pal.bright,
 			BorderSizePixel = 0,
 			ZIndex = 3,
 			Parent = crown,
 		})
 		corner(orb, orbSize * 0.5)
 		stroke(orb, pal.bright, 1, 0.35)
 		table.insert(brightParts, orb)
 	end

 	local crownBase = new("Frame", {
 		Name = "CrownBase",
 		AnchorPoint = Vector2.new(0.5, 1),
 		Position = UDim2.new(0.5, 0, 1, 0),
 		Size = UDim2.fromOffset(crownW * 0.94, crownH * 0.21),
 		BackgroundColor3 = pal.core,
 		BorderSizePixel = 0,
 		ZIndex = 2,
 		Parent = crown,
 	})
 	corner(crownBase, crownH * 0.07)
 	baseGrad = new("UIGradient", {
 		Color = ColorSequence.new({
 			ColorSequenceKeypoint.new(0, pal.bright),
 			ColorSequenceKeypoint.new(0.5, pal.core),
 			ColorSequenceKeypoint.new(1, pal.deep),
 		}),
 		Rotation = 0,
 		Parent = crownBase,
 	})
 	stroke(crownBase, pal.bright, 1, 0.5)
 	table.insert(coreParts, crownBase)

 	-- 副标题
 	if not compact and o.hub ~= false then
 		local hub = new("TextLabel", {
 			Name = "HubText",
 			AnchorPoint = Vector2.new(0.5, 0.5),
 			Position = UDim2.new(0.5, 0, 0.735, 0),
 			Size = UDim2.fromOffset(ds, ds * 0.2),
 			BackgroundTransparency = 1,
 			BorderSizePixel = 0,
 			Text = o.hubText or "Hub",
 			Font = Enum.Font.GothamBlack,
 			TextSize = ds * 0.16,
 			TextColor3 = Color3.fromRGB(255, 255, 255),
 			TextXAlignment = Enum.TextXAlignment.Center,
 			TextYAlignment = Enum.TextYAlignment.Center,
 			ZIndex = 3,
 			Parent = root,
 		})
 		new("UIGradient", {
 			Color = ColorSequence.new({
 				ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
 				ColorSequenceKeypoint.new(0.5, Color3.fromRGB(226, 240, 255)),
 				ColorSequenceKeypoint.new(1, Color3.fromRGB(150, 196, 240)),
 			}),
 			Rotation = 90,
 			Parent = hub,
 		})
 		stroke(hub, pal.deep, 1, 0.55)
 		api.Hub = hub
 	end

 	-- 透明度控制
 	local faders = {}
 	for _, d in ipairs(root:GetDescendants()) do
 		if d:IsA("TextLabel") then
 			table.insert(faders, { inst = d, prop = "TextTransparency", base = d.TextTransparency or 0 })
 		elseif d:IsA("Frame") then
 			table.insert(faders, { inst = d, prop = "BackgroundTransparency", base = d.BackgroundTransparency or 0 })
 		elseif d:IsA("UIStroke") then
 			table.insert(faders, { inst = d, prop = "Transparency", base = d.Transparency or 0 })
 		end
 	end

 	function api:SetOpacity(a)
 		local t = math.clamp(a or 1, 0, 1)
 		local inv = 1 - t
 		for _, item in ipairs(faders) do
 			if item.inst.Parent then
 				item.inst[item.prop] = item.base + (1 - item.base) * inv
 			end
 		end
 	end

 	local opacityValue = new("NumberValue", { Value = 1 })
 	opacityValue.Changed:Connect(function(v)
 		api:SetOpacity(v)
 	end)
 	function api:FadeTo(a, time, style, dir)
 		local tween = TweenService:Create(
 			opacityValue,
 			TweenInfo.new(time or 0.3, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out),
 			{ Value = a }
 		)
 		tween:Play()
 		return tween
 	end

 	local spinning = false
 	function api:StartSpin()
 		if spinning or #api.Orbits == 0 then
 			return
 		end
 		spinning = true
 		task.spawn(function()
 			while spinning do
 				local dt = task.wait(0.03)
 				for _, orbit in ipairs(api.Orbits) do
 					if orbit.holder.Parent then
 						orbit.holder.Rotation = orbit.holder.Rotation + orbit.speed * dt
 					end
 				end
 			end
 		end)
 	end

 	local pulsing = false
 	function api:StartPulse()
 		if pulsing or #api.Glow == 0 then
 			return
 		end
 		pulsing = true
 		task.spawn(function()
 			local t = 0
 			while pulsing do
 				t = t + 0.05
 				local s = 1 + math.sin(t) * 0.035
 				for _, disc in ipairs(api.Glow) do
 					if disc.Parent then
 						local base = disc:GetAttribute("Base") or disc.Size.X.Offset
 						disc.Size = UDim2.fromOffset(base * s, base * s)
 					end
 				end
 				task.wait(0.05)
 			end
 		end)
 	end

 	function api:Stop()
 		spinning = false
 		pulsing = false
 	end

 	function api:SetAccent(color)
 		local bright = UI.LerpColor(color, Color3.fromRGB(255, 255, 255), 0.55)
 		local deep = UI.LerpColor(color, Color3.fromRGB(0, 0, 0), 0.42)
 		pal.core, pal.bright, pal.deep = color, bright, deep
 		for _, inst in ipairs(coreParts) do
 			if inst.Parent then
 				inst.BackgroundColor3 = color
 			end
 		end
 		for _, inst in ipairs(brightParts) do
 			if inst.Parent then
 				inst.BackgroundColor3 = bright
 			end
 		end
 		if letterGrad.Parent then
 			letterGrad.Color = ColorSequence.new({
 				ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
 				ColorSequenceKeypoint.new(0.42, bright),
 				ColorSequenceKeypoint.new(1, color),
 			})
 		end
 		if baseGrad.Parent then
 			baseGrad.Color = ColorSequence.new({
 				ColorSequenceKeypoint.new(0, bright),
 				ColorSequenceKeypoint.new(0.5, color),
 				ColorSequenceKeypoint.new(1, deep),
 			})
 		end
 		for _, g in ipairs(spikeGrads) do
 			if g.Parent then
 				g.Color = ColorSequence.new({
 					ColorSequenceKeypoint.new(0, bright),
 					ColorSequenceKeypoint.new(0.58, color),
 					ColorSequenceKeypoint.new(1, deep),
 				})
 			end
 		end
 		halo.TextColor3 = color
 		shadow.TextColor3 = deep
 	end

 	return api
 end

 --==========================================================================
 -- 启动动画
 --==========================================================================
 function UI.Splash(o)
 	o = o or {}
 	local accent = o.accent or Theme.Accent
 	local shortName = o.name or "SA"
 	local fullName = o.fullName or (shortName .. " HUB")
 	local version = o.version or "1.0.0"
 	local minTime = o.minTime or 2.2

 	local screen = new("ScreenGui", {
 		Name = "SAHubSplash",
 		IgnoreGuiInset = true,
 		DisplayOrder = 9999,
 		ResetOnSpawn = false,
 		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
 		Parent = o.parent or guiParent,
 	})

 	local backdrop = new("Frame", {
 		Size = UDim2.fromScale(1, 1),
 		BackgroundColor3 = Color3.fromRGB(4, 8, 18),
 		BackgroundTransparency = 1,
 		BorderSizePixel = 0,
 		Parent = screen,
 	})

 	local vignette = new("Frame", {
 		Size = UDim2.fromScale(1, 1),
 		BackgroundColor3 = Color3.fromRGB(0, 0, 0),
 		BackgroundTransparency = 1,
 		BorderSizePixel = 0,
 		Parent = backdrop,
 	})
 	new("UIGradient", {
 		Rotation = 90,
 		Transparency = NumberSequence.new({
 			NumberSequenceKeypoint.new(0, 0.55),
 			NumberSequenceKeypoint.new(0.45, 1),
 			NumberSequenceKeypoint.new(1, 0.35),
 		}),
 		Parent = vignette,
 	})

 	local viewportY = 720
 	pcall(function()
 		viewportY = Camera.ViewportSize.Y
 	end)
 	local vscale = math.clamp(viewportY / 880, 0.68, 1.1)
 	local crestSize = 236 * vscale

 	local center = new("Frame", {
 		AnchorPoint = Vector2.new(0.5, 0.5),
 		Position = UDim2.fromScale(0.5, 0.5),
 		Size = UDim2.fromOffset(420, 470),
 		BackgroundTransparency = 1,
 		Parent = backdrop,
 	})

 	local crest = UI.Crest({
 		parent = center,
 		designSize = crestSize,
 		position = UDim2.new(0.5, 0, 0.5, -crestSize * 0.30),
 		text = shortName,
 		hubText = o.hubText or "Hub",
 	})

 	local tagline = new("TextLabel", {
 		AnchorPoint = Vector2.new(0.5, 0.5),
 		Position = UDim2.new(0.5, 0, 0.5, crestSize * 0.28),
 		Size = UDim2.fromOffset(340, 16),
 		BackgroundTransparency = 1,
 		Text = string.upper(fullName) .. "  ·  V" .. version,
 		Font = Enum.Font.GothamMedium,
 		TextSize = 9,
 		TextColor3 = Theme.SubText,
 		TextTransparency = 1,
 		Parent = center,
 	})

 	local barTrack = new("Frame", {
 		AnchorPoint = Vector2.new(0.5, 0.5),
 		Position = UDim2.new(0.5, 0, 0.5, crestSize * 0.42),
 		Size = UDim2.fromOffset(230, 3),
 		BackgroundColor3 = Color3.fromRGB(45, 50, 68),
 		BackgroundTransparency = 1,
 		BorderSizePixel = 0,
 		Parent = center,
 	})
 	corner(barTrack, 2)

 	local barFill = new("Frame", {
 		Size = UDim2.fromScale(0, 1),
 		BackgroundColor3 = accent,
 		BorderSizePixel = 0,
 		Parent = barTrack,
 	})
 	corner(barFill, 2)
 	new("UIGradient", {
 		Color = ColorSequence.new({
 			ColorSequenceKeypoint.new(0, accent),
 			ColorSequenceKeypoint.new(1, Theme.Secondary),
 		}),
 		Parent = barFill,
 	})

 	local barGlow = new("Frame", {
 		AnchorPoint = Vector2.new(0.5, 0.5),
 		Position = UDim2.new(1, 0, 0.5, 0),
 		Size = UDim2.fromOffset(12, 12),
 		BackgroundColor3 = Theme.Secondary,
 		BackgroundTransparency = 0.4,
 		BorderSizePixel = 0,
 		Parent = barFill,
 	})
 	corner(barGlow, 6)

 	local status = new("TextLabel", {
 		AnchorPoint = Vector2.new(0.5, 0.5),
 		Position = UDim2.new(0.5, 0, 0.5, crestSize * 0.52),
 		Size = UDim2.fromOffset(340, 16),
 		BackgroundTransparency = 1,
 		Text = "",
 		Font = Enum.Font.Gotham,
 		TextSize = 10,
 		TextColor3 = Theme.SubText,
 		TextTransparency = 1,
 		Parent = center,
 	})

 	local percent = new("TextLabel", {
 		AnchorPoint = Vector2.new(0.5, 0.5),
 		Position = UDim2.new(0.5, 0, 0.5, crestSize * 0.60),
 		Size = UDim2.fromOffset(340, 14),
 		BackgroundTransparency = 1,
 		Text = "0%",
 		Font = Enum.Font.GothamBold,
 		TextSize = 10,
 		TextColor3 = Theme.Dim,
 		TextTransparency = 1,
 		Parent = center,
 	})

 	local flash = new("Frame", {
 		Size = UDim2.fromScale(1, 1),
 		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
 		BackgroundTransparency = 1,
 		BorderSizePixel = 0,
 		Parent = screen,
 	})

 	tw(backdrop, 0.5, { BackgroundTransparency = 0 })
 	tw(tagline, 0.7, { TextTransparency = 0.25 })
 	tw(barTrack, 0.5, { BackgroundTransparency = 0.15 })
 	tw(status, 0.6, { TextTransparency = 0.2 })
 	tw(percent, 0.6, { TextTransparency = 0.4 })

 	-- 徽标：整体淡入 + 皇冠下落 + 轨道环旋转 + 光晕呼吸
 	crest:SetOpacity(0)
 	crest:FadeTo(1, 0.55, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
 	crest:StartSpin()
 	crest:StartPulse()

 	local crownBasePos = crest.Crown.Position
 	crest.Crown.Position = UDim2.new(crownBasePos.X.Scale, crownBasePos.X.Offset, crownBasePos.Y.Scale, crownBasePos.Y.Offset - crestSize * 0.12)
 	task.delay(0.12, function()
 		if crest.Crown.Parent then
 			tw(crest.Crown, 0.7, { Position = crownBasePos }, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
 		end
 	end)

 	local statusLines = {
 		{ 0.00, "正在初始化核心…" },
 		{ 0.22, "正在载入界面引擎…" },
 		{ 0.48, "正在构建组件…" },
 		{ 0.70, "正在注册功能模块…" },
 		{ 0.88, "正在校验资源…" },
 		{ 0.97, "即将就绪…" },
 	}

 	local progress = 0
 	local ready = false
 	local finished = false
 	local startedAt = os.clock()
 	local revealFn = nil

 	local function currentStatus(p)
 		local text = statusLines[1][2]
 		for _, entry in ipairs(statusLines) do
 			if p >= entry[1] then
 				text = entry[2]
 			end
 		end
 		return text
 	end

 	local function doFinish()
 		if finished then
 			return
 		end
 		finished = true
 		if barFill.Parent then
 			tw(barFill, 0.22, { Size = UDim2.fromScale(1, 1) })
 			percent.Text = "100%"
 			status.Text = "启动完成"
 			tw(status, 0.15, { TextTransparency = 0 })
 		end
 		tw(flash, 0.14, { BackgroundTransparency = 0.55 })
 		task.wait(0.16)
 		tw(flash, 0.3, { BackgroundTransparency = 1 })
 		crest:FadeTo(0, 0.3)
 		tw(tagline, 0.25, { TextTransparency = 1 })
 		tw(status, 0.25, { TextTransparency = 1 })
 		tw(percent, 0.25, { TextTransparency = 1 })
 		tw(barTrack, 0.25, { BackgroundTransparency = 1 })
 		tw(barFill, 0.25, { BackgroundTransparency = 1 })
 		tw(backdrop, 0.45, { BackgroundTransparency = 1 })
 		task.wait(0.45)
 		screen:Destroy()
 		if revealFn then
 			pcall(revealFn)
 		end
 	end

 	task.spawn(function()
 		while not finished do
 			local elapsed = os.clock() - startedAt
 			local target = ready and 1 or 0.94
 			progress = progress + ((target - progress) * 0.035) + 0.0025
 			if progress > target then
 				progress = target
 			end
 			if barFill.Parent then
 				barFill.Size = UDim2.fromScale(progress, 1)
 				percent.Text = tostring(math.floor(progress * 100)) .. "%"
 				status.Text = currentStatus(progress)
 			end
 			if progress >= 0.995 and (ready or elapsed >= minTime) then
 				doFinish()
 				break
 			end
 			task.wait(0.02)
 		end
 	end)

 	task.delay(minTime, function()
 		if not finished then
 			ready = true
 		end
 	end)

 	local skipBtn = new("TextButton", {
 		Size = UDim2.fromScale(1, 1),
 		BackgroundTransparency = 1,
 		Text = "",
 		AutoButtonColor = false,
 		Parent = backdrop,
 	})
 	skipBtn.MouseButton1Click:Connect(function()
 		if not finished then
 			ready = true
 			progress = math.max(progress, 0.9)
 		end
 	end)

 	local splash = {}
 	function splash:Finish(callback)
 		revealFn = callback
 		ready = true
 		progress = math.max(progress, 0.9)
 	end
 	function splash:IsFinished()
 		return finished
 	end
 	function splash:Destroy()
 		finished = true
 		if crest then
 			crest:Stop()
 		end
 		if screen then
 			screen:Destroy()
 		end
 	end
 	return splash
 end

 --==========================================================================
 -- 窗口
 --==========================================================================
 local WindowProto = {}
 local TabProto = {}
 local SectionProto = {}
 WindowProto.__index = WindowProto
 TabProto.__index = TabProto
 SectionProto.__index = SectionProto

 function UI.Window(o)
 	o = o or {}
 	local self = setmetatable({}, WindowProto)
 	self.Tabs = {}
 	self.Elements = {}
 	self.Sections = {}
 	self.AccentAppliers = {}
 	self.ConfigEntries = {}
 	self.Flags = o.Flags or {}
 	self.ActiveTab = nil
 	self.Popup = nil
 	self.ToggleKey = o.toggleKey or Enum.KeyCode.RightShift
 	self.ConfigFile = o.configFile or "SAHub_config.json"

 	local title = o.title or "SA HUB"
 	local subtitle = o.subtitle or ("v" .. UI.Version)
 	local useWatermark = (o.watermark ~= false)
 	local useFloat = (o.floatButton ~= false)

 	local parent = o.parent or guiParent
 	local old = parent:FindFirstChild("SAHubUI")
 	if old then
 		old:Destroy()
 	end

 	local screen = new("ScreenGui", {
 		Name = "SAHubUI",
 		IgnoreGuiInset = true,
 		ResetOnSpawn = false,
 		DisplayOrder = 800,
 		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
 		Parent = parent,
 	})
 	self.Screen = screen

 	local root = new("Frame", {
 		Name = "Root",
 		AnchorPoint = Vector2.new(0.5, 0.5),
 		Position = UDim2.fromScale(0.5, 0.5),
 		Size = UDim2.fromOffset(660, 430),
 		BackgroundTransparency = 1,
 		Visible = false,
 		Parent = screen,
 	})
 	self.Root = root

 	local uiScale = new("UIScale", { Scale = 1, Parent = root })
 	self.UIScale = uiScale

 	for i = 1, 3 do
 		local shadow = new("Frame", {
 			AnchorPoint = Vector2.new(0.5, 0.5),
 			Position = UDim2.new(0.5, 0, 0.5, 6),
 			Size = UDim2.new(1, i * 8, 1, i * 8),
 			BackgroundColor3 = Color3.fromRGB(0, 0, 0),
 			BackgroundTransparency = 0.82 + (i * 0.045),
 			BorderSizePixel = 0,
 			Parent = root,
 		})
 		corner(shadow, 16 + i * 3)
 	end

 	local main = new("Frame", {
 		Name = "Main",
 		Size = UDim2.fromScale(1, 1),
 		BackgroundColor3 = Theme.Background,
 		BackgroundTransparency = 0.03,
 		BorderSizePixel = 0,
 		ClipsDescendants = true,
 		Parent = root,
 	})
 	corner(main, 14)
 	stroke(main, Color3.fromRGB(255, 255, 255), 1, 0.9)
 	self.Main = main

 	-- 顶栏
 	local topbar = new("Frame", {
 		Name = "TopBar",
 		Size = UDim2.new(1, 0, 0, 52),
 		BackgroundTransparency = 1,
 		Parent = main,
 	})

 	local topCrest = UI.Crest({
 		parent = topbar,
 		designSize = 34,
 		compact = true,
 		text = string.sub(title, 1, 2),
 		position = UDim2.new(0, 19, 0.5, 0),
 	})
 	topCrest:SetAccent(Theme.Accent)
 	self.TopCrest = topCrest
 	self:OnAccent(function(c)
 		topCrest:SetAccent(c)
 	end)

 	new("TextLabel", {
 		Size = UDim2.fromOffset(170, 18),
 		Position = UDim2.new(0, 50, 0.5, -14),
 		BackgroundTransparency = 1,
 		Text = title,
 		TextXAlignment = Enum.TextXAlignment.Left,
 		TextTruncate = Enum.TextTruncate.AtEnd,
 		Font = Enum.Font.GothamBold,
 		TextSize = 13,
 		TextColor3 = Theme.Text,
 		Parent = topbar,
 	})

 	local verTag = new("Frame", {
 		Size = UDim2.fromOffset(44, 16),
 		Position = UDim2.new(0, 50, 0.5, 4),
 		BackgroundColor3 = Theme.Element,
 		BackgroundTransparency = 0.25,
 		BorderSizePixel = 0,
 		Parent = topbar,
 	})
 	corner(verTag, 5)
 	new("TextLabel", {
 		Size = UDim2.fromScale(1, 1),
 		BackgroundTransparency = 1,
 		Text = subtitle,
 		TextTruncate = Enum.TextTruncate.AtEnd,
 		Font = Enum.Font.GothamBold,
 		TextSize = 9,
 		TextColor3 = Theme.SubText,
 		Parent = verTag,
 	})

 	-- 搜索
 	local searchBox = new("Frame", {
 		Size = UDim2.fromOffset(140, 26),
 		Position = UDim2.new(1, -184, 0.5, -13),
 		BackgroundColor3 = Theme.Element,
 		BackgroundTransparency = 0.35,
 		BorderSizePixel = 0,
 		Parent = topbar,
 	})
 	corner(searchBox, 8)
 	local searchStroke = stroke(searchBox, Theme.Accent, 1, 1)
 	new("TextLabel", {
 		Size = UDim2.fromOffset(14, 14),
 		Position = UDim2.new(0, 8, 0.5, -7),
 		BackgroundTransparency = 1,
 		Text = "⌕",
 		Font = Enum.Font.GothamBold,
 		TextSize = 13,
 		TextColor3 = Theme.Dim,
 		Parent = searchBox,
 	})
 	local searchInput = new("TextBox", {
 		Size = UDim2.new(1, -30, 1, 0),
 		Position = UDim2.new(0, 26, 0, 0),
 		BackgroundTransparency = 1,
 		Text = "",
 		PlaceholderText = "搜索功能…",
 		PlaceholderColor3 = Theme.Dim,
 		Font = Enum.Font.GothamMedium,
 		TextSize = 11,
 		TextColor3 = Theme.Text,
 		TextXAlignment = Enum.TextXAlignment.Left,
 		ClearTextOnFocus = false,
 		Parent = searchBox,
 	})
 	searchBox.InputBegan:Connect(function(input)
 		if input.UserInputType == Enum.UserInputType.MouseButton1 then
 			searchInput:CaptureFocus()
 		end
 	end)
 	searchInput.Focused:Connect(function()
 		tw(searchStroke, 0.15, { Transparency = 0.4 })
 	end)
 	searchInput.FocusLost:Connect(function()
 		tw(searchStroke, 0.15, { Transparency = 1 })
 	end)
 	searchInput:GetPropertyChangedSignal("Text"):Connect(function()
 		self:Filter(searchInput.Text)
 	end)

 	local function topButton(text, offsetX, color)
 		local btn = new("TextButton", {
 			Size = UDim2.fromOffset(24, 24),
 			Position = UDim2.new(1, offsetX, 0.5, -12),
 			BackgroundColor3 = Theme.Element,
 			BackgroundTransparency = 0.4,
 			Text = text,
 			Font = Enum.Font.GothamBold,
 			TextSize = 14,
 			TextColor3 = color or Theme.SubText,
 			AutoButtonColor = false,
 			Parent = topbar,
 		})
 		corner(btn, 7)
 		btn.MouseEnter:Connect(function()
 			tw(btn, 0.15, { BackgroundTransparency = 0.1, TextColor3 = Theme.Text })
 		end)
 		btn.MouseLeave:Connect(function()
 			tw(btn, 0.15, { BackgroundTransparency = 0.4, TextColor3 = color or Theme.SubText })
 		end)
 		return btn
 	end

 	local minBtn = topButton("–", -60)
 	local closeBtn = topButton("×", -32, Theme.Red)

 	new("Frame", {
 		Size = UDim2.new(1, 0, 0, 1),
 		Position = UDim2.new(0, 0, 0, 52),
 		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
 		BackgroundTransparency = 0.93,
 		BorderSizePixel = 0,
 		Parent = main,
 	})

 	-- 侧边栏
 	local sidebar = new("Frame", {
 		Position = UDim2.new(0, 0, 0, 53),
 		Size = UDim2.new(0, 154, 1, -53),
 		BackgroundColor3 = Theme.Panel,
 		BackgroundTransparency = 0.45,
 		BorderSizePixel = 0,
 		Parent = main,
 	})

 	local tabHolder = new("Frame", {
 		Size = UDim2.new(1, 0, 1, -76),
 		BackgroundTransparency = 1,
 		Parent = sidebar,
 	})
 	layout(tabHolder, 5)
 	pad(tabHolder, 10, 10, 0, 10)
 	self.TabHolder = tabHolder

 	local userCard = new("Frame", {
 		AnchorPoint = Vector2.new(0, 1),
 		Position = UDim2.new(0, 10, 1, -10),
 		Size = UDim2.new(1, -20, 0, 54),
 		BackgroundColor3 = Theme.Element,
 		BackgroundTransparency = 0.4,
 		BorderSizePixel = 0,
 		Parent = sidebar,
 	})
 	corner(userCard, 9)

 	local avatar = new("Frame", {
 		Size = UDim2.fromOffset(26, 26),
 		Position = UDim2.new(0, 9, 0, 8),
 		BackgroundColor3 = Theme.Accent,
 		BackgroundTransparency = 0.15,
 		BorderSizePixel = 0,
 		Parent = userCard,
 	})
 	corner(avatar, 13)
 	self:OnAccent(function(c)
 		avatar.BackgroundColor3 = c
 	end)

 	new("TextLabel", {
 		Size = UDim2.fromScale(1, 1),
 		BackgroundTransparency = 1,
 		Text = string.upper(string.sub(LocalPlayer.Name, 1, 1)),
 		Font = Enum.Font.GothamBold,
 		TextSize = 12,
 		TextColor3 = Theme.Text,
 		Parent = avatar,
 	})

 	new("TextLabel", {
 		Size = UDim2.new(1, -44, 0, 14),
 		Position = UDim2.new(0, 42, 0, 8),
 		BackgroundTransparency = 1,
 		Text = LocalPlayer.DisplayName or LocalPlayer.Name,
 		TextXAlignment = Enum.TextXAlignment.Left,
 		TextTruncate = Enum.TextTruncate.AtEnd,
 		Font = Enum.Font.GothamBold,
 		TextSize = 11,
 		TextColor3 = Theme.Text,
 		Parent = userCard,
 	})

 	local executorName = "Unknown"
 	do
 		local ok, name = pcall(function()
 			if identifyexecutor then
 				return identifyexecutor()
 			end
 			return nil
 		end)
 		if ok and type(name) == "string" then
 			executorName = name
 		end
 	end
 	new("TextLabel", {
 		Size = UDim2.new(1, -44, 0, 12),
 		Position = UDim2.new(0, 42, 0, 24),
 		BackgroundTransparency = 1,
 		Text = executorName,
 		TextXAlignment = Enum.TextXAlignment.Left,
 		TextTruncate = Enum.TextTruncate.AtEnd,
 		Font = Enum.Font.Gotham,
 		TextSize = 9,
 		TextColor3 = Theme.Dim,
 		Parent = userCard,
 	})

 	local statusDot = new("Frame", {
 		Size = UDim2.fromOffset(6, 6),
 		Position = UDim2.new(1, -14, 0, 30),
 		BackgroundColor3 = Theme.Green,
 		BorderSizePixel = 0,
 		Parent = userCard,
 	})
 	corner(statusDot, 3)

 	local content = new("Frame", {
 		Position = UDim2.new(0, 154, 0, 53),
 		Size = UDim2.new(1, -154, 1, -53),
 		BackgroundTransparency = 1,
 		Parent = main,
 	})
 	self.Content = content

 	local overlay = new("Frame", {
 		Size = UDim2.fromScale(1, 1),
 		BackgroundTransparency = 1,
 		ZIndex = 60,
 		Parent = root,
 	})
 	self.Overlay = overlay

 	-- 拖拽
 	local function makeDraggable(handle)
 		local dragging = false
 		local dragStart = nil
 		local startPos = nil
 		handle.InputBegan:Connect(function(input)
 			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
 				dragging = true
 				dragStart = input.Position
 				startPos = root.Position
 				input.Changed:Connect(function()
 					if input.UserInputState == Enum.UserInputState.End then
 						dragging = false
 					end
 				end)
 			end
 		end)
 		UserInputService.InputChanged:Connect(function(input)
 			if not dragging then
 				return
 			end
 			if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
 				local delta = input.Position - dragStart
 				local scale = uiScale.Scale > 0 and uiScale.Scale or 1
 				root.Position = UDim2.new(
 					startPos.X.Scale,
 					startPos.X.Offset + delta.X / scale,
 					startPos.Y.Scale,
 					startPos.Y.Offset + delta.Y / scale
 				)
 				self:ClosePopup()
 			end
 		end)
 	end
 	makeDraggable(topbar)

 	minBtn.MouseButton1Click:Connect(function()
 		self:Minimize()
 	end)
 	closeBtn.MouseButton1Click:Connect(function()
 		self:Hide()
 	end)

 	local function resize()
 		local viewport = Camera.ViewportSize
 		local fit = math.min(viewport.X / (660 + 50), viewport.Y / (430 + 60))
 		local scale = math.clamp(fit, 0.55, 1.12)
 		self.BaseScale = scale
 		self.UIScale.Scale = scale
 	end
 	resize()
 	self.Resize = resize
 	Camera:GetPropertyChangedSignal("ViewportSize"):Connect(resize)

 	UserInputService.InputBegan:Connect(function(input, gameProcessed)
 		if gameProcessed then
 			return
 		end
 		if self.ToggleKey and input.KeyCode == self.ToggleKey then
 			self:ToggleVisible()
 		end
 	end)

 	-- 悬浮按钮
 	if useFloat then
 		local floatBtn = new("TextButton", {
 			AnchorPoint = Vector2.new(1, 1),
 			Position = UDim2.new(1, -18, 1, -18),
 			Size = UDim2.fromOffset(46, 46),
 			BackgroundColor3 = Theme.Panel,
 			Text = "",
 			AutoButtonColor = false,
 			Parent = screen,
 		})
 		corner(floatBtn, 23)
 		local floatStroke = stroke(floatBtn, Theme.Accent, 1.4, 0.35)
 		local grad = new("UIGradient", {
 			Color = ColorSequence.new({
 				ColorSequenceKeypoint.new(0, Theme.Accent),
 				ColorSequenceKeypoint.new(1, Theme.Secondary),
 			}),
 			Rotation = 45,
 			Parent = floatBtn,
 		})
 		local floatCrest = UI.Crest({
 			parent = floatBtn,
 			designSize = 30,
 			compact = true,
 			text = string.sub(title, 1, 2),
 			position = UDim2.fromScale(0.5, 0.5),
 		})
 		floatCrest:SetAccent(Theme.Accent)
 		local shadow = new("Frame", {
 			AnchorPoint = Vector2.new(0.5, 0.5),
 			Position = UDim2.fromScale(0.5, 0.5),
 			Size = UDim2.new(1, 10, 1, 10),
 			BackgroundColor3 = Color3.fromRGB(0, 0, 0),
 			BackgroundTransparency = 0.6,
 			BorderSizePixel = 0,
 			ZIndex = -1,
 			Parent = floatBtn,
 		})
 		corner(shadow, 26)
 		self:OnAccent(function(c)
 			local bright = UI.LerpColor(c, Color3.fromRGB(255, 255, 255), 0.3)
 			grad.Color = ColorSequence.new({
 				ColorSequenceKeypoint.new(0, c),
 				ColorSequenceKeypoint.new(1, bright),
 			})
 			grad.Transparency = NumberSequence.new({
 				NumberSequenceKeypoint.new(0, 0.72),
 				NumberSequenceKeypoint.new(1, 0.94),
 			})
 			floatBtn.BackgroundColor3 = Theme.Panel
 			floatStroke.Color = c
 			floatCrest:SetAccent(c)
 		end)

 		local dragging = false
 		local dragStart = nil
 		local startPos = nil
 		floatBtn.InputBegan:Connect(function(input)
 			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
 				dragging = false
 				dragStart = input.Position
 				startPos = floatBtn.Position
 			end
 		end)
 		UserInputService.InputChanged:Connect(function(input)
 			if not dragStart then
 				return
 			end
 			if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
 				local delta = input.Position - dragStart
 				if delta.Magnitude > 6 then
 					dragging = true
 					floatBtn.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
 				end
 			end
 		end)
 		UserInputService.InputEnded:Connect(function(input)
 			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
 				task.wait(0.05)
 				dragging = false
 				dragStart = nil
 			end
 		end)
 		floatBtn.MouseButton1Click:Connect(function()
 			if not dragging then
 				self:ToggleVisible()
 			end
 		end)
 	end

 	-- 水印
 	if useWatermark then
 		local watermark = new("Frame", {
 			AnchorPoint = Vector2.new(0, 1),
 			Position = UDim2.new(0, 14, 1, -14),
 			Size = UDim2.fromOffset(190, 26),
 			BackgroundColor3 = Theme.Panel,
 			BackgroundTransparency = 0.35,
 			BorderSizePixel = 0,
 			Parent = screen,
 		})
 		corner(watermark, 8)
 		stroke(watermark, Color3.fromRGB(255, 255, 255), 1, 0.9)
 		local wmDot = new("Frame", {
 			Size = UDim2.fromOffset(6, 6),
 			Position = UDim2.new(0, 10, 0.5, -3),
 			BackgroundColor3 = Theme.Green,
 			BorderSizePixel = 0,
 			Parent = watermark,
 		})
 		corner(wmDot, 3)
 		local wmText = new("TextLabel", {
 			Size = UDim2.new(1, -26, 1, 0),
 			Position = UDim2.new(0, 22, 0, 0),
 			BackgroundTransparency = 1,
 			Text = title .. "  " .. subtitle,
 			TextXAlignment = Enum.TextXAlignment.Left,
 			TextTruncate = Enum.TextTruncate.AtEnd,
 			Font = Enum.Font.GothamMedium,
 			TextSize = 10,
 			TextColor3 = Theme.SubText,
 			Parent = watermark,
 		})
 		self.WatermarkText = wmText

 		local frames = 0
 		RunService.RenderStepped:Connect(function()
 			frames = frames + 1
 		end)
 		task.spawn(function()
 			while wmText.Parent do
 				task.wait(1)
 				if wmText.Parent then
 					wmText.Text = string.format("%s  %s  ·  %d FPS", title, subtitle, frames)
 				end
 				frames = 0
 			end
 		end)
 	end

 	if o.accent then
 		Theme.Accent = o.accent
 		for _, fn in ipairs(self.AccentAppliers) do
 			pcall(fn, o.accent)
 		end
 	end

 	return self
 end

 function WindowProto:OnAccent(fn)
 	table.insert(self.AccentAppliers, fn)
 end

 function WindowProto:SetAccent(color)
 	Theme.Accent = color
 	self.Flags.accent = color
 	for _, fn in ipairs(self.AccentAppliers) do
 		pcall(fn, color)
 	end
 end

 function WindowProto:SetToggleKey(key)
 	self.ToggleKey = key
 end

 function WindowProto:Show()
 	self.Root.Visible = true
 	local target = self.BaseScale or 1
 	self.UIScale.Scale = target * 0.93
 	tw(self.UIScale, 0.42, { Scale = target }, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
 end

 function WindowProto:Hide()
 	self:ClosePopup()
 	self.Root.Visible = false
 end

 function WindowProto:Minimize()
 	self:Hide()
 	self:Notify({ Title = "已收起", Text = "按 " .. (self.ToggleKey and self.ToggleKey.Name or "快捷键") .. " 重新打开", Duration = 3 })
 end

 function WindowProto:ToggleVisible()
 	if self.Root.Visible then
 		self:Hide()
 	else
 		self:Show()
 	end
 end

 function WindowProto:IsVisible()
 	return self.Root.Visible
 end

 function WindowProto:ClosePopup()
 	if self.Popup then
 		pcall(function()
 			self.Popup:Destroy()
 		end)
 		self.Popup = nil
 	end
 	if self.PopupConn then
 		self.PopupConn:Disconnect()
 		self.PopupConn = nil
 	end
 end

 function WindowProto:Notify(o)
 	o = o or {}
 	if not self.NotifyHolder then
 		self.NotifyHolder = new("Frame", {
 			AnchorPoint = Vector2.new(1, 0),
 			Position = UDim2.new(1, -16, 0, 16),
 			Size = UDim2.fromOffset(250, 0),
 			AutomaticSize = Enum.AutomaticSize.Y,
 			BackgroundTransparency = 1,
 			ZIndex = 100,
 			Parent = self.Screen,
 		})
 		layout(self.NotifyHolder, 8, false, Enum.HorizontalAlignment.Right)
 	end

 	local card = new("Frame", {
 		Size = UDim2.fromOffset(250, 56),
 		BackgroundColor3 = Theme.PanelLight,
 		BackgroundTransparency = 1,
 		BorderSizePixel = 0,
 		ZIndex = 100,
 		Parent = self.NotifyHolder,
 	})
 	corner(card, 10)
 	stroke(card, Color3.fromRGB(255, 255, 255), 1, 0.86)

 	local accentBar = new("Frame", {
 		Size = UDim2.new(0, 3, 1, -16),
 		Position = UDim2.new(0, 8, 0, 8),
 		BackgroundColor3 = Theme.Accent,
 		BorderSizePixel = 0,
 		Parent = card,
 	})
 	corner(accentBar, 2)

 	local titleLabel = new("TextLabel", {
 		Size = UDim2.new(1, -28, 0, 16),
 		Position = UDim2.new(0, 18, 0, 10),
 		BackgroundTransparency = 1,
 		Text = o.Title or "提示",
 		TextXAlignment = Enum.TextXAlignment.Left,
 		Font = Enum.Font.GothamBold,
 		TextSize = 12,
 		TextColor3 = Theme.Text,
 		TextTransparency = 1,
 		Parent = card,
 	})

 	local bodyLabel = new("TextLabel", {
 		Size = UDim2.new(1, -28, 0, 26),
 		Position = UDim2.new(0, 18, 0, 26),
 		BackgroundTransparency = 1,
 		Text = o.Text or "",
 		TextXAlignment = Enum.TextXAlignment.Left,
 		TextYAlignment = Enum.TextYAlignment.Top,
 		TextWrapped = true,
 		Font = Enum.Font.Gotham,
 		TextSize = 10,
 		TextColor3 = Theme.SubText,
 		TextTransparency = 1,
 		Parent = card,
 	})

 	local lifeBar = new("Frame", {
 		Size = UDim2.new(1, -16, 0, 2),
 		Position = UDim2.new(0, 8, 1, -6),
 		BackgroundColor3 = Theme.Accent,
 		BorderSizePixel = 0,
 		Parent = card,
 	})
 	corner(lifeBar, 1)

 	card.Position = UDim2.new(0, 40, 0, 0)
 	tw(card, 0.28, { BackgroundTransparency = 0.05, Position = UDim2.new(0, 0, 0, 0) })
 	tw(titleLabel, 0.25, { TextTransparency = 0 })
 	tw(bodyLabel, 0.25, { TextTransparency = 0 })

 	local duration = o.Duration or 4
 	tw(lifeBar, duration, { Size = UDim2.new(0, 0, 0, 2) }, Enum.EasingStyle.Linear)
 	task.delay(duration, function()
 		if not card.Parent then
 			return
 		end
 		tw(card, 0.25, { BackgroundTransparency = 1, Position = UDim2.new(0, 40, 0, 0) })
 		tw(titleLabel, 0.2, { TextTransparency = 1 })
 		tw(bodyLabel, 0.2, { TextTransparency = 1 })
 		tw(lifeBar, 0.2, { BackgroundTransparency = 1 })
 		task.wait(0.3)
 		card:Destroy()
 	end)
 end

 --==========================================================================
 -- 分页
 --==========================================================================
 function WindowProto:Tab(o)
 	o = o or {}
 	local tabName = o.Name or "标签"

 	local page = new("ScrollingFrame", {
 		Name = tabName,
 		Size = UDim2.fromScale(1, 1),
 		BackgroundTransparency = 1,
 		BorderSizePixel = 0,
 		ScrollBarThickness = 2,
 		ScrollBarImageColor3 = Theme.Dim,
 		ScrollBarImageTransparency = 0.55,
 		CanvasSize = UDim2.new(0, 0, 0, 0),
 		AutomaticCanvasSize = Enum.AutomaticSize.Y,
 		ScrollingDirection = Enum.ScrollingDirection.Y,
 		Visible = false,
 		Parent = self.Content,
 	})
 	pad(page, 14, 12, 14, 12)

 	local inner = new("Frame", {
 		Size = UDim2.new(1, 0, 0, 0),
 		AutomaticSize = Enum.AutomaticSize.Y,
 		BackgroundTransparency = 1,
 		Parent = page,
 	})
 	layout(inner, 10)

 	local btn = new("TextButton", {
 		Size = UDim2.new(1, 0, 0, 36),
 		BackgroundColor3 = Theme.Element,
 		BackgroundTransparency = 1,
 		Text = "",
 		AutoButtonColor = false,
 		Parent = self.TabHolder,
 	})
 	corner(btn, 8)

 	local activeBar = new("Frame", {
 		AnchorPoint = Vector2.new(0, 0.5),
 		Position = UDim2.new(0, 0, 0.5, 0),
 		Size = UDim2.fromOffset(3, 0),
 		BackgroundColor3 = Theme.Accent,
 		BorderSizePixel = 0,
 		Parent = btn,
 	})
 	corner(activeBar, 2)
 	self:OnAccent(function(c)
 		activeBar.BackgroundColor3 = c
 	end)

 	local iconLabel = new("TextLabel", {
 		Size = UDim2.fromOffset(18, 18),
 		Position = UDim2.new(0, 13, 0.5, -9),
 		BackgroundTransparency = 1,
 		Text = o.Icon or "•",
 		Font = Enum.Font.GothamBold,
 		TextSize = 13,
 		TextColor3 = Theme.SubText,
 		Parent = btn,
 	})

 	local nameLabel = new("TextLabel", {
 		Size = UDim2.new(1, -46, 1, 0),
 		Position = UDim2.new(0, 38, 0, 0),
 		BackgroundTransparency = 1,
 		Text = tabName,
 		TextXAlignment = Enum.TextXAlignment.Left,
 		TextTruncate = Enum.TextTruncate.AtEnd,
 		Font = Enum.Font.GothamMedium,
 		TextSize = 12,
 		TextColor3 = Theme.SubText,
 		Parent = btn,
 	})

 	local tab = setmetatable({
 		Name = tabName,
 		Page = page,
 		Inner = inner,
 		Button = btn,
 		Bar = activeBar,
 		Icon = iconLabel,
 		Label = nameLabel,
 		Window = self,
 		Elements = {},
 		Sections = {},
 	}, TabProto)

 	btn.MouseButton1Click:Connect(function()
 		self:SelectTab(tab)
 	end)
 	btn.MouseEnter:Connect(function()
 		if self.ActiveTab ~= tab then
 			tw(btn, 0.15, { BackgroundTransparency = 0.6 })
 			tw(nameLabel, 0.15, { TextColor3 = Theme.Text })
 		end
 	end)
 	btn.MouseLeave:Connect(function()
 		if self.ActiveTab ~= tab then
 			tw(btn, 0.15, { BackgroundTransparency = 1 })
 			tw(nameLabel, 0.15, { TextColor3 = Theme.SubText })
 		end
 	end)

 	table.insert(self.Tabs, tab)
 	if not self.ActiveTab then
 		self:SelectTab(tab)
 	end
 	return tab
 end

 function WindowProto:SelectTab(tab)
 	for _, t in ipairs(self.Tabs) do
 		local on = (t == tab)
 		t.Page.Visible = on
 		tw(t.Button, 0.18, { BackgroundTransparency = on and 0.35 or 1 })
 		tw(t.Label, 0.18, { TextColor3 = on and Theme.Text or Theme.SubText })
 		tw(t.Icon, 0.18, { TextColor3 = on and Theme.Accent or Theme.SubText })
 		tw(t.Bar, 0.2, { Size = on and UDim2.fromOffset(3, 18) or UDim2.fromOffset(3, 0) })
 	end
 	self.ActiveTab = tab
 	self:ClosePopup()
 end

 function WindowProto:Filter(query)
 	query = string.lower(query or "")
 	for _, tab in ipairs(self.Tabs) do
 		local hits = {}
 		for _, element in ipairs(tab.Elements) do
 			local matched = (query == "") or (string.find(string.lower(element.Name), query, 1, true) ~= nil)
 			element.Instance.Visible = matched
 			if matched and element.Section then
 				hits[element.Section] = true
 			end
 		end
 		for _, section in ipairs(tab.Sections) do
 			section.Frame.Visible = (query == "") or (hits[section] == true)
 		end
 	end
 end

 function WindowProto:Destroy()
 	pcall(function()
 		self.Screen:Destroy()
 	end)
 end

 -- 配置读写
 function WindowProto:SaveConfig(path)
 	path = path or self.ConfigFile
 	if not (writefile and readfile and isfile) then
 		return false, "当前执行器不支持文件写入"
 	end
 	local data = {}
 	for key, value in pairs(self.Flags) do
 		if type(key) == "string" then
 			if typeof(value) == "EnumItem" then
 				data[key] = value.Name
 			elseif typeof(value) == "Color3" then
 				data[key] = { r = value.R, g = value.G, b = value.B }
 			elseif type(value) == "boolean" or type(value) == "number" or type(value) == "string" then
 				data[key] = value
 			end
 		end
 	end
 	local ok = pcall(function()
 		writefile(path, HttpService:JSONEncode(data))
 	end)
 	return ok, ok and "已写入 " .. path or "写入失败"
 end

 function WindowProto:LoadConfig(path)
 	path = path or self.ConfigFile
 	if not (readfile and isfile) then
 		return false, "当前执行器不支持文件读取"
 	end
 	if not isfile(path) then
 		return false, "还没有保存过配置"
 	end
 	local ok, decoded = pcall(function()
 		return HttpService:JSONDecode(readfile(path))
 	end)
 	if not ok or type(decoded) ~= "table" then
 		return false, "配置文件已损坏"
 	end
 	for _, entry in ipairs(self.ConfigEntries) do
 		local value = decoded[entry.flag]
 		if value ~= nil then
 			if type(value) == "table" and value.r and value.g and value.b then
 				value = Color3.new(value.r, value.g, value.b)
 			end
 			pcall(entry.set, value)
 		end
 	end
 	return true, "配置已恢复"
 end

 function WindowProto:RegisterConfig(flag, setter)
 	table.insert(self.ConfigEntries, { flag = flag, set = setter })
 end

 --==========================================================================
 -- 分区
 --==========================================================================
 function TabProto:Section(title)
 	local frame = new("Frame", {
 		Size = UDim2.new(1, 0, 0, 0),
 		AutomaticSize = Enum.AutomaticSize.Y,
 		BackgroundColor3 = Theme.Panel,
 		BackgroundTransparency = 0.2,
 		BorderSizePixel = 0,
 		Parent = self.Inner,
 	})
 	corner(frame, 10)
 	stroke(frame, Color3.fromRGB(255, 255, 255), 1, 0.94)

 	new("TextLabel", {
 		Size = UDim2.new(1, -24, 0, 30),
 		Position = UDim2.new(0, 12, 0, 6),
 		BackgroundTransparency = 1,
 		Text = string.upper(title or "SECTION"),
 		TextXAlignment = Enum.TextXAlignment.Left,
 		Font = Enum.Font.GothamBold,
 		TextSize = 10,
 		TextColor3 = Theme.Dim,
 		Parent = frame,
 	})

 	local list = new("Frame", {
 		Size = UDim2.new(1, -16, 0, 0),
 		Position = UDim2.new(0, 8, 0, 34),
 		AutomaticSize = Enum.AutomaticSize.Y,
 		BackgroundTransparency = 1,
 		Parent = frame,
 	})
 	layout(list, 5)
 	pad(list, 0, 0, 8, 0)

 	local section = setmetatable({
 		Tab = self,
 		Window = self.Window,
 		Frame = frame,
 		List = list,
 		Name = title,
 	}, SectionProto)
 	table.insert(self.Sections, section)
 	return section
 end

 function SectionProto:_register(instance, name)
 	table.insert(self.Tab.Elements, { Name = name or "", Instance = instance, Section = self })
 	return instance
 end

 --==========================================================================
 -- 控件
 --==========================================================================
 function SectionProto:Label(text)
 	local row = new("Frame", {
 		Size = UDim2.new(1, 0, 0, 24),
 		BackgroundTransparency = 1,
 		Parent = self.List,
 	})
 	new("TextLabel", {
 		Size = UDim2.new(1, 0, 1, 0),
 		BackgroundTransparency = 1,
 		Text = text or "",
 		TextXAlignment = Enum.TextXAlignment.Left,
 		TextWrapped = true,
 		Font = Enum.Font.Gotham,
 		TextSize = 11,
 		TextColor3 = Theme.SubText,
 		Parent = row,
 	})
 	return self:_register(row, text or "")
 end

 function SectionProto:Divider()
 	local row = new("Frame", {
 		Size = UDim2.new(1, 0, 0, 8),
 		BackgroundTransparency = 1,
 		Parent = self.List,
 	})
 	new("Frame", {
 		Size = UDim2.new(1, 0, 0, 1),
 		Position = UDim2.new(0, 0, 0.5, 0),
 		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
 		BackgroundTransparency = 0.92,
 		BorderSizePixel = 0,
 		Parent = row,
 	})
 	return row
 end

 function SectionProto:Toggle(o)
 	o = o or {}
 	local window = self.Window

 	local row = new("Frame", {
 		Size = UDim2.new(1, 0, 0, 34),
 		BackgroundColor3 = Theme.Element,
 		BackgroundTransparency = 1,
 		Parent = self.List,
 	})
 	corner(row, 7)

 	new("TextLabel", {
 		Size = UDim2.new(1, -74, 1, 0),
 		Position = UDim2.new(0, 10, 0, 0),
 		BackgroundTransparency = 1,
 		Text = o.Name or "开关",
 		TextXAlignment = Enum.TextXAlignment.Left,
 		TextTruncate = Enum.TextTruncate.AtEnd,
 		Font = Enum.Font.GothamMedium,
 		TextSize = 12,
 		TextColor3 = Theme.Text,
 		Parent = row,
 	})

 	local track = new("Frame", {
 		Size = UDim2.fromOffset(38, 20),
 		Position = UDim2.new(1, -48, 0.5, -10),
 		BackgroundColor3 = Theme.ElementHover,
 		BorderSizePixel = 0,
 		Parent = row,
 	})
 	corner(track, 10)

 	local knob = new("Frame", {
 		Size = UDim2.fromOffset(16, 16),
 		Position = UDim2.new(0, 2, 0.5, -8),
 		BackgroundColor3 = Color3.fromRGB(245, 246, 250),
 		BorderSizePixel = 0,
 		Parent = track,
 	})
 	corner(knob, 8)

 	local btn = new("TextButton", {
 		Size = UDim2.fromScale(1, 1),
 		BackgroundTransparency = 1,
 		Text = "",
 		AutoButtonColor = false,
 		Parent = row,
 	})

 	local state = (o.Default == true)

 	local function render(instant)
 		local duration = instant and 0 or 0.18
 		if state then
 			tw(track, duration, { BackgroundColor3 = Theme.Accent })
 			tw(knob, duration, { Position = UDim2.new(1, -18, 0.5, -8) })
 		else
 			tw(track, duration, { BackgroundColor3 = Theme.ElementHover })
 			tw(knob, duration, { Position = UDim2.new(0, 2, 0.5, -8) })
 		end
 	end

 	local function set(value, silent)
 		state = value and true or false
 		render(true)
 		if o.Flag then
 			window.Flags[o.Flag] = state
 		end
 		if not silent and o.Callback then
 			pcall(o.Callback, state)
 		end
 	end

 	btn.MouseButton1Click:Connect(function()
 		set(not state, false)
 	end)
 	btn.MouseEnter:Connect(function()
 		tw(row, 0.15, { BackgroundTransparency = 0.7 })
 	end)
 	btn.MouseLeave:Connect(function()
 		tw(row, 0.15, { BackgroundTransparency = 1 })
 	end)

 	render(true)
 	if o.Flag then
 		window.Flags[o.Flag] = state
 		window:RegisterConfig(o.Flag, function(v)
 			set(v, true)
 		end)
 		window:OnAccent(function(c)
 			if state then
 				track.BackgroundColor3 = c
 			end
 		end)
 	end

 	self:_register(row, o.Name or "")
 	return {
 		Set = function(v)
 			set(v, true)
 		end,
 		Get = function()
 			return state
 		end,
 	}
 end

 function SectionProto:Slider(o)
 	o = o or {}
 	local window = self.Window
 	local minValue = o.Min or 0
 	local maxValue = o.Max or 100
 	local step = o.Step or 1
 	local suffix = o.Suffix or ""

 	local row = new("Frame", {
 		Size = UDim2.new(1, 0, 0, 44),
 		BackgroundColor3 = Theme.Element,
 		BackgroundTransparency = 1,
 		Parent = self.List,
 	})
 	corner(row, 7)

 	new("TextLabel", {
 		Size = UDim2.new(1, -80, 0, 20),
 		Position = UDim2.new(0, 10, 0, 6),
 		BackgroundTransparency = 1,
 		Text = o.Name or "滑条",
 		TextXAlignment = Enum.TextXAlignment.Left,
 		TextTruncate = Enum.TextTruncate.AtEnd,
 		Font = Enum.Font.GothamMedium,
 		TextSize = 12,
 		TextColor3 = Theme.Text,
 		Parent = row,
 	})

 	local valueLabel = new("TextLabel", {
 		Size = UDim2.fromOffset(66, 16),
 		Position = UDim2.new(1, -74, 0, 8),
 		BackgroundColor3 = Theme.PanelLight,
 		BackgroundTransparency = 0.3,
 		Text = "",
 		Font = Enum.Font.GothamBold,
 		TextSize = 10,
 		TextColor3 = Theme.SubText,
 		Parent = row,
 	})
 	corner(valueLabel, 5)

 	local track = new("Frame", {
 		Size = UDim2.new(1, -20, 0, 4),
 		Position = UDim2.new(0, 10, 1, -16),
 		BackgroundColor3 = Theme.ElementHover,
 		BorderSizePixel = 0,
 		Parent = row,
 	})
 	corner(track, 2)

 	local fill = new("Frame", {
 		Size = UDim2.fromScale(0, 1),
 		BackgroundColor3 = Theme.Accent,
 		BorderSizePixel = 0,
 		Parent = track,
 	})
 	corner(fill, 2)

 	local knob = new("Frame", {
 		AnchorPoint = Vector2.new(0.5, 0.5),
 		Position = UDim2.new(0, 0, 0.5, 0),
 		Size = UDim2.fromOffset(12, 12),
 		BackgroundColor3 = Color3.fromRGB(250, 250, 255),
 		BorderSizePixel = 0,
 		Parent = track,
 	})
 	corner(knob, 6)

 	local hit = new("TextButton", {
 		Size = UDim2.new(1, 0, 0, 28),
 		Position = UDim2.new(0, 0, 1, -32),
 		BackgroundTransparency = 1,
 		Text = "",
 		AutoButtonColor = false,
 		Parent = row,
 	})

 	local value = minValue
 	local dragging = false

 	local function render(instant)
 		local alpha = 0
 		if maxValue ~= minValue then
 			alpha = (value - minValue) / (maxValue - minValue)
 		end
 		alpha = math.clamp(alpha, 0, 1)
 		if instant then
 			fill.Size = UDim2.fromScale(alpha, 1)
 			knob.Position = UDim2.new(alpha, 0, 0.5, 0)
 		else
 			tw(fill, 0.08, { Size = UDim2.fromScale(alpha, 1) })
 			tw(knob, 0.08, { Position = UDim2.new(alpha, 0, 0.5, 0) })
 		end
 		valueLabel.Text = fmtNumber(value) .. suffix
 	end

 	local function commit(newValue, silent)
 		newValue = math.clamp(newValue, minValue, maxValue)
 		if step > 0 then
 			newValue = math.floor((newValue / step) + 0.5) * step
 			newValue = math.clamp(newValue, minValue, maxValue)
 		end
 		value = newValue
 		render(true)
 		if o.Flag then
 			window.Flags[o.Flag] = value
 		end
 		if not silent and o.Callback then
 			pcall(o.Callback, value)
 		end
 	end

 	local function updateFromX(x)
 		local width = track.AbsoluteSize.X
 		if width <= 0 then
 			return
 		end
 		local alpha = (x - track.AbsolutePosition.X) / width
 		alpha = math.clamp(alpha, 0, 1)
 		commit(minValue + (maxValue - minValue) * alpha, false)
 	end

 	hit.InputBegan:Connect(function(input)
 		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
 			dragging = true
 			updateFromX(input.Position.X)
 		end
 	end)
 	UserInputService.InputChanged:Connect(function(input)
 		if not dragging then
 			return
 		end
 		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
 			updateFromX(input.Position.X)
 		end
 	end)
 	UserInputService.InputEnded:Connect(function(input)
 		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
 			dragging = false
 		end
 	end)

 	commit(o.Default or minValue, true)
 	if o.Flag then
 		window:RegisterConfig(o.Flag, function(v)
 			if type(v) == "number" then
 				commit(v, true)
 			end
 		end)
 	end
 	window:OnAccent(function(c)
 		fill.BackgroundColor3 = c
 	end)

 	self:_register(row, o.Name or "")
 	return {
 		Set = function(v)
 			commit(v, true)
 		end,
 		Get = function()
 			return value
 		end,
 	}
 end

 function SectionProto:Button(o)
 	o = o or {}
 	local window = self.Window

 	local row = new("Frame", {
 		Size = UDim2.new(1, 0, 0, 34),
 		BackgroundColor3 = Theme.Element,
 		BackgroundTransparency = 0.15,
 		Parent = self.List,
 	})
 	corner(row, 7)
 	local strokeInst = stroke(row, Theme.Accent, 1, 0.9)

 	new("TextLabel", {
 		Size = UDim2.new(1, -40, 1, 0),
 		Position = UDim2.new(0, 12, 0, 0),
 		BackgroundTransparency = 1,
 		Text = o.Name or "按钮",
 		TextXAlignment = Enum.TextXAlignment.Left,
 		TextTruncate = Enum.TextTruncate.AtEnd,
 		Font = Enum.Font.GothamMedium,
 		TextSize = 12,
 		TextColor3 = Theme.Text,
 		Parent = row,
 	})

 	local arrow = new("TextLabel", {
 		Size = UDim2.fromOffset(16, 16),
 		Position = UDim2.new(1, -24, 0.5, -8),
 		BackgroundTransparency = 1,
 		Text = "›",
 		Font = Enum.Font.GothamBold,
 		TextSize = 14,
 		TextColor3 = Theme.Dim,
 		Parent = row,
 	})

 	local btn = new("TextButton", {
 		Size = UDim2.fromScale(1, 1),
 		BackgroundTransparency = 1,
 		Text = "",
 		AutoButtonColor = false,
 		Parent = row,
 	})

 	btn.MouseEnter:Connect(function()
 		tw(row, 0.15, { BackgroundTransparency = 0 })
 		tw(strokeInst, 0.15, { Transparency = 0.5 })
 		tw(arrow, 0.15, { Position = UDim2.new(1, -20, 0.5, -8) })
 	end)
 	btn.MouseLeave:Connect(function()
 		tw(row, 0.15, { BackgroundTransparency = 0.15 })
 		tw(strokeInst, 0.15, { Transparency = 0.9 })
 		tw(arrow, 0.15, { Position = UDim2.new(1, -24, 0.5, -8) })
 	end)
 	btn.MouseButton1Click:Connect(function()
 		if o.Callback then
 			pcall(o.Callback)
 		end
 	end)
 	window:OnAccent(function(c)
 		strokeInst.Color = c
 	end)

 	self:_register(row, o.Name or "")
 	return { Row = row }
 end

 function SectionProto:Textbox(o)
 	o = o or {}
 	local window = self.Window

 	local row = new("Frame", {
 		Size = UDim2.new(1, 0, 0, 34),
 		BackgroundColor3 = Theme.Element,
 		BackgroundTransparency = 1,
 		Parent = self.List,
 	})
 	corner(row, 7)

 	new("TextLabel", {
 		Size = UDim2.fromOffset(74, 20),
 		Position = UDim2.new(0, 10, 0.5, -10),
 		BackgroundTransparency = 1,
 		Text = o.Name or "输入",
 		TextXAlignment = Enum.TextXAlignment.Left,
 		TextTruncate = Enum.TextTruncate.AtEnd,
 		Font = Enum.Font.GothamMedium,
 		TextSize = 12,
 		TextColor3 = Theme.Text,
 		Parent = row,
 	})

 	local box = new("Frame", {
 		Size = UDim2.new(0, 110, 0, 24),
 		Position = UDim2.new(1, -120, 0.5, -12),
 		BackgroundColor3 = Theme.PanelLight,
 		BackgroundTransparency = 0.2,
 		BorderSizePixel = 0,
 		Parent = row,
 	})
 	corner(box, 6)
 	local boxStroke = stroke(box, Theme.Accent, 1, 1)

 	local input = new("TextBox", {
 		Size = UDim2.new(1, -12, 1, 0),
 		Position = UDim2.new(0, 8, 0, 0),
 		BackgroundTransparency = 1,
 		Text = o.Default or "",
 		PlaceholderText = o.Placeholder or "输入…",
 		PlaceholderColor3 = Theme.Dim,
 		Font = Enum.Font.GothamMedium,
 		TextSize = 11,
 		TextColor3 = Theme.Text,
 		TextXAlignment = Enum.TextXAlignment.Left,
 		ClearTextOnFocus = false,
 		Parent = box,
 	})

 	input.Focused:Connect(function()
 		tw(boxStroke, 0.15, { Transparency = 0.4 })
 	end)
 	input.FocusLost:Connect(function(enterPressed)
 		tw(boxStroke, 0.15, { Transparency = 1 })
 		if o.Flag then
 			window.Flags[o.Flag] = input.Text
 		end
 		if o.Callback then
 			pcall(o.Callback, input.Text, enterPressed)
 		end
 	end)

 	if o.Flag then
 		window.Flags[o.Flag] = input.Text
 		window:RegisterConfig(o.Flag, function(v)
 			if type(v) == "string" then
 				input.Text = v
 			end
 		end)
 	end
 	window:OnAccent(function(c)
 		boxStroke.Color = c
 	end)

 	self:_register(row, o.Name or "")
 	return {
 		Set = function(v)
 			input.Text = tostring(v)
 		end,
 		Get = function()
 			return input.Text
 		end,
 	}
 end

 function SectionProto:Dropdown(o)
 	o = o or {}
 	local window = self.Window
 	local options = o.Options or {}

 	local row = new("Frame", {
 		Size = UDim2.new(1, 0, 0, 34),
 		BackgroundColor3 = Theme.Element,
 		BackgroundTransparency = 1,
 		Parent = self.List,
 	})
 	corner(row, 7)

 	new("TextLabel", {
 		Size = UDim2.new(1, -140, 1, 0),
 		Position = UDim2.new(0, 10, 0, 0),
 		BackgroundTransparency = 1,
 		Text = o.Name or "选择",
 		TextXAlignment = Enum.TextXAlignment.Left,
 		TextTruncate = Enum.TextTruncate.AtEnd,
 		Font = Enum.Font.GothamMedium,
 		TextSize = 12,
 		TextColor3 = Theme.Text,
 		Parent = row,
 	})

 	local display = new("Frame", {
 		Size = UDim2.new(0, 120, 0, 24),
 		Position = UDim2.new(1, -130, 0.5, -12),
 		BackgroundColor3 = Theme.PanelLight,
 		BackgroundTransparency = 0.2,
 		BorderSizePixel = 0,
 		Parent = row,
 	})
 	corner(display, 6)
 	local displayStroke = stroke(display, Theme.Accent, 1, 1)

 	local displayText = new("TextLabel", {
 		Size = UDim2.new(1, -24, 1, 0),
 		Position = UDim2.new(0, 8, 0, 0),
 		BackgroundTransparency = 1,
 		Text = tostring(o.Default or options[1] or "—"),
 		TextXAlignment = Enum.TextXAlignment.Left,
 		TextTruncate = Enum.TextTruncate.AtEnd,
 		Font = Enum.Font.GothamMedium,
 		TextSize = 11,
 		TextColor3 = Theme.SubText,
 		Parent = display,
 	})

 	new("TextLabel", {
 		Size = UDim2.fromOffset(14, 14),
 		Position = UDim2.new(1, -20, 0.5, -7),
 		BackgroundTransparency = 1,
 		Text = "▾",
 		Font = Enum.Font.GothamBold,
 		TextSize = 10,
 		TextColor3 = Theme.Dim,
 		Parent = display,
 	})

 	local btn = new("TextButton", {
 		Size = UDim2.fromScale(1, 1),
 		BackgroundTransparency = 1,
 		Text = "",
 		AutoButtonColor = false,
 		Parent = row,
 	})

 	local value = o.Default or options[1]

 	local function setValue(v, silent)
 		value = v
 		displayText.Text = tostring(v)
 		if o.Flag then
 			window.Flags[o.Flag] = v
 		end
 		if not silent and o.Callback then
 			pcall(o.Callback, v)
 		end
 	end

 	local function openPopup()
 		window:ClosePopup()

 		local pop = new("Frame", {
 			Name = "DropdownPopup",
 			BackgroundColor3 = Theme.PanelLight,
 			BorderSizePixel = 0,
 			ZIndex = 80,
 			Parent = window.Overlay,
 		})
 		corner(pop, 8)
 		stroke(pop, Color3.fromRGB(255, 255, 255), 1, 0.85)

 		local scale = window.UIScale.Scale > 0 and window.UIScale.Scale or 1
 		local rootPos = window.Root.AbsolutePosition
 		local relX = (row.AbsolutePosition.X - rootPos.X) / scale
 		local relY = (row.AbsolutePosition.Y - rootPos.Y) / scale + (row.AbsoluteSize.Y / scale) + 4
 		local width = row.AbsoluteSize.X / scale
 		local itemHeight = 26
 		local listHeight = math.min(#options * itemHeight + 8, 168)

 		pop.Position = UDim2.fromOffset(relX, relY)
 		pop.Size = UDim2.fromOffset(width, listHeight)

 		local scroll = new("ScrollingFrame", {
 			Size = UDim2.fromScale(1, 1),
 			BackgroundTransparency = 1,
 			BorderSizePixel = 0,
 			ScrollBarThickness = 2,
 			ScrollBarImageColor3 = Theme.Dim,
 			CanvasSize = UDim2.new(0, 0, 0, 0),
 			AutomaticCanvasSize = Enum.AutomaticSize.Y,
 			ZIndex = 81,
 			Parent = pop,
 		})
 		pad(scroll, 4)
 		layout(scroll, 2)

 		for _, option in ipairs(options) do
 			local item = new("TextButton", {
 				Size = UDim2.new(1, 0, 0, itemHeight - 2),
 				BackgroundColor3 = Theme.Element,
 				BackgroundTransparency = 1,
 				Text = tostring(option),
 				TextXAlignment = Enum.TextXAlignment.Left,
 				Font = Enum.Font.GothamMedium,
 				TextSize = 11,
 				TextColor3 = (value == option) and Theme.Text or Theme.SubText,
 				AutoButtonColor = false,
 				ZIndex = 81,
 				Parent = scroll,
 			})
 			corner(item, 5)
 			pad(item, 0, 8, 0, 8)

 			item.MouseEnter:Connect(function()
 				tw(item, 0.12, { BackgroundTransparency = 0.6 })
 			end)
 			item.MouseLeave:Connect(function()
 				tw(item, 0.12, { BackgroundTransparency = 1 })
 			end)
 			item.MouseButton1Click:Connect(function()
 				setValue(option, false)
 				window:ClosePopup()
 			end)
 		end

 		window.Popup = pop
 		window.PopupConn = UserInputService.InputBegan:Connect(function(input)
 			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
 				local mouse = input.Position
 				local abs = pop.AbsolutePosition
 				local size = pop.AbsoluteSize
 				local inside = mouse.X >= abs.X and mouse.X <= abs.X + size.X and mouse.Y >= abs.Y and mouse.Y <= abs.Y + size.Y
 				if not inside then
 					window:ClosePopup()
 				end
 			end
 		end)
 	end

 	btn.MouseButton1Click:Connect(function()
 		if window.Popup then
 			window:ClosePopup()
 		else
 			openPopup()
 		end
 	end)
 	btn.MouseEnter:Connect(function()
 		tw(row, 0.15, { BackgroundTransparency = 0.7 })
 		tw(displayStroke, 0.15, { Transparency = 0.6 })
 	end)
 	btn.MouseLeave:Connect(function()
 		tw(row, 0.15, { BackgroundTransparency = 1 })
 		tw(displayStroke, 0.15, { Transparency = 1 })
 	end)

 	if o.Flag then
 		window.Flags[o.Flag] = value
 		window:RegisterConfig(o.Flag, function(v)
 			setValue(v, true)
 		end)
 	end
 	window:OnAccent(function(c)
 		displayStroke.Color = c
 	end)

 	self:_register(row, o.Name or "")
 	return {
 		Set = function(v)
 			setValue(v, true)
 		end,
 		Get = function()
 			return value
 		end,
 	}
 end

 function SectionProto:Keybind(o)
 	o = o or {}
 	local window = self.Window

 	local row = new("Frame", {
 		Size = UDim2.new(1, 0, 0, 34),
 		BackgroundColor3 = Theme.Element,
 		BackgroundTransparency = 1,
 		Parent = self.List,
 	})
 	corner(row, 7)

 	new("TextLabel", {
 		Size = UDim2.new(1, -120, 1, 0),
 		Position = UDim2.new(0, 10, 0, 0),
 		BackgroundTransparency = 1,
 		Text = o.Name or "按键绑定",
 		TextXAlignment = Enum.TextXAlignment.Left,
 		Font = Enum.Font.GothamMedium,
 		TextSize = 12,
 		TextColor3 = Theme.Text,
 		Parent = row,
 	})

 	local keyLabel = new("TextLabel", {
 		Size = UDim2.new(0, 96, 0, 24),
 		Position = UDim2.new(1, -106, 0.5, -12),
 		BackgroundColor3 = Theme.PanelLight,
 		BackgroundTransparency = 0.2,
 		Text = o.Default and o.Default.Name or "未绑定",
 		Font = Enum.Font.GothamBold,
 		TextSize = 10,
 		TextColor3 = Theme.SubText,
 		Parent = row,
 	})
 	corner(keyLabel, 6)

 	local btn = new("TextButton", {
 		Size = UDim2.fromScale(1, 1),
 		BackgroundTransparency = 1,
 		Text = "",
 		AutoButtonColor = false,
 		Parent = row,
 	})

 	local key = o.Default
 	local listening = false

 	local function setKey(newKey)
 		key = newKey
 		keyLabel.Text = newKey and newKey.Name or "未绑定"
 		if o.Flag then
 			window.Flags[o.Flag] = newKey
 		end
 	end

 	btn.MouseButton1Click:Connect(function()
 		listening = true
 		keyLabel.Text = "按键…"
 		tw(keyLabel, 0.1, { TextColor3 = Theme.Accent })
 	end)

 	UserInputService.InputBegan:Connect(function(input, gameProcessed)
 		if not listening then
 			return
 		end
 		if input.UserInputType == Enum.UserInputType.Keyboard then
 			listening = false
 			tw(keyLabel, 0.1, { TextColor3 = Theme.SubText })
 			if input.KeyCode == Enum.KeyCode.Escape then
 				setKey(nil)
 			else
 				setKey(input.KeyCode)
 			end
 			if o.Callback then
 				pcall(o.Callback, key)
 			end
 		end
 	end)

 	if o.Flag then
 		window.Flags[o.Flag] = key
 		window:RegisterConfig(o.Flag, function(v)
 			if type(v) == "EnumItem" then
 				setKey(v)
 			end
 		end)
 	end

 	self:_register(row, o.Name or "")
 	return {
 		Set = function(v)
 			setKey(v)
 		end,
 		Get = function()
 			return key
 		end,
 	}
 end

 return UI

end)()

--==========================================================================
-- 2) 功能模块（原 src/Features.lua）
--==========================================================================
local Features = (function()
 --[[==========================================================================
 	SA HUB · 功能模块  (src/Features.lua)
 	------------------------------------------------------------------
 	只负责"能干什么"，界面由 src/UI.lua 提供。
 	加载方式：
 		local Features = loadstring(game:HttpGet(".../src/Features.lua"))()
 		Features(Window, UI, { reload = function() end })
 	新增功能：在对应的 Section 里加控件，把逻辑写在文件下半部分的"实现"里。
 ==========================================================================]]

 return function(Window, UI, opts)
 	opts = opts or {}
 	local Players = game:GetService("Players")
 	local RunService = game:GetService("RunService")
 	local UserInputService = game:GetService("UserInputService")
 	local Lighting = game:GetService("Lighting")
 	local VirtualUser = game:GetService("VirtualUser")
 	local LocalPlayer = Players.LocalPlayer
 	local flags = Window.Flags

 	--======================================================================
 	-- 前置状态（下面实现部分会用到）
 	--======================================================================
 	local flyState = { conn = nil, bv = nil, bg = nil }
 	local antiAfkConn = nil
 	local lightingSaved = nil
 	local espFolder = nil
 	local startFly, stopFly, setAntiAfk, applyFullbright, applyFov

 	local function getEspFolder()
 		if not espFolder or not espFolder.Parent then
 			local parent = UI.GuiParent or LocalPlayer:WaitForChild("PlayerGui")
 			espFolder = Instance.new("Folder")
 			espFolder.Name = "SAHubESP"
 			espFolder.Parent = parent
 		end
 		return espFolder
 	end

 	--======================================================================
 	-- 基础取值
 	--======================================================================
 	local function getHumanoid()
 		local char = LocalPlayer.Character
 		if char then
 			return char:FindFirstChildOfClass("Humanoid")
 		end
 		return nil
 	end

 	local function applyMovement()
 		local hum = getHumanoid()
 		if not hum then
 			return
 		end
 		if flags.speed and flags.speed > 0 then
 			hum.WalkSpeed = flags.speed
 		end
 		if flags.jump and flags.jump > 0 then
 			hum.UseJumpPower = true
 			hum.JumpPower = flags.jump
 		end
 	end

 	LocalPlayer.CharacterAdded:Connect(function()
 		task.wait(1)
 		applyMovement()
 	end)

 	--======================================================================
 	-- 首页
 	--======================================================================
 	local homeTab = Window:Tab({ Name = "首页", Icon = "★" })
 	local welcome = homeTab:Section("欢迎")
 	welcome:Label("SA HUB 加载完成，祝玩得开心。")
 	welcome:Label("按 " .. (Window.ToggleKey and Window.ToggleKey.Name or "RightShift") .. " 可随时隐藏 / 呼出面板。")

 	local quick = homeTab:Section("快捷操作")
 	quick:Button({
 		Name = "保存当前配置",
 		Callback = function()
 			local ok, msg = Window:SaveConfig()
 			Window:Notify({
 				Title = ok and "配置已保存" or "保存失败",
 				Text = msg or "",
 				Duration = 3,
 			})
 		end,
 	})
 	quick:Button({
 		Name = "读取上次配置",
 		Callback = function()
 			local ok, msg = Window:LoadConfig()
 			Window:Notify({
 				Title = ok and "配置已恢复" or "读取失败",
 				Text = msg or "",
 				Duration = 3,
 			})
 		end,
 	})
 	if opts.reload then
 		quick:Button({
 			Name = "重新载入脚本",
 			Callback = function()
 				Window:Notify({ Title = "正在重载", Text = "界面即将刷新", Duration = 2 })
 				task.wait(0.6)
 				pcall(opts.reload)
 			end,
 		})
 	end

 	--======================================================================
 	-- 玩家
 	--======================================================================
 	local playerTab = Window:Tab({ Name = "玩家", Icon = "◈" })
 	local moveSection = playerTab:Section("移动")
 	moveSection:Slider({
 		Name = "移动速度",
 		Min = 16,
 		Max = 250,
 		Default = 16,
 		Flag = "speed",
 		Callback = function(v)
 			local hum = getHumanoid()
 			if hum then
 				hum.WalkSpeed = v
 			end
 		end,
 	})
 	moveSection:Slider({
 		Name = "跳跃力量",
 		Min = 50,
 		Max = 500,
 		Default = 50,
 		Flag = "jump",
 		Callback = function(v)
 			local hum = getHumanoid()
 			if hum then
 				hum.UseJumpPower = true
 				hum.JumpPower = v
 			end
 		end,
 	})
 	moveSection:Toggle({
 		Name = "无限跳跃",
 		Default = false,
 		Flag = "infjump",
 	})
 	moveSection:Toggle({
 		Name = "穿墙 Noclip",
 		Default = false,
 		Flag = "noclip",
 	})

 	local flySection = playerTab:Section("飞行")
 	flySection:Toggle({
 		Name = "启用飞行",
 		Default = false,
 		Flag = "fly",
 		Callback = function(v)
 			if v then
 				startFly()
 			else
 				stopFly()
 			end
 		end,
 	})
 	flySection:Slider({
 		Name = "飞行速度",
 		Min = 20,
 		Max = 300,
 		Default = 60,
 		Flag = "flyspeed",
 	})
 	flySection:Label("WASD 平移 · 空格上升 · 左Ctrl 下降")

 	local otherSection = playerTab:Section("其他")
 	otherSection:Toggle({
 		Name = "反挂机 Anti-AFK",
 		Default = false,
 		Flag = "antiafk",
 		Callback = function(v)
 			setAntiAfk(v)
 		end,
 	})

 	--======================================================================
 	-- 视觉
 	--======================================================================
 	local visualTab = Window:Tab({ Name = "视觉", Icon = "◉" })
 	local visualSection = visualTab:Section("画面")
 	visualSection:Toggle({
 		Name = "全亮 Fullbright",
 		Default = false,
 		Flag = "fullbright",
 		Callback = function(v)
 			applyFullbright(v)
 		end,
 	})
 	visualSection:Toggle({
 		Name = "玩家透视 ESP",
 		Default = false,
 		Flag = "esp",
 	})
 	visualSection:Slider({
 		Name = "视野 FOV",
 		Min = 40,
 		Max = 120,
 		Default = 70,
 		Flag = "fov",
 		Callback = function()
 			applyFov()
 		end,
 	})

 	--======================================================================
 	-- 战斗
 	--======================================================================
 	local combatTab = Window:Tab({ Name = "战斗", Icon = "✧" })
 	local aimSection = combatTab:Section("自瞄")
 	aimSection:Toggle({
 		Name = "启用自瞄",
 		Default = false,
 		Flag = "aimbot",
 	})
 	aimSection:Slider({
 		Name = "自瞄范围",
 		Min = 40,
 		Max = 600,
 		Default = 240,
 		Flag = "aimfov",
 	})
 	aimSection:Slider({
 		Name = "平滑度",
 		Min = 1,
 		Max = 20,
 		Default = 6,
 		Flag = "aimsmooth",
 	})
 	aimSection:Toggle({
 		Name = "忽略队友",
 		Default = true,
 		Flag = "teamcheck",
 	})

 	--======================================================================
 	-- 设置
 	--======================================================================
 	local settingsTab = Window:Tab({ Name = "设置", Icon = "⚙" })
 	local themeSection = settingsTab:Section("外观")
 	themeSection:Dropdown({
 		Name = "主题色",
 		Options = { "霓虹蓝", "紫罗兰", "薄荷绿", "落日橙", "玫瑰红" },
 		Default = "霓虹蓝",
 		Callback = function(v)
 			local palette = {
 				["霓虹蓝"] = Color3.fromRGB(46, 158, 255),
 				["紫罗兰"] = Color3.fromRGB(138, 92, 246),
 				["薄荷绿"] = Color3.fromRGB(34, 197, 154),
 				["落日橙"] = Color3.fromRGB(249, 115, 70),
 				["玫瑰红"] = Color3.fromRGB(244, 63, 122),
 			}
 			Window:SetAccent(palette[v] or Color3.fromRGB(46, 158, 255))
 		end,
 	})
 	themeSection:Keybind({
 		Name = "显示 / 隐藏面板",
 		Default = Window.ToggleKey,
 		Callback = function(key)
 			if key then
 				Window:SetToggleKey(key)
 			end
 		end,
 	})

 	local configSection = settingsTab:Section("配置")
 	configSection:Button({
 		Name = "保存配置到本地",
 		Callback = function()
 			local ok, msg = Window:SaveConfig()
 			Window:Notify({ Title = ok and "已保存" or "保存失败", Text = msg or "", Duration = 3 })
 		end,
 	})
 	configSection:Button({
 		Name = "从本地读取配置",
 		Callback = function()
 			local ok, msg = Window:LoadConfig()
 			Window:Notify({ Title = ok and "已恢复" or "读取失败", Text = msg or "", Duration = 3 })
 		end,
 	})
 	configSection:Button({
 		Name = "测试通知",
 		Callback = function()
 			Window:Notify({ Title = "SA HUB", Text = "通知系统工作正常", Duration = 3 })
 		end,
 	})

 	local aboutSection = settingsTab:Section("关于")
 	aboutSection:Label((opts.fullName or "SA HUB") .. "  v" .. (opts.version or "1.0.0"))
 	aboutSection:Label("界面与功能分离，可在 src/Features.lua 里自由扩展")

 	--======================================================================
 	-- 实现：移动 / 飞行 / 穿墙
 	--======================================================================
 	startFly = function()
 		stopFly()
 		local char = LocalPlayer.Character
 		local hrp = char and char:FindFirstChild("HumanoidRootPart")
 		local hum = char and char:FindFirstChildOfClass("Humanoid")
 		if not hrp or not hum then
 			return
 		end
 		pcall(function()
 			hum.PlatformStand = true
 		end)

 		local bv = Instance.new("BodyVelocity")
 		bv.MaxForce = Vector3.new(1, 1, 1) * 40000
 		bv.P = 1250
 		bv.Velocity = Vector3.zero
 		bv.Parent = hrp

 		local bg = Instance.new("BodyGyro")
 		bg.MaxTorque = Vector3.new(1, 1, 1) * 40000
 		bg.P = 3000
 		bg.D = 500
 		bg.CFrame = hrp.CFrame
 		bg.Parent = hrp

 		flyState.bv = bv
 		flyState.bg = bg

 		flyState.conn = RunService.RenderStepped:Connect(function()
 			if not flags.fly or not hrp.Parent or not bv.Parent then
 				stopFly()
 				return
 			end
 			local cam = workspace.CurrentCamera
 			local direction = Vector3.zero
 			if UserInputService:IsKeyDown(Enum.KeyCode.W) then
 				direction = direction + cam.CFrame.LookVector
 			end
 			if UserInputService:IsKeyDown(Enum.KeyCode.S) then
 				direction = direction - cam.CFrame.LookVector
 			end
 			if UserInputService:IsKeyDown(Enum.KeyCode.D) then
 				direction = direction + cam.CFrame.RightVector
 			end
 			if UserInputService:IsKeyDown(Enum.KeyCode.A) then
 				direction = direction - cam.CFrame.RightVector
 			end
 			if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
 				direction = direction + Vector3.new(0, 1, 0)
 			end
 			if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
 				direction = direction - Vector3.new(0, 1, 0)
 			end
 			if direction.Magnitude > 0 then
 				bv.Velocity = direction.Unit * (flags.flyspeed or 60)
 			else
 				bv.Velocity = Vector3.zero
 			end
 			bg.CFrame = cam.CFrame
 		end)
 	end

 	stopFly = function()
 		if flyState.conn then
 			flyState.conn:Disconnect()
 			flyState.conn = nil
 		end
 		for _, obj in ipairs({ flyState.bv, flyState.bg }) do
 			if obj then
 				pcall(function()
 					obj:Destroy()
 				end)
 			end
 		end
 		flyState.bv = nil
 		flyState.bg = nil
 		local hum = getHumanoid()
 		if hum then
 			pcall(function()
 				hum.PlatformStand = false
 			end)
 		end
 	end

 	UserInputService.JumpRequest:Connect(function()
 		if flags.infjump then
 			local hum = getHumanoid()
 			if hum then
 				hum:ChangeState(Enum.HumanoidStateType.Jumping)
 			end
 		end
 	end)

 	RunService.Stepped:Connect(function()
 		if not flags.noclip then
 			return
 		end
 		local char = LocalPlayer.Character
 		if not char then
 			return
 		end
 		for _, part in ipairs(char:GetDescendants()) do
 			if part:IsA("BasePart") and part.CanCollide then
 				part.CanCollide = false
 			end
 		end
 	end)

 	--======================================================================
 	-- 实现：反挂机
 	--======================================================================
 	setAntiAfk = function(on)
 		if on and not antiAfkConn then
 			antiAfkConn = LocalPlayer.Idled:Connect(function()
 				pcall(function()
 					VirtualUser:CaptureController()
 					VirtualUser:ClickButton2(Vector2.new())
 				end)
 			end)
 		elseif not on and antiAfkConn then
 			antiAfkConn:Disconnect()
 			antiAfkConn = nil
 		end
 	end

 	--======================================================================
 	-- 实现：全亮
 	--======================================================================
 	applyFullbright = function(on)
 		if on then
 			if not lightingSaved then
 				lightingSaved = {
 					Brightness = Lighting.Brightness,
 					ClockTime = Lighting.ClockTime,
 					FogEnd = Lighting.FogEnd,
 					Ambient = Lighting.Ambient,
 					OutdoorAmbient = Lighting.OutdoorAmbient,
 					GlobalShadows = Lighting.GlobalShadows,
 					EnvironmentDiffuseScale = Lighting.EnvironmentDiffuseScale,
 					EnvironmentSpecularScale = Lighting.EnvironmentSpecularScale,
 				}
 			end
 			Lighting.Brightness = 3
 			Lighting.ClockTime = 14
 			Lighting.FogEnd = 100000
 			Lighting.Ambient = Color3.fromRGB(178, 178, 178)
 			Lighting.OutdoorAmbient = Color3.fromRGB(178, 178, 178)
 			Lighting.GlobalShadows = false
 			Lighting.EnvironmentDiffuseScale = 1
 			Lighting.EnvironmentSpecularScale = 1
 		elseif lightingSaved then
 			for key, value in pairs(lightingSaved) do
 				pcall(function()
 					Lighting[key] = value
 				end)
 			end
 			lightingSaved = nil
 		end
 	end

 	task.spawn(function()
 		while true do
 			if flags.fullbright then
 				pcall(function()
 					Lighting.Brightness = 3
 					Lighting.ClockTime = 14
 					Lighting.FogEnd = 100000
 					Lighting.GlobalShadows = false
 				end)
 			end
 			task.wait(1.5)
 		end
 	end)

 	--======================================================================
 	-- 实现：ESP
 	--======================================================================
 	task.spawn(function()
 		while true do
 			local folder = getEspFolder()
 			for _, child in ipairs(folder:GetChildren()) do
 				if not flags.esp then
 					child:Destroy()
 				else
 					local adornee = child.Adornee
 					if not adornee or not adornee.Parent then
 						child:Destroy()
 					end
 				end
 			end
 			if flags.esp then
 				for _, player in ipairs(Players:GetPlayers()) do
 					if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
 						local existing = folder:FindFirstChild(player.Name)
 						if existing then
 							if existing.Adornee ~= player.Character then
 								existing.Adornee = player.Character
 							end
 						else
 							local highlight = Instance.new("Highlight")
 							highlight.Name = player.Name
 							highlight.Adornee = player.Character
 							highlight.FillColor = UI.Theme.Accent
 							highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
 							highlight.FillTransparency = 0.65
 							highlight.OutlineTransparency = 0.1
 							highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
 							highlight.Parent = folder
 						end
 					end
 				end
 			end
 			task.wait(0.6)
 		end
 	end)

 	--======================================================================
 	-- 实现：FOV
 	--======================================================================
 	applyFov = function()
 		local cam = workspace.CurrentCamera
 		if cam then
 			cam.FieldOfView = flags.fov
 		end
 	end

 	workspace.CurrentCamera:GetPropertyChangedSignal("CameraType"):Connect(function()
 		applyFov()
 	end)

 	--======================================================================
 	-- 实现：自瞄
 	--======================================================================
 	RunService.RenderStepped:Connect(function(dt)
 		if not flags.aimbot then
 			return
 		end
 		local cam = workspace.CurrentCamera
 		if not cam then
 			return
 		end
 		local center = Vector2.new(cam.ViewportSize.X / 2, cam.ViewportSize.Y / 2)
 		local best = nil
 		local bestDistance = math.huge

 		for _, player in ipairs(Players:GetPlayers()) do
 			if player ~= LocalPlayer and player.Character then
 				local hum = player.Character:FindFirstChildOfClass("Humanoid")
 				local root = player.Character:FindFirstChild("HumanoidRootPart")
 				local skip = false
 				if hum and hum.Health <= 0 then
 					skip = true
 				end
 				if flags.teamcheck and player.Team and LocalPlayer.Team and player.Team == LocalPlayer.Team then
 					skip = true
 				end
 				if not skip and root then
 					local screenPos, onScreen = cam:WorldToViewportPoint(root.Position + Vector3.new(0, 1.1, 0))
 					if onScreen then
 						local distance = (Vector2.new(screenPos.X, screenPos.Y) - center).Magnitude
 						if distance <= flags.aimfov and distance < bestDistance then
 							best = root
 							bestDistance = distance
 						end
 					end
 				end
 			end
 		end

 		if best then
 			local target = best.Position + Vector3.new(0, 1.1, 0)
 			local goal = CFrame.new(cam.CFrame.Position, target)
 			local alpha = math.clamp((flags.aimsmooth or 6) * dt * 1.6, 0, 1)
 			cam.CFrame = cam.CFrame:Lerp(goal, alpha)
 		end
 	end)

 	return {
 		applyMovement = applyMovement,
 		applyFov = applyFov,
 	}
 end

end)()

--==========================================================================
-- 3) 入口：把界面和功能接起来
--==========================================================================
local splash = UI.Splash({
	name = CONFIG.Name,
	fullName = CONFIG.FullName,
	version = CONFIG.Version,
	accent = CONFIG.Accent,
	minTime = 2.2,
})

local Window = UI.Window({
	title = CONFIG.FullName,
	subtitle = "v" .. CONFIG.Version,
	accent = CONFIG.Accent,
	toggleKey = CONFIG.ToggleKey,
	configFile = CONFIG.ConfigFile,
})

local features = nil
do
	local ok, result = pcall(Features, Window, UI, {
		fullName = CONFIG.FullName,
		version = CONFIG.Version,
		reload = function()
			if CONFIG.RawUrl and CONFIG.RawUrl ~= "" then
				local okFetch, body = pcall(function()
					local stamp = tostring(math.floor((tick and tick() or 0) * 1000))
					return game:HttpGet(CONFIG.RawUrl .. "?v=" .. stamp)
				end)
				if okFetch and type(body) == "string" and #body > 32 then
					local chunk = loadstring(body)
					if chunk then
						pcall(function()
							Window:Destroy()
						end)
						return chunk()
					end
				end
			end
			Window:Notify({
				Title = "已是最新",
				Text = "重新执行一次脚本即可载入最新版",
				Duration = 4,
			})
		end,
	})
	if ok then
		features = result
	end
end

splash:Finish(function()
	Window:Show()
	if features then
		pcall(features.applyMovement)
		pcall(features.applyFov)
	end
	task.wait(0.4)
	Window:Notify({
		Title = CONFIG.FullName .. " 已就绪",
		Text = "按 " .. CONFIG.ToggleKey.Name .. " 呼出或隐藏面板",
		Duration = 4,
	})
end)

return Window
