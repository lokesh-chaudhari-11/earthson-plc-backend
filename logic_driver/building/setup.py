from setuptools import setup, Extension
from Cython.Build import cythonize

setup(
    ext_modules=cythonize(
        Extension(
            "plc_logic_driver",
            ["plc_logic_driver.pyx"],
            extra_compile_args=["-O3"],  # Optimize for performance
            extra_link_args=[],
        ),
        compiler_directives={
            'language_level': "3",  # Python 3
            'binding': True,       # Enable binding for safety
        },
        annotate=False,            # Disable generation of .html annotation file
    ),
)
