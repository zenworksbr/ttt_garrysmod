---- Scoreboard player score row, based on sandbox version
-- ARQUIVO COM DIVERSAS MODIFICAÇÕES

include("sb_info.lua")


local GetTranslation = LANG.GetTranslation
local GetPTranslation = LANG.GetParamTranslation

-- parâmetros para utilização do slider de volume de voz de jogadores
local sliderOpen = false

-- lista de jogadores com chat de texto silenciado
local mutedPlayers = {}

SB_ROW_HEIGHT = 24 --16

local PANEL = {}

function PANEL:Init()
   -- cannot create info card until player state is known
   self.info = nil

   self.open = false

   self.cols = {}
   self:AddColumn( GetTranslation("sb_ping"), function(ply) return ply:Ping() end )
   self:AddColumn( GetTranslation("sb_deaths"), function(ply) return ply:Deaths() end )
   self:AddColumn( GetTranslation("sb_score"), function(ply) return ply:Frags() end )

   if KARMA.IsEnabled() then
      self:AddColumn( GetTranslation("sb_karma"), function(ply) return math.Round(ply:GetBaseKarma()) end )
   end

   -- Let hooks add their custom columns
   hook.Call("TTTScoreboardColumns", nil, self)

   for _, c in ipairs(self.cols) do
      c:SetMouseInputEnabled(false)
   end

   self.tag = vgui.Create("DLabel", self)
   self.tag:SetText("")
   self.tag:SetMouseInputEnabled(false)

   self.sresult = vgui.Create("DImage", self)
   self.sresult:SetSize(16,16)
   self.sresult:SetMouseInputEnabled(false)

   self.avatar = vgui.Create( "AvatarImage", self )
   self.avatar:SetSize(SB_ROW_HEIGHT, SB_ROW_HEIGHT)
   self.avatar:SetMouseInputEnabled(false)

   self.nick = vgui.Create("DLabel", self)
   self.nick:SetMouseInputEnabled(false)

   self.voice = vgui.Create("DImageButton", self)
   self.voice:SetSize(16,16)

   self:SetCursor( "hand" )
end

function PANEL:AddColumn( label, func, width, _, _ )
   local lbl = vgui.Create( "DLabel", self )
   lbl.GetPlayerText = func
   lbl.IsHeading = false
   lbl.Width = width or 50 -- Retain compatibility with existing code

   table.insert( self.cols, lbl )
   return lbl
end

-- Mirror sb_main, of which it and this file both call using the
--    TTTScoreboardColumns hook, but it is useless in this file
-- Exists only so the hook wont return an error if it tries to
--    use the AddFakeColumn function of `sb_main`, which would
--    cause this file to raise a `function not found` error or others
function PANEL:AddFakeColumn() end

local namecolor = {
   default = COLOR_WHITE,
   admin = Color(220, 180, 0, 255),
   dev = Color(100, 240, 105, 255)
}

local rolecolor = {
   default = Color(0, 0, 0, 0),
   traitor = Color(255, 0, 0, 30),
   detective = Color(0, 0, 255, 30)
}

function GM:TTTScoreboardColorForPlayer(ply)
   if not IsValid(ply) then return namecolor.default end

   -- sim, isto está HORRÍVEL. Eu sei.
   if COLORED_NAME_USERGROUPS[ply:SteamID()] != nil then
      return COLORED_NAME_USERGROUPS[ply:SteamID()]
   elseif ply:IsAdmin() or SB_BASE_PERMS[ply:GetUserGroup()] or SB_MOD_PERMS[ply:GetUserGroup()] or SB_FULL_PERMS[ply:GetUserGroup()] and GetGlobalBool("ttt_highlight_admins", true) then
      return namecolor.admin
   end
   return namecolor.default
end

function GM:TTTScoreboardRowColorForPlayer(ply)
   if not IsValid(ply) then return rolecolor.default end

   if ply:IsTraitor() then
      return rolecolor.traitor
   elseif ply:IsDetective() then
      return rolecolor.detective
   end

   return rolecolor.default
