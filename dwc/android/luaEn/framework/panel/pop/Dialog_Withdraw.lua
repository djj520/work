require "framework/panel/pop/PopUtil"
Dialog_Withdraw = class("Dialog_Withdraw", LuaBasePanel)
local this
local var

local function Close_Dialog()
    if var.isHiding then return end
    PopUtil.popOut(this)
end



local tabContent = 
{
   [1] = "bank_withdraw",
   [2] = "ali_withdraw",
   [3] = "bank_bind",
   [4] = "bank_bind_nation",
   [5] = "ali_bind",
   [6] = "record",
}

local bankCodeDic = {
    [3]={
        ["ICBC"] = "工商银行",
        ["ABC"] = "农业银行",
        ["CCB"] = "建设银行",
        ["SPDB"] = "浦发银行",
        ["CIB"] = "兴业银行",
        ["BCM"] = "交通银行",
        ["CEB"] = "光大银行",
        ["BCCB"] = "北京银行",
        ["CMB"] = "招商银行",
        ["GDB"] = "广发银行",

        ["SHB"] = "上海银行",
        ["BOC"] = "中国银行",
        ["HXB"] = "华夏银行",
        ["PAB"] = "平安银行",
        ["PSBC"] = "中国邮政",
    },
    [4]={
        ["AFF"] = "Affin Bank",
        ["ALB"] = "Alliance Bank",
        ["AMB"] = "AM Bank",
        ["BOC"] = "Bank Of China",
        ["BSN"] = "Bank Simpanan National",
        ["CIMB"] = "CIMB Bank",
        ["CITI"] = "Citi bank",
        ["HLB"] = "Hong Leong Bank",
        ["HSBC"] = "HSBC Bank",
        ["MBB"] = "Maybank",

        ["OCBC"] = "OCBC Bank",
        ["PBB"] = "Public Bank",
        ["RHB"] = "RHB Bank",
        ["UOB"] = "UOB Bank",
        ["SCTB"] = "Standard Chartered Bank",
    },
}

local function GetExchangeMoney(num, id)
    local list = MyUserData.oclist
    local gold = 0
    if list then
        for i =1,#list do
            if list[i].id == id then
                gold = num/list[i].exchange_rate
                gold = f.formatGameScoreZero(gold*100)
                break
            end
        end
    end
    return gold
end

local function OnGetInputSubmitHandler(ipt, text)
    if f.strIsNullOrEmpty(text) and var.wcBank==3 then return end
    local num = var.num_ipt:Text()
    num = tonumber(num)
    local gold = GetExchangeMoney(num,1)
    var.exchange.text = gold
end

local function ShowWithdrawInfo(index)
    var.alipayItem:SetActive(index==2)
    var.bankpayItem:SetActive(index==1)
end

local function UpdateBindButtonText()
    local hasAlipay = true
    if not MyUserData.bankInfo or f.strIsNullOrEmpty(MyUserData.bankInfo.alipay) then
        hasAlipay = false
    end

    if hasAlipay then
        var.bindAlipay_account.text = MyUserData.bankInfo.alipay
        var.bind_alipay_account_ipt:Text(MyUserData.bankInfo.alipay)
        var.bind_alipay_name_ipt:Text(MyUserData.bankInfo.alipayName)
    else
        var.bindAlipay_account.text = "暂未绑定"
    end
    var.hasAlipay = hasAlipay
    local hasBankCode = true
    if not MyUserData.bankInfo or f.strIsNullOrEmpty(MyUserData.bankInfo.bankCode) then
        hasBankCode = false
    end
    var.wcBank = nil
    if hasBankCode then
        for i = 3,4 do
            hasBankCode = bankCodeDic[i][MyUserData.bankInfo.bankCode]~=nil
            if hasBankCode then
                if i==3 then
                    var.logo_in:SetActive(true)
                    var.logo_out:SetActive(false)
                    var.bindBank_logo = var.bindBank_logo_in
                    var.bindBank_logo.spriteName = MyUserData.bankInfo.bankCode
                    var.bindBank_logo_out.gameObject:SetActive(false)
                else
                    var.logo_out:SetActive(true)
                    var.logo_in:SetActive(false)
                    var.bindBank_logo = var.bindBank_logo_out
                    var.bindBank_logo.text = MyUserData.bankInfo.bankCode
                    var.bindBank_logo_in.gameObject:SetActive(false)
                end
                var.bindBank_logo.gameObject:SetActive(true)
                var.bindBank_unbind:SetActive(false)
                var.wcBank = i
                break
            end
        end
    end
    if not hasBankCode then
       var.bindBank_logo_in.gameObject:SetActive(false)
       var.bindBank_logo_out.gameObject:SetActive(false)
        var.bindBank_unbind:SetActive(true)   
    end
    var.hasBankCode = hasBankCode
