
function BETTERQUEST_ON_INIT()
	BETTERQUEST_CREATE_FILTER_CHECKBOX();
end

function BETTERQUEST_CREATE_FILTER_CHECKBOX()
	local frame = ui.GetFrame('quest');

	
	local ctrl = frame:CreateOrGetControl('button', 'BETTERQUEST_UNCHECK', 0, 0, 100, 30);
	AUTO_CAST(ctrl);
	ctrl:SetMargin(420, 65, 0, 70);
	ctrl:SetGravity(ui.LEFT, ui.TOP);
	ctrl:SetText('{@st42b}Uncheck All{/}');
	ctrl:SetClickSound('button_click_big');
	ctrl:SetOverSound('button_over');
	ctrl:SetEventScript(ui.LBUTTONUP, 'BETTERQUEST_UNCHECK_ALL');
	ctrl:SetSkinName("test_pvp_btn");
	
	
end


function BETTERQUEST_UNCHECK_ALL()
	local t,p = pcall(BETTERQUEST_UNCHECK_ALL_S, invIndex);
	if not(t) then
		print("BetterQuest ERROR: "..tostring(p));
	end
end

function BETTERQUEST_UNCHECK_ALL_S()
	
	QUEST_RESET_CHASE();
	
end

