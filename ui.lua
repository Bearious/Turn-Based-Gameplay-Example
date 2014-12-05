-- ui.lua (currently includes Button class with labels, font selection and optional event model)
 
-- Version 2.4
-- Based on the folowing original provided by Ansca Inc.
-- Version 1.5 (works with multitouch, adds setText() method to buttons)
--
-- Copyright (C) 2010 ANSCA Inc. All Rights Reserved.
--
-- Permission is hereby granted, free of charge, to any person obtaining a copy of 
-- this software and associated documentation files (the "Software"), to deal in the 
-- Software without restriction, including without limitation the rights to use, copy, 
-- modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, 
-- and to permit persons to whom the Software is furnished to do so, subject to the 
-- following conditions:
-- 
-- The above copyright notice and this permission notice shall be included in all copies 
-- or substantial portions of the Software.
-- 
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, 
-- INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR 
-- PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE 
-- FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR 
-- OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER 
-- DEALINGS IN THE SOFTWARE.
 
-- Version 1.6 Works with Dynamic Scaling.
-- Based on the work edited by William Flagello, williamflagello.com
-- Original from https://developer.anscamobile.com/code/ui-library
--
-- Version 1.7 Dynamic Scaling text fixes by Jonathan Bebe
-- http://developer.anscamobile.com/forum/2010/12/17/easily-make-your-text-sharp-retina-displays#comment-18164
-- Provided in Ghosts & Monsters Sample Project
--
-- Version 1.71 Retina Updates by Jonathan Bebe
-- http://developer.anscamobile.com/forum/2010/12/17/easily-make-your-text-sharp-retina-displays#comment-38284
-- Adapted to 1.7 base code by E. Gonenc, pixelenvision.com
--
-- Version 1.8 added support for providing already realized display-objects for use in Tiled/Lime
-- Based on the file changed by Frank Siebenlist
-- http://developer.anscamobile.com/forum/2011/02/19/enhanced-uilua-v15
-- Adapted to 1.7 base code by E. Gonenc, pixelenvision.com
--
-- Version 1.9 
-- Added transparency & scaling options to use as over state. newLabel updated to support retina text.
-- Edited by E. Gonenc, pixelenvision.com
--
-- Version 1.91 
-- Added suggested fix for overlapping buttons by Jonathan Bebe
-- http://jonbeebe.net/to-return-true-or-not-to
-- Adapted by E. Gonenc, pixelenvision.com
--
-- Version 2.02
-- Button text will now follow scaling & alpha states of over button
-- Edited by E. Gonenc, pixelenvision.com
--
-- Version 2.1
-- Added suggested .isActive update by monoxgas http://developer.anscamobile.com/code/enhanced-ui-library-uilua#comment-49272
-- Edited by E. Gonenc, pixelenvision.com
--
-- Version 2.2
-- Updated to eliminate the use of LUAs deprecated module() function. This is an internal change only, usage stays the same.
-- http://blog.anscamobile.com/2011/09/a-better-approach-to-external-modules/
-- Edited by E. Gonenc, pixelenvision.com
--
-- Version 2.3
-- Updated to use object.contentBounds instead of deprecated object.stageBounds
-- Added event support, now returns even.target, event.x & event.y values. You can use x/y values to provide different actions
-- based on the coordinates of the touch event reative to the x/y size of the button image.
-- Edited by E. Gonenc, pixelenvision.com
--
-- Version 2.4
-- isActive state enhanced to button can be enabled/disabled without checking current isActive state with if-then.
-- ie. btn.isActive = true (Default state, button is enabled) btn.isActive = false (button is disabled, no animation and action)
-- Edited by E. Gonenc, pixelenvision.com

local M = {}

-------------
-- convenience test functions added by Frank.
 
local coronaMetaTable = getmetatable(display.getCurrentStage())
 
--- Test function that returns whether object is a Corona display object.
-- Note that all Corona types seem to share the same metatable...
local isDisplayObject = function(o)
        return type(o) == "table" and getmetatable(o) == coronaMetaTable
end

