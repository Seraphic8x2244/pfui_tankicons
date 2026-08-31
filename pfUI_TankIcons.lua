-- pfUI_TankIcons
-- Displays pfUI's existing tank-role assignments on pfUI group/raid frames
-- and on the Blizzard Raid tab. Vanilla 1.12.1 / Lua 5.0.

local MODULE = "tankicons"
local ICON = "Interface\\Icons\\INV_Shield_06"
local ICON_SIZE = 12
local RAIDTAB_ICON_SIZE = 11

local UNIT_POINTS = {
  TOPLEFT     = { "TOPLEFT",     1, -1 },
  TOP         = { "TOP",         0, -1 },
  TOPRIGHT    = { "TOPRIGHT",   -1, -1 },
  LEFT        = { "LEFT",        1,  0 },
  CENTER      = { "CENTER",      0,  0 },
  RIGHT       = { "RIGHT",      -1,  0 },
  BOTTOMLEFT  = { "BOTTOMLEFT",  1,  1 },
  BOTTOM      = { "BOTTOM",      0,  1 },
  BOTTOMRIGHT = { "BOTTOMRIGHT",-1,  1 },
}

local RAIDTAB_POINTS = {
  LEFT   = { "LEFT",   2, 0 },
  CENTER = { "CENTER", 0, 0 },
  RIGHT  = { "RIGHT", -2, 0 },
}

