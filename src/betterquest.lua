local acutil = require("acutil");

local filterEnabled = true;
local onlyShowLevel = true;
local onlyShowMap = true;

function BETTERQUEST_ON_INIT()
	BETTERQUEST_CREATE_FILTER_CHECKBOX();
	acutil.setupHook(BETTERQUEST_POSSIBLE_UI_OPEN_CHECK, "SCR_POSSIBLE_UI_OPEN_CHECK");
	acutil.setupHook(BETTERQUEST_UPDATE_ALLQUEST, "UPDATE_ALLQUEST");
	acutil.setupHook(QUEST_ON_INIT_HOOKED, "QUEST_ON_INIT");
end

function BETTERQUEST_CREATE_FILTER_CHECKBOX()
	local frame = ui.GetFrame('quest');
	local ctrl = frame:CreateOrGetControl('button', 'BETTERQUEST_FILTER', 0, 0, 150, 30);
	AUTO_CAST(ctrl);
	ctrl:SetMargin(30, 60, 0, 70);
	ctrl:SetGravity(ui.LEFT, ui.TOP);
	ctrl:SetText('{@st42b}BetterQuest Filters{/}');
	ctrl:SetClickSound('button_click_big');
	ctrl:SetOverSound('button_over');
	ctrl:SetEventScript(ui.LBUTTONUP, 'BETTERQUEST_OPEN_POPUP');
	
	
	
	local ctrl = frame:CreateOrGetControl('button', 'BETTERQUEST_UNCHECK', 0, 0, 150, 30);
	AUTO_CAST(ctrl);
	ctrl:SetMargin(380, 60, 0, 70);
	ctrl:SetGravity(ui.LEFT, ui.TOP);
	ctrl:SetText('{@st42b}Uncheck All{/}');
	ctrl:SetClickSound('button_click_big');
	ctrl:SetOverSound('button_over');
	ctrl:SetEventScript(ui.LBUTTONUP, 'BETTERQUEST_UNCHECK_ALL');
	
	
	--ctrl:SetCheck(filterEnabled == true and 0 or 1);
	
end

function BETTERQUEST_OPEN_POPUP()
	local t,p = pcall(BETTERQUEST_OPEN_POPUP_S, invIndex);
	if not(t) then
		print("BetterQuest ERROR: "..tostring(p));
	end
end

function BETTERQUEST_OPEN_POPUP_S()

	local context = ui.CreateContextMenu("CONTEXT_CLASSICINVENTORY_RBTN", "{#FFFF88}{b}BetterQuest Filter{/}{/}", 0, 0, 200, 0);


	local strShowAllScp = string.format("BETTERQUEST_TOGGLE_FILTER()");
	local strFilterLevelScp = string.format("BETTERQUEST_TOGGLE_FILTERLEVEL()");
	local strFilterMapScp = string.format("BETTERQUEST_TOGGLE_FILTERMAP()");	
	
	ui.AddContextMenuItem(context, "{img fullgray 249 1}{s4} {/}{nl}", "None");
	
	ui.AddContextMenuItem(context, (filterEnabled == false and "{img MCC_check 10 10}" or "{img None_Mark 10 10}").." Show All Eligible", strShowAllScp);
	ui.AddContextMenuItem(context, (onlyShowLevel == false and "{img MCC_check 10 10}" or "{img None_Mark 10 10}").." Show In Level Range (+-10)", strFilterLevelScp);
	ui.AddContextMenuItem(context, (onlyShowMap == false and "{img MCC_check 10 10}" or "{img None_Mark 10 10}").." Show In Map", strFilterMapScp);
	
	context:Resize(250, context:GetHeight());
	ui.OpenContextMenu(context);
	
end

function BETTERQUEST_UNCHECK_ALL()
	local t,p = pcall(BETTERQUEST_UNCHECK_ALL_S, invIndex);
	if not(t) then
		print("BetterQuest ERROR: "..tostring(p));
	end
end

function BETTERQUEST_UNCHECK_ALL_S()
	local clsList, cnt = GetClassList("QuestProgressCheck");
	local frame = ui.GetFrame('quest');
	local questGbox = frame:GetChild('questGbox');

	local quests = {}
	for i = 0, cnt -1 do
		quests[i] = GetClassByIndexFromList(clsList, i);
	end

	for i = 0, cnt -1 do
		--local questIES = GetClassByIndexFromList(clsList, i);
		local questIES = quests[i];
		local ctrlName = "_Q_" .. questIES.ClassID;
		local questCtrl = questGbox:GetChild(ctrlName);
		if questCtrl ~= nil then
			local checkBox = GET_CHILD(questCtrl, "save", "ui::CCheckBox");
			if checkBox:IsChecked() == 1 then
				checkBox:SetCheck(0);
				quest.RemoveCheckQuest(questIES.ClassID);
			end
		end
	end
	
	local questframe2 = ui.GetFrame("questinfoset_2");
	UPDATE_QUESTINFOSET_2(questframe2);
	
