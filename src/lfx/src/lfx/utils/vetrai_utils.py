"""Vetrai environment utility functions."""

import importlib.util

from lfx.log.logger import logger


class _VetraiModule:
    # Static variable
    # Tri-state:
    # - None: Vetrai check not performed yet
    # - True: Vetrai is available
    # - False: Vetrai is not available
    _available = None

    @classmethod
    def is_available(cls):
        return cls._available

    @classmethod
    def set_available(cls, value):
        cls._available = value


def has_vetrai_memory():
    """Check if vetrai.memory (with database support) and MessageTable are available."""
    # TODO: REVISIT: Optimize this implementation later
    # - Consider refactoring to use lazy loading or a more robust service discovery mechanism
    #   that can handle runtime availability changes.

    # Use cached check from previous invocation (if applicable)

    is_vetrai_available = _VetraiModule.is_available()

    if is_vetrai_available is not None:
        return is_vetrai_available

    # First check (lazy load and cache check)

    module_spec = None

    try:
        module_spec = importlib.util.find_spec("vetrai")
    except ImportError:
        pass
    except (TypeError, ValueError) as e:
        logger.error(f"Error encountered checking for vetrai.memory: {e}")

    is_vetrai_available = module_spec is not None
    _VetraiModule.set_available(is_vetrai_available)

    return is_vetrai_available
