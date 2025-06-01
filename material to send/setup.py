from setuptools import setup
from Cython.Build import cythonize

setup(
    ext_modules=cythonize(
        [
            "read_final.pyx",
            "write_final.pyx",
            "alarm_final.pyx"
        ],
        compiler_directives={"language_level": "3"}, 
    ),
)
