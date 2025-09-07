---@class ProcessorConfigurationDialog : MessageDialog
---@field configurations ProcessorConfiguration[]
---@field list SmoothListElement
---@field unitsList SmoothListElement
---@field dialogTitle TextElement
---@field dialogUnitsTitle TextElement
---@field toggleHudButton ButtonElement
---
---@field processor Processor | nil
---@field displayUnits ProcessorUnit[]
---
---@field superClass fun(): MessageDialog
ProcessorConfigurationDialog = {}

ProcessorConfigurationDialog.CLASS_NAME = 'ProcessorConfigurationDialog'
ProcessorConfigurationDialog.XML_FILENAME = g_currentModDirectory .. 'xml/dialogs/ProcessorConfigurationDialog.xml'

local ProcessorConfigurationDialog_mt = Class(ProcessorConfigurationDialog, MessageDialog)

function ProcessorConfigurationDialog.new()
    local self = MessageDialog.new(nil, ProcessorConfigurationDialog_mt)
    ---@cast self ProcessorConfigurationDialog

    self.configurations = {}
    self.displayUnits = {}

    return self
end

function ProcessorConfigurationDialog:delete()
    self:superClass().delete(self)

    FocusManager.guiFocusData[ProcessorConfigurationDialog.CLASS_NAME] = {
        idToElementMapping = {}
    }
end

function ProcessorConfigurationDialog:load()
    g_gui:loadGui(ProcessorConfigurationDialog.XML_FILENAME, ProcessorConfigurationDialog.CLASS_NAME, self)
end

function ProcessorConfigurationDialog:onGuiSetupFinished()
    self:superClass().onGuiSetupFinished(self)

    self.list:setDataSource(self)
    self.unitsList:setDataSource(self)
end

---@param processor Processor
function ProcessorConfigurationDialog:show(processor)
    if processor ~= nil then
        self.processor = processor
        g_gui:showDialog(ProcessorConfigurationDialog.CLASS_NAME)
    end
end

function ProcessorConfigurationDialog:onOpen()
    self:superClass().onOpen(self)

    local config = self.processor:getConfiguration()

    if config ~= nil then
        self.dialogTitle:setText(config:getDialogTitle())
    else
        self.dialogTitle:setText()
    end

    self:updateConfigurations()

    for _, config in ipairs(self.configurations) do
        if config == self.processor.config then
            self.list.soundDisabled = true
            self.list:setSelectedIndex(config.index)
            self.list.soundDisabled = false
            break
        end
    end

    self:updateDisplayUnits()
    self:updateMenuButtons()
end

function ProcessorConfigurationDialog:onClose()
    self:superClass().onClose(self)

    self.displayUnits = {}
    self.configurations = {}
    self.processor = nil
end

function ProcessorConfigurationDialog:updateConfigurations()
    self.configurations = self.processor.configurations
    self.list:reloadData()
end

function ProcessorConfigurationDialog:onClickApply()
    self:applyConfiguration()
end

function ProcessorConfigurationDialog:onClickToggleHud()
    g_processorGui:setEnableHUD(not g_processorGui.enableHud)
    self:updateMenuButtons()
end

---@return ProcessorConfiguration | nil
function ProcessorConfigurationDialog:getSelectedConfiguration()
    return self.configurations[self.list:getSelectedIndexInSection()]
end

---@param list SmoothListElement
---@param section number
---@return number
function ProcessorConfigurationDialog:getNumberOfItemsInSection(list, section)
    if list == self.list then
        return #self.configurations
    else
        return #self.displayUnits
    end
end

---@param list SmoothListElement
---@param section number
---@param index number
---@param cell ListItemElement
function ProcessorConfigurationDialog:populateCellForItemInSection(list, section, index, cell)
    if list == self.list then
        local config = self.configurations[index]

        if config ~= nil then
            local primaryUnit = config:getPrimaryUnit()

            cell:getAttribute('title'):setText(config.name)
            cell:getAttribute('image'):setImageFilename(primaryUnit.fillType.hudOverlayFilename)
            cell:getAttribute('text'):setText(primaryUnit.fillType.title)
            cell:getAttribute('info'):setText(string.format('%i l/s', config.litersPerSecond))
        end
    else
        local unit = self.displayUnits[index]

        if unit ~= nil then
            local ratioText = tostring(MathUtil.round(100 * unit.ratio)) .. '%'

            cell:getAttribute('title'):setText(unit.fillType.title)
            cell:getAttribute('image'):setImageFilename(unit.fillType.hudOverlayFilename)
            cell:getAttribute('ratio'):setText(ratioText)
        end
    end
end

---@param list SmoothListElement
---@param section number
---@param index number
---@param cell ListItemElement
function ProcessorConfigurationDialog:onItemDoubleClick(list, section, index, cell)
    if list == self.list then
        self:applyConfiguration(index)
    end
end

---@param list SmoothListElement
---@param section number
---@param index number
function ProcessorConfigurationDialog:onListSelectionChanged(list, section, index)
    if list == self.list then
        self:updateDisplayUnits()
    end
end

function ProcessorConfigurationDialog:updateDisplayUnits()
    local config = self:getSelectedConfiguration()

    if config ~= nil then
        self.displayUnits = {}

        for _, unit in ipairs(config:getSecondaryUnits()) do
            if not unit.hidden then
                table.insert(self.displayUnits, unit)
            end
        end

        self.dialogUnitsTitle:setText(config:getUnitsListTitle())
        self.dialogUnitsTitle:setVisible(true)
    else
        self.displayUnits = {}

        self.dialogUnitsTitle:setVisible(false)
    end

    self.unitsList:reloadData()
end

---@param index number | nil
function ProcessorConfigurationDialog:applyConfiguration(index)
    index = index or self.list:getSelectedIndexInSection()

    local config = self.configurations[index]

    if config ~= nil then
        self.processor.vehicle:setProcessorConfigurationIndex(index)
    end

    self:close()
end

function ProcessorConfigurationDialog:updateMenuButtons()
    if self.toggleHudButton ~= nil then
        if g_processorGui.enableHud then
            self.toggleHudButton:setText(ProcessorGUI.L10N_TEXTS.DISABLE_HUD)
        else
            self.toggleHudButton:setText(ProcessorGUI.L10N_TEXTS.ENABLE_HUD)
        end
    end
end