-----------------
-- Helper function for newButton utility function below
local function newButtonHandler( self, event )
 
        local result = true
        local default
        local over 
        if self.switched then 
                default = self[2]
                over = self[1]
        else 
                default = self[1]
                over = self[2]
        end
        local txt1,txt2,txt3
        
        local OX,OY,SX,SY,SM
        if self[3] then txt1 = self[3] end
        if self[4] then txt2 = self[4] end
        if self[5] then txt3 = self[5] end
        if txt1 or txt2 or txt3 then
	        if display.contentScaleX < 1.0 or display.contentScaleY < 1.0 then SM = 2 else SM = 1 end 
			OX,OY = (over.xScale/default.xScale),(over.yScale/default.yScale)
			SX,SY = (default.xScale/over.xScale),(default.yScale/over.yScale)
        end

        -- General "onEvent" function overrides onPress and onRelease, if present
        local onEvent = self._onEvent
 
        local onPress = self._onPress
        local onRelease = self._onRelease
 
        local buttonEvent = {}
        if (self._id) then
                buttonEvent.id = self._id
        end
		buttonEvent.isActive = self.isActive
		buttonEvent.target = self
        local phase = event.phase
        if self.isActive then
	        if "began" == phase then
	                if over then 
	                        default.isVisible = false
	                        over.isVisible = true
	                if txt1 then txt1:scale(OX,OY);txt1.alpha = over.alpha end
	                if txt2 then txt2:scale(OX,OY);txt2.alpha = over.alpha end
	                if txt3 then txt3:scale(OX,OY);txt3.alpha = over.alpha end
	                end
	 
	                if onEvent then
	                        buttonEvent.phase = "press"
	                        buttonEvent.x = event.x - self.contentBounds.xMin
	                        buttonEvent.y = event.y - self.contentBounds.yMin
	                        result = onEvent( buttonEvent )
	                elseif onPress then
	                        result = onPress( event )
	                end
	 
	                -- Subsequent touch events will target button even if they are outside the contentBounds of button
	                display.getCurrentStage():setFocus( self, event.id )
	                self.isFocus = true
	                
	        elseif self.isFocus then
	                local bounds = self.contentBounds
	                local x,y = event.x,event.y
	                local isWithinBounds = 
	                        bounds.xMin <= x and bounds.xMax >= x and bounds.yMin <= y and bounds.yMax >= y
	 
	                if "moved" == phase then
	                        if over then
	                                -- The rollover image should only be visible while the finger is within button's stageBounds
	                                default.isVisible = not isWithinBounds
	                                over.isVisible = isWithinBounds
	                        if txt1 and not isWithinBounds and txt1.xScale*SM == OX then txt1:scale(SX,SY);txt1.alpha = default.alpha
	                        elseif txt1 and isWithinBounds and txt1.xScale*SM ~= OX then txt1:scale(OX,OY);txt1.alpha = over.alpha end
	                        if txt2 and not isWithinBounds and txt2.xScale*SM == OX then txt2:scale(SX,SY);txt2.alpha = default.alpha
	                        elseif txt2 and isWithinBounds and txt2.xScale*SM ~= OX then txt2:scale(OX,OY);txt2.alpha = over.alpha end
	                        if txt3 and not isWithinBounds and txt3.xScale*SM == OX then txt3:scale(SX,SY);txt3.alpha = default.alpha
	                        elseif txt3 and isWithinBounds and txt3.xScale*SM ~= OX then txt3:scale(OX,OY);txt3.alpha = over.alpha end
	                        end
	                        
	                elseif "ended" == phase or "cancelled" == phase then 
	                        if over then 
	                                default.isVisible = true
	                                over.isVisible = false
	                        if txt1 and txt1.xScale*SM == OX then txt1:scale(SX,SY);txt1.alpha = default.alpha end
	                        if txt2 and txt2.xScale*SM == OX then txt2:scale(SX,SY);txt2.alpha = default.alpha end
	                        if txt3 and txt3.xScale*SM == OX then txt3:scale(SX,SY);txt3.alpha = default.alpha end
	                        end
	                        
	                        if "ended" == phase then
	                                -- Only consider this a "click" if the user lifts their finger inside button's stageBounds
	                                if isWithinBounds then
	                                        if onEvent then
	                                                buttonEvent.phase = "release"
	                                                buttonEvent.x = event.x - bounds.xMin
	                                                buttonEvent.y = event.y - bounds.yMin
	                                                result = onEvent( buttonEvent )
	                                        elseif onRelease then
	                                                result = onRelease( event )
	                                        end
	                                end
	                        end
	                        
	                        -- Allow touch events to be sent normally to the objects they "hit"
	                        display.getCurrentStage():setFocus( self, nil )
	                        self.isFocus = false
	                end
	        end
        end
        return true

