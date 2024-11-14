import sys
import os
from os import PathLike
from datetime import datetime

from loguru import logger as _ulog
from loguru._logger import Logger
from loguru._logger import Core as _Core
from loguru import _file_sink
from loguru._datetime import aware_now as _aware_now


# Example:
#  import log
#
#  # default level is INFO
#  log.info("hello")
#  # 2024-11-14 17:13:00.183 | INFO    | log | m.py:7 | hello
#
#  # enable debug level
#  log._enable_debug()
#
#  # create a new logger and use default parameter
#  slog = log.new("slog", sink=sys.stdout)
#  slog.info("hello")
#  # 2024-11-14 17:13:00.183 | INFO    | slog | m.py:7 | hello


_default_format = (
    "{time:YYYY-MM-DD HH:mm:ss.SSS} | "
    "{level:<7} | "
    "{extra[mod]} | "
    "{file}:{line} | "
    "{message}"
)
_ulog.remove()
_ulog.add(
    sys.stdout,
    format=_default_format,
    level="INFO",
    backtrace=True,
    colorize=False,
)
_ulog = _ulog.bind(mod="log")


def _enable_debug(level: str = "DEBUG"):
    _, no, _, _ = _ulog.level(level)
    _core = getattr(_ulog, "_core")
    with _core.lock:
        setattr(_core, "min_level", no)
        for handler in _core.handlers.values():
            handler._levelno = no


def new(module, sink, level="INFO", format=_default_format, rotate="00:00"):
    if isinstance(sink, (str, PathLike)):
        kwargs = {"rotation": rotate}
    else:
        kwargs = {}

    _log = Logger(
        core=_Core(),
        exception=None,
        depth=0,
        record=False,
        lazy=False,
        colors=False,
        raw=False,
        capture=True,
        patcher=None,
        extra={"mod": module},
    )
    _log.add(sink, format=format, level=level, backtrace=True, colorize=False, **kwargs)
    return _log


TRACE = "TRACE"
DEBUG = "DEBUG"
INFO = "INFO"
WARNING = "WARNING"
ERROR = "ERROR"
CRITICAL = "CRITICAL"

trace = _ulog.trace
debug = _ulog.debug
info = _ulog.info
warn = _ulog.warning
error = _ulog.error
exception = _ulog.exception
critical = _ulog.critical
