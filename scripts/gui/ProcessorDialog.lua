---@class ProcessorDialog : MessageDialog
---@field configurations Configuration[]
---@field list SmoothListElement
---@field listTitle TextElement
---@field unitsList SmoothListElement
---@field unitsListTitle TextElement
---@field toggleHudButton ButtonElement
---@field processor Processor | nil
---@field units ConfigurationUnit[]
---
---@field superClass fun(): MessageDialog
ProcessorDialog = {}

ProcessorDialog.CLASS_NAME = 'ProcessorDialog'
ProcessorDialog.XML_FILENAME = g_currentModDirectory .. 'xml/dialogs/ProcessorDialog.xml'

local ProcessorDialog_mt = Class(ProcessorDialog, MessageDialog)

---@return ProcessorDialog
---@nodiscard
function ProcessorDialog.new()
    local self = MessageDialog.new(nil, ProcessorDialog_mt)
    ---@cast self ProcessorDialog

    self.configurations = {}
    self.units = {}

    return self
end

function ProcessorDialog:delete()
    self:superClass().delete(self)

    FocusManager.guiFocusData[ProcessorDialog.CLASS_NAME] = {
        idToElementMapping = {}
    }
end

function ProcessorDialog:load()
    g_gui:loadGui(ProcessorDialog.XML_FILENAME, ProcessorDialog.CLASS_NAME, self)
end

function ProcessorDialog:onGuiSetupFinished()
    self:superClass().onGuiSetupFinished(self)

    self.list:setDataSource(self)
    self.unitsList:setDataSource(self)
end

---@param processor Processor
function ProcessorDialog:show(processor)
    if processor ~= nil then
        self.processor = processor
        g_gui:showDialog(ProcessorDialog.CLASS_NAME)
    end
end

function ProcessorDialog:onOpen()
    self:superClass().onOpen(self)

    local currentConfiguration = self.processor.currentConfiguration

    if currentConfiguration ~= nil then
        self.listTitle:setText(currentConfiguration:getUnitTypeName())
    else
        self.listTitle:setText()
    end

    self:updateConfigurations()

    for _, configuration in ipairs(self.configurations) do
        if configuration == currentConfiguration then
            self.list.soundDisabled = true
            self.list:setSelectedIndex(configuration.index)
            self.list.soundDisabled = false
            break
        end
    end

    self:updateUnits()
    self:updateMenuButtons()
end

function ProcessorDialog:onClose()
    self:superClass().onClose(self)

    self.units = {}
    self.configurations = {}
    self.processor = nil
end

function ProcessorDialog:updateConfigurations()
    self.configurations = self.processor.configurations
    self.list:reloadData()
end

---@return Configuration | nil
function ProcessorDialog:getSelectedConfiguration()
    return self.configurations[self.list:getSelectedIndexInSection()]
end

---@param list SmoothListElement
---@param section number
---@return number
function ProcessorDialog:getNumberOfItemsInSection(list, section)
    if list == self.list then
        return #self.configurations
    else
        return #self.units
    end
end

---@param list SmoothListElement
---@param section number
---@param index number
---@param cell ListItemElement
function ProcessorDialog:populateCellForItemInSection(list, section, index, cell)
    if list == self.list then
        local configuration = self.configurations[index]

        if configuration ~= nil then
            local unit = configuration:getUnit()

            cell:getAttribute('title'):setText(configuration.displayName)
            cell:getAttribute('image'):setImageFilename(unit.fillType.hudOverlayFilename)
            cell:getAttribute('text'):setText(unit.fillType.title)

            if configuration.litersPerSecondText ~= nil then
                cell:getAttribute('info'):setText(configuration.litersPerSecondText)
            else
                cell:getAttribute('info'):setText(string.format('%i l/s', configuration.litersPerSecond))
            end
        end
    else
        local unit = self.units[index]

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
function ProcessorDialog:onItemDoubleClick(list, section, index, cell)
    if list == self.list then
        self:applyConfiguration(index)
    end
end

---@param list SmoothListElement
---@param section number
---@param index number
function ProcessorDialog:onListSelectionChanged(list, section, index)
    if list == self.list then
        self:updateUnits()
    end
end

function ProcessorDialog:updateUnits()
    local config = self:getSelectedConfiguration()

    if config ~= nil then
        self.units = {}

        for _, unit in ipairs(config:getUnits()) do
            if unit.visible then
                table.insert(self.units, unit)
            end
        end

        self.unitsListTitle:setText(config:getUnitsTitle())
        self.unitsListTitle:setVisible(true)
    else
        self.units = {}

        self.unitsListTitle:setVisible(false)
    end

    self.unitsList:reloadData()
end

---@param index number | nil
function ProcessorDialog:applyConfiguration(index)
    index = index or self.list:getSelectedIndexInSection()

    local config = self.configurations[index]

    if config ~= nil then
        self.processor.vehicle:setProcessorConfiguration(index)
    end

    self:close()
end

function ProcessorDialog:updateMenuButtons()
    if self.toggleHudButton ~= nil then
        if g_modSettings.enableHud then
            self.toggleHudButton:setText(g_modGui.L10N_TEXTS.DISABLE_HUD)
        else
            self.toggleHudButton:setText(g_modGui.L10N_TEXTS.ENABLE_HUD)
        end
    end
end

function ProcessorDialog:onClickApply()
    self:applyConfiguration()
end

function ProcessorDialog:onClickToggleHud()
    g_modSettings:setEnableHud(not g_modSettings.enableHud)
    self:updateMenuButtons()
end
