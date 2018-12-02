--Fix for SpellBookFrame.lua on Dragonwrath (Atlantiss.eu)
--Actually its not a problem of SpellBookFrame, but it is caused by wrong results returned from function GetProfessionInfo(index)

local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_LOGIN")
f:SetScript("OnEvent", function()

	local function OnEnter(self)
		local spellIndex = self:GetParent():GetParent()["spellIndex" .. self:GetParent():GetID()]
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		if GameTooltip:SetSpellBookItem(spellIndex, "profession") then
			self.UpdateTooltip = OnEnter
		else
			self.UpdateTooltip = nil
		end
	end

	for k,v in pairs ({"PrimaryProfession1", "PrimaryProfession2", "SecondaryProfession1", "SecondaryProfession2", "SecondaryProfession3", "SecondaryProfession4"}) do
		for i = 1, 2 do
			local parentButton = _G[v]["button"..i]
			parentButton.new = parentButton.new or CreateFrame("Button", parentButton:GetName().."New", parentButton, "SecureActionButtonTemplate")
			parentButton.new:SetAllPoints(parentButton)
			parentButton.new:RegisterForDrag("LeftButton")
			parentButton.new:SetScript("OnDragStart", function(self)
				local spellIndex = self:GetParent():GetParent()["spellIndex" .. self:GetParent():GetID()]
				PickupSpellBookItem(spellIndex, "profession")
			end)
			parentButton.new:SetScript("OnEnter", OnEnter)
			parentButton.new:SetScript("OnLeave", function() GameTooltip:Hide() end)
		end
	end

	function UpdateProfessionButton(self)
		local spellIndex = self:GetParent()["spellIndex" .. self:GetID()]
		local texture = GetSpellBookItemTexture(spellIndex, SpellBookFrame.bookType);
		local spellName, subSpellName = GetSpellBookItemName(spellIndex, SpellBookFrame.bookType);

		if self.new then
			self:Disable()
			self.new:SetAttribute("type1", "spell")
			self.new:SetAttribute("spell1", spellName)
			self.new:SetAttribute("alt-type1", "spell")
			self.new:SetAttribute("alt-spell1", spellName)
			self.new:SetAttribute("alt-unit1", "player")
			self.new:SetAttribute("shift-type1", "macro")
			self.new:SetAttribute("shift-macrotext1", "/run local sL,tL=GetSpellLink("..spellIndex..",'profession'); if tL then ChatEdit_InsertLink(tL) elseif sL then ChatEdit_InsertLink(sL) end");
		end

		local isPassive = IsPassiveSpell(spellIndex, SpellBookFrame.bookType);
		if ( isPassive ) then
			self.highlightTexture:SetTexture("Interface\\Buttons\\UI-PassiveHighlight");
			self.spellString:SetTextColor(PASSIVE_SPELL_FONT_COLOR.r, PASSIVE_SPELL_FONT_COLOR.g, PASSIVE_SPELL_FONT_COLOR.b);
		else
			self.highlightTexture:SetTexture("Interface\\Buttons\\ButtonHilight-Square");
			self.spellString:SetTextColor(NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b);
		end
		
		self.iconTexture:SetTexture(texture);
		local start, duration, enable = GetSpellCooldown(spellIndex, SpellBookFrame.bookType);
		CooldownFrame_SetTimer(self.cooldown, start, duration, enable);
		if ( enable == 1 ) then
			self.iconTexture:SetVertexColor(1.0, 1.0, 1.0);
		else
			self.iconTexture:SetVertexColor(0.4, 0.4, 0.4);
		end

		if ( self:GetParent().specializationIndex >= 0 and self:GetID() == self:GetParent().specializationOffset) then
			self.unlearn:Show();
		else
			self.unlearn:Hide();
		end
		
		self.spellString:SetText(spellName);
		self.subSpellString:SetText(subSpellName);	
		self.iconTexture:SetTexture(texture);
		
		SpellButton_UpdateSelection(self);
	end

	function FormatProfession(frame, index)
		if index then
			frame.missingHeader:Hide();
			frame.missingText:Hide();
			
			local name, texture, rank, maxRank, numSpells, spelloffset, skillLine, rankModifier, specializationIndex, specializationOffset = GetProfessionInfo(index);

			if numSpells > 1 then
				local skills = {}
				for i = 1, numSpells do
					local spellIndex = spelloffset + i
					local spellName, subSpellName = GetSpellBookItemName(spellIndex, SpellBookFrame.bookType)
					skills[spellName] = spellIndex
				end
				local i = 1
				for spellName, spellIndex in pairs(skills) do
					frame["spellIndex" .. i] = spellIndex
					i = i + 1
				end
				numSpells = i - 1
			elseif numSpells == 1 then
				frame.spellIndex1 = spelloffset + 1
				frame.spellIndex2 = nil
			else
				frame.spellIndex1 = nil
				frame.spellIndex2 = nil
			end

			frame.skillName = name;
			frame.spellOffset = spelloffset;
			frame.skillLine = skillLine;
			frame.specializationIndex = specializationIndex;
			frame.specializationOffset = specializationOffset;
			
			frame.statusBar:SetMinMaxValues(1,maxRank);
			frame.statusBar:SetValue(rank);
			
			local prof_title = "";
			for i=1,#PROFESSION_RANKS do
				local value,title = PROFESSION_RANKS[i][1], PROFESSION_RANKS[i][2]; 
				if maxRank < value then break end
				prof_title = title;
			end
			frame.rank:SetText(prof_title);
			
			frame.statusBar:Show();
			if rank == maxRank then
				frame.statusBar.capRight:Show();
			else
				frame.statusBar.capRight:Hide();
			end
			
			if frame.icon and texture then
				SetPortraitToTexture(frame.icon, texture);	
				frame.unlearn:Show();
			end
			
			frame.professionName:SetText(name);
			
			if ( rankModifier > 0 ) then
				frame.statusBar.rankText:SetFormattedText(TRADESKILL_RANK_WITH_MODIFIER, rank, rankModifier, maxRank);
			else
				frame.statusBar.rankText:SetFormattedText(TRADESKILL_RANK, rank, maxRank);
			end

			
			if numSpells <= 0 then		
				frame.button1:Hide();
				frame.button2:Hide();
			elseif numSpells == 1 then		
				frame.button2:Hide();
				frame.button1:Show();
				UpdateProfessionButton(frame.button1);
			else
				frame.button1:Show();
				frame.button2:Show();
				UpdateProfessionButton(frame.button1);
				UpdateProfessionButton(frame.button2);
			end
			
		else		
			frame.missingHeader:Show();
			frame.missingText:Show();
			
			if frame.icon then
				SetPortraitToTexture(frame.icon, "Interface\\Icons\\INV_Scroll_04");	
				frame.unlearn:Hide();			
				frame.specialization:SetText("");
			end			
			frame.button1:Hide();
			frame.button2:Hide();
			frame.statusBar:Hide();
			frame.rank:SetText("");
			frame.professionName:SetText("");		
		end
	end
	
end)