end
local function SetUserInfo()
    var.bank.text = f.formatGameScore(Data.MyUser.bank)
    UpdateBindButtonText()
end
local function OnShowed()
    SetUserInfo()
end

local function OnBackBindBankInfo(_, data)
    LM.N(CommonDefine.HideAvoidTouch)
   local msg;
    if data.code == "RC_OK" then
        msg = "绑定成功！"
    else
        msg = ServerDefine.TranslateRetCode(data, "绑定操作失败,%s")
    end
    f.addPopMessage(msg)
end

local function OnBackReqWithdraw(_, data)
    -- f.error("OnBackReqWithdraw", data.code)
    LM.N(CommonDefine.HideAvoidTouch)
    local msg;
    if data.code == "RC_OK" then
        msg = "提交成功！"
        var.lastGetHistoryTime = nil
    else
        msg = ServerDefine.TranslateRetCode(data, "提交失败,%s")
    end
     GameTip:Push(GTB.Tip, msg, 3)
end

local function GoToBindAlipay(obj,index)
     this:OnShowPanel(5)
end
local function GoToBindBank(obj,index)
    this:OnShowPanel(3)
end
local function GoToBindAccount(obj,index)
    this:DynamicOpenPanel({"pop.Dialog_UserCenter", "pop.atlas_usercenter"}, "Dialog_UserCenter", "showbindaccount")
    this:CSClose()
end

local function OnClickSubmit()
    local num = var.num_ipt:Text()
    num = tonumber(num)
    if not num or num<=0 then
        GameTip:Push(GTB.Tip, "请输入兑换金额!", 2) 
        return
    end
    if num%100~=0 then
        GameTip:Push(GTB.Tip, "兑换金额必须是100的整数倍!", 2) 
        return
    end
    if num>MyUserData.bank then
        GameTip:Push(GTB.Tip, "保险柜余额不足!", 2) 
        return
    end

    if f.strIsNullOrEmpty(MyUserData.account) then
        GameTip:Push(GTB.Tip, "您的账号是游客, 正式用户才能使用兑换功能, 是否前去绑定", 4, GoToBindAccount) 
        return
    end
    local way = var.way or 2
    if way == 2 and not var.hasAlipay then
        GameTip:Push(GTB.Tip, "暂未绑定支付宝, 是否前去绑定", 4, GoToBindAlipay) 
        return
    end
    if way == 1 and not var.hasBankCode then
        GameTip:Push(GTB.Tip, "暂未绑定银行卡, 是否前去绑定", 4, GoToBindBank) 
        return
    end
    if way == 2 and num>5000 then
        GameTip:Push(GTB.Tip, "您要提取的金额大于支付宝最大提现金额5000元，请用银行卡提现!", 3) 
        return
    end
    
    if way == 1 and num<500 then
        GameTip:Push(GTB.Tip, "您要提取的金额小于银行卡提现最小提现金额500元，请用支付宝提现!", 3) 
        return
    end

    if MyUserData.isTester then
        GameTip:Push(GTB.Tip, "该账号禁止提现", 2) 
        return
    end
    if way == 1 then 
        way = 2 
    else
        way = 1
    end
    Protocal.Hall:Send(CMD_Main.c2s_ReqWithdraw, {gold = num * 100, way = way})
    LM.N(CommonDefine.ShowAvoidTouch,5,"数据请求中")
end

