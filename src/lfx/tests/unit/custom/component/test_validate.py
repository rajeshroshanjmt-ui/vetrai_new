from textwrap import dedent

from lfx.custom.validate import create_class


def test_importing_vetrai_module_in_lfx():
    code = dedent("""from vetrai.custom import   Component
class TestComponent(Component):
    def some_method(self):
        pass
    """)
    result = create_class(code, "TestComponent")
    assert result.__name__ == "TestComponent"


def test_importing_vetrai_logging_in_lfx():
    """Test that vetrai.logging can be imported in lfx context without errors."""
    code = dedent("""
from vetrai.logging import logger, configure
from vetrai.custom import Component

class TestLoggingComponent(Component):
    def some_method(self):
        # Test that both logger and configure work
        configure(log_level="INFO")
        logger.info("Test message from component")
        return "success"
    """)
    result = create_class(code, "TestLoggingComponent")
    assert result.__name__ == "TestLoggingComponent"
