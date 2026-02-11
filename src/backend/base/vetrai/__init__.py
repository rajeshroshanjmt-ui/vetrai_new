"""Vetrai backwards compatibility layer.

This module provides backwards compatibility by forwarding imports from
vetrai.* to lfx.* to maintain compatibility with existing code that
references the old vetrai module structure.
"""

import importlib
import importlib.util
import sys
from types import ModuleType
from typing import Any


class VetraiCompatibilityModule(ModuleType):
    """A module that forwards attribute access to the corresponding lfx module."""

    def __init__(self, name: str, lfx_module_name: str):
        super().__init__(name)
        self._lfx_module_name = lfx_module_name
        self._lfx_module = None

    def _get_lfx_module(self):
        """Lazily import and cache the lfx module."""
        if self._lfx_module is None:
            try:
                self._lfx_module = importlib.import_module(self._lfx_module_name)
            except ImportError as e:
                msg = f"Cannot import {self._lfx_module_name} for backwards compatibility with {self.__name__}"
                raise ImportError(msg) from e
        return self._lfx_module

    def __getattr__(self, name: str) -> Any:
        """Forward attribute access to the lfx module with caching."""
        lfx_module = self._get_lfx_module()
        try:
            attr = getattr(lfx_module, name)
        except AttributeError as e:
            msg = f"module '{self.__name__}' has no attribute '{name}'"
            raise AttributeError(msg) from e
        else:
            # Cache the attribute in our __dict__ for faster subsequent access
            setattr(self, name, attr)
            return attr

    def __dir__(self):
        """Return directory of the lfx module."""
        try:
            lfx_module = self._get_lfx_module()
            return dir(lfx_module)
        except ImportError:
            return []