local function removeList()
    if not var.historyList or #(var.historyList)<=0 then return end
    for i = #(var.historyList), 1, -1 do
        var.history_spawn:OnRecycle(table.remove(var.historyList, i)[1]);
    end
end

local function GetStateName(state, failure)
    if state==0 then return "已接收" end
    if state==1 or state==100 then return "处理中" end
    if state==2 then return failure end
    if state==3 then return "完成" end
    if state==10 then return "已撤消" end
    if state==100 then return "正在打款" end
    if state==200 then return "已退回" end
    return "-"
end

local function OnClickRemoveWithdrawReq(obj, id)
    LM.N(CommonDefine.ShowAvoidTouch, 2,"数据请求中")
    Protocal.Hall:Send(CMD_Main.c2s_RemoveWithdraw, {id = id})    
    var.toRemoveWithdrawId = id    
end
-- message WithdrawItem {
--     optional int32 id = 1;
--     optional uint32 gold = 2;
--     optional int32 way = 3; //1 支付宝 2 银行卡
--     optional string account = 4; //支付宝或者银行卡账号
--     optional uint32 state = 5; //0 初始 1 正在处理 2 执行失败 3 已经完成 10 玩家撤消
--     optional string failure = 6; //提现请求失败原因
--     optional uint32 createTime = 7; //创建时间
-- }   
local function ShowList(historyListData)
    removeList()
    var.historyList = var.historyList or {}
    local obj,widge
    local index = 1
    for i, data in ipairs(historyListData) do
        obj = var.history_spawn:Fetch("HistoryItem", var.history_container)
        table.insert(var.historyList,{obj, data.id})
        widget = obj:GetComponent("SimpleWidgetReference")        
        widget:GetComponentByIndex(0).text = f.formatGameScoreZero(data.gold).."元"
        widget:GetComponentByIndex(1).text = data.way == 1 and "支付宝" or "银行卡"
        widget:GetComponentByIndex(2).text = os.date("%Y-%m-%d %H:%M:%S", data.createTime)
        widget:GetComponentByIndex(3).text = GetStateName(data.state, data.failure)      
        widget:GetComponentByIndex(4).text = data.orderNo
        widget:GetComponentByIndex(5).text = f.formatGameScoreZero(data.fee).."元"
        if data.state == 0 then
            widget:GetGameObjectByIndex(0):SetActive(false)
            this:AddClickHandler(widget:GetGameObjectByIndex(0), OnClickRemoveWithdrawReq, data.id) 
        else
            EventUtil.RemoveClickHandler(widget:GetGameObjectByIndex(0), OnClickRemoveWithdrawReq)
            widget:GetGameObjectByIndex(0):SetActive(false)
        end     
        local str = data.failure  
        if f.strIsNullOrEmpty(str) then
            widget:GetGameObjectByIndex(1):SetActive(false)
        else
            widget:GetGameObjectByIndex(1):SetActive(true)
            widget:GetComponentByIndex(6).text = str
        end
    end
    var.history_grid:Reposition()
end

local function OnWithdrawUpdate(_, data)
    -- f.error("OnWithdrawUpdate", data.id, data.state, var.historyList)
    if var.historyList then
        for i, d in ipairs(var.historyList) do
            if d[2] == data.id then
                local obj = d[1]
                local widget = obj:GetComponent("SimpleWidgetReference")
                widget:GetComponentByIndex(3).text = GetStateName(data.state, data.failure)   
                local str = data.failure  
                if f.strIsNullOrEmpty(str) then
                    widget:GetGameObjectByIndex(1):SetActive(false)
                else
                    widget:GetGameObjectByIndex(1):SetActive(true)
                    widget:GetComponentByIndex(6).text = str
                end   
                break
            end
        end
    end
end

local function OnBackRemoveWithdraw(_, data)
    LM.N(CommonDefine.HideAvoidTouch)
    local msg;
    if data.code == "RC_OK" then
        msg = "撤消成功！"

    else
        msg = ServerDefine.TranslateRetCode(data, "提交失败,%s")
    end

    if data.code == "RC_OK" and var.historyList then
        for i = #(var.historyList), 1, -1 do
            if var.historyList[i][2] == var.toRemoveWithdrawId then
                var.history_spawn:OnRecycle(table.remove(var.historyList, i)[1]);
                break
            end
        end            
        var.history_grid:Reposition()
    end    
    var.toRemoveWithdrawId = nil
    GameTip:Push(GTB.Tip, msg, 3)