end

local function ColorForPlayer(ply)
   if IsValid(ply) then
      local c = hook.Call("TTTScoreboardColorForPlayer", GAMEMODE, ply)

      -- verify that we got a proper color
      if c and istable(c) and c.r and c.b and c.g and c.a then
         return c
      else
         ErrorNoHalt("TTTScoreboardColorForPlayer hook returned something that isn't a color!\n")
      end
   end
   return namecolor.default
end

function PANEL:Paint(width, height)
   if not IsValid(self.Player) then return end

--   if ( self.Player:GetFriendStatus() == "friend" ) then
--      color = Color( 236, 181, 113, 255 )
--   end

   local ply = self.Player

   local c = hook.Call("TTTScoreboardRowColorForPlayer", GAMEMODE, ply)

   surface.SetDrawColor(c)
   surface.DrawRect(0, 0, width, SB_ROW_HEIGHT)


   if ply == LocalPlayer() then
      surface.SetDrawColor( 200, 200, 200, math.Clamp(math.sin(RealTime() * 2) * 50, 0, 100))
      surface.DrawRect(0, 0, width, SB_ROW_HEIGHT )
   end

   return true
end


function PANEL:SetPlayer(ply)
   self.Player = ply
   self.avatar:SetPlayer(ply)

   if not self.info then
      local g = ScoreGroup(ply)
      if g == GROUP_TERROR and ply != LocalPlayer() then
         self.info = vgui.Create("TTTScorePlayerInfoTags", self)
         self.info:SetPlayer(ply)

         self:InvalidateLayout()
      elseif g == GROUP_FOUND or g == GROUP_NOTFOUND then
         self.info = vgui.Create("TTTScorePlayerInfoSearch", self)
         self.info:SetPlayer(ply)
         self:InvalidateLayout()
      end
   else
      self.info:SetPlayer(ply)

      self:InvalidateLayout()
   end

   self.voice.DoClick = function()
      if IsValid(ply) and ply != LocalPlayer() and !sliderOpen then
         self:ShowMicVolumeSlider()
         sliderOpen = true
      end
   end

   self:UpdatePlayerData()
end

function PANEL:GetPlayer() return self.Player end

function PANEL:UpdatePlayerData()
   if not IsValid(self.Player) then return end

   local ply = self.Player
   for i=1,#self.cols do
       -- Set text from function, passing the label along so stuff like text
       -- color can be changed
      self.cols[i]:SetText( self.cols[i].GetPlayerText(ply, self.cols[i]) )
   end

   self.nick:SetText(ply:Nick())
   self.nick:SizeToContents()
   self.nick:SetTextColor(ColorForPlayer(ply))

   local ptag = ply.sb_tag
   if ScoreGroup(ply) != GROUP_TERROR then
      ptag = nil
   end

   self.tag:SetText(ptag and GetTranslation(ptag.txt) or "")
   self.tag:SetTextColor(ptag and ptag.color or COLOR_WHITE)

   self.sresult:SetVisible(ply.search_result != nil)

   -- more blue if a detective searched them
   if ply.search_result and (LocalPlayer():IsDetective() or (not ply.search_result.show)) then
      self.sresult:SetImageColor(Color(200, 200, 255))
   end

   -- cols are likely to need re-centering
   self:LayoutColumns()

   if self.info then
      self.info:UpdatePlayerData()
   end

   if self.Player != LocalPlayer() then
      local muted = self.Player:IsMuted() 
      self.voice:SetImage(muted and "icon16/sound_mute.png" or "icon16/sound.png")
   else
      self.voice:Hide()
   end
end

function PANEL:ApplySchemeSettings()
   for k,v in pairs(self.cols) do
      v:SetFont("treb_small")
      v:SetTextColor(COLOR_WHITE)
   end

   self.nick:SetFont("treb_small")
   self.nick:SetTextColor(ColorForPlayer(self.Player))

   local ptag = self.Player and self.Player.sb_tag
   self.tag:SetTextColor(ptag and ptag.color or COLOR_WHITE)
   self.tag:SetFont("treb_small")

   self.sresult:SetImage("icon16/magnifier.png")
   self.sresult:SetImageColor(Color(170, 170, 170, 150))
