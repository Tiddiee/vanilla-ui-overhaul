local function nfReadSettings()
    local raw = file.Read( "vuo_settings.txt", "DATA" )
    local cfg = raw and util.JSONToTable( raw ) or nil
    return istable( cfg ) and cfg or {}
end

local function nfNum( v, lo, hi, def )
    v = tonumber( v )
    if ( not v ) then return def end
    return math.Clamp( math.floor( v + 0.5 ), lo, hi )
end

local function nfFontFile( name )
    if ( not isstring( name ) or name == "" ) then return nil end
    local all = {}
    for _, ext in ipairs( { "*.ttf", "*.otf" } ) do
        local files = file.Find( "materials/vuo_fonts/" .. ext, "GAME" )
        if ( istable( files ) ) then
            for _, fn in ipairs( files ) do all[ #all + 1 ] = fn end
        end
    end
    table.sort( all )
    for _, fn in ipairs( all ) do
        if ( string.StripExtension( fn ) == name and not string.find( fn, "[\"\\]" ) ) then return fn end
    end
    return nil
end

local function nfStyleInjectJS()
    local cfg = nfReadSettings()
    local rgb = "35,135,237"
    if ( isstring( cfg.accentBlue ) and string.match( cfg.accentBlue, "^%s*%d+%s*,%s*%d+%s*,%s*%d+%s*$" ) ) then
        rgb = cfg.accentBlue
    end

    local scale = math.Clamp( tonumber( cfg.ldInfoScale ) or 1, 0.7, 1.6 )

    local css = ":root{--vuo-a:" .. rgb ..
                ";--ld-w:" .. nfNum( cfg.ldWidth, 180, 560, 280 ) .. "px" ..
                ";--ld-bar:" .. nfNum( cfg.ldBar, 3, 16, 7 ) .. "px" ..
                ";--ld-text:" .. nfNum( cfg.ldText, 10, 22, 13 ) .. "px" ..
                ";--ld-info:" .. string.format( "%.2f", scale ) ..
                ";--ld-y:" .. string.format( "%.2f", 1 - nfNum( cfg.ldY, 0, 100, 0 ) / 100 ) ..
                ";--ld-iy:" .. string.format( "%.2f", 1 - nfNum( cfg.ldInfoY, 0, 100, 100 ) / 100 ) .. "}"

    if ( cfg.ldPos == "left" ) then
        css = css .. "#nf_loading{left:24px !important;right:auto !important}"
    elseif ( cfg.ldPos == "center" ) then
        css = css .. "#nf_loading{left:50% !important;right:auto !important;transform:translateX(-50%) translateY(calc(-100% * var(--ld-y,1))) !important}"
    end

    if ( cfg.ldInfoPos == "center" ) then
        css = css .. ".server_info{left:50% !important;transform:translateX(-50%) translateY(calc(-100% * var(--ld-iy,0) * var(--ld-info,1))) scale(var(--ld-info,1)) !important;transform-origin:top center !important}"
    elseif ( cfg.ldInfoPos == "right" ) then
        css = css .. ".server_info{left:auto !important;right:16px !important;transform-origin:top right !important}"
    end

    local font = nfFontFile( cfg.font )
    if ( font ) then
        css = css .. "@font-face{font-family:\"VUOLoadFont\";src:url(\"asset://garrysmod/materials/vuo_fonts/" .. font .. "\");font-display:swap}" ..
                     "body,#nf_loading{font-family:\"VUOLoadFont\",'Roboto','Segoe UI','Noto Sans','Helvetica Neue',Arial,sans-serif !important}"
    end

    return "(function(){var id='vuo_accent_style';var s=document.getElementById(id);" ..
           "if(!s){s=document.createElement('style');s.id=id;(document.head||document.documentElement).appendChild(s);}" ..
           "s.textContent=" .. string.format( "%q", css ) .. ";})();"
end

local PANEL = {}

function PANEL:Init()

	self:SetSize( ScrW(), ScrH() )

end

function PANEL:ShowURL( url, force )

	if ( string.len( url ) < 5 ) then
		return
	end

	if ( IsValid( self.HTML ) ) then
		if ( !force ) then return end

		self:RunJavascript( "if(window.nfLoadServer)nfLoadServer('" .. url:JavascriptSafe() .. "')" )
		self.nfInjected = false
		self.LoadedURL = url
		return
	end

	self:SetSize( ScrW(), ScrH() )

	self.HTML = vgui.Create( "DHTML", self )
	self.HTML:SetSize( ScrW(), ScrH() )
	self.HTML:Dock( FILL )
	self.HTML:SetMouseInputEnabled( true )

	self.HTML.OnChangeTitle = function( _, title )
		if title == "NF_CANCEL" then
			engine.Disconnect()
		end
	end

	self.HTML.OnDocumentReady = function( _, pageurl )
		self.HTML:AddFunction( "lua", "Run", function( param, ... )
			local args = { ... }
			for id, arg in pairs( args ) do
				if ( isstring( arg ) ) then
					args[ id ] = string.format( "%q", arg )
				end
			end
			RunString( param:format( unpack( args ) ) )
		end )
		self.HTML:AddFunction( "lua", "PlaySound", function( param ) surface.PlaySound( param ) end )
		self.nfInjected = false
	end

	self.HTML:OpenURL( url )

	self:InvalidateLayout()
	self:SetMouseInputEnabled( true )

	self.LoadedURL = url

end

function PANEL:PerformLayout()

	self:SetSize( ScrW(), ScrH() )

end

function PANEL:Paint()

	if ( !IsValid( self.HTML ) || self.HTML:IsLoading() ) then
		surface.SetDrawColor( 10, 10, 14, 255 )
		surface.DrawRect( 0, 0, self:GetWide(), self:GetTall() )
	end

	if ( self.JavascriptRun && IsValid( self.HTML ) && !self.HTML:IsLoading() ) then

		self:RunJavascript( self.JavascriptRun )
		self.JavascriptRun = nil

	end

end

function PANEL:RunJavascript( str )

	if ( !IsValid( self.HTML ) ) then return end
	if ( self.HTML:IsLoading() ) then return end

	self.HTML:RunJavascript( str )

end

local _nfCSS = [[
@keyframes nfFadeIn{from{opacity:0;transform:translateY(6px)}to{opacity:1;transform:translateY(0)}}
#nf_loading{position:fixed;right:24px;top:calc(28px + (100vh - 56px) * var(--ld-y,1));transform:translateY(calc(-100% * var(--ld-y,1)));background:rgba(10,10,14,0.78);border:1px solid rgba(255,255,255,0.12);border-radius:8px;padding:14px 16px 12px 16px;display:flex;flex-direction:row;align-items:center;gap:12px;z-index:2147483647;pointer-events:none;font-family:'Helvetica Neue',Helvetica,Arial,sans-serif;box-shadow:0 4px 24px rgba(0,0,0,0.55)}
#nf_info{display:flex;flex-direction:column;gap:10px;width:var(--ld-w,280px)}
#nf_status{font-size:var(--ld-text,13px);color:rgba(225,238,255,0.90);letter-spacing:0.09em;text-shadow:0 1px 6px rgba(0,0,0,0.90);white-space:nowrap;overflow:hidden;text-overflow:ellipsis;line-height:1.4}
#nf_cancel{font-size:calc(var(--ld-text,13px) * 0.77);width:6.6em;height:2.2em;flex-shrink:0;color:rgba(210,225,248,0.85);letter-spacing:0.09em;border-radius:4px;border:1px solid rgba(255,255,255,0.12);background:rgba(255,255,255,0.04);display:flex;align-items:center;justify-content:center;pointer-events:none;user-select:none;-webkit-user-select:none}
#nf_track{width:100%;height:var(--ld-bar,7px);background:rgba(255,255,255,0.07);border-radius:9999px;overflow:hidden}
#nf_fill{height:100%;width:0%;border-radius:9999px;background:rgba(var(--vuo-a,35,135,237),0.95);box-shadow:0 0 10px rgba(var(--vuo-a,35,135,237),0.70);transition:width 0.45s cubic-bezier(0.4,0,0.2,1)}
]]

local _nfInjectJS = [[
(function(){
  if(document.getElementById('nf_loading'))return;
  var s=document.createElement('style');s.textContent=]] .. string.format("%q", _nfCSS) .. [[;
  document.head&&document.head.appendChild(s);
  var d=document.createElement('div');d.id='nf_loading';
  d.innerHTML='<div id="nf_info"><div id="nf_status">Connecting...</div><div id="nf_track"><div id="nf_fill"></div></div></div><div id="nf_cancel">Cancel</div>';
  document.body&&document.body.appendChild(d);
  window.SetLoadingFraction=function(f){var el=document.getElementById('nf_fill');if(el)el.style.width=(Math.max(0,Math.min(1,f))*100)+'%';};
  window.SetStatusChanged=function(t){var el=document.getElementById('nf_status');if(el&&t)el.innerText=t;};
})();
]]

local _nfStatusMap = {
	["Sending client info"]   = 0.05,
	["Receiving server info"] = 0.10,
	["Requesting resources"]  = 0.15,
	["Downloading resources"] = 0.25,
	["Loading resources"]     = 0.45,
	["Starting Lua"]          = 0.65,
	["Lua Started"]           = 0.85,
	["Initializing game"]     = 0.92,
}

local function NF_GetFractionForStatus( str )
	if !str then return nil end
	for key, val in pairs( _nfStatusMap ) do
		if string.find( str, key, 1, true ) then return val end
	end
	return nil
end

function PANEL:OnActivate()

	if ( IsValid( pnlMainMenu ) ) then
		pcall( function() pnlMainMenu:Call( "if(window.vuoGameState){vuoGameState(true,false);}" ) end )
	end

	self:ShowURL( GetDefaultLoadingHTML() )

	self.NumDownloadables    = 0
	self.CheckedSingleplayer = false
	self.nfInjected          = false
	self.nfLastStatus        = "Connecting..."
	self.nfLastFraction      = 0

end

function PANEL:OnDeactivate()

	if ( IsValid( self.HTML ) ) then self.HTML:Remove() end
	self.LoadedURL = nil
	self.NumDownloadables = 0

	system.FlashWindow()

end

function PANEL:OnScreenSizeChanged( oldW, oldH, newW, newH )

	self:InvalidateLayout( true )

end

function PANEL:Think()

	self:CheckForStatusChanges()
	self:CheckDownloadTables()

	if ( !self.CheckedSingleplayer && IsHostingGame() ) then
		local map = GetConVarString( "host_map" )
		map = string.StripExtension( map )

		GameDetails( GetConVarString( "hostname" ), "127.0.0.1", map, 1, 1, "", GetConVarString( "gamemode" ) )
		self.CheckedSingleplayer = true
	end

	if !self.nfInjected && IsValid( self.HTML ) && !self.HTML:IsLoading() then
		self:RunJavascript( _nfInjectJS )

		self:RunJavascript( nfStyleInjectJS() )

		local s = self.nfLastStatus or "Connecting..."
		local fr = self.nfLastFraction or 0
		self:RunJavascript( "if(window.SetStatusChanged) SetStatusChanged('" .. s:JavascriptSafe() .. "')" )
		self:RunJavascript( "if(window.SetLoadingFraction) SetLoadingFraction(" .. fr .. ")" )
		self.nfInjected = true
	elseif self.nfInjected && IsValid( self.HTML ) && self.HTML:IsLoading() then
		self.nfInjected = false
	end

end

function PANEL:StatusChanged( strStatus )

	self.nfLastStatus = strStatus
	local f = NF_GetFractionForStatus( strStatus )
	if f then
		self.nfLastFraction = f
		self:RunJavascript( "if(window.SetLoadingFraction) SetLoadingFraction(" .. f .. ")" )
	end

	self:RunJavascript( "if(window.SetStatusChanged) SetStatusChanged('" .. strStatus:JavascriptSafe() .. "')" )

	local matchedFileName = string.match( strStatus, "%w+/%w+ [-] (.+) is downloading" )
	if ( matchedFileName ) then

		self:RunJavascript( "if ( window.DownloadingFile ) DownloadingFile( '" .. matchedFileName:JavascriptSafe() .. "' )" )

		return

	end

	local startPos, _ = string.find( strStatus, "Downloading " )
	if ( startPos ) then

		strStatus = string.sub( strStatus, startPos )

		if ( string.EndsWith( strStatus, "via Workshop" ) ) then
			strStatus = string.gsub( strStatus, "' via Workshop", "" )
			strStatus = string.gsub( strStatus, "Downloading '", "" )
		end

		local fileName = string.gsub( strStatus, "Downloading ", "" )

		self:RunJavascript( "if ( window.DownloadingFile ) DownloadingFile( '" .. fileName:JavascriptSafe() .. "' )" )

		return

	end

end

function PANEL:CheckForStatusChanges()

	local str = GetLoadStatus()
	if ( !str ) then return end

	str = string.Trim( str )
	str = string.Trim( str, "\n" )
	str = string.Trim( str, "\t" )

	str = string.gsub( str, "%.bz2", "" )
	str = string.gsub( str, "%.ztmp", "" )
	str = string.gsub( str, "\\", "/" )

	if ( self.OldStatus && self.OldStatus == str ) then return end

	self.OldStatus = str
	self:StatusChanged( str )

end

function PANEL:RefreshDownloadables()

	self.Downloadables = GetDownloadables()
	if ( !self.Downloadables ) then return end

	local iDownloading = 0
	local iFileCount = 0
	for k, v in pairs( self.Downloadables ) do

		v = string.gsub( v, "%.bz2", "" )
		v = string.gsub( v, "%.ztmp", "" )
		v = string.gsub( v, "\\", "/" )

		iDownloading = iDownloading + self:FileNeedsDownload( v )
		iFileCount = iFileCount + 1

	end

	if ( iDownloading == 0 ) then return end

	self:RunJavascript( "if ( window.SetFilesNeeded ) SetFilesNeeded( " .. iDownloading .. ")" )
	self:RunJavascript( "if ( window.SetFilesTotal ) SetFilesTotal( " .. iFileCount .. ")" )

end

function PANEL:FileNeedsDownload( filename )

	local bExists = file.Exists( filename, "GAME" )
	if ( bExists ) then return 0 end

	return 1

end

function PANEL:CheckDownloadTables()

	local NumDownloadables = NumDownloadables()
	if ( !NumDownloadables ) then return end

	if ( self.NumDownloadables && NumDownloadables == self.NumDownloadables ) then return end

	self.NumDownloadables = NumDownloadables
	self:RefreshDownloadables()

end

local PanelType_Loading = vgui.RegisterTable( PANEL, "EditablePanel" )

local pnlLoading = nil

function GetLoadPanel()

	if ( !IsValid( pnlLoading ) ) then
		pnlLoading = vgui.CreateFromTable( PanelType_Loading )
	end

	return pnlLoading

end

function IsInLoading()

	if ( !IsValid( pnlLoading ) || !IsValid( pnlLoading.HTML ) ) then
		return false
	end

	return true

end

function GameDetails( servername, serverurl, mapname, maxplayers, maxplayers_visible, steamid, gamemode )

	if ( engine.IsPlayingDemo() ) then return end

	serverurl = serverurl:Replace( "%s", steamid )
	serverurl = serverurl:Replace( "%m", mapname )

	if ( maxplayers > 1 && GetConVar( "cl_enable_loadingurl" ):GetBool() && ( serverurl:StartsWith( "http" ) || serverurl:StartsWith( "asset://" ) ) ) then
		pnlLoading:ShowURL( serverurl, true )
	end

	local niceGamemode = gamemode
	for k, v in pairs( engine.GetGamemodes() ) do
		if ( niceGamemode == v.name ) then
			niceGamemode = v.title
			break
		end
	end

	pnlLoading.JavascriptRun = string.format( [[if ( window.GameDetails ) GameDetails( "%s", "%s", "%s", %i, "%s", "%s", %.2f, "%s", "%s" );]],
		servername:JavascriptSafe(), serverurl:JavascriptSafe(), mapname:JavascriptSafe(), maxplayers_visible, steamid:JavascriptSafe(), gamemode:JavascriptSafe(),
		GetConVarNumber( "snd_musicvolume" ), GetConVarString( "gmod_language" ):JavascriptSafe(), niceGamemode:JavascriptSafe() )

end

do
    local FOLDER = "sound/vuo_music"
    local EXTS   = { "*.mp3", "*.ogg", "*.wav", "*.flac" }

    local function vuoGetTracks()
        local out = {}
        for _, ext in ipairs( EXTS ) do
            local files = file.Find( FOLDER .. "/" .. ext, "GAME" )
            if ( istable( files ) ) then
                for _, fn in ipairs( files ) do out[ #out + 1 ] = fn end
            end
        end
        table.sort( out )
        return out
    end

    local function vuoPushTracks()
        if ( not IsValid( pnlMainMenu ) ) then return end
        local parts = {}
        for _, fn in ipairs( vuoGetTracks() ) do
            local name = string.gsub( string.StripExtension( fn ), "_", " " )
            local url  = "asset://garrysmod/" .. FOLDER .. "/" .. fn
            parts[ #parts + 1 ] = "{name:\"" .. name:JavascriptSafe() ..
                                  "\",url:\"" .. url:JavascriptSafe() .. "\"}"
        end

        pcall( function()
            pnlMainMenu:Call( "if(window.vuoSetMusic){vuoSetMusic([" ..
                table.concat( parts, "," ) .. "]);}" )
        end )
    end

    timer.Simple( 2, function()
        print( "[VUO Music] " .. #vuoGetTracks() .. " track(s) in garrysmod/" .. FOLDER ..
               " | pnlMainMenu=" .. tostring( IsValid( pnlMainMenu ) ) )
    end )

    local n = 0
    local function loop()
        n = n + 1
        vuoPushTracks()
        if ( n < 15 ) then timer.Simple( 1, loop ) end
    end
    timer.Simple( 1, loop )
end

do
    local SETTINGS_FILE = "vuo_settings.txt"
    local BG_FOLDER     = "materials/vuo_backgrounds"
    local BG_EXTS       = { "*.png", "*.jpg", "*.jpeg" }

    local function vuoBackgrounds()
        local out = {}
        for _, ext in ipairs( BG_EXTS ) do
            local files = file.Find( BG_FOLDER .. "/" .. ext, "GAME" )
            if ( istable( files ) ) then
                for _, fn in ipairs( files ) do out[ #out + 1 ] = fn end
            end
        end
        table.sort( out )
        return out
    end

    local function vuoDefaultBackgrounds()
        local out, seen = {}, {}
        local function add( path, fn )
            local low = string.lower( path )
            if ( seen[ low ] ) then return end
            seen[ low ] = true
            out[ #out + 1 ] = {
                name = string.gsub( string.StripExtension( fn ), "_", " " ),
                url  = "asset://garrysmod/" .. path,
            }
        end
        for _, ext in ipairs( BG_EXTS ) do
            local files = file.Find( "backgrounds/" .. ext, "MOD" )
            if ( istable( files ) ) then
                for _, fn in ipairs( files ) do add( "backgrounds/" .. fn, fn ) end
            end
        end
        table.sort( out, function( a, b ) return a.name < b.name end )
        return out
    end

    local function vuoPush()
        if ( not IsValid( pnlMainMenu ) ) then return end

        local parts = {}
        for _, fn in ipairs( vuoBackgrounds() ) do
            parts[ #parts + 1 ] = "{name:\"" .. string.gsub( string.StripExtension( fn ), "_", " " ):JavascriptSafe() ..
                                  "\",url:\"asset://garrysmod/" .. BG_FOLDER .. "/" .. fn .. "\"}"
        end
        local dparts = {}
        for _, b in ipairs( vuoDefaultBackgrounds() ) do
            dparts[ #dparts + 1 ] = "{name:\"" .. b.name:JavascriptSafe() ..
                                    "\",url:\"" .. b.url:JavascriptSafe() .. "\"}"
        end
        local raw = file.Read( SETTINGS_FILE, "DATA" ) or "{}"
        pcall( function()
            pnlMainMenu:Call( "if(window.vuoSetBackgrounds){vuoSetBackgrounds([" .. table.concat( parts, "," ) .. "]);}" )
            pnlMainMenu:Call( "if(window.vuoSetDefaultBackgrounds){vuoSetDefaultBackgrounds([" .. table.concat( dparts, "," ) .. "]);}" )
            pnlMainMenu:Call( "if(window.vuoApplySettings){vuoApplySettings(" .. raw .. ");}" )
        end )
    end

    local n = 0
    local function loop()
        n = n + 1
        vuoPush()
        if ( n < 15 ) then timer.Simple( 1, loop ) end
    end
    timer.Simple( 1.2, loop )
end

do
    local active, opts = {}, { swap = 30, zoom = true, darken = 0, fade = true, cssmode = false }
    local mats = {}
    local idx, prevIdx, swapAt, fadeAt = 1, nil, 0, 0

    local function matFor( path )
        if ( mats[ path ] ) then return mats[ path ] end
        local m = Material( path, "nocull smooth" )
        mats[ path ] = m
        return m
    end

    local function clean( p )
        p = tostring( p or "" )
        p = string.gsub( p, "^asset://garrysmod/", "" )
        p = string.gsub( p, "^materials/", "" )
        return p
    end

    function VUO_SetBackground( json )
        local d = util.JSONToTable( json or "{}" ) or {}
        local list = istable( d.on ) and d.on or {}
        local o = istable( d.opts ) and d.opts or {}
        active = {}
        for _, p in ipairs( list ) do
            local c = clean( p )
            if ( c ~= "" ) then active[ #active + 1 ] = c end
        end
        opts.swap   = math.max( 2, tonumber( o.swap ) or 30 )
        opts.zoom   = o.zoom and true or false
        opts.anim   = ( o.anim and tostring( o.anim ) ) or ( opts.zoom and "zoom" or "none" )
        opts.cssmode = o.cssmode and true or false
        opts.fade   = o.fade ~= false
        idx = 1; prevIdx = nil; swapAt = SysTime() + opts.swap
    end

    local function drawImg( path, alpha )
        if ( alpha <= 0 ) then return end
        local m = matFor( path )
        if ( not m or m:IsError() ) then return end
        surface.SetMaterial( m )
        local w, h = ScrW(), ScrH()
        local now = SysTime()
        local anim = opts.anim or "none"
        local s, ox, oy = 1.0, 0, 0
        if ( anim == "zoom" ) then
            s = 1.04 + ( math.sin( now * 0.18 ) * 0.5 + 0.5 ) * 0.08
        elseif ( anim == "pan" ) then
            s = 1.12
            ox = math.sin( now * 0.13 ) * ( w * 0.03 )
            oy = math.cos( now * 0.10 ) * ( h * 0.02 )
        elseif ( anim == "float" ) then
            s = 1.08 + ( math.sin( now * 0.12 ) * 0.5 + 0.5 ) * 0.03
            ox = math.sin( now * 0.09 ) * ( w * 0.018 )
            oy = math.sin( now * 0.07 ) * ( h * 0.018 )
        end
        surface.SetDrawColor( 255, 255, 255, alpha )
        surface.DrawTexturedRectRotated( w * 0.5 + ox, h * 0.5 + oy, w * s, h * s, 0 )
    end

    local origDraw = DrawBackground
    local function VUODrawBackground()

        local inGame = ( isfunction( IsInGame ) and IsInGame() ) or ( isfunction( IsInLoading ) and IsInLoading() )
        if ( inGame ) then
            if ( isfunction( origDraw ) ) then return origDraw() end
            return
        end
        if ( opts.cssmode ) then
            surface.SetDrawColor( 0, 0, 0, 255 )
            surface.DrawRect( 0, 0, ScrW(), ScrH() )
            return
        end
        if ( #active == 0 ) then
            if ( isfunction( origDraw ) ) then return origDraw() end
            return
        end
        local now = SysTime()
        if ( #active > 1 and now >= swapAt ) then
            prevIdx = idx
            idx = idx % #active + 1
            swapAt = now + opts.swap
            fadeAt = now
        end
        local cur = active[ idx ]
        if ( not cur ) then return end
        local t = opts.fade and math.Clamp( ( now - fadeAt ) / 1.2, 0, 1 ) or 1
        if ( prevIdx and active[ prevIdx ] and t < 1 ) then
            drawImg( active[ prevIdx ], 255 )
            drawImg( cur, math.floor( t * 255 ) )
        else
            drawImg( cur, 255 )
            prevIdx = nil
        end
    end

    local seeded = false
    timer.Create( "VUO_BgHijack", 1, 0, function()
        if ( DrawBackground ~= VUODrawBackground ) then
            if ( isfunction( DrawBackground ) ) then origDraw = DrawBackground end
            _G.DrawBackground = VUODrawBackground
        end
        if ( not seeded ) then
            seeded = true
            local raw = file.Read( "vuo_settings.txt", "DATA" )
            local cfg = raw and util.JSONToTable( raw ) or nil
            if ( cfg and istable( cfg.bgOn ) ) then
                VUO_SetBackground( util.TableToJSON( {
                    on = cfg.bgOn,
                    opts = {
                        swap   = cfg.bgSwap,
                        anim   = ( not cfg.bgBlurOn and cfg.bganim ) or "none",
                        zoom   = ( not cfg.bgBlurOn and cfg.bganim and cfg.bganim ~= "none" ) and true or false,
                        cssmode = ( cfg.bgBlurOn and ( tonumber( cfg.bgBlur ) or 0 ) > 0 ) or false,
                        fade   = cfg.bgFade,
                    },
                } ) )
            end
        end
    end )
end

do
    local FONT_FOLDER  = "materials/vuo_fonts"
    local SOUND_FOLDER = "sound/vuo_sounds"

    local function vuoFonts()
        local out = {}
        for _, ext in ipairs( { "*.ttf", "*.otf" } ) do
            local files = file.Find( FONT_FOLDER .. "/" .. ext, "GAME" )
            if ( istable( files ) ) then
                for _, fn in ipairs( files ) do out[ #out + 1 ] = fn end
            end
        end
        table.sort( out )
        return out
    end

    local function vuoFindSound( base )
        for _, ext in ipairs( { ".wav", ".mp3", ".ogg" } ) do
            if ( file.Exists( SOUND_FOLDER .. "/" .. base .. ext, "GAME" ) ) then
                return "vuo_sounds/" .. base .. ext
            end
        end
        return nil
    end

    local function vuoPushExtras()
        if ( not IsValid( pnlMainMenu ) ) then return end

        local fparts = {}
        for _, fn in ipairs( vuoFonts() ) do
            fparts[ #fparts + 1 ] = "{name:\"" .. string.StripExtension( fn ):JavascriptSafe() ..
                                    "\",url:\"asset://garrysmod/" .. FONT_FOLDER .. "/" .. fn:JavascriptSafe() .. "\"}"
        end

        local hover, click, back = vuoFindSound( "hover" ), vuoFindSound( "click" ), vuoFindSound( "back" )
        local function js( v ) return v and ( "\"" .. v:JavascriptSafe() .. "\"" ) or "null" end

        pcall( function()
            pnlMainMenu:Call( "if(window.vuoSetFonts){vuoSetFonts([" .. table.concat( fparts, "," ) .. "]);}" )
            pnlMainMenu:Call( "if(window.vuoSetSounds){vuoSetSounds({hover:" .. js( hover ) .. ",click:" .. js( click ) .. ",back:" .. js( back ) .. "});}" )
        end )
    end

    local n = 0
    local function loop()
        n = n + 1
        vuoPushExtras()
        if ( n < 15 ) then timer.Simple( 1, loop ) end
    end
    timer.Simple( 1.4, loop )
end

do
    local pnl = nil
    local wrapped = false
    local lastOpen = nil
    timer.Create( "VUO_ProblemsActive", 0.2, 0, function()
        if ( not wrapped and isfunction( OpenProblemsPanel ) ) then
            wrapped = true
            local orig = OpenProblemsPanel
            OpenProblemsPanel = function()
                local w = vgui.GetWorldPanel()
                local before = {}
                if ( IsValid( w ) ) then for _, c in ipairs( w:GetChildren() ) do before[ c ] = true end end
                orig()
                if ( IsValid( w ) ) then for _, c in ipairs( w:GetChildren() ) do if ( not before[ c ] ) then pnl = c break end end end
            end
        end
        local open = false
        pcall( function() open = IsValid( pnl ) and pnl:IsVisible() and true or false end )
        if ( open ~= lastOpen ) then
            lastOpen = open
            if ( IsValid( pnlMainMenu ) ) then
                pcall( function() pnlMainMenu:Call( "window.vuoProblemsOpen=" .. ( open and "true" or "false" ) .. ";" ) end )
            end
        end
    end )
end

do
    local last = nil
    timer.Create( "VUO_MusicGameState", 0.25, 0, function()
        if ( not IsValid( pnlMainMenu ) ) then return end

        local loading = ( isfunction( IsInLoading ) and IsInLoading() ) and true or false
        local ingame  = ( isfunction( IsInGame )    and IsInGame()    ) and true or false

        local state = tostring( loading ) .. "|" .. tostring( ingame )
        if ( state == last ) then return end
        last = state

        pcall( function()
            pnlMainMenu:Call( string.format( "if(window.vuoGameState){vuoGameState(%s,%s);}",
                loading and "true" or "false", ingame and "true" or "false" ) )
        end )
    end )
end