end


local function OnSendWithdrawList(_, data)
    -- f.error("OnSendWithdrawList", #(data.list))
    LM.N(CommonDefine.HideAvoidTouch)
    ShowList(data.list)
end

local function OpenWithdrawHistory(obj,index)
    var.history:SetActive(true)    
    if not var.lastGetHistoryTime then
        var.lastGetHistoryTime = os.time()
        LM.N(CommonDefine.ShowAvoidTouch, 2,"数据请求中")
        Protocal.Hall:Send(CMD_Main.c2s_ReqWithdrawList, {pageIndex = 1, pageSize = 10})        
    end
end

local function CloseWithdrawHistory()
    var.history:SetActive(false)
end

local function SetBankSelectorPos()
    local hasBankCode = true
    if not MyUserData.bankInfo or f.strIsNullOrEmpty(MyUserData.bankInfo.bankCode) then
        hasBankCode = false
    end
    if hasBankCode then
        for i = 3,4 do
            hasBankCode = bankCodeDic[i][MyUserData.bankInfo.bankCode]~=nil
            if hasBankCode then break end
        end
    end
    if hasBankCode then
        var.bank_selector:SetActive(true)
        var.bank_selector.transform.position = var.bankList[var.bind_choice][MyUserData.bankInfo.bankCode].transform.position
        var.selectBankCode = MyUserData.bankInfo.bankCode
        var.bind_bank_account_ipt:Text()
    else
        var.bank_selector:SetActive(false)
        var.selectBankCode = nil
    end
    var.bind_bank_account_ipt:Text(hasBankCode and (MyUserData.bankInfo.bankCardNum or "") or "")
    var.bind_bank_name_ipt:Text(hasBankCode and (MyUserData.bankInfo.bankName or "") or "")
end

local function OnClickBank(obj, code, zhui)
    var.selectBankCode = zhui..code
    var.bank_selector:SetActive(true)
    var.bank_selector.transform.position = var.bankList[var.bind_choice][code].transform.position
end

local function ShowBankList()
    local item
    if var.bind_choice == 3 then
        var.bank_container = var.bank_container_in
        var.bank_container_out.gameObject:SetActive(false)
        var.bank_grid = var.bank_grid_in
        item = "BankFlag"
    elseif var.bind_choice == 4 then
        var.bank_container = var.bank_container_out
        var.bank_container_in.gameObject:SetActive(false)
        var.bank_grid = var.bank_grid_out
        item = "NationalBank"
    end
    var.bank_container.gameObject:SetActive(true)
    if not var.bankList[var.bind_choice] then
        var.bankList[var.bind_choice] = {}
        local obj,widget,zhui
        for code, name in pairs(bankCodeDic[var.bind_choice]) do
            obj = var.bank_spawn:Fetch(item,var.bank_container)
            widget = obj:GetComponent("SimpleWidgetReference")
            if var.bind_choice == 3 then
                widget:GetComponentByIndex(0).spriteName = code;
                zhui = ""
            elseif var.bind_choice == 4 then
                widget:GetComponentByIndex(0).text = name;
                zhui = "MYR$"
            end            
            var.bankList[var.bind_choice][code] = obj
            this:AddClickHandler(obj, OnClickBank, code, zhui)
        end
        var.bank_grid:Reposition()        
    end
    SetBankSelectorPos()
end

local function OnSubmitBindAlipay()
    local alipayAccount = var.bind_alipay_account_ipt:Text()
    local alipayName = var.bind_alipay_name_ipt:Text()
    
    if f.strIsNullOrEmpty(alipayAccount) then GameTip:Push(GTB.Tip, "请输入支付宝账号!", 2) return end
    if f.strIsNullOrEmpty(alipayName) then GameTip:Push(GTB.Tip, "请输入姓名!", 2) return end
   
    if not f.isPhoneNum(alipayAccount) and not f.isEmail(alipayAccount) then
        GameTip:Push(GTB.Tip, "支付宝账号格式错误!", 2) 
        return
    end

    LM.N(CommonDefine.ShowAvoidTouch,5,"数据请求中")
    Protocal.Hall:Send(CMD_Main.c2s_BindBankInfo, {alipay = {account = alipayAccount, name = alipayName}})  
end

local function OnSubmitBindBank()
    if not var.selectBankCode then
        GameTip:Push(GTB.Tip, "请选择银行类别", 3);
        return
    end

    local bankCardNum = var.bind_bank_account_ipt:Text()
    local bankName = var.bind_bank_name_ipt:Text()
    
    if f.strIsNullOrEmpty(bankCardNum) then GameTip:Push(GTB.Tip, "请输入卡号!", 2) return end
    if f.strIsNullOrEmpty(bankName) then GameTip:Push(GTB.Tip, "请输入姓名!", 2) return end
   

    if string.len(bankCardNum)<6 then GameTip:Push(GTB.Tip, "银行卡号格式错误!", 2) return end  
    LM.N(CommonDefine.ShowAvoidTouch,5,"数据请求中")
    f.error("OnSubmitBindBank",var.selectBankCode,bankCardNum,bankName)
    Protocal.Hall:Send(CMD_Main.c2s_BindBankInfo, {bank = {bankCode = var.selectBankCode, bankCardNum = bankCardNum, bankName = bankName}})  
end

local function OnShowPanel(index)
    if index == 1 and MyUserData.isBank == 0 then GameTip:Push(GTB.Tip, "当前不支持银行卡提现!", 2) return end
    if index == 2 and MyUserData.isAlipay == 0 then GameTip:Push(GTB.Tip, "当前不支持支付宝提现!", 2) return end
    if var.currIndex then
        var.sprList[var.currIndex].spriteName = tabContent[var.currIndex].."_no"
        var.sprList[var.currIndex]:MakePixelPerfect()
    end
    var.sprList[index].spriteName = tabContent[index]
    var.sprList[index]:MakePixelPerfect()
    if var.currPanel then
        var.currPanel:SetActive(false)
    end
    if index == 1 or index ==2 then
        var.withdraw:SetActive(true)
        var.currPanel = var.withdraw
        var.way = index
        ShowWithdrawInfo(index)
    elseif index == 3 or index == 4 then
        var.bindBank:SetActive(true)
        var.currPanel = var.bindBank
        var.bind_choice = index
        ShowBankList()
    elseif index == 5 then
        var.bindAli:SetActive(true)
        var.currPanel = var.bindAli
    else
        var.history:SetActive(true)
        var.currPanel = var.history
        OpenWithdrawHistory()
    end
    var.currIndex = index
end

local function OnClickTab(obj, index)
    if var.currIndex ~= index then
        OnShowPanel(index)
    end
end

local function AccordPayShowPanelAndTab( ... )
    if var.tabList then
        for k,obj in ipairs(var.tabList) do
            var.spawn:OnRecycle(obj)
        end
    end
    var.tabList = {}
    var.sprList = {}
    for i = 1,#tabContent do
        local isContinue = true
        if i == 4 and not var.isShowInter then isContinue = false end
        if isContinue then
            local obj = var.spawn:Fetch("Butn", var.container)
            table.insert(var.tabList, obj)
            local widget = obj:GetComponent("SimpleWidgetReference")
            local spr = widget:GetComponentByIndex(0)
            spr.spriteName = tabContent[i].."_no"
            spr:MakePixelPerfect()
            table.insert(var.sprList, i, spr)
            this:AddClickHandler(obj, OnClickTab, i)
        end
    end
    var.grid:Reposition()
    if not MyUserData.isBank then 
        OnShowPanel(1) 
    else
        if MyUserData.isBank==1 then
            OnShowPanel(1)
        elseif MyUserData.isAlipay==1 then
            OnShowPanel(2)
        else
            OnShowPanel(3)
        end  
    end
    if MyUserData.fee then
        var.procedure.text = MyUserData.fee.."%"
    else
        var.procedure.text = "5%"
    end
end

function Dialog_Withdraw:OnShowPanel(index)
    OnShowPanel(index)
end

function Dialog_Withdraw:Init()
    this = self;
    var = this.var;
    this.super.Init(this);

    var.bankList = {}
	this:AddClickHandler(this:Find("Fix/Close"), Close_Dialog) 

    var.spawn = this:Find("Dynamic/Tab/Assets", "SpawnManager")
    var.grid = this:Find("Dynamic/Tab/Container/Grid", "UIGrid")
    var.container = this:Find("Dynamic/Tab/Container/Grid", "Transform")

    var.bindBank = this:Find("Dynamic/Content/BindBank")
    var.bindAli = this:Find("Dynamic/Content/BindAlipay")
    var.withdraw = this:Find("Dynamic/Content/Withdraw")
    var.history = this:Find("Dynamic/Content/History")

    var.bank_spawn = this:Find("Dynamic/Content/BindBank/BankList/Assets", "SpawnManager")
    var.bank_grid_in = this:Find("Dynamic/Content/BindBank/BankList/Container_In", "UIGrid")
    var.bank_grid_out = this:Find("Dynamic/Content/BindBank/BankList/Container_Out", "UIGrid")
    var.bank_container_in = this:Find("Dynamic/Content/BindBank/BankList/Container_In", "Transform")
    var.bank_container_out = this:Find("Dynamic/Content/BindBank/BankList/Container_Out", "Transform")
    var.bank_selector = this:Find("Dynamic/Content/BindBank/BankList/Selector")

    this:AddClickHandler(this:Find("Dynamic/Content/BindBank/Submit"), OnSubmitBindBank)
    var.bind_bank_account_ipt = LuaUIInput.New(nil, this:Find("Dynamic/Content/BindBank/Account/Input"), this:Find("Dynamic/Content/BindBank/Account/Input","UIInput"), true)
    var.bind_bank_name_ipt = LuaUIInput.New(nil, this:Find("Dynamic/Content/BindBank/Name/Input"), this:Find("Dynamic/Content/BindBank/Name/Input","UIInput"), true)

    this:AddClickHandler(this:Find("Dynamic/Content/BindAlipay/Submit"), OnSubmitBindAlipay)
    var.bind_alipay_account_ipt = LuaUIInput.New(nil, this:Find("Dynamic/Content/BindAlipay/Account/Input"), this:Find("Dynamic/Content/BindAlipay/Account/Input","UIInput"), true)
    var.bind_alipay_name_ipt = LuaUIInput.New(nil, this:Find("Dynamic/Content/BindAlipay/Name/Input"), this:Find("Dynamic/Content/BindAlipay/Name/Input","UIInput"), true)

    var.bank = this:Find("Dynamic/Content/Withdraw/Bank/Label","UILabel")

    var.alipayItem = this:Find("Dynamic/Content/Withdraw/Alipa")
    var.bankpayItem = this:Find("Dynamic/Content/Withdraw/BindBank")
    -- var.gameInfo = this:Find("Dynamic/Content/Info", "UILabel")

    -- this:AddClickHandler(this:Find("Dynamic/Content/History"), OpenWithdrawHistory)
    -- this:AddClickHandler(this:Find("Dynamic/Content/Alipa/Bind"), GoToBindAlipay)
    -- this:AddClickHandler(this:Find("Dynamic/Content/BindBank/Bind"), GoToBindBank)
    var.bindAlipay_account = this:Find("Dynamic/Content/Withdraw/Alipa/Account","UILabel")

    -- var.bindAlipay_text = this:Find("Dynamic/Content/Alipa/Bind/Text","UILabel")
    -- var.bindBank_text = this:Find("Dynamic/Content/BindBank/Bind/Text","UILabel")
    var.logo_in = this:Find("Dynamic/Content/Withdraw/BindBank/Logo")
    var.logo_out = this:Find("Dynamic/Content/Withdraw/BindBank/NationalBank")
    var.bindBank_logo_in = this:Find("Dynamic/Content/Withdraw/BindBank/Logo","UISprite")
    var.bindBank_logo_out = this:Find("Dynamic/Content/Withdraw/BindBank/NationalBank/Label", "UILabel")
    var.exchange = this:Find("Dynamic/Content/Withdraw/BindBank/NationalBank/Exchange/Label", "UILabel")
    var.exchange.text = 0
    var.bindBank_unbind = this:Find("Dynamic/Content/Withdraw/BindBank/Account")
    this:AddClickHandler(this:Find("Dynamic/Content/Withdraw/Submit"), OnClickSubmit)
    var.num_ipt = LuaUIInput.New(nil, this:Find("Dynamic/Content/Withdraw/WithdrawNum/Money/Input"), this:Find("Dynamic/Content/Withdraw/WithdrawNum/Money/Input","UIInput"), true)    
    var.num_ipt:AddOnSubmitHandler(OnGetInputSubmitHandler)
    -- var.history = this:Find("Dynamic/History")
    var.history_spawn = this:Find("Dynamic/Content/History/Content/Assets","SpawnManager")
    var.history_container = this:Find("Dynamic/Content/History/Content/List","Transform")
    var.history_grid = this:Find("Dynamic/Content/History/Content/List","UIGrid")

    var.procedure = this:Find("Dynamic/Content/Withdraw/Tip/Label", "UILabel")
 
    -- if MyUserData.channel then
        var.isShowInter = false--string.sub(MyUserData.channel,1,4) == "MY00"
    -- end

    -- this:AddClickHandler(this:Find("Dynamic/History/Close"), CloseWithdrawHistory)  
end

local function RemoveEvent()
    if var.r then
        Proxy.Hall:RemoveCmdListener(CMD_Main.s2c_BackRemoveWithdraw, OnBackRemoveWithdraw);
        Proxy.Hall:RemoveCmdListener(CMD_Main.s2c_SendWithdrawList, OnSendWithdrawList); 
        Proxy.Hall:RemoveCmdListener(CMD_Main.s2c_BackReqWithdraw, OnBackReqWithdraw);
        Proxy.Hall:RemoveCmdListener(CMD_Main.s2c_SendBindBankInfo, UpdateBindButtonText);    
        Proxy.Hall:RemoveCmdListener(CMD_Main.s2c_WithdrawUpdate, OnWithdrawUpdate);   
        Proxy.Hall:RemoveCmdListener(CMD_Main.s2c_BackBindBankInfo, OnBackBindBankInfo);     
        LM.R(MessagerName.BasicUserInfoUpdated, SetUserInfo);
        var.r = false
    end
end
function Dialog_Withdraw:OnShow()
    this.super.OnShow(this);
    PopUtil.popIn(this, "Fix/Mask")  
    this:AddCSCoroutine(OnShowed, 1, 0.2)    
    AccordPayShowPanelAndTab()

    Proxy.Hall:AddCmdListener(CMD_Main.s2c_BackRemoveWithdraw, OnBackRemoveWithdraw);
    Proxy.Hall:AddCmdListener(CMD_Main.s2c_SendWithdrawList, OnSendWithdrawList); 
    Proxy.Hall:AddCmdListener(CMD_Main.s2c_BackReqWithdraw, OnBackReqWithdraw);
    Proxy.Hall:AddCmdListener(CMD_Main.s2c_SendBindBankInfo, UpdateBindButtonText, -1);    
    Proxy.Hall:AddCmdListener(CMD_Main.s2c_WithdrawUpdate, OnWithdrawUpdate);
    Proxy.Hall:AddCmdListener(CMD_Main.s2c_BackBindBankInfo, OnBackBindBankInfo);
    LM.A(MessagerName.BasicUserInfoUpdated, SetUserInfo);
    var.r = true             
end

function Dialog_Withdraw:OnHide()
    this.super.OnHide(this)
    RemoveEvent()
end
function Dialog_Withdraw:OnDestroy()
    RemoveEvent()
    var = nil;
    this.super.OnDestroy(this);
end
Dialog_Withdraw.New("Dialog_Withdraw", nil, "module")