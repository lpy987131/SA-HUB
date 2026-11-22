--[[==========================================================================
	SA HUB · 入口  (SA_HUB.lua)
	------------------------------------------------------------------
	仓库结构：
		SA_HUB.lua          ← 本文件，loadstring 只拉这个
		src/UI.lua          ← 界面框架（窗口 / 控件 / 启动动画）
		src/Features.lua    ← 功能模块（玩家 / 视觉 / 战斗 …）

	使用前把下面 Base 改成你自己的仓库地址：
		https://raw.githubusercontent.com/用户名/仓库名/分支/

	然后执行：
		loadstring(game:HttpGet("https://raw.githubusercontent.com/用户名/仓库名/main/SA_HUB.lua"))()
==========================================================================]]

local CONFIG = {
	Base = "https://raw.githubusercontent.com/USER/REPO/main/",
	Name = "SA",
	FullName = "SA HUB",
	Version = "1.1.0",
	Accent = Color3.fromRGB(46, 158, 255),
	ToggleKey = Enum.KeyCode.RightShift,
	ConfigFile = "SAHub_config.json",
}

local function fetchFile(path)
	local url = CONFIG.Base .. path .. "?v=" .. tostring(CONFIG.Version)
	local ok, body = pcall(function()
		return game:HttpGet(url)
	end)
	if not ok or type(body) ~= "string" or #body < 32 then
		return nil
	end
	return body
end

local function run(source)
	local chunk, err = loadstring(source)
	if not chunk then
		return nil, err
	end
	local ok, result = pcall(chunk)
	if not ok then
		return nil, result
	end
	return result
end

--==========================================================================
-- 1) 界面框架
--==========================================================================
local uiSource = fetchFile("src/UI.lua")
if not uiSource then
	return
end

local UI, uiErr = run(uiSource)
if not UI then
	return
end

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

--==========================================================================
-- 2) 功能模块
--==========================================================================
local features = nil
local featureSource = fetchFile("src/Features.lua")
if featureSource then
	local factory, featureErr = run(featureSource)
	if type(factory) == "function" then
		local ok, result = pcall(factory, Window, UI, {
			fullName = CONFIG.FullName,
			version = CONFIG.Version,
			reload = function()
				pcall(function()
					Window:Destroy()
				end)
				loadstring(game:HttpGet(CONFIG.Base .. "SA_HUB.lua"))()
			end,
		})
		if ok then
			features = result
		end
	end
end

--==========================================================================
-- 3) 收尾
--==========================================================================
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
	if not featureSource then
		Window:Notify({
			Title = "功能模块未加载",
			Text = "检查 src/Features.lua 的地址是否正确",
			Duration = 6,
		})
	end
end)