end

function PANEL:LayoutColumns()
   local cx = self:GetWide()
   for k,v in ipairs(self.cols) do
      v:SizeToContents()
      cx = cx - v.Width
      v:SetPos(cx - v:GetWide()/2, (SB_ROW_HEIGHT - v:GetTall()) / 2)
   end

   self.tag:SizeToContents()
   cx = cx - 90
   self.tag:SetPos(cx - self.tag:GetWide()/2, (SB_ROW_HEIGHT - self.tag:GetTall()) / 2)

   self.sresult:SetPos(cx - 8, (SB_ROW_HEIGHT - 16) / 2)
end

function PANEL:PerformLayout()
   self.avatar:SetPos(0,0)
   self.avatar:SetSize(SB_ROW_HEIGHT,SB_ROW_HEIGHT)

   local fw = sboard_panel.ply_frame:GetWide()
   self:SetWide( sboard_panel.ply_frame.scroll.Enabled and fw-16 or fw )

   if not self.open then
      self:SetSize(self:GetWide(), SB_ROW_HEIGHT)

      if self.info then self.info:SetVisible(false) end
   elseif self.info then
      self:SetSize(self:GetWide(), 100 + SB_ROW_HEIGHT)

      self.info:SetVisible(true)
      self.info:SetPos(5, SB_ROW_HEIGHT + 5)
      self.info:SetSize(self:GetWide(), 100)
      self.info:PerformLayout()

      self:SetSize(self:GetWide(), SB_ROW_HEIGHT + self.info:GetTall())
   end

   self.nick:SizeToContents()

   self.nick:SetPos(SB_ROW_HEIGHT + 10, (SB_ROW_HEIGHT - self.nick:GetTall()) / 2)

   self:LayoutColumns()

   self.voice:SetVisible(not self.open)
   self.voice:SetSize(16, 16)
   self.voice:DockMargin(4, 4, 4, 4)
   self.voice:Dock(RIGHT)
end

function PANEL:DoClick(x, y)
   self:SetOpen(not self.open)
end

function PANEL:SetOpen(o)
   if self.open then
      surface.PlaySound("ui/buttonclickrelease.wav")
   else
      surface.PlaySound("ui/buttonclick.wav")
   end

   self.open = o

   self:PerformLayout()
   self:GetParent():PerformLayout()
   sboard_panel:PerformLayout()
end

