--------------
--  Logger  --
--------------
require "Base/Container"
-- Usage: 
--      LOG(RUN, INFO).Format()

FATAL = 1
ERROR = 2
WARN = 3
INFO = 4
DEBUG = 5
SYS = "SYS"
RUN = "RUN"
CSL = "CSL"
OPT = "OPT"
TST = "TST"
SPK = "SPK"
ACT = "ACT"

_G.Logger = {}
Logger.container = Container:Get("Logger")

-- performance 50k/s
function Logger:Init()
	for level = FATAL, DEBUG, 1 do
		for _, logger in pairs({SYS, RUN, CSL, OPT, TST, SPK, ACT}) do
			local tab = {
				logger = logger,
				level = level
			}
			tab.Format = function(format, ...)
                if Base.LoggerService then
	                if ... then
					    Base.LoggerService.object:Write(tab.logger, tab.level, string.format(format, ...))
				    else
				        Base.LoggerService.object:Write(tab.logger, tab.level, format)
			        end
				end
				return tab
			end
			Logger.container[logger] = Logger.container[logger] or {}
			Logger.container[logger][level] = tab
		end
	end
end
Logger:Init()

LOG = function(logger, level)
	return Logger.container[logger][level]
end

if Base.Enviroment.pro_spec_t ~= 'local' and Base.Enviroment.pro_spec_t ~= 'docker-local' then
_G.print = function() end
end