end

local refreshQuestFrame = function()
	local topFrame = ui.GetFrame('quest');
	local questbox = GET_CHILD(topFrame, 'questbox', 'ui::CTabControl');
	local currentTabIndex = questbox:GetSelectItemIndex();
	if currentTabIndex == 0 then
		UPDATE_ALLQUEST(topFrame);
	elseif currentTabIndex == 1 then
		UPDATE_ALLQUEST_ABANDONLIST(topFrame);
	end
end

local refreshQuestInfoFrame = function()
	local frame = ui.GetFrame('questinfo');
	UPDATE_QUESTMARK(frame, '', '', 0);
end

local refreshQuestInfoSet2Frame = function()
	local frame = ui.GetFrame('questinfoset_2');
	UPDATE_QUESTINFOSET_2(frame);
end

function BETTERQUEST_TOGGLE_FILTER()
	filterEnabled = not filterEnabled;
	refreshQuestFrame();
	refreshQuestInfoFrame();
	refreshQuestInfoSet2Frame();
end

function BETTERQUEST_TOGGLE_FILTERLEVEL()
	onlyShowLevel = not onlyShowLevel;
	refreshQuestFrame();
	refreshQuestInfoFrame();
	refreshQuestInfoSet2Frame();
end

function BETTERQUEST_TOGGLE_FILTERMAP()
	onlyShowMap = not onlyShowMap;
	refreshQuestFrame();
	refreshQuestInfoFrame();
	refreshQuestInfoSet2Frame();
end

function BETTERQUEST_POSSIBLE_UI_OPEN_CHECK(pc, questIES)
	if filterEnabled == false then
		return 'OPEN';
	end

	if questIES.PossibleUI_Notify == 'NO' then
		return 'HIDE';
	end

	if questIES.QuestMode ~= 'MAIN' and questIES.Check_QuestCount > 0 then
		local sObj = GetSessionObject(pc, 'ssn_klapeda');
		local result1 = SCR_QUEST_CHECK_MODULE_QUEST(pc, questIES, sObj);
		if result1 == 'YES' then
			return 'OPEN';
		end
	elseif questIES.QuestMode == 'MAIN' or questIES.PossibleUI_Notify == 'UNCOND' then
		return 'OPEN';
	end

	return 'HIDE';
end

function BETTERQUEST_UPDATE_ALLQUEST(frame, msg, isNew, questID, isNewQuest)
	local pc = GetMyPCObject();
	local mylevel = info.GetLevel(session.GetMyHandle());
	local posY = 60;

	local sobjIES = GET_MAIN_SOBJ();
	local questGbox = frame:GetChild('questGbox');

	local newCtrlAdded = false;
	if questID ~= nil and questID > 0 then
		local questIES = GetClassByType("QuestProgressCheck", questID);
		local result = SCR_QUEST_CHECK_C(pc, questIES.ClassName);
		local ctrlName = "_Q_" .. questIES.ClassID;

		local isRemoved = false;
		
		if onlyShowLevel == false then
			if not (questIES.Level <  mylevel+10 and questIES.Level > mylevel-10) then
				questGbox:RemoveChild(ctrlName);
				isRemoved = true;
			end
		end
		if onlyShowMap == false then
			if not (GetZoneName(pc) == questIES.StartMap) then
				questGbox:RemoveChild(ctrlName);
				isRemoved = true;
			end
		end
			
			
		if not isRemoved then
			
			-- ???? ????? ?????????? ???? ?????????? ui???? ???? ????.
			if isNewQuest == 0 and isNew == 1 then
				questGbox:RemoveChild(ctrlName);
			elseif QUEST_ABANDON_RESTARTLIST_CHECK(questIES, sobjIES) == 'NOTABANDON' then
				local newY = SET_QUEST_LIST_SET(frame, questGbox, posY, ctrlName, questIES, result, isNew, questID);
				if newY ~= posY then
					newCtrlAdded = true;
				end
				posY = newY;
			end
		
		end

	else
		-- Update All
		local clsList, cnt = GetClassList("QuestProgressCheck");

		--Sort Init
		local quests = {}
		for i = 0, cnt -1 do
			quests[i] = GetClassByIndexFromList(clsList, i);
		end
		table.sort(quests,questSort);
		--Sort End

		for i = 0, cnt -1 do
			local questIES = quests[i]; --
			local questAutoIES = GetClass('QuestProgressCheck_Auto',questIES.ClassName)
			local ctrlName = "_Q_" .. questIES.ClassID;
			
			local isRemoved = false;
			
			if onlyShowLevel == false then
				if not (questIES.Level <  mylevel+10 and questIES.Level > mylevel-10) then
					questGbox:RemoveChild(ctrlName);
					isRemoved = true;
				end
			end
			if onlyShowMap == false then
				if not (GetZoneName(pc) == questIES.StartMap) then
					questGbox:RemoveChild(ctrlName);
					isRemoved = true;
				end
			end
			

			if questIES.ClassName ~= "None" and not isRemoved then
				local abandonCheck = QUEST_ABANDON_RESTARTLIST_CHECK(questIES, sobjIES)
				if abandonCheck == 'NOTABANDON' or abandonCheck == 'ABANDON/NOTLIST' then
					
					local result = SCR_QUEST_CHECK_C(pc, questIES.ClassName);
					if IS_ABOUT_JOB(questIES) == true then
						if result ~= 'IMPOSSIBLE' and result ~= 'None' then
							posY = SET_QUEST_LIST_SET(frame, questGbox, posY, ctrlName, questIES, result, isNew, questID);
						end
					else
						posY = SET_QUEST_LIST_SET(frame, questGbox, posY, ctrlName, questIES, result, isNew, questID);
					end
				else
					questGbox:RemoveChild(ctrlName);
				end
			end
		end
	end

	ALIGN_QUEST_CTRLS(questGbox);
	if isNewQuest == nil then
		UPDATE_QUEST_DETAIL(frame, questID);
	elseif questID ~= nil and isNewQuest > 0 then
		local questIES = GetClassByType("QuestProgressCheck", questID);
		if newCtrlAdded == true then
			UPDATE_QUEST_DETAIL(frame, questID);
		end
	end
	updateQuestName()
	frame:Invalidate();