local function RegisterAddon()
  if not pfUI or not pfUI.RegisterModule then return end
  if pfUI.module and pfUI.module[MODULE] then return end

  -- Add our defaults to pfUI's own configuration database.
  -- No addon-specific SavedVariables are required.
  if pfUI.UpdateConfig then
    pfUI:UpdateConfig(MODULE, nil, "raidtab_visible", "1")
    pfUI:UpdateConfig(MODULE, nil, "raidtab_justify", "RIGHT")
    pfUI:UpdateConfig(MODULE, nil, "groupframe_visible", "1")
    pfUI:UpdateConfig(MODULE, nil, "groupframe_justify", "TOPRIGHT")
    pfUI:UpdateConfig(MODULE, nil, "raidframe_visible", "1")
    pfUI:UpdateConfig(MODULE, nil, "raidframe_justify", "TOPRIGHT")
  end

  pfUI:RegisterModule(MODULE, "vanilla", function()
    local C = pfUI_config
    local tracked = {}
    local trackedCount = 0
    local raidPanelHooked = nil
    local guiRegistered = nil

    local function Config()
      C[MODULE] = C[MODULE] or {}
      return C[MODULE]
    end

    local function TankRoles()
      if pfUI and pfUI.uf and pfUI.uf.raid then
        return pfUI.uf.raid.tankrole
      end
    end

    local function IsTankName(name)
      local roles = TankRoles()
      return name and roles and roles[name] and true or false
    end

    local function UnitFromFrame(frame)
      if not frame or not frame.label then return nil end
      return tostring(frame.label) .. tostring(frame.id or "")
    end

    local function FrameKind(frame)
      if not frame then return nil end

      -- pfUI's stable internal identities are the primary discriminator.
      -- Group frames use fname Group0..Group4; raid frames use Raid1..Raid40.
      if frame.fname then
        local fname = tostring(frame.fname)
        if string.sub(fname, 1, 5) == "Group" then return "group" end
        if string.sub(fname, 1, 4) == "Raid" then return "raid" end
      end

      -- Compatibility fallback for forks retaining Shagu's global frame names.
      local name = frame.GetName and frame:GetName()
      if name then
        if string.sub(name, 1, 6) == "pfRaid" then return "raid" end
        if string.sub(name, 1, 7) == "pfGroup" then return "group" end
      end

      -- Last-resort fallback for forks with renamed frames.
      if frame.fname then
        local fname = string.lower(tostring(frame.fname))
        if string.find(fname, "raid") then return "raid" end
        if string.find(fname, "group") then return "group" end
      end

      return nil
    end

    local function PlaceIcon(icon, parent, pointData)
      if not icon or not parent or not pointData then return end
      icon:ClearAllPoints()
      icon:SetPoint(pointData[1], parent, pointData[1], pointData[2], pointData[3])
    end

    local function EnsurePfUIIcon(frame)
      if not frame or frame.pfTankIcon then return end

      local kind = FrameKind(frame)
      if not kind then return end

      -- A texture placed directly on the unitframe parent can be covered by
      -- pfUI's child health/power frames. Give the tank marker its own child
      -- frame at a deliberately higher frame level, then draw the texture in it.
      local holder = CreateFrame("Frame", nil, frame)
      holder:SetWidth(ICON_SIZE)
      holder:SetHeight(ICON_SIZE)
      holder:SetFrameLevel(frame:GetFrameLevel() + 20)

      local icon = holder:CreateTexture(nil, "OVERLAY")
      icon:SetTexture(ICON)
      icon:SetPoint("TOPLEFT", holder, "TOPLEFT", 0, 0)
      icon:SetPoint("BOTTOMRIGHT", holder, "BOTTOMRIGHT", 0, 0)
      icon:SetTexCoord(.08, .92, .08, .92)
      holder:Hide()

      frame.pfTankIcon = holder
      frame.pfTankIconTexture = icon
      frame.pfTankIconKind = kind

      trackedCount = trackedCount + 1
      tracked[trackedCount] = frame
    end

    local function UpdatePfUIFrame(frame)
      if not frame then return end

      EnsurePfUIIcon(frame)
      if not frame.pfTankIcon then return end

      local cfg = Config()
      local kind = frame.pfTankIconKind or FrameKind(frame)
      local visible, justify

      if kind == "raid" then
        visible = cfg.raidframe_visible == "1"
        justify = cfg.raidframe_justify or "TOPRIGHT"
      elseif kind == "group" then
        visible = cfg.groupframe_visible == "1"
        justify = cfg.groupframe_justify or "TOPRIGHT"
      else
        frame.pfTankIcon:Hide()
        return
      end

      PlaceIcon(frame.pfTankIcon, frame, UNIT_POINTS[justify] or UNIT_POINTS.TOPRIGHT)

      local unit = UnitFromFrame(frame)
      local name = unit and UnitName(unit)

      if visible and IsTankName(name) then
        frame.pfTankIcon:Show()
      else
        frame.pfTankIcon:Hide()
      end
    end

    local function DiscoverPfUIFrames()
      local i, frame

      -- pfUI registers every unitframe in this array when CreateUnitFrame runs.
      -- This is the authoritative source and works even if a fork changes globals.
      if pfUI.uf and pfUI.uf.frames then
        for i = 1, table.getn(pfUI.uf.frames) do
          frame = pfUI.uf.frames[i]
          if frame then EnsurePfUIIcon(frame) end
        end
      end

      -- Compatibility fallback for older/forked builds that may not populate
      -- pfUI.uf.frames in the same way.
      for i = 0, 4 do
        frame = getglobal("pfGroup" .. i)
        if frame then EnsurePfUIIcon(frame) end
      end

      for i = 1, 40 do
        frame = getglobal("pfRaid" .. i)
        if frame then EnsurePfUIIcon(frame) end
      end
    end

    local function UpdateTrackedFrames()
      local i
      DiscoverPfUIFrames()
      for i = 1, trackedCount do
        UpdatePfUIFrame(tracked[i])
      end
    end

    local function EnsureRaidButtonIcon(button)
      if not button or button.pfTankIcon then return end

      local icon = button:CreateTexture(nil, "OVERLAY")
      icon:SetTexture(ICON)
      icon:SetWidth(RAIDTAB_ICON_SIZE)
      icon:SetHeight(RAIDTAB_ICON_SIZE)
      icon:SetTexCoord(.08, .92, .08, .92)
      icon:Hide()

      button.pfTankIcon = icon
    end

    local function UpdateRaidPanel()
      local cfg = Config()
      local point = RAIDTAB_POINTS[cfg.raidtab_justify or "RIGHT"] or RAIDTAB_POINTS.RIGHT
      local enabled = cfg.raidtab_visible == "1"
      local i, button, name

      for i = 1, 40 do
        button = getglobal("RaidGroupButton" .. i)
        if button then
          EnsureRaidButtonIcon(button)
          PlaceIcon(button.pfTankIcon, button, point)

          name = button.name
          if not name then name = UnitName("raid" .. i) end

          if enabled and IsTankName(name) then
            button.pfTankIcon:Show()
          else
            button.pfTankIcon:Hide()
          end
        end
      end
    end

    local function UpdateAll()
      UpdateTrackedFrames()
      UpdateRaidPanel()
    end

    local function RegisterGUI()
      if guiRegistered then return end
      if not pfUI.gui or not pfUI.gui.CreateGUIEntry or not pfUI.gui.CreateConfig then return end

      local CreateGUIEntry = pfUI.gui.CreateGUIEntry
      local CreateConfig = pfUI.gui.CreateConfig
      local cfg = Config()

      local raidTabJustify = {
        "LEFT:Left",
        "CENTER:Centre",
        "RIGHT:Right",
      }

      local frameJustify = {
        "TOPLEFT:Top Left",
        "TOP:Top",
        "TOPRIGHT:Top Right",
        "LEFT:Left",
        "CENTER:Centre",
        "RIGHT:Right",
        "BOTTOMLEFT:Bottom Left",
        "BOTTOM:Bottom",
        "BOTTOMRIGHT:Bottom Right",
      }

      CreateGUIEntry("Thirdparty", "TankIcons", function()
        CreateConfig(UpdateAll, "RaidTab Visibility", cfg, "raidtab_visible", "checkbox")
        CreateConfig(UpdateAll, "RaidTab Justification", cfg, "raidtab_justify", "dropdown", raidTabJustify)

        CreateConfig(UpdateAll, "GroupFrame Visibility", cfg, "groupframe_visible", "checkbox")
        CreateConfig(UpdateAll, "GroupFrame Justification", cfg, "groupframe_justify", "dropdown", frameJustify)

        CreateConfig(UpdateAll, "RaidFrame Visibility", cfg, "raidframe_visible", "checkbox")
        CreateConfig(UpdateAll, "RaidFrame Justification", cfg, "raidframe_justify", "dropdown", frameJustify)
      end)

      guiRegistered = true
    end

    -- Every pfUI unitframe passes through RefreshUnit. Only group/raid frames
    -- are accepted by EnsurePfUIIcon, so player/target/etc remain untouched.
    if pfUI.uf and pfUI.uf.RefreshUnit and hooksecurefunc then
      hooksecurefunc(pfUI.uf, "RefreshUnit", function(uf, frame)
        UpdatePfUIFrame(frame)
      end)
    end

    local function HookRaidPanel()
      if raidPanelHooked then return end
      if RaidGroupFrame_Update and hooksecurefunc then
        hooksecurefunc("RaidGroupFrame_Update", UpdateRaidPanel)
        raidPanelHooked = true
        UpdateRaidPanel()
      end
    end

    HookRaidPanel()
    RegisterGUI()

    -- pfUI also post-hooks UnitPopup_OnClick to change tankrole. Depending on
    -- module registration order, our post-hook can run before pfUI's tank hook.
    -- Queue a one-frame, one-shot refresh so every popup hook has finished first.
    local deferred = CreateFrame("Frame")
    deferred:Hide()
    deferred:SetScript("OnUpdate", function()
      this:Hide()
      UpdateAll()
    end)

    local function QueueUpdateAll()
      deferred:Show()
    end

    if UnitPopup_OnClick and hooksecurefunc then
      hooksecurefunc("UnitPopup_OnClick", QueueUpdateAll)
    end

    local events = CreateFrame("Frame")
    events:RegisterEvent("PLAYER_ENTERING_WORLD")
    events:RegisterEvent("RAID_ROSTER_UPDATE")
    events:RegisterEvent("PARTY_MEMBERS_CHANGED")
    events:RegisterEvent("PLAYER_TARGET_CHANGED")
    events:RegisterEvent("ADDON_LOADED")
    events:SetScript("OnEvent", function()
      HookRaidPanel()
      RegisterGUI()
      UpdateAll()
    end)

    UpdateAll()
  end)
end

-- No TOC dependency is declared. If pfUI is already available, register now;
-- otherwise wait for it to load. If pfUI is absent, this addon stays inert.
if pfUI and pfUI.RegisterModule then
  RegisterAddon()
else
  local loader = CreateFrame("Frame")
  loader:RegisterEvent("ADDON_LOADED")
  loader:SetScript("OnEvent", function()
    if pfUI and pfUI.RegisterModule then
      RegisterAddon()
      this:UnregisterAllEvents()
    end
  end)
end
