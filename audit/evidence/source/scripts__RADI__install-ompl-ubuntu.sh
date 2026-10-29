1: #!/bin/bash
2: 
3: set -e
4: 
5: if [ `id -u` == 0 ]; then
6:     SUDO=
7:     export DEBIAN_FRONTEND=noninteractive
8:     apt-get -y install lsb-release
9: else
10:     SUDO="sudo -H"
11: fi
12: 
13: ubuntu_version=`lsb_release -rs | sed 's/\.//'`
14: 
15: install_common_dependencies()
16: {
17:     # install most dependencies via apt-get
18:     ${SUDO} apt-get -y update
19:     ${SUDO} apt-get -y upgrade
20:     # We explicitly set the C++ compiler to g++, the default GNU g++ compiler. This is
21:     # needed because we depend on system-installed libraries built with g++ and linked
22:     # against libstdc++. In case `c++` corresponds to `clang++`, code will not build, even
23:     # if we would pass the flag `-stdlib=libstdc++` to `clang++`.
24:     ${SUDO} apt-get -y install g++ cmake pkg-config libboost-serialization-dev libboost-filesystem-dev libboost-system-dev libboost-program-options-dev libboost-test-dev libeigen3-dev libode-dev wget libyaml-cpp-dev
25:     export CXX=g++
26:     export MAKEFLAGS="-j `nproc`"
27: }
28: 
29: install_python_binding_dependencies()
30: {
31:     ${SUDO} apt-get -y install python${PYTHONV}-dev python${PYTHONV}-pip
32:     # install additional python dependencies via pip
33:     ${SUDO} pip${PYTHONV} install -vU https://github.com/CastXML/pygccxml/archive/develop.zip pyplusplus
34:     # install castxml
35:     if [[ $ubuntu_version > 1910 ]]; then
36:         ${SUDO} apt-get -y install castxml
37:     else
38:         wget -q -O- https://data.kitware.com/api/v1/file/5e8b740d2660cbefba944189/download | tar zxf - -C ${HOME}
39:         export PATH=${HOME}/castxml/bin:${PATH}
40:     fi
41:     ${SUDO} apt-get -y install libboost-python-dev
42:     if [[ $ubuntu_version > 1710 ]]; then
43:         ${SUDO} apt-get -y install libboost-numpy-dev python${PYTHONV}-numpy
44:     fi
45:     if [[ $ubuntu_version > 1904 ]]; then
46:         ${SUDO} apt-get -y install pypy3
47:     fi
48: }
49: 
50: install_app_dependencies()
51: {
52:     ${SUDO} apt-get -y install python${PYTHONV}-pyqt5.qtopengl freeglut3-dev libassimp-dev python${PYTHONV}-opengl python${PYTHONV}-flask python${PYTHONV}-celery libccd-dev
53:     # install additional python dependencies via pip
54:     ${SUDO} pip${PYTHONV} install -vU PyOpenGL-accelerate
55:     # install fcl
56:     if ! pkg-config --atleast-version=0.5.0 fcl; then
57:         if [[ $ubuntu_version > 1604 ]]; then
58:             ${SUDO} apt-get -y install libfcl-dev
59:         else
60:             wget -O - https://github.com/flexible-collision-library/fcl/archive/0.6.1.tar.gz | tar zxf -
61:             cd fcl-0.6.1; cmake .; ${SUDO} -E make install; cd ..
62:         fi
63:     fi
64: }
65: 
66: install_ompl()
67: {
68:     if [ -z $APP ]; then
69:         OMPL="ompl"
70:     else
71:         OMPL="omplapp"
72:     fi
73:     if [ -z $GITHUB ]; then
74:         if [ -z $APP ]; then
75:             wget -O - https://github.com/ompl/${OMPL}/archive/1.7.0.tar.gz | tar zxf -
76:             cd ${OMPL}-1.7.0
77:         else
78:             wget -O - https://github.com/ompl/${OMPL}/releases/download/1.7.0/${OMPL}-1.7.0-Source.tar.gz | tar zxf -
79:             cd $OMPL-1.7.0-Source
80:         fi
81:     else
82:         ${SUDO} apt-get -y install git
83:         git clone --recurse-submodules https://github.com/ompl/${OMPL}.git
84:         cd $OMPL
85:         git checkout 0f990886e9e40014e32ddee177c8d798adbc8fb7 # Temporary: with this commit works
86:     fi
87:     mkdir -p build/Release
88:     cd build/Release
89:     cmake ../.. -DPYTHON_EXEC=/usr/bin/python${PYTHONV}
90:     if [ ! -z $PYTHON ]; then
91:         # Check if the total memory is less than 6GB.
92:         if [ `cat /proc/meminfo | head -1 | awk '{print $2}'` -lt 6291456 ]; then
93:             echo "Python binding generation is very memory intensive. At least 6GB of RAM is recommended."
94:             echo "Proceeding with binding generation using 1 core..."
95:             make -j 1 update_bindings
96:         else
97:             make update_bindings
98:         fi
99:     fi
100:     make
101:     ${SUDO} make install
102: }
103: 
104: for i in "$@"
105: do
106: case $i in
107:     -a|--app)
108:         APP=1
109:         PYTHON=1
110:         shift
111:         ;;
112:     -p|--python)
113:         PYTHON=1
114:         shift
115:         ;;
116:     -g|--github)
117:         GITHUB=1
118:         shift
119:         ;;
120:     *)
121:         # unknown option -> show help
122:         echo "Usage: `basename $0` [-p] [-a]"
123:         echo "  -p: enable Python bindings"
124:         echo "  -a: enable OMPL.app (implies '-p')"
125:         echo "  -g: install latest commit from main branch on GitHub"
126:     ;;
127: esac
128: done
129: 
130: # the default version of Python in 17.10 and above is version 3
131: if [[ $ubuntu_version > 1704 ]]; then
132:     PYTHONV=3
133: fi
134: 
135: install_common_dependencies
136: if [ ! -z $PYTHON ]; then
137:     install_python_binding_dependencies
138: fi
139: if [ ! -z $APP ]; then
140:     install_app_dependencies
141: fi
142: install_ompl
