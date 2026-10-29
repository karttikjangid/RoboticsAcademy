1: """
2: Auxiliary script for setting the Nvidia libraries in the RADI
3: 
4: Register all pip-installed nvidia .so files with ldconfig so onnxruntime-gpu
5: finds them regardless of whether pip used site-packages or dist-packages
6: """
7: 
8: import sysconfig, pathlib
9: 
10: site = pathlib.Path(sysconfig.get_path("purelib"))
11: conf = "\n".join(str(d) for d in site.glob("nvidia/*/lib") if d.is_dir())
12: pathlib.Path("/etc/ld.so.conf.d/nvidia-pip.conf").write_text(conf + "\n")
