1: #!/bin/bash
2: 
3: # Default branch if not specified
4: ROBOTICS_ACADEMY="humble-devel"
5: ROBOTICS_INFRASTRUCTURE="humble-devel"
6: RAM="humble-devel"
7: ROS_DISTRO="humble"
8: IMAGE_TAG="test"
9: OFFLINE_BUILD=false
10: FORCE_BUILD=false
11: FORCE_BUILD_NO_CACHE=false
12: 
13: # Default GitHub owners
14: ACADEMY_OWNER="JdeRobot"
15: INFRA_OWNER="JdeRobot"
16: 
17: Help()
18: {
19:    echo "Syntax: build.sh [options]"
20:    echo "Options:"
21:    echo "  -h                           Print this Help."
22:    echo "  -f                           Force creation of the base image. If omitted, the base image is created only if it doesn't exist."
23:    echo "  -F                           Force creation of the base image without using docker cache."
24:    echo "  -o, --offline       <value>  Use offline dockerfile."
25:    echo "  -a, --academy       <value>  Branch of RoboticsAcademy.               Default: humble-devel"
26:    echo "  -i, --infra         <value>  Branch of RoboticsInfrastructure.        Default: humble-devel"
27:    echo "  -m, --ram           <value>  Branch of RoboticsApplicationManager.    Default: humble-devel"
28:    echo "  -r, --ros           <value>  ROS Distro (humble).                     Default: humble"
29:    echo "  -t, --tag           <value>  Tag name of the image.                   Default: test"
30:    echo "  --academy-owner     <value>  GitHub owner for RoboticsAcademy.        Default: JdeRobot"
31:    echo "  --infra-owner       <value>  GitHub owner for RoboticsInfrastructure. Default: JdeRobot"
32:    echo
33:    echo "Example:"
34:    echo "   ./build.sh -t my_image"
35:    echo "   ./build.sh --infra-owner <github-user> -i <infra-fork-branch> --tag my_image"
36:    echo
37: }
38: 
39: while [[ $# -gt 0 ]]; do
40:     case "$1" in
41:         -a | --academy)
42:             ROBOTICS_ACADEMY="$2"
43:             shift 2
44:             ;;
45:         -i | --infra)
46:             ROBOTICS_INFRASTRUCTURE="$2"
47:             shift 2
48:             ;;
49:         -m | --ram)
50:             RAM="$2"
51:             shift 2
52:             ;;
53:         -r | --ros)
54:             ROS_DISTRO="$2"
55:             shift 2
56:             ;;
57:         -t | --tag)
58:             IMAGE_TAG="$2"
59:             shift 2
60:             ;;
61:         --academy-owner)
62:             ACADEMY_OWNER="$2"
63:             shift 2
64:             ;;
65:         --infra-owner)
66:             INFRA_OWNER="$2"
67:             shift 2
68:             ;;
69:         -f | --force)
70:             FORCE_BUILD=true
71:             shift
72:             ;;
73:         -o | --offline)
74:             OFFLINE_BUILD=true
75:             shift
76:             ;;
77:         -F | --force-no-cache)
78:             FORCE_BUILD_NO_CACHE=true
79:             shift
80:             ;;
81:         -h | --help)
82:             echo "Generates RoboticsAcademy RoboticsBackend image"
83:             echo
84:             Help
85:             exit 0
86:             ;;
87:         *)
88:             echo "Invalid Option: $1"
89:             Help
90:             exit 1
91:             ;;
92:    esac
93: done
94: 
95: echo "ROBOTICS_ACADEMY:-------------:$ROBOTICS_ACADEMY (Owner: $ACADEMY_OWNER)"
96: echo "ROBOTICS_INFRASTRUCTURE:------:$ROBOTICS_INFRASTRUCTURE (Owner: $INFRA_OWNER)"
97: echo "RAM:--------------------------:$RAM"
98: echo "ROS_DISTRO:-------------------:$ROS_DISTRO"
99: echo "IMAGE_TAG:--------------------:$IMAGE_TAG"
100: echo
101: 
102: if [[ $ROS_DISTRO == "humble" ]]; then
103:     DOCKERFILE_BASE="Dockerfile.dependencies_humble"
104:     if $OFFLINE_BUILD; then
105:       DOCKERFILE="scripts/RADI/Dockerfile.humble_offline"
106:     else
107:       DOCKERFILE="Dockerfile.humble"
108:     fi
109: else
110:     echo "Error: Unknown ROS_DISTRO ($ROS_DISTRO). Please set it to 'humble'."
111:     exit 1
112: fi
113: 
114: if $FORCE_BUILD_NO_CACHE; then
115:   NO_CACHE="--no-cache"
116: else
117:   NO_CACHE=""
118: fi
119: 
120: 
121: if $FORCE_BUILD_NO_CACHE || $FORCE_BUILD || [[ "$(docker images -q jderobot/robotics-applications:dependencies-$ROS_DISTRO 2> /dev/null)" == "" ]]; then
122:   echo "===================== BUILDING $ROS_DISTRO BASE IMAGE ====================="
123:   echo "Building base using $DOCKERFILE_BASE for ROS $ROS_DISTRO"
124:   docker build $NO_CACHE -f $DOCKERFILE_BASE \
125:     --build-arg TARGETARCH=$(uname -m | sed 's/x86_64/amd64/;s/arm64/arm64/') \
126:     -t jderobot/robotics-applications:dependencies-$ROS_DISTRO .
127: fi
128: 
129: if [ $? -eq 0 ]; then
130:     echo "Docker Base Image Build Successful"
131: else
132:     echo "Docker Base Image Build FAILED...exiting"
133:     exit
134: fi
135: 
136: echo "===================== BUILDING $ROS_DISTRO RoboticsBackend ====================="
137: echo "Building RoboticsBackend using $DOCKERFILE for ROS $ROS_DISTRO"
138: 
139: if $OFFLINE_BUILD; then
140:   cd ../..
141: fi
142: 
143: docker build --no-cache -f $DOCKERFILE \
144:   --build-arg ROBOTICS_ACADEMY=$ROBOTICS_ACADEMY \
145:   --build-arg ROBOTICS_INFRASTRUCTURE=$ROBOTICS_INFRASTRUCTURE \
146:   --build-arg RAM=$RAM \
147:   --build-arg ROS_DISTRO=$ROS_DISTRO \
148:   --build-arg IMAGE_TAG=$IMAGE_TAG \
149:   --build-arg ACADEMY_OWNER=$ACADEMY_OWNER \
150:   --build-arg INFRA_OWNER=$INFRA_OWNER \
151:   -t jderobot/robotics-academy:$IMAGE_TAG .
152: 
153: if $OFFLINE_BUILD; then
154:   cd scripts/RADI
155: fi
