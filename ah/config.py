import os

from ah.defs import SECONDS_IN
from ah.fs import get_temp_path

BN_CLIENT_ID = os.environ.get("BN_CLIENT_ID")
BN_CLIENT_SECRET = os.environ.get("BN_CLIENT_SECRET")
# minimum 60 days
MIN_RECORD_EXPIRES = 60 * SECONDS_IN.DAY
LOGGING_LEVEL = os.environ.get("LOGGING_LEVEL", "INFO")
DEFAULT_CACHE_PATH = os.path.join(get_temp_path(), "ah_cache")
DEFAULT_DB_PATH = "db"
DEFAULT_DB_COMPRESS = True
# how often to take a snapshot of the system memory / cpu usage
DEFAULT_SNAPSHOT_INTERVAL = 10
MAX_SNAPSHOTS = 100