function PANEL:DoRightClick()
   local menu = DermaMenu()
   menu.Player = self:GetPlayer()
   local close = hook.Call( "TTTScoreboardMenu", nil, menu )
   
   if close then menu:Remove() return end
   menu:Open()
   
   -- menu de interação com comandos diretos
   -- para serem utilizados por staffs
   local menu = DermaMenu()   
   menu.Player = self:GetPlayer()   
   local close = hook.Call( "TTTScoreboardMenu", nil, menu )   
   
   if close then menu:Remove() return end   
   menu:Open()   	
   local ply = self.Player
   
   surface.PlaySound("buttons/button9.wav")			
   local options = DermaMenu()
   options:AddOption("Cargo: " .. ply:GetUserGroup(), function() -- sb_roles[ply:GetUserGroup()].name -- atlaschat.ranks[ply:GetUserGroup()].tag
      if !LocalPlayer() then return end
      SetClipboardText(ply:GetUserGroup())
      chat.AddText(Color(151, 211, 255), "Cargo '", Color(0, 255, 0), ply:GetUserGroup(), Color(151, 211, 255), "', de ", Color(0, 255, 0), ply:Nick(), Color(151, 211, 255), " copiado com sucesso!")
      surface.PlaySound("buttons/button9.wav") 
   end):SetImage(atlaschat.ranks[ply:GetUserGroup()].icon) -- atlaschat.ranks[ply:GetUserGroup()].icon) -- sb_roles[ply:GetUserGroup()].icon)
   options:AddSpacer()
   options:AddOption("Copiar Nome", function() 
      if !LocalPlayer() then return end
      SetClipboardText(ply:Nick())
      chat.AddText("'", Color(0, 255, 0), ply:Nick(), Color(151, 211, 255), "' copiado com sucesso!")
      surface.PlaySound("buttons/button9.wav") 
   end):SetImage("icon16/user_edit.png")			
   options:AddOption("Copiar SteamID", function() 
      if !LocalPlayer() then return end
      SetClipboardText(ply:SteamID())
      chat.AddText("'", Color(0, 255, 0), ply:SteamID(), Color(151, 211, 255), "', de ", Color(0, 255, 0), ply:Nick(), Color(151, 211, 255), " copiado com sucesso!")
      surface.PlaySound("buttons/button9.wav") 
   end):SetImage("icon16/tag_blue.png")			
   options:AddSpacer()
   
   options:AddOption("Abrir Perfil Steam", function() 
   ply:ShowProfile() surface.PlaySound("buttons/button9.wav") 
   end):SetImage("icon16/world.png")			
   options:AddSpacer()
   options:Open()
   
   if (SB_VIP_PERMS[LocalPlayer():GetUserGroup()] and LocalPlayer() == ply) or SB_MOD_PERMS[LocalPlayer():GetUserGroup()] then
      local superop,supimg = options:AddSubMenu("Cargos")					
      supimg:SetImage("icon16/group_edit.png")
   
      superop:AddOption("Remover rank", function()
         RunConsoleCommand("ulx","removerank",ply:Nick())
         surface.PlaySound("buttons/button9.wav")
      end):SetImage("icon16/html_delete.png")

      if (SB_FULL_PERMS[LocalPlayer():GetUserGroup()]) then

         superop:AddSpacer()
         superop:AddOption("Dar Temp. Helper", function()
            RunConsoleCommand("ulx","adduser",ply:Nick(),"temp_helper")
            surface.PlaySound("buttons/button9.wav")
         end):SetImage(atlaschat.ranks["temp_helper"].icon)

         superop:AddOption("Dar cargo Ajudante", function()
            RunConsoleCommand("ulx","adduser",ply:Nick(),"helper")
            surface.PlaySound("buttons/button9.wav")
         end):SetImage(atlaschat.ranks["helper"].icon)

         superop:AddOption("Dar cargo Doador", function()
            RunConsoleCommand("ulx","adduser",ply:Nick(),"donator")
            surface.PlaySound("buttons/button9.wav")
         end):SetImage(atlaschat.ranks["donator"].icon)

         superop:AddOption("Dar cargo Moderador", function()
            RunConsoleCommand("ulx","adduser",ply:Nick(),"operator")
            surface.PlaySound("buttons/button9.wav")
         end):SetImage(atlaschat.ranks["operator"].icon)

         superop:AddOption("Dar cargo Mod Doador", function()
            RunConsoleCommand("ulx","adduser",ply:Nick(),"operator_donator")
            surface.PlaySound("buttons/button9.wav")
         end):SetImage(atlaschat.ranks["operator_donator"].icon)

         superop:AddOption("Dar cargo Adminstrador", function()
            RunConsoleCommand("ulx","adduser",ply:Nick(),"admin")
            surface.PlaySound("buttons/button9.wav")
         end):SetImage(atlaschat.ranks["admin"].icon)

         superop:AddOption("Dar cargo Admin Doador", function()
            RunConsoleCommand("ulx","adduser",ply:Nick(),"admin_donator")
            surface.PlaySound("buttons/button9.wav")
         end):SetImage(atlaschat.ranks["admin_donator"].icon)

         superop:AddOption("Dar cargo Admin Chefe", function()
            RunConsoleCommand("ulx","adduser",ply:Nick(),"superadmin")
            surface.PlaySound("buttons/button9.wav")
         end):SetImage(atlaschat.ranks["superadmin"].icon)

         superop:AddSpacer()
         superop:AddOption("Remover cargo", function()
            RunConsoleCommand("ulx","removeuser",ply:Nick())
            surface.PlaySound("buttons/button9.wav")
         end):SetImage("icon16/group_delete.png")

      end

      superop:AddSpacer()

   end

   if SB_BASE_PERMS[LocalPlayer():GetUserGroup()] then
      
      local adminop,subimg = options:AddSubMenu("Administrar")					
      subimg:SetImage("icon16/lorry.png")
      
      adminop:AddOption("Slay agora", function() 
         RunConsoleCommand("ulx","slay",ply:Nick()) 
         surface.PlaySound("buttons/button9.wav") 
      end):SetImage("icon16/cut_red.png") 

      if SB_MOD_PERMS[LocalPlayer():GetUserGroup()] then

         adminop:AddOption("Reviver", function() 
            RunConsoleCommand("ulx","respawn",ply:Nick()) 
            surface.PlaySound("buttons/button9.wav") 
         end):SetImage("icon16/rainbow.png")

      end

      adminop:AddSpacer()
      adminop:AddOption("Teleportar", function() 
         RunConsoleCommand("ulx","teleport",ply:Nick())
         surface.PlaySound("buttons/button9.wav") 
      end):SetImage("icon16/wand.png")	

      adminop:AddOption("Trazer", function() 
         RunConsoleCommand("ulx","bring",ply:Nick())
         surface.PlaySound("buttons/button9.wav") 
      end):SetImage("icon16/wand.png")	

      adminop:AddSpacer()      
      adminop:AddOption("Expulsar", function() 
         RunConsoleCommand("ulx","kick",ply:Nick(),"Você foi expulso do servidor")
         surface.PlaySound("buttons/button9.wav") 
      end):SetImage("icon16/delete.png")	
      
      adminop:AddSpacer()					
      adminop:AddOption("Mutar", function() 
         RunConsoleCommand("ulx","mute",ply:Nick()) 
         surface.PlaySound("buttons/button9.wav") 
      end):SetImage("icon16/keyboard_delete.png")					
      
      adminop:AddOption("Dar gag", function() 
         RunConsoleCommand("ulx","gag",ply:Nick()) 
         surface.PlaySound("buttons/button9.wav") 
      end):SetImage("icon16/sound_mute.png")
      
      adminop:AddSpacer()					
      adminop:AddOption("Tirar mute", function() 
         RunConsoleCommand("ulx","unmute",ply:Nick()) 
         surface.PlaySound("buttons/button9.wav") 
      end):SetImage("icon16/keyboard_add.png")					
      
      adminop:AddOption("Tirar gag", function() 
         RunConsoleCommand("ulx","ungag",ply:Nick()) 
         surface.PlaySound("buttons/button9.wav") 
      end):SetImage("icon16/sound.png")
      
      if SB_MOD_PERMS[LocalPlayer():GetUserGroup()] then

         local funop, funimg = options:AddSubMenu("Diversão")
         funimg:SetImage("icon16/bricks.png")

         local tttop, tttimg = options:AddSubMenu("TTT")
         tttimg:SetImage("icon16/exclamation.png")

         tttop:AddOption("Forçar Espectador", function()
            RunConsoleCommand("ulx","fspec",ply:Nick()) 
            surface.PlaySound("buttons/button9.wav") 
         end):SetImage("icon16/camera.png")	

         tttop:AddOption("Tirar de Espectador", function()
            RunConsoleCommand("ulx","unspec",ply:Nick()) 
            surface.PlaySound("buttons/button9.wav") 
         end):SetImage("icon16/camera_delete.png")	

         tttop:AddSpacer()
         tttop:AddOption("Desabilitar Detetive", function()
            RunConsoleCommand("ulx", "undetective", ply:Nick())
            chat.AddText(Color(151, 211, 255), "Jogador '", Color(0, 255, 0), ply:Nick(), Color(151, 211, 255), "' agora estará com o ", Color(0, 255, 0), "Detetive desativado", Color(151, 211, 255), "!")
            surface.PlaySound("buttons/button9.wav") 
         end):SetImage("icon16/award_star_delete.png")

         tttop:AddOption("Habilitar Detetive", function()
            RunConsoleCommand("ulx", "forcedetective", ply:Nick())
            chat.AddText(Color(151, 211, 255), "Jogador '", Color(0, 255, 0), ply:Nick(), Color(151, 211, 255), "' agora estará com o ", Color(0, 255, 0), "Detetive desativado", Color(151, 211, 255), "!")
            surface.PlaySound("buttons/button9.wav") 
         end):SetImage("icon16/award_star_add.png")

         adminop:AddSpacer()			
         adminop:AddOption("Assistir", function() 
            RunConsoleCommand("ulx","spectate",ply:Nick()) 
            surface.PlaySound("buttons/button9.wav") 
         end):SetImage("icon16/zoom.png")	

         adminop:AddSpacer()

         funop:AddSpacer()
         funop:AddOption("Explodir", function()
            RunConsoleCommand("ulx","explode",ply:Nick())
            surface.PlaySound("buttons/button9.wav")
         end):SetImage("icon16/asterisk_orange.png")

         funop:AddOption("Launch", function()
            RunConsoleCommand("ulx","launch",ply:Nick())
            surface.PlaySound("buttons/button9.wav")
         end):SetImage("icon16/sport_football.png")

         if SB_FULL_PERMS[LocalPlayer():GetUserGroup()] then

            funop:AddSpacer()
            funop:AddOption("Crash", function()
               RunConsoleCommand("ulx","crash",ply:Nick())
               surface.PlaySound("buttons/button9.wav")
            end):SetImage("icon16/cancel.png")

            tttop:AddSpacer()
            tttop:AddOption("Forçar Traidor Agora", function()
               RunConsoleCommand("ulx","force",ply:Nick(),"traitor")
               surface.PlaySound("buttons/button9.wav")
            end):SetImage("icon16/flag_red.png")

            tttop:AddOption("Forçar Detetive Agora", function()
               RunConsoleCommand("ulx","force",ply:Nick(),"detective")
               surface.PlaySound("buttons/button9.wav")
            end):SetImage("icon16/flag_blue.png")

            tttop:AddOption("Forçar Inocente Agora", function()
               RunConsoleCommand("ulx","force",ply:Nick(),"innocent")
               surface.PlaySound("buttons/button9.wav")
            end):SetImage("icon16/flag_green.png")

            tttop:AddSpacer()
            tttop:AddOption("Traidor Próxima Rodada", function()
               RunConsoleCommand("ulx","forcenr",ply:Nick(),"traitor")
               surface.PlaySound("buttons/button9.wav")  
            end):SetImage("icon16/flag_red.png")

            tttop:AddOption("Detetive Próxima Rodada", function()
               RunConsoleCommand("ulx","forcenr",ply:Nick(),"detective")
               surface.PlaySound("buttons/button9.wav")
            end):SetImage("icon16/flag_blue.png")

            tttop:AddSpacer()

      	end
            
         adminop:AddSpacer()	
         funop:AddSpacer()			
         options:Open()
         end		
      end
