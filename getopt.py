import sys
import os
import getopt

class Options:
    stderr = sys.stderr
    stdout = sys.stdout
    exit = sys.exit

    uid = gid = None

    progname = sys.argv[0]
    configfile = None


    def __init__(self, require_configfile=True) -> None:
        self.names_list = []
        self.short_options = []
        self.long_options = []
        self.options_map = {}
        self.default_map = {}
        self.required_map = {}
        self.environ_map = {}
        self.attr_priorities = {}
        self.require_configfile = require_configfile

        self.add("configfile", None, "c:", "configuration=")

        self.environ_expansions = {}
        for k, v in os.environ.items():
            self.environ_expansions['ENV_%s' % k] = v


    def _set(self, attr, value, priority):
        current = self.attr_priorities.get(attr, -1)
        if priority >= current:
            setattr(self, attr, value)
            self.attr_priorities[attr] = priority

    def add(self,
            name=None,                  # attribute name on self
            confname=None,              # dotted config path name
            short=None,                 # short option name
            long=None,                  # long option name
            handler=None,               # handler (defaults to string)
            default=None,               # default value
            required=None,              # message if not provided
            flag=None,                  # if not None, flag value
            env=None,                   # if not None, environment variable
            ):
        if flag is not None:
            if handler is not None:
                raise ValueError("use at most one of flag= and handler=")
            if not long and not short:
                raise ValueError("flag= requires a command line flag")
            if short and short.endswith(":"):
                raise ValueError("flag= requires a command line flag")
            if long and long.endswith("="):
                raise ValueError("flag= requires a command line flag")
            handler = lambda arg, flag=flag: flag

        if short and long:
            if short.endswith(":") != long.endswith("="):
                raise ValueError("inconsistent short/long options: %r %r" % (
                    short, long))

        if short:
            if short[0] == "-":
                raise ValueError("short option should not start with '-'")
            key, rest = short[:1], short[1:]
            if rest not in ("", ":"):
                raise ValueError("short option should be 'x' or 'x:'")
            key = "-" + key
            if key in self.options_map:
                raise ValueError("duplicate short option key '%s'" % key)
            self.options_map[key] = (name, handler)
            self.short_options.append(short)

        if long:
            if long[0] == "-":
                raise ValueError("long option should not start with '-'")
            key = long
            if key[-1] == "=":
                key = key[:-1]
            key = "--" + key
            if key in self.options_map:
                raise ValueError("duplicate long option key '%s'" % key)
            self.options_map[key] = (name, handler)
            self.long_options.append(long)

        if env:
            self.environ_map[env] = (name, handler)

        if name:
            if not hasattr(self, name):
                setattr(self, name, None)
            self.names_list.append((name, confname))
            if default is not None:
                self.default_map[name] = default
            if required:
                self.required_map[name] = required

    def usage(self, msg):
        """Print a brief error message to stderr and exit(2)."""
        self.stderr.write("Error: %s\n" % str(msg))
        self.stderr.write("For help, use %s -h\n" % self.progname)
        self.exit(2)

    def realize(self, args=None):
        if args is None:
            args = sys.argv[1:]

        if not self.progname:
            self.progname = sys.argv[0]

        self.options = []
        self.args = []


        # Call getopt
        try:
            self.options, self.args = getopt.getopt(
                args , "".join(self.short_options), self.long_options
            )
        except getopt.error as err:
            self.usage(str(err))


        # Process options returned by getopt
        for opt, arg in self.options:
            name, handler = self.options_map[opt]
            if handler is not None:
                try:
                    arg = handler(arg)
                except ValueError as err:
                    self.usage("invalid value for %s %r: %s" % (opt, arg, msg))
            if name and arg is not None:
                if getattr(self, name) is not None:
                    self.usage("conflicting command line option %r" % opt)
                self._set(name, arg, 2)

        # Process environment variables
        for envvar in self.environ_map.keys():
            name, handler = self.environ_map[envvar]
            if envvar in os.environ:
                value = os.environ[envvar]
                if handler is not None:
                    try:
                        value = handler(value)
                    except ValueError as err:
                        self.usage("invalid environment value for %s %r: %s" % (envvar, value, err))
                if name and value is not None:
                    self._set(name, value, 1)

        if self.configfile is None:
            self.usage("No special config file; use the -c option to specify a config file.")

        if not self.exists(self.configfile):
            self.usage(f"No such file: {self.configfile}")

        print(self.configfile)
        print(self.options)
        print(self.environ_expansions)
        print(self.environ_map)
        print(self.attr_priorities)

    def exists(self, path):
        return os.path.exists(path)

    def open(self, path, mode="r"):
        return open(path, mode)

options = Options()
options.realize()
