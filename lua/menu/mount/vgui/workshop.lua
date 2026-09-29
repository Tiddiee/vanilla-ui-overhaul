PANEL.Base = "DPanel"

local pnlRocket = vgui.RegisterFile( "addon_rocket.lua" )

local function wsSettings()
	local raw = file.Read( "vuo_settings.txt", "DATA" )
	return raw and util.JSONToTable( raw ) or {}
end

local function wsColor( str, r, g, b )
	if ( isstring( str ) ) then
		local cr, cg, cb = string.match( str, "(%d+)%s*,%s*(%d+)%s*,%s*(%d+)" )
		if ( cr and cg and cb ) then return tonumber( cr ), tonumber( cg ), tonumber( cb ) end
	end
	return r, g, b
end

local function u16( s, o )
	local a, b = string.byte( s, o + 1, o + 2 )
	return ( a or 0 ) * 256 + ( b or 0 )
end

local function u32( s, o )
	return u16( s, o ) * 65536 + u16( s, o + 2 )
end

local function wsFamilyName( path )

	local f = file.Open( path, "rb", "GAME" )
	if ( !f ) then return end

	local head = f:Read( 12 ) or ""
	local count = u16( head, 4 )
	local dir = count > 0 and f:Read( count * 16 ) or ""
	local tbl

	for i = 0, count - 1 do
		if ( string.sub( dir, i * 16 + 1, i * 16 + 4 ) == "name" ) then
			f:Seek( u32( dir, i * 16 + 8 ) )
			tbl = f:Read( u32( dir, i * 16 + 12 ) )
			break
		end
	end

	f:Close()
	if ( !tbl ) then return end

	local strings = u16( tbl, 4 )
	local found

	for i = 0, u16( tbl, 2 ) - 1 do
		local rec = 6 + i * 12
		if ( u16( tbl, rec ) == 3 and u16( tbl, rec + 6 ) == 1 ) then
			local len, off = u16( tbl, rec + 8 ), strings + u16( tbl, rec + 10 )
			local chars = {}
			for j = 0, len - 2, 2 do
				local c = u16( tbl, off + j )
				if ( c < 32 or c > 126 ) then chars = nil break end
				chars[ #chars + 1 ] = string.char( c )
			end
			if ( chars and #chars > 0 ) then
				found = table.concat( chars )
				if ( u16( tbl, rec + 4 ) == 0x409 ) then break end
			end
		end
	end

	return found

end

local function wsFontWorks( family )

	local sample = "The quick brown fox 0123456789"

	surface.CreateFont( "WorkshopProbe_" .. family, { font = family, size = 32 } )
	surface.SetFont( "WorkshopProbe_" .. family )
	local aw, ah = surface.GetTextSize( sample )

	surface.CreateFont( "WorkshopProbeMissing", { font = "vuo_missing_font", size = 32 } )
	surface.SetFont( "WorkshopProbeMissing" )
	local bw, bh = surface.GetTextSize( sample )

	return aw != bw or ah != bh

end

local familyCache = {}

function VUO_FontFamily()

	local name = wsSettings().font
	if ( !isstring( name ) or name == "" or string.find( name, "[/\\]" ) ) then return nil end
	if ( familyCache[ name ] != nil ) then return familyCache[ name ] or nil end

	local family

	for _, ext in ipairs( { ".ttf", ".otf" } ) do
		local path = "materials/vuo_fonts/" .. name .. ext
		if ( file.Exists( path, "GAME" ) ) then
			family = wsFamilyName( path )
			break
		end
	end

	if ( family and !wsFontWorks( family ) ) then family = nil end

	familyCache[ name ] = family or false
	return family

end

local function wsFonts()

	local family = VUO_FontFamily()
	local suffix = family and ( "_" .. family ) or ""

	surface.CreateFont( "WorkshopLarge" .. suffix, {
		font		= family or "Roboto Medium",
		size		= 18,
		antialias	= true,
		weight		= 500
	})

	surface.CreateFont( "WorkshopSmall" .. suffix, {
		font		= family or "Roboto",
		size		= 13,
		antialias	= true,
		weight		= 400
	})

	return "WorkshopLarge" .. suffix, "WorkshopSmall" .. suffix

end

local cornerRadius = 8
local cornerPixels = {}

for py = 0, cornerRadius - 1 do
	for px = 0, cornerRadius - 1 do
		local d = math.sqrt( ( cornerRadius - px - 0.5 ) ^ 2 + ( cornerRadius - py - 0.5 ) ^ 2 )
		local a = 1 - math.abs( d - ( cornerRadius - 0.5 ) )
		if ( a > 0 ) then table.insert( cornerPixels, { px, py, a } ) end
	end
end

local function RoundedOutline( x, y, w, h, col )

	local r = cornerRadius

	surface.SetDrawColor( col.r, col.g, col.b, col.a )
	surface.DrawRect( x + r, y, w - r * 2, 1 )
	surface.DrawRect( x + r, y + h - 1, w - r * 2, 1 )
	surface.DrawRect( x, y + r, 1, h - r * 2 )
	surface.DrawRect( x + w - 1, y + r, 1, h - r * 2 )

	for _, p in ipairs( cornerPixels ) do
		surface.SetDrawColor( col.r, col.g, col.b, col.a * p[3] )
		surface.DrawRect( x + p[1], y + p[2], 1, 1 )
		surface.DrawRect( x + w - 1 - p[1], y + p[2], 1, 1 )
		surface.DrawRect( x + p[1], y + h - 1 - p[2], 1, 1 )
		surface.DrawRect( x + w - 1 - p[1], y + h - 1 - p[2], 1, 1 )
	end

end

local function Pill( x, y, w, h, frac, trackCol, fillCol )

	draw.RoundedBox( h * 0.5, x, y, w, h, trackCol )

	local fw = math.max( h, math.floor( w * math.Clamp( frac, 0, 1 ) ) )
	draw.RoundedBox( h * 0.5, x, y, fw, h, fillCol )

end

AccessorFunc( PANEL, "m_bDrawProgress", "DrawProgress", FORCE_BOOL )

function PANEL:Init()

	local cfg = wsSettings()
	local pr, pg, pb = wsColor( cfg.accentBlue, 35, 135, 237 )
	local sr, sg, sb = wsColor( cfg.accentGreen, 60, 200, 140 )

	local fontLarge, fontSmall = wsFonts()

	self.BoxColor		= Color( 8, 10, 18, 179 )
	self.BorderColor	= Color( pr, pg, pb, 46 )
	self.TrackColor		= Color( 255, 255, 255, 18 )
	self.FillColor		= Color( pr, pg, pb, 242 )
	self.TotalFillColor	= Color( sr, sg, sb, 210 )

	self.Label = self:Add( "DLabel" )
	self.Label:SetText( "..." )
	self.Label:SetFont( fontLarge )
	self.Label:SetTextColor( Color( 225, 238, 255, 235 ) )
	self.Label:Dock( TOP )
	self.Label:DockMargin( 16, 10, 16, 8 )
	self.Label:SetContentAlignment( 5 )

	self.ProgressLabel = self:Add( "DLabel" )
	self.ProgressLabel:SetText( "" )
	self.ProgressLabel:SetFont( fontSmall )
	self.ProgressLabel:SetContentAlignment( 4 )
	self.ProgressLabel:SetVisible( false )
	self.ProgressLabel:SetTextColor( Color( 210, 225, 248, 190 ) )

	self.TotalsLabel = self:Add( "DLabel" )
	self.TotalsLabel:SetText( "" )
	self.TotalsLabel:SetFont( fontSmall )
	self.TotalsLabel:SetContentAlignment( 4 )
	self.TotalsLabel:SetVisible( false )
	self.TotalsLabel:SetTextColor( Color( 210, 225, 248, 130 ) )

	self.Progress = 0
	self.TotalProgress = 0
	self.ShownProgress = 0
	self.ShownTotal = 0

	self:SetDrawProgress( false )

	self:SetAlpha( 0 )
	self:AlphaTo( 255, 0.25, 0 )

end

function PANEL:PerformLayout( wide )

	self:SetSize( 500, 80 )
	self:Center()
	self:AlignBottom( 16 )

	self.ProgressLabel:SetSize( 100, 16 )
	self.ProgressLabel:SetPos( wide - 100, 40 )

	self.TotalsLabel:SetSize( 100, 16 )
	self.TotalsLabel:SetPos( wide - 100, 58 )

end

function PANEL:Spawn()

	self:InvalidateLayout( true )

end

function PANEL:PrepareDownloading()

	if ( IsValid( self.Rocket ) ) then self.Rocket:Remove() end

	self.Rocket = self:Add( pnlRocket )
	self.Rocket:Dock( LEFT )
	self.Rocket:MoveToBack()
	self.Rocket:DockMargin( 8, 0, 8, 0 )

end

function PANEL:StartDownloading( id, iImageID, title, iSize )

	self.Label:SetText( language.GetPhrase( "ugc.downloadingX" ):format( title ) )

	self.Rocket:Charging( id, iImageID )

	self.ProgressLabel:Show()
	self.ProgressLabel:SetText( "" )

	self.TotalsLabel:Show()

	self:SetDrawProgress( true )
	self:UpdateProgress( 0, iSize )

end

function PANEL:FinishedDownloading( id )

	self.Progress = -1

end

function PANEL:SetMessage( msg )

	self.Label:SetText( msg )

	self:SetDrawProgress( false )

end

function PANEL:Paint( wide, tall )

	draw.RoundedBox( cornerRadius, 0, 0, wide, tall, self.BoxColor )
	RoundedOutline( 0, 0, wide, tall, self.BorderColor )

	if ( !self:GetDrawProgress() ) then return end

	local x = 112
	local w = wide - 228
	local step = math.min( FrameTime() * 10, 1 )

	if ( self.TotalProgress < self.ShownTotal ) then self.ShownTotal = self.TotalProgress end
	self.ShownTotal = Lerp( step, self.ShownTotal, self.TotalProgress )
	Pill( x, 64, w, 4, self.ShownTotal, self.TrackColor, self.TotalFillColor )

	local currentProgress = self.Progress

	if ( currentProgress >= 0 ) then
		if ( currentProgress < self.ShownProgress ) then self.ShownProgress = currentProgress end
		self.ShownProgress = Lerp( step, self.ShownProgress, currentProgress )
		Pill( x, 44, w, 8, self.ShownProgress, self.TrackColor, self.FillColor )
	else
		Pill( x, 44, w, 8, 1, self.TrackColor, self.FillColor )
	end

end

function PANEL:UpdateProgress( downloaded, expected )

	if ( expected <= 0 ) then
		self.Progress = 0
		self.ProgressLabel:SetText( "" )
		return
	end

	self.Progress = downloaded / expected

	if ( self.Progress > 0 ) then
		self.ProgressLabel:SetText( language.GetPhrase( "ugc.XoutofY" ):format( Format( "%.0f%%", self.Progress * 100 ), string.NiceSize( expected ) ) )
	else
		self.ProgressLabel:SetText( string.NiceSize( expected ) )
	end

end

function PANEL:ExtractProgress( title, percent )

	self.Label:SetText( language.GetPhrase( "ugc.extractingX" ):format( title ) )
	self.Progress = percent / 100

	if ( self.Progress > 0 ) then
		self.ProgressLabel:SetText( Format( "%.0f%%", percent ) )
	else
		self.ProgressLabel:SetText( "0%" )
	end

end

function PANEL:UpdateTotalProgress( iCurrent, iTotal )

	self.TotalsLabel:SetText( language.GetPhrase( "ugc.addonXofY" ):format( iCurrent, iTotal ) )
	self.TotalProgress = iCurrent / iTotal

end

function PANEL:SubscriptionsProgress( iCurrent, iTotal )

	self.Label:SetText( "#ugc.fetching" )
	self:SetDrawProgress( true )

	self.Progress = iCurrent / iTotal

	self.ProgressLabel:Show()
	self.ProgressLabel:SetText( language.GetPhrase( "ugc.XofY" ):format( iCurrent, iTotal ) )

end
