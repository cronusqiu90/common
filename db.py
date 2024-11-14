import contextlib
from typing import Optional

from sqlalchemy import create_engine as sqla_create_engine
from sqlalchemy.engine.url import URL as sqla_url_maker
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import scoped_session as sqla_scoped_session
from sqlalchemy.orm import sessionmaker as sqla_session_maker
from sqlalchemy.orm.decl_api import DeclarativeMeta
from sqlalchemy.pool import QueuePool

__all__ = ["Table", "setup", "session"]

_engine = None
_session_factory = None
_session_maker = None

Table: DeclarativeMeta = declarative_base()


def setup(
    dbname: str,
    user: Optional[str],
    password: Optional[str],
    host: str = "localhost",
    port: int = 3306,
    **kwargs
):
    driver = kwargs.pop("driver", "pymysql")
    pool_size = kwargs.pop("pool_size", 10)
    echo = kwargs.pop("echo", False)
    url = sqla_url_maker.create(
        drivername="mysql+%s" % driver,
        username=user,
        password=password,
        host=host,
        port=port,
        database=dbname,
    )
    engine_create_params = {
        "poolclass": QueuePool,
        "pool_size": pool_size,
        "pool_pre_ping": True,
        "echo": echo,
    }

    global _engine, _session_factory, _session_maker
    _engine = sqla_create_engine(url, **engine_create_params)
    _session_factory = sqla_session_maker(bind=_engine)
    _session_maker = sqla_scoped_session(_session_factory)
    Table.metadata.create_all(_engine)  # type: ignore


@contextlib.contextmanager
def session():
    _session = _session_maker()  # type: ignore
    try:
        _session.expire_on_commit = False
        with _session.begin():
            yield _session
        _session.expunge_all()
        _session.commit()
    except Exception as err:
        _session.rollback()
        raise err
    finally:
        _session.close()
