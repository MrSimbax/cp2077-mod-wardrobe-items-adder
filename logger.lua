local Logger = {}

Logger.LogLevel = {
    DEBUG = 1,
    INFO = 2,
    WARN = 3,
    ERROR = 4,
    OFF = 5
}

local function printf (fmtstr, ...)
    print(string.format(fmtstr, ...))
end

function Logger:debug (fmtstr, ...)
    if self.logLevel <= self.LogLevel.DEBUG then
        printf(self.prefix.."[DEBUG] "..fmtstr, ...)
    end
end

function Logger:info (fmtstr, ...)
    if self.logLevel <= self.LogLevel.INFO then
        printf(self.prefix.."[INFO] "..fmtstr, ...)
    end
end

function Logger:warn (fmtstr, ...)
    if self.logLevel <= self.LogLevel.WARN then
        printf(self.prefix.."[WARN] "..fmtstr, ...)
    end
end

function Logger:error (fmtstr, ...)
    if self.logLevel <= self.LogLevel.ERROR then
        printf(self.prefix.."[ERROR] "..fmtstr, ...)
    end
end

function Logger:init (logLevel, prefix)
    self.prefix = prefix or ''
    self.logLevel = logLevel or self.LogLevel.INFO
    return self
end

return Logger