def _setup_compatibility_modules():
    """Set up comprehensive compatibility modules for vetrai.base imports."""
    # First, set up the base attribute on this module (vetrai)
    current_module = sys.modules[__name__]

    # Define all the modules we need to support
    module_mappings = {
        # Core base module
        "vetrai.base": "lfx.base",
        # Inputs module - critical for class identity
        "vetrai.inputs": "lfx.inputs",
        "vetrai.inputs.inputs": "lfx.inputs.inputs",
        # Schema modules - also critical for class identity
        "vetrai.schema": "lfx.schema",
        "vetrai.schema.data": "lfx.schema.data",
        "vetrai.schema.serialize": "lfx.schema.serialize",
        # Template modules
        "vetrai.template": "lfx.template",
        "vetrai.template.field": "lfx.template.field",
        "vetrai.template.field.base": "lfx.template.field.base",
        # Components modules
        "vetrai.components": "lfx.components",
        "vetrai.components.helpers": "lfx.components.helpers",
        "vetrai.components.helpers.calculator_core": "lfx.components.helpers.calculator_core",
        "vetrai.components.helpers.create_list": "lfx.components.helpers.create_list",
        "vetrai.components.helpers.current_date": "lfx.components.helpers.current_date",
        "vetrai.components.helpers.id_generator": "lfx.components.helpers.id_generator",
        "vetrai.components.helpers.memory": "lfx.components.helpers.memory",
        "vetrai.components.helpers.output_parser": "lfx.components.helpers.output_parser",
        "vetrai.components.helpers.store_message": "lfx.components.helpers.store_message",
        # Individual modules that exist in lfx
        "vetrai.base.agents": "lfx.base.agents",
        "vetrai.base.chains": "lfx.base.chains",
        "vetrai.base.data": "lfx.base.data",
        "vetrai.base.data.utils": "lfx.base.data.utils",
        "vetrai.base.document_transformers": "lfx.base.document_transformers",
        "vetrai.base.embeddings": "lfx.base.embeddings",
        "vetrai.base.flow_processing": "lfx.base.flow_processing",
        "vetrai.base.io": "lfx.base.io",
        "vetrai.base.io.chat": "lfx.base.io.chat",
        "vetrai.base.io.text": "lfx.base.io.text",
        "vetrai.base.langchain_utilities": "lfx.base.langchain_utilities",
        "vetrai.base.memory": "lfx.base.memory",
        "vetrai.base.models": "lfx.base.models",
        "vetrai.base.models.google_generative_ai_constants": "lfx.base.models.google_generative_ai_constants",
        "vetrai.base.models.openai_constants": "lfx.base.models.openai_constants",
        "vetrai.base.models.anthropic_constants": "lfx.base.models.anthropic_constants",
        "vetrai.base.models.aiml_constants": "lfx.base.models.aiml_constants",
        "vetrai.base.models.aws_constants": "lfx.base.models.aws_constants",
        "vetrai.base.models.groq_constants": "lfx.base.models.groq_constants",
        "vetrai.base.models.novita_constants": "lfx.base.models.novita_constants",
        "vetrai.base.models.ollama_constants": "lfx.base.models.ollama_constants",
        "vetrai.base.models.sambanova_constants": "lfx.base.models.sambanova_constants",
        "vetrai.base.models.cometapi_constants": "lfx.base.models.cometapi_constants",
        "vetrai.base.prompts": "lfx.base.prompts",
        "vetrai.base.prompts.api_utils": "lfx.base.prompts.api_utils",
        "vetrai.base.prompts.utils": "lfx.base.prompts.utils",
        "vetrai.base.textsplitters": "lfx.base.textsplitters",
        "vetrai.base.tools": "lfx.base.tools",
        "vetrai.base.vectorstores": "lfx.base.vectorstores",
    }

    # Create compatibility modules for each mapping
    for vetrai_name, lfx_name in module_mappings.items():
        if vetrai_name not in sys.modules:
            # Check if the lfx module exists
            try:
                spec = importlib.util.find_spec(lfx_name)
                if spec is not None:
                    # Create compatibility module
                    compat_module = VetraiCompatibilityModule(vetrai_name, lfx_name)
                    sys.modules[vetrai_name] = compat_module

                    # Set up the module hierarchy
                    parts = vetrai_name.split(".")
                    if len(parts) > 1:
                        parent_name = ".".join(parts[:-1])
                        parent_module = sys.modules.get(parent_name)
                        if parent_module is not None:
                            setattr(parent_module, parts[-1], compat_module)

                    # Special handling for top-level modules
                    if vetrai_name == "vetrai.base":
                        current_module.base = compat_module
                    elif vetrai_name == "vetrai.inputs":
                        current_module.inputs = compat_module
                    elif vetrai_name == "vetrai.schema":
                        current_module.schema = compat_module
                    elif vetrai_name == "vetrai.template":
                        current_module.template = compat_module
                    elif vetrai_name == "vetrai.components":
                        current_module.components = compat_module
            except (ImportError, ValueError):
                # Skip modules that don't exist in lfx
                continue

    # Handle modules that exist only in vetrai (like knowledge_bases)
    # These need special handling because they're not in lfx yet
    vetrai_only_modules = {
        "vetrai.base.data.kb_utils": "vetrai.base.data.kb_utils",
        "vetrai.base.knowledge_bases": "vetrai.base.knowledge_bases",
        "vetrai.components.knowledge_bases": "vetrai.components.knowledge_bases",
    }

    for vetrai_name in vetrai_only_modules:
        if vetrai_name not in sys.modules:
            try:
                # Try to find the actual physical module file
                from pathlib import Path

                base_dir = Path(__file__).parent

                if vetrai_name == "vetrai.base.data.kb_utils":
                    kb_utils_file = base_dir / "base" / "data" / "kb_utils.py"
                    if kb_utils_file.exists():
                        spec = importlib.util.spec_from_file_location(vetrai_name, kb_utils_file)
                        if spec is not None and spec.loader is not None:
                            module = importlib.util.module_from_spec(spec)
                            sys.modules[vetrai_name] = module
                            spec.loader.exec_module(module)

                            # Also add to parent module
                            parent_module = sys.modules.get("vetrai.base.data")
                            if parent_module is not None:
                                parent_module.kb_utils = module

                elif vetrai_name == "vetrai.base.knowledge_bases":
                    kb_dir = base_dir / "base" / "knowledge_bases"
                    kb_init_file = kb_dir / "__init__.py"
                    if kb_init_file.exists():
                        spec = importlib.util.spec_from_file_location(vetrai_name, kb_init_file)
                        if spec is not None and spec.loader is not None:
                            module = importlib.util.module_from_spec(spec)
                            sys.modules[vetrai_name] = module
                            spec.loader.exec_module(module)

                            # Also add to parent module
                            parent_module = sys.modules.get("vetrai.base")
                            if parent_module is not None:
                                parent_module.knowledge_bases = module

                elif vetrai_name == "vetrai.components.knowledge_bases":
                    components_kb_dir = base_dir / "components" / "knowledge_bases"
                    components_kb_init_file = components_kb_dir / "__init__.py"
                    if components_kb_init_file.exists():
                        spec = importlib.util.spec_from_file_location(vetrai_name, components_kb_init_file)
                        if spec is not None and spec.loader is not None:
                            module = importlib.util.module_from_spec(spec)
                            sys.modules[vetrai_name] = module
                            spec.loader.exec_module(module)

                            # Also add to parent module
                            parent_module = sys.modules.get("vetrai.components")
                            if parent_module is not None:
                                parent_module.knowledge_bases = module
            except (ImportError, AttributeError):
                # If direct file loading fails, skip silently
                continue


# Set up all the compatibility modules
_setup_compatibility_modules()
