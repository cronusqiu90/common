import threading
from threading import TIMEOUT_MAX


class SThread(threading.Thread):
    "background service thread"

    def __init__(self, name=None, **kwargs):
        super().__init__()
        self.__is_shutdown = threading.Event()
        self.__is_stopped = threading.Event()
        self.daemon = True
        self.name = name or self.__class__.__name__

    def _set_stopped(self):
        try:
            self.__is_stopped.set()
        except TypeError:  # pragma: no cover
            # lost the race at interpreter shutdown,
            # so gc collected builtin modules
            pass

    def stop(selff):
        "gracefully shutdown"
        self.__is_shutdown.set()
        self.__is_stopped.set()
        if self.is_alive():
            self.join(TIMEOUT_MAX)

    def body(self):
        raise NotImplementedError()

    def on_crash(self, msg, *fmt, **kwargs):
        # traceback.print_ext(None, sys.stderr)
        pass

    def run(self):
        body = self.body
        is_shutdown = self.__is_shutdown.is_set

        try:
            while not is_shutdown():
                try:
                    body()
                except Exception as err:  # pylint: disable=broad-except
                    self.on_crash("{0!r} crashed: {1!r}", self.name, err)
                    self._set_stopped()
        finally:
            self._set_stopped()