end


function doQuestThings(questIES, questname, nametxt)

	if questIES.QuestMode == 'REPEAT' then
		local pc = GetMyPCObject();
		local sObj = GetSessionObject(pc, 'ssn_klapeda')
		if sObj ~= nil then
			if questIES.Repeat_Count ~= 0 then
				questname = "[" .. questIES.Level .. "] " .. questIES.Name..ScpArgMsg("Auto__-_BanBog({Auto_1}/{Auto_2})","Auto_1", sObj[questIES.QuestPropertyName..'_R'] + 1, "Auto_2",questIES.Repeat_Count)
			else
				questname = "[" .. questIES.Level .. "] " .. questIES.Name..ScpArgMsg("Auto__-_BanBog({Auto_1}/MuHan)","Auto_1", sObj[questIES.QuestPropertyName..'_R'])
			end
		end
	elseif questIES.QuestMode == 'PARTY' then
		local pc = GetMyPCObject();
		local sObj = GetSessionObject(pc, 'ssn_klapeda')
		if sObj ~= nil then
			questname = "[" .. questIES.Level .. "] " .. questIES.Name..ScpArgMsg("Auto__-_BanBog({Auto_1}/{Auto_2})","Auto_1", sObj.PARTY_Q_COUNT1 + 1, "Auto_2",CON_PARTYQUEST_DAYMAX1)
		end
	end
	questname = "[" .. questIES.Level .. "] " .. questIES.Name;

	if questIES.QuestMode == 'MAIN' then
		nametxt:SetText("[" .. questIES.Level .. "] "..QUEST_TITLE_FONT..'{#FF6600}'..questname)
	else
		nametxt:SetText("[" .. questIES.Level .. "] "..QUEST_TITLE_FONT..questname)
	end
	nametxt:SetText(questname);

end


function updateQuestName()
	local frame = ui.GetFrame('quest');
	local questGbox = frame:GetChild('questGbox');
	local mylevel = info.GetLevel(session.GetMyHandle());

	local clsList, cnt = GetClassList("QuestProgressCheck");
	for i = 0, cnt -1 do

		local questIES = GetClassByIndexFromList(clsList, i);
		local ctrlName = "_Q_" .. questIES.ClassID;
		
		local Quest_Ctrl = GET_CHILD(questGbox, ctrlName, "ui::CControlSet");
		if Quest_Ctrl ~= nil then
			local nametxt = GET_CHILD(Quest_Ctrl, "name", "ui::CRichText");
			

				doQuestThings(questIES, questname, nametxt);

		end

	end
end

function questSort(a, b)
	return a.Level > b.Level
end

function QUEST_ON_INIT_HOOKED(addon, frame)
	_G["QUEST_ON_INIT_OLD"](addon, frame);
	BETTERQUEST_CREATE_FILTER_CHECKBOX();
end