end

 
---------------
-- Button class
 
local function newButton( params )
        local button, defaultSrc , defaultX , defaultY , overSrc , overX , overY , overScale , overAlpha , size, font, textColor, offset
        
        local sizeDivide = 1
 	   local sizeMultiply = 1
 
        if display.contentScaleX < 1.0 or display.contentScaleY < 1.0 then
                sizeMultiply = 2
                sizeDivide = 0.5                
        end
        
        if params.defaultSrc then
                button = display.newGroup()
                if isDisplayObject(params.defaultSrc) then
                        default = params.defaultSrc
                else
                        default = display.newImageRect ( params.defaultSrc , params.defaultX , params.defaultY )
                end             
                button:insert( default, false )
        end
        
        if params.overSrc then
                if isDisplayObject(params.overSrc) then
                	over = params.overSrc
                else
                	over = display.newImageRect ( params.overSrc , params.overX , params.overY )
                end
                if params.overAlpha then
                    over.alpha = params.overAlpha
                end
                if params.overScale then
                        over:scale(params.overScale,params.overScale)
                end
                over.isVisible = false
                button:insert( over, false )    
        else 
                over = display.newImageRect ( params.defaultSrc , params.defaultX , params.defaultY )
                over.isVisible = false
                button:insert(over,false)
        end
        function button:switch()
                if self.switched then
                	self[2].isVisible = false
                	self[1].isVisible = true
                else
                	self[1].isVisible = false
                    self[2].isVisible = true
                end
                self.switched = not self.switched 
        end
        -- Public methods
        function button:setText( newText )
        
                local labelText = self.text
                if ( labelText ) then
                        labelText:removeSelf()
                        self.text = nil
                end
 
                local labelShadow = self.shadow
                if ( labelShadow ) then
                        labelShadow:removeSelf()
                        self.shadow = nil
                end
 
                local labelHighlight = self.highlight
                if ( labelHighlight ) then
                        labelHighlight:removeSelf()
                        self.highlight = nil
                end
                
                if ( params.size and type(params.size) == "number" ) then size=params.size else size=20 end
                if ( params.font ) then font=params.font else font=native.systemFontBold end
                if ( params.textColor ) then textColor=params.textColor else textColor={ 255, 255, 255, 255 } end
                
                size = size * sizeMultiply
                
                -- Optional vertical correction for fonts with unusual baselines (I'm looking at you, Zapfino)
                if ( params.offset and type(params.offset) == "number" ) then offset=params.offset else offset = 0 end
                
                if ( params.emboss ) then
                        -- Make the label text look "embossed" (also adjusts effect for textColor brightness)
                        local textBrightness = ( textColor[1] + textColor[2] + textColor[3] ) / 3
                        
                        labelHighlight = display.newText( newText, 0, 0, font, size )
                        if ( textBrightness > 127) then
                                labelHighlight:setTextColor( 255, 255, 255, 20 )
                        else
                                labelHighlight:setTextColor( 255, 255, 255, 140 )
                        end
                        button:insert( labelHighlight, true )
                        labelHighlight.x = labelHighlight.x + 1.5; labelHighlight.y = labelHighlight.y + 1.5 + offset
                        self.highlight = labelHighlight
 
                        labelShadow = display.newText( newText, 0, 0, font, size )
                        if ( textBrightness > 127) then
                                labelShadow:setTextColor( 0, 0, 0, 128 )
                        else
                                labelShadow:setTextColor( 0, 0, 0, 20 )
                        end
                        button:insert( labelShadow, true )
                        labelShadow.x = labelShadow.x - 1; labelShadow.y = labelShadow.y - 1 + offset
                        self.shadow = labelShadow
                        
                        labelHighlight.xScale = sizeDivide; labelHighlight.yScale = sizeDivide
                        labelShadow.xScale = sizeDivide; labelShadow.yScale = sizeDivide
                end
                
                labelText = display.newText( newText, 0, 0, font, size )
                labelText:setTextColor( textColor[1], textColor[2], textColor[3], textColor[4] )
                button:insert( labelText, true )
                labelText.y = labelText.y + offset
                self.text = labelText
                
                labelText.xScale = sizeDivide; labelText.yScale = sizeDivide
        end
        
        if params.text then
                button:setText( params.text )
        end
        
        if ( params.onPress and ( type(params.onPress) == "function" ) ) then
                button._onPress = params.onPress
        end
        if ( params.onRelease and ( type(params.onRelease) == "function" ) ) then
                button._onRelease = params.onRelease
        end
        
        if (params.onEvent and ( type(params.onEvent) == "function" ) ) then
                button._onEvent = params.onEvent
        end
        
        -- set button to active (meaning, can be pushed)
        button.isActive = true
        
        -- Set button as a table listener by setting a table method and adding the button as its own table listener for "touch" events
        button.touch = newButtonHandler
        button:addEventListener( "touch", button )
 
        if params.x then
                button.x = params.x
        end
        
        if params.y then
                button.y = params.y
        end
        
        if params.id then
                button._id = params.id
        end
 
        return button
end
M.newButton = newButton
 
--------------
-- Label class

local function newLabel( params )
        local labelText
        local size, font, textColor, align
        local t = display.newGroup()
        
        local sizeDivide = 1
 	   local sizeMultiply = 1
 
        if ( params.bounds ) then
                local bounds = params.bounds
                local left = bounds[1]
                local top = bounds[2]
                local width = bounds[3]
                local height = bounds[4]
        
                if ( params.size and type(params.size) == "number" ) then size=params.size else size=20 end
                if ( params.font ) then font=params.font else font=native.systemFontBold end
                if ( params.textColor ) then textColor=params.textColor else textColor={ 255, 255, 255, 255 } end
                if ( params.offset and type(params.offset) == "number" ) then offset=params.offset else offset = 0 end
                if ( params.align ) then align = params.align else align = "center" end
                
                if ( params.text ) then
                        labelText = display.newText( params.text, 0, 0, font, size * 2 )
                        labelText.xScale = 0.5; labelText.yScale = 0.5
                        labelText:setTextColor( textColor[1], textColor[2], textColor[3], textColor[4] )
                        t:insert( labelText )
                        -- TODO: handle no-initial-text case by creating a field with an empty string?
        
                        if ( align == "left" ) then
                                labelText.x = left + labelText.contentWidth * 0.5
                        elseif ( align == "right" ) then
                                labelText.x = (left + width) - labelText.contentWidth * 0.5
                        else
                                labelText.x = ((2 * left) + width) * 0.5
                        end
                end
                
                labelText.y = top + labelText.contentHeight * 0.5
 
                -- Public methods
                function t:setText( newText )
                        if ( newText ) then
                                labelText.text = newText
                                
                                if ( "left" == align ) then
                                        labelText.x = left + labelText.contentWidth * 0.5
                                elseif ( "right" == align ) then
                                        labelText.x = (left + width) - labelText.contentWidth * 0.5
                                else
                                        labelText.x = ((2 * left) + width) * 0.5
                                end
                        end
                end
                
                function t:setTextColor( r, g, b, a )
                        local newR = 255
                        local newG = 255
                        local newB = 255
                        local newA = 255
 
                        if ( r and type(r) == "number" ) then newR = r end
                        if ( g and type(g) == "number" ) then newG = g end
                        if ( b and type(b) == "number" ) then newB = b end
                        if ( a and type(a) == "number" ) then newA = a end
 
                        labelText:setTextColor( r, g, b, a )
                end
        end
        
        -- Return instance (as display group)
        return t
        
end
M.newLabel = newLabel

return M