end


function PANEL:ShowMicVolumeSlider()
   local width = 300
   local height = 50
   local padding = 10

   local sliderHeight = 16
   local sliderDisplayHeight = 8

   local x = math.max(gui.MouseX() - width, 0)
   local y = math.min(gui.MouseY(), ScrH() - height)

   local currentPlayerVolume = self:GetPlayer():GetVoiceVolumeScale()
   currentPlayerVolume = currentPlayerVolume != nil and currentPlayerVolume or 1

   -- Frame for the slider
   local frame = vgui.Create("DFrame")
   frame:SetPos(x, y)
   frame:SetSize(width, height)
   frame:MakePopup()
   frame:SetTitle("")
   frame:ShowCloseButton(false)
   frame:SetDraggable(false)
   frame:SetSizable(false)
   frame.Paint = function(self, w, h)
      draw.RoundedBox(5, 0, 0, w, h, Color(24, 25, 28, 255))
   end

   -- Automatically close after 10 seconds (something may have gone wrong)
   timer.Simple(10, function()
      if IsValid(frame) then
         frame:Close()
         sliderOpen = false
      end
   end)


   -- "Player volume"
   local label = vgui.Create("DLabel", frame)
   label:SetPos(padding, padding)
   label:SetFont("cool_small")
   label:SetSize(width - padding * 2, 20)
   label:SetColor(Color(255, 255, 255, 255))
   label:SetText(LANG.GetTranslation("sb_playervolume"))

   local chat = vgui.Create("DImageButton", frame)
   chat:SetImage(table.HasValue( mutedPlayers, self:GetPlayer():SteamID() ) and "icon16/comment_delete.png" or "icon16/comment.png")

   chat.DoClick = function ()
      if table.HasValue( mutedPlayers, self:GetPlayer():SteamID() ) then
         table.RemoveByValue( mutedPlayers, self:GetPlayer():SteamID() )
         chat:SetImage("icon16/comment.png")
      else
         table.insert(mutedPlayers, self:GetPlayer():SteamID())
         chat:SetImage("icon16/comment_delete.png")
      end
   end
   chat:Dock(RIGHT)
   chat:SetSize(16,16)

   -- Slider
   local slider = vgui.Create("DSlider", frame)
   slider:SetHeight(sliderHeight)
   slider:Dock(TOP)
   slider:DockMargin(padding, 0, padding, 0)
   slider:SetSlideX(currentPlayerVolume)
   slider:SetLockY(0.5)
   slider.TranslateValues = function(slider, x, y)
      if IsValid(self:GetPlayer()) then 
         self:GetPlayer():SetVoiceVolumeScale(x)
         if (x == 0) then
            self:GetPlayer():SetMuted(true)
         else 
            self:GetPlayer():SetMuted(false)
         end
       end
      return x, y
   end

   -- Close the slider panel once the player has selected a volume
   slider.OnMouseReleased = function(panel, mcode) 
      if (IsValid(frame)) then
         frame:Close()
         sliderOpen = false
      end
   end
   slider.Knob.OnMouseReleased = function(panel, mcode) 
      if (IsValid(frame)) then
         frame:Close()
         sliderOpen = false
      end
   end
   hook.Add( "ScoreboardHide", "Scoreboard_CloseVolumePanelForSB", function()
      if (IsValid(frame)) then
         frame:Close()
         sliderOpen = false
      end
    end )


   -- Slider rendering
   -- Render slider bar
   slider.Paint = function(self, w, h)
      local volumePercent = slider:GetSlideX()

      -- Filled in box
      draw.RoundedBox(5, 0, sliderDisplayHeight / 2, w * volumePercent, sliderDisplayHeight, Color(200, 46, 46, 255))

      -- Grey box
      draw.RoundedBox(5, w * volumePercent, sliderDisplayHeight / 2, w * (1 - volumePercent), sliderDisplayHeight, Color(79, 84, 92, 255))
   end

   -- Render slider "knob" & text
   slider.Knob.Paint = function(self, w, h)
      if slider:IsEditing() then
         local textValue = math.Round(slider:GetSlideX() * 100) .. "%"
         local textPadding = 5

         -- The position of the text and size of rounded box are not relative to the text size. May cause problems if font size changes
         draw.RoundedBox(
            5, -- Radius
            -sliderHeight * 0.5 - textPadding, -- X
            -25, -- Y
            sliderHeight * 2 + textPadding * 2, -- Width
            sliderHeight + textPadding * 2, -- Height
            Color(52, 54, 57, 255)
         )
         draw.DrawText(textValue, "cool_small", sliderHeight / 2, -20, Color(255, 255, 255, 255), TEXT_ALIGN_CENTER)
      end
      
      draw.RoundedBox(100, 0, 0, sliderHeight, sliderHeight, Color(255, 255, 255, 255))
   end
end

vgui.Register( "TTTScorePlayerRow", PANEL, "DButton" )
